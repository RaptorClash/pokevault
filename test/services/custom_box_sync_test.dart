import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/database_path_helper.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath1;
  late String dbPath2;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('pokevault_custom_box_sync_test_');
    dbPath1 = p.join(tempDir.path, 'user_data_1.sqlite');
    dbPath2 = p.join(tempDir.path, 'user_data_2.sqlite');
    DatabasePathHelper.overrideCurrentDirectory = tempDir;
    DatabasePathHelper.overrideIsDesktop = true;
  });

  tearDown(() {
    DatabaseService.setUserDatabaseForTesting(null);
    DatabasePathHelper.resetOverrides();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Custom Box & Dex Cloud Sync Tests', () {
    test('Export and merge preserves customized box dimensions, pokemon IDs, and settings', () async {
      // 1. Setup DB 1
      final db1 = await databaseFactory.openDatabase(
        dbPath1,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: DatabaseService.createUserDataTables,
        ),
      );
      DatabaseService.setUserDatabaseForTesting(db1);

      // Create a customized dex with non-default dimensions (3 columns x 4 rows = 12 capacity)
      final customBox = CustomBoxState(
        title: 'Team Alpha',
        pokemonIds: ['25_normal', '133_normal'],
        regionKey: 'custom',
        columns: 3,
        rows: 4,
        autoShift: false,
        strictLimits: true,
      );

      final originalDex = UserDex(
        id: 'custom_dex_42',
        title: 'Mein Custom Dex',
        region: 'custom_empty',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [customBox],
      );

      await DatabaseService.instance.saveUserDex(originalDex);

      // 2. Export Cloud Sync Data
      final cloudData = await DatabaseService.instance.exportCloudSyncData();
      expect(cloudData['format_version'], equals(2));
      final exportedDexes = cloudData['user_dexes'] as List<dynamic>;
      expect(exportedDexes.any((d) => d['id'] == 'custom_dex_42'), isTrue);

      // 3. Setup fresh DB 2 (simulating device 2)
      final db2 = await databaseFactory.openDatabase(
        dbPath2,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: DatabaseService.createUserDataTables,
        ),
      );
      DatabaseService.setUserDatabaseForTesting(db2);

      // Merge cloud data into DB 2
      await DatabaseService.instance.mergeCloudSyncData(cloudData);

      // 4. Verify restored dex on DB 2
      final restoredDexes = await DatabaseService.instance.getAllUserDexes();
      final restoredDex = restoredDexes.firstWhere((d) => d.id == 'custom_dex_42');

      expect(restoredDex.title, equals('Mein Custom Dex'));
      expect(restoredDex.customBoxes.length, equals(1));

      final restoredBox = restoredDex.customBoxes.first;
      expect(restoredBox.title, equals('Team Alpha'));
      expect(restoredBox.columns, equals(3));
      expect(restoredBox.rows, equals(4));
      expect(restoredBox.capacity, equals(12));
      expect(restoredBox.autoShift, isFalse);
      expect(restoredBox.pokemonIds, equals(['25_normal', '133_normal']));

      await db1.close();
      await db2.close();
    });

    test('DexProvider.saveUserDexAndSync updates in-memory list, saves to DB, and notifies listeners', () async {
      final db = await databaseFactory.openDatabase(
        dbPath1,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: DatabaseService.createUserDataTables,
        ),
      );
      DatabaseService.setUserDatabaseForTesting(db);

      final dex = UserDex(
        id: 'dex_sync_1',
        title: 'Sync Test Dex',
        region: 'hoenn',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: [], columns: 6, rows: 5),
        ],
      );

      final provider = DexProvider(databaseService: DatabaseService.instance);
      await provider.initialized;

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      // Modify box columns to 4 and rows to 6
      dex.customBoxes.first.columns = 4;
      dex.customBoxes.first.rows = 6;

      await provider.saveUserDexAndSync(dex);

      expect(notified, isTrue);

      // Verify DB persistence
      final loadedDexes = await DatabaseService.instance.getAllUserDexes();
      final loaded = loadedDexes.firstWhere((d) => d.id == 'dex_sync_1');
      expect(loaded.customBoxes.first.columns, equals(4));
      expect(loaded.customBoxes.first.rows, equals(6));

      provider.dispose();
      await db.close();
    });

    test('DexProvider.saveUserDexAndSync adds new dex to userDexes if not already present', () async {
      final db = await databaseFactory.openDatabase(
        dbPath1,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: DatabaseService.createUserDataTables,
        ),
      );
      DatabaseService.setUserDatabaseForTesting(db);

      final newDex = UserDex(
        id: 'brand_new_dex_99',
        title: 'Brand New Dex',
        region: 'kanto_regional',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: [], columns: 4, rows: 5),
        ],
      );

      final provider = DexProvider(databaseService: DatabaseService.instance);
      await provider.initialized;

      expect(provider.userDexes.any((d) => d.id == 'brand_new_dex_99'), isFalse);

      await provider.saveUserDexAndSync(newDex);

      expect(provider.userDexes.any((d) => d.id == 'brand_new_dex_99'), isTrue);
      expect(provider.userDexes.firstWhere((d) => d.id == 'brand_new_dex_99').title, equals('Brand New Dex'));

      provider.dispose();
      await db.close();
    });
  });
}
