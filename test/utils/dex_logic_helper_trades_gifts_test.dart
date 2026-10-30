import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

void main() {
  group('DexLogicHelper Trades, Gifts and Glitch Dex Tests (TDD)', () {
    late Pokemon poliwhirl;
    late Pokemon eevee;
    late Pokemon alcremie;
    late Pokemon treecko;
    late Pokemon torchic;
    late Pokemon mew;
    late List<Pokemon> pokemonList;
    late List<Map<String, dynamic>> specialObtainables;

    setUp(() {
      poliwhirl = Pokemon(
        id: 61,
        nameDe: 'Quaputzi',
        nameEn: 'Poliwhirl',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 120,
        evolutionChainId: 26,
        eggGroups: ['water1'],
        weight: 20.0,
        speed: 90,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 61,
            types: ['water'],
            exclusiveRegions: [],
          ),
        ],
      );

      eevee = Pokemon(
        id: 133,
        nameDe: 'Evoli',
        nameEn: 'Eevee',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 67,
        eggGroups: ['ground'],
        weight: 6.5,
        speed: 55,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 133,
            types: ['normal'],
            exclusiveRegions: [],
          ),
        ],
      );

      alcremie = Pokemon(
        id: 869,
        nameDe: 'Pokusan',
        nameEn: 'Alcremie',
        hasGenderDifferences: false,
        genderRate: 8,
        captureRate: 100,
        evolutionChainId: 450,
        eggGroups: ['fairy', 'amorphous'],
        weight: 0.5,
        speed: 64,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 8,
            imageId: 869,
            types: ['fairy'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'ruby-cream',
            formType: 'other',
            minGen: 8,
            imageId: 869,
            types: ['fairy'],
            exclusiveRegions: [],
          ),
        ],
      );

      treecko = Pokemon(
        id: 252,
        nameDe: 'Geckarbor',
        nameEn: 'Treecko',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 130,
        eggGroups: ['monster', 'dragon'],
        weight: 5.0,
        speed: 70,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 3,
            imageId: 252,
            types: ['grass'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'vc_glitch',
            formType: 'other',
            minGen: 2,
            imageId: 252,
            types: ['grass'],
            exclusiveRegions: [],
          ),
        ],
      );

      torchic = Pokemon(
        id: 255,
        nameDe: 'Flemmli',
        nameEn: 'Torchic',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 131,
        eggGroups: ['field'],
        weight: 2.5,
        speed: 45,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 3,
            imageId: 255,
            types: ['fire'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'vc_glitch',
            formType: 'other',
            minGen: 2,
            imageId: 255,
            types: ['fire'],
            exclusiveRegions: [],
          ),
        ],
      );

      mew = Pokemon(
        id: 151,
        nameDe: 'Mew',
        nameEn: 'Mew',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 45,
        evolutionChainId: 78,
        eggGroups: ['no-eggs'],
        weight: 4.0,
        speed: 100,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 151,
            types: ['psychic'],
            exclusiveRegions: [],
          ),
        ],
      );

      pokemonList = [poliwhirl, eevee, alcremie, treecko, torchic, mew];

      specialObtainables = [
        {
          'id': 128,
          'pokemon_id': 61,
          'obtain_type': 'trade',
          'game_version': 'Pokémon Sun and Moon',
          'location': 'Route 5',
          'npc_name': 'Barabara',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
        {
          'id': 50,
          'pokemon_id': 133,
          'obtain_type': 'gift',
          'game_version': 'Pokémon Yellow',
          'location': 'Celadon Mansion',
          'npc_name': 'NPC',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
      ];
    });

    test('Disabling includeTrades removes in-game trade entries but keeps gifts', () {
      final dex = UserDex(
        id: 'dex_trade_off',
        title: 'Dex Without Trades',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: false,
        includeGifts: true,
        isShinyDex: false,
      );

      final entries = DexLogicHelper.buildDisplayEntries(
        dex,
        pokemonList,
        specialObtainables,
      );

      final hasTradePoliwhirl = entries.any((e) => e.uniqueId.contains('special_128_trade'));
      final hasGiftEevee = entries.any((e) => e.uniqueId.contains('special_50_gift'));

      expect(hasTradePoliwhirl, isFalse);
      expect(hasGiftEevee, isTrue);
    });

    test('Disabling includeGifts removes gift entries but keeps trades', () {
      final dex = UserDex(
        id: 'dex_gift_off',
        title: 'Dex Without Gifts',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: true,
        includeGifts: false,
        isShinyDex: false,
      );

      final entries = DexLogicHelper.buildDisplayEntries(
        dex,
        pokemonList,
        specialObtainables,
      );

      final hasTradePoliwhirl = entries.any((e) => e.uniqueId.contains('special_128_trade'));
      final hasGiftEevee = entries.any((e) => e.uniqueId.contains('special_50_gift'));

      expect(hasTradePoliwhirl, isTrue);
      expect(hasGiftEevee, isFalse);
    });

    test('includeOther only controls other forms (costumes/alcremie) and does not force trades/gifts', () {
      final dex = UserDex(
        id: 'dex_other_only',
        title: 'Other Only Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: false,
        includeGifts: false,
        isShinyDex: false,
      );

      final entries = DexLogicHelper.buildDisplayEntries(
        dex,
        pokemonList,
        specialObtainables,
      );

      final hasTradePoliwhirl = entries.any((e) => e.uniqueId.contains('special_128_trade'));
      final hasGiftEevee = entries.any((e) => e.uniqueId.contains('special_50_gift'));
      final hasAlcremieOther = entries.any((e) => e.uniqueId == '869_ruby-cream');

      expect(hasTradePoliwhirl, isFalse);
      expect(hasGiftEevee, isFalse);
      expect(hasAlcremieOther, isTrue);
    });

    test('glitch_dex correctly includes Mew and Gen 3 starters with vc_glitch form', () {
      final dex = UserDex(
        id: 'glitch_dex_1',
        title: 'Glitch Dex',
        region: 'glitch_dex',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        includeTrades: false,
        includeGifts: false,
        isShinyDex: false,
      );

      final entries = DexLogicHelper.buildDisplayEntries(
        dex,
        pokemonList,
        [],
      );

      expect(entries.any((e) => e.pokemon.id == 151), isTrue);
      expect(entries.any((e) => e.pokemon.id == 252 && e.uniqueId.contains('vc_glitch')), isTrue);
      expect(entries.any((e) => e.pokemon.id == 255 && e.uniqueId.contains('vc_glitch')), isTrue);
    });
  });
}
