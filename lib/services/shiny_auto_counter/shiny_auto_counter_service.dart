import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/shiny_hunt.dart';
import '../../providers/shiny_hunt_provider.dart';
import '../scanner_core/engine/ocr_detection_engine.dart';
import '../scanner_core/feedback/scanner_feedback.dart';
import '../scanner_core/media/frame_transition_detector.dart';
import '../scanner_core/media/visual_shiny_detector.dart';
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
  final ShinyDetectionSource? detectionSource;
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
    this.detectionSource,
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
        detectionSource: detectionSource,
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
  StreamSubscription<SlotVisualFrame>? _visualFrameSub;

  final SparkleDelayDetector _sparkleDelayDetector = SparkleDelayDetector();
  final VisualShinyColorDetector _colorDetector = VisualShinyColorDetector();
  final Map<
      int,
      ({
        String speciesKey,
        int? pokemonId,
        String? pokemonName,
        Duration sampleAfter,
      })> _pendingColorSampleBySlot = {};

  final Map<int, ShinySlotStateMachine> _slots = {};
  final Map<int, Timer> _rearmTimers = {};
  final List<AutoCountLogEntry> _logs = [];
  final List<AutoCountLogEntry> _activeShinyAlerts = [];
  int _logSequence = 0;
  int _sessionGeneration = 0;

  // Serialized FIFO queue for zero race conditions across N concurrent slots.
  final Queue<_SerializedAutoTask> _queue = Queue();
  bool _drainingQueue = false;
  bool _running = false;
  bool _paused = false;
  bool _syncingProvider = false;
  bool _settingsLoaded = false;
  Future<void>? _settingsLoadFuture;
  _PendingAutoCounterSession? _pendingSession;

  @visibleForTesting
  bool hasPendingRearmTimer(int slotId) => _rearmTimers.containsKey(slotId);

  final ValueNotifier<bool> isRunningNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> hasPendingSessionNotifier = ValueNotifier(false);
  final ValueNotifier<List<ShinySlotSnapshot>> slotStatesNotifier =
      ValueNotifier(const []);
  final ValueNotifier<List<AutoCountLogEntry>> recentLogsNotifier =
      ValueNotifier(const []);
  final ValueNotifier<AutoCountLogEntry?> latestShinyAlertNotifier =
      ValueNotifier(null);
  final ValueNotifier<List<AutoCountLogEntry>> activeShinyAlertsNotifier =
      ValueNotifier(const []);
  final ValueNotifier<ShinyAutoCounterSettings> settingsNotifier =
      ValueNotifier(const ShinyAutoCounterSettings());

  final Stopwatch _fallbackClock = Stopwatch()..start();
  Duration get _nowElapsed => _elapsedClock?.call() ?? _fallbackClock.elapsed;

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

  /// Ensures persisted auto-counter settings are loaded once before reading or merging rules.
  Future<void> ensureSettingsLoaded() {
    if (_settingsLoaded) return Future.value();
    final existing = _settingsLoadFuture;
    if (existing != null) return existing;
    final future = () async {
      try {
        final loaded = await ShinyAutoCounterSettings.loadFromPrefs();
        if (_settingsLoaded) return;
        _settingsLoaded = true;
        if (loaded != null && !_running) {
          _settings = _huntProvider != null
              ? _pruneStaleOverrides(loaded, _huntProvider!)
              : loaded;
          settingsNotifier.value = _settings;
        }
      } finally {
        _settingsLoadFuture = null;
      }
    }();
    _settingsLoadFuture = future;
    return future;
  }

  /// Arms a pending session that automatically attaches as soon as a desktop or mobile
  /// scanner coordinator starts tracking.
  void armPendingSession({
    required ShinyHuntProvider huntProvider,
    required String defaultHuntId,
    required ShinyAutoCounterSettings settings,
  }) {
    _pendingSession = _PendingAutoCounterSession(
      huntProvider: huntProvider,
      defaultHuntId: defaultHuntId,
      settings: settings,
    );
    hasPendingSessionNotifier.value = true;
  }

  /// Cancels any pending auto-connect session.
  void cancelPendingSession() {
    _pendingSession = null;
    hasPendingSessionNotifier.value = false;
  }

  /// Attaches a pending session to the newly started [coordinator] & [source], if armed.
  bool attachIfPending({
    required ScannerCoordinator coordinator,
    ScannerSource? source,
    List<int> slotIds = const [1],
    Map<int, int>? slotColorOverrides,
  }) {
    final pending = _pendingSession;
    if (pending == null) return false;
    _pendingSession = null;
    hasPendingSessionNotifier.value = false;
    startSession(
      huntProvider: pending.huntProvider,
      coordinator: coordinator,
      source: source,
      defaultHuntId: pending.defaultHuntId,
      slotIds: slotIds,
      slotColorOverrides: slotColorOverrides,
      settings: pending.settings,
    );
    return true;
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
    _sessionGeneration++;
    _pendingSession = null;
    hasPendingSessionNotifier.value = false;
    _cancelAllRearmTimers();
    _cleanupSubscriptions();
    _huntProvider?.setAutoCounterActiveHunts(
      const {},
      isRunningAndUnpaused: false,
    );
    _huntProvider?.removeListener(_onHuntProviderChanged);

    final prevCoord = _coordinator;
    if (prevCoord != null && !identical(prevCoord, coordinator)) {
      prevCoord.setOverlayCustomPatterns(const []);
      prevCoord.setSlotCustomPatternFilter(null);
      prevCoord.setSuppressEncounterFeedback(false);
    }

    _huntProvider = huntProvider;
    _coordinator = coordinator;
    _source = source;
    _defaultHuntId = defaultHuntId;

    final hunt = huntProvider.getHuntById(defaultHuntId);
    final rawSettings = settings ??
        (_settingsLoaded
            ? _settings
            : (hunt != null
                ? ShinyAutoCounterSettings.forHuntMethod(hunt.method)
                : const ShinyAutoCounterSettings()));
    _settings = _pruneStaleOverrides(rawSettings, huntProvider);
    _settingsLoaded = true;
    settingsNotifier.value = _settings;

    coordinator.setSuppressEncounterFeedback(true);
    _applyCustomPatternsToCoordinator();
    huntProvider.addListener(_onHuntProviderChanged);

    _slots.clear();
    _logs.clear();
    recentLogsNotifier.value = const [];
    final effectiveSlotIds = slotIds.isEmpty ? const [1] : slotIds;
    for (int i = 0; i < effectiveSlotIds.length; i++) {
      final sid = effectiveSlotIds[i];
      final colorHex = slotColorOverrides?[sid] ??
          MultiInstanceGridHelper.colorForIndex(sid > 0 ? sid - 1 : i);
      final targetHuntId =
          _settings.slotToHuntOverrides[sid] ?? defaultHuntId;
      final targetHunt = huntProvider.getHuntById(targetHuntId);
      final effectiveSettings = _settings.resolveForHunt(
        huntId: targetHuntId,
        huntMethod: targetHunt?.method,
      );

      _slots[sid] = ShinySlotStateMachine(
        slotId: sid,
        colorHex: colorHex,
        targetPokemonId: targetHunt?.pokemonId,
        targetPokemonName: targetHunt?.pokemonName,
        assignedHuntId: targetHuntId,
        settings: effectiveSettings,
        elapsedClock: _elapsedClock,
      )..setHasExplicitHuntOverride(
          _settings.huntSettingsOverrides.containsKey(targetHuntId),
        );
    }
    _syncSourceTransitionConfig();

    _eventSub = coordinator.events.listen(
      (event) {
        _enqueue(() => _processScannerEvent(event));
      },
      onDone: () => onSourceStopped(coordinator),
    );
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
    _sparkleDelayDetector.reset();
    _colorDetector.reset();
    _pendingColorSampleBySlot.clear();
    _activeShinyAlerts.clear();
    activeShinyAlertsNotifier.value = const [];
    isRunningNotifier.value = true;
    isPausedNotifier.value = false;
    latestShinyAlertNotifier.value = null;
    _syncVisualFrameSubscription();
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  void _syncProviderActiveAutoHunts() {
    final provider = _huntProvider;
    if (provider == null) return;
    if (!_running) {
      provider.setAutoCounterActiveHunts(
        const {},
        isRunningAndUnpaused: false,
      );
      return;
    }
    final activeIds = <String>{};
    for (final slot in _slots.values) {
      if (slot.phase == ShinySlotPhase.pausedManual ||
          slot.phase == ShinySlotPhase.pausedByShiny) {
        continue;
      }
      final hid = _settings.slotToHuntOverrides[slot.slotId] ??
          slot.assignedHuntId ??
          _defaultHuntId;
      if (hid != null && hid.isNotEmpty) {
        activeIds.add(hid);
      }
    }
    provider.setAutoCounterActiveHunts(
      activeIds,
      isRunningAndUnpaused: _running && !_paused,
    );
  }

  void setDefaultHuntId(String huntId) {
    final prevDefault = _defaultHuntId;
    _defaultHuntId = huntId;
    for (final slot in _slots.values) {
      if (!_settings.slotToHuntOverrides.containsKey(slot.slotId)) {
        final h = _huntProvider?.getHuntById(huntId);
        final changedHunt = prevDefault != huntId ||
            slot.assignedHuntId != huntId ||
            slot.targetPokemonId != h?.pokemonId;
        slot.updateSettings(
          _settings.resolveForHunt(huntId: huntId, huntMethod: h?.method),
        );
        slot.setHasExplicitHuntOverride(
          _settings.huntSettingsOverrides.containsKey(huntId),
        );
        slot.updateTarget(
          pokemonId: h?.pokemonId,
          pokemonName: h?.pokemonName,
          huntId: huntId,
        );
        if (changedHunt) {
          _resetSlotForHuntChange(slot);
        }
      }
    }
    _syncSourceTransitionConfig();
    _syncVisualFrameSubscription();
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  void _resetSlotForHuntChange(ShinySlotStateMachine slot) {
    _cancelRearmTimer(slot.slotId);
    _clearCoordinatorBattleState(slot.slotId);
    _sparkleDelayDetector.reset(slot.slotId);
    _colorDetector.reset(slot.slotId);
    _pendingColorSampleBySlot.remove(slot.slotId);
    _removeShinyAlertForSlot(slot.slotId);
    if (slot.phase != ShinySlotPhase.pausedManual) {
      slot.forceRearm();
    }
  }

  /// Resolves the effective auto-counter settings for a specific [hunt].
  ShinyAutoCounterSettings settingsForHunt(ShinyHunt hunt) {
    return _settings.resolveForHunt(huntId: hunt.id, huntMethod: hunt.method);
  }

  /// Stores or updates a per-hunt auto-counter rule override and applies it
  /// immediately to all slots assigned to [huntId].
  void updateHuntSettings(String huntId, ShinyAutoCounterSettings huntRule) {
    final cleanedRule = huntRule.copyWith(huntSettingsOverrides: const {});
    if (!_settingsLoaded) {
      unawaited(() async {
        await ensureSettingsLoaded();
        updateHuntSettings(huntId, cleanedRule);
      }());
      final nextOverrides = Map<String, ShinyAutoCounterSettings>.from(
        _settings.huntSettingsOverrides,
      );
      nextOverrides[huntId] = cleanedRule;
      updateSettings(_settings.copyWith(huntSettingsOverrides: nextOverrides));
      return;
    }
    final nextOverrides =
        Map<String, ShinyAutoCounterSettings>.from(_settings.huntSettingsOverrides);
    nextOverrides[huntId] = cleanedRule;
    final updated = _settings.copyWith(huntSettingsOverrides: nextOverrides);
    updateSettings(updated);
    unawaited(ShinyAutoCounterSettings.saveToPrefs(updated));
  }

  void updateSettings(ShinyAutoCounterSettings next) {
    final pruned = _huntProvider != null
        ? _pruneStaleOverrides(next, _huntProvider!)
        : next;
    _settings = pruned;
    settingsNotifier.value = pruned;
    _applyCustomPatternsToCoordinator();

    for (final slot in _slots.values) {
      final assigned = pruned.slotToHuntOverrides[slot.slotId] ?? _defaultHuntId;
      final h = assigned != null ? _huntProvider?.getHuntById(assigned) : null;
      final changedTarget = slot.assignedHuntId != assigned ||
          slot.targetPokemonId != h?.pokemonId ||
          slot.targetPokemonName != h?.pokemonName;
      slot.updateSettings(
        pruned.resolveForHunt(huntId: assigned, huntMethod: h?.method),
      );
      slot.setHasExplicitHuntOverride(
        assigned != null && pruned.huntSettingsOverrides.containsKey(assigned),
      );
      slot.updateTarget(
        pokemonId: h?.pokemonId,
        pokemonName: h?.pokemonName,
        huntId: assigned,
      );
      if (changedTarget) {
        _resetSlotForHuntChange(slot);
      }
    }
    _syncSourceTransitionConfig();
    _syncVisualFrameSubscription();
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  /// Rebinds the active [ScannerSource] live (e.g., when switching Window <-> Webcam)
  /// without tearing down the running auto-counter session.
  Future<void> rebindSource(
    ScannerSource? source, {
    List<int>? slotIds,
    Map<int, int>? slotColorOverrides,
  }) async {
    if (!_running) return;
    final gen = _sessionGeneration;
    final oldTransitionSub = _transitionSub;
    final oldVisualSub = _visualFrameSub;
    _transitionSub = null;
    _visualFrameSub = null;
    _source = source;
    if (source is FrameTransitionScannerSource) {
      _transitionSub = source.transitionStream.listen((transition) {
        _enqueue(() => _processFrameTransition(transition));
      });
    }
    if (slotIds != null) {
      syncSlots(slotIds: slotIds, slotColorOverrides: slotColorOverrides);
    } else {
      _syncSourceTransitionConfig();
      _syncVisualFrameSubscription();
      _publishSlotSnapshots();
    }
    await oldTransitionSub?.cancel();
    await oldVisualSub?.cancel();
    if (gen != _sessionGeneration || !_running) return;
  }

  /// Synchronizes live multi-instance slot additions and removals during an active session,
  /// preserving phase and session count for existing slots.
  void syncSlots({
    required List<int> slotIds,
    Map<int, int>? slotColorOverrides,
  }) {
    if (!_running) return;
    final effectiveIds = (slotIds.isEmpty ? const [1] : slotIds).toSet();

    for (final sid in _slots.keys.toList()) {
      if (!effectiveIds.contains(sid)) {
        _cancelRearmTimer(sid);
        _slots.remove(sid);
        _pendingColorSampleBySlot.remove(sid);
        _sparkleDelayDetector.reset(sid);
        _colorDetector.reset(sid);
        _removeShinyAlertForSlot(sid);
      }
    }

    for (final sid in effectiveIds) {
      if (!_slots.containsKey(sid)) {
        final colorHex = slotColorOverrides?[sid] ??
            MultiInstanceGridHelper.colorForIndex(sid > 0 ? sid - 1 : 0);
        final huntId = _settings.slotToHuntOverrides[sid] ?? _defaultHuntId;
        final h = huntId != null ? _huntProvider?.getHuntById(huntId) : null;
        _slots[sid] = ShinySlotStateMachine(
          slotId: sid,
          colorHex: colorHex,
          targetPokemonId: h?.pokemonId,
          targetPokemonName: h?.pokemonName,
          assignedHuntId: huntId,
          settings: _settings.resolveForHunt(
            huntId: huntId,
            huntMethod: h?.method,
          ),
          elapsedClock: _elapsedClock,
        )..setHasExplicitHuntOverride(
            huntId != null && _settings.huntSettingsOverrides.containsKey(huntId),
          );
      }
    }

    _syncSourceTransitionConfig();
    _syncVisualFrameSubscription();
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  void assignSlotToHunt(int slotId, String? huntId) {
    if (!_settingsLoaded) {
      unawaited(() async {
        await ensureSettingsLoaded();
        assignSlotToHunt(slotId, huntId);
      }());
    }
    final nextOverrides = Map<int, String>.from(_settings.slotToHuntOverrides);
    if (huntId == null || huntId.isEmpty) {
      nextOverrides.remove(slotId);
    } else {
      nextOverrides[slotId] = huntId;
    }
    final updated = _settings.copyWith(slotToHuntOverrides: nextOverrides);
    updateSettings(updated);
    if (_settingsLoaded) {
      unawaited(ShinyAutoCounterSettings.saveToPrefs(updated));
    }
  }

  void toggleGlobalPause() {
    setGlobalPause(!_paused);
  }

  void setGlobalPause(bool paused) {
    _paused = paused;
    if (paused) {
      _sparkleDelayDetector.reset();
      _pendingColorSampleBySlot.clear();
    }
    isPausedNotifier.value = _paused;
    _syncProviderActiveAutoHunts();
  }

  void togglePauseSlot(int slotId) {
    final slot = _slots[slotId];
    if (slot == null) return;
    if (slot.phase == ShinySlotPhase.pausedByShiny) {
      resumeShinyPausedSlot(slotId);
      return;
    } else {
      final nextPaused = slot.phase != ShinySlotPhase.pausedManual;
      if (nextPaused) {
        _cancelRearmTimer(slotId);
        _sparkleDelayDetector.clearPendingEncounter(slotId);
        _pendingColorSampleBySlot.remove(slotId);
      }
      slot.setManualPaused(nextPaused);
    }
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  void _recordShinyAlert(AutoCountLogEntry entry) {
    _activeShinyAlerts.removeWhere((e) => e.slotId == entry.slotId);
    _activeShinyAlerts.insert(0, entry);
    activeShinyAlertsNotifier.value = List.unmodifiable(_activeShinyAlerts);
    latestShinyAlertNotifier.value = entry;
  }

  void _removeShinyAlertForSlot(int slotId) {
    _activeShinyAlerts.removeWhere((e) => e.slotId == slotId);
    activeShinyAlertsNotifier.value = List.unmodifiable(_activeShinyAlerts);
    latestShinyAlertNotifier.value =
        _activeShinyAlerts.isNotEmpty ? _activeShinyAlerts.first : null;
  }

  void resumeShinyPausedSlot(int slotId) {
    final slot = _slots[slotId];
    if (slot == null) return;
    _cancelRearmTimer(slotId);
    slot.resumeFromShinyPause();
    _clearCoordinatorBattleState(slotId);
    _pendingColorSampleBySlot.remove(slotId);
    _sparkleDelayDetector.reset(slotId);
    _colorDetector.reset(slotId);
    _removeShinyAlertForSlot(slotId);

    // Ensure any remaining pausedByShiny slot without a log entry still surfaces
    if (_activeShinyAlerts.isEmpty) {
      final remainingShiny = _slots.values
          .where((s) => s.phase == ShinySlotPhase.pausedByShiny)
          .toList()
        ..sort((a, b) => a.slotId.compareTo(b.slotId));
      if (remainingShiny.isNotEmpty) {
        final nextSlot = remainingShiny.first;
        final matchingLog = _logs.cast<AutoCountLogEntry?>().firstWhere(
              (e) =>
                  e != null &&
                  e.slotId == nextSlot.slotId &&
                  e.isShiny &&
                  !e.undone,
              orElse: () => null,
            );
        _recordShinyAlert(
          matchingLog ??
              AutoCountLogEntry(
                id: 'shiny_slot_${nextSlot.slotId}',
                slotId: nextSlot.slotId,
                colorHex: nextSlot.colorHex,
                huntId: nextSlot.assignedHuntId ?? _defaultHuntId ?? '',
                pokemonId: nextSlot.targetPokemonId,
                pokemonName: nextSlot.targetPokemonName,
                delta: 0,
                reason: 'shiny:${nextSlot.targetPokemonName ?? ''}',
                isShiny: true,
                detectionSource: ShinyDetectionSource.ocrText,
                timestamp: DateTime.now(),
              ),
        );
      }
    }
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  void rearmSlot(int slotId) {
    final slot = _slots[slotId];
    if (slot == null) return;
    _cancelRearmTimer(slotId);
    slot.forceRearm();
    _clearCoordinatorBattleState(slotId);
    _pendingColorSampleBySlot.remove(slotId);
    _sparkleDelayDetector.clearPendingEncounter(slotId);
    _removeShinyAlertForSlot(slotId);
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  /// Re-arms all active/counted/manual-paused slots, preserving any slots paused by a Shiny hit.
  void rearmAllSlots() {
    for (final slot in _slots.values) {
      if (slot.phase == ShinySlotPhase.pausedByShiny) continue;
      _cancelRearmTimer(slot.slotId);
      slot.forceRearm();
      _clearCoordinatorBattleState(slot.slotId);
      _pendingColorSampleBySlot.remove(slot.slotId);
      _sparkleDelayDetector.clearPendingEncounter(slot.slotId);
    }
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
  }

  /// Called when an upstream tracker/coordinator stops so no zombie auto-counter session remains active.
  void onSourceStopped(ScannerCoordinator? stoppedCoordinator) {
    if (!_running) return;
    if (stoppedCoordinator != null &&
        !identical(_coordinator, stoppedCoordinator)) {
      return;
    }
    unawaited(stopSession());
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
    final idx = _logs.indexWhere((e) => !e.undone && e.delta > 0);
    if (idx < 0) return false;
    return undoEntry(_logs[idx].id);
  }

  /// Undoes a specific log entry by [entryId], subtracting its exact delta,
  /// updating the slot session counter, and re-arming only when safe.
  bool undoEntry(String entryId) {
    final idx = _logs.indexWhere((e) => e.id == entryId && !e.undone);
    if (idx < 0) return false;
    final entry = _logs[idx];
    if (entry.delta > 0) {
      _huntProvider?.decrementAuto(entry.huntId, delta: entry.delta);
    }

    final slot = _slots[entry.slotId];
    final latestSlotIdx =
        _logs.indexWhere((e) => e.slotId == entry.slotId && !e.undone);
    final isLatestForSlot = latestSlotIdx == idx;
    final preservePause = slot != null &&
        (slot.phase == ShinySlotPhase.pausedManual ||
            (slot.phase == ShinySlotPhase.pausedByShiny &&
                (!isLatestForSlot || !entry.isShiny)));
    final canRearmActiveSlot = isLatestForSlot && !preservePause;

    if (canRearmActiveSlot) {
      _cancelRearmTimer(entry.slotId);
      _clearCoordinatorBattleState(entry.slotId);
      _pendingColorSampleBySlot.remove(entry.slotId);
      _sparkleDelayDetector.clearPendingEncounter(entry.slotId);
    }
    slot?.recordUndo(
      entry.delta,
      preservePause: preservePause,
      allowRearm: isLatestForSlot,
    );
    if (entry.isShiny && canRearmActiveSlot) {
      _removeShinyAlertForSlot(entry.slotId);
    }
    _logs[idx] = entry.copyWith(undone: true);
    recentLogsNotifier.value = List.unmodifiable(_logs);
    _syncProviderActiveAutoHunts();
    _publishSlotSnapshots();
    return true;
  }

  void dismissShinyAlert([int? slotId]) {
    if (slotId != null) {
      _removeShinyAlertForSlot(slotId);
      return;
    }
    _activeShinyAlerts.clear();
    activeShinyAlertsNotifier.value = const [];
    latestShinyAlertNotifier.value = null;
  }

  Future<void> stopSession({bool stopCoordinatorSource = false}) async {
    final gen = ++_sessionGeneration;
    _running = false;
    _paused = false;
    isRunningNotifier.value = false;
    isPausedNotifier.value = false;
    _cancelAllRearmTimers();
    _cleanupSubscriptions();
    _huntProvider?.setAutoCounterActiveHunts(
      const {},
      isRunningAndUnpaused: false,
    );
    _huntProvider?.removeListener(_onHuntProviderChanged);

    final coord = _coordinator;
    if (coord != null) {
      coord.setOverlayCustomPatterns(const []);
      coord.setSlotCustomPatternFilter(null);
      coord.setSuppressEncounterFeedback(false);
    }
    _coordinator = null;
    _source = null;
    _huntProvider = null;
    _slots.clear();
    _pendingColorSampleBySlot.clear();
    _sparkleDelayDetector.reset();
    _colorDetector.reset();
    _activeShinyAlerts.clear();
    activeShinyAlertsNotifier.value = const [];
    latestShinyAlertNotifier.value = null;
    slotStatesNotifier.value = const [];

    if (coord != null && stopCoordinatorSource) {
      await coord.stop();
      if (gen != _sessionGeneration) return;
    }
  }

  void _syncVisualFrameSubscription() {
    final src = _source;
    final shouldListen =
        _running &&
        src is VisualFrameScannerSource &&
        (_settings.anyColorDeviationEnabled ||
            _slots.values.any((s) => s.settings.enableColorDeviationShinyCheck));
    if (!shouldListen) {
      _visualFrameSub?.cancel();
      _visualFrameSub = null;
      return;
    }
    if (_visualFrameSub != null) return;
    _visualFrameSub = src.visualFrameStream.listen((vf) {
      if (_pendingColorSampleBySlot.isEmpty) return;
      _enqueue(() => _processVisualFrame(vf));
    });
  }

  void _cleanupSubscriptions() {
    _eventSub?.cancel();
    _cueSub?.cancel();
    _transitionSub?.cancel();
    _visualFrameSub?.cancel();
    _eventSub = null;
    _cueSub = null;
    _transitionSub = null;
    _visualFrameSub = null;
  }

  void _clearCoordinatorBattleState(int slotId) {
    _coordinator?.clearBattleState(slotId);
    if (_slots.length <= 1 || slotId == 1) {
      _coordinator?.clearBattleState(0);
    }
  }

  void _cancelRearmTimer(int slotId) {
    _rearmTimers.remove(slotId)?.cancel();
  }

  void _cancelAllRearmTimers() {
    for (final timer in _rearmTimers.values) {
      timer.cancel();
    }
    _rearmTimers.clear();
  }

  void _scheduleRearmTimer(ShinySlotStateMachine slot) {
    _cancelRearmTimer(slot.slotId);
    if (_elapsedClock != null) return;
    if (slot.phase == ShinySlotPhase.counted &&
        slot.settings.detectionMode == ShinyHuntDetectionMode.eggHatch) {
      _rearmTimers[slot.slotId] = Timer(
        const Duration(seconds: 18, milliseconds: 50),
        () {
          _rearmTimers.remove(slot.slotId);
          if (!_running || !identical(_slots[slot.slotId], slot)) return;
          if (slot.checkRearmReady()) {
            _clearCoordinatorBattleState(slot.slotId);
            _publishSlotSnapshots();
          } else if (slot.phase == ShinySlotPhase.counted &&
              slot.settings.detectionMode == ShinyHuntDetectionMode.eggHatch) {
            _scheduleRearmTimer(slot);
          }
        },
      );
      return;
    }
    if (slot.phase != ShinySlotPhase.rearmPending) return;
    final remaining = slot.remainingRearmDuration ??
        Duration(milliseconds: slot.settings.minResetCooldownMs);
    final delay = remaining <= Duration.zero
        ? const Duration(milliseconds: 5)
        : remaining + const Duration(milliseconds: 5);
    _rearmTimers[slot.slotId] = Timer(delay, () {
      _rearmTimers.remove(slot.slotId);
      if (!_running || !identical(_slots[slot.slotId], slot)) return;
      if (slot.checkRearmReady()) {
        _clearCoordinatorBattleState(slot.slotId);
        _publishSlotSnapshots();
      } else if (slot.phase == ShinySlotPhase.rearmPending) {
        _scheduleRearmTimer(slot);
      }
    });
  }

  void _syncSourceTransitionConfig() {
    final src = _source;
    if (src is FrameTransitionScannerSource) {
      src.updateTransitionMinDuration(
        Duration(milliseconds: _settings.transitionMinDurationMs),
      );
      src.updateTransitionThresholds(
        blackThreshold: _settings.blackLumaThreshold,
        whiteThreshold: _settings.whiteLumaThreshold,
      );
      final slotConfigs = <int, SlotTransitionConfig>{};
      for (final slot in _slots.values) {
        final cfg = SlotTransitionConfig(
          blackThreshold: slot.settings.blackLumaThreshold,
          whiteThreshold: slot.settings.whiteLumaThreshold,
          minTransitionDuration:
              Duration(milliseconds: slot.settings.transitionMinDurationMs),
        );
        slotConfigs[slot.slotId] = cfg;
        if (slot.slotId == 1 || _slots.length == 1) {
          slotConfigs[0] = cfg;
        }
      }
      src.updateSlotTransitionConfigs(slotConfigs);
    }
  }

  ShinyAutoCounterSettings _pruneStaleOverrides(
    ShinyAutoCounterSettings settings,
    ShinyHuntProvider provider,
  ) {
    if (provider.isLoading) return settings;
    final validIds = provider.hunts.map((h) => h.id).toSet();
    final nextSlotOverrides = <int, String>{};
    bool changed = false;
    for (final entry in settings.slotToHuntOverrides.entries) {
      if (validIds.contains(entry.value)) {
        nextSlotOverrides[entry.key] = entry.value;
      } else {
        changed = true;
      }
    }
    final nextHuntOverrides = <String, ShinyAutoCounterSettings>{};
    for (final entry in settings.huntSettingsOverrides.entries) {
      if (validIds.contains(entry.key)) {
        nextHuntOverrides[entry.key] = entry.value;
      } else {
        changed = true;
      }
    }
    if (!changed) return settings;
    return settings.copyWith(
      slotToHuntOverrides: nextSlotOverrides,
      huntSettingsOverrides: nextHuntOverrides,
    );
  }

  void _onHuntProviderChanged() {
    final provider = _huntProvider;
    if (!_running || provider == null || _syncingProvider || provider.isLoading) {
      return;
    }
    _syncingProvider = true;
    try {
      final pruned = _pruneStaleOverrides(_settings, provider);
      if (!identical(pruned, _settings)) {
        updateSettings(pruned);
        unawaited(ShinyAutoCounterSettings.saveToPrefs(pruned));
        return;
      }

      bool slotsChanged = false;
      for (final slot in _slots.values) {
        final assigned =
            _settings.slotToHuntOverrides[slot.slotId] ?? _defaultHuntId;
        final h = assigned != null ? provider.getHuntById(assigned) : null;
        final huntGoneOrCompleted = h == null || h.isCompleted;
        final targetChanged = slot.targetPokemonId != h?.pokemonId ||
            slot.targetPokemonName != h?.pokemonName ||
            slot.assignedHuntId != assigned;
        if (targetChanged ||
            (huntGoneOrCompleted &&
                (slot.phase == ShinySlotPhase.pausedByShiny ||
                    slot.phase == ShinySlotPhase.counted ||
                    slot.phase == ShinySlotPhase.rearmPending))) {
          slot.updateTarget(
            pokemonId: h?.pokemonId,
            pokemonName: h?.pokemonName,
            huntId: assigned,
          );
          _resetSlotForHuntChange(slot);
          slotsChanged = true;
        }
        final hasOverride =
            assigned != null && _settings.huntSettingsOverrides.containsKey(assigned);
        if (slot.hasExplicitHuntOverride != hasOverride) {
          slot.setHasExplicitHuntOverride(hasOverride);
          slotsChanged = true;
        }
        final resolved =
            _settings.resolveForHunt(huntId: assigned, huntMethod: h?.method);
        if (slot.settings.detectionMode != resolved.detectionMode ||
            slot.settings.matchFilter != resolved.matchFilter) {
          slot.updateSettings(resolved);
          slotsChanged = true;
        }
      }
      if (slotsChanged) {
        _syncSourceTransitionConfig();
        _syncVisualFrameSubscription();
        _syncProviderActiveAutoHunts();
        _publishSlotSnapshots();
      }
    } finally {
      _syncingProvider = false;
    }
  }

  bool _patternBelongsToSlotFilter(int slotId, String patternId) {
    final slot = _slots[slotId] ??
        (slotId == 0 ? (_slots[1] ?? _slots.values.firstOrNull) : null);
    if (slot == null) return true;
    if (patternId.startsWith('shiny_base:')) {
      return !slot.hasExplicitHuntOverride;
    }
    if (!patternId.startsWith('shiny_hunt:')) {
      return true;
    }
    final rest = patternId.substring('shiny_hunt:'.length);
    final sepIdx = rest.indexOf(':');
    if (sepIdx <= 0) return true;
    final huntScopeId = rest.substring(0, sepIdx);
    return slot.assignedHuntId == huntScopeId;
  }

  void _applyCustomPatternsToCoordinator() {
    final coord = _coordinator;
    if (coord == null) return;
    coord.setOverlayCustomPatterns(_settings.buildEngineCustomPatterns());
    coord.setSlotCustomPatternFilter(_patternBelongsToSlotFilter);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final gen = _sessionGeneration;
    final task = _SerializedAutoTask(() async {
      if (gen != _sessionGeneration) return;
      await action();
    });
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
        final next = _queue.removeFirst();
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

  bool _isSlotHuntActive(ShinySlotStateMachine slot) {
    final huntId = _settings.slotToHuntOverrides[slot.slotId] ??
        slot.assignedHuntId ??
        _defaultHuntId;
    if (huntId == null || huntId.isEmpty) return false;
    final hunt = _huntProvider?.getHuntById(huntId);
    return hunt != null && !hunt.isCompleted && !hunt.isPaused;
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
        settings: _settings.resolveForHunt(
          huntId: huntId,
          huntMethod: h?.method,
        ),
        elapsedClock: _elapsedClock,
      )..setHasExplicitHuntOverride(
          huntId != null && _settings.huntSettingsOverrides.containsKey(huntId),
        );
      _slots[instanceIndex] = created;
      _syncSourceTransitionConfig();
      _syncVisualFrameSubscription();
      _syncProviderActiveAutoHunts();
      return created;
    }
    return null;
  }

  Future<void> _processScannerEvent(ScannerEvent event) async {
    if (!_running || _paused) return;
    final slot = _resolveSlot(event.instanceIndex);
    if (slot == null || !_isSlotHuntActive(slot)) return;

    final prevPhase = slot.phase;
    final decision = slot.onScannerEvent(event);
    if (prevPhase == ShinySlotPhase.rearmPending &&
        slot.phase == ShinySlotPhase.rearmPending &&
        decision.reason == 'slot_not_armed') {
      // Early OCR arrived before cooldown finished; clear coordinator battle state
      // so this encounter is not swallowed once cooldown expires.
      _clearCoordinatorBattleState(slot.slotId);
    }
    if (slot.phase == ShinySlotPhase.rearmPending) {
      if (!(decision.shouldIncrement &&
          slot.settings.detectionMode == ShinyHuntDetectionMode.eggHatch)) {
        _pendingColorSampleBySlot.remove(slot.slotId);
        _sparkleDelayDetector.clearPendingEncounter(slot.slotId);
      }
      if (prevPhase == ShinySlotPhase.counted) {
        _clearCoordinatorBattleState(slot.slotId);
      }
      _scheduleRearmTimer(slot);
    } else if (slot.phase == ShinySlotPhase.pausedByShiny) {
      _cancelRearmTimer(slot.slotId);
      _sparkleDelayDetector.clearPendingEncounter(slot.slotId);
      _syncProviderActiveAutoHunts();
    } else if (slot.phase != ShinySlotPhase.rearmPending &&
        !(slot.phase == ShinySlotPhase.counted &&
            slot.settings.detectionMode == ShinyHuntDetectionMode.eggHatch)) {
      _cancelRearmTimer(slot.slotId);
    }
    await _applyDecision(slot, decision, sourceEvent: event);
    _publishSlotSnapshots();
  }

  Future<void> _processCueSignal(ScannerCueSignal cue) async {
    if (!_running || _paused) return;
    final slot = _resolveSlot(cue.slotId == 0 ? null : cue.slotId);
    if (slot == null || !_isSlotHuntActive(slot)) return;

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
      _pendingColorSampleBySlot.remove(slot.slotId);
      _sparkleDelayDetector.clearPendingEncounter(slot.slotId);
      _clearCoordinatorBattleState(slot.slotId);
      if (cue.slotId == 0) {
        _coordinator?.clearBattleState(0);
      }
    }
    if (slot.phase == ShinySlotPhase.rearmPending &&
        (rearmed || !hasPendingRearmTimer(slot.slotId))) {
      _scheduleRearmTimer(slot);
    }

    if (cue.battleCue == BattleCue.battleMenu &&
        slot.settings.enableSparkleDelayShinyCheck &&
        slot.canEvaluateVisualShiny) {
      final signal = _sparkleDelayDetector.onBattleMenuSeen(
        slot.slotId,
        _nowElapsed,
        delayThresholdMs: slot.settings.sparkleDelayThresholdMs,
      );
      if (signal != null) {
        final decision = slot.onVisualShinySignal(signal);
        await _applyDecision(
          slot,
          decision,
          detectionSource: signal.source,
        );
        if (slot.phase == ShinySlotPhase.pausedByShiny) {
          _syncProviderActiveAutoHunts();
        }
      }
    }

    if (cue.eggHatchCue == EggHatchCue.ohPrompt) {
      final decision = slot.onEggHatchCue(cue.eggHatchCue);
      await _applyDecision(slot, decision);
      if (_running &&
          identical(_slots[slot.slotId], slot) &&
          slot.phase == ShinySlotPhase.counted) {
        _scheduleRearmTimer(slot);
      }
    }
    _publishSlotSnapshots();
  }

  Future<void> _processVisualFrame(SlotVisualFrame vf) async {
    if (!_running || _paused) return;
    final slot = _resolveSlot(vf.slotId == 0 ? null : vf.slotId);
    if (slot == null || !_isSlotHuntActive(slot)) return;
    if (!slot.settings.enableColorDeviationShinyCheck) return;
    if (!slot.canEvaluateVisualShiny) {
      _pendingColorSampleBySlot.remove(slot.slotId);
      return;
    }
    final pending = _pendingColorSampleBySlot[slot.slotId];
    if (pending == null) return;
    if (_nowElapsed < pending.sampleAfter) return;

    final precomputed = vf.precomputedHistogram;
    final VisualShinySignal? signal;
    if (precomputed != null) {
      if (precomputed.length != 16) return;
      _pendingColorSampleBySlot.remove(slot.slotId);
      signal = _colorDetector.analyzeHistogram(
        precomputed,
        slotId: slot.slotId,
        speciesKey: pending.speciesKey,
        deviationThreshold: slot.settings.colorDeviationThreshold,
      );
    } else {
      final frame = vf.frame;
      if (frame == null) return;
      // Wait until a frame with sufficient chroma arrives (skip black/white fades).
      final hist = VisualShinyColorDetector.extractHistogram(frame);
      if (hist == null) return;
      _pendingColorSampleBySlot.remove(slot.slotId);

      signal = _colorDetector.analyzeHistogram(
        hist,
        slotId: slot.slotId,
        speciesKey: pending.speciesKey,
        deviationThreshold: slot.settings.colorDeviationThreshold,
      );
    }
    if (signal != null) {
      final decision = slot.onVisualShinySignal(
        signal,
        detectedPokemonId: pending.pokemonId,
        detectedPokemonName: pending.pokemonName,
      );
      await _applyDecision(
        slot,
        decision,
        detectionSource: signal.source,
      );
      if (slot.phase == ShinySlotPhase.pausedByShiny) {
        _syncProviderActiveAutoHunts();
      }
      _publishSlotSnapshots();
    }
  }

  Future<void> _processFrameTransition(FrameTransitionEvent transition) async {
    if (!_running || _paused) return;
    final slot =
        _resolveSlot(transition.slotId == 0 ? null : transition.slotId);
    if (slot == null || !_isSlotHuntActive(slot)) return;

    final prevPhase = slot.phase;
    final decision = slot.onFrameTransition(transition);
    if (slot.phase == ShinySlotPhase.rearmPending) {
      _pendingColorSampleBySlot.remove(slot.slotId);
      _sparkleDelayDetector.clearPendingEncounter(slot.slotId);
      if (prevPhase == ShinySlotPhase.counted) {
        _clearCoordinatorBattleState(slot.slotId);
        if (transition.slotId == 0) {
          _coordinator?.clearBattleState(0);
        }
      }
      _scheduleRearmTimer(slot);
    }
    await _applyDecision(slot, decision);
    _publishSlotSnapshots();
  }

  Future<void> _applyDecision(
    ShinySlotStateMachine slot,
    ShinyCountDecision decision, {
    ScannerEvent? sourceEvent,
    ShinyDetectionSource? detectionSource,
  }) async {
    if (!decision.isShinyAlertOnly &&
        (!decision.shouldIncrement || decision.delta <= 0)) {
      return;
    }

    final huntId = _settings.slotToHuntOverrides[slot.slotId] ??
        slot.assignedHuntId ??
        _defaultHuntId;
    if (huntId == null || huntId.isEmpty) return;

    final provider = _huntProvider;
    if (provider == null) return;

    final ShinyHunt? hunt = provider.getHuntById(huntId);
    if (hunt == null || hunt.isCompleted || hunt.isPaused) return;

    if (decision.isShinyAlertOnly) {
      final resolvedSource = detectionSource ?? ShinyDetectionSource.ocrText;
      final alertEntry = AutoCountLogEntry(
        id: 'shiny_alert_${++_logSequence}_${slot.slotId}',
        slotId: slot.slotId,
        colorHex: slot.colorHex,
        huntId: huntId,
        pokemonId: decision.pokemonId,
        pokemonName: decision.pokemonName,
        delta: 0,
        reason: decision.reason,
        isShiny: true,
        detectionSource: resolvedSource,
        timestamp: DateTime.now(),
      );
      _logs.insert(0, alertEntry);
      if (_logs.length > maxLogEntries) {
        _logs.removeRange(maxLogEntries, _logs.length);
      }
      recentLogsNotifier.value = List.unmodifiable(_logs);
      _recordShinyAlert(alertEntry);
      await _triggerFeedback(
        alertEntry,
        isShiny: true,
        slotSettings: slot.settings,
        sourceEvent: sourceEvent,
      );
      return;
    }

    provider.incrementAuto(huntId, delta: decision.delta);

    final resolvedSource = decision.isShiny
        ? (detectionSource ?? ShinyDetectionSource.ocrText)
        : null;
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
      detectionSource: resolvedSource,
      timestamp: DateTime.now(),
    );
    _logs.insert(0, entry);
    if (_logs.length > maxLogEntries) {
      _logs.removeRange(maxLogEntries, _logs.length);
    }
    recentLogsNotifier.value = List.unmodifiable(_logs);

    if (decision.isShiny) {
      _pendingColorSampleBySlot.remove(slot.slotId);
      _recordShinyAlert(entry);
      await _triggerFeedback(
        entry,
        isShiny: true,
        slotSettings: slot.settings,
        sourceEvent: sourceEvent,
      );
    } else {
      if (slot.settings.enableSparkleDelayShinyCheck) {
        _sparkleDelayDetector.onEncounterCounted(slot.slotId, _nowElapsed);
      }
      if (slot.settings.enableColorDeviationShinyCheck) {
        final fallbackName =
            (decision.pokemonName?.trim().isNotEmpty ?? false)
                ? decision.pokemonName!.trim()
                : huntId;
        _pendingColorSampleBySlot[slot.slotId] = (
          speciesKey: '${decision.pokemonId ?? fallbackName}',
          pokemonId: decision.pokemonId,
          pokemonName: decision.pokemonName,
          sampleAfter: _nowElapsed + const Duration(milliseconds: 700),
        );
      }
      await _triggerFeedback(
        entry,
        isShiny: false,
        slotSettings: slot.settings,
        sourceEvent: sourceEvent,
      );
    }
  }

  Future<void> _triggerFeedback(
    AutoCountLogEntry entry, {
    required bool isShiny,
    required ShinyAutoCounterSettings slotSettings,
    ScannerEvent? sourceEvent,
  }) async {
    final playSound =
        isShiny ? slotSettings.playSoundOnShiny : slotSettings.playSoundOnCount;
    final playHaptic = isShiny
        ? slotSettings.playHapticOnShiny
        : slotSettings.playHapticOnCount;

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
      final feedbackHandler = _feedback ?? const _SystemSoundScannerFeedback();
      if (isShiny) {
        await feedbackHandler.onShiny(ev);
      } else {
        await feedbackHandler.onEncounter(ev);
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

class _SystemSoundScannerFeedback implements ScannerFeedback {
  const _SystemSoundScannerFeedback();

  @override
  Future<void> onCaught(ScannerEvent event) async {}

  @override
  Future<void> onEvolved(ScannerEvent event) async {}

  @override
  Future<void> onEncounter(ScannerEvent event) async {
    try {
      unawaited(SystemSound.play(SystemSoundType.click).catchError((_) {}));
    } catch (_) {}
  }

  @override
  Future<void> onShiny(ScannerEvent event) async {
    try {
      unawaited(SystemSound.play(SystemSoundType.alert).catchError((_) {}));
    } catch (_) {}
  }
}

class _SerializedAutoTask {
  final Future<void> Function() action;
  final Completer<void> completer = Completer<void>();
  _SerializedAutoTask(this.action);
}

class _PendingAutoCounterSession {
  final ShinyHuntProvider huntProvider;
  final String defaultHuntId;
  final ShinyAutoCounterSettings settings;

  const _PendingAutoCounterSession({
    required this.huntProvider,
    required this.defaultHuntId,
    required this.settings,
  });
}
