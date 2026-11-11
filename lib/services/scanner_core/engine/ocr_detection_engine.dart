import '../models/scanner_event.dart';

/// Result from parsing raw OCR text through the [OcrDetectionEngine].
class OcrParseResult {
  final ScannerEventType type;
  final String extractedPokemonName;
  final String? extractedPreEvolutionName;
  final String? detectedLanguage;
  final bool isShiny;
  final String? gender;
  final bool isAlpha;
  final double confidence;

  const OcrParseResult({
    required this.type,
    required this.extractedPokemonName,
    this.extractedPreEvolutionName,
    this.detectedLanguage,
    this.isShiny = false,
    this.gender,
    this.isAlpha = false,
    this.confidence = 1.0,
  });
}

/// Multi-lingual regex and token parser for in-game dialogue and status text.
class OcrDetectionEngine {
  static final RegExp _noisePattern = RegExp(
    r'\b(?:beutel|flucht|tasche|speichern|gespeichert|options?|bericht|level\s*\d+|kp\s*\d+|setzt\s+.+\s+ein|used\s+.+|potion|ball)\b',
    caseSensitive: false,
  );

  static final RegExp _genderMalePattern = RegExp(
    r'(?:♂|\b(?:männlich|male)\b)',
    caseSensitive: false,
  );

  static final RegExp _genderFemalePattern = RegExp(
    r'(?:♀|\b(?:weiblich|female)\b)',
    caseSensitive: false,
  );

  static final RegExp _shinyPattern = RegExp(
    r'(?:✨|\b(?:shiny|schillernd)\b)',
    caseSensitive: false,
  );

  static final RegExp _alphaPattern = RegExp(
    r'\b(?:alpha|elite|herrscher)\b',
    caseSensitive: false,
  );

  // Evolved Patterns: returns (pre, evolved, lang)
  static final List<({RegExp regex, String lang})> _evolutionPatterns = [
    (
      regex: RegExp(
        r'([^\n\r!]+?)\s+hat sich zu\s+([^\n\r!]+?)\s+entwickelt(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'([^\n\r!]+?)\s+entwickelt sich zu\s+([^\n\r!]+)(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'([^\n\r!]+?)\s+evolved into\s+([^\n\r!]+)(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    (
      regex: RegExp(
        r'([^\n\r!]+?)\s+a évolué en\s+([^\n\r!]+)(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    (
      regex: RegExp(
        r'¡?([^\n\r!]+?)\s+evolucionó a\s+([^\n\r!]+)(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    (
      regex: RegExp(
        r'([^\n\r!]+?)\s+si è evoluto in\s+([^\n\r!]+)(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    (
      regex: RegExp(
        r'([^\n\r!]+?)は\s*([^\n\r!]+?)に\s*しんかした(?:!|$)',
      ),
      lang: 'ja',
    ),
  ];

  // Caught Patterns: returns (pokemonName, lang)
  static final List<({RegExp regex, String lang})> _caughtPatterns = [
    // German
    (
      regex: RegExp(
        r'(?:(?:Klasse|Super|Toll)!\s+)?([^\n\r!]+?)\s+wurde gefangen(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:(?:Klasse|Super|Toll)!\s+)?([^\n\r!]+?)\s+gefangen(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    // English
    (
      regex: RegExp(
        r'(?:(?:Gotcha|All right)!\s+)?([^\n\r!]+?)\s+was caught(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    (
      regex: RegExp(
        r'You caught\s+([^\n\r!]+)(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    // French
    (
      regex: RegExp(
        r'(?:Et hop!\s+)?([^\n\r!]+?)\s+est capturé(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    // Spanish
    (
      regex: RegExp(
        r'(?:¡?Ya está!\s+)?¡?([^\n\r!]+?)\s+atrapado(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    // Italian
    (
      regex: RegExp(
        r'(?:Preso!\s+)?Hai catturato\s+([^\n\r!]+)(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    // Japanese
    (
      regex: RegExp(
        r'([^\n\r!]+?)を\s*つかまえた(?:!|$)',
      ),
      lang: 'ja',
    ),
  ];

  // Encounter Patterns: returns (pokemonName, lang)
  static final List<({RegExp regex, String lang})> _encounterPatterns = [
    // German
    (
      regex: RegExp(
        r'(?:Ein\s+)?wildes?\s+([^\n\r!]+?)\s+(?:erscheint|taucht auf|greift an)!?',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    // English
    (
      regex: RegExp(
        r'Wild\s+([^\n\r!]+?)\s+appeared!?',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    // French
    (
      regex: RegExp(
        r'Un\s+([^\n\r!]+?)\s+sauvage apparaît!?',
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    // Spanish
    (
      regex: RegExp(
        r'¡?Un\s+([^\n\r!]+?)\s+salvaje apareció!?',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    // Italian
    (
      regex: RegExp(
        r'Appare un\s+([^\n\r!]+?)\s+selvatico!?',
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    // Japanese
    (
      regex: RegExp(
        r'やせいの\s*([^\n\r!]+?)が\s*とびだしてきた!?',
      ),
      lang: 'ja',
    ),
  ];

  /// Parses [rawText] into an [OcrParseResult], or returns `null` if the text contains no valid game events.
  OcrParseResult? parse(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return null;

    final isShiny = _shinyPattern.hasMatch(trimmed);
    final isAlpha = _alphaPattern.hasMatch(trimmed);

    String? gender;
    if (_genderMalePattern.hasMatch(trimmed)) {
      gender = 'male';
    } else if (_genderFemalePattern.hasMatch(trimmed)) {
      gender = 'female';
    }

    // Split text into lines to support multi-line OCR frames
    final lines = trimmed.split(RegExp(r'[\r\n]+'));

    for (final line in lines) {
      final lineTrimmed = line.trim();
      if (lineTrimmed.isEmpty) continue;

      // Check Evolutions first
      for (final ep in _evolutionPatterns) {
        final match = ep.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final pre = _cleanName(match.group(1) ?? '');
          final evo = _cleanName(match.group(2) ?? '');
          if (pre.isNotEmpty && evo.isNotEmpty) {
            return OcrParseResult(
              type: ScannerEventType.evolved,
              extractedPokemonName: evo,
              extractedPreEvolutionName: pre,
              detectedLanguage: ep.lang,
              isShiny: isShiny,
              gender: gender,
              isAlpha: isAlpha,
              confidence: 0.95,
            );
          }
        }
      }

      // Check Caught
      for (final cp in _caughtPatterns) {
        final match = cp.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final name = _cleanName(match.group(1) ?? '');
          if (name.isNotEmpty && !_isNoise(name)) {
            return OcrParseResult(
              type: ScannerEventType.caught,
              extractedPokemonName: name,
              detectedLanguage: cp.lang,
              isShiny: isShiny,
              gender: gender,
              isAlpha: isAlpha,
              confidence: 0.95,
            );
          }
        }
      }

      // Check Encounter
      for (final ec in _encounterPatterns) {
        final match = ec.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final name = _cleanName(match.group(1) ?? '');
          if (name.isNotEmpty && !_isNoise(name)) {
            return OcrParseResult(
              type: ScannerEventType.encounter,
              extractedPokemonName: name,
              detectedLanguage: ec.lang,
              isShiny: isShiny,
              gender: gender,
              isAlpha: isAlpha,
              confidence: 0.90,
            );
          }
        }
      }
    }

    return null;
  }

  bool _isNoise(String text) {
    if (text.trim().isEmpty) return true;
    return _noisePattern.hasMatch(text);
  }

  String _cleanName(String raw) {
    var s = raw.trim();
    // Strip common surrounding noise / quotes / punctuation
    s = s.replaceAll(RegExp(r'^["\s¡!]+|["\s!]+$'), '');
    // Strip tags like (Männlich), (Weiblich), (Shiny), (schillernd), ♂, ♀, ✨, Alpha, Elite
    s = s.replaceAll(
      RegExp(
        r'[\(\[](?:männlich|weiblich|male|female|shiny|schillernd|alpha|elite)[\)\]]',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'[♂♀✨*]'), '');
    s = s.replaceAll(
      RegExp(r'\b(?:shiny|alpha|elite)\b', caseSensitive: false),
      '',
    );
    return s.trim();
  }
}
