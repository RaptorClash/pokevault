import '../models/scanner_event.dart';
import '../models/scanner_settings.dart';
import 'ocr_noise_stop_words.dart';

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

/// Semantic egg-hatching cues used by the Shiny-Hunt auto-counter state machine.
enum EggHatchCue {
  none,
  ohPrompt,
  hatched,
}

/// Semantic soft-reset / title-screen cues used to re-arm a counted slot.
enum ResetCue {
  none,
  titleOrContinue,
  customReset,
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
  final String? matchedCustomPatternId;

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
    this.matchedCustomPatternId,
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
    r'(?:\berfolgreich\s+geflohen\b|\bentkommen\b|\bgot\s+away\s+safely\b|\bran\s+away\b|\b(?:wurde\s+besiegt|ging\s+k\.?o\.?|fainted)\b|vous\s+prenez\s+la\s+fuite|escapaste\s+sin\s+problemas|scappato\s+senza\s+problemi|にげきれた|도망쳤다|逃走了|逃跑了)',
    caseSensitive: false,
  );

  static final RegExp _eggPromptCuePattern = RegExp(
    r'(?:^|[\s"„“])(?:oh\?|nanu\?!|huh\?|¿eh\?|eh\?|おや？|어라\?|咦？)(?:$|[\s.!?"„“])',
    caseSensitive: false,
  );

  static final RegExp _softResetCuePattern = RegExp(
    r'^\s*(?:weiter|continue|continuer|continuar|continua|press\s+start|neues\s+spiel|new\s+game|spielstand|つづきから|さいしょから|이어하기|继续游戏|繼續遊戲)\s*[!:.▶►]*\s*$',
    caseSensitive: false,
  );

  // Egg Hatch Patterns across all 9 franchise languages
  static final List<({RegExp regex, String lang})> _eggHatchPatterns = [
    (
      regex: RegExp(
        r'Aus\s+dem\s+Ei\s+ist\s+(?:ein\s+|eine\s+)?([^\n\r!！]+?)\s+geschlüpft(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:Ein\s+|Eine\s+)?([^\n\r!！]+?)\s+ist\s+aus\s+dem\s+Ei\s+geschlüpft(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:An?\s+)?([^\n\r!！]+?)\s+hatched\s+from\s+the\s+Egg(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    (
      regex: RegExp(
        r"(?:Un\s+|Une\s+)?([^\n\r!！]+?)\s+vient\s+d'éclore(?:\s*[!！]|$)",
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    (
      regex: RegExp(
        r'¡?(?:Un\s+|Una\s+)?([^\n\r!！]+?)\s+salió\s+del\s+Huevo(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    (
      regex: RegExp(
        r"(?:Un\s+|Una\s+)?([^\n\r!！]+?)\s+è\s+nato\s+dall'Uovo(?:[!！]|$)",
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)が\s*タマゴから\s*かえった(?:[!！]|$)',
      ),
      lang: 'ja',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)(?:이|가)\s*알에서\s*태어났다(?:[!！]|$)',
      ),
      lang: 'ko',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)从蛋里孵出来了(?:[!！]|$)',
      ),
      lang: 'zh-Hans',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)從蛋裡孵出來了(?:[!！]|$)',
      ),
      lang: 'zh-Hant',
    ),
  ];

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

  static final RegExp _cjkPattern = RegExp(
    r'[\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]',
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
    r'(?:✨|\b(?:shiny|schillernd|chromatique|variocolor|cromatico)\b|いろちがい|色違い|이로치|异色|異色)',
    caseSensitive: false,
  );

  static final RegExp _alphaPattern = RegExp(
    r'(?:\b(?:alpha|elite|herrscher|baron|alfa)\b|オヤブン|우두머리|头目|頭目)',
    caseSensitive: false,
  );

  // Evolved Patterns: returns (pre, evolved, lang)
  static final List<({RegExp regex, String lang})> _evolutionPatterns = [
    (
      regex: RegExp(
        r'([^\n\r!！]+?)\s+hat sich zu\s+([^\n\r!！]+?)\s+entwickelt(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)\s+entwickelt sich zu\s+([^\n\r!！]+?)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)\s+evolved into\s+([^\n\r!！]+?)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)\s+a évolué en\s+([^\n\r!！]+?)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    (
      regex: RegExp(
        r'¡?([^\n\r!！]+?)\s+(?:ha\s+)?evolucionado\s+a\s+([^\n\r!！]+?)(?:[!！]|$)|¡?([^\n\r!！]+?)\s+evolucionó\s+a\s+([^\n\r!！]+?)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)\s+si è evoluto in\s+([^\n\r!！]+?)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    (
      regex: RegExp(
        r'([^\n\r!！]+?)は\s*([^\n\r!！]+?)に\s*しんかした(?:[!！]|$)',
      ),
      lang: 'ja',
    ),
    // Korean
    (
      regex: RegExp(
        r'([^\n\r!！]+?)(?:은\(는\)|은|는)\s*([^\n\r!！]+?)(?:\(으\)로|으로|로)\s*진화했다(?:[!！]|$)',
      ),
      lang: 'ko',
    ),
    // Simplified Chinese
    (
      regex: RegExp(
        r'([^\n\r!！]+?)进化成了\s*([^\n\r!！]+?)(?:[!！]|$)',
      ),
      lang: 'zh-Hans',
    ),
    // Traditional Chinese
    (
      regex: RegExp(
        r'([^\n\r!！]+?)進化成了\s*([^\n\r!！]+?)(?:[!！]|$)',
      ),
      lang: 'zh-Hant',
    ),
  ];

  // Caught Patterns: returns (pokemonName, lang)
  static final List<({RegExp regex, String lang})> _caughtPatterns = [
    // German
    (
      regex: RegExp(
        r'(?:(?:Kl[aeuw]s+e|Super|Toll|Heureka)[!.,]?\s+)?([^\n\r!！]+?)\s+wurde gefangen(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:(?:Kl[aeuw]s+e|Super|Toll|Heureka)[!.,]?\s+)?([^\n\r!！]+?)\s+gefangen(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    // English
    (
      regex: RegExp(
        r'(?:(?:Gotcha|All right)!\s+)?([^\n\r!！]+?)\s+was caught(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    (
      regex: RegExp(
        r'You caught\s+([^\n\r!！]+?)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    // French
    (
      regex: RegExp(
        r'(?:Et hop\s*!\s+)?([^\n\r!！]+?)\s+(?:est capturé|a été attrapé)\s*(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    // Spanish
    (
      regex: RegExp(
        r'(?:¡?Ya está!\s+)?¡?(?:Has atrapado a\s+([^\n\r!！]+?)|([^\n\r!！]+?)\s+atrapado)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    // Italian
    (
      regex: RegExp(
        r'(?:Preso!\s+)?(?:Hai catturato\s+([^\n\r!！]+?)|([^\n\r!！]+?)\s+è stato catturato)(?:[!！]|$)',
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    // Japanese
    (
      regex: RegExp(
        r'([^\n\r!！]+?)を\s*つかまえた(?:[!！]|$)',
      ),
      lang: 'ja',
    ),
    // Korean
    (
      regex: RegExp(
        r'(?:신난다[!！]?\s+)?([^\n\r!！]+?)(?:을\(를\)|을|를)\s*잡았다(?:[!！]|$)',
      ),
      lang: 'ko',
    ),
    // Simplified Chinese
    (
      regex: RegExp(
        r'(?:太好了[!！]?\s*)?(?:收服了\s*([^\n\r!！]+?)|([^\n\r!！]+?)被收服了)(?:[!！]|$)',
      ),
      lang: 'zh-Hans',
    ),
    // Traditional Chinese
    (
      regex: RegExp(
        r'(?:太好了[!！]?\s*)?(?:收服了\s*([^\n\r!！]+?)|([^\n\r!！]+?)被收服了)(?:[!！]|$)',
      ),
      lang: 'zh-Hant',
    ),
  ];

  // Encounter Patterns: returns (pokemonName, lang)
  static final List<({RegExp regex, String lang})> _encounterPatterns = [
    // German
    (
      regex: RegExp(
        r'(?:Ein\s+)?wildes?\s+([^\n\r!！]+?)\s+(?:erscheint|taucht auf|greift an)[!！]?',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    // English
    (
      regex: RegExp(
        r'Wild\s+([^\n\r!！]+?)\s+appeared[!！]?',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    // French
    (
      regex: RegExp(
        r'(?:Un|Une)\s+([^\n\r!！]+?)\s+sauvage\s+apparaît\s*[!！]?',
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    // Spanish
    (
      regex: RegExp(
        r'¡?(?:Un|Una)\s+([^\n\r!！]+?)\s+salvaje\s+apareció[!！]?',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    // Italian
    (
      regex: RegExp(
        r'(?:È\s+apparso\s+un|Appare\s+un)\s+([^\n\r!！]+?)\s+selvatico[!！]?',
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    // Japanese
    (
      regex: RegExp(
        r'やせいの\s*([^\n\r!！]+?)が\s*とびだしてきた[!！]?',
      ),
      lang: 'ja',
    ),
    // Korean
    (
      regex: RegExp(
        r'야생의\s*([^\n\r!！]+?)(?:이\(가\)|이|가)\s*나타났다[!！]?',
      ),
      lang: 'ko',
    ),
    // Simplified Chinese
    (
      regex: RegExp(
        r'野生的\s*([^\n\r!！]+?)\s*出现了[!！]?',
      ),
      lang: 'zh-Hans',
    ),
    // Traditional Chinese
    (
      regex: RegExp(
        r'野生的\s*([^\n\r!！]+?)\s*出現了[!！]?',
      ),
      lang: 'zh-Hant',
    ),
  ];

  static final List<({RegExp regex, String lang})> _multiEncounterPatterns = [
    // German: Double grass / Double battle / Horde / Outbreak across Gen 3-9
    (
      regex: RegExp(
        r'Ein\s+wildes?\s+([^\n\r!！]+?)\s+und\s+(?:ein\s+)?(?:wildes?\s+)?([^\n\r!！]+?)\s+(?:erscheint|erscheinen|greifen\s+an|tauchen\s+auf|sind\s+aufgetaucht)[!！]?',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    (
      regex: RegExp(
        r'(?:Eine\s+(?:Gruppe|Horde)\s+wilder|Wilde)\s+([^\n\r!！]+?)\s+(?:erscheint|erscheinen|greift\s+an|greifen\s+an|taucht\s+auf|tauchen\s+auf)[!！]?',
        caseSensitive: false,
      ),
      lang: 'de',
    ),
    // English: Double / Horde / SOS across Gen 3-9
    (
      regex: RegExp(
        r'(?:A\s+)?wild\s+([^\n\r!！]+?)\s+and\s+(?:a\s+)?(?:wild\s+)?([^\n\r!！]+?)\s+(?:appeared|attacked)[!！]?',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    (
      regex: RegExp(
        r'A\s+(?:horde|pack)\s+of\s+wild\s+([^\n\r!！]+?)\s+appeared[!！]?',
        caseSensitive: false,
      ),
      lang: 'en',
    ),
    // French
    (
      regex: RegExp(
        r'(?:Un|Une)\s+([^\n\r!！]+?)\s+et\s+(?:un|une)\s+([^\n\r!！]+?)\s+sauvages?\s+apparaissent\s*[!！]?|Une\s+horde\s+de\s+([^\n\r!！]+?)\s+sauvages\s+apparaît\s*[!！]?',
        caseSensitive: false,
      ),
      lang: 'fr',
    ),
    // Spanish
    (
      regex: RegExp(
        r'¡?(?:Un|Una)\s+([^\n\r!！]+?)\s+y\s+(?:un|una)\s+([^\n\r!！]+?)\s+salvajes\s+aparecieron[!！]?|¡?Una\s+horda\s+de\s+([^\n\r!！]+?)\s+salvajes\s+apareció[!！]?',
        caseSensitive: false,
      ),
      lang: 'es',
    ),
    // Italian
    (
      regex: RegExp(
        r'(?:Un|Una)\s+([^\n\r!！]+?)\s+e\s+(?:un|una)\s+([^\n\r!！]+?)\s+selvatici\s+appaiono[!！]?|Un\s+gruppo\s+di\s+([^\n\r!！]+?)\s+selvatici\s+è\s+apparso[!！]?',
        caseSensitive: false,
      ),
      lang: 'it',
    ),
    // Japanese
    (
      regex: RegExp(
        r'やせいの\s*([^\n\r!！]+?)と\s*([^\n\r!！]+?)が\s*とびだしてきた[!！]?',
      ),
      lang: 'ja',
    ),
    // Korean
    (
      regex: RegExp(
        r'야생의\s*([^\n\r!！]+?)(?:와|과)\s*([^\n\r!！]+?)(?:이|가)\s*나타났다[!！]?',
      ),
      lang: 'ko',
    ),
    // Chinese (Simplified & Traditional)
    (
      regex: RegExp(
        r'野生的\s*([^\n\r!！]+?)[和与與]\s*([^\n\r!！]+?)\s*(?:出现了|出現了)[!！]?',
      ),
      lang: 'zh-Hans',
    ),
  ];

  List<({
    String id,
    RegExp regex,
    ScannerEventType eventType,
    bool hasPokemonPlaceholder,
  })> _compiledCustomPatterns = const [];

  OcrDetectionEngine({List<CustomOcrPattern> customPatterns = const []}) {
    updateCustomPatterns(customPatterns);
  }

  /// Replaces the active custom OCR pattern list and compiles regexes once.
  void updateCustomPatterns(List<CustomOcrPattern> patterns) {
    final compiled = <({
      String id,
      RegExp regex,
      ScannerEventType eventType,
      bool hasPokemonPlaceholder,
    })>[];
    for (final p in patterns) {
      if (!p.enabled) continue;
      final regex = _compileCustomTemplate(
        p.template,
        allowLiteralWithoutPlaceholder:
            p.eventType == ScannerEventType.softReset ||
            p.eventType == ScannerEventType.customReset ||
            p.eventType == ScannerEventType.eggHatched ||
            p.eventType == ScannerEventType.encounter,
      );
      if (regex != null) {
        compiled.add((
          id: p.id,
          regex: regex,
          eventType: p.eventType,
          hasPokemonPlaceholder: p.template.contains('{pokemon}'),
        ));
      }
    }
    _compiledCustomPatterns = List.unmodifiable(compiled);
  }

  static RegExp? _compileCustomTemplate(
    String rawTemplate, {
    bool allowLiteralWithoutPlaceholder = false,
  }) {
    final template = rawTemplate.trim();
    if (template.isEmpty) return null;
    final hasPlaceholder = template.contains('{pokemon}');
    if (!hasPlaceholder && !allowLiteralWithoutPlaceholder) return null;

    final endsWithPokemon = hasPlaceholder && template.endsWith('{pokemon}');
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

  /// Classifies whether [rawText] indicates an egg-hatching prompt ("Oh?") or completion.
  EggHatchCue detectEggHatchCue(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return EggHatchCue.none;
    for (final ep in _eggHatchPatterns) {
      if (ep.regex.hasMatch(trimmed)) {
        return EggHatchCue.hatched;
      }
    }
    for (final line in trimmed.split(RegExp(r'[\r\n]+'))) {
      final lineTrimmed = line.trim();
      if (lineTrimmed.isNotEmpty && _eggPromptCuePattern.hasMatch(lineTrimmed)) {
        return EggHatchCue.ohPrompt;
      }
    }
    return EggHatchCue.none;
  }

  /// Classifies whether [rawText] indicates a soft-reset / title-screen cue or custom reset rule.
  ResetCue detectResetCue(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return ResetCue.none;
    for (final cp in _compiledCustomPatterns) {
      if (cp.id.startsWith('shiny_hunt:')) continue;
      if ((cp.eventType == ScannerEventType.customReset ||
              cp.eventType == ScannerEventType.softReset) &&
          cp.regex.hasMatch(trimmed)) {
        return ResetCue.customReset;
      }
    }
    for (final line in trimmed.split(RegExp(r'[\r\n]+'))) {
      final lineTrimmed = line.trim();
      if (lineTrimmed.isNotEmpty && _softResetCuePattern.hasMatch(lineTrimmed)) {
        return ResetCue.titleOrContinue;
      }
    }
    return ResetCue.none;
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
      final hudNames = <String>[];
      for (final rawLine in filteredLines) {
        final stripped = _stripHudLineMetadata(rawLine);
        if (stripped.isEmpty || _isInvalidCandidate(stripped)) continue;
        final subParts = stripped
            .split(RegExp(r'\s{2,}|[·|,/]+'))
            .map(_cleanName)
            .where((s) => s.isNotEmpty && !_isInvalidCandidate(s));
        for (final part in subParts) {
          if (part.length >= (_cjkPattern.hasMatch(part) ? 2 : 3)) {
            hudNames.add(part);
          }
        }
      }
      final joinedHud = filteredLines.join(' ').trim();
      final meaningfulTokens = joinedHud
          .split(RegExp(r'\s+'))
          .map((t) => t.replaceAll(RegExp(r'''[!?,.:;"'`’•·_«»‹›\[\]\(\)]+'''), ''))
          .where(
            (t) =>
                t.length >= (_cjkPattern.hasMatch(t) ? 2 : 3) &&
                _letterPattern.hasMatch(t) &&
                !_stopWordCandidatePattern.hasMatch(t) &&
                !_pureExclamationTriggerPattern.hasMatch(t),
          );
      if (joinedHud.isEmpty || (meaningfulTokens.isEmpty && hudNames.isEmpty)) {
        return null;
      }
      return OcrParseResult(
        type: ScannerEventType.encounter,
        extractedPokemonName: joinedHud,
        extractedPokemonNames: List.unmodifiable(hudNames),
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
        if (match != null) {
          if (!cp.hasPokemonPlaceholder) {
            return OcrParseResult(
              type: cp.eventType,
              extractedPokemonName: match.group(0)?.trim() ?? lineTrimmed,
              detectedLanguage: 'custom',
              isShiny: isShiny,
              gender: gender,
              isAlpha: isAlpha,
              confidence: 0.96,
              matchedCustomPatternId: cp.id,
            );
          }
          if (match.groupCount >= 1) {
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
                matchedCustomPatternId: cp.id,
              );
            }
          }
        }
      }

      // Check Egg Hatched
      for (final eh in _eggHatchPatterns) {
        final match = eh.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final name = _cleanName(_extractFirstGroup(match));
          if (name.isNotEmpty && !_isInvalidCandidate(name)) {
            return OcrParseResult(
              type: ScannerEventType.eggHatched,
              extractedPokemonName: name,
              detectedLanguage: eh.lang,
              isShiny: isShiny,
              gender: gender,
              isAlpha: isAlpha,
              confidence: 0.95,
            );
          }
        }
      }

      // Check Evolutions first
      for (final ep in _evolutionPatterns) {
        final match = ep.regex.firstMatch(lineTrimmed);
        if (match != null) {
          final (rawPre, rawEvo) = _extractTwoGroups(match);
          final pre = _cleanName(rawPre);
          final evo = _cleanName(rawEvo);
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
          final name = _cleanName(_extractFirstGroup(match));
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
          final name = _cleanName(_extractFirstGroup(match));
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
                t.length >= (_cjkPattern.hasMatch(t) ? 2 : 3) &&
                _letterPattern.hasMatch(t) &&
                !_stopWordCandidatePattern.hasMatch(t) &&
                !_pureExclamationTriggerPattern.hasMatch(t) &&
                !OcrNoiseStopWords.all.contains(t.toLowerCase()),
          );
      if (candidateText.isNotEmpty && meaningfulTokens.isNotEmpty) {
        final hasMultiCue = isEncounterContext &&
            RegExp(
              r'(?:\b(?:und|and|et|y|e|horde|gruppe|pack)\b|[&,と과和与與])',
              caseSensitive: false,
            ).hasMatch(candidateText);
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
          isMultiEncounter: hasMultiCue,
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
    final lower = trimmed.toLowerCase();
    if (_stopWordCandidatePattern.hasMatch(trimmed) ||
        OcrNoiseStopWords.all.contains(lower)) {
      return true;
    }
    // Reject purely numeric / symbol garbage like "1487"
    if (!_letterPattern.hasMatch(trimmed)) return true;
    return false;
  }

  String _extractFirstGroup(RegExpMatch match) {
    for (int g = 1; g <= match.groupCount; g++) {
      final value = match.group(g);
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  (String, String) _extractTwoGroups(RegExpMatch match) {
    final nonNull = <String>[];
    for (int g = 1; g <= match.groupCount; g++) {
      final value = match.group(g);
      if (value != null && value.trim().isNotEmpty) {
        nonNull.add(value);
      }
    }
    if (nonNull.length >= 2) {
      return (nonNull[0], nonNull[1]);
    }
    return ('', '');
  }

  String _cleanName(String raw) {
    var s = raw.trim();
    // Strip common surrounding noise / quotes / punctuation
    s = s.replaceAll(RegExp(r'^["\s¡!！]+|["\s!！]+$'), '');
    // Strip standalone leading indefinite articles (e.g. "ein Glumanda", "a Charmander")
    final withoutArticle = s.replaceFirst(
      RegExp(r'^(?:ein|eine|un|une|una|a|an)\s+', caseSensitive: false),
      '',
    );
    if (withoutArticle.trim().isNotEmpty) {
      s = withoutArticle.trim();
    }
    // Strip tags like (Männlich), (Weiblich), (Shiny), (schillernd), ♂, ♀, ✨, Alpha, Elite
    s = s.replaceAll(
      RegExp(
        r'[\(\[](?:männlich|weiblich|male|female|shiny|schillernd|chromatique|variocolor|cromatico|alpha|elite|baron|alfa)[\)\]]',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'[♂♀✨*]'), '');
    s = s.replaceAll(
      RegExp(
        r'\b(?:shiny|schillernd|chromatique|variocolor|cromatico|alpha|elite|baron|alfa)\b',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(
      RegExp(r'(?:いろちがい|色違い|이로치|异色|異色|オヤブン|우두머리|头目|頭目)'),
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

  String _stripHudLineMetadata(String rawLine) {
    var line = rawLine.trim();
    line = line.replaceAll(RegExp(r'[♂♀✨*]'), ' ');
    line = line.replaceAll(
      RegExp(r'(?:Lv|Lvl|Level)\.?\s*\d*', caseSensitive: false),
      ' ',
    );
    line = line.replaceAll(
      RegExp(r'\b(?:KP|HP)\b\s*\d*(?:/\d+)?', caseSensitive: false),
      ' ',
    );
    line = line.replaceAll(RegExp(r'\b\d+\s*[/\-–:]\s*\d+\b'), ' ');
    line = line.replaceAllMapped(
      RegExp(r'([A-Za-zÀ-ÿ])\s+([01|]+)\s+([A-Za-zÀ-ÿ])'),
      (m) => '${m[1]}${m[2]}${m[3]}',
    );
    line = line.replaceAll(RegExp(r'\b\d+(?:/\d+)?\b'), ' ');
    return _cleanName(line.replaceAll(RegExp(r'\s+'), ' ').trim());
  }
}
