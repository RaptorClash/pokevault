import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../utils/notification_helper.dart';
import '../../i18n/strings.g.dart';

/// Handles table schema definitions, sequential idempotent migrations,
/// and index management for PokéVault SQLite databases.
class DatabaseMigrator {
  DatabaseMigrator._();

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
          include_trades INTEGER DEFAULT 0,
          include_gifts INTEGER DEFAULT 0,
          include_glitch INTEGER DEFAULT 0,
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
          pause_history TEXT DEFAULT '[]',
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
      NotificationHelper.showError('${t.error_db_create} $e');
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

  /// Cleans orphaned rows before enforcing foreign keys.
  static Future<void> cleanOrphanedUserDataBeforeFk(DatabaseExecutor db) async {
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
    try {
      final info = await db.rawQuery("PRAGMA table_info($table)");
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
    } catch (_) {}
  }

  /// Ensures high-performance B-tree indexes are present on user data tables.
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
    await _createIndexIfTableExists(db, 'gender_differences', 'idx_gender_differences_pokemon_id', 'pokemon_id');
    await _createIndexIfTableExists(db, 'shiny_locks', 'idx_shiny_locks_poke', 'pokemon_id');
    await _createIndexIfTableExists(db, 'shiny_locks', 'idx_shiny_locks_poke_ver', 'pokemon_id, game_version');

    try {
      final info = await db.rawQuery("PRAGMA table_info(shiny_categories)");
      if (info.isNotEmpty) {
        final existingCats = await db.query(
          'shiny_categories',
          where: "pokemon_id IN (92, 93, 104, 105) AND category = 'gen1_huntable'",
        );
        final existingIds = existingCats.map((r) => (r['pokemon_id'] as num).toInt()).toSet();
        for (final id in [92, 93, 104, 105]) {
          if (!existingIds.contains(id)) {
            await db.execute('''
              INSERT INTO shiny_categories (pokemon_id, category)
              VALUES ($id, 'gen1_huntable');
            ''');
          }
        }
      }
      final dlInfo = await db.rawQuery("PRAGMA table_info(default_levels)");
      if (dlInfo.isNotEmpty) {
        final defLevels = {92: 20, 93: 23, 104: 20, 105: 30};
        final existing = await db.query(
          'default_levels',
          where: 'pokemon_id IN (92, 93, 104, 105)',
        );
        final existingMap = {
          for (var r in existing) (r['pokemon_id'] as num).toInt(): (r['default_level'] as num).toInt()
        };
        for (final entry in defLevels.entries) {
          if (existingMap[entry.key] != entry.value) {
            await db.execute('''
              INSERT INTO default_levels (pokemon_id, default_level)
              VALUES (${entry.key}, ${entry.value})
              ON CONFLICT(pokemon_id) DO UPDATE SET default_level = ${entry.value};
            ''');
          }
        }
      }
    } catch (_) {}

    await db.rawQuery('PRAGMA optimize;');
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
            pause_history TEXT DEFAULT '[]',
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
    if (oldVersion < 11) {
      try {
        await addColumnIfNotExists(db, 'shiny_hunts', 'pause_history', "TEXT DEFAULT '[]'");
        debugPrint("Datenbank erfolgreich auf Version 11 (Shiny Hunt Pause History) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V11: $e");
      }
    }
    if (oldVersion < 12) {
      try {
        await addColumnIfNotExists(db, 'user_dexes', 'include_trades', 'INTEGER DEFAULT 1');
        await addColumnIfNotExists(db, 'user_dexes', 'include_gifts', 'INTEGER DEFAULT 1');
        debugPrint("Datenbank erfolgreich auf Version 12 (Trades & Gifts) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V12: $e");
      }
    }
    if (oldVersion < 13) {
      try {
        await addColumnIfNotExists(db, 'user_dexes', 'include_glitch', 'INTEGER DEFAULT 0');
        debugPrint("Datenbank erfolgreich auf Version 13 (Glitch Pokemon) migriert!");
      } catch (e) {
        debugPrint("Migrations-Fehler V13: $e");
      }
    }
  }
}
