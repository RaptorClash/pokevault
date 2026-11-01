import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../utils/notification_helper.dart';
import '../i18n/strings.g.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/special_dex_models.dart';
import '../models/ribbon.dart';
import '../models/shiny_hunt.dart';
import 'database_path_helper.dart';
import 'dao/pokemon_dao.dart';
import 'dao/user_dex_dao.dart';
import 'dao/shiny_hunt_dao.dart';
import 'dao/cloud_sync_dao.dart';
import 'dao/database_migrator.dart';

/// Central database service providing access to the application's SQLite databases.
///
/// Implements a dual-database architecture delegating to focused DAOs:
/// - [pokemonDao]: Read-only queries and in-memory caches on `pokedex.sqlite`.
/// - [userDexDao]: CRUD operations for user dexes, folders, and pokemon caught states on `user_data.sqlite`.
/// - [shinyHuntDao]: CRUD operations for shiny hunts and phases on `user_data.sqlite`.
/// - [cloudSyncDao]: Cloud sync export and schema-resilient transactional merge on `user_data.sqlite`.
/// - [DatabaseMigrator]: Schema definitions, idempotent migrations, and indexes.
class DatabaseService {
  /// The singleton instance of [DatabaseService].
  static final DatabaseService instance = DatabaseService._init();
  static Database? _appDatabase;
  static Database? _userDatabase;
  static Future<void>? _migrationFuture;

  /// DAO for Pokémon reference data and in-memory caches.
  late final PokemonDao pokemonDao;

  /// DAO for user-created Dexes, folder hierarchies, and Pokémon tracking statuses.
  late final UserDexDao userDexDao;

  /// DAO for Shiny Hunt tracking.
  late final ShinyHuntDao shinyHuntDao;

  /// DAO for Cloud Sync export and transactional merge.
  late final CloudSyncDao cloudSyncDao;

  DatabaseService._init() {
    pokemonDao = PokemonDao(() => appDatabase);
    userDexDao = UserDexDao(() => userDatabase);
    shinyHuntDao = ShinyHuntDao(() => userDatabase);
    cloudSyncDao = CloudSyncDao(() => userDatabase);
  }

  /// Clears in-memory caches of static reference data in [pokemonDao].
  void clearMemoryCache() {
    pokemonDao.clearMemoryCache();
  }

  static Future<void> _ensureMigration() {
    _migrationFuture ??= DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();
    return _migrationFuture!;
  }

  @visibleForTesting
  static void resetMigrationForTesting() {
    _migrationFuture = null;
  }

  /// Returns the read-only application database (`pokedex.sqlite`).
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
  static const int currentAppDbVersion = 29;
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
        NotificationHelper.showError('${t.error_db_init} $e');
      }
    }

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onDowngrade: (db, oldVersion, newVersion) async {},
        onOpen: (db) async {
          // Use rawQuery for PRAGMA statements to avoid Android SQLiteDatabase execSQL query checks
          await db.rawQuery('PRAGMA busy_timeout = 30000;');
          await db.rawQuery('PRAGMA synchronous = NORMAL;');
          await db.rawQuery('PRAGMA temp_store = MEMORY;');
          await DatabaseMigrator.ensureAppDatabaseIndexes(db);
        },
      ),
    );
  }

  /// Returns the read-write user database (`user_data.sqlite`).
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
        await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE);');
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
        version: 13,
        onCreate: DatabaseMigrator.createUserDataTables,
        onUpgrade: DatabaseMigrator.upgradeUserDataTables,
        onDowngrade: DatabaseMigrator.downgradeUserDataTables,
        onOpen: (db) async {
          // Use rawQuery for PRAGMA statements to avoid Android SQLiteDatabase execSQL query checks
          await db.rawQuery('PRAGMA busy_timeout = 30000;');
          if (!kIsWeb) {
            await db.rawQuery('PRAGMA journal_mode = WAL;');
          }
          await db.rawQuery('PRAGMA synchronous = NORMAL;');
          await DatabaseMigrator.cleanOrphanedUserDataBeforeFk(db);
          await db.rawQuery('PRAGMA foreign_keys = ON;');
          await DatabaseMigrator.ensureUserDataIndexes(db);
        },
      ),
    );
  }

  // --- Static Migrator Forwarders for Backwards Compatibility ---

  /// Creates all core user data tables (`user_dexes`, `folders`, `folder_structure`, `user_pokemon`, `shiny_hunts`).
  static Future<void> createUserDataTables(Database db, int version) =>
      DatabaseMigrator.createUserDataTables(db, version);

  /// Adds a new column to [table] if it does not already exist.
  static Future<void> addColumnIfNotExists(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) =>
      DatabaseMigrator.addColumnIfNotExists(db, table, column, definition);

  /// Handles database downgrade scenarios non-destructively.
  static Future<void> downgradeUserDataTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) =>
      DatabaseMigrator.downgradeUserDataTables(db, oldVersion, newVersion);

  /// Ensures high-performance B-tree indexes are present on user data tables.
  static Future<void> ensureUserDataIndexes(DatabaseExecutor db) =>
      DatabaseMigrator.ensureUserDataIndexes(db);

  /// Ensures composite and lookup indexes are created on large static app database tables.
  static Future<void> ensureAppDatabaseIndexes(DatabaseExecutor db) =>
      DatabaseMigrator.ensureAppDatabaseIndexes(db);

  /// Upgrades user database schema sequentially across versions using idempotent alter table statements.
  static Future<void> upgradeUserDataTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) =>
      DatabaseMigrator.upgradeUserDataTables(db, oldVersion, newVersion);

  // --- PokemonDao Forwarders ---

  Future<List<Map<String, dynamic>>> getShinyLocks(int pokemonId) =>
      pokemonDao.getShinyLocks(pokemonId);

  Future<List<Map<String, dynamic>>> getAllShinyLocks() =>
      pokemonDao.getAllShinyLocks();

  Future<List<Pokemon>> getAllPokemon() => pokemonDao.getAllPokemon();

  Future<Map<String, List<int>>> getAllDexOrders() => pokemonDao.getAllDexOrders();

  Future<Map<String, String>> getBallUrls() => pokemonDao.getBallUrls();

  Future<Map<String, Map<String, List<String>>>?> getEncounters(int pokemonId) =>
      pokemonDao.getEncounters(pokemonId);

  Future<Map<String, dynamic>?> getEvolutionChain(int chainId) =>
      pokemonDao.getEvolutionChain(chainId);

  Future<Map<String, dynamic>?> getMatchingBalls(String uniqueId) =>
      pokemonDao.getMatchingBalls(uniqueId);

  Future<List<int>?> getGen1BaseStats(int pokemonId) =>
      pokemonDao.getGen1BaseStats(pokemonId);

  Future<Map<int, Map<String, dynamic>>> getGen12PreEvolutions() =>
      pokemonDao.getGen12PreEvolutions();

  Future<int> getDefaultLevel(int pokemonId) =>
      pokemonDao.getDefaultLevel(pokemonId);

  Future<List<String>> getShinyCategories(int pokemonId) =>
      pokemonDao.getShinyCategories(pokemonId);

  Future<List<PokeAbility>> getAllAbilities() => pokemonDao.getAllAbilities();

  Future<List<PokeMove>> getAllMoves() => pokemonDao.getAllMoves();

  Future<List<PokemonLearnset>> getPokemonForMove(int moveId) =>
      pokemonDao.getPokemonForMove(moveId);

  Future<List<PokemonLearnset>> getPokemonForAbility(int abilityId) =>
      pokemonDao.getPokemonForAbility(abilityId);

  Future<List<Ribbon>> getAllRibbons() => pokemonDao.getAllRibbons();

  Future<List<String>> getAvailableVersionGroups(int pokemonId) =>
      pokemonDao.getAvailableVersionGroups(pokemonId);

  Future<int> getBasePokemonId(int chainId) =>
      pokemonDao.getBasePokemonId(chainId);

  Future<List<Map<String, dynamic>>> getSpecialObtainables() =>
      pokemonDao.getSpecialObtainables();

  Future<Map<String, String>?> getGenderDifference(int pokemonId) =>
      pokemonDao.getGenderDifference(pokemonId);

  // --- UserDexDao Forwarders ---

  Future<List<UserDex>> getAllUserDexes() => userDexDao.getAllUserDexes();

  Future<void> saveUserDex(UserDex dex) => userDexDao.saveUserDex(dex);

  Future<void> deleteUserDex(String dexId) => userDexDao.deleteUserDex(dexId);

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
  }) =>
      userDexDao.savePokemonStatus(
        dexId,
        uniqueId,
        isCaught: isCaught,
        isShiny: isShiny,
        isIgnored: isIgnored,
        isAlpha: isAlpha,
        ribbons: ribbons,
        teraTypes: teraTypes,
        languages: languages,
      );

  Future<int> cleanupOrphanedPokemon(
    String dexId,
    Set<String> activeUniqueIds,
  ) =>
      userDexDao.cleanupOrphanedPokemon(dexId, activeUniqueIds);

  Future<List<DexFolder>> getAllFolders() => userDexDao.getAllFolders();

  Future<void> saveFolder(DexFolder folder) => userDexDao.saveFolder(folder);

  Future<void> deleteFolder(String folderId, {bool recursive = false}) =>
      userDexDao.deleteFolder(folderId, recursive: recursive);

  Future<Map<String, List<String>>> getStructure() => userDexDao.getStructure();

  Future<void> saveStructure(Map<String, List<String>> structure) =>
      userDexDao.saveStructure(structure);

  Future<void> clearUserData() => userDexDao.clearUserData();

  // --- ShinyHuntDao Forwarders ---

  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) =>
      shinyHuntDao.getAllShinyHunts(includeDeleted: includeDeleted);

  Future<ShinyHunt?> getShinyHunt(String id) => shinyHuntDao.getShinyHunt(id);

  Future<void> saveShinyHunt(ShinyHunt hunt) => shinyHuntDao.saveShinyHunt(hunt);

  Future<void> deleteShinyHunt(String id, {bool softDelete = true}) =>
      shinyHuntDao.deleteShinyHunt(id, softDelete: softDelete);

  // --- CloudSyncDao Forwarders ---

  Future<Map<String, dynamic>> exportCloudSyncData() =>
      cloudSyncDao.exportCloudSyncData();

  Future<void> mergeCloudSyncData(Map<String, dynamic> cloudData) =>
      cloudSyncDao.mergeCloudSyncData(cloudData);
}
