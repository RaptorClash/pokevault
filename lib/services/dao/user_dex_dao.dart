import 'package:sqflite/sqflite.dart';
import '../../models/user_dex.dart';

/// Data Access Object for User Dexes, Custom Folders, Folder Hierarchies,
/// and individual Pokémon caught/shiny statuses persisted in `user_data.sqlite`.
class UserDexDao {
  final Future<Database> Function() _getDatabase;

  UserDexDao(this._getDatabase);

  /// Returns all active [UserDex] instances and their associated Pokémon states.
  Future<List<UserDex>> getAllUserDexes() async {
    final db = await _getDatabase();
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
    final db = await _getDatabase();
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

    final info = await db.rawQuery("PRAGMA table_info('user_dexes')");
    final localCols = info.map((r) => r['name'].toString().toLowerCase()).toSet();
    final cols = dexMap.keys.where((c) => localCols.contains(c.toLowerCase())).toList();
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
    final db = await _getDatabase();
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
    final db = await _getDatabase();
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

  /// Cleans up orphaned custom form IDs that were unselected from a Dex.
  Future<int> cleanupOrphanedPokemon(String dexId, Set<String> activeUniqueIds) async {
    final db = await _getDatabase();
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
    final db = await _getDatabase();
    final maps = await db.query(
      'folders',
      where: 'deleted_at = ?',
      whereArgs: [0],
    );
    return maps.map((m) => DexFolder.fromMap(m)).toList();
  }

  Future<void> saveFolder(DexFolder folder) async {
    final db = await _getDatabase();
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
    final db = await _getDatabase();
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
    final db = await _getDatabase();
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
    final db = await _getDatabase();
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

  Future<void> clearUserData() async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.rawQuery('PRAGMA defer_foreign_keys = ON;');
      await txn.delete('user_pokemon');
      await txn.delete('folder_structure');
      await txn.delete('shiny_hunts');
      await txn.delete('folders');
      await txn.delete('user_dexes');
    });
  }
}
