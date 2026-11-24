import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/shiny_hunt.dart';
import '../../providers/shiny_hunt_provider.dart';
import '../scanner_core/engine/ocr_detection_engine.dart';
import '../scanner_core/feedback/scanner_feedback.dart';
import '../scanner_core/media/frame_transition_detector.dart';
import '../scanner_core/models/scanner_event.dart';
import '../scanner_core/models/scanner_settings.dart';
import '../scanner_core/scanner_coordinator.dart';
import '../scanner_core/source/scanner_source.dart';
import 'shiny_auto_counter_config.dart';
import 'shiny_slot_state_machine.dart';

/// Ring-buffer audit entry for every automatic encounter increment and Undo action.
class AutoCountLogEntry {
  final String id;
  final int slotId;
  final int colorHex;
  final String huntId;
  final int? pokemonId;
  final String? pokemonName;
  final int delta;
  final String reason;
  final bool isShiny;
  final DateTime timestamp;
  final bool undone;

  const AutoCountLogEntry({
    required this.id,
    required this.slotId,
    required this.colorHex,
    required this.huntId,
    this.pokemonId,
    this.pokemonName,
    required this.delta,
    required this.reason,
    this.isShiny = false,
    required this.timestamp,
    this.undone = false,
  });

  AutoCountLogEntry copyWith({bool? undone}) => AutoCountLogEntry(
        id: id,
        slotId: slotId,
        colorHex: colorHex,
        huntId: huntId,
        pokemonId: pokemonId,
        pokemonName: pokemonName,
        delta: delta,
        reason: reason,
        isShiny: isShiny,
        timestamp: timestamp,
        undone: undone ?? this.undone,
      );
}

/// Threadsafe coordinator connecting [ScannerCoordinator], [FrameTransitionScannerSource],
/// per-slot [ShinySlotStateMachine] instances, and [ShinyHuntProvider].
class ShinyAutoCounterService {
  static final ShinyAutoCounterService _instance =
      ShinyAutoCounterService._internal();
  factory ShinyAutoCounterService() => _instance;
  static ShinyAutoCounterService get instance => _instance;

  ShinyAutoCounterService._internal([
    this._elapsedClock,
    this._feedback,
  ]);

  @visibleForTesting
  factory ShinyAutoCounterService.forTesting({
    Duration Function()? elapsedClock,
    ScannerFeedback? feedback,
  }) {
    return ShinyAutoCounterService._internal(
      elapsedClock,
      feedback,
    );
  }

  static const int maxLogEntries = 50;

  final Duration Function()? _elapsedClock;
  ScannerFeedback? _feedback;

  ShinyHuntProvider? _huntProvider;
  ScannerCoordinator? _coordinator;
  ScannerSource? _source;
  String? _defaultHuntId;
  ShinyAutoCounterSettings _settings = const ShinyAutoCounterSettings();

  StreamSubscription<ScannerEvent>? _eventSub;
  StreamSubscription<ScannerCueSignal>? _cueSub;
  StreamSubscription<FrameTransitionEvent>? _transitionSub;

  final Map<int, ShinySlotStateMachine> _slots = {};
  final List<AutoCountLogEntry> _logs = [];
  int _logSequence = 0;

  // Serialized FIFO queue for zero race conditions across N concurrent slots.
  final List<_SerializedAutoTask> _queue = [];
  bool _drainingQueue = false;
  bool _running = false;
  bool _paused = false;

  final ValueNotifier<bool> isRunningNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier(false);
  final ValueNotifier<List<ShinySlotSnapshot>> slotStatesNotifier =
      ValueNotifier(const []);
  final ValueNotifier<List<AutoCountLogEntry>> recentLogsNotifier =
      ValueNotifier(const []);
  final ValueNotifier<AutoCountLogEntry?> latestShinyAlertNotifier =
      ValueNotifier(null);
  final ValueNotifier<ShinyAutoCounterSettings> settingsNotifier =
      ValueNotifier(const ShinyAutoCounterSettings());

  bool get isRunning => _running;
  bool get isPaused => _paused;
  String? get defaultHuntId => _defaultHuntId;
  ShinyAutoCounterSettings get settings => _settings;
  ScannerCoordinator? get coordinator => _coordinator;
  ScannerSource? get source => _source;
  List<AutoCountLogEntry> get recentLogs => List.unmodifiable(_logs);

  void configureFeedback(ScannerFeedback? feedback) {
    _feedback = feedback;
  }

  /// Starts or reconfigures an auto-counter session across [slotIds].
  void startSession({
    required ShinyHuntProvider huntProvider,
    required ScannerCoordinator coordinator,
    required String defaultHuntId,
    ScannerSource? source,
    List<int> slotIds = const [1],
    Map<int, int>? slotColorOverrides,
    ShinyAutoCounterSettings? settings,
  }) {
    _cleanupSubscriptions();

    _huntProvider = huntProvider;
    _coordinator = coordinator;
    _source = source;
    _defaultHuntId = defaultHuntId;

    final hunt = huntProvider.getHuntById(defaultHuntId);
    _settings = settings ??
        (hunt != null
            ? ShinyAutoCounterSettings.forHuntMethod(hunt.method)
            : const ShinyAutoCounterSettings());
    settingsNotifier.value = _settings;

    _applyCustomPatternsToCoordinator();

    _slots.clear();
    final effectiveSlotIds = slotIds.isEmpty ? const [1] : slotIds;
    for (int i = 0; i < effectiveSlotIds.length; i++) {
      final sid = effectiveSlotIds[i];
      final colorHex = slotColorOverrides?[sid] ??
          MultiInstanceGridHelper.colorForIndex(sid > 0 ? sid - 1 : i);
      final targetHuntId =
          _settings.slotToHuntOverrides[sid] ?? defaultHuntId;
      final targetHunt = huntProvider.getHuntById(targetHuntId);

      _slots[sid] = ShinySlotStateMachine(
        slotId: sid,
        colorHex: colorHex,
        targetPokemonId: targetHunt?.pokemonId,
        targetPokemonName: targetHunt?.pokemonName,
        assignedHuntId: targetHuntId,
        settings: _settings,
        elapsedClock: _elapsedClock,
      );
    }

    _eventSub = coordinator.events.listen((event) {
      _enqueue(() => _processScannerEvent(event));
    });
    _cueSub = coordinator.cueStream.listen((cue) {
      _enqueue(() => _processCueSignal(cue));
    });
    if (source is FrameTransitionScannerSource) {
      _transitionSub = source.transitionStream.listen((transition) {
        _enqueue(() => _processFrameTransition(transition));
      });
    }

    _running = true;
    _paused = false;
    isRunningNotifier.value = true;
    isPausedNotifier.value = false;
    latestShinyAlertNotifier.value = null;
    _publishSlotSnapshots();
  }

  void setDefaultHuntId(String huntId) {
    _defaultHuntId = huntId;
    for (final slot in _slots.values) {
      if (!_settings.slotToHuntOverrides.containsKey(slot.slotId)) {
        final h = _huntProvider?.getHuntById(huntId);
        slot.updateTarget(
          pokemonId: h?.pokemonId,
          pokemonName: h?.pokemonName,
          huntId: huntId,
        );
      }
    }
    _publishSlotSnapshots();
  }

  void updateSettings(ShinyAutoCounterSettings next) {
    _settings = next;
    settingsNotifier.value = next;
    _applyCustomPatternsToCoordinator();

    for (final slot in _slots.values) {
      final assigned = next.slotToHuntOverrides[slot.slotId] ?? _defaultHuntId;
      final h = assigned != null ? _huntProvider?.getHuntById(assigned) : null;
      slot.updateSettings(next);
      slot.updateTarget(
        pokemonId: h?.pokemonId,
        pokemonName: h?.pokemonName,
        huntId: assigned,
      );
    }
    _publishSlotSnapshots();
  }

  void assignSlotToHunt(int slotId, String? huntId) {
    final nextOverrides = Map<int, String>.from(_settings.slotToHuntOverrides);
    if (huntId == null || huntId.isEmpty) {
      nextOverrides.remove(slotId);
    } else {
      nextOverrides[slotId] = huntId;
    }
    updateSettings(_settings.copyWith(slotToHuntOverrides: nextOverrides));
  }

  void toggleGlobalPause() {
    _paused = !_paused;
    isPausedNotifier.value = _paused;
  }

  void setGlobalPause(bool paused) {
    _paused = paused;
    isPausedNotifier.value = _paused;
  }

  void togglePauseSlot(int slotId) {
    final slot = _slots[slotId];
    if (slot == null) return;
    if (slot.phase == ShinySlotPhase.pausedByShiny) {
      slot.resumeFromShinyPause();
      _coordinator?.clearBattleState(slotId);
    } else {
      slot.setManualPaused(slot.phase != ShinySlotPhase.pausedManual);
    }
    _publishSlotSnapshots();
  }

  void resumeShinyPausedSlot(int slotId) {
    final slot = _slots[slotId];
    if (slot == null) return;
    slot.resumeFromShinyPause();
    _coordinator?.clearBattleState(slotId);
    if (latestShinyAlertNotifier.value?.slotId == slotId) {
      latestShinyAlertNotifier.value = null;
    }
    _publishSlotSnapshots();
  }

  void rearmSlot(int slotId) {
    final slot = _slots[slotId];
    if (slot == null) return;
    slot.forceRearm();
    _coordinator?.clearBattleState(slotId);
    _publishSlotSnapshots();
  }

  /// Directly feeds a [FrameTransitionEvent] through the serialized queue.
  Future<void> handleFrameTransition(FrameTransitionEvent transition) {
    return _enqueue(() => _processFrameTransition(transition));
  }

  /// Waits until pending stream microtasks and serialized queue tasks have drained.
  Future<void> waitForIdle() async {
    await Future<void>.microtask(() {});
    await Future<void>.microtask(() {});
    if (_drainingQueue || _queue.isNotEmpty) {
      await _enqueue(() async {});
    }
  }

  /// Undoes the most recent non-undone automatic increment.
  bool undoLastCount() {
    final idx = _logs.indexWhere((e) => !e.undone);
    if (idx < 0) return false;
    return undoEntry(_logs[idx].id);
  }

  /// Undoes a specific log entry by [entryId], subtracting its exact delta.
  bool undoEntry(String entryId) {
    final idx = _logs.indexWhere((e) => e.id == entryId && !e.undone);
    if (idx < 0) return false;
    final entry = _logs[idx];
    _huntProvider?.decrementAuto(entry.huntId, delta: entry.delta);
    _logs[idx] = entry.copyWith(undone: true);
    recentLogsNotifier.value = List.unmodifiable(_logs);
    return true;
  }

  void dismissShinyAlert() {
    latestShinyAlertNotifier.value = null;
  }

  Future<void> stopSession({bool stopCoordinatorSource = false}) async {
    _running = false;
    _paused = false;
    isRunningNotifier.value = false;
    isPausedNotifier.value = false;
    _cleanupSubscriptions();
    if (stopCoordinatorSource) {
      await _coordinator?.stop();
    }
    _slots.clear();
    slotStatesNotifier.value = const [];
  }

  void _cleanupSubscriptions() {
    _eventSub?.cancel();
    _cueSub?.cancel();
    _transitionSub?.cancel();
    _eventSub = null;
    _cueSub = null;
    _transitionSub = null;
  }

  void _applyCustomPatternsToCoordinator() {
    final coord = _coordinator;
    if (coord == null) return;
    final combined = <CustomOcrPattern>[
      ...coord.settings.customPatterns,
      ..._settings.buildEngineCustomPatterns(),
    ];
    coord.engine.updateCustomPatterns(combined);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final task = _SerializedAutoTask(action);
    _queue.add(task);
    if (!_drainingQueue) {
      _drainingQueue = true;
      _drainQueue();
    }
    return task.completer.future;
  }

  Future<void> _drainQueue() async {
    try {
      while (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        try {
          await next.action();
          if (!next.completer.isCompleted) {
            next.completer.complete();
          }
        } catch (e, st) {
          if (!next.completer.isCompleted) {
            next.completer.completeError(e, st);
          }
        }
      }
    } finally {
      _drainingQueue = false;
    }
  }

  ShinySlotStateMachine? _resolveSlot(int? instanceIndex) {
    if (instanceIndex != null && _slots.containsKey(instanceIndex)) {
      return _slots[instanceIndex];
    }
    if (instanceIndex == null || instanceIndex == 0) {
      if (_slots.containsKey(1)) return _slots[1];
      if (_slots.isNotEmpty) return _slots.values.first;
    }
    // Dynamically create slot if multi-instance slot ID arrives mid-session
    if (instanceIndex != null && _running) {
      final colorHex = MultiInstanceGridHelper.colorForIndex(
        instanceIndex > 0 ? instanceIndex - 1 : 0,
      );
      final huntId =
          _settings.slotToHuntOverrides[instanceIndex] ?? _defaultHuntId;
      final h = huntId != null ? _huntProvider?.getHuntById(huntId) : null;
      final created = ShinySlotStateMachine(
        slotId: instanceIndex,
        colorHex: colorHex,
        targetPokemonId: h?.pokemonId,
        targetPokemonName: h?.pokemonName,
        assignedHuntId: huntId,
        settings: _settings,
        elapsedClock: _elapsedClock,
      );
      _slots[instanceIndex] = created;
      return created;
    }
    return null;
  }

  Future<void> _processScannerEvent(ScannerEvent event) async {
    if (!_running || _paused) return;
    final slot = _resolveSlot(event.instanceIndex);
    if (slot == null) return;

    final decision = slot.onScannerEvent(event);
    await _applyDecision(slot, decision, sourceEvent: event);
    _publishSlotSnapshots();
  }

  Future<void> _processCueSignal(ScannerCueSignal cue) async {
    if (!_running || _paused) return;
    final slot = _resolveSlot(cue.slotId == 0 ? null : cue.slotId);
    if (slot == null) return;

    bool rearmed = false;
    if (cue.battleCue == BattleCue.battleEnded) {
      rearmed = slot.onBattleCue(cue.battleCue) || rearmed;
    }
    if (cue.resetCue != ResetCue.none) {
      rearmed = slot.onResetCue(cue.resetCue) || rearmed;
    }
    if (cue.rawText.isNotEmpty) {
      rearmed = slot.onRawText(cue.rawText) || rearmed;
    }
    if (rearmed) {
      _coordinator?.clearBattleState(slot.slotId);
      if (cue.slotId == 0) {
        _coordinator?.clearBattleState(0);
      }
    }

    if (cue.eggHatchCue == EggHatchCue.ohPrompt) {
      final decision = slot.onEggHatchCue(cue.eggHatchCue);
      await _applyDecision(slot, decision);
    }
    _publishSlotSnapshots();
  }

  Future<void> _processFrameTransition(FrameTransitionEvent transition) async {
    if (!_running || _paused) return;
    final slot =
        _resolveSlot(transition.slotId == 0 ? null : transition.slotId);
    if (slot == null) return;

    final prevPhase = slot.phase;
    final decision = slot.onFrameTransition(transition);
    if (slot.phase == ShinySlotPhase.rearmPending &&
        prevPhase == ShinySlotPhase.counted) {
      _coordinator?.clearBattleState(slot.slotId);
      if (transition.slotId == 0) {
        _coordinator?.clearBattleState(0);
      }
    }
    await _applyDecision(slot, decision);
    _publishSlotSnapshots();
  }

  Future<void> _applyDecision(
    ShinySlotStateMachine slot,
    ShinyCountDecision decision, {
    ScannerEvent? sourceEvent,
  }) async {
    if (!decision.shouldIncrement || decision.delta <= 0) return;

    final huntId = _settings.slotToHuntOverrides[slot.slotId] ??
        slot.assignedHuntId ??
        _defaultHuntId;
    if (huntId == null || huntId.isEmpty) return;

    final provider = _huntProvider;
    if (provider == null) return;

    final ShinyHunt? hunt = provider.getHuntById(huntId);
    if (hunt == null || hunt.isCompleted) return;

    provider.incrementAuto(huntId, delta: decision.delta);

    _logSequence++;
    final entry = AutoCountLogEntry(
      id: 'auto_${_logSequence}_${slot.slotId}',
      slotId: slot.slotId,
      colorHex: slot.colorHex,
      huntId: huntId,
      pokemonId: decision.pokemonId,
      pokemonName: decision.pokemonName,
      delta: decision.delta,
      reason: decision.reason,
      isShiny: decision.isShiny,
      timestamp: DateTime.now(),
    );
    _logs.insert(0, entry);
    if (_logs.length > maxLogEntries) {
      _logs.removeRange(maxLogEntries, _logs.length);
    }
    recentLogsNotifier.value = List.unmodifiable(_logs);

    if (decision.isShiny) {
      latestShinyAlertNotifier.value = entry;
      await _triggerFeedback(entry, isShiny: true, sourceEvent: sourceEvent);
    } else {
      await _triggerFeedback(entry, isShiny: false, sourceEvent: sourceEvent);
    }
  }

  Future<void> _triggerFeedback(
    AutoCountLogEntry entry, {
    required bool isShiny,
    ScannerEvent? sourceEvent,
  }) async {
    final playSound =
        isShiny ? _settings.playSoundOnShiny : _settings.playSoundOnCount;
    final playHaptic =
        isShiny ? _settings.playHapticOnShiny : _settings.playHapticOnCount;

    if (playHaptic) {
      try {
        unawaited(
          (isShiny
                  ? HapticFeedback.heavyImpact()
                  : HapticFeedback.selectionClick())
              .catchError((_) {}),
        );
      } catch (_) {}
    }

    if (playSound) {
      final ev = sourceEvent ??
          ScannerEvent(
            type: isShiny
                ? ScannerEventType.shinyDetected
                : ScannerEventType.encounter,
            pokemonId: entry.pokemonId,
            rawText: entry.reason,
            matchedName: entry.pokemonName ?? entry.reason,
            isShiny: isShiny,
            timestamp: entry.timestamp,
            instanceIndex: entry.slotId,
          );
      if (isShiny) {
        await _feedback?.onShiny(ev);
      } else {
        await _feedback?.onEncounter(ev);
      }
    }
  }

  void _publishSlotSnapshots() {
    final list = _slots.values
        .map((s) => s.toSnapshot(fallbackHuntId: _defaultHuntId))
        .toList()
      ..sort((a, b) => a.slotId.compareTo(b.slotId));
    slotStatesNotifier.value = List.unmodifiable(list);
  }
}

class _SerializedAutoTask {
  final Future<void> Function() action;
  final Completer<void> completer = Completer<void>();
  _SerializedAutoTask(this.action);
}
