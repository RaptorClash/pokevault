import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
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
    tempDir = Directory.systemTemp.createTempSync('pokevault_provider_hunt_test_');
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

  test('ShinyHuntProvider increment and decrement adjust currentEncounters correctly', () async {
    final provider = ShinyHuntProvider(databaseService: DatabaseService.instance);
    await provider.initialized;
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-inc-test',
      title: 'Charmander',
      pokemonId: 4,
      pokemonName: 'Glumanda',
      game: 'FireRed',
      generation: 3.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      incrementStep: 1,
      createdAt: now,
      updatedAt: now,
    );

    await provider.createHunt(hunt);
    expect(provider.activeHunts.length, equals(1));

    provider.increment('hunt-inc-test');
    provider.increment('hunt-inc-test');
    provider.increment('hunt-inc-test');
    expect(provider.getHuntById('hunt-inc-test')!.currentEncounters, equals(3));

    provider.decrement('hunt-inc-test');
    expect(provider.getHuntById('hunt-inc-test')!.currentEncounters, equals(2));

    provider.setStep('hunt-inc-test', 5);
    provider.increment('hunt-inc-test');
    expect(provider.getHuntById('hunt-inc-test')!.currentEncounters, equals(7));

    provider.setManualCount('hunt-inc-test', 4000);
    expect(provider.getHuntById('hunt-inc-test')!.currentEncounters, equals(4000));

    // Mandatory flush saves to SQLite
    await provider.flushPendingWrites();
    final dbHunt = await DatabaseService.instance.getShinyHunt('hunt-inc-test');
    expect(dbHunt!.currentEncounters, equals(4000));

    provider.dispose();
  });

  test('Mandatory flush on dispose preserves in-flight debounced counts', () async {
    final provider = ShinyHuntProvider(databaseService: DatabaseService.instance);
    await provider.initialized;
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-flush-test',
      title: 'Squirtle',
      pokemonId: 7,
      pokemonName: 'Schiggy',
      game: 'LeafGreen',
      generation: 3.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      createdAt: now,
      updatedAt: now,
    );

    await provider.createHunt(hunt);
    provider.increment('hunt-flush-test');
    provider.increment('hunt-flush-test');

    // In-flight count is 2. Dispose should flush immediately without waiting 250ms
    await provider.flushPendingWrites();
    provider.dispose();

    final dbHunt = await DatabaseService.instance.getShinyHunt('hunt-flush-test');
    expect(dbHunt!.currentEncounters, equals(2));
  });

  test('recordPhaseShiny resets currentEncounters, increases priorPhaseEncounters and phase', () async {
    final provider = ShinyHuntProvider(databaseService: DatabaseService.instance);
    await provider.initialized;
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-phase-test',
      title: 'Safari Zone Scyther',
      pokemonId: 123,
      pokemonName: 'Sichlor',
      game: 'FireRed',
      generation: 3.0,
      method: 'Safari',
      baseOdds: 8192.0,
      currentEncounters: 350,
      phase: 1,
      createdAt: now,
      updatedAt: now,
    );

    await provider.createHunt(hunt);

    // Record phase shiny (e.g. found Nidorino instead of Sichlor)
    await provider.recordPhaseShiny(
      'hunt-phase-test',
      caughtPokemonId: 33,
      caughtPokemonName: 'Nidorino',
    );

    final updated = provider.getHuntById('hunt-phase-test')!;
    expect(updated.currentEncounters, equals(0));
    expect(updated.priorPhaseEncounters, equals(350));
    expect(updated.totalEncounters, equals(350));
    expect(updated.phase, equals(2));
    expect(updated.phaseHistory.length, equals(1));
    expect(updated.phaseHistory.first.phaseNumber, equals(1));
    expect(updated.phaseHistory.first.encounters, equals(350));
    expect(updated.phaseHistory.first.caughtPokemonName, equals('Nidorino'));

    // Check DB
    final fromDb = await DatabaseService.instance.getShinyHunt('hunt-phase-test');
    expect(fromDb!.phase, equals(2));
    expect(fromDb.priorPhaseEncounters, equals(350));
    expect(fromDb.currentEncounters, equals(0));
    expect(fromDb.phaseHistory.length, equals(1));

    provider.dispose();
  });

  test('completeHunt marks hunt completed and syncs to DexProvider', () async {
    final dex = UserDex(
      id: 'test_dex_complete',
      title: 'Kanto Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
    );
    await DatabaseService.instance.saveUserDex(dex);

    final dexProvider = DexProvider(databaseService: DatabaseService.instance);
    dexProvider.userDexes = [dex];

    final huntProvider = ShinyHuntProvider(databaseService: DatabaseService.instance);
    await huntProvider.initialized;
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-complete-test',
      title: 'Mewtwo SR',
      pokemonId: 150,
      pokemonName: 'Mewtu',
      game: 'FireRed',
      generation: 3.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      currentEncounters: 2400,
      createdAt: now,
      updatedAt: now,
    );

    await huntProvider.createHunt(hunt);

    await huntProvider.completeHunt(
      'hunt-complete-test',
      ballUsed: 'master_ball',
      targetDexId: 'test_dex_complete',
      targetUniqueId: '150',
      dexProvider: dexProvider,
      notes: 'Caught in Master Ball on attempt 2400!',
    );

    final finished = huntProvider.getHuntById('hunt-complete-test')!;
    expect(finished.isCompleted, isTrue);
    expect(finished.ballUsed, equals('master_ball'));
    expect(finished.completedAt, isNotNull);
    expect(finished.notes, contains('attempt 2400'));

    // Verify DexProvider has marked Mewtwo as caught and shiny
    expect(dex.caughtIds.contains('150'), isTrue);
    expect(dex.shinyIds.contains('150'), isTrue);

    huntProvider.dispose();
    dexProvider.dispose();
  });

  test('App lifecycle background pauses and triggers mandatory flush', () async {
    final provider = ShinyHuntProvider(databaseService: DatabaseService.instance);
    await provider.initialized;
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'hunt-lifecycle-test',
      title: 'Pikachu',
      pokemonId: 25,
      pokemonName: 'Pikachu',
      game: 'FireRed',
      generation: 3.0,
      method: 'Wild',
      baseOdds: 8192.0,
      createdAt: now,
      updatedAt: now,
    );

    await provider.createHunt(hunt);
    provider.increment('hunt-lifecycle-test');

    // Simulate app going to background
    provider.didChangeAppLifecycleState(AppLifecycleState.paused);
    await provider.flushPendingWrites();

    final dbHunt = await DatabaseService.instance.getShinyHunt('hunt-lifecycle-test');
    expect(dbHunt!.currentEncounters, equals(1));

    provider.dispose();
  });
}
