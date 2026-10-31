import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/dao/cloud_sync_dao.dart';
import 'package:pokevault/services/dao/user_dex_dao.dart';
import 'package:pokevault/services/dao/database_migrator.dart';
import 'package:pokevault/models/user_dex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late CloudSyncDao cloudSyncDao;
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
    cloudSyncDao = CloudSyncDao(() async => db);
    userDexDao = UserDexDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CloudSyncDao Isolated Tests (TDD)', () {
    test('exportCloudSyncData exports all user data tables with format_version 2', () async {
      final dex = UserDex(
        id: 'dex-cloud-1',
        title: 'Cloud Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await userDexDao.saveUserDex(dex);

      final exported = await cloudSyncDao.exportCloudSyncData();

      expect(exported['format_version'], equals(2));
      expect(exported['user_dexes'], isA<List>());
      expect((exported['user_dexes'] as List).length, equals(1));
      expect(exported['folders'], isA<List>());
      expect(exported['folder_structure'], isA<List>());
      expect(exported['user_pokemon'], isA<List>());
      expect(exported['shiny_hunts'], isA<List>());
    });

    test('mergeCloudSyncData safely imports remote rows, updates newer records, and ignores unknown columns', () async {
      // 1. Initial local record
      final initialDex = UserDex(
        id: 'dex-cloud-merge',
        title: 'Initial Title',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      await userDexDao.saveUserDex(initialDex);

      // 2. Prepare incoming cloud payload with unknown column and unknown table
      final remotePayload = <String, dynamic>{
        'format_version': 2,
        'user_dexes': [
          {
            'id': 'dex-cloud-merge',
            'title': 'Updated Remote Title',
            'region': 'kanto',
            'include_genders': 0,
            'include_regional': 0,
            'include_mega': 0,
            'include_gmax': 0,
            'include_other': 0,
            'is_shiny_dex': 0,
            'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch + 10000,
            'deleted_at': 0,
            'future_column_should_be_ignored': 'some_val',
          },
          {
            'id': 'dex-brand-new',
            'title': 'Brand New Dex',
            'region': 'johto',
            'include_genders': 0,
            'include_regional': 0,
            'include_mega': 0,
            'include_gmax': 0,
            'include_other': 0,
            'is_shiny_dex': 0,
            'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
            'deleted_at': 0,
          }
        ],
        'future_table_does_not_exist': [
          {'id': 'foo', 'data': 'bar'}
        ],
      };

      await cloudSyncDao.mergeCloudSyncData(remotePayload);

      final dexes = await userDexDao.getAllUserDexes();
      expect(dexes.length, equals(2));

      final updated = dexes.firstWhere((d) => d.id == 'dex-cloud-merge');
      expect(updated.title, equals('Updated Remote Title'));

      final brandNew = dexes.firstWhere((d) => d.id == 'dex-brand-new');
      expect(brandNew.title, equals('Brand New Dex'));
    });
  });
}
