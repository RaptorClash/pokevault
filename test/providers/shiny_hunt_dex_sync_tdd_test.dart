import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('pokevault_shiny_dex_sync_tdd_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    await DatabaseService.instance.clearUserData();
  });

  group('Shiny Hunt & Dex Sync TDD Tests', () {
    test('1. Normal form hunt without targetUniqueId syncs canonical "1_normal" to Dex', () async {
      final dex = UserDex(
        id: 'dex-tdd-1',
        title: 'Kanto Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [
        Pokemon(
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
          forms: [
            PokemonForm(
              name: 'normal',
              formType: 'normal',
              minGen: 1,
              imageId: 1,
              types: ['Grass', 'Poison'],
              exclusiveRegions: [],
            ),
          ],
        ),
      ];

      final huntProvider = ShinyHuntProvider(databaseService: DatabaseService.instance);
      await huntProvider.initialized;

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-bulbasaur-1',
        title: 'Bulbasaur Hunt',
        pokemonId: 1,
        pokemonName: 'Bisasam',
        pokemonFormId: 1,
        targetDexId: 'dex-tdd-1',
        targetUniqueId: null, // Started from Hub without targetUniqueId
        game: 'FireRed',
        generation: 3.0,
        method: 'Wild',
        baseOdds: 8192.0,
        currentEncounters: 1500,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      // Complete the hunt as caught
      await huntProvider.completeHunt(
        'hunt-bulbasaur-1',
        ballUsed: 'poke-ball',
        targetDexId: 'dex-tdd-1',
        dexProvider: dexProvider,
      );

      final completedHunt = huntProvider.getHuntById('hunt-bulbasaur-1')!;
      expect(completedHunt.isCompleted, isTrue);
      expect(completedHunt.targetUniqueId, equals('1_normal'));

      // The Dex caughtIds and shinyIds MUST contain the canonical '1_normal'
      expect(dex.caughtIds.contains('1_normal'), isTrue,
          reason: "Dex caughtIds should contain '1_normal' instead of plain '1'");
      expect(dex.shinyIds.contains('1_normal'), isTrue,
          reason: "Dex shinyIds should contain '1_normal' instead of plain '1'");

      // DexLogicHelper MUST consider '1_normal' as caught and shiny
      expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '1_normal'), isTrue);

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('2. Form variant hunt without targetUniqueId syncs "26_alola" to Dex', () async {
      final dex = UserDex(
        id: 'dex-tdd-2',
        title: 'Alola Dex',
        region: 'alola',
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [
        Pokemon(
          id: 26,
          nameDe: 'Raichu',
          nameEn: 'Raichu',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 75,
          evolutionChainId: 10,
          eggGroups: ['Field', 'Fairy'],
          weight: 30.0,
          speed: 110,
          forms: [
            PokemonForm(
              name: 'normal',
              formType: 'normal',
              minGen: 1,
              imageId: 26,
              types: ['Electric'],
              exclusiveRegions: [],
            ),
            PokemonForm(
              name: 'alola',
              formType: 'regional',
              minGen: 7,
              imageId: 10100,
              types: ['Electric', 'Psychic'],
              exclusiveRegions: ['alola'],
            ),
          ],
        ),
      ];

      final huntProvider = ShinyHuntProvider(databaseService: DatabaseService.instance);
      await huntProvider.initialized;

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-raichu-alola',
        title: 'Alolan Raichu Hunt',
        pokemonId: 26,
        pokemonName: 'Alola-Raichu',
        pokemonFormId: 10100,
        targetDexId: 'dex-tdd-2',
        targetUniqueId: null,
        game: 'Ultra Sun',
        generation: 7.0,
        method: 'SOS Chain',
        baseOdds: 4096.0,
        currentEncounters: 350,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      await huntProvider.completeHunt(
        'hunt-raichu-alola',
        ballUsed: 'ultra-ball',
        targetDexId: 'dex-tdd-2',
        dexProvider: dexProvider,
      );

      final completedHunt = huntProvider.getHuntById('hunt-raichu-alola')!;
      expect(completedHunt.targetUniqueId, equals('26_alola'));
      expect(dex.caughtIds.contains('26_alola'), isTrue);
      expect(dex.shinyIds.contains('26_alola'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '26_alola'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '26_alola'), isTrue);

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('3. Phase shiny catch records canonical "41_normal" in Dex', () async {
      final dex = UserDex(
        id: 'dex-tdd-3',
        title: 'Johto Dex',
        region: 'johto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];

      final huntProvider = ShinyHuntProvider(databaseService: DatabaseService.instance);
      await huntProvider.initialized;

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-phase-sync',
        title: 'Dunsparce Hunt',
        pokemonId: 206,
        pokemonName: 'Dummisel',
        game: 'HeartGold',
        generation: 4.0,
        method: 'Rock Smash',
        baseOdds: 8192.0,
        currentEncounters: 420,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      // Record a phase catch of a Zubat (#41)
      await huntProvider.recordPhaseShiny(
        'hunt-phase-sync',
        caughtPokemonId: 41,
        caughtPokemonName: 'Zubat',
        syncToDex: true,
        targetDexId: 'dex-tdd-3',
        dexProvider: dexProvider,
      );

      expect(dex.caughtIds.contains('41_normal'), isTrue,
          reason: "Phase catch should record '41_normal' instead of '41'");
      expect(dex.shinyIds.contains('41_normal'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '41_normal'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '41_normal'), isTrue);

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('4. Living Dex with Custom Box slots marks instances as caught & shiny', () async {
      final customBox = CustomBoxState(
        title: 'Box 1',
        pokemonIds: [
          '1_normal__1700000000_0',
          '4_normal__1700000000_1',
          '7_normal__1700000000_2',
        ],
      );

      final dex = UserDex(
        id: 'dex-tdd-4',
        title: 'Living Dex',
        region: 'national',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
        customBoxes: [customBox],
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];

      final huntProvider = ShinyHuntProvider(databaseService: DatabaseService.instance);
      await huntProvider.initialized;

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-living-dex',
        title: 'Bulbasaur Living Dex Hunt',
        pokemonId: 1,
        pokemonName: 'Bisasam',
        pokemonFormId: 1,
        targetDexId: 'dex-tdd-4',
        targetUniqueId: null,
        game: 'Scarlet',
        generation: 9.0,
        method: 'Masuda',
        baseOdds: 512.0,
        currentEncounters: 300,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      await huntProvider.completeHunt(
        'hunt-living-dex',
        targetDexId: 'dex-tdd-4',
        dexProvider: dexProvider,
      );

      // The specific slot in the custom box MUST be marked caught & shiny
      expect(dex.caughtIds.contains('1_normal__1700000000_0'), isTrue);
      expect(dex.shinyIds.contains('1_normal__1700000000_0'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__1700000000_0'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '1_normal__1700000000_0'), isTrue);

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('5. Backward compatibility: Dex with legacy "1" in caughtIds/shinyIds is recognized as caught & shiny', () {
      final dex = UserDex(
        id: 'dex-legacy',
        title: 'Legacy Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1', '25'],
        shinyIds: ['1', '25'],
      );

      // Even though dex only stores '1' or '25', isPokemonCaught & isPokemonShiny with '1_normal' must return true!
      expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '1_normal'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '25_normal'), isTrue);

      // Plain ID queries should also work
      expect(DexLogicHelper.isPokemonCaught(dex, '1'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '1'), isTrue);

      // Uncaught pokemon remains false
      expect(DexLogicHelper.isPokemonCaught(dex, '4_normal'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '4_normal'), isFalse);
    });

    test('6. Gender Dex marks male/female entries and DexLogicHelper evaluates them correctly', () async {
      final dex = UserDex(
        id: 'dex-gender',
        title: 'Gender Dex',
        region: 'kanto',
        includeGenders: true,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];

      // Mark Pikachu caught and shiny via markPokemonCaughtAndShiny with normal form
      await dexProvider.markPokemonCaughtAndShiny('dex-gender', '25_normal');

      final liveDex = dexProvider.userDexes.firstWhere((d) => d.id == 'dex-gender');

      // In a gender dex, primary gender '25_m' should be caught & shiny
      expect(liveDex.caughtIds.contains('25_m'), isTrue);
      expect(liveDex.shinyIds.contains('25_m'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(liveDex, '25_m'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(liveDex, '25_m'), isTrue);

      // Mark Pikachu a second time, it should fill female slot '25_f'
      await dexProvider.markPokemonCaughtAndShiny('dex-gender', '25_normal');
      expect(liveDex.caughtIds.contains('25_f'), isTrue);
      expect(liveDex.shinyIds.contains('25_f'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(liveDex, '25_f'), isTrue);

      dexProvider.dispose();
    });

    test('7. Adversarial cases: empty uniqueId, placeholder, multiple custom box instances', () {
      final box = CustomBoxState(
        title: 'Custom Box',
        pokemonIds: [
          '1_normal__inst1',
          '1_normal__inst2',
          'placeholder__999',
        ],
      );
      final dex = UserDex(
        id: 'dex-adv',
        title: 'Adv Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal'],
        shinyIds: ['1_normal'],
        customBoxes: [box],
      );

      // Placeholders must never be caught
      expect(DexLogicHelper.isPokemonCaught(dex, ''), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, 'placeholder__999'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, ''), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, 'placeholder__999'), isFalse);

      // Base caught -> first instance inherits caught, second instance does not
      expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__inst1'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__inst2'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '1_normal__inst1'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '1_normal__inst2'), isFalse);
    });

    test('8. Base form not named "normal" (Giratina "altered") syncs and evaluates correctly for both new hunts and legacy numbers', () async {
      final dex = UserDex(
        id: 'dex-giratina',
        title: 'Sinnoh Dex',
        region: 'sinnoh',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['487'],
        shinyIds: ['487'],
      );
      await DatabaseService.instance.saveUserDex(dex);

      // Legacy check: dex only has '487', but dex entry is '487_altered'
      expect(DexLogicHelper.isPokemonCaught(dex, '487_altered'), isTrue,
          reason: 'Legacy number 487 must be recognized as caught for base form altered');
      expect(DexLogicHelper.isPokemonShiny(dex, '487_altered'), isTrue,
          reason: 'Legacy number 487 must be recognized as shiny for base form altered');

      // Now complete a hunt for Giratina without targetUniqueId
      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [
        Pokemon(
          id: 487,
          nameDe: 'Giratina',
          nameEn: 'Giratina',
          hasGenderDifferences: false,
          genderRate: -1,
          captureRate: 3,
          evolutionChainId: 250,
          eggGroups: ['Undiscovered'],
          weight: 750.0,
          speed: 90,
          forms: [
            PokemonForm(
              name: 'altered',
              formType: 'normal',
              minGen: 4,
              imageId: 487,
              types: ['Ghost', 'Dragon'],
              exclusiveRegions: [],
            ),
            PokemonForm(
              name: 'origin',
              formType: 'other',
              minGen: 4,
              imageId: 10007,
              types: ['Ghost', 'Dragon'],
              exclusiveRegions: [],
            ),
          ],
        ),
      ];

      final huntProvider = ShinyHuntProvider(databaseService: DatabaseService.instance);
      await huntProvider.initialized;

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-giratina',
        title: 'Giratina Hunt',
        pokemonId: 487,
        pokemonName: 'Giratina',
        pokemonFormId: 487,
        targetDexId: 'dex-giratina',
        targetUniqueId: null,
        game: 'Platinum',
        generation: 4.0,
        method: 'Soft Reset',
        baseOdds: 8192.0,
        currentEncounters: 2000,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      await huntProvider.completeHunt(
        'hunt-giratina',
        ballUsed: 'dusk-ball',
        targetDexId: 'dex-giratina',
        dexProvider: dexProvider,
      );

      final completedHunt = huntProvider.getHuntById('hunt-giratina')!;
      expect(completedHunt.targetUniqueId, equals('487_altered'),
          reason: 'Giratina hunt targetUniqueId should resolve to canonical 487_altered, not 487_normal');
      expect(dex.caughtIds.contains('487_altered'), isTrue);
      expect(dex.shinyIds.contains('487_altered'), isTrue);

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('9. Living Dex with duplicate slots fills only the first uncaught slot on catch', () async {
      final customBox = CustomBoxState(
        title: 'Bulbasaur Box',
        pokemonIds: [
          '1_normal__slot1',
          '1_normal__slot2',
        ],
      );

      final dex = UserDex(
        id: 'dex-duplicate-slots',
        title: 'Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
        customBoxes: [customBox],
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];

      // Mark first shiny catch
      await dexProvider.markPokemonCaughtAndShiny('dex-duplicate-slots', '1_normal');

      final liveDex = dexProvider.userDexes.firstWhere((d) => d.id == 'dex-duplicate-slots');

      // ONLY the first slot should be marked caught & shiny in customBoxes!
      expect(liveDex.caughtIds.contains('1_normal__slot1'), isTrue,
          reason: 'First uncaught slot should be filled');
      expect(liveDex.caughtIds.contains('1_normal__slot2'), isFalse,
          reason: 'Second slot should remain uncaught after 1 catch');
      expect(DexLogicHelper.isPokemonCaught(liveDex, '1_normal__slot1'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(liveDex, '1_normal__slot2'), isFalse);

      // Now mark second catch
      await dexProvider.markPokemonCaughtAndShiny('dex-duplicate-slots', '1_normal');

      // Now BOTH slots should be caught & shiny
      expect(liveDex.caughtIds.contains('1_normal__slot2'), isTrue,
          reason: 'Second slot should be filled after second catch');
      expect(DexLogicHelper.isPokemonCaught(liveDex, '1_normal__slot2'), isTrue);

      dexProvider.dispose();
    });

    test('10. Gender Dex: Non-gender Pokemon (Bulbasaur) does not generate dummy _m/_f entries', () async {
      final dex = UserDex(
        id: 'dex-gender-check',
        title: 'Gender Dex',
        region: 'kanto',
        includeGenders: true,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [
        Pokemon(
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
        ),
      ];

      await dexProvider.markPokemonCaughtAndShiny('dex-gender-check', '1_normal');

      // Bulbasaur does not have gender differences, so it should NOT add '1_m' or '1_f'
      expect(dex.caughtIds.contains('1_m'), isFalse,
          reason: 'Non-gender Pokemon must not create dummy 1_m entry');
      expect(dex.caughtIds.contains('1_f'), isFalse,
          reason: 'Non-gender Pokemon must not create dummy 1_f entry');

      dexProvider.dispose();
    });

    test('11. Phase catch for Pokemon with non-normal base form (Giratina) records "487_altered"', () async {
      final dex = UserDex(
        id: 'dex-tdd-phase-giratina',
        title: 'Phase Dex',
        region: 'sinnoh',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [
        Pokemon(
          id: 487,
          nameDe: 'Giratina',
          nameEn: 'Giratina',
          hasGenderDifferences: false,
          genderRate: -1,
          captureRate: 3,
          evolutionChainId: 250,
          eggGroups: ['Undiscovered'],
          weight: 750.0,
          speed: 90,
          forms: [
            PokemonForm(
              name: 'altered',
              formType: 'normal',
              minGen: 4,
              imageId: 487,
              types: ['Ghost', 'Dragon'],
              exclusiveRegions: [],
            ),
          ],
        ),
      ];

      final huntProvider = ShinyHuntProvider(databaseService: DatabaseService.instance);
      await huntProvider.initialized;

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-phase-test',
        title: 'Distortion World Hunt',
        pokemonId: 483,
        pokemonName: 'Dialga',
        game: 'Platinum',
        generation: 4.0,
        method: 'Soft Reset',
        baseOdds: 8192.0,
        currentEncounters: 50,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      // Record a phase catch of Giratina (#487)
      await huntProvider.recordPhaseShiny(
        'hunt-phase-test',
        caughtPokemonId: 487,
        caughtPokemonName: 'Giratina',
        syncToDex: true,
        targetDexId: 'dex-tdd-phase-giratina',
        dexProvider: dexProvider,
      );

      expect(dex.caughtIds.contains('487_altered'), isTrue,
          reason: "Phase catch should record '487_altered' for Giratina");
      expect(dex.shinyIds.contains('487_altered'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '487_altered'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '487_altered'), isTrue);

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('12. Living Dex custom box slot with legacy base ID (Giratina) evaluates correctly', () {
      final customBox = CustomBoxState(
        title: 'Legends Box',
        pokemonIds: [
          '487_altered__slot_gira',
        ],
      );

      final dex = UserDex(
        id: 'dex-custom-legacy',
        title: 'Legacy Custom Box Dex',
        region: 'national',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
        caughtIds: ['487'],
        shinyIds: ['487'],
        customBoxes: [customBox],
      );

      // Legacy plain number 487 in caughtIds/shinyIds should evaluate the primary instance as caught & shiny
      expect(DexLogicHelper.isPokemonCaught(dex, '487_altered__slot_gira'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '487_altered__slot_gira'), isTrue);
    });

    test('13. Regional forms must NOT be falsely marked caught when only base form is caught', () {
      final dex = UserDex(
        id: 'dex-regional-isolation',
        title: 'Regional Check Dex',
        region: 'national',
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['26_normal', '194', '58'],
        shinyIds: ['26_normal', '194', '58'],
      );

      // Normal forms are caught
      expect(DexLogicHelper.isPokemonCaught(dex, '26_normal'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '194_normal'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '58_normal'), isTrue);

      // Regional variants MUST NOT be marked caught
      expect(DexLogicHelper.isPokemonCaught(dex, '26_alola'), isFalse,
          reason: 'Alolan Raichu must not be caught when only normal Raichu is caught');
      expect(DexLogicHelper.isPokemonCaught(dex, '194_paldea'), isFalse,
          reason: 'Paldean Wooper must not be caught when only normal Wooper is caught');
      expect(DexLogicHelper.isPokemonCaught(dex, '58_hisui'), isFalse,
          reason: 'Hisuian Growlithe must not be caught when only normal Growlithe is caught');
      expect(DexLogicHelper.isPokemonCaught(dex, '77_galar'), isFalse,
          reason: 'Galarian Ponyta must not be caught');

      // Nor shiny
      expect(DexLogicHelper.isPokemonShiny(dex, '26_alola'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '194_paldea'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '58_hisui'), isFalse);
    });
  });
}


