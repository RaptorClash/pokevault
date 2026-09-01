import 'dart:convert';
import 'dart:io';
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
      options: OpenDatabaseOptions(version: 1, onCreate: _createUserDataTables),
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
          is_shiny_dex INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folders (
          id TEXT PRIMARY KEY,
          title TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folder_structure (
          parent_id TEXT,
          child_id TEXT,
          order_index INTEGER,
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
          PRIMARY KEY (dex_id, unique_id)
        )
      ''');
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error_db_create')} $e');
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
    final dexMaps = await db.query('user_dexes');
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
    await db.insert(
      'user_dexes',
      dex.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteUserDex(String dexId) async {
    final db = await instance.userDatabase;
    await db.delete('user_dexes', where: 'id = ?', whereArgs: [dexId]);
    await db.delete('user_pokemon', where: 'dex_id = ?', whereArgs: [dexId]);
    await db.delete(
      'folder_structure',
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DexFolder>> getAllFolders() async {
    final db = await instance.userDatabase;
    final maps = await db.query('folders');
    return maps.map((m) => DexFolder.fromMap(m)).toList();
  }

  Future<void> saveFolder(DexFolder folder) async {
    final db = await instance.userDatabase;
    await db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFolder(String folderId) async {
    final db = await instance.userDatabase;
    await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
    await db.delete(
      'folder_structure',
      where: 'parent_id = ? OR child_id = ?',
      whereArgs: [folderId, folderId],
    );
  }

  Future<Map<String, List<String>>> getStructure() async {
    final db = await instance.userDatabase;
    final maps = await db.query('folder_structure', orderBy: 'order_index ASC');
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
    await db.delete('folder_structure');
    Batch batch = db.batch();

    structure.forEach((parentId, children) {
      for (int i = 0; i < children.length; i++) {
        batch.insert('folder_structure', {
          'parent_id': parentId,
          'child_id': children[i],
          'order_index': i,
        });
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
}
