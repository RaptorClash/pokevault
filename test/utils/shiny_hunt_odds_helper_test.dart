import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/utils/shiny_hunt_odds_helper.dart';

void main() {
  group('ShinyHuntOddsHelper - Binomial & Basic Probabilities', () {
    test('rolls = 0 returns 0.0 probability and 1.0 complement', () {
      expect(ShinyHuntOddsHelper.calculateProbability(4096.0, 0), equals(0.0));
      expect(ShinyHuntOddsHelper.calculateComplementProbability(4096.0, 0), equals(1.0));
    });

    test('baseOdds <= 1.0 returns 1.0 probability', () {
      expect(ShinyHuntOddsHelper.calculateProbability(1.0, 1), equals(1.0));
      expect(ShinyHuntOddsHelper.calculateComplementProbability(1.0, 1), equals(0.0));
    });

    test('standard odds n = 4096 on baseOdds 4096 matches 1 - (1 - 1/4096)^4096 (~63.2%)', () {
      final p = ShinyHuntOddsHelper.calculateProbability(4096.0, 4096);
      final q = ShinyHuntOddsHelper.calculateComplementProbability(4096.0, 4096);
      expect(p + q, closeTo(1.0, 1e-9));
      // 1 - 1/e ≈ 0.63212
      expect(p, closeTo(0.63215, 0.001));
      expect(q, closeTo(0.36785, 0.001));
    });

    test('standard odds n = 512 on baseOdds 512 matches ~63.2%', () {
      final p = ShinyHuntOddsHelper.calculateProbability(512.0, 512);
      expect(p, closeTo(0.6323, 0.001));
    });

    test('standard odds n = 8192 on baseOdds 8192 matches ~63.2%', () {
      final p = ShinyHuntOddsHelper.calculateProbability(8192.0, 8192);
      expect(p, closeTo(0.63213, 0.001));
    });

    test('odds ratio calculation', () {
      expect(ShinyHuntOddsHelper.calculateOddsRatio(5120, 4096.0), equals(1.25));
      expect(ShinyHuntOddsHelper.calculateOddsRatio(2048, 4096.0), equals(0.5));
    });

    test('odds classification (Under Odds, At Odds, Over Odds)', () {
      expect(
        ShinyHuntOddsHelper.getClassification(4000, 4096.0),
        equals(OddsClassification.underOdds),
      );
      expect(
        ShinyHuntOddsHelper.getClassification(4096, 4096.0),
        equals(OddsClassification.atOdds),
      );
      expect(
        ShinyHuntOddsHelper.getClassification(8192, 4096.0),
        equals(OddsClassification.atOdds),
      );
      expect(
        ShinyHuntOddsHelper.getClassification(8193, 4096.0),
        equals(OddsClassification.overOdds),
      );
    });
  });

  group('ShinyHuntOddsHelper - Float Odds & Special Glitches', () {
    test('Odd Egg 14% (baseOdds = 7.142857) has 14% chance on roll 1', () {
      const oddEggOdds = 100.0 / 14.0;
      final p1 = ShinyHuntOddsHelper.calculateProbability(oddEggOdds, 1);
      expect(p1, closeTo(0.14, 0.0001));

      // After 5 eggs: 1 - (1 - 0.14)^5 = 1 - 0.86^5 ≈ 0.5295
      final p5 = ShinyHuntOddsHelper.calculateProbability(oddEggOdds, 5);
      expect(p5, closeTo(1.0 - pow(0.86, 5), 0.0001));
    });

    test('Cute Charm Glitch 21.34% (baseOdds = 4.6860356) has 21.34% chance on roll 1', () {
      const cuteCharmOdds = 100.0 / 21.34;
      final p1 = ShinyHuntOddsHelper.calculateProbability(cuteCharmOdds, 1);
      expect(p1, closeTo(0.2134, 0.0001));
    });

    test('Gen 2 Shiny Ditto 1:64 (baseOdds = 64.0) has 1/64 chance on roll 1', () {
      final p1 = ShinyHuntOddsHelper.calculateProbability(64.0, 1);
      expect(p1, closeTo(1.0 / 64.0, 0.0001));
    });
  });

  group('ShinyHuntOddsHelper - Multi-Spawns k', () {
    test('HGSS Starter Soft Reset (k=3, baseOdds=8192)', () {
      // 1 reset checks 3 starter balls
      // Probability on 1 encounter with k=3: 1 - (1 - 1/8192)^3 ≈ 3/8192 ≈ 0.000366
      const rolls = 1 * 3;
      final p = ShinyHuntOddsHelper.calculateProbability(8192.0, rolls);
      expect(p, closeTo(1.0 - pow(1.0 - 1.0 / 8192.0, 3), 1e-8));
    });

    test('Horde Battles (k=5, baseOdds=4096)', () {
      // 100 hordes = 500 encounters
      final p = ShinyHuntOddsHelper.calculateProbability(4096.0, 500);
      expect(p, closeTo(1.0 - pow(1.0 - 1.0 / 4096.0, 500), 1e-8));
    });
  });

  group('ShinyHuntOddsHelper - BDSP Charm Bug Logic', () {
    test('BDSP game detection', () {
      expect(ShinyHuntOddsHelper.isBDSP('BDSP'), isTrue);
      expect(ShinyHuntOddsHelper.isBDSP('Brilliant Diamond'), isTrue);
      expect(ShinyHuntOddsHelper.isBDSP('Strahlender Diamant'), isTrue);
      expect(ShinyHuntOddsHelper.isBDSP('Sword / Shield'), isFalse);
    });

    test('BDSP Shiny Charm is NOT applicable for Wild/Soft Reset encounters', () {
      expect(
        ShinyHuntOddsHelper.isShinyCharmApplicable('BDSP', 'Wild / Soft Reset', 4.0),
        isFalse,
      );
      expect(
        ShinyHuntOddsHelper.isShinyCharmApplicable('BDSP', 'Untergrund', 4.0),
        isFalse,
      );
    });

    test('BDSP Shiny Charm IS applicable for Masuda / Breeding', () {
      expect(
        ShinyHuntOddsHelper.isShinyCharmApplicable('BDSP', 'Masuda-Methode (Zucht)', 4.0),
        isTrue,
      );
      expect(
        ShinyHuntOddsHelper.isShinyCharmApplicable('BDSP', 'Breeding', 4.0),
        isTrue,
      );
    });

    test('BDSP warning note is generated when Charm is active on non-Masuda', () {
      final note = ShinyHuntOddsHelper.getSpecialNote(
        game: 'Strahlender Diamant',
        method: 'Wild',
        generation: 4.0,
        hasShinyCharm: true,
      );
      expect(note, isNotNull);
      expect(note, contains('Spielfehler'));

      final noteMasuda = ShinyHuntOddsHelper.getSpecialNote(
        game: 'Strahlender Diamant',
        method: 'Masuda',
        generation: 4.0,
        hasShinyCharm: true,
      );
      expect(noteMasuda, isNull);
    });

    test('Pre-Gen 5 never applies Shiny Charm', () {
      expect(
        ShinyHuntOddsHelper.isShinyCharmApplicable('HeartGold', 'Masuda', 4.0),
        isFalse,
      );
    });
  });

  group('ShinyHuntOddsHelper - Dynamic Chain Probabilities', () {
    test('Radar chain odds scale up to 1/200 at step 40', () {
      final step1 = ShinyHuntOddsHelper.getStepOddsForChainMethod(
        method: 'Poké-Radar',
        step: 1,
        hasShinyCharm: false,
        generation: 4.0,
      );
      final step40 = ShinyHuntOddsHelper.getStepOddsForChainMethod(
        method: 'Poké-Radar',
        step: 40,
        hasShinyCharm: false,
        generation: 4.0,
      );
      expect(step1, greaterThan(step40));
      expect(step40, equals(200.0));
    });

    test('Chain fishing increases odds per streak up to 20', () {
      final step1 = ShinyHuntOddsHelper.getStepOddsForChainMethod(
        method: 'Chain Fishing',
        step: 1,
        hasShinyCharm: false,
      );
      final step20 = ShinyHuntOddsHelper.getStepOddsForChainMethod(
        method: 'Chain Fishing',
        step: 20,
        hasShinyCharm: false,
      );
      expect(step1, equals(4096.0 / 3.0));
      expect(step20, equals(4096.0 / 41.0)); // ~99.9
    });

    test('calculateDynamicChainProbability accumulates compounding chances monotonically', () {
      final prob10 = ShinyHuntOddsHelper.calculateDynamicChainProbability(
        method: 'Chain Fishing',
        currentChain: 10,
        spawnsPerEncounter: 1,
        hasShinyCharm: false,
      );
      final prob20 = ShinyHuntOddsHelper.calculateDynamicChainProbability(
        method: 'Chain Fishing',
        currentChain: 20,
        spawnsPerEncounter: 1,
        hasShinyCharm: false,
      );
      expect(prob20, greaterThan(prob10));
      expect(prob10, greaterThan(0.0));
    });
  });

  group('ShinyHuntOddsHelper - Dex Game & Gen Detection (Smart Defaults)', () {
    test('Regionaldex detections map correctly', () {
      final paldea = ShinyHuntOddsHelper.detectGameAndGenForDex('paldea_regional');
      expect(paldea.game, equals('Karmesin / Purpur'));
      expect(paldea.generation, equals(9.0));

      final hgss = ShinyHuntOddsHelper.detectGameAndGenForDex('updated_johto_regional');
      expect(hgss.game, equals('HeartGold / SoulSilver'));
      expect(hgss.generation, equals(4.0));

      final hisui = ShinyHuntOddsHelper.detectGameAndGenForDex('hisui_regional');
      expect(hisui.game, equals('Legenden: Arceus'));
      expect(hisui.generation, equals(8.5));

      final za = ShinyHuntOddsHelper.detectGameAndGenForDex('lumiose_regional');
      expect(za.game, equals('Legenden: Z-A'));
      expect(za.generation, equals(9.5));
    });
  });

  group('ShinyHuntOddsHelper - isChainMethod & calculateEffectiveProbability', () {
    test('isChainMethod correctly identifies chain methods', () {
      expect(ShinyHuntOddsHelper.isChainMethod('Poké-Radar'), isTrue);
      expect(ShinyHuntOddsHelper.isChainMethod('Chain Fishing'), isTrue);
      expect(ShinyHuntOddsHelper.isChainMethod('Catch Combo'), isTrue);
      expect(ShinyHuntOddsHelper.isChainMethod('S.O.S. Calling'), isTrue);
      expect(ShinyHuntOddsHelper.isChainMethod('Standard Wild'), isFalse);
      expect(ShinyHuntOddsHelper.isChainMethod('Soft Reset'), isFalse);
      expect(ShinyHuntOddsHelper.isChainMethod('Masuda-Methode'), isFalse);
    });

    test('calculateEffectiveProbability uses dynamic chain compounding for unprepared chain hunts', () {
      final now = DateTime.now();
      final chainHunt = ShinyHunt(
        id: 'chain-1',
        title: 'Chain Fishing Feebas',
        pokemonId: 349,
        pokemonName: 'Barschwa',
        game: 'Omega Rubin / Alpha Saphir',
        generation: 6.0,
        method: 'Chain Fishing',
        baseOdds: 4096.0, // > 1500.0 triggers dynamic chain calculation
        currentEncounters: 20,
        createdAt: now,
        updatedAt: now,
      );

      final effProb = ShinyHuntOddsHelper.calculateEffectiveProbability(chainHunt);
      final dynamicProb = ShinyHuntOddsHelper.calculateDynamicChainProbability(
        method: 'Chain Fishing',
        currentChain: 20,
        spawnsPerEncounter: 1,
        hasShinyCharm: false,
      );

      expect(effProb, equals(dynamicProb));
      expect(effProb, greaterThan(0.0));

      final complement = ShinyHuntOddsHelper.calculateEffectiveComplementProbability(chainHunt);
      expect(complement, closeTo(1.0 - effProb, 1e-9));
    });

    test('calculateEffectiveProbability uses baseOdds when chain is prepared', () {
      final now = DateTime.now();
      final preparedChainHunt = ShinyHunt(
        id: 'chain-prep-1',
        title: 'Radar Hunt Prepared',
        pokemonId: 25,
        pokemonName: 'Pikachu',
        game: 'Diamant / Perl',
        generation: 4.0,
        method: 'Poké-Radar',
        baseOdds: 200.0, // <= 1500.0 uses static binomial at max chain odds
        currentEncounters: 100,
        createdAt: now,
        updatedAt: now,
      );

      final effProb = ShinyHuntOddsHelper.calculateEffectiveProbability(preparedChainHunt);
      final expectedBinomial = ShinyHuntOddsHelper.calculateProbability(200.0, 100);

      expect(effProb, equals(expectedBinomial));
    });

    test('calculateEffectiveProbability uses standard binomial for non-chain hunts', () {
      final now = DateTime.now();
      final wildHunt = ShinyHunt(
        id: 'wild-1',
        title: 'Wild Mewtwo',
        pokemonId: 150,
        pokemonName: 'Mewtu',
        game: 'Feuerrot',
        generation: 3.0,
        method: 'Soft Reset',
        baseOdds: 8192.0,
        currentEncounters: 8192,
        createdAt: now,
        updatedAt: now,
      );

      final effProb = ShinyHuntOddsHelper.calculateEffectiveProbability(wildHunt);
      expect(effProb, closeTo(0.632, 0.001));
    });
  });
}
