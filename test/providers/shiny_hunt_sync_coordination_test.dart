import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/database_path_helper.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('shiny_hunt_sync_test_');
    dbPath = p.join(tempDir.path, 'user_data.sqlite');
    DatabasePathHelper.overrideCurrentDirectory = tempDir;
    DatabasePathHelper.overrideIsDesktop = true;

    db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 10,
        onCreate: DatabaseService.createUserDataTables,
      ),
    );
    DatabaseService.setUserDatabaseForTesting(db);

    final dbDir = Directory(p.join(tempDir.path, 'database'));
    if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
    final appDb = await databaseFactory.openDatabase(
      p.join(dbDir.path, 'pokedex.sqlite'),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, v) async {
          await d.execute('CREATE TABLE IF NOT EXISTS pokemon (id INTEGER PRIMARY KEY, name_de TEXT, name_en TEXT)');
          await d.execute('CREATE TABLE IF NOT EXISTS forms (id INTEGER PRIMARY KEY, pokemon_id INTEGER, name TEXT, form_type TEXT)');
          await d.execute('CREATE TABLE IF NOT EXISTS dex_orders (dex_name TEXT, pokemon_id INTEGER, order_index INTEGER)');
          await d.execute('CREATE TABLE IF NOT EXISTS special_dexes (dex_name TEXT, pokemon_id INTEGER)');
          await d.execute('CREATE TABLE IF NOT EXISTS gen1_base_stats (id INTEGER PRIMARY KEY)');
          await d.execute('CREATE TABLE IF NOT EXISTS ball_urls (name TEXT PRIMARY KEY, url TEXT)');
          await d.execute('CREATE TABLE IF NOT EXISTS ribbons (id TEXT PRIMARY KEY, name TEXT, icon_url TEXT)');
        },
      ),
    );
    DatabaseService.setAppDatabaseForTesting(appDb);
  });

  tearDown(() async {
    await db.close();
    DatabaseService.setUserDatabaseForTesting(null);
    DatabaseService.setAppDatabaseForTesting(null);
    DatabasePathHelper.resetOverrides();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('ShinyHuntProvider & DexProvider Sync Coordination Tests', () {
    test('ShinyHuntProvider flushes pending writes to SQLite before DexProvider cloud upload', () async {
      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      final huntProvider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
        dexProvider: dexProvider,
      );
      await huntProvider.initialized;

      final now = DateTime.now();
      final testHunt = ShinyHunt(
        id: 'hunt_coord_1',
        title: 'Glumanda Hunt',
        pokemonId: 4,
        pokemonName: 'Glumanda',
        game: 'FireRed',
        generation: 3,
        method: 'soft_reset',
        baseOdds: 8192,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(testHunt);

      // Tap to increment encounters
      huntProvider.increment('hunt_coord_1');
      huntProvider.increment('hunt_coord_1');
      expect(huntProvider.getHuntById('hunt_coord_1')?.currentEncounters, equals(2));

      // Execute registered beforeUploadHooks (verifying hook actually flushes writes)
      await dexProvider.runBeforeUploadHooksForTesting();

      // Check SQLite directly
      final rows = await db.query('shiny_hunts', where: 'id = ?', whereArgs: ['hunt_coord_1']);
      expect(rows, isNotEmpty);
      expect(rows.first['current_encounters'], equals(2));

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('DexProvider.mergeCloudData triggers ShinyHuntProvider.loadHunts automatically', () async {
      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      final huntProvider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
        dexProvider: dexProvider,
      );
      await huntProvider.initialized;
      expect(huntProvider.hunts, isEmpty);

      // Simulate incoming cloud sync data with a shiny hunt from another device
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      final remoteCloudData = <String, dynamic>{
        'format_version': 2,
        'user_dexes': [],
        'folders': [],
        'folder_structure': [],
        'user_pokemon': [],
        'shiny_hunts': [
          {
            'id': 'remote_hunt_99',
            'title': 'Rayquaza Hunt',
            'pokemon_id': 384,
            'pokemon_name': 'Rayquaza',
            'game': 'Emerald',
            'generation': 3.0,
            'method': 'soft_reset',
            'base_odds': 8192.0,
            'current_encounters': 500,
            'status': 'active',
            'phase': 1,
            'created_at': nowMs,
            'updated_at': nowMs,
            'deleted_at': 0,
          }
        ],
      };

      // When DexProvider merges cloud data, it must invoke registered cloudDataMergedHooks
      await dexProvider.mergeCloudData(remoteCloudData);

      // ShinyHuntProvider should have reloaded its hunts automatically
      expect(huntProvider.hunts.any((h) => h.id == 'remote_hunt_99'), isTrue);
      final hunt = huntProvider.getHuntById('remote_hunt_99');
      expect(hunt?.pokemonName, equals('Rayquaza'));
      expect(hunt?.currentEncounters, equals(500));

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('ShinyHuntProvider.loadHunts automatically flushes pending dirty writes to prevent counter rollback', () async {
      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      final huntProvider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
        dexProvider: dexProvider,
      );
      await huntProvider.initialized;

      final now = DateTime.now();
      final testHunt = ShinyHunt(
        id: 'hunt_rollback_test',
        title: 'Mewtu Hunt',
        pokemonId: 150,
        pokemonName: 'Mewtu',
        game: 'FireRed',
        generation: 3,
        method: 'soft_reset',
        baseOdds: 8192,
        currentEncounters: 10,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(testHunt);

      // Increment counters in memory (dirty, unwritten to SQLite yet)
      huntProvider.increment('hunt_rollback_test');
      huntProvider.increment('hunt_rollback_test');
      huntProvider.increment('hunt_rollback_test');
      expect(huntProvider.getHuntById('hunt_rollback_test')?.currentEncounters, equals(13));

      // Trigger loadHunts directly (e.g. cloud refresh or lifecycle event)
      await huntProvider.loadHunts();

      // Verified: encounters MUST NOT be reset to 10
      expect(huntProvider.getHuntById('hunt_rollback_test')?.currentEncounters, equals(13));

      // Check SQLite has persisted the 13 encounters
      final rows = await db.query('shiny_hunts', where: 'id = ?', whereArgs: ['hunt_rollback_test']);
      expect(rows.first['current_encounters'], equals(13));

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('DexProvider.mergeCloudData triggers beforeMergeHooks and flushes dirty shiny hunt state before merging', () async {
      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      final huntProvider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
        dexProvider: dexProvider,
      );
      await huntProvider.initialized;

      final baseTime = DateTime.now().subtract(const Duration(minutes: 5));
      final testHunt = ShinyHunt(
        id: 'hunt_merge_dirty_test',
        title: 'Groudon Hunt',
        pokemonId: 383,
        pokemonName: 'Groudon',
        game: 'Ruby',
        generation: 3,
        method: 'soft_reset',
        baseOdds: 8192,
        currentEncounters: 100,
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      await huntProvider.createHunt(testHunt);

      // User increments locally just before merge (in memory dirty state)
      huntProvider.increment('hunt_merge_dirty_test');
      expect(huntProvider.getHuntById('hunt_merge_dirty_test')?.currentEncounters, equals(101));

      // Cloud data comes in with a new hunt
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      final remoteCloudData = <String, dynamic>{
        'format_version': 2,
        'user_dexes': [],
        'folders': [],
        'folder_structure': [],
        'user_pokemon': [],
        'shiny_hunts': [
          {
            'id': 'remote_hunt_kyogre',
            'title': 'Kyogre Hunt',
            'pokemon_id': 382,
            'pokemon_name': 'Kyogre',
            'game': 'Sapphire',
            'generation': 3.0,
            'method': 'soft_reset',
            'base_odds': 8192.0,
            'current_encounters': 250,
            'status': 'active',
            'phase': 1,
            'created_at': nowMs,
            'updated_at': nowMs,
            'deleted_at': 0,
          }
        ],
      };

      await dexProvider.mergeCloudData(remoteCloudData);

      // Local dirty hunt is preserved at 101 encounters
      expect(huntProvider.getHuntById('hunt_merge_dirty_test')?.currentEncounters, equals(101));
      // Remote hunt is also merged
      expect(huntProvider.getHuntById('remote_hunt_kyogre')?.currentEncounters, equals(250));

      huntProvider.dispose();
      dexProvider.dispose();
    });

    test('attachDexProvider and detachDexProvider manage hooks cleanly', () async {
      final dexProvider = DexProvider(databaseService: DatabaseService.instance);
      await dexProvider.initialized;
      final huntProvider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await huntProvider.initialized;
      await Future.delayed(const Duration(milliseconds: 50));

      huntProvider.attachDexProvider(dexProvider);
      // Detaching removes hooks without error
      huntProvider.detachDexProvider();
      huntProvider.dispose();
      dexProvider.dispose();
    });
  });
}
