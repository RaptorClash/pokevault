import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

void main() {
  group('DexLogicHelper.computeDexProgress (TDD & Boundary)', () {
    // Helper to generate mock base Pokémon
    List<Pokemon> createMockPokemonList(int count) {
      return List.generate(count, (i) {
        final id = i + 1;
        return Pokemon(
          id: id,
          nameDe: 'Pokémon $id',
          nameEn: 'Pokemon $id',
          hasGenderDifferences: false,
          genderRate: 1,
          captureRate: 45,
          evolutionChainId: 1,
          eggGroups: const [],
          weight: 10,
          speed: 50,
          forms: const [],
        );
      });
    }

    test('Standard Nationaldex (1025 base) ignores extra forms/trades/gifts in caughtIds', () {
      final mockPokemon = createMockPokemonList(1025);

      // User has 1025 base entries, PLUS 427 form/trade/gift/instance entries in caughtIds (Total: 1452)
      final allCaughtIds = [
        ...List.generate(1025, (i) => '${i + 1}'),
        '19_alola',
        '26_alola',
        '386_speed',
        '386_attack',
        'trade_special_1',
        'gift_mew',
        '25__1',
        '25__2',
      ];

      final standardDex = UserDex(
        id: 'nat_dex',
        title: 'Nationaldex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: false,
        includeGifts: false,
        isShinyDex: false,
        caughtIds: allCaughtIds,
      );

      final stats = DexLogicHelper.computeDexProgress(
        standardDex,
        allPokemon: mockPokemon,
      );

      // Must be EXACTLY 1025 of 1025, NEVER 1452 of 1025!
      expect(stats.totalCount, 1025);
      expect(stats.caughtCount, 1025);
      expect(stats.percent, 1.0);
      expect(stats.caughtCount <= stats.totalCount, isTrue);
    });

    test('Nationaldex with partial completion calculates exact fraction correctly', () {
      final mockPokemon = createMockPokemonList(1025);

      // User has caught 500 base species, plus some extra random form ids
      final caughtIds = [
        ...List.generate(500, (i) => '${i + 1}'),
        '19_alola', // Should be ignored because includeRegional is false
        'gift_jirachi', // Should be ignored because includeGifts is false
      ];

      final standardDex = UserDex(
        id: 'nat_partial',
        title: 'Nationaldex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: false,
        includeGifts: false,
        isShinyDex: false,
        caughtIds: caughtIds,
      );

      final stats = DexLogicHelper.computeDexProgress(
        standardDex,
        allPokemon: mockPokemon,
      );

      expect(stats.totalCount, 1025);
      expect(stats.caughtCount, 500);
      expect(stats.percent, closeTo(500 / 1025, 0.001));
      expect(stats.caughtCount <= stats.totalCount, isTrue);
    });

    test('Dex with forms and trades enabled expands totalCount accurately', () {
      final mockPokemon = createMockPokemonList(151);

      final specialObtainables = [
        {'id': 1, 'obtain_type': 'trade', 'pokemon_id': 1},
        {'id': 2, 'obtain_type': 'gift', 'pokemon_id': 25},
      ];

      final detailedDex = UserDex(
        id: 'kanto_all',
        title: 'Kanto mit Formen',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: true,
        includeGifts: true,
        isShinyDex: false,
        caughtIds: ['1_normal', '1_special_1_trade_unknown_normal', '25_special_2_gift_unknown_normal'],
      );

      final stats = DexLogicHelper.computeDexProgress(
        detailedDex,
        allPokemon: mockPokemon,
        specialObtainables: specialObtainables,
      );

      // 151 base + 2 special obtainables = 153 total
      expect(stats.totalCount, 153);
      expect(stats.caughtCount, 3);
      expect(stats.percent, closeTo(3 / 153, 0.001));
      expect(stats.caughtCount <= stats.totalCount, isTrue);
    });

    test('Ignored Pokémon IDs are deducted from both totalCount and caughtCount', () {
      final mockPokemon = createMockPokemonList(10);

      final dex = UserDex(
        id: 'ignored_test',
        title: 'Test Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1', '2', '3', '4'],
        ignoredIds: ['1', '2'], // 1 and 2 are caught but ignored
      );

      final stats = DexLogicHelper.computeDexProgress(
        dex,
        allPokemon: mockPokemon,
      );

      // Total was 10, minus 2 ignored = 8.
      // Caught was 4, minus 2 ignored = 2.
      expect(stats.totalCount, 8);
      expect(stats.caughtCount, 2);
      expect(stats.percent, 2 / 8);
    });

    test('Custom box dex counts box slots instead of raw species list', () {
      final dex = UserDex(
        id: 'box_dex',
        title: 'Custom Box Dex',
        region: 'custom',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['25', '26'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25', '26', '133', ''],
          ),
        ],
      );

      final stats = DexLogicHelper.computeDexProgress(dex);

      // 3 non-empty slots in Box 1 ('25', '26', '133'), 2 are caught ('25', '26')
      expect(stats.totalCount, 3);
      expect(stats.caughtCount, 2);
      expect(stats.percent, closeTo(2 / 3, 0.001));
    });

    test('Adversarial: Empty dex and empty allPokemon does not throw or divide by zero', () {
      final dex = UserDex(
        id: 'empty_dex',
        title: 'Empty',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      final stats = DexLogicHelper.computeDexProgress(dex, allPokemon: []);

      expect(stats.totalCount, greaterThanOrEqualTo(0));
      expect(stats.caughtCount, 0);
      expect(stats.percent, 0.0);
    });
  });
}
