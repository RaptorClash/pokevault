import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';

void main() {
  group('OcrDetectionEngine Egg Hatch & Soft Reset extensions', () {
    late OcrDetectionEngine engine;

    setUp(() {
      engine = OcrDetectionEngine();
    });

    test('parses egg hatch messages across all 9 franchise languages', () {
      const cases = [
        ('Glumanda ist aus dem Ei geschlüpft!', 'Glumanda', 'de'),
        ('Charmander hatched from the Egg!', 'Charmander', 'en'),
        ('Salamèche vient d\'éclore !', 'Salamèche', 'fr'),
        ('¡Charmander salió del Huevo!', 'Charmander', 'es'),
        ('Charmander è nato dall\'Uovo!', 'Charmander', 'it'),
        ('ヒトカゲが タマゴから かえった！', 'ヒトカゲ', 'ja'),
        ('파이리가 알에서 태어났다!', '파이리', 'ko'),
        ('小火龙从蛋里孵出来了！', '小火龙', 'zh-Hans'),
        ('小火龍從蛋裡孵出來了！', '小火龍', 'zh-Hant'),
      ];

      for (final (text, expectedName, expectedLang) in cases) {
        final res = engine.parse(text);
        expect(res, isNotNull, reason: 'Failed for: $text');
        expect(res!.type, equals(ScannerEventType.eggHatched), reason: 'Type mismatch for: $text');
        expect(res.extractedPokemonName, equals(expectedName), reason: 'Name mismatch for: $text');
        expect(res.detectedLanguage, equals(expectedLang), reason: 'Lang mismatch for: $text');
      }
    });

    test('detects Oh? egg hatch prompt cue without filtering it out, including multiline frames', () {
      expect(engine.detectEggHatchCue('Oh?'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('Oh?\nBox 1'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('Nanu?!\nTeam'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('Nanu?!'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('Huh?'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('Glumanda ist aus dem Ei geschlüpft!'), equals(EggHatchCue.hatched));
      expect(engine.detectEggHatchCue('Wildes Pikachu erscheint!'), equals(EggHatchCue.none));
    });

    test('detects soft reset / title menu cues in multiple languages without false-matching normal dialogue', () {
      expect(engine.detectResetCue('Weiter\nNeues Spiel'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('  Weiter  \nNeues Spiel'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('Weiter'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('Continue'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('CONTINUE\nNEW GAME'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('PRESS START'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('つづきから\nさいしょから'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('이어하기'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('继续游戏'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('繼續遊戲'), equals(ResetCue.titleOrContinue));
      expect(engine.detectResetCue('Wildes Mewtu erscheint!'), equals(ResetCue.none));
      // Normal dialogue sentences containing "weiter" or "continue" must NOT trigger reset!
      expect(engine.detectResetCue('Der Kampf geht weiter!'), equals(ResetCue.none));
      expect(engine.detectResetCue("Let's continue the journey!"), equals(ResetCue.none));
    });

    test('supports custom reset/trigger templates without {pokemon} placeholder', () {
      engine.updateCustomPatterns(const [
        CustomOcrPattern(
          id: 'reset_1',
          template: 'Drücke Start',
          eventType: ScannerEventType.customReset,
        ),
        CustomOcrPattern(
          id: 'trig_1',
          template: '{pokemon} erscheint jetzt',
          eventType: ScannerEventType.encounter,
        ),
      ]);

      final resetRes = engine.parse('Bitte Drücke Start um fortzufahren');
      expect(resetRes, isNotNull);
      expect(resetRes!.type, equals(ScannerEventType.customReset));

      final trigRes = engine.parse('Mewtu erscheint jetzt!');
      expect(trigRes, isNotNull);
      expect(trigRes!.type, equals(ScannerEventType.encounter));
      expect(trigRes.extractedPokemonName, equals('Mewtu'));
    });

    test('parses German/English/French egg hatch variants with indefinite articles without corrupting names like Enton or Aron', () {
      const variants = [
        ('Aus dem Ei ist ein Glumanda geschlüpft!', 'Glumanda', 'de'),
        ('Aus dem Ei ist eine Evoli geschlüpft!', 'Evoli', 'de'),
        ('Ein Glumanda ist aus dem Ei geschlüpft!', 'Glumanda', 'de'),
        ('A Charmander hatched from the Egg!', 'Charmander', 'en'),
        ("Un Salamèche vient d'éclore !", 'Salamèche', 'fr'),
        ('Enton ist aus dem Ei geschlüpft!', 'Enton', 'de'),
        ('Aron hatched from the Egg!', 'Aron', 'en'),
      ];

      for (final (text, expectedName, expectedLang) in variants) {
        final res = engine.parse(text);
        expect(res, isNotNull, reason: 'Failed for: $text');
        expect(res!.type, equals(ScannerEventType.eggHatched), reason: 'Type mismatch for: $text');
        expect(res.extractedPokemonName, equals(expectedName), reason: 'Name mismatch for: $text');
        expect(res.detectedLanguage, equals(expectedLang), reason: 'Lang mismatch for: $text');
        expect(engine.detectEggHatchCue(text), equals(EggHatchCue.hatched));
      }
    });

    test('does not mark encounter shiny when emulator chrome contains Shiny', () {
      final res = engine.parse(
        'melonDS - Pokemon Platinum Shiny Hunt\nEin wildes Pikachu erscheint!',
      );
      expect(res, isNotNull);
      expect(res!.type, equals(ScannerEventType.encounter));
      expect(res.extractedPokemonName, equals('Pikachu'));
      expect(res.isShiny, isFalse);
    });

    test('matches German Nanu? without ! and ASCII ? in JP/KR/ZH egg prompt cues', () {
      expect(engine.detectEggHatchCue('Nanu?'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('おや?'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('어라?'), equals(EggHatchCue.ohPrompt));
      expect(engine.detectEggHatchCue('咦?'), equals(EggHatchCue.ohPrompt));
    });

    test('ScannerCoordinator emits frame-2 shiny upgrade and bypasses ignoredPokemonIds for customReset', () async {
      var clock = Duration.zero;
      final coord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
          PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
        ]),
        settings: const ScannerSettings(
          ignoredPokemonIds: [4],
          customPatterns: [
            CustomOcrPattern(
              id: 'reset_glumanda',
              template: 'Glumanda Reset',
              eventType: ScannerEventType.customReset,
            ),
          ],
        ),
        elapsedClock: () => clock,
      );
      addTearDown(coord.dispose);

      // Frame 1: normal Pikachu -> recorded in _activeBattlesBySlot
      final first = await coord.processFrameText('Ein wildes Pikachu erscheint!');
      expect(first, hasLength(1));
      expect(first.first.isShiny, isFalse);

      // Frame 2: same species upgrades to isShiny == true -> must NOT be swallowed
      clock += const Duration(milliseconds: 300);
      final upgraded = await coord.processFrameText('Wildes ✨ Pikachu erscheint!');
      expect(upgraded, hasLength(1));
      expect(upgraded.first.isShiny, isTrue);

      // Multi-encounter path also allows shiny upgrade on frame 2
      clock += const Duration(seconds: 2);
      final multiFirst = await coord.processFrameText(
        'Pikachu Lv.5',
        encounterOnly: true,
        allowMultiEncounter: true,
        instanceIndex: 2,
      );
      expect(multiFirst, hasLength(1));
      expect(multiFirst.first.isShiny, isFalse);

      clock += const Duration(milliseconds: 300);
      final multiUpgrade = await coord.processFrameText(
        '✨ Pikachu Lv.5',
        encounterOnly: true,
        allowMultiEncounter: true,
        instanceIndex: 2,
      );
      expect(multiUpgrade, hasLength(1));
      expect(multiUpgrade.first.isShiny, isTrue);

      // Literal customReset whose text matches an ignored starter must NOT be blocked
      final resetEvents = await coord.processFrameText('Glumanda Reset');
      expect(resetEvents, hasLength(1));
      expect(resetEvents.first.type, equals(ScannerEventType.customReset));
    });
  });
}
