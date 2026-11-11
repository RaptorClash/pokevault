import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';

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
    });
  });
}
