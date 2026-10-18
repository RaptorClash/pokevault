import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/models/shiny_hunt.dart';
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
    tempDir = Directory.systemTemp.createTempSync('pokevault_db_hunt_test_');
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

  test('Save and retrieve shiny hunt with float baseOdds and phase history', () async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-123',
      title: 'Togepi Odd Egg Hunt',
      pokemonId: 175,
      pokemonName: 'Togepi',
      game: 'Kristall',
      generation: 2.0,
      method: 'Kurioses Ei',
      baseOdds: 7.142857,
      spawnsPerEncounter: 1,
      currentEncounters: 4,
      priorPhaseEncounters: 12,
      phase: 2,
      phaseHistory: [
        ShinyPhaseEntry(
          phaseNumber: 1,
          encounters: 12,
          caughtPokemonId: 239,
          caughtPokemonName: 'Elekid',
          completedAt: now.subtract(const Duration(hours: 2)),
        ),
      ],
      createdAt: now,
      updatedAt: now,
      notes: 'Testing float odds and phase tracking',
    );

    await DatabaseService.instance.saveShinyHunt(hunt);

    final retrieved = await DatabaseService.instance.getShinyHunt('hunt-123');
    expect(retrieved, isNotNull);
    expect(retrieved!.id, equals('hunt-123'));
    expect(retrieved.title, equals('Togepi Odd Egg Hunt'));
    expect(retrieved.pokemonId, equals(175));
    expect(retrieved.pokemonName, equals('Togepi'));
    expect(retrieved.baseOdds, closeTo(7.142857, 1e-6));
    expect(retrieved.currentEncounters, equals(4));
    expect(retrieved.priorPhaseEncounters, equals(12));
    expect(retrieved.totalEncounters, equals(16));
    expect(retrieved.totalRolls, equals(16));
    expect(retrieved.phase, equals(2));
    expect(retrieved.phaseHistory.length, equals(1));
    expect(retrieved.phaseHistory.first.caughtPokemonName, equals('Elekid'));
    expect(retrieved.phaseHistory.first.encounters, equals(12));

    final allHunts = await DatabaseService.instance.getAllShinyHunts();
    expect(allHunts.any((h) => h.id == 'hunt-123'), isTrue);
  });

  test('Soft delete excludes hunt from getAllShinyHunts unless includeDeleted: true', () async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-to-delete',
      title: 'Charmander SR',
      pokemonId: 4,
      pokemonName: 'Glumanda',
      game: 'FireRed',
      generation: 3.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.instance.saveShinyHunt(hunt);
    expect((await DatabaseService.instance.getAllShinyHunts()).length, equals(1));

    await DatabaseService.instance.deleteShinyHunt('hunt-to-delete', softDelete: true);
    expect((await DatabaseService.instance.getAllShinyHunts()).length, equals(0));

    final withDeleted = await DatabaseService.instance.getAllShinyHunts(includeDeleted: true);
    expect(withDeleted.length, equals(1));
    expect(withDeleted.first.deletedAt, greaterThan(0));
  });

  test('Hard delete completely removes hunt from database', () async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-hard-delete',
      title: 'Bulbasaur',
      pokemonId: 1,
      pokemonName: 'Bisasam',
      game: 'FireRed',
      generation: 3.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.instance.saveShinyHunt(hunt);
    await DatabaseService.instance.deleteShinyHunt('hunt-hard-delete', softDelete: false);

    final retrieved = await DatabaseService.instance.getShinyHunt('hunt-hard-delete');
    expect(retrieved, isNull);
    expect((await DatabaseService.instance.getAllShinyHunts(includeDeleted: true)).isEmpty, isTrue);
  });

  test('clearUserData deletes shiny_hunts', () async {
    final now = DateTime.now();
    await DatabaseService.instance.saveShinyHunt(ShinyHunt(
      id: 'hunt-clear',
      title: 'Pikachu',
      pokemonId: 25,
      pokemonName: 'Pikachu',
      game: 'Emerald',
      generation: 3.0,
      method: 'Wild',
      baseOdds: 8192.0,
      createdAt: now,
      updatedAt: now,
    ));

    expect((await DatabaseService.instance.getAllShinyHunts()).length, equals(1));
    await DatabaseService.instance.clearUserData();
    expect((await DatabaseService.instance.getAllShinyHunts(includeDeleted: true)).isEmpty, isTrue);
  });

  test('exportCloudSyncData and mergeCloudSyncData syncs shiny_hunts', () async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'sync-hunt-1',
      title: 'Rayquaza SR',
      pokemonId: 384,
      pokemonName: 'Rayquaza',
      game: 'Emerald',
      generation: 3.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      currentEncounters: 1500,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseService.instance.saveShinyHunt(hunt);

    final exported = await DatabaseService.instance.exportCloudSyncData();
    expect(exported.containsKey('shiny_hunts'), isTrue);
    final rawHunts = exported['shiny_hunts'] as List;
    expect(rawHunts.length, equals(1));

    // Clear local data
    await DatabaseService.instance.clearUserData();
    expect((await DatabaseService.instance.getAllShinyHunts()).isEmpty, isTrue);

    // Merge cloud data back
    await DatabaseService.instance.mergeCloudSyncData(exported);
    final restoredHunts = await DatabaseService.instance.getAllShinyHunts();
    expect(restoredHunts.length, equals(1));
    expect(restoredHunts.first.id, equals('sync-hunt-1'));
    expect(restoredHunts.first.currentEncounters, equals(1500));
  });
}
