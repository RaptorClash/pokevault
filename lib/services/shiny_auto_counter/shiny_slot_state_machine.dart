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
  final bool isShinyAlertOnly;
  final String reason;
  final int? pokemonId;
  final String? pokemonName;

  const ShinyCountDecision.none([this.reason = ''])
      : shouldIncrement = false,
        delta = 0,
        isShiny = false,
        isShinyAlertOnly = false,
        pokemonId = null,
        pokemonName = null;

  const ShinyCountDecision.increment({
    required this.delta,
    required this.reason,
    this.isShiny = false,
    this.pokemonId,
    this.pokemonName,
  })  : shouldIncrement = true,
        isShinyAlertOnly = false;

  const ShinyCountDecision.shinyAlert({
    required this.reason,
    this.pokemonId,
    this.pokemonName,
  })  : shouldIncrement = false,
        delta = 0,
        isShiny = true,
        isShinyAlertOnly = true;
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

  /// Reverts a previously counted increment on this slot and immediately re-arms it.
  void recordUndo(int delta) {
    if (delta > 0) {
      _sessionCount = (_sessionCount - delta).clamp(0, 9999999);
    }
    forceRearm();
  }

  Duration? get remainingRearmDuration {
    if (_phase != ShinySlotPhase.rearmPending) return null;
    final started = _rearmStartedAt;
    if (started == null) return Duration.zero;
    final cooldown = Duration(milliseconds: settings.minResetCooldownMs);
    final elapsed = _now - started;
    if (elapsed >= cooldown) return Duration.zero;
    return cooldown - elapsed;
  }

  /// Promotes `rearmPending` -> `armed` when cooldown has elapsed; returns true if promoted.
  bool checkRearmReady() {
    if (_phase != ShinySlotPhase.rearmPending) return false;
    _promoteRearmIfReady();
    return _phase == ShinySlotPhase.armed;
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

  bool _patternBelongsToSlot(String? patternId) {
    if (patternId == null || !patternId.startsWith('shiny_hunt:')) {
      return true;
    }
    final rest = patternId.substring('shiny_hunt:'.length);
    final sepIdx = rest.indexOf(':');
    if (sepIdx <= 0) return true;
    final huntScopeId = rest.substring(0, sepIdx);
    return assignedHuntId == huntScopeId;
  }

  bool _matchesTarget(ScannerEvent event) {
    if (settings.matchFilter == ShinyMatchFilter.allPokemon) {
      return true;
    }
    if (event.matchedCustomPatternId != null && event.pokemonId == null) {
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
    if (!_patternBelongsToSlot(event.matchedCustomPatternId)) {
      return const ShinyCountDecision.none('hunt_scope_mismatch');
    }

    if (event.type == ScannerEventType.softReset ||
        event.type == ScannerEventType.customReset) {
      _beginRearm('reset_pattern');
      return const ShinyCountDecision.none('rearm_from_event');
    }

    if (event.type == ScannerEventType.caught &&
        settings.detectionMode == ShinyHuntDetectionMode.wildEncounter) {
      _beginRearm('caught');
      return const ShinyCountDecision.none('rearm_caught');
    }

    _promoteRearmIfReady();

    // Egg-hatch follow-up after "Oh?": allow shiny alert / pause and guaranteed auto-rearm without double-counting.
    if (settings.detectionMode == ShinyHuntDetectionMode.eggHatch &&
        event.type == ScannerEventType.eggHatched &&
        _eggOhPromptCounted &&
        _phase == ShinySlotPhase.counted) {
      _eggOhPromptCounted = false;
      _lastEventAt = DateTime.now();
      if (event.matchedName.isNotEmpty) {
        _lastTriggerLabel = event.matchedName;
      }
      if (event.isShiny && _matchesTarget(event)) {
        if (settings.autoPauseSlotOnShiny) {
          _phase = ShinySlotPhase.pausedByShiny;
        } else {
          _beginRearm('egg_hatched');
        }
        return ShinyCountDecision.shinyAlert(
          reason: 'shiny:${event.matchedName}',
          pokemonId: event.pokemonId,
          pokemonName: event.matchedName,
        );
      }
      _beginRearm('egg_hatched');
      return const ShinyCountDecision.none('egg_already_counted_on_oh');
    }

    if (_phase != ShinySlotPhase.armed) {
      return const ShinyCountDecision.none('slot_not_armed');
    }

    if (!_isTriggerEventForMode(event)) {
      return const ShinyCountDecision.none('mode_mismatch');
    }

    if (!_matchesTarget(event)) {
      return const ShinyCountDecision.none('target_filter_mismatch');
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
      if (settings.detectionMode == ShinyHuntDetectionMode.eggHatch &&
          event.type == ScannerEventType.eggHatched) {
        _beginRearm('egg_hatched');
      }
    }

    return ShinyCountDecision.increment(
      delta: delta,
      isShiny: event.isShiny,
      reason: event.isShiny
          ? 'shiny:${event.matchedName}'
          : 'ocr:${event.matchedName}',
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
      if (settings.matchFilter == ShinyMatchFilter.targetPokemonOnly) {
        return const ShinyCountDecision.none('egg_oh_waiting_for_target');
      }
      if (_phase != ShinySlotPhase.armed) {
        return const ShinyCountDecision.none('slot_not_armed');
      }
      _eggOhPromptCounted = true;
      _sessionCount += 1;
      _lastEventAt = DateTime.now();
      _lastTriggerLabel = 'egg_oh_prompt';
      _phase = ShinySlotPhase.counted;
      return const ShinyCountDecision.increment(
        delta: 1,
        reason: 'egg_oh_prompt',
      );
    }
    return const ShinyCountDecision.none();
  }

  /// Processes a battle-phase cue (e.g. fled / fainted).
  bool onBattleCue(BattleCue cue) {
    if (cue == BattleCue.battleEnded) {
      final wasCounted = _phase == ShinySlotPhase.counted;
      _beginRearm('battle_ended');
      return wasCounted;
    }
    return false;
  }

  /// Processes a soft-reset / title-screen cue.
  bool onResetCue(ResetCue cue, {String rawLabel = 'reset_menu'}) {
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
          ? 'black_screen_reset'
          : 'white_screen_reset';
      _phase = ShinySlotPhase.armed;
      return ShinyCountDecision.increment(
        delta: 1,
        reason: _lastTriggerLabel!,
      );
    }

    _beginRearm(
      transition.type == FrameTransitionType.blackScreenEnded
          ? 'black_screen'
          : 'white_screen',
    );
    return const ShinyCountDecision.none('rearm_from_transition');
  }
}
