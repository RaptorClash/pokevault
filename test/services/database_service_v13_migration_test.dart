import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/database_path_helper.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pokevault_v13_test_');
    dbPath = p.join(tempDir.path, 'user_data.sqlite');
    DatabasePathHelper.overrideCurrentDirectory = tempDir;
    DatabasePathHelper.overrideIsDesktop = true;
  });

  tearDown(() {
    DatabaseService.setUserDatabaseForTesting(null);
    DatabasePathHelper.resetOverrides();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('DatabaseService V13 Migration Tests', () {
    test('Migrates database from version 12 to 13 adding include_glitch column with default 0', () async {
      // 1. Initialize a DB at version 12 with V12 schema (without include_glitch)
      final dbV12 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 12,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE user_dexes (
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
          },
        ),
      );

      // Verify include_glitch does not exist yet in V12
      var tableInfo = await dbV12.rawQuery("PRAGMA table_info('user_dexes')");
      bool hasGlitchColV12 = tableInfo.any((c) => c['name'] == 'include_glitch');
      expect(hasGlitchColV12, isFalse);

      // Insert a dex in V12
      await dbV12.insert('user_dexes', {
        'id': 'dex_v12_test',
        'title': 'V12 Test Dex',
        'region': 'kanto',
        'include_genders': 0,
        'include_regional': 0,
        'include_mega': 0,
        'include_gmax': 0,
        'include_other': 0,
        'include_trades': 0,
        'include_gifts': 0,
        'is_shiny_dex': 0,
      });
      await dbV12.close();

      // 2. Open DB via DatabaseService (which runs version 13 upgrade)
      final dbV13 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 13,
          onCreate: DatabaseService.createUserDataTables,
          onUpgrade: DatabaseService.upgradeUserDataTables,
        ),
      );

      tableInfo = await dbV13.rawQuery("PRAGMA table_info('user_dexes')");
      bool hasGlitchColV13 = tableInfo.any((c) => c['name'] == 'include_glitch');
      expect(hasGlitchColV13, isTrue, reason: 'Migration V13 must add include_glitch column');

      final dexRows = await dbV13.query('user_dexes', where: 'id = ?', whereArgs: ['dex_v12_test']);
      expect(dexRows.isNotEmpty, isTrue);
      expect(dexRows.first['include_glitch'], equals(0));
      await dbV13.close();
    });
  });
}
