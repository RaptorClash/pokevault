import '../scanner_core/engine/ocr_detection_engine.dart';
import '../scanner_core/media/frame_transition_detector.dart';
import '../scanner_core/models/scanner_event.dart';
import 'shiny_auto_counter_config.dart';

/// Lifecycle phase of a single auto-counter scan slot.
enum ShinySlotPhase {
  armed,
  counted,
  rearmPending,
  pausedByShiny,
  pausedManual,
}

/// Immutable UI snapshot representing a scan slot's live status.
class ShinySlotSnapshot {
  final int slotId;
  final int colorHex;
  final ShinySlotPhase phase;
  final String? assignedHuntId;
  final String? lastTriggerLabel;
  final int sessionCount;
  final DateTime? lastEventAt;

  const ShinySlotSnapshot({
    required this.slotId,
    required this.colorHex,
    required this.phase,
    this.assignedHuntId,
    this.lastTriggerLabel,
    this.sessionCount = 0,
    this.lastEventAt,
  });
}

/// Result returned by [ShinySlotStateMachine] upon processing an event or transition.
class ShinyCountDecision {
  final bool shouldIncrement;
  final int delta;
  final bool isShiny;
  final String reason;
  final int? pokemonId;
  final String? pokemonName;

  const ShinyCountDecision.none([this.reason = ''])
      : shouldIncrement = false,
        delta = 0,
        isShiny = false,
        pokemonId = null,
        pokemonName = null;

  const ShinyCountDecision.increment({
    required this.delta,
    required this.reason,
    this.isShiny = false,
    this.pokemonId,
    this.pokemonName,
  }) : shouldIncrement = true;
}

/// Pure-Dart per-slot state machine preventing duplicate counts during idle/pause
/// while reliably re-arming on genuine reset, battle-end, or screen-transition edges.
class ShinySlotStateMachine {
  final int slotId;
  final int colorHex;
  int? targetPokemonId;
  String? targetPokemonName;
  String? assignedHuntId;
  ShinyAutoCounterSettings settings;
  final Duration Function()? elapsedClock;
  final Stopwatch _monotonic = Stopwatch()..start();

  ShinySlotPhase _phase = ShinySlotPhase.armed;
  Duration? _rearmStartedAt;
  Duration? _lastTransitionCountAt;
  String? _lastTriggerLabel;
  int _sessionCount = 0;
  DateTime? _lastEventAt;
  bool _eggOhPromptCounted = false;

  ShinySlotStateMachine({
    required this.slotId,
    required this.colorHex,
    this.targetPokemonId,
    this.targetPokemonName,
    this.assignedHuntId,
    ShinyAutoCounterSettings? settings,
    this.elapsedClock,
  }) : settings = settings ?? const ShinyAutoCounterSettings();

  ShinySlotPhase get phase => _phase;
  int get sessionCount => _sessionCount;
  String? get lastTriggerLabel => _lastTriggerLabel;

  Duration get _now => elapsedClock?.call() ?? _monotonic.elapsed;

  ShinySlotSnapshot toSnapshot({String? fallbackHuntId}) {
    return ShinySlotSnapshot(
      slotId: slotId,
      colorHex: colorHex,
      phase: _phase,
      assignedHuntId: assignedHuntId ?? fallbackHuntId,
      lastTriggerLabel: _lastTriggerLabel,
      sessionCount: _sessionCount,
      lastEventAt: _lastEventAt,
    );
  }

  void updateTarget({
    int? pokemonId,
    String? pokemonName,
    String? huntId,
  }) {
    targetPokemonId = pokemonId;
    targetPokemonName = pokemonName;
    assignedHuntId = huntId;
  }

  void updateSettings(ShinyAutoCounterSettings next) {
    settings = next;
  }

  void setManualPaused(bool paused) {
    if (paused) {
      _phase = ShinySlotPhase.pausedManual;
    } else if (_phase == ShinySlotPhase.pausedManual) {
      _phase = ShinySlotPhase.armed;
      _rearmStartedAt = null;
      _eggOhPromptCounted = false;
    }
  }

  void resumeFromShinyPause() {
    if (_phase == ShinySlotPhase.pausedByShiny) {
      _phase = ShinySlotPhase.armed;
      _rearmStartedAt = null;
      _eggOhPromptCounted = false;
    }
  }

  void forceRearm() {
    _phase = ShinySlotPhase.armed;
    _rearmStartedAt = null;
    _eggOhPromptCounted = false;
  }

  void _promoteRearmIfReady() {
    if (_phase != ShinySlotPhase.rearmPending) return;
    final started = _rearmStartedAt;
    if (started == null) {
      _phase = ShinySlotPhase.armed;
      return;
    }
    final cooldown = Duration(milliseconds: settings.minResetCooldownMs);
    if (_now - started >= cooldown) {
      _phase = ShinySlotPhase.armed;
      _rearmStartedAt = null;
      _eggOhPromptCounted = false;
    }
  }

  void _beginRearm(String reason) {
    if (_phase == ShinySlotPhase.pausedByShiny ||
        _phase == ShinySlotPhase.pausedManual) {
      return;
    }
    if (_phase == ShinySlotPhase.counted) {
      _phase = ShinySlotPhase.rearmPending;
      _rearmStartedAt = _now;
      _lastTriggerLabel = reason;
    }
  }

  bool _matchesTarget(ScannerEvent event) {
    if (settings.matchFilter == ShinyMatchFilter.allPokemon) {
      return true;
    }
    if (targetPokemonId != null && event.pokemonId != null) {
      return event.pokemonId == targetPokemonId;
    }
    final targetName = targetPokemonName?.trim().toLowerCase();
    if (targetName != null && targetName.isNotEmpty) {
      return event.matchedName.trim().toLowerCase() == targetName;
    }
    return true;
  }

  bool _isTriggerEventForMode(ScannerEvent event) {
    switch (settings.detectionMode) {
      case ShinyHuntDetectionMode.wildEncounter:
        return event.type == ScannerEventType.encounter ||
            event.type == ScannerEventType.shinyDetected;
      case ShinyHuntDetectionMode.softReset:
        return event.type == ScannerEventType.encounter ||
            event.type == ScannerEventType.shinyDetected;
      case ShinyHuntDetectionMode.eggHatch:
        return event.type == ScannerEventType.eggHatched;
      case ShinyHuntDetectionMode.screenTransitionOnly:
        return false;
    }
  }

  /// Processes a parsed [ScannerEvent].
  ShinyCountDecision onScannerEvent(ScannerEvent event) {
    if (event.type == ScannerEventType.softReset ||
        event.type == ScannerEventType.customReset) {
      _beginRearm('Reset-Pattern');
      return const ShinyCountDecision.none('rearm_from_event');
    }

    if (event.type == ScannerEventType.caught &&
        settings.detectionMode == ShinyHuntDetectionMode.wildEncounter) {
      _beginRearm('Gefangen');
      return const ShinyCountDecision.none('rearm_caught');
    }

    _promoteRearmIfReady();
    if (_phase != ShinySlotPhase.armed) {
      return const ShinyCountDecision.none('slot_not_armed');
    }

    if (!_isTriggerEventForMode(event)) {
      return const ShinyCountDecision.none('mode_mismatch');
    }

    if (!_matchesTarget(event)) {
      return const ShinyCountDecision.none('target_filter_mismatch');
    }

    // If egg was already counted on "Oh?" prompt, suppress duplicate on eggHatched.
    if (settings.detectionMode == ShinyHuntDetectionMode.eggHatch &&
        event.type == ScannerEventType.eggHatched &&
        _eggOhPromptCounted) {
      return const ShinyCountDecision.none('egg_already_counted_on_oh');
    }

    final delta = (settings.detectionMode == ShinyHuntDetectionMode.wildEncounter &&
            settings.useEventEncounterCount &&
            event.encounterCount > 1)
        ? event.encounterCount
        : 1;

    _sessionCount += delta;
    _lastEventAt = DateTime.now();
    _lastTriggerLabel = event.matchedName.isNotEmpty
        ? event.matchedName
        : event.type.name;

    if (event.isShiny && settings.autoPauseSlotOnShiny) {
      _phase = ShinySlotPhase.pausedByShiny;
    } else {
      _phase = ShinySlotPhase.counted;
    }

    return ShinyCountDecision.increment(
      delta: delta,
      isShiny: event.isShiny,
      reason: event.isShiny ? 'Shiny erkannt: ${event.matchedName}' : 'OCR: ${event.matchedName}',
      pokemonId: event.pokemonId,
      pokemonName: event.matchedName,
    );
  }

  /// Processes an egg-hatching cue ("Oh?" or hatched).
  ShinyCountDecision onEggHatchCue(EggHatchCue cue) {
    if (settings.detectionMode != ShinyHuntDetectionMode.eggHatch) {
      return const ShinyCountDecision.none('not_egg_mode');
    }
    _promoteRearmIfReady();
    if (cue == EggHatchCue.ohPrompt) {
      if (_phase != ShinySlotPhase.armed) {
        return const ShinyCountDecision.none('slot_not_armed');
      }
      _eggOhPromptCounted = true;
      _sessionCount += 1;
      _lastEventAt = DateTime.now();
      _lastTriggerLabel = 'Oh? (Ei)';
      _phase = ShinySlotPhase.counted;
      return const ShinyCountDecision.increment(
        delta: 1,
        reason: 'Ei-Schlupf gestartet (Oh?)',
      );
    }
    return const ShinyCountDecision.none();
  }

  /// Processes a battle-phase cue (e.g. fled / fainted).
  bool onBattleCue(BattleCue cue) {
    if (cue == BattleCue.battleEnded) {
      final wasCounted = _phase == ShinySlotPhase.counted;
      _beginRearm('Kampf beendet');
      return wasCounted;
    }
    return false;
  }

  /// Processes a soft-reset / title-screen cue.
  bool onResetCue(ResetCue cue, {String rawLabel = 'Reset-Menü'}) {
    if (cue != ResetCue.none) {
      final wasCounted = _phase == ShinySlotPhase.counted;
      _beginRearm(rawLabel);
      return wasCounted;
    }
    return false;
  }

  /// Checks raw OCR text against user-defined `customResetPatterns`.
  bool onRawText(String rawText) {
    if (settings.customResetPatterns.isEmpty) return false;
    final lower = rawText.toLowerCase();
    for (final pattern in settings.customResetPatterns) {
      final trimmed = pattern.trim().toLowerCase();
      if (trimmed.isNotEmpty && lower.contains(trimmed)) {
        return onResetCue(ResetCue.customReset, rawLabel: pattern.trim());
      }
    }
    return false;
  }

  /// Processes a luminance transition (black/white screen recovery).
  ShinyCountDecision onFrameTransition(FrameTransitionEvent transition) {
    final enabled = switch (transition.type) {
      FrameTransitionType.blackScreenEnded => settings.enableBlackScreenReset,
      FrameTransitionType.whiteScreenEnded => settings.enableWhiteScreenReset,
    };
    if (!enabled) {
      return const ShinyCountDecision.none('transition_disabled');
    }
    if (transition.durationMs < settings.transitionMinDurationMs) {
      return const ShinyCountDecision.none('transition_too_short');
    }

    if (_phase == ShinySlotPhase.pausedByShiny ||
        _phase == ShinySlotPhase.pausedManual) {
      return const ShinyCountDecision.none('slot_paused');
    }

    if (settings.detectionMode == ShinyHuntDetectionMode.screenTransitionOnly) {
      final now = _now;
      final cooldown = Duration(milliseconds: settings.minResetCooldownMs);
      if (_lastTransitionCountAt != null &&
          now - _lastTransitionCountAt! < cooldown) {
        return const ShinyCountDecision.none('transition_cooldown');
      }
      _lastTransitionCountAt = now;
      _sessionCount += 1;
      _lastEventAt = DateTime.now();
      _lastTriggerLabel = transition.type == FrameTransitionType.blackScreenEnded
          ? 'Schwarzbild-Reset'
          : 'Weißbild-Reset';
      _phase = ShinySlotPhase.armed;
      return ShinyCountDecision.increment(
        delta: 1,
        reason: _lastTriggerLabel!,
      );
    }

    _beginRearm(
      transition.type == FrameTransitionType.blackScreenEnded
          ? 'Schwarzbild'
          : 'Weißbild',
    );
    return const ShinyCountDecision.none('rearm_from_transition');
  }
}
