import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

void main() {
  group('Let\'s Go In-Game Trades Alola Forms Tests (TDD)', () {
    late Pokemon rattata;
    late Pokemon raichu;
    late List<Pokemon> pokemonList;
    late List<Map<String, dynamic>> specialObtainables;

    setUp(() {
      rattata = Pokemon(
        id: 19,
        nameDe: 'Rattfratz',
        nameEn: 'Rattata',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 255,
        evolutionChainId: 7,
        eggGroups: ['field'],
        weight: 3.5,
        speed: 72,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 19,
            types: ['normal'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'alola',
            formType: 'regional',
            minGen: 7,
            imageId: 10091,
            types: ['dark', 'normal'],
            exclusiveRegions: [],
          ),
        ],
      );

      raichu = Pokemon(
        id: 26,
        nameDe: 'Raichu',
        nameEn: 'Raichu',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 75,
        evolutionChainId: 10,
        eggGroups: ['field', 'fairy'],
        weight: 30.0,
        speed: 110,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 26,
            types: ['electric'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'alola',
            formType: 'regional',
            minGen: 7,
            imageId: 10100,
            types: ['electric', 'psychic'],
            exclusiveRegions: [],
          ),
        ],
      );

      pokemonList = [rattata, raichu];

      specialObtainables = [
        // English Let's Go trade (straight quote)
        {
          'id': 140,
          'pokemon_id': 19,
          'obtain_type': 'trade',
          'game_version': "Pokémon: Let's Go, Pikachu! and Let's Go, Eevee!",
          'location': 'Cerulean City',
          'npc_name': '',
          'form': 'alola',
          'is_n_pokemon': 0,
        },
        // German Let's Go trade (curly quote ’)
        {
          'id': 292,
          'pokemon_id': 19,
          'obtain_type': 'trade',
          'game_version': 'Pokémon: Let’s Go, Pikachu! und Let’s Go, Evoli!',
          'location': 'Azuria City',
          'npc_name': '',
          'form': 'normal', // Old database row had 'normal'
          'is_n_pokemon': 0,
        },
        // German Let's Go trade for Raichu with curly quote
        {
          'id': 298,
          'pokemon_id': 26,
          'obtain_type': 'trade',
          'game_version': 'Pokémon: Let’s Go, Pikachu! und Let’s Go, Evoli!',
          'location': 'Saffronia City',
          'npc_name': '',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
      ];
    });

    test('Let\'s Go trades are resolved to Alola form, image URL and name suffix', () {
      final dex = UserDex(
        id: 'dex_lets_go_test',
        title: 'Let\'s Go Test',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        includeTrades: true,
        includeGifts: true,
      );

      final entries = DexLogicHelper.buildDisplayEntries(
        dex,
        pokemonList,
        specialObtainables,
      );

      final tradeEntries = entries.where((e) => e.uniqueId.contains('_trade_')).toList();

      // Because English (140) and German (292) are both Rattata Let's Go trades,
      // they must deduplicate to a single entry!
      final rattataTrades = tradeEntries.where((e) => e.pokemon.id == 19).toList();
      expect(rattataTrades.length, 1, reason: 'Duplicate trades should be deduplicated');

      final rattataEntry = rattataTrades.first;
      expect(rattataEntry.form?.name, 'alola');
      expect(rattataEntry.uniqueId, contains('alola'));
      expect(rattataEntry.imageUrl, contains('10091.png'));
      expect(rattataEntry.displaySuffix, contains('(Alola)'));

      // Check Raichu trade (which came from German curly quote row)
      final raichuTrades = tradeEntries.where((e) => e.pokemon.id == 26).toList();
      expect(raichuTrades.length, 1);
      final raichuEntry = raichuTrades.first;
      expect(raichuEntry.form?.name, 'alola');
      expect(raichuEntry.uniqueId, contains('alola'));
      expect(raichuEntry.imageUrl, contains('10100.png'));
      expect(raichuEntry.displaySuffix, contains('(Alola)'));
    });
  });
}
