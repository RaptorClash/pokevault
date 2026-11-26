import 'dart:async';
import 'engine/ocr_detection_engine.dart';
import 'engine/pokemon_fuzzy_matcher.dart';
import 'feedback/scanner_feedback.dart';
import 'models/scanner_event.dart';
import 'models/scanner_settings.dart';
import 'source/scanner_source.dart';

/// Semantic cue telemetry emitted on every processed OCR frame for downstream listeners
/// such as the Shiny-Hunt auto-counter state machine.
class ScannerCueSignal {
  final int slotId;
  final String rawText;
  final BattleCue battleCue;
  final EggHatchCue eggHatchCue;
  final ResetCue resetCue;

  const ScannerCueSignal({
    required this.slotId,
    required this.rawText,
    required this.battleCue,
    required this.eggHatchCue,
    required this.resetCue,
  });
}

/// Central coordinator connecting OCR engine, fuzzy dictionary, feedback, and active sources.
class ScannerCoordinator {
  final OcrDetectionEngine engine;
  final PokemonFuzzyMatcher matcher;
  ScannerSettings _settings;
  final ScannerFeedback _feedback;

  ScannerSource? _source;
  StreamSubscription<String>? _sourceSub;
  StreamSubscription<String>? _focusSourceSub;
  StreamSubscription<MultiInstanceTextEmission>? _multiSourceSub;

  final StreamController<ScannerEvent> _eventsController =
      StreamController<ScannerEvent>.broadcast();
  final StreamController<List<ScannerEvent>> _activeFocusController =
      StreamController<List<ScannerEvent>>.broadcast();
  final StreamController<ScannerCueSignal> _cueController =
      StreamController<ScannerCueSignal>.broadcast();

  // Debouncing / Duplicate suppression cache per (role/type/pokemonId/shiny) key
  final Map<String, Duration> _recentEmittedAt = {};
  final Duration _duplicateCooldown;
  // Single-screen battle-state tracker: tracks already-logged species per slot so
  // fainting/delayed enemy detection inside the same battle never spams duplicate feed entries.
  final Map<int, ({Set<int> speciesIds, String fallbackKey, Duration lastSeenAt})>
      _activeBattlesBySlot = {};

  /// Maximum idle duration before an active battle suppression entry expires.
  static const Duration battleTimeout = Duration(minutes: 20);
  static const Duration _battleTimeout = battleTimeout;
  static const int _maxPendingPerSlot = 6;

  final Stopwatch _monotonicClock = Stopwatch()..start();
  final Duration Function()? elapsedClock;
  final List<_PendingScanRequest> _pendingQueue = [];
  bool _isProcessingQueue = false;
  int _droppedFramesCount = 0;
  String? _effectiveOcrLanguage;
  List<CustomOcrPattern> _overlayCustomPatterns = const [];
  bool _suppressEncounterFeedback = false;

  /// Resolved effective game/OCR language code (e.g. `'de'`, `'en'`), or `null` for all.
  String? get effectiveOcrLanguage => _effectiveOcrLanguage;

  /// Number of stale intermediate frames dropped by per-slot backpressure.
  int get debugDroppedFramesCount => _droppedFramesCount;

  Duration get _currentElapsed => elapsedClock?.call() ?? _monotonicClock.elapsed;

  ScannerCoordinator({
    required this.engine,
    required this.matcher,
    ScannerSettings? settings,
    ScannerFeedback? feedback,
    Duration encounterCooldown = const Duration(milliseconds: 1500),
    this.elapsedClock,
  })  : _settings = settings ?? ScannerSettings.defaults(),
        _feedback = feedback ?? const SilentScannerFeedback(),
        _duplicateCooldown = encounterCooldown {
    _syncEngineCustomPatterns();
    setEffectiveOcrLanguage(_effectiveOcrLanguage);
  }

  /// Currently active settings.
  ScannerSettings get settings => _settings;

  /// Broadcast stream of recognized and resolved scanner events.
  Stream<ScannerEvent> get events => _eventsController.stream;

  /// Broadcast stream of grouped active opponent(s) detected in a frame (1..5 Pokémon).
  Stream<List<ScannerEvent>> get activeFocusStream =>
      _activeFocusController.stream;

  /// Broadcast stream of semantic cues (battle end, egg hatch prompt, reset cue, raw text).
  Stream<ScannerCueSignal> get cueStream => _cueController.stream;

  void _syncEngineCustomPatterns() {
    engine.updateCustomPatterns([
      ..._settings.customPatterns,
      ..._overlayCustomPatterns,
    ]);
  }

  /// Attaches or clears an external custom-pattern overlay (e.g. from ShinyAutoCounterService)
  /// so `updateSettings()` never erases active auto-counter rules.
  void setOverlayCustomPatterns(List<CustomOcrPattern> patterns) {
    _overlayCustomPatterns = List.unmodifiable(patterns);
    _syncEngineCustomPatterns();
  }

  /// Suppresses coordinator encounter/shiny audio feedback while an external auto-counter
  /// owns encounter notifications.
  void setSuppressEncounterFeedback(bool suppress) {
    _suppressEncounterFeedback = suppress;
  }

  /// Clears active single-screen battle deduplication and cooldown caches for [slotId] (or all slots).
  void clearBattleState([int? slotId]) {
    if (slotId == null) {
      _activeBattlesBySlot.clear();
      _recentEmittedAt.clear();
      return;
    }
    _activeBattlesBySlot.remove(slotId);
    final instPrefix = 'inst_${slotId}_';
    final rawPrefix = '${slotId}_';
    _recentEmittedAt.removeWhere(
      (k, _) =>
          k.startsWith(instPrefix) ||
          k.startsWith(rawPrefix) ||
          (slotId == 0 && (k.startsWith('dlg_') || k.startsWith('hud_'))),
    );
  }

  /// Sets the app/Dex fallback game language and updates [matcher]'s active language filter.
  /// If `settings.ocrLanguage` is an explicit override (not `'auto'`), that override wins.
  void setEffectiveOcrLanguage(String? languageCode) {
    _effectiveOcrLanguage = languageCode;
    final configured = _settings.ocrLanguage;
    final targetLang =
        (configured != 'auto' && configured.isNotEmpty) ? configured : languageCode;
    matcher.setActiveLanguage(targetLang);
  }

  /// Updates current settings dynamically.
  void updateSettings(ScannerSettings newSettings) {
    _settings = newSettings;
    _syncEngineCustomPatterns();
    setEffectiveOcrLanguage(_effectiveOcrLanguage);
  }

  /// Attaches a [ScannerSource] to receive continuous OCR text frames.
  void bindSource(ScannerSource source) {
    _sourceSub?.cancel();
    _focusSourceSub?.cancel();
    _multiSourceSub?.cancel();
    _source = source;
    _sourceSub = _source!.textStream.listen((text) {
      processFrameText(text, encounterOnly: false, allowMultiEncounter: true);
    });
    if (source is DualZoneScannerSource) {
      _focusSourceSub = source.focusTextStream.listen((text) {
        processFrameText(text, encounterOnly: true, allowMultiEncounter: true);
      });
    }
    if (source is MultiInstanceScannerSource) {
      _multiSourceSub = source.multiInstanceTextStream.listen((emission) {
        processFrameText(
          emission.rawText,
          encounterOnly: emission.encounterOnly,
          allowMultiEncounter: true,
          instanceIndex: emission.slotId,
          instanceColorHex: emission.colorHex,
        );
      });
    }
  }

  /// Explicitly binds a dedicated Zone B opponent-HUD text stream (`encounterOnly: true`).
  void bindFocusStream(Stream<String> focusStream) {
    _focusSourceSub?.cancel();
    _focusSourceSub = focusStream.listen((text) {
      processFrameText(text, encounterOnly: true, allowMultiEncounter: true);
    });
  }

  /// Starts the connected scanner source.
  Future<void> start() async {
    if (_source != null && !_source!.isRunning) {
      await _source!.start();
    }
  }

  /// Stops the connected scanner source.
  Future<void> stop() async {
    if (_source != null && _source!.isRunning) {
      await _source!.stop();
    }
  }

  /// Analyzes [rawText] and returns the first emitted event, or `null`.
  Future<ScannerEvent?> processText(String rawText) async {
    final emitted = await processFrameText(
      rawText,
      encounterOnly: false,
      allowMultiEncounter: true,
    );
    return emitted.firstOrNull;
  }

  /// Analyzes [rawText] for single or multi-Pokémon encounters, enforces
  /// `ignoredPokemonIds` starter/team protection, single-screen battle-state deduplication,
  /// and per-ID cooldowns, and emits focus/event streams.
  Future<List<ScannerEvent>> processFrameText(
    String rawText, {
    bool encounterOnly = false,
    bool allowMultiEncounter = true,
    int? instanceIndex,
    int? instanceColorHex,
  }) {
    if (_eventsController.isClosed) {
      return Future.value(const []);
    }

    final slotKey = instanceIndex ?? 0;
    final req = _PendingScanRequest(
      rawText: rawText,
      encounterOnly: encounterOnly,
      allowMultiEncounter: allowMultiEncounter,
      instanceIndex: instanceIndex,
      instanceColorHex: instanceColorHex,
      slotKey: slotKey,
    );

    if (_isProcessingQueue) {
      int slotPendingCount = 0;
      for (final item in _pendingQueue) {
        if (item.slotKey == slotKey) slotPendingCount++;
      }
      while (slotPendingCount >= _maxPendingPerSlot) {
        final oldestIdx =
            _pendingQueue.indexWhere((item) => item.slotKey == slotKey);
        if (oldestIdx < 0) break;
        final dropped = _pendingQueue.removeAt(oldestIdx);
        slotPendingCount--;
        _droppedFramesCount++;
        if (!dropped.completer.isCompleted) {
          dropped.completer.complete(const []);
        }
      }
      _pendingQueue.add(req);
      return req.completer.future;
    }

    _isProcessingQueue = true;
    _drainQueueWithInitial(req);
    return req.completer.future;
  }

  Future<void> _drainQueueWithInitial(_PendingScanRequest initial) async {
    _PendingScanRequest? current = initial;
    try {
      while (current != null) {
        try {
          final result = await _processFrameTextSerialized(
            current.rawText,
            encounterOnly: current.encounterOnly,
            allowMultiEncounter: current.allowMultiEncounter,
            instanceIndex: current.instanceIndex,
            instanceColorHex: current.instanceColorHex,
          );
          if (!current.completer.isCompleted) {
            current.completer.complete(result);
          }
        } catch (e, st) {
          if (!current.completer.isCompleted) {
            current.completer.completeError(e, st);
          }
        }
        current = _pendingQueue.isNotEmpty ? _pendingQueue.removeAt(0) : null;
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<List<ScannerEvent>> _processFrameTextSerialized(
    String rawText, {
    bool encounterOnly = false,
    bool allowMultiEncounter = true,
    int? instanceIndex,
    int? instanceColorHex,
  }) async {
    final now = DateTime.now();
    final elapsed = _currentElapsed;
    final battleSlotKey = instanceIndex ?? 0;
    final battleCue = engine.detectBattleCue(rawText);
    final eggHatchCue = engine.detectEggHatchCue(rawText);
    final resetCue = engine.detectResetCue(rawText);

    if (rawText.trim().isNotEmpty && !_cueController.isClosed) {
      _cueController.add(
        ScannerCueSignal(
          slotId: battleSlotKey,
          rawText: rawText,
          battleCue: battleCue,
          eggHatchCue: eggHatchCue,
          resetCue: resetCue,
        ),
      );
    }

    if (resetCue != ResetCue.none) {
      clearBattleState(battleSlotKey);
    }

    if (battleCue == BattleCue.battleEnded) {
      _activeBattlesBySlot.remove(battleSlotKey);
      return const [];
    }
    if (battleCue == BattleCue.battleMenu &&
        _activeBattlesBySlot.containsKey(battleSlotKey)) {
      final active = _activeBattlesBySlot[battleSlotKey]!;
      _activeBattlesBySlot[battleSlotKey] = (
        speciesIds: active.speciesIds,
        fallbackKey: active.fallbackKey,
        lastSeenAt: elapsed,
      );
      return const [];
    }

    final parseResult = engine.parse(
      rawText,
      role: encounterOnly
          ? OcrScanRole.enemyHudFocusOnly
          : OcrScanRole.dialogueAndCatch,
    );
    if (parseResult == null) return const [];

    final effectiveType =
        encounterOnly ? ScannerEventType.encounter : parseResult.type;

    if (effectiveType == ScannerEventType.evolved && !_settings.trackEvolutions) {
      return const [];
    }

    final isShiny = _settings.detectShinies && parseResult.isShiny;
    final isAlpha = _settings.detectAlphas && parseResult.isAlpha;

    // Multi-encounter / Zone B resolution
    if (allowMultiEncounter &&
        (encounterOnly || parseResult.isMultiEncounter)) {
      final orderedIds = <int>[];
      final bestById = <int, FuzzyMatchResult>{};
      final countsById = <int, int>{};

      void recordCandidate(FuzzyMatchResult hit, int addCount) {
        final existing = bestById[hit.pokemonId];
        if (existing == null) {
          orderedIds.add(hit.pokemonId);
          bestById[hit.pokemonId] = hit;
          countsById[hit.pokemonId] = addCount;
        } else {
          if (hit.confidence > existing.confidence) {
            bestById[hit.pokemonId] = hit;
          }
          countsById[hit.pokemonId] =
              (countsById[hit.pokemonId] ?? 1) + addCount;
        }
      }

      if (parseResult.extractedPokemonNames.isNotEmpty) {
        for (final rawName in parseResult.extractedPokemonNames) {
          final direct =
              matcher.matchTopK(rawName, limit: 1, threshold: 0.72).firstOrNull;
          if (direct != null) {
            recordCandidate(direct, 1);
          } else {
            final lineHits = matcher.matchAllWithCounts(
              rawName,
              maxPokemon: 5,
              threshold: encounterOnly ? 0.72 : 0.76,
            );
            for (final entry in lineHits) {
              recordCandidate(entry.match, entry.count);
            }
          }
        }
      }

      if (orderedIds.isEmpty) {
        final tokenMatches = matcher.matchAllWithCounts(
          parseResult.extractedPokemonName,
          maxPokemon: 5,
          threshold: encounterOnly ? 0.72 : 0.76,
        );
        for (final entry in tokenMatches) {
          recordCandidate(entry.match, entry.count);
        }
      }

      // Filter ignored starter/team Pokémon
      final filteredIds = orderedIds
          .where((id) => !_settings.ignoredPokemonIds.contains(id))
          .toList();
      if (filteredIds.isEmpty) return const [];

      final focusGroup = <ScannerEvent>[];
      final newlyEmitted = <ScannerEvent>[];
      final zoneTag = instanceIndex != null
          ? 'inst_$instanceIndex'
          : (encounterOnly ? 'hud' : 'dlg');

      final filteredIdSet = filteredIds.toSet();
      final activeBattle = _activeBattlesBySlot[battleSlotKey];
      final battleValid = activeBattle != null &&
          elapsed - activeBattle.lastSeenAt < _battleTimeout;
      final sharesAnySpecies = battleValid &&
          activeBattle.speciesIds.intersection(filteredIdSet).isNotEmpty;
      final alreadySeenInBattle =
          sharesAnySpecies ? activeBattle.speciesIds : <int>{};

      for (final pid in filteredIds) {
        final match = bestById[pid]!;
        final count = countsById[pid] ?? 1;
        final isSmartMatch =
            parseResult.isSmartSearchFallback || match.confidence < 1.0;
        final event = ScannerEvent(
          type: effectiveType,
          pokemonId: match.pokemonId,
          rawText: rawText,
          matchedName: match.canonicalName,
          isShiny: isShiny,
          gender: parseResult.gender,
          isAlpha: isAlpha,
          confidence: match.confidence,
          timestamp: now,
          languageCode: parseResult.detectedLanguage,
          alternatives: [match],
          isSmartMatch: isSmartMatch,
          instanceIndex: instanceIndex,
          instanceColorHex: instanceColorHex,
          encounterCount: count,
          matchedCustomPatternId: parseResult.matchedCustomPatternId,
        );
        focusGroup.add(event);

        if (effectiveType == ScannerEventType.encounter &&
            !isShiny &&
            alreadySeenInBattle.contains(match.pokemonId)) {
          continue;
        }

        final duplicateKey =
            '${zoneTag}_${effectiveType.name}_${match.pokemonId}_$isShiny';
        final prevTime = _recentEmittedAt[duplicateKey];
        if (prevTime == null ||
            elapsed - prevTime >= _duplicateCooldown) {
          _recentEmittedAt[duplicateKey] = elapsed;
          newlyEmitted.add(event);
        }
      }

      if (effectiveType == ScannerEventType.encounter) {
        final updatedSet = <int>{...alreadySeenInBattle, ...filteredIdSet};
        _activeBattlesBySlot[battleSlotKey] = (
          speciesIds: updatedSet,
          fallbackKey: updatedSet.join(','),
          lastSeenAt: elapsed,
        );
      } else if (effectiveType == ScannerEventType.caught) {
        _activeBattlesBySlot.remove(battleSlotKey);
      }

      if (focusGroup.isNotEmpty && !_activeFocusController.isClosed) {
        _activeFocusController.add(List.unmodifiable(focusGroup));
      }

      for (final event in newlyEmitted) {
        await _dispatchFeedback(event, isShiny);
        if (!_eventsController.isClosed) {
          _eventsController.add(event);
        }
      }
      return List.unmodifiable(newlyEmitted.isNotEmpty ? newlyEmitted : focusGroup);
    }

    final isResetEventType = effectiveType == ScannerEventType.softReset ||
        effectiveType == ScannerEventType.customReset;

    // Single Pokémon resolution path
    List<FuzzyMatchResult> candidates = const [];
    if (!isResetEventType) {
      if (parseResult.isSmartSearchFallback) {
        candidates = matcher.matchTokensFromLine(
          parseResult.extractedPokemonName,
          limit: 3,
          threshold: 0.72,
        );
        if (candidates.isEmpty) {
          return const [];
        }
      } else {
        candidates = matcher.matchTopK(
          parseResult.extractedPokemonName,
          limit: 3,
          threshold: 0.72,
        );
        if (candidates.isEmpty &&
            parseResult.extractedPokemonName.contains(' ')) {
          candidates = matcher.matchTokensFromLine(
            parseResult.extractedPokemonName,
            limit: 3,
            threshold: 0.72,
          );
        }
      }

      // Filter out any ignored starter/team candidate
      candidates = candidates
          .where((c) => !_settings.ignoredPokemonIds.contains(c.pokemonId))
          .toList();

      final matchCheck = candidates.isNotEmpty ? candidates.first : null;
      if (matchCheck == null && candidates.isEmpty) {
        // Check if an ignored exact name triggered this event cleanly -> block it
        final directCheck = matcher.match(parseResult.extractedPokemonName);
        if (directCheck != null &&
            _settings.ignoredPokemonIds.contains(directCheck.pokemonId)) {
          return const [];
        }
      }
    }

    final match = candidates.isNotEmpty ? candidates.first : null;
    final pokemonId = match?.pokemonId;
    if (!isResetEventType &&
        pokemonId != null &&
        _settings.ignoredPokemonIds.contains(pokemonId)) {
      return const [];
    }

    final matchedName = match?.canonicalName ?? parseResult.extractedPokemonName;
    final confidence = match?.confidence ?? parseResult.confidence;
    final isSmartMatch =
        parseResult.isSmartSearchFallback ||
        (match != null && match.confidence < 1.0);

    // Resolve pre-evolution for evolution events
    int? preEvoId;
    String? preEvoName;
    if (effectiveType == ScannerEventType.evolved &&
        parseResult.extractedPreEvolutionName != null) {
      final preMatch = matcher.match(parseResult.extractedPreEvolutionName!);
      preEvoId = preMatch?.pokemonId;
      preEvoName = preMatch?.canonicalName ?? parseResult.extractedPreEvolutionName;
    }

    final singleSpeciesKey = (pokemonId ?? matchedName).toString();
    final activeSingleBattle = _activeBattlesBySlot[battleSlotKey];
    if (effectiveType == ScannerEventType.encounter) {
      final sameId = pokemonId != null &&
          activeSingleBattle != null &&
          activeSingleBattle.speciesIds.contains(pokemonId);
      final sameFallback = activeSingleBattle != null &&
          activeSingleBattle.fallbackKey == singleSpeciesKey;
      if (!isShiny &&
          activeSingleBattle != null &&
          (sameId || sameFallback) &&
          elapsed - activeSingleBattle.lastSeenAt < _battleTimeout) {
        _activeBattlesBySlot[battleSlotKey] = (
          speciesIds: activeSingleBattle.speciesIds,
          fallbackKey: activeSingleBattle.fallbackKey,
          lastSeenAt: elapsed,
        );
        return const [];
      }
      _activeBattlesBySlot[battleSlotKey] = (
        speciesIds: pokemonId != null ? {pokemonId} : <int>{},
        fallbackKey: singleSpeciesKey,
        lastSeenAt: elapsed,
      );
    } else if (effectiveType == ScannerEventType.caught) {
      _activeBattlesBySlot.remove(battleSlotKey);
    }

    final duplicateKey =
        '${instanceIndex ?? 'dlg'}_${effectiveType.name}_${pokemonId ?? matchedName}_$isShiny';
    final prevTime = _recentEmittedAt[duplicateKey];
    if (prevTime != null && elapsed - prevTime < _duplicateCooldown) {
      return const [];
    }
    _recentEmittedAt[duplicateKey] = elapsed;

    final event = ScannerEvent(
      type: effectiveType,
      pokemonId: pokemonId,
      rawText: rawText,
      matchedName: matchedName,
      isShiny: isShiny,
      gender: parseResult.gender,
      isAlpha: isAlpha,
      preEvolutionId: preEvoId,
      preEvolutionName: preEvoName,
      confidence: confidence,
      timestamp: now,
      languageCode: parseResult.detectedLanguage,
      alternatives: candidates,
      isSmartMatch: isSmartMatch,
      instanceIndex: instanceIndex,
      instanceColorHex: instanceColorHex,
      matchedCustomPatternId: parseResult.matchedCustomPatternId,
    );

    final isResetEvent = effectiveType == ScannerEventType.softReset ||
        effectiveType == ScannerEventType.customReset;

    if (!isResetEvent) {
      if (!_activeFocusController.isClosed) {
        _activeFocusController.add([event]);
      }

      await _dispatchFeedback(event, isShiny);
    }

    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }

    return [event];
  }

  Future<void> _dispatchFeedback(ScannerEvent event, bool isShiny) async {
    if (!(_settings.playAudioFeedback || _settings.playHapticFeedback)) {
      return;
    }
    if (_suppressEncounterFeedback &&
        (event.type == ScannerEventType.encounter ||
            event.type == ScannerEventType.shinyDetected ||
            (isShiny && event.type != ScannerEventType.caught))) {
      return;
    }
    if (isShiny) {
      await _feedback.onShiny(event);
    }
    switch (event.type) {
      case ScannerEventType.caught:
        await _feedback.onCaught(event);
        break;
      case ScannerEventType.encounter:
        await _feedback.onEncounter(event);
        break;
      case ScannerEventType.evolved:
        await _feedback.onEvolved(event);
        break;
      default:
        break;
    }
  }

  /// Disposes subscriptions and controllers.
  Future<void> dispose() async {
    for (final pending in _pendingQueue) {
      if (!pending.completer.isCompleted) {
        pending.completer.complete(const []);
      }
    }
    _pendingQueue.clear();
    await _sourceSub?.cancel();
    await _focusSourceSub?.cancel();
    await _multiSourceSub?.cancel();
    _sourceSub = null;
    _focusSourceSub = null;
    _multiSourceSub = null;
    await _eventsController.close();
    await _activeFocusController.close();
    await _cueController.close();
  }
}

class _PendingScanRequest {
  final String rawText;
  final bool encounterOnly;
  final bool allowMultiEncounter;
  final int? instanceIndex;
  final int? instanceColorHex;
  final int slotKey;
  final Completer<List<ScannerEvent>> completer = Completer<List<ScannerEvent>>();

  _PendingScanRequest({
    required this.rawText,
    required this.encounterOnly,
    required this.allowMultiEncounter,
    required this.instanceIndex,
    required this.instanceColorHex,
    required this.slotKey,
  });
}
