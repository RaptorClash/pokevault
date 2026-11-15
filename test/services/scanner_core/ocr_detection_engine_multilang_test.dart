import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';

void main() {
  group('OcrDetectionEngine Multi-Language Expansion Tests (TDD)', () {
    late OcrDetectionEngine engine;

    setUp(() {
      engine = OcrDetectionEngine();
    });

    group('Korean (ko) dialogue patterns', () {
      test('parses Korean caught, encounter, and evolution lines', () {
        final caught = engine.parse('신난다! 파이리을(를) 잡았다!');
        expect(caught, isNotNull);
        expect(caught!.type, ScannerEventType.caught);
        expect(caught.extractedPokemonName, '파이리');
        expect(caught.detectedLanguage, 'ko');

        final caughtDirect = engine.parse('피카츄를 잡았다!');
        expect(caughtDirect, isNotNull);
        expect(caughtDirect!.type, ScannerEventType.caught);
        expect(caughtDirect.extractedPokemonName, '피카츄');

        final encounter = engine.parse('야생의 꼬부기가 나타났다!');
        expect(encounter, isNotNull);
        expect(encounter!.type, ScannerEventType.encounter);
        expect(encounter.extractedPokemonName, '꼬부기');
        expect(encounter.detectedLanguage, 'ko');

        final evolved = engine.parse('이상해씨는 이상해풀(으)로 진화했다!');
        expect(evolved, isNotNull);
        expect(evolved!.type, ScannerEventType.evolved);
        expect(evolved.extractedPreEvolutionName, '이상해씨');
        expect(evolved.extractedPokemonName, '이상해풀');
        expect(evolved.detectedLanguage, 'ko');
      });
    });

    group('Simplified Chinese (zh-Hans) dialogue patterns', () {
      test('parses Simplified Chinese caught, encounter, and evolution lines', () {
        final caught = engine.parse('太好了！收服了小火龙！');
        expect(caught, isNotNull);
        expect(caught!.type, ScannerEventType.caught);
        expect(caught.extractedPokemonName, '小火龙');
        expect(caught.detectedLanguage, 'zh-Hans');

        final caughtAlt = engine.parse('皮卡丘被收服了！');
        expect(caughtAlt, isNotNull);
        expect(caughtAlt!.type, ScannerEventType.caught);
        expect(caughtAlt.extractedPokemonName, '皮卡丘');

        final encounter = engine.parse('野生的小火龙出现了！');
        expect(encounter, isNotNull);
        expect(encounter!.type, ScannerEventType.encounter);
        expect(encounter.extractedPokemonName, '小火龙');
        expect(encounter.detectedLanguage, 'zh-Hans');

        final evolved = engine.parse('妙蛙种子进化成了妙蛙草！');
        expect(evolved, isNotNull);
        expect(evolved!.type, ScannerEventType.evolved);
        expect(evolved.extractedPreEvolutionName, '妙蛙种子');
        expect(evolved.extractedPokemonName, '妙蛙草');
        expect(evolved.detectedLanguage, 'zh-Hans');
      });
    });

    group('Traditional Chinese (zh-Hant) dialogue patterns', () {
      test('parses Traditional Chinese caught, encounter, and evolution lines', () {
        final caught = engine.parse('太好了！收服了小火龍！');
        expect(caught, isNotNull);
        expect(caught!.type, ScannerEventType.caught);
        expect(caught.extractedPokemonName, '小火龍');
        expect(caught.detectedLanguage, anyOf('zh-Hans', 'zh-Hant'));

        final encounter = engine.parse('野生的傑尼龜出現了！');
        expect(encounter, isNotNull);
        expect(encounter!.type, ScannerEventType.encounter);
        expect(encounter.extractedPokemonName, '傑尼龜');
        expect(encounter.detectedLanguage, 'zh-Hant');

        final evolved = engine.parse('妙蛙種子進化成了妙蛙草！');
        expect(evolved, isNotNull);
        expect(evolved!.type, ScannerEventType.evolved);
        expect(evolved.extractedPreEvolutionName, '妙蛙種子');
        expect(evolved.extractedPokemonName, '妙蛙草');
        expect(evolved.detectedLanguage, 'zh-Hant');
      });
    });

    group('Additional FR / ES / IT / JA phrases & metadata', () {
      test('parses French, Spanish, Italian, Japanese variants and shiny/alpha keywords', () {
        final frEnc = engine.parse('Un Pikachu chromatique sauvage apparaît !');
        expect(frEnc, isNotNull);
        expect(frEnc!.type, ScannerEventType.encounter);
        expect(frEnc.isShiny, isTrue);
        expect(frEnc.extractedPokemonName, 'Pikachu');

        final frCaught = engine.parse('Et hop ! Évoli a été attrapé !');
        expect(frCaught, isNotNull);
        expect(frCaught!.type, ScannerEventType.caught);
        expect(frCaught.extractedPokemonName, 'Évoli');

        final esCaught = engine.parse('¡Ya está! ¡Has atrapado a Bulbasaur!');
        expect(esCaught, isNotNull);
        expect(esCaught!.type, ScannerEventType.caught);
        expect(esCaught.extractedPokemonName, 'Bulbasaur');

        final esEvo = engine.parse('¡Charmander ha evolucionado a Charmeleon!');
        expect(esEvo, isNotNull);
        expect(esEvo!.type, ScannerEventType.evolved);
        expect(esEvo.extractedPreEvolutionName, 'Charmander');
        expect(esEvo.extractedPokemonName, 'Charmeleon');

        final itEnc = engine.parse('È apparso un Eevee selvatico!');
        expect(itEnc, isNotNull);
        expect(itEnc!.type, ScannerEventType.encounter);
        expect(itEnc.extractedPokemonName, 'Eevee');

        final itCaught = engine.parse('Preso! Pikachu è stato catturato!');
        expect(itCaught, isNotNull);
        expect(itCaught!.type, ScannerEventType.caught);
        expect(itCaught.extractedPokemonName, 'Pikachu');

        final jaAlpha = engine.parse('オヤブン ガブリアスを つかまえた！');
        expect(jaAlpha, isNotNull);
        expect(jaAlpha!.type, ScannerEventType.caught);
        expect(jaAlpha.isAlpha, isTrue);
        expect(jaAlpha.extractedPokemonName, 'ガブリアス');
      });

      test('detects multilingual battle-end cues', () {
        expect(engine.detectBattleCue("Vous prenez la fuite !"), BattleCue.battleEnded);
        expect(engine.detectBattleCue('¡Escapaste sin problemas!'), BattleCue.battleEnded);
        expect(engine.detectBattleCue('Scappato senza problemi!'), BattleCue.battleEnded);
        expect(engine.detectBattleCue('うまく にげきれた！'), BattleCue.battleEnded);
        expect(engine.detectBattleCue('무사히 도망쳤다!'), BattleCue.battleEnded);
        expect(engine.detectBattleCue('顺利逃走了！'), BattleCue.battleEnded);
      });

      test('PokemonFuzzyMatcher matches CJK & Korean entries cleanly and ignores noise tokens', () {
        final matcher = PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 4, name: '小火龙', language: 'zh-Hans'),
          PokemonMatcherEntry(id: 4, name: '小火龍', language: 'zh-Hant'),
          PokemonMatcherEntry(id: 4, name: '파이리', language: 'ko'),
          PokemonMatcherEntry(id: 4, name: 'ヒトカゲ', language: 'ja'),
          PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'en'),
        ]);

        expect(matcher.match('小火龙')?.pokemonId, 4);
        expect(matcher.match('파이리')?.pokemonId, 4);
        expect(matcher.match('ヒトカゲ')?.pokemonId, 4);
        expect(matcher.match('sauvage'), isNull);
        expect(matcher.match('salvaje'), isNull);
        expect(matcher.match('selvatico'), isNull);
      });
    });
  });
}
