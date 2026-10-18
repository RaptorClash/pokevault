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
}
