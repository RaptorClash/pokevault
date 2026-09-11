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
import 'package:shared_preferences/shared_preferences.dart';
import '../models/special_dex_models.dart';
import '../models/ribbon.dart';

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

  static const int _currentAppDbVersion = 14;

  Future<Database> _initAppDB(String fileName) async {
    String path = fileName;
    DatabaseFactory factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;

    if (!kIsWeb) {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, fileName);
    }

    final prefs = await SharedPreferences.getInstance();
    final int storedDbVersion = prefs.getInt('app_db_version') ?? 0;
    bool dbExists = await factory.databaseExists(path);

    if (!dbExists || storedDbVersion < _currentAppDbVersion) {
      try {
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
        version: 5,
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
          is_alpha INTEGER DEFAULT 0,
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
    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE user_pokemon ADD COLUMN caught_ribbons TEXT DEFAULT ''",
        );
        await db.execute(
          "ALTER TABLE user_pokemon ADD COLUMN caught_tera_types TEXT DEFAULT ''",
        );
        debugPrint(
          "Datenbank erfolgreich auf Version 4 (Ribbons & Tera) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler V4: $e");
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          "ALTER TABLE user_pokemon ADD COLUMN is_alpha INTEGER DEFAULT 0",
        );
        debugPrint(
          "Datenbank erfolgreich auf Version 5 (Alpha Status) migriert!",
        );
      } catch (e) {
        debugPrint("Migrations-Fehler V5: $e");
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
        if ((p['is_alpha'] as num?)?.toInt() == 1) dex.alphaIds.add(uId);
        String rStr = p['caught_ribbons']?.toString() ?? '';
        if (rStr.isNotEmpty) dex.caughtRibbons[uId] = rStr.split(',');
        String tStr = p['caught_tera_types']?.toString() ?? '';
        if (tStr.isNotEmpty) dex.caughtTeraTypes[uId] = tStr.split(',');
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
    bool? isAlpha,
    List<String>? ribbons,
    List<String>? teraTypes,
  }) async {
    final db = await instance.userDatabase;
    final maps = await db.query(
      'user_pokemon',
      where: 'dex_id = ? AND unique_id = ?',
      whereArgs: [dexId, uniqueId],
    );
    int caught = 0, shiny = 0, ignored = 0, alpha = 0;
    String r = '', t = '';

    if (maps.isNotEmpty) {
      caught = (maps.first['is_caught'] as num?)?.toInt() ?? 0;
      shiny = (maps.first['is_shiny'] as num?)?.toInt() ?? 0;
      ignored = (maps.first['is_ignored'] as num?)?.toInt() ?? 0;
      alpha = (maps.first['is_alpha'] as num?)?.toInt() ?? 0;
      r = maps.first['caught_ribbons']?.toString() ?? '';
      t = maps.first['caught_tera_types']?.toString() ?? '';
    }
    if (isCaught != null) caught = isCaught ? 1 : 0;
    if (isShiny != null) shiny = isShiny ? 1 : 0;
    if (isIgnored != null) ignored = isIgnored ? 1 : 0;
    if (isAlpha != null) alpha = isAlpha ? 1 : 0;
    if (ribbons != null) r = ribbons.join(',');
    if (teraTypes != null) t = teraTypes.join(',');
    await db.insert('user_pokemon', {
      'dex_id': dexId,
      'unique_id': uniqueId,
      'is_caught': caught,
      'is_shiny': shiny,
      'is_ignored': ignored,
      'is_alpha': alpha,
      'caught_ribbons': r,
      'caught_tera_types': t,
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
}
