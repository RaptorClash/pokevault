import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_progress_helper.dart';

Pokemon _createTestPokemon({
  required int id,
  String nameDe = 'TestMon',
  String nameEn = 'TestMon',
  List<String> types = const ['normal'],
  String formType = 'normal',
  String formName = 'normal',
}) {
  return Pokemon(
    id: id,
    nameDe: nameDe,
    nameEn: nameEn,
    hasGenderDifferences: false,
    genderRate: 4,
    captureRate: 255,
    evolutionChainId: 1,
    eggGroups: ['monster'],
    weight: 10.0,
    speed: 50,
    forms: [
      PokemonForm(
        name: formName,
        formType: formType,
        minGen: 1,
        imageId: id,
        types: types,
        exclusiveRegions: [],
      ),
    ],
  );
}

DexDisplayEntry _createEntry({
  required Pokemon pokemon,
  required String uniqueId,
  PokemonForm? form,
}) {
  return DexDisplayEntry(
    pokemon: pokemon,
    uniqueId: uniqueId,
    displaySuffix: '',
    imageUrl: 'https://example.com/$uniqueId.png',
    form: form ?? (pokemon.forms.isNotEmpty ? pokemon.forms.first : null),
  );
}

void main() {
  group('DexProgressHelper TDD Tests', () {
    test('calculate returns 0% and empty lists for empty entries', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Empty Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      final stats = DexProgressHelper.calculate(dex, []);

      expect(stats.totalCount, 0);
      expect(stats.caughtCount, 0);
      expect(stats.percentage, 0.0);
      expect(stats.shinyCount, 0);
      expect(stats.alphaCount, 0);
      expect(stats.generationStats, isEmpty);
      expect(stats.typeStats, isEmpty);
      expect(stats.variantStats, isEmpty);
    });

    test('calculate ignores placeholder entries and ignoredIds', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Kanto Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal', '2_normal'],
        ignoredIds: ['2_normal'],
      );

      final p1 = _createTestPokemon(id: 1, nameDe: 'Bisasam');
      final p2 = _createTestPokemon(id: 2, nameDe: 'Bisaknosp');

      final entries = [
        _createEntry(pokemon: p1, uniqueId: '1_normal'),
        _createEntry(pokemon: p2, uniqueId: '2_normal'),
        DexDisplayEntry.placeholderEntry('placeholder__1'),
      ];

      final stats = DexProgressHelper.calculate(dex, entries);

      // p2 is ignored, placeholder is placeholder -> only p1 is counted
      expect(stats.totalCount, 1);
      expect(stats.caughtCount, 1);
      expect(stats.percentage, 100.0);
    });

    test('calculate computes partial completion percentage correctly', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Kanto Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal', '2_normal', '3_normal'],
        shinyIds: ['1_normal'],
        alphaIds: ['2_normal'],
      );

      final p1 = _createTestPokemon(id: 1, nameDe: 'Bisasam');
      final p2 = _createTestPokemon(id: 2, nameDe: 'Bisaknosp');
      final p3 = _createTestPokemon(id: 3, nameDe: 'Bisaflor');
      final p4 = _createTestPokemon(id: 4, nameDe: 'Glumanda');

      final entries = [
        _createEntry(pokemon: p1, uniqueId: '1_normal'),
        _createEntry(pokemon: p2, uniqueId: '2_normal'),
        _createEntry(pokemon: p3, uniqueId: '3_normal'),
        _createEntry(pokemon: p4, uniqueId: '4_normal'),
      ];

      final stats = DexProgressHelper.calculate(dex, entries);

      expect(stats.totalCount, 4);
      expect(stats.caughtCount, 3);
      expect(stats.percentage, 75.0);
      expect(stats.shinyCount, 1);
      expect(stats.alphaCount, 1);
    });

    test('calculate correctly groups by Generations and omits unused Gens', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Multi-Gen Dex',
        region: 'national',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal', '152_normal', '906_normal'],
      );

      final pGen1 = _createTestPokemon(id: 1, nameDe: 'Bisasam'); // Gen 1 (1-151)
      final pGen1_2 = _createTestPokemon(id: 151, nameDe: 'Mew'); // Gen 1 (1-151)
      final pGen2 = _createTestPokemon(id: 152, nameDe: 'Endivie'); // Gen 2 (152-251)
      final pGen9 = _createTestPokemon(id: 906, nameDe: 'Felori'); // Gen 9 (906-1025)

      final entries = [
        _createEntry(pokemon: pGen1, uniqueId: '1_normal'),
        _createEntry(pokemon: pGen1_2, uniqueId: '151_normal'),
        _createEntry(pokemon: pGen2, uniqueId: '152_normal'),
        _createEntry(pokemon: pGen9, uniqueId: '906_normal'),
      ];

      final stats = DexProgressHelper.calculate(dex, entries, language: 'de');

      // Only Gen 1, Gen 2, and Gen 9 should be in generationStats
      expect(stats.generationStats.length, 3);

      final gen1 = stats.generationStats.firstWhere((g) => g.key == 'gen_1');
      expect(gen1.name, contains('Gen 1'));
      expect(gen1.total, 2);
      expect(gen1.caught, 1);
      expect(gen1.percentage, 50.0);
      expect(gen1.isComplete, false);

      final gen2 = stats.generationStats.firstWhere((g) => g.key == 'gen_2');
      expect(gen2.name, contains('Gen 2'));
      expect(gen2.total, 1);
      expect(gen2.caught, 1);
      expect(gen2.percentage, 100.0);
      expect(gen2.isComplete, true);

      final gen9 = stats.generationStats.firstWhere((g) => g.key == 'gen_9');
      expect(gen9.name, contains('Gen 9'));
      expect(gen9.total, 1);
      expect(gen9.caught, 1);
      expect(gen9.percentage, 100.0);
      expect(gen9.isComplete, true);
    });

    test('calculate correctly tallies dual types for both types and assigns type colors', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Types Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal'],
      );

      // Bisasam is grass and poison
      final pBulba = _createTestPokemon(id: 1, nameDe: 'Bisasam', types: ['grass', 'poison']);
      // Glumanda is fire
      final pCharm = _createTestPokemon(id: 4, nameDe: 'Glumanda', types: ['fire']);

      final entries = [
        _createEntry(pokemon: pBulba, uniqueId: '1_normal'),
        _createEntry(pokemon: pCharm, uniqueId: '4_normal'),
      ];

      final stats = DexProgressHelper.calculate(dex, entries, language: 'de');

      // Types occurring: grass, poison, fire (3 types)
      expect(stats.typeStats.length, 3);

      final grass = stats.typeStats.firstWhere((t) => t.key == 'grass');
      expect(grass.total, 1);
      expect(grass.caught, 1);
      expect(grass.color, const Color(0xFF7AC74C));

      final poison = stats.typeStats.firstWhere((t) => t.key == 'poison');
      expect(poison.total, 1);
      expect(poison.caught, 1);
      expect(poison.color, const Color(0xFFA33EA1));

      final fire = stats.typeStats.firstWhere((t) => t.key == 'fire');
      expect(fire.total, 1);
      expect(fire.caught, 0);
      expect(fire.percentage, 0.0);
      expect(fire.color, const Color(0xFFEE8130));
    });

    test('calculate categorizes variants: regular, regional, mega, gmax, shiny, alpha', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Variants Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal', '19_alola', '6_mega_x'],
        shinyIds: ['1_normal'],
        alphaIds: ['19_alola'],
      );

      final pRegular = _createTestPokemon(id: 1, nameDe: 'Bisasam', formType: 'normal');
      final pRegional = _createTestPokemon(id: 19, nameDe: 'Alola-Rattfratz', formType: 'regional', formName: 'alola');
      final pMega = _createTestPokemon(id: 6, nameDe: 'Mega-Glurak X', formType: 'mega', formName: 'mega_x');
      final pGmax = _createTestPokemon(id: 25, nameDe: 'Gigadynamax-Pikachu', formType: 'gmax', formName: 'gmax');

      final entries = [
        _createEntry(pokemon: pRegular, uniqueId: '1_normal'),
        _createEntry(pokemon: pRegional, uniqueId: '19_alola'),
        _createEntry(pokemon: pMega, uniqueId: '6_mega_x'),
        _createEntry(pokemon: pGmax, uniqueId: '25_gmax'),
      ];

      final stats = DexProgressHelper.calculate(dex, entries, language: 'de');

      final reg = stats.variantStats.firstWhere((v) => v.key == 'regular');
      expect(reg.total, 1);
      expect(reg.caught, 1);

      final regional = stats.variantStats.firstWhere((v) => v.key == 'regional');
      expect(regional.total, 1);
      expect(regional.caught, 1);

      final mega = stats.variantStats.firstWhere((v) => v.key == 'mega');
      expect(mega.total, 1);
      expect(mega.caught, 1);

      final gmax = stats.variantStats.firstWhere((v) => v.key == 'gmax');
      expect(gmax.total, 1);
      expect(gmax.caught, 0);

      final shiny = stats.variantStats.firstWhere((v) => v.key == 'shiny');
      expect(shiny.total, 4);
      expect(shiny.caught, 1);

      final alpha = stats.variantStats.firstWhere((v) => v.key == 'alpha');
      expect(alpha.total, 4);
      expect(alpha.caught, 1);
    });

    test('calculate works seamlessly with custom boxes instance IDs', () {
      final dex = UserDex(
        id: 'custom_dex',
        title: 'Custom Box Dex',
        region: 'custom',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal__1234_0'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['1_normal__1234_0', '1_normal__5678_1'],
          ),
        ],
      );

      final p = _createTestPokemon(id: 1, nameDe: 'Bisasam');
      final entries = [
        _createEntry(pokemon: p, uniqueId: '1_normal__1234_0'),
        _createEntry(pokemon: p, uniqueId: '1_normal__5678_1'),
      ];

      final stats = DexProgressHelper.calculate(dex, entries);

      expect(stats.totalCount, 2);
      expect(stats.caughtCount, 1);
      expect(stats.percentage, 50.0);
    });

    test('calculate returns localized variant names for English', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Variants Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: false,
        isShinyDex: false,
      );

      final pRegular = _createTestPokemon(id: 1, nameDe: 'Bisasam', formType: 'normal');
      final pRegional = _createTestPokemon(id: 19, nameDe: 'Alola-Rattfratz', formType: 'regional', formName: 'alola');
      final pMega = _createTestPokemon(id: 6, nameDe: 'Mega-Glurak X', formType: 'mega', formName: 'mega_x');
      final pGmax = _createTestPokemon(id: 25, nameDe: 'Gigadynamax-Pikachu', formType: 'gmax', formName: 'gmax');

      final entries = [
        _createEntry(pokemon: pRegular, uniqueId: '1_normal'),
        _createEntry(pokemon: pRegional, uniqueId: '19_alola'),
        _createEntry(pokemon: pMega, uniqueId: '6_mega_x'),
        _createEntry(pokemon: pGmax, uniqueId: '25_gmax'),
      ];

      final stats = DexProgressHelper.calculate(dex, entries, language: 'en');

      final reg = stats.variantStats.firstWhere((v) => v.key == 'regular');
      expect(reg.name, 'Regular Forms');

      final regional = stats.variantStats.firstWhere((v) => v.key == 'regional');
      expect(regional.name, 'Regional Forms');

      final mega = stats.variantStats.firstWhere((v) => v.key == 'mega');
      expect(mega.name, 'Mega Evolutions');

      final gmax = stats.variantStats.firstWhere((v) => v.key == 'gmax');
      expect(gmax.name, 'Gigantamax');

      final shiny = stats.variantStats.firstWhere((v) => v.key == 'shiny');
      expect(shiny.name, 'Shinies');

      final alpha = stats.variantStats.firstWhere((v) => v.key == 'alpha');
      expect(alpha.name, 'Alpha Pokémon');
    });
  });
}
