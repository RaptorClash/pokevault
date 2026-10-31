import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/services/dao/user_dex_dao.dart';
import 'package:pokevault/services/dao/database_migrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late UserDexDao userDexDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 13,
        onCreate: DatabaseMigrator.createUserDataTables,
      ),
    );
    userDexDao = UserDexDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserDexDao Isolated Tests (TDD)', () {
    test('saveUserDex and getAllUserDexes persists and retrieves dexes with pokemon status', () async {
      final dex = UserDex(
        id: 'dex-1',
        title: 'Kanto Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      await userDexDao.saveUserDex(dex);

      await userDexDao.savePokemonStatus(
        'dex-1',
        '25',
        isCaught: true,
        isShiny: true,
        isAlpha: false,
        ribbons: ['champion_kalos'],
        teraTypes: ['electric'],
        languages: ['de', 'en'],
      );

      final dexes = await userDexDao.getAllUserDexes();
      expect(dexes.length, equals(1));
      final loaded = dexes.first;
      expect(loaded.id, equals('dex-1'));
      expect(loaded.title, equals('Kanto Living Dex'));
      expect(loaded.caughtIds.contains('25'), isTrue);
      expect(loaded.shinyIds.contains('25'), isTrue);
      expect(loaded.caughtRibbons['25'], equals(['champion_kalos']));
      expect(loaded.caughtTeraTypes['25'], equals(['electric']));
      expect(loaded.caughtLanguages['25'], equals(['de', 'en']));
    });

    test('deleteUserDex performs soft delete and unlinks folder structure', () async {
      final dex = UserDex(
        id: 'dex-del',
        title: 'To Delete',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await userDexDao.saveUserDex(dex);
      expect((await userDexDao.getAllUserDexes()).length, equals(1));

      await userDexDao.deleteUserDex('dex-del');
      expect((await userDexDao.getAllUserDexes()).length, equals(0));
    });

    test('cleanupOrphanedPokemon deletes removed custom form unique IDs', () async {
      final dex = UserDex(
        id: 'dex-orphan',
        title: 'Orphan Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await userDexDao.saveUserDex(dex);

      // Save valid and orphan unique IDs
      await userDexDao.savePokemonStatus('dex-orphan', '25', isCaught: true);
      await userDexDao.savePokemonStatus('dex-orphan', '25__form_custom_old', isCaught: true);
      await userDexDao.savePokemonStatus('dex-orphan', '25__form_custom_active', isCaught: true);

      final deleted = await userDexDao.cleanupOrphanedPokemon(
        'dex-orphan',
        {'25', '25__form_custom_active'},
      );

      expect(deleted, equals(1));

      final loaded = (await userDexDao.getAllUserDexes()).first;
      expect(loaded.caughtIds.contains('25'), isTrue);
      expect(loaded.caughtIds.contains('25__form_custom_active'), isTrue);
      expect(loaded.caughtIds.contains('25__form_custom_old'), isFalse);
    });

    test('Folder CRUD and Structure management works as expected', () async {
      final folder = DexFolder(
        id: 'folder-1',
        title: 'Gen 1 Folders',
      );
      await userDexDao.saveFolder(folder);

      final folders = await userDexDao.getAllFolders();
      expect(folders.length, equals(1));
      expect(folders.first.title, equals('Gen 1 Folders'));

      await userDexDao.saveStructure({
        'root': ['folder-1'],
        'folder-1': ['dex-1', 'dex-2'],
      });

      final struct = await userDexDao.getStructure();
      expect(struct['root'], equals(['folder-1']));
      expect(struct['folder-1'], equals(['dex-1', 'dex-2']));

      // Delete non-recursive moves children to root
      await userDexDao.deleteFolder('folder-1', recursive: false);
      final foldersAfter = await userDexDao.getAllFolders();
      expect(foldersAfter, isEmpty);

      final structAfter = await userDexDao.getStructure();
      expect(structAfter['root']?.contains('dex-1'), isTrue);
      expect(structAfter['root']?.contains('dex-2'), isTrue);
    });

    test('clearUserData deletes all user table contents', () async {
      await userDexDao.saveUserDex(UserDex(
        id: 'd-1',
        title: 'D1',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      ));
      await userDexDao.saveFolder(DexFolder(id: 'f-1', title: 'F1'));

      await userDexDao.clearUserData();

      expect(await userDexDao.getAllUserDexes(), isEmpty);
      expect(await userDexDao.getAllFolders(), isEmpty);
    });
  });
}
