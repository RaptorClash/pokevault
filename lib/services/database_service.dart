import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../utils/notification_helper.dart';
import '../l10n/app_translations.dart';
import 'dart:typed_data';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _appDatabase;
  static Database? _userDatabase;

  DatabaseService._init();

  Future<Database> get appDatabase async {
    if (_appDatabase != null) return _appDatabase!;
    _appDatabase = await _initAppDB('pokedex.sqlite');
    return _appDatabase!;
  }

  Future<Database> _initAppDB(String fileName) async {
    String path = fileName;
    DatabaseFactory factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;
    if (!kIsWeb) {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, fileName);
    }
    bool dbExists = await factory.databaseExists(path);
    if (!dbExists) {
      try {
        ByteData data = await rootBundle.load('assets/db/$fileName');
        Uint8List bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await factory.writeDatabaseBytes(path, bytes);
      } catch (e) {
        NotificationHelper.showError('${Translator.get('error_db_init')} $e');
      }
    }
    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1),
    );
  }

  Future<Database> get userDatabase async {
    if (_userDatabase != null) return _userDatabase!;
    _userDatabase = await _initUserDB('user_data.sqlite');
    return _userDatabase!;
  }

  Future<Database> _initUserDB(String fileName) async {
    String path = fileName;
    DatabaseFactory factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;
    if (!kIsWeb) {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, fileName);
    }
    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _createUserDataTables,
        onUpgrade: _upgradeUserDataTables,
      ),
    );
  }

  Future<void> _createUserDataTables(Database db, int version) async {
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
          view_mode TEXT DEFAULT 'list',
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
          updated_at INTEGER DEFAULT 0,
          PRIMARY KEY (dex_id, unique_id)
        )
      ''');
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error_db_create')} $e');
    }
  }

  Future<void> _upgradeUserDataTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      int now = DateTime.now().toUtc().millisecondsSinceEpoch;
      try {
        await db.execute(
          'ALTER TABLE user_dexes ADD COLUMN updated_at INTEGER DEFAULT $now',
        );
        await db.execute(
          'ALTER TABLE user_dexes ADD COLUMN deleted_at INTEGER DEFAULT 0',
        );

        await db.execute(
          'ALTER TABLE folders ADD COLUMN updated_at INTEGER DEFAULT $now',
        );
        await db.execute(
          'ALTER TABLE folders ADD COLUMN deleted_at INTEGER DEFAULT 0',
        );

        await db.execute(
          'ALTER TABLE folder_structure ADD COLUMN updated_at INTEGER DEFAULT $now',
        );
        await db.execute(
          'ALTER TABLE folder_structure ADD COLUMN deleted_at INTEGER DEFAULT 0',
        );

        await db.execute(
          'ALTER TABLE user_pokemon ADD COLUMN updated_at INTEGER DEFAULT $now',
        );
        debugPrint(
          "Datenbank erfolgreich auf Version 2 (Offline-First) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler (Spalten existieren evtl. schon): $e");
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          "ALTER TABLE user_dexes ADD COLUMN view_mode TEXT DEFAULT 'list'",
        );
        await db.execute(
          "ALTER TABLE user_dexes ADD COLUMN sort_mode TEXT DEFAULT 'dex'",
        );
        debugPrint(
          "Datenbank erfolgreich auf Version 3 (Sort/View-Modes) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler V3: $e");
      }
    }
  }

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

  Future<Map<String, dynamic>?> getMatchingBalls(String uniqueId) async {
    final db = await instance.appDatabase;
    final maps = await db.query(
      'matching_balls',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
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
      }
      dexes.add(dex);
    }
    return dexes;
  }

  Future<void> saveUserDex(UserDex dex) async {
    final db = await instance.userDatabase;

    Map<String, dynamic> dexMap = dex.toMap();
    dexMap['updated_at'] = DateTime.now().toUtc().millisecondsSinceEpoch;
    dexMap['deleted_at'] = 0;

    await db.insert(
      'user_dexes',
      dexMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<void> savePokemonStatus(
    String dexId,
    String uniqueId, {
    bool? isCaught,
    bool? isShiny,
    bool? isIgnored,
  }) async {
    final db = await instance.userDatabase;
    final maps = await db.query(
      'user_pokemon',
      where: 'dex_id = ? AND unique_id = ?',
      whereArgs: [dexId, uniqueId],
    );
    int caught = 0, shiny = 0, ignored = 0;
    if (maps.isNotEmpty) {
      caught = (maps.first['is_caught'] as num?)?.toInt() ?? 0;
      shiny = (maps.first['is_shiny'] as num?)?.toInt() ?? 0;
      ignored = (maps.first['is_ignored'] as num?)?.toInt() ?? 0;
    }
    if (isCaught != null) caught = isCaught ? 1 : 0;
    if (isShiny != null) shiny = isShiny ? 1 : 0;
    if (isIgnored != null) ignored = isIgnored ? 1 : 0;

    await db.insert('user_pokemon', {
      'dex_id': dexId,
      'unique_id': uniqueId,
      'is_caught': caught,
      'is_shiny': shiny,
      'is_ignored': ignored,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

    await db.insert(
      'folders',
      folderMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFolder(String folderId) async {
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
      where: 'parent_id = ? OR child_id = ?',
      whereArgs: [folderId, folderId],
    );
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
        batch.insert('folder_structure', {
          'parent_id': parentId,
          'child_id': children[i],
          'order_index': i,
          'updated_at': now,
          'deleted_at': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    await batch.commit(noResult: true);
  }

  Future<void> clearUserData() async {
    final db = await instance.userDatabase;
    await db.delete('user_dexes');
    await db.delete('folders');
    await db.delete('folder_structure');
    await db.delete('user_pokemon');
  }

  Future<Map<String, dynamic>> exportCloudSyncData() async {
    final db = await instance.userDatabase;
    return {
      'format_version': 2,
      'user_dexes': await db.query('user_dexes'),
      'folders': await db.query('folders'),
      'folder_structure': await db.query('folder_structure'),
      'user_pokemon': await db.query('user_pokemon'),
    };
  }

  Future<void> mergeCloudSyncData(Map<String, dynamic> cloudData) async {
    final db = await instance.userDatabase;

    await db.transaction((txn) async {
      Future<void> mergeTable(
        String tableName,
        List<String> primaryKeys,
        List<dynamic>? remoteRows,
      ) async {
        if (remoteRows == null) return;

        for (var row in remoteRows) {
          final remoteRow = Map<String, dynamic>.from(row);
          final whereClause = primaryKeys.map((k) => '$k = ?').join(' AND ');
          final whereArgs = primaryKeys.map((k) => remoteRow[k]).toList();

          final localResult = await txn.query(
            tableName,
            where: whereClause,
            whereArgs: whereArgs,
          );

          if (localResult.isEmpty) {
            await txn.insert(
              tableName,
              remoteRow,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            final localRow = localResult.first;
            final localUpdated = (localRow['updated_at'] as num?)?.toInt() ?? 0;
            final remoteUpdated =
                (remoteRow['updated_at'] as num?)?.toInt() ?? 0;

            if (remoteUpdated > localUpdated) {
              await txn.update(
                tableName,
                remoteRow,
                where: whereClause,
                whereArgs: whereArgs,
              );
            }
          }
        }
      }

      await mergeTable('user_dexes', ['id'], cloudData['user_dexes'] as List?);
      await mergeTable('folders', ['id'], cloudData['folders'] as List?);
      await mergeTable('folder_structure', [
        'parent_id',
        'child_id',
      ], cloudData['folder_structure'] as List?);
      await mergeTable('user_pokemon', [
        'dex_id',
        'unique_id',
      ], cloudData['user_pokemon'] as List?);
    });
  }
}
