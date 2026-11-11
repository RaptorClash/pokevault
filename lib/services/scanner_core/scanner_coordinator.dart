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

  final StreamController<ScannerEvent> _eventsController =
      StreamController<ScannerEvent>.broadcast();

  // Debouncing / Duplicate suppression cache
  String? _lastEmittedKey;
  DateTime? _lastEmittedTime;
  static const Duration _duplicateCooldown = Duration(milliseconds: 1500);

  ScannerCoordinator({
    required this.engine,
    required this.matcher,
    ScannerSettings? settings,
    ScannerFeedback? feedback,
  })  : _settings = settings ?? ScannerSettings.defaults(),
        _feedback = feedback ?? const SilentScannerFeedback();

  /// Currently active settings.
  ScannerSettings get settings => _settings;

  /// Broadcast stream of recognized and resolved scanner events.
  Stream<ScannerEvent> get events => _eventsController.stream;

  /// Updates current settings dynamically.
  void updateSettings(ScannerSettings newSettings) {
    _settings = newSettings;
  }

  /// Attaches a [ScannerSource] to receive continuous OCR text frames.
  void bindSource(ScannerSource source) {
    _sourceSub?.cancel();
    _source = source;
    _sourceSub = _source!.textStream.listen((text) {
      processText(text);
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

  /// Analyzes [rawText], performs fuzzy matching, duplicate suppression, and dispatches events.
  Future<ScannerEvent?> processText(String rawText) async {
    final parseResult = engine.parse(rawText);
    if (parseResult == null) return null;

    // Respect event settings
    if (parseResult.type == ScannerEventType.evolved && !_settings.trackEvolutions) {
      return null;
    }

    final match = matcher.match(parseResult.extractedPokemonName);
    final pokemonId = match?.pokemonId;
    final matchedName = match?.canonicalName ?? parseResult.extractedPokemonName;
    final confidence = match?.confidence ?? parseResult.confidence;

    // Resolve pre-evolution for evolution events
    int? preEvoId;
    String? preEvoName;
    if (parseResult.type == ScannerEventType.evolved &&
        parseResult.extractedPreEvolutionName != null) {
      final preMatch = matcher.match(parseResult.extractedPreEvolutionName!);
      preEvoId = preMatch?.pokemonId;
      preEvoName = preMatch?.canonicalName ?? parseResult.extractedPreEvolutionName;
    }

    final isShiny = _settings.detectShinies && parseResult.isShiny;
    final isAlpha = _settings.detectAlphas && parseResult.isAlpha;

    // Duplicate check within cooldown window
    final duplicateKey = '${parseResult.type}_${pokemonId ?? matchedName}_$isShiny';
    final now = DateTime.now();
    if (_lastEmittedKey == duplicateKey && _lastEmittedTime != null) {
      if (now.difference(_lastEmittedTime!) < _duplicateCooldown) {
        return null;
      }
    }
    _lastEmittedKey = duplicateKey;
    _lastEmittedTime = now;

    final event = ScannerEvent(
      type: parseResult.type,
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
    );

    // Trigger feedback
    if (_settings.playAudioFeedback || _settings.playHapticFeedback) {
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

    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }

    return event;
  }

  /// Disposes subscriptions and controllers.
  Future<void> dispose() async {
    await _sourceSub?.cancel();
    _sourceSub = null;
    await _eventsController.close();
  }
}
