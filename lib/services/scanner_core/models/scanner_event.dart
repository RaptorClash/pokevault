/// Enumeration of recognized in-game scanner events.
enum ScannerEventType {
  encounter,
  caught,
  evolved,
  shinyDetected,
  alphaDetected,
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
  });

  @override
  String toString() {
    return 'ScannerEvent(type: $type, id: $pokemonId, name: $matchedName, shiny: $isShiny, alpha: $isAlpha, confidence: $confidence)';
  }
}
