import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/utils/catch_rate/models.dart';
import 'package:pokevault/utils/catch_rate/strategy_base.dart';

void main() {
  group('Catch Rate Calculator - Ausführliche Tests', () {
    final bulbasaur = Pokemon(
      id: 1,
      nameDe: 'Bisasam',
      nameEn: 'Bulbasaur',
      hasGenderDifferences: false,
      genderRate: 1,
      captureRate: 45,
      evolutionChainId: 1,
      eggGroups: ['Monster', 'Grass'],
      weight: 6.9,
      speed: 45,
      forms: [],
    );

    final snorlax = Pokemon(
      id: 143,
      nameDe: 'Relaxo',
      nameEn: 'Snorlax',
      hasGenderDifferences: false,
      genderRate: 1,
      captureRate: 25,
      evolutionChainId: 1,
      eggGroups: ['Monster'],
      weight: 460.0,
      speed: 30,
      forms: [],
    );

    CatchRateParams buildParams(
      Pokemon poke, {
      required String ballId,
      int turnCount = 1,
      int statusType = 0,
      double hpPercent = 100.0,
      bool isNightOrCave = false,
      bool isSurfingOrDiving = false,
      int ownLevel = 50,
      int enemyLevel = 50,
    }) {
      return CatchRateParams(
        pokemon: poke,
        ballId: ballId,
        hpPercent: hpPercent,
        statusType: statusType,
        turnCount: turnCount,
        enemyLevel: enemyLevel,
        ownLevel: ownLevel,
        isFishing: false,
        isSurfingOrDiving: isSurfingOrDiving,
        isNightOrCave: isNightOrCave,
        isLoveConditionMet: false,
        isAlreadyCaught: false,
        isDarkGrass: false,
        hisuiCatchStatus: 0,
        isFlying: false,
        powerBonus: 1.0,
        dexMultiplier: 1.0,
        hasCatchingCharm: false,
      );
    }

    group('Gen 1 Mechaniken', () {
      final strategy = CatchRateStrategyFactory.getStrategy(1.0);

      test('Meisterball fängt immer', () {
        final result = strategy.calculate(
          buildParams(bulbasaur, ballId: 'master'),
        );
        expect(result.catchChance, equals(100.0));
      });

      test('Statusprobleme erhöhen die Fangchance', () {
        final healthy = strategy.calculate(
          buildParams(bulbasaur, ballId: 'poke', statusType: 0),
        );
        final asleep = strategy.calculate(
          buildParams(bulbasaur, ballId: 'poke', statusType: 2),
        );
        expect(asleep.catchChance > healthy.catchChance, isTrue);
      });
    });

    group('Gen 2 Mechaniken (Schwerball & Levelball)', () {
      final strategy = CatchRateStrategyFactory.getStrategy(2.0);

      test(
        'Schwerball gibt Malus bei leichten und Bonus bei schweren Pokémon',
        () {
          final resultLight = strategy.calculate(
            buildParams(bulbasaur, ballId: 'heavy'),
          );
          final resultHeavy = strategy.calculate(
            buildParams(snorlax, ballId: 'heavy'),
          );

          expect(resultLight.baseRate, equals(25));
          expect(resultHeavy.baseRate, equals(65));
        },
      );

      test('Levelball skaliert mit dem Level-Unterschied', () {
        final equalLvl = strategy.calculate(
          buildParams(bulbasaur, ballId: 'level', ownLevel: 50, enemyLevel: 50),
        );
        expect(equalLvl.bonus, equals(1.0));

        final higherLvl = strategy.calculate(
          buildParams(bulbasaur, ballId: 'level', ownLevel: 50, enemyLevel: 30),
        );
        expect(higherLvl.bonus, equals(2.0));

        final doubleLvl = strategy.calculate(
          buildParams(bulbasaur, ballId: 'level', ownLevel: 50, enemyLevel: 20),
        );
        expect(doubleLvl.bonus, equals(4.0));

        final quadLvl = strategy.calculate(
          buildParams(
            bulbasaur,
            ballId: 'level',
            ownLevel: 100,
            enemyLevel: 20,
          ),
        );
        expect(quadLvl.bonus, equals(8.0));
      });
    });

    group('Moderne Mechaniken (Gen 5 bis 9)', () {
      final strategyGen5 = CatchRateStrategyFactory.getStrategy(5.0);
      final strategyGen9 = CatchRateStrategyFactory.getStrategy(9.0);

      test('Flottball Bonus verfällt nach Runde 1', () {
        expect(
          strategyGen9
              .calculate(buildParams(bulbasaur, ballId: 'quick', turnCount: 1))
              .bonus,
          equals(5.0),
        );
        expect(
          strategyGen9
              .calculate(buildParams(bulbasaur, ballId: 'quick', turnCount: 2))
              .bonus,
          equals(1.0),
        );
      });

      test('Timerball skaliert bis zum Cap', () {
        final t1 = strategyGen5
            .calculate(buildParams(bulbasaur, ballId: 'timer', turnCount: 1))
            .bonus;
        final t10 = strategyGen5
            .calculate(buildParams(bulbasaur, ballId: 'timer', turnCount: 10))
            .bonus;
        final t30 = strategyGen5
            .calculate(buildParams(bulbasaur, ballId: 'timer', turnCount: 30))
            .bonus;

        expect(t10 > t1, isTrue);
        expect(t30, equals(4.0));
      });

      test('Wenig KP resultiert in höherer Fangchance', () {
        final fullHp = strategyGen9.calculate(
          buildParams(bulbasaur, ballId: 'poke', hpPercent: 100.0),
        );
        final lowHp = strategyGen9.calculate(
          buildParams(bulbasaur, ballId: 'poke', hpPercent: 1.0),
        );

        expect(lowHp.catchChance > fullHp.catchChance, isTrue);
      });
    });

    group('Spezial-Editionen (Arceus & Z-A)', () {
      final strategyArceus = CatchRateStrategyFactory.getStrategy(8.5);

      test('Originball hat 100%', () {
        final result = strategyArceus.calculate(
          buildParams(bulbasaur, ballId: 'origin'),
        );
        expect(result.catchChance, equals(100.0));
      });

      test('Federball bekommt Bonus bei fliegenden Zielen', () {
        final paramsFlying = CatchRateParams(
          pokemon: bulbasaur,
          ballId: 'feather',
          hpPercent: 100,
          statusType: 0,
          turnCount: 1,
          enemyLevel: 50,
          ownLevel: 50,
          isFishing: false,
          isSurfingOrDiving: false,
          isNightOrCave: false,
          isLoveConditionMet: false,
          isAlreadyCaught: false,
          isDarkGrass: false,
          hisuiCatchStatus: 0,
          powerBonus: 1.0,
          dexMultiplier: 1.0,
          hasCatchingCharm: false,
          isFlying: true,
        );
        final result = strategyArceus.calculate(paramsFlying);
        expect(result.bonus, equals(1.25));
      });
    });
  });
}
