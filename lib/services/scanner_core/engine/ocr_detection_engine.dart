import '../models/scanner_event.dart';
import '../models/scanner_settings.dart';

/// Specifies which UI region / semantic role an OCR scan came from.
enum OcrScanRole {
  /// Dialogue / textbox / catch confirmation scanner.
  dialogueAndCatch,

  /// Opponent HUD scanner: strictly extracts encounter/focus targets, never catches.
  enemyHudFocusOnly,
}

/// Semantic combat-phase cues used by the single-screen battle state machine.
enum BattleCue {
  none,
  battleMenu,
  battleEnded,
}

/// Result from parsing raw OCR text through the [OcrDetectionEngine].
class OcrParseResult {
  final ScannerEventType type;
  final String extractedPokemonName;
  final List<String> extractedPokemonNames;
  final String? extractedPreEvolutionName;
  final String? detectedLanguage;
  final bool isShiny;
  final String? gender;
  final bool isAlpha;
  final double confidence;
  final bool isSmartSearchFallback;
  final bool isMultiEncounter;

  const OcrParseResult({
    required this.type,
    required this.extractedPokemonName,
    this.extractedPokemonNames = const [],
    this.extractedPreEvolutionName,
    this.detectedLanguage,
    this.isShiny = false,
    this.gender,
    this.isAlpha = false,
    this.confidence = 1.0,
    this.isSmartSearchFallback = false,
    this.isMultiEncounter = false,
  });
}

/// Multi-lingual regex and token parser for in-game dialogue and status text.
class OcrDetectionEngine {
  static final RegExp _noisePattern = RegExp(
    r'\b(?:was\s+soll|soll\s+\S+(?:\s+\S+)?\s+tun|what\s+will|will\s+\S+(?:\s+\S+)?\s+do|spitzname\w*|nickname\w*|beutel|flucht|tasche|speichern|gespeichert|options?|bericht|level\s*\d+|kp\s*\d+|setzt\s+.+\s+ein|used\s+.+|potion|ball)\b',
    caseSensitive: false,
  );

  static final RegExp _battlePromptPattern = RegExp(
    r'(?:\b(?:was|wlas|klas|kas)\s+soll\b|\bsoll\s+\S+(?:\s+\S+)?\s+(?:tun|t[l1i][.rn]{1,3}\S*|tt\.rn\S*)\??|\bwhat\s+will\b|\bwill\s+[^\n\r?]+\s+do\??|\bgib\b[^\n\r?]*\bspitzname|\bnickname\b|\b(?:kampf|fight)\b.*\b(?:beutel|bag)\b.*\b(?:flucht|run)\b)',
    caseSensitive: false,
  );

  static final RegExp _battleEndCuePattern = RegExp(
    r'(?:\berfolgreich\s+geflohen\b|\bentkommen\b|\bgot\s+away\s+safely\b|\bran\s+away\b|\b(?:wurde\s+besiegt|ging\s+k\.?o\.?|fainted)\b)',
    caseSensitive: false,
  );

  static final RegExp _uiOrCounterPattern = RegExp(
    r'(?:\b[o0-9]+\s*(?:von|of|/)\s*\d+\b|^\s*[o0-9]+\s+(?:gefangen|caught)\s*$|\b(?:ziel-?pok[eé]dex|live-?ereignisse|aktueller\s+live-?fokus|fehlt\s+im\s+ziel-?dex|scan-?bereich|desktop\s+tracker|ocr\s+aktiv|floating\s+hud)\b)',
    caseSensitive: false,
  );

  static final RegExp _emulatorChromePattern = RegExp(
    r'(?:\[\s*\d+\s*/\s*\d+\s*[\]\)]?|\b(?:melonds|desmume|mgba|retroarch|citra|azahar|ryujinx|yuzu)\b|\bfile\s+system\b|\bview\s+config\b|\bconfig\s+help\b|^\s*\d+\s+[a-z]{1,2}\s*$|^\s*\d+\s*/\s*\d+\s*$)',
    caseSensitive: false,
  );

  static final RegExp _smartCatchContextPattern = RegExp(
    r'(?:\b(?:klasse|klase|klas|super|prima|gotcha|hurra)\s*!|\bw[uü]?r?d[ea]\b|\b(?:gefangen|aefar\S*|gefan\S*|caught|captur\S*)\b)',
    caseSensitive: false,
  );

  static final RegExp _smartEncounterContextPattern = RegExp(
    r'(?:\b(?:wildes|wilde|wild)\b|\bersch(?:eint|ien|in)\b|\bappea?r\S*\b|\bsalvaje\b|\bsauvage\b)',
    caseSensitive: false,
  );

  static final RegExp _pureExclamationTriggerPattern = RegExp(
    r'^(?:klasse|klase|klas|super|prima|gotcha|hurra|toll)[!.\s]*$',
    caseSensitive: false,
  );

  static final RegExp _letterPattern = RegExp(
    r'[A-Za-zÀ-ÿ\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]',
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
        r'(?:(?:Kl[aeuw]s+e|Super|Toll|Heureka)[!.,]?\s+)?([^\n\r!]+?)\s+wurde gefangen(?:!|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:(?:Kl[aeuw]s+e|Super|Toll|Heureka)[!.,]?\s+)?([^\n\r!]+?)\s+gefangen(?:!|$)',
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

  static final List<({RegExp regex, String lang})> _multiEncounterPatterns = [
    (
      regex: RegExp(
        r'Ein\s+wildes?\s+([^\n\r!]+?)\s+und\s+(?:ein\s+)?wildes?\s+([^\n\r!]+?)\s+(?:erscheint|erscheinen)!?',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:Eine\s+Gruppe\s+wilder|Wilde)\s+([^\n\r!]+?)\s+(?:erscheint|erscheinen)!?',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:A\s+)?wild\s+([^\n\r!]+?)\s+and\s+(?:a\s+)?wild\s+([^\n\r!]+?)\s+appeared!?',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    (
      regex: RegExp(
        r'A\s+(?:horde|pack)\s+of\s+wild\s+([^\n\r!]+?)\s+appeared!?',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
  ];

  List<({RegExp regex, ScannerEventType eventType})> _compiledCustomPatterns =
      const [];

  OcrDetectionEngine({List<CustomOcrPattern> customPatterns = const []}) {
    updateCustomPatterns(customPatterns);
  }

  /// Replaces the active custom OCR pattern list and compiles regexes once.
  void updateCustomPatterns(List<CustomOcrPattern> patterns) {
    final compiled = <({RegExp regex, ScannerEventType eventType})>[];
    for (final p in patterns) {
      if (!p.enabled) continue;
      final regex = _compileCustomTemplate(p.template);
      if (regex != null) {
        compiled.add((regex: regex, eventType: p.eventType));
      }
    }
    _compiledCustomPatterns = List.unmodifiable(compiled);
  }

  static RegExp? _compileCustomTemplate(String rawTemplate) {
    final template = rawTemplate.trim();
    if (template.isEmpty || !template.contains('{pokemon}')) return null;

    final endsWithPokemon = template.endsWith('{pokemon}');
    final buffer = StringBuffer();
    int idx = 0;
    while (idx < template.length) {
      if (template.startsWith('{pokemon}', idx)) {
        final atEnd = endsWithPokemon && idx + 9 == template.length;
        buffer.write(atEnd ? r'([^\n\r!?]+?)\s*[!?.]*$' : r'([^\n\r!?]+?)');
        idx += 9;
      } else if (template[idx] == '*') {
        buffer.write(r'.*?');
        idx += 1;
      } else {
        buffer.write(RegExp.escape(template[idx]));
        idx += 1;
      }
    }
    return RegExp(buffer.toString(), caseSensitive: false);
  }

  /// Classifies whether [rawText] indicates an ongoing battle command menu
  /// or an explicit battle-end message (fled / defeated / fainted) for the
  /// single-screen battle-state deduplication tracker.
  BattleCue detectBattleCue(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return BattleCue.none;
    if (_battleEndCuePattern.hasMatch(trimmed)) {
      return BattleCue.battleEnded;
    }
    if (_battlePromptPattern.hasMatch(trimmed)) {
      return BattleCue.battleMenu;
    }
    return BattleCue.none;
  }

  /// Parses [rawText] into an [OcrParseResult], or returns `null` if the text contains no valid game events.
  OcrParseResult? parse(
    String rawText, {
    OcrScanRole role = OcrScanRole.dialogueAndCatch,
  }) {
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

    // Split text into lines, strip PokeVault HUD/emulator chrome & noise lines,
    // and add a joined dialogue view so multi-line DS boxes match cleanly.
    final lines = trimmed
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final filteredLines = lines
        .where(
          (l) =>
              !_uiOrCounterPattern.hasMatch(l) &&
              !_emulatorChromePattern.hasMatch(l) &&
              !_noisePattern.hasMatch(l) &&
              !_battlePromptPattern.hasMatch(l),
        )
        .toList();
    if (filteredLines.isEmpty) return null;

    // Dedicated enemy HUD focus role (Zone B): never emit caught/evolved, allow multi-enemy names.
    if (role == OcrScanRole.enemyHudFocusOnly) {
      final joinedHud = filteredLines.join(' ').trim();
      final meaningfulTokens = joinedHud
          .split(RegExp(r'\s+'))
          .map((t) => t.replaceAll(RegExp(r'''[!?,.:;"'`’•·_«»‹›\[\]\(\)]+'''), ''))
          .where(
            (t) =>
                t.length >= 3 &&
                _letterPattern.hasMatch(t) &&
                !_stopWordCandidatePattern.hasMatch(t) &&
                !_pureExclamationTriggerPattern.hasMatch(t),
          );
      if (joinedHud.isEmpty || meaningfulTokens.isEmpty) return null;
      return OcrParseResult(
        type: ScannerEventType.encounter,
        extractedPokemonName: joinedHud,
        detectedLanguage: null,
        isShiny: isShiny,
        gender: gender,
        isAlpha: isAlpha,
        confidence: 0.85,
        isSmartSearchFallback: true,
        isMultiEncounter: true,
      );
    }

    final candidates = <String>[
      if (filteredLines.length > 1) filteredLines.join(' '),
      ...filteredLines,
    ];

    for (final lineTrimmed in candidates) {
      // Reject player battle-command / nickname prompts even when split across lines
      if (_battlePromptPattern.hasMatch(lineTrimmed)) {
        continue;
      }

      // Check user custom patterns first (allows explicit overrides per game/ROM)
      for (final cp in _compiledCustomPatterns) {
        final match = cp.regex.firstMatch(lineTrimmed);
        if (match != null && match.groupCount >= 1) {
          final name = _cleanName(match.group(1) ?? '');
          if (name.isNotEmpty && !_isInvalidCandidate(name)) {
            return OcrParseResult(
              type: cp.eventType,
              extractedPokemonName: name,
              detectedLanguage: 'custom',
              isShiny: isShiny,
              gender: gender,
              isAlpha: isAlpha,
              confidence: 0.96,
              isSmartSearchFallback: name.contains(' '),
            );
          }
        }
      }

      // Check Evolutions first
      for (final ep in _evolutionPatterns) {
        final match = ep.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final pre = _cleanName(match.group(1) ?? '');
          final evo = _cleanName(match.group(2) ?? '');
          if (pre.isNotEmpty &&
              evo.isNotEmpty &&
              !_isInvalidCandidate(pre) &&
              !_isInvalidCandidate(evo)) {
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
          if (name.isNotEmpty && !_isInvalidCandidate(name)) {
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

      // Check Multi-Encounter / Horde / Double Battle BEFORE single-encounter patterns
      for (final me in _multiEncounterPatterns) {
        final match = me.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final groups = <String>[];
          for (int g = 1; g <= match.groupCount; g++) {
            final grp = match.group(g);
            if (grp != null && grp.trim().isNotEmpty) {
              groups.add(grp);
            }
          }
          final names = _splitMultiPokemonNames(groups);
          if (names.isNotEmpty) {
            return OcrParseResult(
              type: ScannerEventType.encounter,
              extractedPokemonName: names.first,
              extractedPokemonNames: names,
              detectedLanguage: me.lang,
              isShiny: isShiny,
              gender: gender,
              isAlpha: isAlpha,
              confidence: 0.92,
              isMultiEncounter: true,
            );
          }
        }
      }

      // Check Single Encounter
      for (final ec in _encounterPatterns) {
        final match = ec.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final name = _cleanName(match.group(1) ?? '');
          if (name.isNotEmpty && !_isInvalidCandidate(name)) {
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

    // Smart-Search Context Fallback: when DS pixel fonts garble dialogue verbs
    // (e.g. "Klasse!\nZr-rrokex wrde aefar«t!"), retain non-chrome dialogue tokens
    // so PokemonFuzzyMatcher.matchTokensFromLine can resolve the Pokémon.
    final dialogueText = filteredLines.join(' ');
    if (_battlePromptPattern.hasMatch(dialogueText) ||
        _battlePromptPattern.hasMatch(trimmed)) {
      return null;
    }
    final isCatchContext = _smartCatchContextPattern.hasMatch(dialogueText);
    final isEncounterContext =
        !isCatchContext && _smartEncounterContextPattern.hasMatch(dialogueText);

    if (isCatchContext || isEncounterContext) {
      final candidateLines = filteredLines
          .where((l) => !_pureExclamationTriggerPattern.hasMatch(l))
          .toList();
      final candidateText = (candidateLines.isNotEmpty
              ? candidateLines.join(' ')
              : dialogueText)
          .trim();
      final meaningfulTokens = candidateText
          .split(RegExp(r'\s+'))
          .map((t) => t.replaceAll(RegExp(r'''[!?,.:;"'`’•·_«»‹›\[\]\(\)]+'''), ''))
          .where(
            (t) =>
                t.length >= 3 &&
                _letterPattern.hasMatch(t) &&
                !_stopWordCandidatePattern.hasMatch(t) &&
                !_pureExclamationTriggerPattern.hasMatch(t) &&
                !RegExp(
                  r'^(?:gefangen|caught|appeared|erscheint|wildes|wilde|wild)$',
                  caseSensitive: false,
                ).hasMatch(t),
          );
      if (candidateText.isNotEmpty && meaningfulTokens.isNotEmpty) {
        return OcrParseResult(
          type: isCatchContext
              ? ScannerEventType.caught
              : ScannerEventType.encounter,
          extractedPokemonName: candidateText,
          detectedLanguage: null,
          isShiny: isShiny,
          gender: gender,
          isAlpha: isAlpha,
          confidence: 0.78,
          isSmartSearchFallback: true,
        );
      }
    }

    return null;
  }

  bool _isNoise(String text) {
    if (text.trim().isEmpty) return true;
    return _noisePattern.hasMatch(text) || _uiOrCounterPattern.hasMatch(text);
  }

  static final RegExp _stopWordCandidatePattern = RegExp(
    r'^(?:wurde|worden|was|were|been|ist|est|ein|eine|einer|der|die|das|the|you|du|es)$',
    caseSensitive: false,
  );

  bool _isInvalidCandidate(String candidate) {
    final trimmed = candidate.trim();
    if (_isNoise(trimmed)) return true;
    if (_stopWordCandidatePattern.hasMatch(trimmed)) return true;
    // Reject purely numeric / symbol garbage like "1487"
    if (!_letterPattern.hasMatch(trimmed)) return true;
    return false;
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

  List<String> _splitMultiPokemonNames(List<String> rawGroups) {
    final out = <String>[];
    final seen = <String>{};
    for (final group in rawGroups) {
      final parts = group.split(
        RegExp(r'(?:,|\s+(?:und|and|&)\s+)', caseSensitive: false),
      );
      for (final part in parts) {
        final cleaned = _cleanName(part);
        if (cleaned.isEmpty || _isInvalidCandidate(cleaned)) continue;
        final key = cleaned.toLowerCase();
        if (seen.add(key)) {
          out.add(cleaned);
        }
      }
    }
    return List.unmodifiable(out);
  }
}
