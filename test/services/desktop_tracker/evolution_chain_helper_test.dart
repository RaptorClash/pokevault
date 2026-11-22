import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/services/desktop_tracker/evolution_chain_helper.dart';

Pokemon _dummyPokemon(int id, String deName, String enName, {int chainId = 100}) {
  return Pokemon(
    id: id,
    nameDe: deName,
    nameEn: enName,
    hasGenderDifferences: false,
    genderRate: 4,
    captureRate: 120,
    evolutionChainId: chainId,
    eggGroups: const [],
    weight: 10.0,
    speed: 60,
    forms: const [],
  );
}

void main() {
  group('EvolutionChainHelper (TDD)', () {
    final darmanitanChain = <String, dynamic>{
      'species_id': 554, // Flampion
      'evolves_to': [
        {
          'species_id': 555, // Flampivian
          'evolves_to': const [],
        },
      ],
    };

    final serperiorChain = <String, dynamic>{
      'species_id': 495, // Serpifeu
      'evolves_to': [
        {
          'species_id': 496, // Efoserp
          'evolves_to': [
            {
              'species_id': 497, // Serpiroyal
              'evolves_to': const [],
            },
          ],
        },
      ],
    };

    final eeveeChain = <String, dynamic>{
      'species_id': 133, // Evoli
      'evolves_to': [
        {'species_id': 134, 'evolves_to': const []}, // Aquana
        {'species_id': 135, 'evolves_to': const []}, // Blitza
        {'species_id': 136, 'evolves_to': const []}, // Flamara
      ],
    };

    final pokemonMap = <int, Pokemon>{
      554: _dummyPokemon(554, 'Flampion', 'Darumaka', chainId: 282),
      555: _dummyPokemon(555, 'Flampivian', 'Darmanitan', chainId: 282),
      495: _dummyPokemon(495, 'Serpifeu', 'Snivy', chainId: 254),
      496: _dummyPokemon(496, 'Efoserp', 'Servine', chainId: 254),
      497: _dummyPokemon(497, 'Serpiroyal', 'Serperior', chainId: 254),
      133: _dummyPokemon(133, 'Evoli', 'Eevee', chainId: 67),
      134: _dummyPokemon(134, 'Aquana', 'Vaporeon', chainId: 67),
      135: _dummyPokemon(135, 'Blitza', 'Jolteon', chainId: 67),
      136: _dummyPokemon(136, 'Flamara', 'Flareon', chainId: 67),
    };

    UserDex makeDex({List<String> caughtIds = const [], bool isShinyDex = false, List<String> shinyIds = const []}) {
      return UserDex(
        id: 'dex_1',
        title: 'Nationaldex',
        region: 'national',
        isShinyDex: isShinyDex,
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: caughtIds,
        shinyIds: shinyIds,
      );
    }

    test('Reports missing direct evolution (Flampion -> Flampivian)', () {
      final dexMissing = makeDex(caughtIds: const ['554']);
      final status = EvolutionChainHelper.evaluate(
        pokemonId: 554,
        chainData: darmanitanChain,
        activeDex: dexMissing,
        pokemonById: pokemonMap,
        languageCode: 'de',
      );

      expect(status.totalFutureCount, 1);
      expect(status.missingIds, [555]);
      expect(status.missingNames, ['Flampivian']);
      expect(status.hasMissingEvolutions, isTrue);
      expect(status.summaryLabel, contains('Flampivian'));
      expect(status.summaryLabel, contains('fehlt'));
    });

    test('Reports all later evolutions caught when descendant is already in dex', () {
      final dexComplete = makeDex(caughtIds: const ['554', '555']);
      final status = EvolutionChainHelper.evaluate(
        pokemonId: 554,
        chainData: darmanitanChain,
        activeDex: dexComplete,
        pokemonById: pokemonMap,
        languageCode: 'de',
      );

      expect(status.totalFutureCount, 1);
      expect(status.missingIds, isEmpty);
      expect(status.hasMissingEvolutions, isFalse);
      expect(status.summaryLabel, contains('Alle Entw.'));
    });

    test('Ignores pre-evolutions when focused on middle or final stage', () {
      // Focused on Efoserp (496): pre-evolution 495 missing should NOT trigger missing future evo if 497 is caught!
      final dexFinalCaught = makeDex(caughtIds: const ['497']);
      final middleStatus = EvolutionChainHelper.evaluate(
        pokemonId: 496,
        chainData: serperiorChain,
        activeDex: dexFinalCaught,
        pokemonById: pokemonMap,
        languageCode: 'de',
      );
      expect(middleStatus.totalFutureCount, 1);
      expect(middleStatus.missingIds, isEmpty);
      expect(middleStatus.hasMissingEvolutions, isFalse);

      // Focused on Serpiroyal (497): leaf stage has 0 later evolutions
      final finalStatus = EvolutionChainHelper.evaluate(
        pokemonId: 497,
        chainData: serperiorChain,
        activeDex: makeDex(),
        pokemonById: pokemonMap,
        languageCode: 'de',
      );
      expect(finalStatus.totalFutureCount, 0);
      expect(finalStatus.hasMissingEvolutions, isFalse);
    });

    test('Handles branching evolutions (Evoli) concisely in English and German', () {
      final dexPartial = makeDex(caughtIds: const ['134']);
      final statusDe = EvolutionChainHelper.evaluate(
        pokemonId: 133,
        chainData: eeveeChain,
        activeDex: dexPartial,
        pokemonById: pokemonMap,
        languageCode: 'de',
      );
      expect(statusDe.totalFutureCount, 3);
      expect(statusDe.missingIds, [135, 136]);
      expect(statusDe.missingNames, ['Blitza', 'Flamara']);
      expect(statusDe.hasMissingEvolutions, isTrue);

      final statusEn = EvolutionChainHelper.evaluate(
        pokemonId: 133,
        chainData: eeveeChain,
        activeDex: dexPartial,
        pokemonById: pokemonMap,
        languageCode: 'en',
      );
      expect(statusEn.missingNames, ['Jolteon', 'Flareon']);
    });
  });
}
