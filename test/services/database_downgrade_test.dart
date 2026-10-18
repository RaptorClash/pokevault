import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/services/database_path_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pokevault_downgrade_test_');
    dbPath = p.join(tempDir.path, 'test_user_data.sqlite');
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

  group('Database Downgrade & Idempotent Upgrade Tests', () {
    test('onDowngrade allows opening DB with lower version without crashing or destroying data', () async {
      // 1. Create a DB at higher version 11 with a future column
      final dbV11 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 11,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE shiny_hunts (
                id TEXT PRIMARY KEY,
                title TEXT,
                pokemon_id INTEGER,
                pokemon_name TEXT,
                pokemon_form_id INTEGER,
                target_dex_id TEXT,
                target_unique_id TEXT,
                game TEXT,
                generation REAL,
                method TEXT,
                has_shiny_charm INTEGER DEFAULT 0,
                base_odds REAL,
                spawns_per_encounter INTEGER DEFAULT 1,
                current_encounters INTEGER DEFAULT 0,
                prior_phase_encounters INTEGER DEFAULT 0,
                increment_step INTEGER DEFAULT 1,
                status TEXT DEFAULT 'active',
                phase INTEGER DEFAULT 1,
                phase_history TEXT DEFAULT '[]',
                total_time_seconds INTEGER DEFAULT 0,
                ball_used TEXT,
                notes TEXT,
                hunting_type TEXT,
                future_column TEXT DEFAULT 'v11_value',
                created_at INTEGER,
                updated_at INTEGER,
                completed_at INTEGER,
                deleted_at INTEGER DEFAULT 0
              )
            ''');
            await db.insert('shiny_hunts', {
              'id': 'hunt_test_1',
              'title': 'Test Hunt',
              'pokemon_id': 25,
              'future_column': 'preserved_data',
              'updated_at': 1000,
            });
          },
        ),
      );
      await dbV11.close();

      // 2. Open DB with version 10 (simulating downgrade to older app version)
      final dbV10 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 10,
          onDowngrade: DatabaseService.downgradeUserDataTables,
        ),
      );

      final rows = await dbV10.query('shiny_hunts', where: 'id = ?', whereArgs: ['hunt_test_1']);
      expect(rows.first['future_column'], equals('preserved_data'));
      await dbV10.close();

      // 3. Re-open DB with version 11 (simulating upgrade back to newer version)
      // Must not throw "duplicate column name" error
      final dbReUpgraded = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 11,
          onUpgrade: (db, oldVersion, newVersion) async {
            // Idempotent column addition
            await DatabaseService.addColumnIfNotExists(db, 'shiny_hunts', 'future_column', 'TEXT');
          },
        ),
      );

      final reRows = await dbReUpgraded.query('shiny_hunts', where: 'id = ?', whereArgs: ['hunt_test_1']);
      expect(reRows.first['future_column'], equals('preserved_data'));
      await dbReUpgraded.close();
    });

    test('Non-destructive writes preserve future columns in existing rows', () async {
      // Create user_data tables + extra future column on user_dexes and shiny_hunts
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: (db, version) async {
            await DatabaseService.createUserDataTables(db, version);
            await db.execute('ALTER TABLE user_dexes ADD COLUMN future_setting TEXT DEFAULT "keep_me"');
            await db.execute('ALTER TABLE shiny_hunts ADD COLUMN future_mode TEXT DEFAULT "auto_catch"');
            await db.execute('ALTER TABLE user_pokemon ADD COLUMN future_badge TEXT DEFAULT "shiny_gold"');
          },
        ),
      );
      DatabaseService.setUserDatabaseForTesting(db);

      // Insert initial row with future column populated
      await db.insert('user_dexes', {
        'id': 'dex_future',
        'title': 'Original Title',
        'future_setting': 'critical_setting_v2',
        'updated_at': 100,
      });

      await db.insert('shiny_hunts', {
        'id': 'hunt_future',
        'title': 'Original Hunt',
        'pokemon_id': 1,
        'future_mode': 'ultra_method',
        'updated_at': 100,
      });

      await db.insert('user_pokemon', {
        'dex_id': 'dex_future',
        'unique_id': 'p1',
        'is_caught': 1,
        'future_badge': 'special_badge_data',
        'updated_at': 100,
      });

      // Update rows via DatabaseService (which doesn't know about future columns)
      final dex = UserDex(
        id: 'dex_future',
        title: 'Updated Title',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await DatabaseService.instance.saveUserDex(dex);

      final hunt = ShinyHunt(
        id: 'hunt_future',
        title: 'Updated Hunt',
        pokemonId: 1,
        pokemonName: 'Bulbasaur',
        game: 'Red',
        generation: 1,
        method: 'Random Encounter',
        baseOdds: 8192.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseService.instance.saveShinyHunt(hunt);

      await DatabaseService.instance.savePokemonStatus(
        'dex_future',
        'p1',
        isShiny: true,
      );

      // Verify that the future columns are still intact!
      final dexRow = (await db.query('user_dexes', where: 'id = ?', whereArgs: ['dex_future'])).first;
      expect(dexRow['title'], equals('Updated Title'));
      expect(dexRow['future_setting'], equals('critical_setting_v2'), reason: 'Future column must be preserved');

      final huntRow = (await db.query('shiny_hunts', where: 'id = ?', whereArgs: ['hunt_future'])).first;
      expect(huntRow['title'], equals('Updated Hunt'));
      expect(huntRow['future_mode'], equals('ultra_method'), reason: 'Future column must be preserved');

      final pokeRow = (await db.query('user_pokemon', where: 'dex_id = ? AND unique_id = ?', whereArgs: ['dex_future', 'p1'])).first;
      expect(pokeRow['is_shiny'], equals(1));
      expect(pokeRow['future_badge'], equals('special_badge_data'), reason: 'Future column must be preserved');
    });
  });
}
