import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';

void main() {
  group('OcrDetectionEngine Tests (TDD & Adversarial)', () {
    late OcrDetectionEngine engine;

    setUp(() {
      engine = OcrDetectionEngine();
    });

    group('Caught messages (Multi-Language)', () {
      test('German catch phrases', () {
        final r1 = engine.parse('Glumanda wurde gefangen!');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.caught);
        expect(r1.extractedPokemonName, 'Glumanda');
        expect(r1.detectedLanguage, 'de');

        final r2 = engine.parse('Klasse! Pikachu wurde gefangen!');
        expect(r2, isNotNull);
        expect(r2!.type, ScannerEventType.caught);
        expect(r2.extractedPokemonName, 'Pikachu');

        final r3 = engine.parse('Toll! Mewtu gefangen!');
        expect(r3, isNotNull);
        expect(r3!.type, ScannerEventType.caught);
        expect(r3.extractedPokemonName, 'Mewtu');
      });

      test('English catch phrases', () {
        final r1 = engine.parse('Gotcha! Charmander was caught!');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.caught);
        expect(r1.extractedPokemonName, 'Charmander');
        expect(r1.detectedLanguage, 'en');

        final r2 = engine.parse('All right! Pikachu was caught!');
        expect(r2, isNotNull);
        expect(r2!.extractedPokemonName, 'Pikachu');

        final r3 = engine.parse('Squirtle was caught!');
        expect(r3, isNotNull);
        expect(r3!.extractedPokemonName, 'Squirtle');
      });

      test('French catch phrases', () {
        final r1 = engine.parse('Salamèche est capturé!');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.caught);
        expect(r1.extractedPokemonName, 'Salamèche');
        expect(r1.detectedLanguage, 'fr');

        final r2 = engine.parse('Et hop! Carapuce est capturé!');
        expect(r2, isNotNull);
        expect(r2!.extractedPokemonName, 'Carapuce');
      });

      test('Spanish catch phrases', () {
        final r1 = engine.parse('¡Charmander atrapado!');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.caught);
        expect(r1.extractedPokemonName, 'Charmander');
        expect(r1.detectedLanguage, 'es');

        final r2 = engine.parse('¡Ya está! ¡Pikachu atrapado!');
        expect(r2, isNotNull);
        expect(r2!.extractedPokemonName, 'Pikachu');
      });

      test('Italian catch phrases', () {
        final r1 = engine.parse('Hai catturato Charmander!');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.caught);
        expect(r1.extractedPokemonName, 'Charmander');
        expect(r1.detectedLanguage, 'it');

        final r2 = engine.parse('Preso! Hai catturato Pikachu!');
        expect(r2, isNotNull);
        expect(r2!.extractedPokemonName, 'Pikachu');
      });

      test('Japanese catch phrases', () {
        final r1 = engine.parse('ヒトカゲを つかまえた!');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.caught);
        expect(r1.extractedPokemonName, 'ヒトカゲ');
        expect(r1.detectedLanguage, 'ja');

        final r2 = engine.parse('ピカチュウをつかまえた!');
        expect(r2, isNotNull);
        expect(r2!.extractedPokemonName, 'ピカチュウ');
      });
    });

    group('Encounter messages (Multi-Language)', () {
      test('German encounter phrases', () {
        final r1 = engine.parse('Ein wildes Glumanda erscheint!');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.encounter);
        expect(r1.extractedPokemonName, 'Glumanda');

        final r2 = engine.parse('Wilde Taubsi greift an!');
        expect(r2, isNotNull);
        expect(r2!.type, ScannerEventType.encounter);
        expect(r2.extractedPokemonName, 'Taubsi');
      });

      test('English encounter phrases', () {
        final r = engine.parse('Wild Charmander appeared!');
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.encounter);
        expect(r.extractedPokemonName, 'Charmander');
      });

      test('Japanese encounter phrases', () {
        final r = engine.parse('やせいの ヒトカゲが とびだしてきた!');
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.encounter);
        expect(r.extractedPokemonName, 'ヒトカゲ');
      });
    });

    group('Evolution messages (Multi-Language)', () {
      test('German evolution phrases', () {
        final r = engine.parse('Glumanda hat sich zu Glutexo entwickelt!');
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.evolved);
        expect(r.extractedPokemonName, 'Glutexo');
        expect(r.extractedPreEvolutionName, 'Glumanda');
        expect(r.detectedLanguage, 'de');
      });

      test('English evolution phrases', () {
        final r = engine.parse('Charmander evolved into Charmeleon!');
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.evolved);
        expect(r.extractedPokemonName, 'Charmeleon');
        expect(r.extractedPreEvolutionName, 'Charmander');
        expect(r.detectedLanguage, 'en');
      });

      test('French evolution phrases', () {
        final r = engine.parse('Salamèche a évolué en Reptincel!');
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.evolved);
        expect(r.extractedPokemonName, 'Reptincel');
        expect(r.extractedPreEvolutionName, 'Salamèche');
      });

      test('Japanese evolution phrases', () {
        final r = engine.parse('ヒトカゲは リザードに しんかした!');
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.evolved);
        expect(r.extractedPokemonName, 'リザード');
        expect(r.extractedPreEvolutionName, 'ヒトカゲ');
      });
    });

    group('Metadata extraction (Gender, Shiny, Alpha)', () {
      test('Extracts male and female symbols and words', () {
        final r1 = engine.parse('Gotcha! Charmander ♂ was caught!');
        expect(r1?.gender, 'male');

        final r2 = engine.parse('Gotcha! Pikachu ♀ was caught!');
        expect(r2?.gender, 'female');

        final r3 = engine.parse('Glumanda (Männlich) wurde gefangen!');
        expect(r3?.gender, 'male');
      });

      test('Extracts Shiny indicators', () {
        final r1 = engine.parse('✨ Wild Charmander appeared!');
        expect(r1?.isShiny, isTrue);

        final r2 = engine.parse('Gotcha! Shiny Charmander was caught!');
        expect(r2?.isShiny, isTrue);

        final r3 = engine.parse('Glumanda (schillernd) wurde gefangen!');
        expect(r3?.isShiny, isTrue);
      });

      test('Extracts Alpha indicators', () {
        final r1 = engine.parse('Alpha Knakrack wurde gefangen!');
        expect(r1?.isAlpha, isTrue);

        final r2 = engine.parse('Elite Garchomp was caught!');
        expect(r2?.isAlpha, isTrue);
      });
    });

    group('Adversarial & Noise filtration', () {
      test('Ignores standard UI labels and battle text', () {
        expect(engine.parse(''), isNull);
        expect(engine.parse('    \n\t  '), isNull);
        expect(engine.parse('BEUTEL   POKÉMON   FLUCHT'), isNull);
        expect(engine.parse('Glumanda setzt Glut ein!'), isNull);
        expect(engine.parse('Kp 45/45   Lv. 12'), isNull);
        expect(engine.parse('Das Spiel wurde gespeichert.'), isNull);
      });

      test('Extracts dialogue from multi-line text blocks', () {
        const multiLine = '''
[TOP BAR] LVL 5
Ein wildes Glumanda ♂ erscheint!
[HP 100/100]
''';
        final r = engine.parse(multiLine);
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.encounter);
        expect(r.extractedPokemonName, 'Glumanda');
        expect(r.gender, 'male');
      });

      test('Ignores PokeVault UI dex counters like 0 von 1487 gefangen and pure numbers', () {
        expect(engine.parse('0 von 1487 gefangen'), isNull);
        expect(engine.parse('O von 1487 gefangen'), isNull);
        expect(engine.parse('1487 gefangen'), isNull);
        expect(engine.parse('12 / 1025 gefangen'), isNull);
        expect(engine.parse('Alola (US/UM Akala)\n0 von 1487 gefangen'), isNull);
        expect(engine.parse('ZIEL-POKÉDEX: 25 von 151 gefangen'), isNull);

        // Legitimate Pokemon containing digits must still match
        final porygon = engine.parse('Porygon2 wurde gefangen!');
        expect(porygon, isNotNull);
        expect(porygon!.extractedPokemonName, 'Porygon2');
      });

      test('Extracts caught Pokemon split across multiple lines (Gen 5 DS dialogue)', () {
        final splitCatch = engine.parse('Klasse!\nFlampion wurde gefangen!');
        expect(splitCatch, isNotNull);
        expect(splitCatch!.type, ScannerEventType.caught);
        expect(splitCatch.extractedPokemonName, 'Flampion');

        final splitAcrossTwoLines = engine.parse('Klasse! Flampion\nwurde gefangen!');
        expect(splitAcrossTwoLines, isNotNull);
        expect(splitAcrossTwoLines!.type, ScannerEventType.caught);
        expect(splitAcrossTwoLines.extractedPokemonName, 'Flampion');

        final noisyGen5 = engine.parse("Klase!\nF'lanpign wurde gefangen!");
        expect(noisyGen5, isNotNull);
        expect(noisyGen5!.type, ScannerEventType.caught);
      });

      test('Extracts garbled Pokemon Black catch phrase with melonDS menu chrome via smart context', () {
        const blackLog = '[110/601 melonDS 1.1\n'
            'File System View Config Help\n'
            'Klasse!\n'
            'Zr-rrokex wrde aefar«t!\n'
            '14 so\n'
            '150/204';
        final r = engine.parse(blackLog);
        expect(r, isNotNull);
        expect(r!.type, ScannerEventType.caught);
        expect(r.isSmartSearchFallback, isTrue);
        expect(r.extractedPokemonName, contains('Zr-rrokex'));

        // Pure emulator menu chrome + FPS/Dex counters must still return null
        expect(
          engine.parse('[87/60] melonDS 1.1\nFile System View Config Help\n150/204'),
          isNull,
        );
      });

      test('Rejects battle menu command prompts so player starter is never misclassified as caught', () {
        expect(engine.parse('Was soll Serpiroyal tun?'), isNull);
        expect(engine.parse('What will Serperior do?'), isNull);
        expect(engine.parse('Gib Serpiroyal einen Spitznamen?'), isNull);
        expect(
          engine.parse('[97/601 melonDS 1.1\nFile System View Config Help\nWas soll\nSerpiroyal tun?'),
          isNull,
        );
        // Real screenshot 1 garbled OCR glitches ("Was" -> "Klas", "tun?" -> "tl.rt?")
        expect(engine.parse('Klas soll Serpirogal tl.rt?'), isNull);
        expect(engine.parse('Klas soll Serpiroyal tl.rt?'), isNull);
        expect(engine.parse('Wlas soll Flampion tun?'), isNull);
      });

      test('Detects battle-menu and battle-end cues for single-screen state machine', () {
        expect(engine.detectBattleCue('Klas soll Serpirogal tl.rt?'), BattleCue.battleMenu);
        expect(engine.detectBattleCue('Was soll Serpiroyal tun?'), BattleCue.battleMenu);
        expect(engine.detectBattleCue('KAMPF  BEUTEL  FLUCHT  POKÉMON'), BattleCue.battleMenu);
        expect(engine.detectBattleCue('Du bist erfolgreich geflohen!'), BattleCue.battleEnded);
        expect(engine.detectBattleCue('Wildes Flampion wurde besiegt!'), BattleCue.battleEnded);
        expect(engine.detectBattleCue('Got away safely!'), BattleCue.battleEnded);
        expect(engine.detectBattleCue('Ein wildes Flampion erscheint!'), BattleCue.none);
      });

      test('Parses multi-encounter and horde battle phrases plus enemyHudFocusOnly mode', () {
        final multi = engine.parse('Ein wildes Pikachu und ein wildes Evoli erscheinen!');
        expect(multi, isNotNull);
        expect(multi!.type, ScannerEventType.encounter);
        expect(multi.isMultiEncounter, isTrue);
        expect(multi.extractedPokemonNames, containsAll(['Pikachu', 'Evoli']));

        final horde = engine.parse('Eine Gruppe wilder Zurrokex erscheint!');
        expect(horde, isNotNull);
        expect(horde!.type, ScannerEventType.encounter);
        expect(horde.isMultiEncounter, isTrue);

        // enemyHudFocusOnly forces encounter role even on raw HUD text
        final hudFocus = engine.parse(
          'Zurrokex Lv.16   Ganovil Lv.17',
          role: OcrScanRole.enemyHudFocusOnly,
        );
        expect(hudFocus, isNotNull);
        expect(hudFocus!.type, ScannerEventType.encounter);
        expect(hudFocus.isMultiEncounter, isTrue);
      });

      test('enemyHudFocusOnly preserves multi-line stacked HUD entries and Zone A supports all mainline multi-encounter phrases', () {
        final stackedHud = engine.parse(
          'Sleima ♀ Lv.17\nKP\nZubat ♂ Lv.15\nKP',
          role: OcrScanRole.enemyHudFocusOnly,
        );
        expect(stackedHud, isNotNull);
        expect(stackedHud!.isMultiEncounter, isTrue);
        expect(stackedHud.extractedPokemonNames, ['Sleima', 'Zubat']);

        final gen5Double = engine.parse(
          'Ein wildes Sleima und ein wildes Zubat greifen an!',
        );
        expect(gen5Double, isNotNull);
        expect(gen5Double!.isMultiEncounter, isTrue);
        expect(gen5Double.extractedPokemonNames, ['Sleima', 'Zubat']);

        final shortDeDouble = engine.parse(
          'Ein wildes Sleima und ein Zubat erscheinen!',
        );
        expect(shortDeDouble, isNotNull);
        expect(shortDeDouble!.isMultiEncounter, isTrue);
        expect(shortDeDouble.extractedPokemonNames, ['Sleima', 'Zubat']);

        final enShortDouble = engine.parse(
          'A wild Grimer and Zubat appeared!',
        );
        expect(enShortDouble, isNotNull);
        expect(enShortDouble!.isMultiEncounter, isTrue);
        expect(enShortDouble.extractedPokemonNames, ['Grimer', 'Zubat']);

        final garbledMulti = engine.parse(
          'Wildes Slleima und 2ubat grfien an!',
        );
        expect(garbledMulti, isNotNull);
        expect(garbledMulti!.type, ScannerEventType.encounter);
        expect(garbledMulti.isMultiEncounter, isTrue);
      });
    });

    group('Custom user OCR patterns', () {
      test('Matches enabled custom pattern with {pokemon} placeholder and * wildcard', () {
        engine.updateCustomPatterns(const [
          CustomOcrPattern(
            id: 'gen5_klasse',
            template: 'Klasse! {pokemon}',
            eventType: ScannerEventType.caught,
            enabled: true,
          ),
          CustomOcrPattern(
            id: 'wildcard_enc',
            template: 'Gefahr * greift {pokemon} an',
            eventType: ScannerEventType.encounter,
            enabled: true,
          ),
          CustomOcrPattern(
            id: 'disabled_pat',
            template: ' ignoriere {pokemon}',
            eventType: ScannerEventType.caught,
            enabled: false,
          ),
        ]);

        final r1 = engine.parse('Klasse! Flampion');
        expect(r1, isNotNull);
        expect(r1!.type, ScannerEventType.caught);
        expect(r1.extractedPokemonName, 'Flampion');

        final r2 = engine.parse('Gefahr im hohen Gras greift Milza an');
        expect(r2, isNotNull);
        expect(r2!.type, ScannerEventType.encounter);
        expect(r2.extractedPokemonName, 'Milza');

        expect(engine.parse('ignoriere Flampion'), isNull);
      });
    });
  });
}
