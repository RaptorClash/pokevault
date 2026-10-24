import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/shiny_hunt_timeline_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('pokevault_shiny_pause_tdd_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    await DatabaseService.instance.clearUserData();
  });

  group('TDD: Shiny Hunt Timestamps & Pause Tracking Tests', () {
    test('1. ShinyPauseInterval model serializes, deserializes, and computes duration', () {
      final t1 = DateTime(2026, 10, 24, 14, 0, 0);
      final t2 = DateTime(2026, 10, 24, 14, 45, 0);

      final interval = ShinyPauseInterval(pausedAt: t1, resumedAt: t2);
      expect(interval.duration, equals(const Duration(minutes: 45)));

      final map = interval.toMap();
      expect(map['paused_at'], equals(t1.millisecondsSinceEpoch));
      expect(map['resumed_at'], equals(t2.millisecondsSinceEpoch));

      final restored = ShinyPauseInterval.fromMap(map);
      expect(restored.pausedAt.millisecondsSinceEpoch, equals(t1.millisecondsSinceEpoch));
      expect(restored.resumedAt?.millisecondsSinceEpoch, equals(t2.millisecondsSinceEpoch));
      expect(restored.duration, equals(const Duration(minutes: 45)));

      // Active ongoing pause (resumedAt == null)
      final ongoing = ShinyPauseInterval(pausedAt: t1);
      expect(ongoing.resumedAt, isNull);
      expect(ongoing.duration, isNull);

      final ongoingMap = ongoing.toMap();
      expect(ongoingMap['resumed_at'], isNull);
      final restoredOngoing = ShinyPauseInterval.fromMap(ongoingMap);
      expect(restoredOngoing.resumedAt, isNull);
    });

    test('2. ShinyHunt model stores createdAt, completedAt, and pauseHistory with JSON persistence', () {
      final start = DateTime(2026, 10, 24, 10, 0, 0);
      final pause1 = DateTime(2026, 10, 24, 11, 0, 0);
      final resume1 = DateTime(2026, 10, 24, 11, 30, 0);
      final finished = DateTime(2026, 10, 24, 15, 0, 0);

      final hunt = ShinyHunt(
        id: 'hunt-timestamps-1',
        title: 'Mewtu Hunt',
        pokemonId: 150,
        pokemonName: 'Mewtu',
        game: 'FireRed',
        generation: 3.0,
        method: 'Soft Reset',
        baseOdds: 8192.0,
        createdAt: start,
        updatedAt: start,
        completedAt: finished,
        pauseHistory: [
          ShinyPauseInterval(pausedAt: pause1, resumedAt: resume1),
        ],
      );

      final map = hunt.toMap();
      expect(map['created_at'], equals(start.millisecondsSinceEpoch));
      expect(map['completed_at'], equals(finished.millisecondsSinceEpoch));
      expect(map['pause_history'], isA<String>());

      final restored = ShinyHunt.fromMap(map);
      expect(restored.createdAt.millisecondsSinceEpoch, equals(start.millisecondsSinceEpoch));
      expect(restored.completedAt?.millisecondsSinceEpoch, equals(finished.millisecondsSinceEpoch));
      expect(restored.pauseHistory.length, equals(1));
      expect(restored.pauseHistory.first.pausedAt.millisecondsSinceEpoch, equals(pause1.millisecondsSinceEpoch));
      expect(restored.pauseHistory.first.resumedAt?.millisecondsSinceEpoch, equals(resume1.millisecondsSinceEpoch));
      expect(restored.pauseHistory.first.duration, equals(const Duration(minutes: 30)));
    });

    test('3. ShinyHuntProvider pauseHunt, resumeHunt, and increment tracking history', () async {
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;

      final start = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-pause-test-1',
        title: 'Rayquaza Hunt',
        pokemonId: 384,
        pokemonName: 'Rayquaza',
        game: 'Emerald',
        generation: 3.0,
        method: 'Soft Reset',
        baseOdds: 8192.0,
        createdAt: start,
        updatedAt: start,
      );
      await provider.createHunt(hunt);

      expect(hunt.pauseHistory, isEmpty);
      expect(hunt.isActive, isTrue);

      // 1. Pause the hunt
      await provider.pauseHunt(hunt.id);
      expect(hunt.isPaused, isTrue);
      expect(hunt.pauseHistory.length, equals(1));
      expect(hunt.pauseHistory.first.resumedAt, isNull, reason: 'Active pause has null resumedAt');

      // 2. Resume the hunt
      await provider.resumeHunt(hunt.id);
      expect(hunt.isActive, isTrue);
      expect(hunt.pauseHistory.length, equals(1));
      expect(hunt.pauseHistory.first.resumedAt, isNotNull, reason: 'Resumed pause has non-null resumedAt');

      // 3. Pause again and resume via encounter increment
      await provider.pauseHunt(hunt.id);
      expect(hunt.isPaused, isTrue);
      expect(hunt.pauseHistory.length, equals(2));
      expect(hunt.pauseHistory.last.resumedAt, isNull);

      provider.increment(hunt.id);
      expect(hunt.isActive, isTrue);
      expect(hunt.pauseHistory.last.resumedAt, isNotNull, reason: 'Incrementing should resume and close interval');

      // 4. Complete the hunt
      await provider.completeHunt(hunt.id, ballUsed: 'master-ball');
      expect(hunt.isCompleted, isTrue);
      expect(hunt.completedAt, isNotNull);

      provider.dispose();
    });

    test('4. Paused hunt completed directly closes open pause interval', () async {
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;

      final start = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-pause-test-2',
        title: 'Kyogre Hunt',
        pokemonId: 382,
        pokemonName: 'Kyogre',
        game: 'Sapphire',
        generation: 3.0,
        method: 'Soft Reset',
        baseOdds: 8192.0,
        createdAt: start,
        updatedAt: start,
      );
      await provider.createHunt(hunt);

      await provider.pauseHunt(hunt.id);
      expect(hunt.pauseHistory.last.resumedAt, isNull);

      await provider.completeHunt(hunt.id);
      expect(hunt.isCompleted, isTrue);
      expect(hunt.pauseHistory.last.resumedAt, isNotNull, reason: 'Completing hunt while paused must close pause interval');

      provider.dispose();
    });

    test('5. SQLite full round-trip preserves pause history and timestamps', () async {
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;

      final start = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-sqlite-roundtrip',
        title: 'Groudon Hunt',
        pokemonId: 383,
        pokemonName: 'Groudon',
        game: 'Ruby',
        generation: 3.0,
        method: 'Soft Reset',
        baseOdds: 8192.0,
        createdAt: start,
        updatedAt: start,
      );
      await provider.createHunt(hunt);

      await provider.pauseHunt(hunt.id);
      await provider.resumeHunt(hunt.id);
      await provider.completeHunt(hunt.id, ballUsed: 'ultra-ball');

      // Reload fresh from SQLite
      final loadedHunts = await DatabaseService.instance.getAllShinyHunts();
      final loaded = loadedHunts.firstWhere((h) => h.id == hunt.id);

      expect(loaded.createdAt.millisecondsSinceEpoch, equals(start.millisecondsSinceEpoch));
      expect(loaded.completedAt, isNotNull);
      expect(loaded.pauseHistory.length, equals(1));
      expect(loaded.pauseHistory.first.resumedAt, isNotNull);

      provider.dispose();
    });

    test('6. Clock skew protection: resumedAt before pausedAt clamps duration to Duration.zero', () {
      final t1 = DateTime(2026, 10, 24, 15, 0, 0);
      final t2 = DateTime(2026, 10, 24, 14, 0, 0); // Clock moved backwards by 1 hour

      final interval = ShinyPauseInterval(pausedAt: t1, resumedAt: t2);
      expect(interval.duration, equals(Duration.zero),
          reason: 'Duration must never be negative even if system time changed backwards');
    });

    test('7. Multi-day pause interval formatting in ShinyHuntTimelineDialog includes resume date', () {
      final p = DateTime(2026, 10, 20, 22, 15);
      final r = DateTime(2026, 10, 21, 8, 30);
      final interval = ShinyPauseInterval(pausedAt: p, resumedAt: r);

      final formatted = ShinyHuntTimelineDialog.formatPauseIntervalRange(interval);
      // Expected: "20.10. 22:15 - 21.10. 08:30 Uhr"
      expect(formatted, contains('21.10.'),
          reason: 'When pause spans to another day, resume date must be explicitly shown');
      expect(formatted, contains('20.10.'));
      expect(formatted, contains('22:15'));
      expect(formatted, contains('08:30'));
    });
  });
}
