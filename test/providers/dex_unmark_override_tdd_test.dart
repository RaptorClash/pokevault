import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/providers/dex_provider.dart';
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
    tempDir = Directory.systemTemp.createTempSync('pokevault_unmark_tdd_');
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

  group('TDD: Manual Unmark & Desync Override Tests', () {
    final heatran = Pokemon(
      id: 485,
      nameDe: 'Heatran',
      nameEn: 'Heatran',
      hasGenderDifferences: false,
      genderRate: 1,
      captureRate: 3,
      evolutionChainId: 251,
      eggGroups: ['Undiscovered'],
      weight: 430.0,
      speed: 77,
      forms: [
        PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 4,
          imageId: 485,
          types: ['Fire', 'Steel'],
          exclusiveRegions: [],
        ),
      ],
    );

    test('1. Completed hunt marks both 485 and 485_normal; toggling off caught removes both', () async {
      final dex = UserDex(
        id: 'dex-heatran-1',
        title: 'Sinnoh Dex',
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
      dexProvider.allPokemon = [heatran];

      // Simulate completed hunt marking Heatran as caught & shiny
      await dexProvider.markPokemonCaughtAndShiny(dex.id, '485_normal');

      expect(dex.caughtIds.contains('485_normal'), isTrue);
      expect(dex.caughtIds.contains('485'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '485'), isTrue);

      // Now manual unmark (toggle caught OFF)
      dexProvider.togglePokemon(dex.id, '485_normal', targetState: false);

      // CRITICAL ASSERTION:
      // Both '485_normal' and the raw number '485' MUST be removed!
      expect(dex.caughtIds.contains('485_normal'), isFalse,
          reason: "'485_normal' should be removed from caughtIds");
      expect(dex.caughtIds.contains('485'), isFalse,
          reason: "'485' raw number must be removed so Dex grid does not remain green");
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse,
          reason: "DexLogicHelper must evaluate 485_normal as NOT caught");
      expect(DexLogicHelper.isPokemonCaught(dex, '485'), isFalse,
          reason: "DexLogicHelper must evaluate raw 485 as NOT caught");

      // Verify SQLite state after unmark
      final loadedDexes = await DatabaseService.instance.getAllUserDexes();
      final loadedDex = loadedDexes.firstWhere((d) => d.id == dex.id);
      expect(loadedDex.caughtIds.contains('485_normal'), isFalse);
      expect(loadedDex.caughtIds.contains('485'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(loadedDex, '485_normal'), isFalse);

      dexProvider.dispose();
    });

    test('2. Completed hunt marks both 485 and 485_normal; toggling off shiny removes both from shinyIds', () async {
      final dex = UserDex(
        id: 'dex-heatran-2',
        title: 'Sinnoh Dex',
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
      dexProvider.allPokemon = [heatran];

      await dexProvider.markPokemonCaughtAndShiny(dex.id, '485_normal');

      expect(dex.shinyIds.contains('485_normal'), isTrue);
      expect(dex.shinyIds.contains('485'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '485_normal'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '485'), isTrue);

      // Manual unmark shiny
      dexProvider.toggleShiny(dex.id, '485_normal', targetState: false);

      expect(dex.shinyIds.contains('485_normal'), isFalse);
      expect(dex.shinyIds.contains('485'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '485_normal'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '485'), isFalse);

      // Verify SQLite reload
      final loadedDexes = await DatabaseService.instance.getAllUserDexes();
      final loadedDex = loadedDexes.firstWhere((d) => d.id == dex.id);
      expect(loadedDex.shinyIds.contains('485_normal'), isFalse);
      expect(loadedDex.shinyIds.contains('485'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(loadedDex, '485_normal'), isFalse);

      dexProvider.dispose();
    });

    test('3. After unmarking, user can mark back ON without getting stuck', () async {
      final dex = UserDex(
        id: 'dex-heatran-3',
        title: 'Sinnoh Dex',
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
      dexProvider.allPokemon = [heatran];

      await dexProvider.markPokemonCaughtAndShiny(dex.id, '485_normal');

      // Unmark
      dexProvider.togglePokemon(dex.id, '485_normal');
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse);

      // Toggle back ON
      dexProvider.togglePokemon(dex.id, '485_normal');
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isTrue);
      expect(dex.caughtIds.contains('485_normal'), isTrue);

      // Unmark again
      dexProvider.togglePokemon(dex.id, '485_normal');
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse);

      dexProvider.dispose();
    });

    test('4. Pre-existing database with orphaned raw 485 is cleaned on unmarking 485_normal', () async {
      final dex = UserDex(
        id: 'dex-heatran-4',
        title: 'Sinnoh Dex',
        region: 'sinnoh',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      // Manually simulate pre-existing database with both '485' and '485_normal'
      await DatabaseService.instance.savePokemonStatus(dex.id, '485', isCaught: true, isShiny: true);
      await DatabaseService.instance.savePokemonStatus(dex.id, '485_normal', isCaught: true, isShiny: true);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dex.caughtIds.addAll(['485', '485_normal']);
      dex.shinyIds.addAll(['485', '485_normal']);
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [heatran];

      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isTrue);

      // User unmarks 485_normal via Switch (targetState: false)
      dexProvider.togglePokemon(dex.id, '485_normal', targetState: false);
      dexProvider.toggleShiny(dex.id, '485_normal', targetState: false);

      expect(dex.caughtIds.contains('485'), isFalse);
      expect(dex.caughtIds.contains('485_normal'), isFalse);
      expect(dex.shinyIds.contains('485'), isFalse);
      expect(dex.shinyIds.contains('485_normal'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '485_normal'), isFalse);

      dexProvider.dispose();
    });

    test('5. Shiny Dex: Unmarking caught also unmarks shiny and cleans raw numbers', () async {
      final dex = UserDex(
        id: 'dex-heatran-5',
        title: 'Shiny Sinnoh Dex',
        region: 'sinnoh',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [heatran];

      await dexProvider.markPokemonCaughtAndShiny(dex.id, '485_normal');
      expect(dex.caughtIds.contains('485'), isTrue);
      expect(dex.shinyIds.contains('485'), isTrue);

      // In a shiny dex, togglePokemon off should unmark caught AND shiny and remove 485
      dexProvider.togglePokemon(dex.id, '485_normal', targetState: false);

      expect(dex.caughtIds.contains('485'), isFalse);
      expect(dex.caughtIds.contains('485_normal'), isFalse);
      expect(dex.shinyIds.contains('485'), isFalse);
      expect(dex.shinyIds.contains('485_normal'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '485_normal'), isFalse);

      dexProvider.dispose();
    });

    test('6. Custom Boxes (Living Dex): Toggling base form unmarks all custom box instances', () async {
      final customBox = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['485_normal__inst1', '485_normal__inst2'],
      );
      final dex = UserDex(
        id: 'dex-heatran-6',
        title: 'Living Sinnoh Dex',
        region: 'sinnoh',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [customBox],
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [heatran];

      dex.caughtIds.addAll(['485', '485_normal', '485_normal__inst1', '485_normal__inst2']);

      // Unmarking the base form (not an instance) should unmark everything
      dexProvider.togglePokemon(dex.id, '485_normal', targetState: false);

      expect(dex.caughtIds.contains('485'), isFalse);
      expect(dex.caughtIds.contains('485_normal'), isFalse);
      expect(dex.caughtIds.contains('485_normal__inst1'), isFalse);
      expect(dex.caughtIds.contains('485_normal__inst2'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse);

      dexProvider.dispose();
    });

    test('7. Gender Dex: Unmarking female variant (25_f) does NOT delete male variant (25_m)', () async {
      final pikachu = Pokemon(
        id: 25,
        nameDe: 'Pikachu',
        nameEn: 'Pikachu',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 190,
        evolutionChainId: 10,
        eggGroups: ['Field', 'Fairy'],
        weight: 6.0,
        speed: 90,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 25,
            types: ['Electric'],
            exclusiveRegions: [],
          ),
        ],
      );

      final dex = UserDex(
        id: 'dex-gender-7',
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
      dexProvider.allPokemon = [pikachu];

      // Mark both male and female as caught
      dex.caughtIds.addAll(['25', '25_m', '25_f']);
      await DatabaseService.instance.savePokemonStatus(dex.id, '25', isCaught: true);
      await DatabaseService.instance.savePokemonStatus(dex.id, '25_m', isCaught: true);
      await DatabaseService.instance.savePokemonStatus(dex.id, '25_f', isCaught: true);

      expect(dex.caughtIds.contains('25_m'), isTrue);
      expect(dex.caughtIds.contains('25_f'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_m'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_f'), isTrue);

      // Now user unmarks ONLY female Pikachu
      dexProvider.togglePokemon(dex.id, '25_f', targetState: false);

      // 25_f must be removed
      expect(dex.caughtIds.contains('25_f'), isFalse, reason: 'Female Pikachu should be unmarked');
      expect(DexLogicHelper.isPokemonCaught(dex, '25_f'), isFalse);

      // CRITICAL: 25_m MUST STILL BE CAUGHT!
      expect(dex.caughtIds.contains('25_m'), isTrue, reason: 'Male Pikachu MUST NOT be deleted when unmarking female');
      expect(DexLogicHelper.isPokemonCaught(dex, '25_m'), isTrue, reason: 'Male Pikachu should still be caught');

      // Since male Pikachu is still caught, raw 25 (species caught) should still be evaluated as caught
      expect(DexLogicHelper.isPokemonCaught(dex, '25'), isTrue, reason: 'Species 25 is still caught via 25_m');

      dexProvider.dispose();
    });

    test('8. Legacy custom box instances (e.g. 485__inst1) are cleaned when unmarking 485_normal', () async {
      final customBox = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['485__inst1'], // Legacy ID without _normal
      );
      final dex = UserDex(
        id: 'dex-heatran-8',
        title: 'Legacy Living Dex',
        region: 'sinnoh',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [customBox],
      );
      await DatabaseService.instance.saveUserDex(dex);

      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      dexProvider.userDexes = [dex];
      dexProvider.allPokemon = [heatran];

      dex.caughtIds.addAll(['485', '485__inst1']);
      await DatabaseService.instance.savePokemonStatus(dex.id, '485', isCaught: true);
      await DatabaseService.instance.savePokemonStatus(dex.id, '485__inst1', isCaught: true);

      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isTrue);

      // Unmarking 485_normal must also purge legacy 485__inst1
      dexProvider.togglePokemon(dex.id, '485_normal', targetState: false);

      expect(dex.caughtIds.contains('485__inst1'), isFalse, reason: 'Legacy instance 485__inst1 must be purged');
      expect(dex.caughtIds.contains('485'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '485'), isFalse);

      dexProvider.dispose();
    });

    test('9. Regular Dex: Unmarking caught also clears shiny and alpha status', () async {
      final dex = UserDex(
        id: 'dex-heatran-9',
        title: 'Standard Dex',
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
      dexProvider.allPokemon = [heatran];

      // Mark Heatran as both caught and shiny
      await dexProvider.markPokemonCaughtAndShiny(dex.id, '485_normal');
      expect(dex.caughtIds.contains('485_normal'), isTrue);
      expect(dex.shinyIds.contains('485_normal'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isTrue);
      expect(DexLogicHelper.isPokemonShiny(dex, '485_normal'), isTrue);

      // User unmarks "Gefangen Status" (isCaught: false)
      dexProvider.togglePokemon(dex.id, '485_normal', targetState: false);

      // An uncaught Pokemon cannot remain shiny!
      expect(DexLogicHelper.isPokemonCaught(dex, '485_normal'), isFalse);
      expect(DexLogicHelper.isPokemonShiny(dex, '485_normal'), isFalse,
          reason: 'Unmarking caught must also clear shiny status');
      expect(dex.shinyIds.contains('485_normal'), isFalse);
      expect(dex.shinyIds.contains('485'), isFalse);

      dexProvider.dispose();
    });

    test('10. Non-Gender Dex: Unmarking female 3_f does not remove rawBaseNumber 3 if 3_normal is caught', () async {
      final bisaflor = Pokemon(
        id: 3,
        nameDe: 'Bisaflor',
        nameEn: 'Venusaur',
        hasGenderDifferences: true,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['Monster', 'Grass'],
        weight: 100.0,
        speed: 80,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 3,
            types: ['Grass', 'Poison'],
            exclusiveRegions: [],
          ),
        ],
      );

      final dex = UserDex(
        id: 'dex-bisaflor-10',
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
      dexProvider.allPokemon = [bisaflor];

      // Male Venusaur (3_normal) is caught
      dexProvider.togglePokemon(dex.id, '3_normal', targetState: true);
      expect(dex.caughtIds.contains('3_normal'), isTrue);
      expect(dex.caughtIds.contains('3'), isTrue);

      // Now female (3_f) was viewed and caught
      dexProvider.togglePokemon(dex.id, '3_f', targetState: true);
      expect(dex.caughtIds.contains('3_f'), isTrue);
      expect(dex.caughtIds.contains('3'), isTrue);

      // Now female (3_f) is un-toggled (isCaught: false)
      dexProvider.togglePokemon(dex.id, '3_f', targetState: false);

      expect(dex.caughtIds.contains('3_f'), isFalse);
      // Because 3_normal is still caught, rawBaseNumber '3' MUST still remain in caughtIds!
      expect(dex.caughtIds.contains('3_normal'), isTrue);
      expect(dex.caughtIds.contains('3'), isTrue,
          reason: '3 must remain caught because 3_normal is still caught');
      expect(DexLogicHelper.isPokemonCaught(dex, '3_normal'), isTrue);

      dexProvider.dispose();
    });
  });
}
