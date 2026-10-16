import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/utils/breeding_logic_helper.dart';

Pokemon _createPoke({
  required int id,
  required String name,
  required List<String> eggGroups,
  int genderRate = 4, // 50% female by default (1/8ths)
}) {
  return Pokemon(
    id: id,
    nameDe: name,
    nameEn: name,
    hasGenderDifferences: false,
    genderRate: genderRate,
    captureRate: 45,
    evolutionChainId: id,
    eggGroups: eggGroups,
    weight: 10.0,
    speed: 50,
    forms: [
      PokemonForm(
        name: 'normal',
        formType: 'normal',
        minGen: 1,
        imageId: id,
        types: ['normal'],
        exclusiveRegions: [],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BreedingLogicHelper Tests', () {
    final Map<int, Map<String, dynamic>> dummyPreEvolutions = {
      26: {'pre': 25}, // Raichu <- Pikachu
      172: {'pre': 25}, // Pichu
    };

    test('startId == targetId returns single-element path', () async {
      final args = BreedingCalcArgs(
        startId: 25,
        targetId: 25,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [_createPoke(id: 25, name: 'Pikachu', eggGroups: ['field', 'fairy'])],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, equals([[25]]));
    });

    test('startId == 132 (Ditto) returns direct [132, targetId] path', () async {
      final target = _createPoke(id: 4, name: 'Charmander', eggGroups: ['monster', 'dragon']);
      final ditto = _createPoke(id: 132, name: 'Ditto', eggGroups: ['ditto']);

      final args = BreedingCalcArgs(
        startId: 132,
        targetId: 4,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [ditto, target],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, equals([[132, 4]]));
    });

    test('Direct breeding path when species share egg group', () async {
      final pikachu = _createPoke(id: 25, name: 'Pikachu', eggGroups: ['field', 'fairy']);
      final eevee = _createPoke(id: 133, name: 'Eevee', eggGroups: ['field']);

      final args = BreedingCalcArgs(
        startId: 25,
        targetId: 133,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [pikachu, eevee],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, isNotEmpty);
      expect(paths.first, equals([25, 133]));
    });

    test('Multi-step breeding path across intermediate species', () async {
      // Bulbasaur: monster, plant
      final bulbasaur = _createPoke(id: 1, name: 'Bulbasaur', eggGroups: ['monster', 'plant']);
      // Slowpoke: monster, water1
      final slowpoke = _createPoke(id: 79, name: 'Slowpoke', eggGroups: ['monster', 'water1']);
      // Psyduck: water1, field
      final psyduck = _createPoke(id: 54, name: 'Psyduck', eggGroups: ['water1', 'field']);

      // Bulbasaur (monster) -> Slowpoke (monster, water1) -> Psyduck (water1)
      final args = BreedingCalcArgs(
        startId: 1,
        targetId: 54,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [bulbasaur, slowpoke, psyduck],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, isNotEmpty);
      expect(paths.first, equals([1, 79, 54]));
    });

    test('Baby pokemon as startId cannot breed and returns no path', () async {
      // 172 is Pichu (isBaby == true)
      final pichu = _createPoke(id: 172, name: 'Pichu', eggGroups: ['no-eggs']);
      final eevee = _createPoke(id: 133, name: 'Eevee', eggGroups: ['field']);

      final args = BreedingCalcArgs(
        startId: 172,
        targetId: 133,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [pichu, eevee],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, isEmpty);
    });

    test('useOnlyCaught filters out uncaught intermediate pokemon', () async {
      final bulbasaur = _createPoke(id: 1, name: 'Bulbasaur', eggGroups: ['monster', 'plant']);
      final slowpoke = _createPoke(id: 79, name: 'Slowpoke', eggGroups: ['monster', 'water1']);
      final psyduck = _createPoke(id: 54, name: 'Psyduck', eggGroups: ['water1', 'field']);

      // Intermediate is Slowpoke (79). If 79 is not in caughtBaseIds, path should be empty
      final argsUncaught = BreedingCalcArgs(
        startId: 1,
        targetId: 54,
        useOnlyCaught: true,
        caughtBaseIds: {1}, // Only Bulbasaur caught
        allPokemon: [bulbasaur, slowpoke, psyduck],
        preEvolutions: dummyPreEvolutions,
      );

      final pathsUncaught = await BreedingLogicHelper.calculatePathsInBackground(argsUncaught);
      expect(pathsUncaught, isEmpty);

      // Now with 79 in caughtBaseIds
      final argsCaught = BreedingCalcArgs(
        startId: 1,
        targetId: 54,
        useOnlyCaught: true,
        caughtBaseIds: {1, 79},
        allPokemon: [bulbasaur, slowpoke, psyduck],
        preEvolutions: dummyPreEvolutions,
      );

      final pathsCaught = await BreedingLogicHelper.calculatePathsInBackground(argsCaught);
      expect(pathsCaught, isNotEmpty);
      expect(pathsCaught.first, equals([1, 79, 54]));
    });

    test('Genderless or male-only target without Ditto cannot be bred by non-Ditto', () async {
      // genderRate == -1 (genderless, e.g., Magnemite 81)
      final pikachu = _createPoke(id: 25, name: 'Pikachu', eggGroups: ['mineral']);
      final magnemite = _createPoke(id: 81, name: 'Magnemite', eggGroups: ['mineral'], genderRate: -1);

      final args = BreedingCalcArgs(
        startId: 25,
        targetId: 81,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [pikachu, magnemite],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, isEmpty);

      // genderRate == 0 (100% male target, e.g. Hitmonlee 106)
      final hitmonlee = _createPoke(id: 106, name: 'Hitmonlee', eggGroups: ['humanshape'], genderRate: 0);
      final machop = _createPoke(id: 66, name: 'Machop', eggGroups: ['humanshape']);

      final argsMaleTarget = BreedingCalcArgs(
        startId: 66,
        targetId: 106,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [machop, hitmonlee],
        preEvolutions: dummyPreEvolutions,
      );

      final maleTargetPaths = await BreedingLogicHelper.calculatePathsInBackground(argsMaleTarget);
      expect(maleTargetPaths, isEmpty);
    });

    test('100% female species (genderRate == 8) cannot act as intermediate parent', () async {
      final pokeA = _createPoke(id: 1, name: 'PokeA', eggGroups: ['monster']);
      // Intermediate is 100% female (genderRate == 8)
      final pokeFemale = _createPoke(id: 115, name: 'PokeFemale', eggGroups: ['monster', 'field'], genderRate: 8);
      final pokeTarget = _createPoke(id: 133, name: 'PokeTarget', eggGroups: ['field']);

      final args = BreedingCalcArgs(
        startId: 1,
        targetId: 133,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [pokeA, pokeFemale, pokeTarget],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, isEmpty);
    });

    test('Returns empty when no compatible egg groups connect start and target', () async {
      final caterpie = _createPoke(id: 10, name: 'Caterpie', eggGroups: ['bug']);
      final geodude = _createPoke(id: 74, name: 'Geodude', eggGroups: ['mineral']);

      final args = BreedingCalcArgs(
        startId: 10,
        targetId: 74,
        useOnlyCaught: false,
        caughtBaseIds: {},
        allPokemon: [caterpie, geodude],
        preEvolutions: dummyPreEvolutions,
      );

      final paths = await BreedingLogicHelper.calculatePathsInBackground(args);
      expect(paths, isEmpty);
    });
  });
}
