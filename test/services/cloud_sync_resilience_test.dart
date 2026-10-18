import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/google_drive_sync_service.dart';
import 'package:pokevault/services/database_path_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pokevault_sync_test_');
    dbPath = p.join(tempDir.path, 'test_user_data.sqlite');
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

  group('Cloud Sync Import Resilience (mergeCloudSyncData)', () {
    test('Tolerates future tables and unknown columns without SQL crashes', () async {
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 10,
          onCreate: DatabaseService.createUserDataTables,
        ),
      );
      DatabaseService.setUserDatabaseForTesting(db);

      final cloudPayload = <String, dynamic>{
        'format_version': 2,
        // Known table with unknown column 'future_column_x'
        'user_dexes': [
          {
            'id': 'dex_cloud_1',
            'title': 'Cloud Dex',
            'region': 'kanto',
            'future_column_x': 'some_new_feature_value',
            'updated_at': 2000,
            'deleted_at': 0,
          }
        ],
        // Known table with unknown column 'radar_odds'
        'shiny_hunts': [
          {
            'id': 'hunt_cloud_1',
            'title': 'Pikachu Hunt',
            'pokemon_id': 25,
            'radar_odds': 4096.0,
            'updated_at': 2000,
            'deleted_at': 0,
          }
        ],
        // Completely unknown future table from v1.5.0
        'future_battle_stats': [
          {
            'id': 'battle_1',
            'wins': 42,
          }
        ],
      };

      // Calling mergeCloudSyncData must succeed and not throw sqlite column errors
      await expectLater(
        DatabaseService.instance.mergeCloudSyncData(cloudPayload),
        completes,
      );

      final dexRows = await db.query('user_dexes', where: 'id = ?', whereArgs: ['dex_cloud_1']);
      expect(dexRows.length, equals(1));
      expect(dexRows.first['title'], equals('Cloud Dex'));

      final huntRows = await db.query('shiny_hunts', where: 'id = ?', whereArgs: ['hunt_cloud_1']);
      expect(huntRows.length, equals(1));
      expect(huntRows.first['title'], equals('Pikachu Hunt'));
    });
  });

  group('Field-Level Patch Merge for Cloud Upload (mergeForUpload)', () {
    test('Preserves unknown future tables and preserves unknown fields in modified items', () {
      final existingCloudData = <String, dynamic>{
        'format_version': 3,
        // Unknown future table from Android v1.5.0
        'future_player_badges': [
          {'id': 'badge_1', 'tier': 'gold', 'updated_at': 500}
        ],
        // Known table with future column 'hunting_streak'
        'shiny_hunts': [
          {
            'id': 'hunt_1',
            'title': 'Old Title',
            'pokemon_id': 1,
            'hunting_streak': 15,
            'updated_at': 1000,
          },
          {
            'id': 'hunt_2',
            'title': 'Untouched Hunt',
            'pokemon_id': 4,
            'updated_at': 1500,
          }
        ],
      };

      // Local older client (e.g. Windows v1.4.0) only knows standard columns and changed hunt_1's title
      final localExportData = <String, dynamic>{
        'format_version': 2,
        'shiny_hunts': [
          {
            'id': 'hunt_1',
            'title': 'Patched By Older Client',
            'pokemon_id': 1,
            'updated_at': 2000, // Newer than remote 1000
          },
          {
            'id': 'hunt_3_new',
            'title': 'Brand New Local Hunt',
            'pokemon_id': 7,
            'updated_at': 2000,
          }
        ],
        'folders': <Map<String, dynamic>>[],
        'folder_structure': <Map<String, dynamic>>[],
        'user_dexes': <Map<String, dynamic>>[],
        'user_pokemon': <Map<String, dynamic>>[],
      };

      final merged = GoogleDriveSyncService.mergeForUpload(localExportData, existingCloudData);

      // 1. Future table is preserved
      expect(merged.containsKey('future_player_badges'), isTrue);
      expect((merged['future_player_badges'] as List).length, equals(1));
      expect((merged['future_player_badges'] as List).first['tier'], equals('gold'));

      // 2. Format version preserves max
      expect(merged['format_version'], equals(3));

      // 3. hunt_1 has updated title AND preserved 'hunting_streak'
      final hunts = (merged['shiny_hunts'] as List).cast<Map<String, dynamic>>();
      final hunt1 = hunts.firstWhere((h) => h['id'] == 'hunt_1');
      expect(hunt1['title'], equals('Patched By Older Client'));
      expect(hunt1['hunting_streak'], equals(15), reason: 'Future column must NOT be wiped on upload');
      expect(hunt1['updated_at'], equals(2000));

      // 4. Remote untouched item hunt_2 is preserved
      expect(hunts.any((h) => h['id'] == 'hunt_2'), isTrue);

      // 5. New local item hunt_3_new is included
      expect(hunts.any((h) => h['id'] == 'hunt_3_new'), isTrue);
    });

    test('Correctly matches composite primary keys for user_pokemon and folder_structure', () {
      final existingCloudData = <String, dynamic>{
        'format_version': 2,
        'user_pokemon': [
          {
            'dex_id': 'd1',
            'unique_id': 'u1',
            'is_caught': 1,
            'future_evs': '252,0,252,0,4,0',
            'updated_at': 1000,
          }
        ],
        'folder_structure': [
          {
            'parent_id': 'f1',
            'child_id': 'd1',
            'order_index': 0,
            'future_icon': 'star',
            'updated_at': 1000,
          }
        ]
      };

      final localExportData = <String, dynamic>{
        'format_version': 2,
        'user_pokemon': [
          {
            'dex_id': 'd1',
            'unique_id': 'u1',
            'is_caught': 1,
            'is_shiny': 1, // Marked shiny locally
            'updated_at': 2000,
          }
        ],
        'folder_structure': [
          {
            'parent_id': 'f1',
            'child_id': 'd1',
            'order_index': 5, // Reordered locally
            'updated_at': 2000,
          }
        ],
      };

      final merged = GoogleDriveSyncService.mergeForUpload(localExportData, existingCloudData);

      final pokes = (merged['user_pokemon'] as List).cast<Map<String, dynamic>>();
      expect(pokes.length, equals(1));
      expect(pokes.first['is_shiny'], equals(1));
      expect(pokes.first['future_evs'], equals('252,0,252,0,4,0'), reason: 'Future composite PK field preserved');

      final structure = (merged['folder_structure'] as List).cast<Map<String, dynamic>>();
      expect(structure.length, equals(1));
      expect(structure.first['order_index'], equals(5));
      expect(structure.first['future_icon'], equals('star'), reason: 'Future composite PK field preserved');
    });
  });
}
