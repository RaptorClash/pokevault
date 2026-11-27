import '../engine/pokemon_fuzzy_matcher.dart';

/// Enumeration of recognized in-game scanner events.
enum ScannerEventType {
  encounter,
  caught,
  evolved,
  shinyDetected,
  alphaDetected,
  eggHatched,
  softReset,
  customReset,
  unknown,
}

/// Represents an immutable event produced by the ScannerCore engine.
class ScannerEvent {
  final ScannerEventType type;
  final int? pokemonId;
  final String rawText;
  final String matchedName;
  final bool isShiny;
  final String? gender; // 'male', 'female', or null
  final bool isAlpha;
  final int? preEvolutionId;
  final String? preEvolutionName;
  final double confidence;
  final DateTime timestamp;
  final String? languageCode;
  final List<FuzzyMatchResult> alternatives;
  final bool isSmartMatch;
  final bool autoAddedCaught;
  final bool autoAddedShiny;
  final bool autoAddedAlpha;
  final int? instanceIndex;
  final int? instanceColorHex;
  final int encounterCount;
  final String? matchedCustomPatternId;

  const ScannerEvent({
    required this.type,
    this.pokemonId,
    required this.rawText,
    required this.matchedName,
    this.isShiny = false,
    this.gender,
    this.isAlpha = false,
    this.preEvolutionId,
    this.preEvolutionName,
    this.confidence = 1.0,
    required this.timestamp,
    this.languageCode,
    this.alternatives = const [],
    this.isSmartMatch = false,
    this.autoAddedCaught = false,
    this.autoAddedShiny = false,
    this.autoAddedAlpha = false,
    this.instanceIndex,
    this.instanceColorHex,
    this.encounterCount = 1,
    this.matchedCustomPatternId,
  });

  ScannerEvent copyWith({
    ScannerEventType? type,
    int? pokemonId,
    String? rawText,
    String? matchedName,
    bool? isShiny,
    String? gender,
    bool? isAlpha,
    int? preEvolutionId,
    String? preEvolutionName,
    double? confidence,
    DateTime? timestamp,
    String? languageCode,
    List<FuzzyMatchResult>? alternatives,
    bool? isSmartMatch,
    bool? autoAddedCaught,
    bool? autoAddedShiny,
    bool? autoAddedAlpha,
    int? instanceIndex,
    int? instanceColorHex,
    int? encounterCount,
    String? matchedCustomPatternId,
  }) {
    return ScannerEvent(
      type: type ?? this.type,
      pokemonId: pokemonId ?? this.pokemonId,
      rawText: rawText ?? this.rawText,
      matchedName: matchedName ?? this.matchedName,
      isShiny: isShiny ?? this.isShiny,
      gender: gender ?? this.gender,
      isAlpha: isAlpha ?? this.isAlpha,
      preEvolutionId: preEvolutionId ?? this.preEvolutionId,
      preEvolutionName: preEvolutionName ?? this.preEvolutionName,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      languageCode: languageCode ?? this.languageCode,
      alternatives: alternatives ?? this.alternatives,
      isSmartMatch: isSmartMatch ?? this.isSmartMatch,
      autoAddedCaught: autoAddedCaught ?? this.autoAddedCaught,
      autoAddedShiny: autoAddedShiny ?? this.autoAddedShiny,
      autoAddedAlpha: autoAddedAlpha ?? this.autoAddedAlpha,
      instanceIndex: instanceIndex ?? this.instanceIndex,
      instanceColorHex: instanceColorHex ?? this.instanceColorHex,
      encounterCount: encounterCount ?? this.encounterCount,
      matchedCustomPatternId:
          matchedCustomPatternId ?? this.matchedCustomPatternId,
    );
  }

  @override
  String toString() {
    return 'ScannerEvent(type: $type, id: $pokemonId, name: $matchedName, shiny: $isShiny, alpha: $isAlpha, confidence: $confidence)';
  }
}
