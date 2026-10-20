import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../utils/notification_helper.dart';
import '../l10n/app_translations.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/special_dex_models.dart';
import '../models/ribbon.dart';
import '../models/shiny_hunt.dart';
import 'database_path_helper.dart';

/// Central database service providing access to the application's SQLite databases.
///
/// Implements a dual-database architecture:
/// 1. **Reference Database** (`pokedex.sqlite` accessed via [appDatabase]):
///    A read-only database extracted from assets containing all static game data,
///    including Pokémon definitions, forms, moves, abilities, ribbons, marks,
///    encounters, catch rates, and legal Pokéballs.
/// 2. **User Database** (`user_data.sqlite` accessed via [userDatabase]):
///    A read-write database persisting user-created Dexes, custom folder hierarchies,
///    caught statuses, shiny tracking, and active Shiny Hunts. Features idempotent
///    schema migrations and downgrade tolerance.
class DatabaseService {
  /// The singleton instance of [DatabaseService].
  static final DatabaseService instance = DatabaseService._init();
  static Database? _appDatabase;
  static Database? _userDatabase;
  static Future<void>? _migrationFuture;

  static Future<void> _ensureMigration() {
    _migrationFuture ??= DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();
    return _migrationFuture!;
  }

  @visibleForTesting
  static void resetMigrationForTesting() {
    _migrationFuture = null;
  }

  DatabaseService._init();

  /// Returns the read-only application database (`pokedex.sqlite`).
  ///
  /// Automatically checks for bundle asset updates against the stored version
  /// and applies indexes upon opening.
  Future<Database> get appDatabase async {
    if (_appDatabase != null && _appDatabase!.isOpen) return _appDatabase!;
    _appDatabase = await _initAppDB('pokedex.sqlite');
    return _appDatabase!;
  }

  @visibleForTesting
  static void setAppDatabaseForTesting(Database? db) {
    _appDatabase = db;
  }

  @visibleForTesting
  static void setUserDatabaseForTesting(Database? db) {
    _userDatabase = db;
  }

  @visibleForTesting
  static const int currentAppDbVersion = 26;
  static const int _currentAppDbVersion = currentAppDbVersion;

  Future<Database> _initAppDB(String fileName) async {
    await _ensureMigration();

    String path = fileName;
    DatabaseFactory factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;

    if (!kIsWeb) {
      path = await DatabasePathHelper.resolveDatabasePath(fileName);
    }

    final prefs = await SharedPreferences.getInstance();
    final int storedDbVersion = prefs.getInt('app_db_version') ?? 0;
    bool dbExists = await factory.databaseExists(path);

    if (!dbExists || storedDbVersion < _currentAppDbVersion) {
      try {
        if (_appDatabase != null && _appDatabase!.isOpen) {
          await _appDatabase!.close();
          _appDatabase = null;
        }
        if (!kIsWeb) {
          for (final ext in ['-wal', '-shm']) {
            final aux = File('$path$ext');
            if (aux.existsSync()) {
              try {
                aux.deleteSync();
              } catch (_) {}
            }
          }
        }
        ByteData data = await rootBundle.load('assets/db/$fileName');
        Uint8List bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await factory.writeDatabaseBytes(path, bytes);
        await prefs.setInt('app_db_version', _currentAppDbVersion);
        debugPrint(
          "App-Datenbank erfolgreich auf Version $_currentAppDbVersion aktualisiert.",
        );
      } catch (e) {
        NotificationHelper.showError('${Translator.get('error_db_init')} $e');
      }
    }

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onDowngrade: (db, oldVersion, newVersion) async {},
        onOpen: (db) async {
          await db.execute('PRAGMA busy_timeout = 5000;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA temp_store = MEMORY;');
          await ensureAppDatabaseIndexes(db);
        },
      ),
    );
  }

  /// Returns the read-write user database (`user_data.sqlite`).
  ///
  /// Opens with WAL journal mode, enables foreign keys, performs idempotent
  /// schema upgrades, and verifies secondary indexes.
  Future<Database> get userDatabase async {
    if (_userDatabase != null && _userDatabase!.isOpen) return _userDatabase!;
    _userDatabase = await _initUserDB('user_data.sqlite');
    return _userDatabase!;
  }

  /// Runs VACUUM on the user database to reclaim storage space from deleted entries.
  /// Also checkpoints and truncates the WAL file on non-web platforms.
  Future<void> vacuumUserDatabase() async {
    final db = await userDatabase;
    await db.execute('VACUUM;');
    if (!kIsWeb) {
      try {
        await db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (_) {}
    }
  }

  Future<Database> _initUserDB(String fileName) async {
    await _ensureMigration();

    String path = fileName;
    DatabaseFactory factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;

    if (!kIsWeb) {
      path = await DatabasePathHelper.resolveDatabasePath(fileName);
    }

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 10,
        onCreate: createUserDataTables,
        onUpgrade: upgradeUserDataTables,
        onDowngrade: downgradeUserDataTables,
        onOpen: (db) async {
          await db.execute('PRAGMA busy_timeout = 5000;');
          if (!kIsWeb) {
            await db.execute('PRAGMA journal_mode = WAL;');
          }
          await db.execute('PRAGMA synchronous = NORMAL;');
          await _cleanOrphanedUserDataBeforeFk(db);
          await db.execute('PRAGMA foreign_keys = ON;');
          await ensureUserDataIndexes(db);
        },
      ),
    );
  }

  /// Creates all core user data tables (`user_dexes`, `folders`, `folder_structure`, `user_pokemon`, `shiny_hunts`).
  static Future<void> createUserDataTables(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_dexes (
          id TEXT PRIMARY KEY,
          title TEXT,
          region TEXT,
          include_genders INTEGER,
          include_regional INTEGER,
          include_mega INTEGER,
          include_gmax INTEGER,
          include_other INTEGER,
          is_shiny_dex INTEGER,
          is_alpha INTEGER DEFAULT 0,
          mega_sort TEXT DEFAULT 'origin',
          gmax_sort TEXT DEFAULT 'origin',
          regional_sort TEXT DEFAULT 'mechanic',
          view_mode TEXT DEFAULT 'list',
          custom_boxes TEXT DEFAULT '[]',
          sort_mode TEXT DEFAULT 'dex',
          updated_at INTEGER DEFAULT 0,
          deleted_at INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folders (
          id TEXT PRIMARY KEY,
          title TEXT,
          updated_at INTEGER DEFAULT 0,
          deleted_at INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folder_structure (
          parent_id TEXT,
          child_id TEXT,
          order_index INTEGER,
          updated_at INTEGER DEFAULT 0,
          deleted_at INTEGER DEFAULT 0,
          PRIMARY KEY (parent_id, child_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_pokemon (
          dex_id TEXT,
          unique_id TEXT,
          is_caught INTEGER DEFAULT 0,
          is_shiny INTEGER DEFAULT 0,
          is_ignored INTEGER DEFAULT 0,
          is_alpha INTEGER DEFAULT 0,
          caught_ribbons TEXT DEFAULT '',
          caught_tera_types TEXT DEFAULT '',
          caught_languages TEXT DEFAULT '',
          updated_at INTEGER DEFAULT 0,
          PRIMARY KEY (dex_id, unique_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shiny_hunts (
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
          created_at INTEGER,
          updated_at INTEGER,
          completed_at INTEGER,
          deleted_at INTEGER DEFAULT 0
        )
      ''');
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error_db_create')} $e');
    }
  }

  /// Adds a new column to [table] if it does not already exist.
  static Future<void> addColumnIfNotExists(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name']?.toString().toLowerCase() == column.toLowerCase());
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  /// Handles database downgrade scenarios non-destructively.
  ///
  /// Prevents crashes when switching to older app versions by preserving
  /// all existing tables, columns, and rows without data loss.
  static Future<void> downgradeUserDataTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint("Downgrade von Version $oldVersion auf $newVersion erkannt. Bestehende Daten bleiben erhalten.");
  }

  static Future<void> _cleanOrphanedUserDataBeforeFk(DatabaseExecutor db) async {
    try {
      await db.execute('''
        DELETE FROM folder_structure
        WHERE parent_id != 'root'
        AND parent_id NOT IN (SELECT id FROM folders)
      ''');
      await db.execute('''
        UPDATE shiny_hunts
        SET target_dex_id = NULL
        WHERE target_dex_id IS NOT NULL
        AND target_dex_id != ''
        AND target_dex_id NOT IN (SELECT id FROM user_dexes)
      ''');
    } catch (e) {
      debugPrint("Bereinigung verwaister Datensätze: $e");
    }
  }

  static Future<void> _createIndexIfTableExists(
    DatabaseExecutor db,
    String table,
    String indexName,
    String columns,
  ) async {
    final info = await db.rawQuery("PRAGMA table_info('$table')");
    if (info.isNotEmpty) {
      final idxInfo = await db.rawQuery("PRAGMA index_info('$indexName')");
      if (idxInfo.isNotEmpty) {
        final existingCols = idxInfo.map((r) => r['name']?.toString().toLowerCase()).toList();
        final targetCols = columns.split(',').map((c) => c.trim().toLowerCase().split(' ').first).toList();
        if (existingCols.join(',') != targetCols.join(',')) {
          await db.execute('DROP INDEX IF EXISTS $indexName;');
        }
      }
      await db.execute('CREATE INDEX IF NOT EXISTS $indexName ON $table ($columns);');
    }
  }

  /// Ensures high-performance B-tree indexes are present on user data tables.
  ///
  /// Optimizes queries across folders, shiny hunts, and dex listings.
  static Future<void> ensureUserDataIndexes(DatabaseExecutor db) async {
    await _createIndexIfTableExists(db, 'folder_structure', 'idx_folder_structure_child', 'child_id');
    await _createIndexIfTableExists(db, 'folder_structure', 'idx_folder_structure_parent_order', 'parent_id, deleted_at, order_index');
    await _createIndexIfTableExists(db, 'shiny_hunts', 'idx_shiny_hunts_deleted_updated', 'deleted_at, updated_at DESC');
    await _createIndexIfTableExists(db, 'shiny_hunts', 'idx_shiny_hunts_status', 'status, deleted_at');
    await _createIndexIfTableExists(db, 'shiny_hunts', 'idx_shiny_hunts_target_dex', 'target_dex_id');
    await _createIndexIfTableExists(db, 'user_dexes', 'idx_user_dexes_deleted_updated', 'deleted_at, updated_at DESC');
    await _createIndexIfTableExists(db, 'folders', 'idx_folders_deleted_updated', 'deleted_at, updated_at DESC');
  }

  /// Ensures composite and lookup indexes are created on large static app database tables.
  ///
  /// Speeds up join operations on moves, abilities, forms, and encounters.
  static Future<void> ensureAppDatabaseIndexes(DatabaseExecutor db) async {
    await _createIndexIfTableExists(db, 'pokemon_moves', 'idx_pokemon_moves_move_id', 'move_id');
    await _createIndexIfTableExists(db, 'pokemon_moves', 'idx_pokemon_moves_poke_vg', 'pokemon_id, version_group');
    await _createIndexIfTableExists(db, 'pokemon_abilities', 'idx_pokemon_abilities_ability_id', 'ability_id');
    await _createIndexIfTableExists(db, 'pokemon_abilities', 'idx_pokemon_abilities_poke_id', 'pokemon_id');
    await _createIndexIfTableExists(db, 'encounters', 'idx_encounters_poke_id', 'pokemon_id');
    await _createIndexIfTableExists(db, 'forms', 'idx_forms_poke_id', 'pokemon_id');
    await _createIndexIfTableExists(db, 'dex_orders', 'idx_dex_orders_name_order', 'dex_name, order_index');
    await _createIndexIfTableExists(db, 'dex_orders', 'idx_dex_orders_poke_dex', 'pokemon_id, dex_name, order_index');
    await _createIndexIfTableExists(db, 'special_dexes', 'idx_special_dexes_name', 'dex_name');
    await _createIndexIfTableExists(db, 'special_dexes', 'idx_special_dexes_poke_dex', 'pokemon_id, dex_name');
    await _createIndexIfTableExists(db, 'shiny_categories', 'idx_shiny_categories_poke_id', 'pokemon_id');
    await _createIndexIfTableExists(db, 'special_obtainable', 'idx_special_obtainable_poke_id', 'pokemon_id');

    try {
      final info = await db.rawQuery("PRAGMA table_info(shiny_categories)");
      if (info.isNotEmpty) {
        for (final id in [92, 93, 104, 105]) {
          await db.execute('''
            INSERT INTO shiny_categories (pokemon_id, category)
            SELECT $id, 'gen1_huntable'
            WHERE NOT EXISTS (
              SELECT 1 FROM shiny_categories WHERE pokemon_id = $id AND category = 'gen1_huntable'
            );
          ''');
        }
      }
      final dlInfo = await db.rawQuery("PRAGMA table_info(default_levels)");
      if (dlInfo.isNotEmpty) {
        final defLevels = {92: 20, 93: 23, 104: 20, 105: 30};
        for (final entry in defLevels.entries) {
          await db.execute('''
            INSERT INTO default_levels (pokemon_id, default_level)
            SELECT ${entry.key}, ${entry.value}
            WHERE NOT EXISTS (
              SELECT 1 FROM default_levels WHERE pokemon_id = ${entry.key}
            );
          ''');
          await db.execute('''
            UPDATE default_levels
            SET default_level = ${entry.value}
            WHERE pokemon_id = ${entry.key};
          ''');
        }
      }
    } catch (_) {}

    await db.execute('PRAGMA optimize;');
  }

  /// Upgrades user database schema sequentially across versions using idempotent alter table statements.
  static Future<void> upgradeUserDataTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      int now = DateTime.now().toUtc().millisecondsSinceEpoch;
      try {
        await addColumnIfNotExists(db, 'user_dexes', 'updated_at', 'INTEGER DEFAULT $now');
        await addColumnIfNotExists(db, 'user_dexes', 'deleted_at', 'INTEGER DEFAULT 0');
        await addColumnIfNotExists(db, 'folders', 'updated_at', 'INTEGER DEFAULT $now');
        await addColumnIfNotExists(db, 'folders', 'deleted_at', 'INTEGER DEFAULT 0');
        await addColumnIfNotExists(db, 'folder_structure', 'updated_at', 'INTEGER DEFAULT $now');
        await addColumnIfNotExists(db, 'folder_structure', 'deleted_at', 'INTEGER DEFAULT 0');
        await addColumnIfNotExists(db, 'user_pokemon', 'updated_at', 'INTEGER DEFAULT $now');
        debugPrint(
          "Datenbank erfolgreich auf Version 2 (Offline-First) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler V2: $e");
      }
    }
    if (oldVersion < 3) {
      try {
        await addColumnIfNotExists(db, 'user_dexes', 'view_mode', "TEXT DEFAULT 'list'");
        await addColumnIfNotExists(db, 'user_dexes', 'sort_mode', "TEXT DEFAULT 'dex'");
        debugPrint(
          "Datenbank erfolgreich auf Version 3 (Sort/View-Modes) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler V3: $e");
      }
    }
    if (oldVersion < 4) {
      try {
        await addColumnIfNotExists(db, 'user_pokemon', 'caught_ribbons', "TEXT DEFAULT ''");
        await addColumnIfNotExists(db, 'user_pokemon', 'caught_tera_types', "TEXT DEFAULT ''");
        debugPrint(
          "Datenbank erfolgreich auf Version 4 (Ribbons & Tera) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler V4: $e");
      }
    }
    if (oldVersion < 5) {
      try {
        await addColumnIfNotExists(db, 'user_pokemon', 'is_alpha', "INTEGER DEFAULT 0");
        debugPrint(
          "Datenbank erfolgreich auf Version 5 (Alpha Status) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler V5: $e");
      }
    }
    if (oldVersion < 6) {
      try {
        await addColumnIfNotExists(db, 'user_pokemon', 'caught_languages', "TEXT DEFAULT ''");
        debugPrint("Datenbank erfolgreich auf Version 6 (Sprachen) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V6: $e");
      }
    }
    if (oldVersion < 7) {
      try {
        await addColumnIfNotExists(db, 'user_dexes', 'mega_sort', "TEXT DEFAULT 'origin'");
        await addColumnIfNotExists(db, 'user_dexes', 'gmax_sort', "TEXT DEFAULT 'origin'");
        await addColumnIfNotExists(db, 'user_dexes', 'regional_sort', "TEXT DEFAULT 'mechanic'");
        debugPrint("Datenbank erfolgreich auf Version 7 (Sortiereinstellungen) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V7: $e");
      }
    }
    if (oldVersion < 8) {
      try {
        await addColumnIfNotExists(db, 'user_dexes', 'custom_boxes', "TEXT DEFAULT '[]'");
        debugPrint("Datenbank erfolgreich auf Version 8 (Custom Boxes) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V8: $e");
      }
    }
    if (oldVersion < 9) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS shiny_hunts (
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
            created_at INTEGER,
            updated_at INTEGER,
            completed_at INTEGER,
            deleted_at INTEGER DEFAULT 0
          )
        ''');
        debugPrint("Datenbank erfolgreich auf Version 9 (Shiny Hunts) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V9: $e");
      }
    }
    if (oldVersion < 10) {
      try {
        await addColumnIfNotExists(db, 'shiny_hunts', 'hunting_type', 'TEXT');
        debugPrint("Datenbank erfolgreich auf Version 10 (Shiny Hunt Jagdart) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V10: $e");
      }
    }
  }

  /// Returns all Pokémon from the reference database including their forms.
  Future<List<Pokemon>> getAllPokemon() async {
    final db = await instance.appDatabase;
    final pokeMaps = await db.query('pokemon');
    final formMaps = await db.query('forms');

    Map<int, List<PokemonForm>> formsByPoke = {};
    for (var f in formMaps) {
      int pId = (f['pokemon_id'] as num?)?.toInt() ?? 0;
      formsByPoke.putIfAbsent(pId, () => []).add(PokemonForm.fromMap(f));
    }

    return pokeMaps
        .map(
          (p) => Pokemon.fromMap(
            p,
            formsByPoke[(p['id'] as num?)?.toInt() ?? 0] ?? [],
          ),
        )
        .toList();
  }

  /// Returns an index mapping of all regional and special Pokédex names to ordered lists of Pokémon IDs.
  Future<Map<String, List<int>>> getAllDexOrders() async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'dex_orders',
      orderBy: 'dex_name ASC, order_index ASC',
    );

    Map<String, List<int>> result = {};
    for (var m in maps) {
      String dexName = m['dex_name']?.toString() ?? '';
      int pId = (m['pokemon_id'] as num?)?.toInt() ?? 0;
      result.putIfAbsent(dexName, () => []).add(pId);
    }

    final specialMaps = await db.query('special_dexes');
    for (var m in specialMaps) {
      String dexName = m['dex_name']?.toString().replaceAll('-', '_') ?? '';
      int pId = (m['pokemon_id'] as num?)?.toInt() ?? 0;
      result.putIfAbsent(dexName, () => []).add(pId);
    }

    result['national_overall'] = result['paldea_national'] ?? [];
    return result;
  }

  /// Returns a map associating Pokéball identifiers with their icon URLs.
  Future<Map<String, String>> getBallUrls() async {
    final db = await instance.appDatabase;
    final maps = await db.query('ball_urls');
    Map<String, String> result = {};
    for (var m in maps) {
      result[m['ball_name']?.toString() ?? ''] =
          m['image_url']?.toString() ?? '';
    }
    return result;
  }

  /// Returns wild encounter locations and methods for [pokemonId] grouped by generation and version.
  Future<Map<String, Map<String, List<String>>>?> getEncounters(
    int pokemonId,
  ) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'encounters',
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
    );

    if (maps.isEmpty) return null;

    Map<String, Map<String, List<String>>> result = {};
    for (var map in maps) {
      String gen = map['gen']?.toString() ?? '';
      String version = map['version']?.toString() ?? '';
      String locData = map['location_data']?.toString() ?? '';

      result.putIfAbsent(gen, () => {});
      result[gen]![version] = locData.split('|||||');
    }
    return result;
  }

  /// Returns the parsed JSON evolution chain for [chainId], or `null` if not found.
  Future<Map<String, dynamic>?> getEvolutionChain(int chainId) async {
    if (chainId == -1) return null;
    final db = await instance.appDatabase;
    final maps = await db.query(
      'evolutions',
      where: 'chain_id = ?',
      whereArgs: [chainId],
    );
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['chain_json']?.toString() ?? '{}');
    }
    return null;
  }

  /// Returns legal and recommended Pokéball lists for [uniqueId] in normal and shiny variations.
  Future<Map<String, dynamic>?> getMatchingBalls(String uniqueId) async {
    final db = await instance.appDatabase;
    var maps = await db.query(
      'matching_balls',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
    if (maps.isEmpty && !uniqueId.contains('_')) {
      maps = await db.query(
        'matching_balls',
        where: 'unique_id = ?',
        whereArgs: ['${uniqueId}_normal'],
      );
    }
    if (maps.isNotEmpty) {
      String nb = maps.first['normal_balls']?.toString() ?? 'any_ball';
      String sb = maps.first['shiny_balls']?.toString() ?? 'any_ball';
      return {
        'normal': nb == 'any_ball' ? [] : nb.split(','),
        'shiny': sb == 'any_ball' ? [] : sb.split(','),
      };
    }
    return null;
  }

  /// Returns all active [UserDex] instances and their associated Pokémon states.
  Future<List<UserDex>> getAllUserDexes() async {
    final db = await instance.userDatabase;
    final dexMaps = await db.query(
      'user_dexes',
      where: 'deleted_at = ?',
      whereArgs: [0],
    );

    List<UserDex> dexes = [];
    for (var map in dexMaps) {
      UserDex dex = UserDex.fromMap(map);
      final pMaps = await db.query(
        'user_pokemon',
        where: 'dex_id = ?',
        whereArgs: [dex.id],
      );

      for (var p in pMaps) {
        String uId = p['unique_id']?.toString() ?? '';
        if ((p['is_caught'] as num?)?.toInt() == 1) dex.caughtIds.add(uId);
        if ((p['is_shiny'] as num?)?.toInt() == 1) dex.shinyIds.add(uId);
        if ((p['is_ignored'] as num?)?.toInt() == 1) dex.ignoredIds.add(uId);
        if ((p['is_alpha'] as num?)?.toInt() == 1) dex.alphaIds.add(uId);

        String rStr = p['caught_ribbons']?.toString() ?? '';
        if (rStr.isNotEmpty) dex.caughtRibbons[uId] = rStr.split(',');

        String tStr = p['caught_tera_types']?.toString() ?? '';
        if (tStr.isNotEmpty) dex.caughtTeraTypes[uId] = tStr.split(',');

        String lStr = p['caught_languages']?.toString() ?? '';
        if (lStr.isNotEmpty) {
          dex.caughtLanguages[uId] = lStr.split(',');
        }
      }
      dexes.add(dex);
    }
    return dexes;
  }

  /// Inserts or updates the [dex] configuration non-destructively in local SQLite.
  Future<void> saveUserDex(UserDex dex) async {
    final db = await instance.userDatabase;
    Map<String, dynamic> dexMap = dex.toMap();
    dexMap.remove('caught_ids');
    dexMap.remove('shiny_ids');
    dexMap.remove('alpha_ids');
    dexMap.remove('ignored_ids');
    dexMap.remove('caught_ribbons');
    dexMap.remove('caught_tera_types');
    dexMap.remove('caught_languages');
    dexMap['updated_at'] = DateTime.now().toUtc().millisecondsSinceEpoch;
    dexMap['deleted_at'] = 0;

    final cols = dexMap.keys.toList();
    final placeholders = cols.map((_) => '?').join(', ');
    final updateSets = cols
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');

    final sql = '''
      INSERT INTO user_dexes (${cols.join(', ')})
      VALUES ($placeholders)
      ON CONFLICT(id) DO UPDATE SET $updateSets
    ''';

    await db.rawInsert(sql, cols.map((c) => dexMap[c]).toList());
  }

  /// Soft-deletes the user Dex identified by [dexId] and removes it from folder structures.
  Future<void> deleteUserDex(String dexId) async {
    final db = await instance.userDatabase;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.update(
      'user_dexes',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [dexId],
    );
    await db.update(
      'folder_structure',
      {'deleted_at': now, 'updated_at': now},
      where: 'child_id = ?',
      whereArgs: [dexId],
    );
  }

  /// Persists caught, shiny, alpha, ribbon, tera, and language attributes for a Pokémon in a Dex.
  Future<void> savePokemonStatus(
    String dexId,
    String uniqueId, {
    bool? isCaught,
    bool? isShiny,
    bool? isIgnored,
    bool? isAlpha,
    List<String>? ribbons,
    List<String>? teraTypes,
    List<String>? languages,
  }) async {
    final db = await instance.userDatabase;
    final maps = await db.query(
      'user_pokemon',
      where: 'dex_id = ? AND unique_id = ?',
      whereArgs: [dexId, uniqueId],
    );

    int caught = 0, shiny = 0, ignored = 0, alpha = 0;
    String r = '', t = '', l = '';

    if (maps.isNotEmpty) {
      caught = (maps.first['is_caught'] as num?)?.toInt() ?? 0;
      shiny = (maps.first['is_shiny'] as num?)?.toInt() ?? 0;
      ignored = (maps.first['is_ignored'] as num?)?.toInt() ?? 0;
      alpha = (maps.first['is_alpha'] as num?)?.toInt() ?? 0;
      r = maps.first['caught_ribbons']?.toString() ?? '';
      t = maps.first['caught_tera_types']?.toString() ?? '';
      l = maps.first['caught_languages']?.toString() ?? '';
    }

    if (isCaught != null) caught = isCaught ? 1 : 0;
    if (isShiny != null) shiny = isShiny ? 1 : 0;
    if (isIgnored != null) ignored = isIgnored ? 1 : 0;
    if (isAlpha != null) alpha = isAlpha ? 1 : 0;
    if (ribbons != null) r = ribbons.join(',');
    if (teraTypes != null) t = teraTypes.join(',');
    if (languages != null) l = languages.join(',');

    final data = {
      'dex_id': dexId,
      'unique_id': uniqueId,
      'is_caught': caught,
      'is_shiny': shiny,
      'is_ignored': ignored,
      'is_alpha': alpha,
      'caught_ribbons': r,
      'caught_tera_types': t,
      'caught_languages': l,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    };

    final cols = data.keys.toList();
    final placeholders = cols.map((_) => '?').join(', ');
    final updateSets = cols
        .where((c) => c != 'dex_id' && c != 'unique_id')
        .map((c) => '$c = excluded.$c')
        .join(', ');

    final sql = '''
      INSERT INTO user_pokemon (${cols.join(', ')})
      VALUES ($placeholders)
      ON CONFLICT(dex_id, unique_id) DO UPDATE SET $updateSets
    ''';

    await db.rawInsert(sql, cols.map((c) => data[c]).toList());
  }

  Future<int> cleanupOrphanedPokemon(String dexId, Set<String> activeUniqueIds) async {
    final db = await instance.userDatabase;
    final rows = await db.query(
      'user_pokemon',
      columns: ['unique_id'],
      where: 'dex_id = ?',
      whereArgs: [dexId],
    );

    int deletedCount = 0;
    final batch = db.batch();
    for (final row in rows) {
      final uId = row['unique_id'] as String? ?? '';
      if (uId.contains('__') && !activeUniqueIds.contains(uId)) {
        batch.delete(
          'user_pokemon',
          where: 'dex_id = ? AND unique_id = ?',
          whereArgs: [dexId, uId],
        );
        deletedCount++;
      }
    }
    if (deletedCount > 0) {
      await batch.commit(noResult: true);
    }
    return deletedCount;
  }

  Future<List<DexFolder>> getAllFolders() async {
    final db = await instance.userDatabase;
    final maps = await db.query(
      'folders',
      where: 'deleted_at = ?',
      whereArgs: [0],
    );
    return maps.map((m) => DexFolder.fromMap(m)).toList();
  }

  Future<void> saveFolder(DexFolder folder) async {
    final db = await instance.userDatabase;
    Map<String, dynamic> folderMap = folder.toMap();
    folderMap['updated_at'] = DateTime.now().toUtc().millisecondsSinceEpoch;
    folderMap['deleted_at'] = 0;

    final cols = folderMap.keys.toList();
    final placeholders = cols.map((_) => '?').join(', ');
    final updateSets = cols
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');

    final sql = '''
      INSERT INTO folders (${cols.join(', ')})
      VALUES ($placeholders)
      ON CONFLICT(id) DO UPDATE SET $updateSets
    ''';

    await db.rawInsert(sql, cols.map((c) => folderMap[c]).toList());
  }

  Future<void> deleteFolder(String folderId, {bool recursive = false}) async {
    final db = await instance.userDatabase;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;

    await db.update(
      'folders',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [folderId],
    );

    await db.update(
      'folder_structure',
      {'deleted_at': now, 'updated_at': now},
      where: 'child_id = ?',
      whereArgs: [folderId],
    );

    if (recursive) {
      await db.update(
        'folder_structure',
        {'deleted_at': now, 'updated_at': now},
        where: 'parent_id = ?',
        whereArgs: [folderId],
      );
    } else {
      await db.update(
        'folder_structure',
        {'parent_id': 'root', 'updated_at': now},
        where: 'parent_id = ? AND deleted_at = ?',
        whereArgs: [folderId, 0],
      );
    }
  }

  Future<Map<String, List<String>>> getStructure() async {
    final db = await instance.userDatabase;
    final maps = await db.query(
      'folder_structure',
      where: 'deleted_at = ?',
      whereArgs: [0],
      orderBy: 'order_index ASC',
    );

    Map<String, List<String>> structure = {};
    for (var m in maps) {
      String pId = m['parent_id']?.toString() ?? 'root';
      String cId = m['child_id']?.toString() ?? '';
      structure.putIfAbsent(pId, () => []).add(cId);
    }
    if (!structure.containsKey('root')) structure['root'] = [];

    return structure;
  }

  Future<void> saveStructure(Map<String, List<String>> structure) async {
    final db = await instance.userDatabase;
    int now = DateTime.now().toUtc().millisecondsSinceEpoch;

    await db.update('folder_structure', {'deleted_at': now, 'updated_at': now});

    Batch batch = db.batch();
    structure.forEach((parentId, children) {
      for (int i = 0; i < children.length; i++) {
        batch.rawInsert('''
          INSERT INTO folder_structure (parent_id, child_id, order_index, updated_at, deleted_at)
          VALUES (?, ?, ?, ?, 0)
          ON CONFLICT(parent_id, child_id) DO UPDATE SET
            order_index = excluded.order_index,
            updated_at = excluded.updated_at,
            deleted_at = 0
        ''', [parentId, children[i], i, now]);
      }
    });
    await batch.commit(noResult: true);
  }

  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async {
    final db = await instance.userDatabase;
    final maps = await db.query(
      'shiny_hunts',
      where: includeDeleted ? null : 'deleted_at = 0',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => ShinyHunt.fromMap(m)).toList();
  }

  Future<ShinyHunt?> getShinyHunt(String id) async {
    final db = await instance.userDatabase;
    final maps = await db.query(
      'shiny_hunts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ShinyHunt.fromMap(maps.first);
  }

  Future<void> saveShinyHunt(ShinyHunt hunt) async {
    final db = await instance.userDatabase;
    final map = hunt.toMap();
    map['updated_at'] = DateTime.now().toUtc().millisecondsSinceEpoch;

    final cols = map.keys.toList();
    final placeholders = cols.map((_) => '?').join(', ');
    final updateSets = cols
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');

    final sql = '''
      INSERT INTO shiny_hunts (${cols.join(', ')})
      VALUES ($placeholders)
      ON CONFLICT(id) DO UPDATE SET $updateSets
    ''';

    await db.rawInsert(sql, cols.map((c) => map[c]).toList());
  }

  Future<void> deleteShinyHunt(String id, {bool softDelete = true}) async {
    final db = await instance.userDatabase;
    if (softDelete) {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.update(
        'shiny_hunts',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete(
        'shiny_hunts',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> clearUserData() async {
    final db = await instance.userDatabase;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON;');
      await txn.delete('user_pokemon');
      await txn.delete('folder_structure');
      await txn.delete('shiny_hunts');
      await txn.delete('folders');
      await txn.delete('user_dexes');
    });
  }

  Future<Map<String, dynamic>> exportCloudSyncData() async {
    final db = await instance.userDatabase;
    return {
      'format_version': 2,
      'user_dexes': await db.query('user_dexes'),
      'folders': await db.query('folders'),
      'folder_structure': await db.query('folder_structure'),
      'user_pokemon': await db.query('user_pokemon'),
      'shiny_hunts': await db.query('shiny_hunts'),
    };
  }

  Future<void> mergeCloudSyncData(Map<String, dynamic> cloudData) async {
    final db = await instance.userDatabase;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON;');

      final Map<String, Set<String>> cachedColumns = {};
      Future<Set<String>> getLocalColumns(String table) async {
        if (cachedColumns.containsKey(table)) return cachedColumns[table]!;
        final info = await txn.rawQuery("PRAGMA table_info('$table')");
        final cols = info.map((r) => r['name'].toString().toLowerCase()).toSet();
        cachedColumns[table] = cols;
        return cols;
      }

      Future<void> mergeTable(
        String tableName,
        List<String> primaryKeys,
        List<dynamic>? remoteRows,
      ) async {
        if (remoteRows == null) return;
        final localCols = await getLocalColumns(tableName);
        if (localCols.isEmpty) return; // Table not present in local schema, skip safely

        for (var row in remoteRows) {
          final remoteRow = Map<String, dynamic>.from(row as Map);
          final filteredRow = <String, dynamic>{};
          for (final entry in remoteRow.entries) {
            if (localCols.contains(entry.key.toLowerCase())) {
              filteredRow[entry.key] = entry.value;
            }
          }

          bool hasAllPks = true;
          for (final pk in primaryKeys) {
            if (!filteredRow.containsKey(pk)) {
              hasAllPks = false;
              break;
            }
          }
          if (!hasAllPks) continue;

          final whereClause = primaryKeys.map((k) => '$k = ?').join(' AND ');
          final whereArgs = primaryKeys.map((k) => filteredRow[k]).toList();

          final localResult = await txn.query(
            tableName,
            where: whereClause,
            whereArgs: whereArgs,
          );

          if (localResult.isEmpty) {
            await txn.insert(tableName, filteredRow);
          } else {
            final localRow = localResult.first;
            final localUpdated = (localRow['updated_at'] as num?)?.toInt() ?? 0;
            final remoteUpdated =
                (filteredRow['updated_at'] as num?)?.toInt() ?? 0;
            if (remoteUpdated > localUpdated) {
              await txn.update(
                tableName,
                filteredRow,
                where: whereClause,
                whereArgs: whereArgs,
              );
            }
          }
        }
      }

      // Order of syncing respects foreign keys
      await mergeTable('folders', ['id'], cloudData['folders'] as List?);
      await mergeTable('user_dexes', ['id'], cloudData['user_dexes'] as List?);
      await mergeTable('folder_structure', [
        'parent_id',
        'child_id',
      ], cloudData['folder_structure'] as List?);
      await mergeTable('shiny_hunts', ['id'], cloudData['shiny_hunts'] as List?);
      await mergeTable('user_pokemon', [
        'dex_id',
        'unique_id',
      ], cloudData['user_pokemon'] as List?);
    });
  }

  Future<List<int>?> getGen1BaseStats(int pokemonId) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'gen1_base_stats',
      where: 'id = ?',
      whereArgs: [pokemonId],
    );
    if (maps.isNotEmpty) {
      final m = maps.first;
      return [
        (m['hp'] as num).toInt(),
        (m['atk'] as num).toInt(),
        (m['def'] as num).toInt(),
        (m['spc'] as num).toInt(),
        (m['spe'] as num).toInt(),
      ];
    }
    return null;
  }

  Future<Map<int, Map<String, dynamic>>> getGen12PreEvolutions() async {
    final db = await instance.appDatabase;
    final maps = await db.query('gen12_pre_evolutions');
    Map<int, Map<String, dynamic>> result = {};
    for (var m in maps) {
      result[(m['id'] as num).toInt()] = {
        'pre': (m['pre_id'] as num).toInt(),
        'req': m['req'].toString(),
      };
    }
    return result;
  }

  Future<int> getDefaultLevel(int pokemonId) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'default_levels',
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
    );
    return maps.isNotEmpty ? (maps.first['default_level'] as num).toInt() : 15;
  }

  Future<List<String>> getShinyCategories(int pokemonId) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'shiny_categories',
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  Future<List<PokeAbility>> getAllAbilities() async {
    final db = await instance.appDatabase;
    final maps = await db.query('abilities', orderBy: 'id ASC');
    return maps
        .map(
          (m) => PokeAbility(
            id: m['id'] as int,
            nameDe: m['name_de'] as String,
            nameEn: m['name_en'] as String,
            descDe: m['desc_de'] as String,
            descEn: m['desc_en'] as String,
          ),
        )
        .toList();
  }

  Future<List<PokeMove>> getAllMoves() async {
    final db = await instance.appDatabase;
    final maps = await db.query('moves', orderBy: 'id ASC');
    return maps
        .map(
          (m) => PokeMove(
            id: m['id'] as int,
            nameDe: m['name_de'] as String,
            nameEn: m['name_en'] as String,
            type: m['type'] as String,
            power: m['power'] as int? ?? 0,
            accuracy: m['accuracy'] as int? ?? 0,
            pp: m['pp'] as int? ?? 0,
            damageClass: m['damage_class'] as String,
            descDe: m['desc_de'] as String,
            descEn: m['desc_en'] as String,
          ),
        )
        .toList();
  }

  Future<List<PokemonLearnset>> getPokemonForMove(int moveId) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'pokemon_moves',
      where: 'move_id = ?',
      whereArgs: [moveId],
    );
    return maps
        .map(
          (m) => PokemonLearnset(
            pokemonId: m['pokemon_id'] as int,
            learnMethod: m['learn_method'] as String,
            levelLearned: m['level_learned'] as int,
            versionGroup: m['version_group'] as String,
          ),
        )
        .toList();
  }

  Future<List<PokemonLearnset>> getPokemonForAbility(int abilityId) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'pokemon_abilities',
      where: 'ability_id = ?',
      whereArgs: [abilityId],
    );
    return maps
        .map(
          (m) => PokemonLearnset(
            pokemonId: m['pokemon_id'] as int,
            learnMethod: 'ability',
            levelLearned: 0,
            versionGroup: 'all',
            isHiddenAbility: (m['is_hidden'] as int) == 1,
          ),
        )
        .toList();
  }

  Future<List<Ribbon>> getAllRibbons() async {
    final db = await instance.appDatabase;
    final maps = await db.query('ribbons');
    return maps.map((m) => Ribbon.fromMap(m)).toList();
  }

  Future<List<String>> getAvailableVersionGroups(int pokemonId) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'pokemon_moves',
      columns: ['version_group'],
      where: 'pokemon_id = ?',
      whereArgs: [pokemonId],
      distinct: true,
    );
    return maps.map((m) => m['version_group'] as String).toList();
  }

  Future<int> getBasePokemonId(int chainId) async {
    if (chainId == -1) return -1;
    final db = await instance.appDatabase;
    final maps = await db.query(
      'evolutions',
      where: 'chain_id = ?',
      whereArgs: [chainId],
    );
    if (maps.isNotEmpty) {
      final data = jsonDecode(maps.first['chain_json']?.toString() ?? '{}');
      if (data['species_id'] != null) {
        return (data['species_id'] as num).toInt();
      }
    }
    return -1;
  }

  Future<List<Map<String, dynamic>>> getSpecialObtainables() async {
    final db = await instance.appDatabase;
    return await db.query('special_obtainable');
  }
}


