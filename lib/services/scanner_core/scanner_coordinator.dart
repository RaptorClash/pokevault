import 'dart:async';
import 'engine/ocr_detection_engine.dart';
import 'engine/pokemon_fuzzy_matcher.dart';
import 'feedback/scanner_feedback.dart';
import 'models/scanner_event.dart';
import 'models/scanner_settings.dart';
import 'source/scanner_source.dart';

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

  // Debouncing / Duplicate suppression cache per (role/type/pokemonId/shiny) key
  final Map<String, DateTime> _recentEmittedKeys = {};
  final Duration _duplicateCooldown;
  // Single-screen battle-state tracker: suppresses duplicate encounter feed spam inside the same battle
  final Map<int, ({String speciesKey, DateTime lastSeenAt})> _activeBattlesBySlot = {};
  static const Duration _battleTimeout = Duration(minutes: 3);

  ScannerCoordinator({
    required this.engine,
    required this.matcher,
    ScannerSettings? settings,
    ScannerFeedback? feedback,
    Duration encounterCooldown = const Duration(milliseconds: 1500),
  })  : _settings = settings ?? ScannerSettings.defaults(),
        _feedback = feedback ?? const SilentScannerFeedback(),
        _duplicateCooldown = encounterCooldown {
    engine.updateCustomPatterns(_settings.customPatterns);
  }

  /// Currently active settings.
  ScannerSettings get settings => _settings;

  /// Broadcast stream of recognized and resolved scanner events.
  Stream<ScannerEvent> get events => _eventsController.stream;

  /// Broadcast stream of grouped active opponent(s) detected in a frame (1..5 Pokémon).
  Stream<List<ScannerEvent>> get activeFocusStream =>
      _activeFocusController.stream;

  /// Updates current settings dynamically.
  void updateSettings(ScannerSettings newSettings) {
    _settings = newSettings;
    engine.updateCustomPatterns(newSettings.customPatterns);
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
  }) async {
    final now = DateTime.now();
    final battleSlotKey = instanceIndex ?? 0;
    final battleCue = engine.detectBattleCue(rawText);
    if (battleCue == BattleCue.battleEnded) {
      _activeBattlesBySlot.remove(battleSlotKey);
      return const [];
    }
    if (battleCue == BattleCue.battleMenu &&
        _activeBattlesBySlot.containsKey(battleSlotKey)) {
      final active = _activeBattlesBySlot[battleSlotKey]!;
      _activeBattlesBySlot[battleSlotKey] = (
        speciesKey: active.speciesKey,
        lastSeenAt: now,
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
      final multiCandidates = <FuzzyMatchResult>[];
      final seenIds = <int>{};

      if (parseResult.extractedPokemonNames.isNotEmpty) {
        for (final rawName in parseResult.extractedPokemonNames) {
          final hit = matcher.matchTopK(rawName, limit: 1, threshold: 0.72).firstOrNull;
          if (hit != null && seenIds.add(hit.pokemonId)) {
            multiCandidates.add(hit);
          }
        }
      }

      if (multiCandidates.isEmpty) {
        final tokenMatches = matcher.matchAllFromText(
          parseResult.extractedPokemonName,
          maxPokemon: 5,
          threshold: encounterOnly ? 0.74 : 0.78,
        );
        for (final hit in tokenMatches) {
          if (seenIds.add(hit.pokemonId)) {
            multiCandidates.add(hit);
          }
        }
      }

      // Filter ignored starter/team Pokémon
      final filtered = multiCandidates
          .where((m) => !_settings.ignoredPokemonIds.contains(m.pokemonId))
          .toList();
      if (filtered.isEmpty) return const [];

      final focusGroup = <ScannerEvent>[];
      final newlyEmitted = <ScannerEvent>[];
      final zoneTag = instanceIndex != null
          ? 'inst_$instanceIndex'
          : (encounterOnly ? 'hud' : 'dlg');

      final speciesKey = filtered.map((m) => m.pokemonId.toString()).join(',');
      final activeBattle = _activeBattlesBySlot[battleSlotKey];
      final sameActiveBattle = activeBattle != null &&
          activeBattle.speciesKey == speciesKey &&
          now.difference(activeBattle.lastSeenAt) < _battleTimeout;

      for (final match in filtered) {
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
        );
        focusGroup.add(event);

        if (sameActiveBattle && effectiveType == ScannerEventType.encounter) {
          continue;
        }

        final duplicateKey =
            '${zoneTag}_${effectiveType.name}_${match.pokemonId}_$isShiny';
        final prevTime = _recentEmittedKeys[duplicateKey];
        if (prevTime == null ||
            now.difference(prevTime) >= _duplicateCooldown) {
          _recentEmittedKeys[duplicateKey] = now;
          newlyEmitted.add(event);
        }
      }

      if (effectiveType == ScannerEventType.encounter) {
        _activeBattlesBySlot[battleSlotKey] = (
          speciesKey: speciesKey,
          lastSeenAt: now,
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

    // Single Pokémon resolution path
    List<FuzzyMatchResult> candidates;
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

    final match = candidates.isNotEmpty ? candidates.first : null;
    if (match == null && candidates.isEmpty) {
      // Check if an ignored exact name triggered this event cleanly -> block it
      final directCheck = matcher.match(parseResult.extractedPokemonName);
      if (directCheck != null &&
          _settings.ignoredPokemonIds.contains(directCheck.pokemonId)) {
        return const [];
      }
    }

    final pokemonId = match?.pokemonId;
    if (pokemonId != null &&
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
      if (activeSingleBattle != null &&
          activeSingleBattle.speciesKey == singleSpeciesKey &&
          now.difference(activeSingleBattle.lastSeenAt) < _battleTimeout) {
        _activeBattlesBySlot[battleSlotKey] = (
          speciesKey: singleSpeciesKey,
          lastSeenAt: now,
        );
        return const [];
      }
      _activeBattlesBySlot[battleSlotKey] = (
        speciesKey: singleSpeciesKey,
        lastSeenAt: now,
      );
    } else if (effectiveType == ScannerEventType.caught) {
      _activeBattlesBySlot.remove(battleSlotKey);
    }

    final duplicateKey =
        '${instanceIndex ?? 'dlg'}_${effectiveType.name}_${pokemonId ?? matchedName}_$isShiny';
    final prevTime = _recentEmittedKeys[duplicateKey];
    if (prevTime != null && now.difference(prevTime) < _duplicateCooldown) {
      return const [];
    }
    _recentEmittedKeys[duplicateKey] = now;

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
    );

    if (!_activeFocusController.isClosed) {
      _activeFocusController.add([event]);
    }

    await _dispatchFeedback(event, isShiny);

    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }

    return [event];
  }

  Future<void> _dispatchFeedback(ScannerEvent event, bool isShiny) async {
    if (!(_settings.playAudioFeedback || _settings.playHapticFeedback)) {
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
    await _sourceSub?.cancel();
    await _focusSourceSub?.cancel();
    await _multiSourceSub?.cancel();
    _sourceSub = null;
    _focusSourceSub = null;
    _multiSourceSub = null;
    await _eventsController.close();
    await _activeFocusController.close();
  }
}
