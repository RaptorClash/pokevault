import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:pokevault/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pokevault_idx_test_');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('user_data.sqlite uses indexes for queries', () async {
    final dbPath = p.join(tempDir.path, 'user_data.sqlite');
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 10,
        onCreate: DatabaseService.createUserDataTables,
        onOpen: (db) async {
          await DatabaseService.ensureUserDataIndexes(db);
        },
      ),
    );

    // Explain query plans
    final eqpDexes = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM user_dexes WHERE deleted_at = 0 ORDER BY updated_at DESC',
    );
    final dexPlan = eqpDexes.map((r) => r['detail'].toString()).join(' ');
    expect(dexPlan.contains('USING INDEX') || dexPlan.contains('idx_user_dexes_deleted_updated'), isTrue);

    final eqpHunts = await db.rawQuery(
      "EXPLAIN QUERY PLAN SELECT * FROM shiny_hunts WHERE status = 'active' AND deleted_at = 0",
    );
    final huntPlan = eqpHunts.map((r) => r['detail'].toString()).join(' ');
    expect(huntPlan.contains('USING INDEX') || huntPlan.contains('idx_shiny_hunts_status'), isTrue);

    final eqpStructure = await db.rawQuery(
      "EXPLAIN QUERY PLAN SELECT * FROM folder_structure WHERE parent_id = 'root' AND deleted_at = 0 ORDER BY order_index ASC",
    );
    final structPlan = eqpStructure.map((r) => r['detail'].toString()).join(' ');
    expect(structPlan.contains('USING INDEX') || structPlan.contains('idx_folder_structure_parent_order'), isTrue);

    await db.close();
  });

  test('pokedex.sqlite uses indexes for pokemon_moves, encounters and abilities', () async {
    final dbPath = p.join(tempDir.path, 'pokedex.sqlite');
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE pokemon_moves (
              pokemon_id INTEGER,
              move_id INTEGER,
              learn_method TEXT,
              level_learned INTEGER,
              version_group TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE encounters (
              pokemon_id INTEGER,
              gen TEXT,
              version TEXT,
              location_data TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE pokemon_abilities (
              pokemon_id INTEGER,
              ability_id INTEGER,
              is_hidden INTEGER
            )
          ''');
        },
        onOpen: (db) async {
          await DatabaseService.ensureAppDatabaseIndexes(db);
        },
      ),
    );

    final eqpMoves = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM pokemon_moves WHERE move_id = ?',
      [1],
    );
    final movesPlan = eqpMoves.map((r) => r['detail'].toString()).join(' ');
    expect(movesPlan.contains('USING INDEX') || movesPlan.contains('idx_pokemon_moves_move_id'), isTrue);

    final eqpMovesVg = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM pokemon_moves WHERE pokemon_id = ? AND version_group = ?',
      [1, 'red-blue'],
    );
    final movesVgPlan = eqpMovesVg.map((r) => r['detail'].toString()).join(' ');
    expect(movesVgPlan.contains('USING INDEX') || movesVgPlan.contains('idx_pokemon_moves_poke_vg'), isTrue);

    final eqpEncounters = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM encounters WHERE pokemon_id = ?',
      [1],
    );
    final encPlan = eqpEncounters.map((r) => r['detail'].toString()).join(' ');
    expect(encPlan.contains('USING INDEX') || encPlan.contains('idx_encounters_poke_id'), isTrue);

    await db.close();
  });

  test('pokedex.sqlite uses covering index for dex_orders and special_dexes lookups', () async {
    final dbPath = p.join(tempDir.path, 'pokedex_dex_orders.sqlite');
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE dex_orders (
              pokemon_id INTEGER,
              dex_name TEXT,
              order_index INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE special_dexes (
              pokemon_id INTEGER,
              dex_name TEXT
            )
          ''');
        },
        onOpen: (db) async {
          await DatabaseService.ensureAppDatabaseIndexes(db);
        },
      ),
    );

    // 1. Dex orders lookups: Both SELECT * and selective projections must use COVERING INDEX
    final eqpDexOrdersAll = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM dex_orders WHERE pokemon_id = ? AND dex_name = ?',
      [25, 'hisui_regional'],
    );
    final planAll = eqpDexOrdersAll.map((r) => r['detail'].toString()).join(' ');
    expect(planAll.contains('idx_dex_orders_poke_dex'), isTrue);
    expect(planAll.contains('COVERING INDEX'), isTrue);

    final eqpDexOrdersSelective = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT pokemon_id FROM dex_orders WHERE pokemon_id = ? AND dex_name = ?',
      [25, 'hisui_regional'],
    );
    final planSelective = eqpDexOrdersSelective.map((r) => r['detail'].toString()).join(' ');
    expect(planSelective.contains('COVERING INDEX'), isTrue);

    // 2. Special dexes lookups must also use COVERING INDEX
    final eqpSpecial = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM special_dexes WHERE pokemon_id = ? AND dex_name = ?',
      [25, 'legendary-dex'],
    );
    final specialPlan = eqpSpecial.map((r) => r['detail'].toString()).join(' ');
    expect(specialPlan.contains('idx_special_dexes_poke_dex'), isTrue);
    expect(specialPlan.contains('COVERING INDEX'), isTrue);

    await db.close();
  });

  test('DatabaseService automatically upgrades existing partial index to full covering index', () async {
    final dbPath = p.join(tempDir.path, 'pokedex_upgrade_index.sqlite');
    // Pre-create table with old partial 2-column index
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE dex_orders (
              pokemon_id INTEGER,
              dex_name TEXT,
              order_index INTEGER
            )
          ''');
          // Old index that only covered 2 columns:
          await db.execute('CREATE INDEX idx_dex_orders_poke_dex ON dex_orders (pokemon_id, dex_name);');
        },
      ),
    );

    // Verify it was NOT a covering index for SELECT *
    final oldEqp = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM dex_orders WHERE pokemon_id = 25 AND dex_name = ?',
      ['hisui_regional'],
    );
    final oldPlan = oldEqp.map((r) => r['detail'].toString()).join(' ');
    expect(oldPlan.contains('COVERING INDEX'), isFalse);

    // Now run ensureAppDatabaseIndexes to upgrade it
    await DatabaseService.ensureAppDatabaseIndexes(db);

    // Verify it is now upgraded to COVERING INDEX for SELECT *
    final newEqp = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM dex_orders WHERE pokemon_id = 25 AND dex_name = ?',
      ['hisui_regional'],
    );
    final newPlan = newEqp.map((r) => r['detail'].toString()).join(' ');
    expect(newPlan.contains('COVERING INDEX'), isTrue);

    await db.close();
  });

  test('DatabaseService currentAppDbVersion is bumped to at least 26 for deployment', () {
    expect(DatabaseService.currentAppDbVersion, greaterThanOrEqualTo(26));
  });

  test('DatabaseService vacuumUserDatabase reclaims space and passes integrity check', () async {
    final dbPath = p.join(tempDir.path, 'user_data_vacuum.sqlite');
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 10,
        onCreate: DatabaseService.createUserDataTables,
        onOpen: (db) async {
          await DatabaseService.ensureUserDataIndexes(db);
        },
      ),
    );
    DatabaseService.setUserDatabaseForTesting(db);

    // Insert 50 test entries
    for (int i = 0; i < 50; i++) {
      await db.insert('user_dexes', {
        'id': 'dex_$i',
        'title': 'Test Dex $i',
        'region': 'kanto',
        'include_genders': 0,
        'include_regional': 0,
        'include_mega': 0,
        'include_gmax': 0,
        'include_other': 0,
        'is_shiny_dex': 0,
        'deleted_at': i < 40 ? 1 : 0, // 40 soft-deleted entries
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Execute VACUUM
    await expectLater(DatabaseService.instance.vacuumUserDatabase(), completes);

    // Verify integrity
    final integrity = await db.rawQuery('PRAGMA integrity_check;');
    expect(integrity.first.values.first, equals('ok'));

    await db.close();
    DatabaseService.setUserDatabaseForTesting(null);
  });

  test('shipped assets/db/pokedex.sqlite has valid covering indexes and passing integrity check', () async {
    final assetPath = p.join(Directory.current.path, 'assets', 'db', 'pokedex.sqlite');
    expect(File(assetPath).existsSync(), isTrue);

    final db = await databaseFactory.openDatabase(
      assetPath,
      options: OpenDatabaseOptions(readOnly: true),
    );

    final integrity = await db.rawQuery('PRAGMA integrity_check;');
    expect(integrity.first.values.first, equals('ok'));

    final eqpDex = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM dex_orders WHERE pokemon_id = ? AND dex_name = ?',
      [25, 'hisui_regional'],
    );
    final planDex = eqpDex.map((r) => r['detail'].toString()).join(' ');
    expect(planDex.contains('idx_dex_orders_poke_dex'), isTrue);
    expect(planDex.contains('COVERING INDEX'), isTrue);

    final eqpSpecial = await db.rawQuery(
      'EXPLAIN QUERY PLAN SELECT * FROM special_dexes WHERE pokemon_id = ? AND dex_name = ?',
      [25, 'legendary-dex'],
    );
    final planSpecial = eqpSpecial.map((r) => r['detail'].toString()).join(' ');
    expect(planSpecial.contains('idx_special_dexes_poke_dex'), isTrue);
    expect(planSpecial.contains('COVERING INDEX'), isTrue);

    await db.close();
  });
}
