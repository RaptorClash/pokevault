import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import 'package:pokevault/l10n/app_translations.dart';

void main() {
  group('DexLogicHelper Enhancements & Boundary Tests (TDD)', () {
    late Pokemon togetic;
    late Pokemon larvitar;
    late Pokemon treecko;
    late Pokemon furfrou;
    late List<Pokemon> pokemonList;
    late List<Map<String, dynamic>> specialObtainables;

    setUp(() {
      Translator.currentLanguage = 'de';

      togetic = Pokemon(
        id: 176,
        nameDe: 'Togetic',
        nameEn: 'Togetic',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 75,
        evolutionChainId: 87,
        eggGroups: ['flying', 'fairy'],
        weight: 3.2,
        speed: 40,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 2,
            imageId: 176,
            types: ['fairy', 'flying'],
            exclusiveRegions: [],
          ),
        ],
      );

      larvitar = Pokemon(
        id: 246,
        nameDe: 'Larvitar',
        nameEn: 'Larvitar',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 45,
        evolutionChainId: 126,
        eggGroups: ['monster'],
        weight: 72.0,
        speed: 41,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 2,
            imageId: 246,
            types: ['rock', 'ground'],
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

      furfrou = Pokemon(
        id: 676,
        nameDe: 'Coiffwaff',
        nameEn: 'Furfrou',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 120,
        evolutionChainId: 347,
        eggGroups: ['field'],
        weight: 28.0,
        speed: 102,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 6,
            imageId: 676,
            types: ['normal'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'heart',
            formType: 'other',
            minGen: 6,
            imageId: 676,
            types: ['normal'],
            exclusiveRegions: [],
          ),
        ],
      );

      final slowpoke = Pokemon(
        id: 79,
        nameDe: 'Flegmon',
        nameEn: 'Slowpoke',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 190,
        evolutionChainId: 33,
        eggGroups: ['monster', 'water1'],
        weight: 36.0,
        speed: 15,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 79,
            types: ['water', 'psychic'],
            exclusiveRegions: [],
          ),
        ],
      );

      pokemonList = [togetic, larvitar, treecko, furfrou, slowpoke];

      specialObtainables = [
        {
          'id': 75,
          'pokemon_id': 176,
          'obtain_type': 'trade',
          'game_version': 'Pokémon XD: Gale of Darkness',
          'location': 'Outskirt Stand',
          'npc_name': 'Hordel',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
        {
          'id': 242,
          'pokemon_id': 176,
          'obtain_type': 'trade',
          'game_version': 'Colosseum & XD: Der Dunkle Sturm',
          'location': 'Wüstenbar',
          'npc_name': 'Charly',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
        {
          'id': 78,
          'pokemon_id': 246,
          'obtain_type': 'trade',
          'game_version': 'Pokémon XD: Gale of Darkness',
          'location': 'Pyrite Town',
          'npc_name': 'Duking',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
        {
          'id': 245,
          'pokemon_id': 246,
          'obtain_type': 'trade',
          'game_version': 'Colosseum & XD: Der Dunkle Sturm',
          'location': 'Pyritus',
          'npc_name': 'Duking',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
        {
          'id': 205,
          'pokemon_id': 79,
          'obtain_type': 'trade',
          'game_version': 'Pokémon Legends: Z-A',
          'location': 'Illumina City',
          'npc_name': 'NPC',
          'form': 'normal',
          'is_n_pokemon': 0,
        },
      ];
    });

    test('isSecondaryForm recognizes special obtainables and glitch forms as secondary', () {
      expect(
        DexLogicHelper.isSecondaryForm('176_special_75_xd_hoenn_normal'),
        isTrue,
        reason: 'Special obtainables must be treated as secondary to prevent raw number coupling',
      );
      expect(
        DexLogicHelper.isSecondaryForm('176_special_242_colosseum_hoenn_normal'),
        isTrue,
      );
      expect(
        DexLogicHelper.isSecondaryForm('252_vc_glitch'),
        isTrue,
        reason: 'vc_glitch forms must be treated as secondary',
      );
      expect(
        DexLogicHelper.isSecondaryForm('176_normal'),
        isFalse,
      );
    });

    test('Special obtainables of Togetic do NOT share caught status with base Togetic or each other', () {
      final dex = UserDex(
        id: 'test_special_uncoupled',
        title: 'Uncoupled Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: true,
        includeGifts: true,
        isShinyDex: false,
        caughtIds: ['176'], // base Togetic is caught
      );

      const specialId1 = '176_special_75_xd_hoenn_normal';
      const specialId2 = '176_special_242_colosseum_hoenn_normal';

      // Base Togetic is caught via '176'
      expect(DexLogicHelper.isPokemonCaught(dex, '176_normal'), isTrue);

      // BUT the special trade obtainables must NOT be considered caught!
      expect(
        DexLogicHelper.isPokemonCaught(dex, specialId1),
        isFalse,
        reason: 'Special trade Togetic 1 must not inherit caught status from base Togetic 176',
      );
      expect(
        DexLogicHelper.isPokemonCaught(dex, specialId2),
        isFalse,
        reason: 'Special trade Togetic 2 must not inherit caught status from base Togetic 176',
      );

      // Now add only specialId1 to caughtIds:
      dex.caughtIds.clear();
      dex.caughtIds.add(specialId1);

      expect(DexLogicHelper.isPokemonCaught(dex, specialId1), isTrue);
      expect(
        DexLogicHelper.isPokemonCaught(dex, specialId2),
        isFalse,
        reason: 'Tapping specialId1 must not mark specialId2 as caught',
      );
      expect(
        DexLogicHelper.isPokemonCaught(dex, '176_normal'),
        isFalse,
        reason: 'Tapping specialId1 must not mark 176_normal as caught',
      );
    });

    test('Special obtainables of Togetic do NOT share shiny status with base Togetic or each other', () {
      final dex = UserDex(
        id: 'test_special_shiny',
        title: 'Shiny Uncoupled Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: true,
        includeGifts: true,
        isShinyDex: true,
        shinyIds: ['176_special_75_xd_hoenn_normal'],
      );

      expect(DexLogicHelper.isPokemonShiny(dex, '176_special_75_xd_hoenn_normal'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '176_special_242_colosseum_hoenn_normal'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '176_normal'), isFalse);
    });

    test('includeGlitch controls inclusion of vc_glitch forms in national / standard dex', () {
      final dexWithoutGlitch = UserDex(
        id: 'dex_no_glitch',
        title: 'No Glitch Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: false,
        includeGifts: false,
        includeGlitch: false,
        isShinyDex: false,
      );

      final entriesWithoutGlitch = DexLogicHelper.buildDisplayEntries(
        dexWithoutGlitch,
        pokemonList,
        [],
      );
      expect(
        entriesWithoutGlitch.any((e) => e.uniqueId == '252_vc_glitch'),
        isFalse,
        reason: 'vc_glitch forms must be omitted when includeGlitch is false',
      );

      final dexWithGlitch = UserDex(
        id: 'dex_with_glitch',
        title: 'With Glitch Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: false,
        includeGifts: false,
        includeGlitch: true,
        isShinyDex: false,
      );

      final entriesWithGlitch = DexLogicHelper.buildDisplayEntries(
        dexWithGlitch,
        pokemonList,
        [],
      );
      expect(
        entriesWithGlitch.any((e) => e.uniqueId == '252_vc_glitch'),
        isTrue,
        reason: 'vc_glitch forms must be included when includeGlitch is true',
      );
    });

    test('Box titles for cat_orre indicate Tausche in German and Trades in English', () {
      final dex = UserDex(
        id: 'dex_orre',
        title: 'Orre Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: true,
        includeGifts: true,
        isShinyDex: false,
      );

      Translator.currentLanguage = 'de';
      final entriesDe = DexLogicHelper.buildDisplayEntries(dex, pokemonList, specialObtainables);
      final boxesDe = DexLogicHelper.generateBoxes(entriesDe, true, dex);
      final orreBoxDe = boxesDe.firstWhere((b) => b.title.contains('Colosseum & XD'));
      expect(
        orreBoxDe.title.contains('Tausche'),
        isTrue,
        reason: 'Orre section title must indicate Tausche in German so user knows they are trades',
      );

      Translator.currentLanguage = 'en';
      final entriesEn = DexLogicHelper.buildDisplayEntries(dex, pokemonList, specialObtainables);
      final boxesEn = DexLogicHelper.generateBoxes(entriesEn, true, dex);
      final orreBoxEn = boxesEn.firstWhere((b) => b.title.contains('Colosseum & XD'));
      expect(
        orreBoxEn.title.contains('Trades'),
        isTrue,
        reason: 'Orre section title must indicate Trades in English',
      );
    });

    test('Box title for Lumiose trades appends (Z-A)', () {
      final dex = UserDex(
        id: 'dex_lumiose',
        title: 'Lumiose Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        includeTrades: true,
        includeGifts: true,
        isShinyDex: false,
      );

      final entries = DexLogicHelper.buildDisplayEntries(dex, pokemonList, specialObtainables);
      final boxes = DexLogicHelper.generateBoxes(entries, true, dex);
      final lumioseTradeBox = boxes.firstWhere((b) => b.regionKey == 'lumiose');
      expect(
        lumioseTradeBox.title.contains('(Z-A)'),
        isTrue,
        reason: 'Lumiose trades box header must include (Z-A)',
      );
    });

    test('Furfrou box title is localized properly as Kalos Coiffwaff in German and Kalos Furfrou in English', () {
      final dex = UserDex(
        id: 'dex_furfrou',
        title: 'Furfrou Dex',
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

      Translator.currentLanguage = 'de';
      final entriesDe = DexLogicHelper.buildDisplayEntries(dex, [furfrou], []);
      final boxesDe = DexLogicHelper.generateBoxes(entriesDe, true, dex);
      final furfrouBoxDe = boxesDe.firstWhere((b) => b.title.contains('Coiffwaff'));
      expect(furfrouBoxDe.title.contains('Coiffwaff'), isTrue);
      expect(furfrouBoxDe.title.contains('furfrou'), isFalse);

      Translator.currentLanguage = 'en';
      final entriesEn = DexLogicHelper.buildDisplayEntries(dex, [furfrou], []);
      final boxesEn = DexLogicHelper.generateBoxes(entriesEn, true, dex);
      final furfrouBoxEn = boxesEn.firstWhere((b) => b.title.contains('Furfrou'));
      expect(furfrouBoxEn.title.contains('Furfrou'), isTrue);
    });
  });
}
