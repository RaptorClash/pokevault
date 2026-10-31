import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('shiny_lock_caching_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  tearDown(() {
    // Reset any test DB overrides and clear memory cache after each test
    DatabaseService.setAppDatabaseForTesting(null);
    DatabaseService.instance.clearMemoryCache();
  });

  group('DatabaseService Shiny Locks - Adversarial Caching & Edge Cases', () {
    test('getAllShinyLocks returns identical cached instance on multiple sequential calls', () async {
      // Warm up
      final firstCall = await DatabaseService.instance.getAllShinyLocks();
      expect(firstCall, isNotEmpty);

      // Subsequent calls
      final secondCall = await DatabaseService.instance.getAllShinyLocks();
      final thirdCall = await DatabaseService.instance.getAllShinyLocks();

      // Caching verification: Must return the exact same instance in memory
      expect(identical(firstCall, secondCall), isTrue, reason: 'Second call should return cached instance');
      expect(identical(secondCall, thirdCall), isTrue, reason: 'Third call should return cached instance');
    });

    test('getAllShinyLocks handles concurrent in-flight requests gracefully', () async {
      DatabaseService.instance.clearMemoryCache();

      // Dispatch 10 parallel calls
      final futures = List.generate(10, (_) => DatabaseService.instance.getAllShinyLocks());
      final results = await Future.wait(futures);

      expect(results.length, 10);
      for (final result in results) {
        expect(result, isNotEmpty);
      }
      // All subsequent resolved results should match the cached instance
      final cached = await DatabaseService.instance.getAllShinyLocks();
      for (final result in results) {
        expect(result.length, cached.length);
      }
    });

    test('getAllShinyLocks returns empty list and does NOT throw if DB table is empty', () async {
      final emptyDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, v) async {
          await db.execute('CREATE TABLE shiny_locks (pokemon_id INTEGER, form_name TEXT, game_version TEXT, lock_type TEXT, notes TEXT)');
        },
      );

      try {
        DatabaseService.setAppDatabaseForTesting(emptyDb);
        DatabaseService.instance.clearMemoryCache();

        final result1 = await DatabaseService.instance.getAllShinyLocks();
        expect(result1, isEmpty);

        // Multiple calls with empty table: should also return empty cached list
        final result2 = await DatabaseService.instance.getAllShinyLocks();
        expect(result2, isEmpty);
        expect(identical(result1, result2), isTrue);

        // getShinyLocks on empty table returns empty list
        final victini = await DatabaseService.instance.getShinyLocks(494);
        expect(victini, isEmpty);
      } finally {
        DatabaseService.setAppDatabaseForTesting(null);
        DatabaseService.instance.clearMemoryCache();
        await emptyDb.close();
      }
    });

    test('DatabaseService self-heals if appDatabase is closed by re-initializing', () async {
      final mockDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, v) async {
          await db.execute('CREATE TABLE dummy (pokemon_id INTEGER)');
        },
      );
      // Close the DB
      await mockDb.close();

      // Set the closed DB
      DatabaseService.setAppDatabaseForTesting(mockDb);
      DatabaseService.instance.clearMemoryCache();

      // Because _appDatabase!.isOpen is false, appDatabase getter reopens pokedex.sqlite!
      final result = await DatabaseService.instance.getAllShinyLocks();
      expect(result, isNotEmpty);
    });

    test('getAllShinyLocks returns empty list and does NOT throw if DB query throws', () async {
      final noTableDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, v) async {
          // No shiny_locks table created -> db.query('shiny_locks') will throw SqfliteException
          await db.execute('CREATE TABLE other_table (id INTEGER)');
        },
      );

      try {
        DatabaseService.setAppDatabaseForTesting(noTableDb);
        DatabaseService.instance.clearMemoryCache();

        // Must safely catch exception and return []
        final result = await DatabaseService.instance.getAllShinyLocks();
        expect(result, isEmpty);

        // Subsequent call also returns cached []
        final secondResult = await DatabaseService.instance.getAllShinyLocks();
        expect(secondResult, isEmpty);
        expect(identical(result, secondResult), isTrue);

        // getShinyLocks also does not throw and returns []
        final specificLocks = await DatabaseService.instance.getShinyLocks(494);
        expect(specificLocks, isEmpty);
      } finally {
        DatabaseService.setAppDatabaseForTesting(null);
        DatabaseService.instance.clearMemoryCache();
        await noTableDb.close();
      }
    });

    test('getShinyLocks caller mutation does NOT corrupt DatabaseService cache', () async {
      // Ensure real DB is used
      DatabaseService.setAppDatabaseForTesting(null);
      DatabaseService.instance.clearMemoryCache();

      // Retrieve Victini locks
      final victiniLocks = await DatabaseService.instance.getShinyLocks(494);
      expect(victiniLocks, isNotEmpty);
      final initialCount = victiniLocks.length;

      // Caller mutates the returned list
      victiniLocks.clear();
      expect(victiniLocks, isEmpty);

      // Re-query: Cache must be intact!
      final reQueriedLocks = await DatabaseService.instance.getShinyLocks(494);
      expect(reQueriedLocks.length, initialCount);
    });

    test('clearMemoryCache invalidates cached locks and forces re-query', () async {
      // Step 1: Seed initial mock DB with 1 entry
      final mockDb1 = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, v) async {
          await db.execute('CREATE TABLE shiny_locks (pokemon_id INTEGER, pokemon_name TEXT)');
          await db.insert('shiny_locks', {'pokemon_id': 9999, 'pokemon_name': 'MockMon'});
        },
      );

      try {
        DatabaseService.setAppDatabaseForTesting(mockDb1);
        DatabaseService.instance.clearMemoryCache();

        final result1 = await DatabaseService.instance.getAllShinyLocks();
        expect(result1.length, 1);
        expect(result1.first['pokemon_id'], 9999);

        // Step 2: Insert new entry into mock DB without clearing cache
        await mockDb1.insert('shiny_locks', {'pokemon_id': 8888, 'pokemon_name': 'MockMon2'});

        // Still returns cached result (length 1)
        final cachedResult = await DatabaseService.instance.getAllShinyLocks();
        expect(cachedResult.length, 1);

        // Step 3: Clear cache
        DatabaseService.instance.clearMemoryCache();

        // Now it re-queries DB and sees length 2
        final refreshedResult = await DatabaseService.instance.getAllShinyLocks();
        expect(refreshedResult.length, 2);
      } finally {
        DatabaseService.setAppDatabaseForTesting(null);
        DatabaseService.instance.clearMemoryCache();
        await mockDb1.close();
      }
    });

    test('getShinyLocks with non-existent or negative ID returns empty list', () async {
      final negativeLocks = await DatabaseService.instance.getShinyLocks(-1);
      expect(negativeLocks, isEmpty);

      final hugeLocks = await DatabaseService.instance.getShinyLocks(999999);
      expect(hugeLocks, isEmpty);
    });
  });
}
