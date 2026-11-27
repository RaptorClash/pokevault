import 'dart:async';
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

  test('preserves manual increment/decrement during loadHunts, serializes concurrent flushes, and guards notifyListeners after dispose', () async {
    final loadCompleter = Completer<List<ShinyHunt>>();
    final slowDb = _DelayedHuntDatabase(
      base: DatabaseService.instance,
      loadFuture: loadCompleter.future,
    );
    final now = DateTime.now();
    final initialHunt = ShinyHunt(
      id: 'hunt-race-1',
      title: 'Evoli',
      pokemonId: 133,
      pokemonName: 'Evoli',
      game: 'Violet',
      generation: 9.0,
      method: 'Wild',
      baseOdds: 4096.0,
      currentEncounters: 10,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseService.instance.saveShinyHunt(initialHunt);

    final provider = ShinyHuntProvider(
      databaseService: slowDb,
      enableTimer: false,
    );
    await provider.initialized;

    // Trigger loadHunts (stalls on loadCompleter), then perform manual increment while loading
    final loadFuture = provider.loadHunts();
    await Future<void>.delayed(Duration.zero);
    provider.increment('hunt-race-1');
    provider.increment('hunt-race-1');
    provider.decrement('hunt-race-1');

    loadCompleter.complete([
      ShinyHunt(
        id: 'hunt-race-1',
        title: 'Evoli',
        pokemonId: 133,
        pokemonName: 'Evoli',
        game: 'Violet',
        generation: 9.0,
        method: 'Wild',
        baseOdds: 4096.0,
        currentEncounters: 10,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    await loadFuture;

    // Net +1 delta must survive reload (10 + 1 = 11) and be flushed to DB
    expect(provider.getHuntById('hunt-race-1')!.currentEncounters, equals(11));
    final fromDb = await DatabaseService.instance.getShinyHunt('hunt-race-1');
    expect(fromDb!.currentEncounters, equals(11));

    // Dispose while a second loadHunts is in flight -> completing after dispose must NOT throw FlutterError
    final loadCompleter2 = Completer<List<ShinyHunt>>();
    slowDb.loadFuture = loadCompleter2.future;
    final loadFuture2 = provider.loadHunts();
    await Future<void>.delayed(Duration.zero);
    provider.dispose();
    loadCompleter2.complete([]);
    await loadFuture2;

    // incrementAuto / decrementAuto after dispose must NOT throw FlutterError
    provider.incrementAuto('hunt-race-1');
    provider.decrementAuto('hunt-race-1');
  });

  test('loadHunts awaits in-flight flushPendingWrites even after _pendingDirtyHuntIds is cleared', () async {
    final saveCompleter = Completer<void>();
    final now = DateTime.now();
    var dbCount = 10;
    final gatedDb = _FlushRaceHuntDatabase(
      onSave: (hunt) async {
        await saveCompleter.future;
        dbCount = hunt.currentEncounters;
      },
      onLoad: () async => [
        ShinyHunt(
          id: 'hunt-flush-race',
          title: 'Evoli',
          pokemonId: 133,
          pokemonName: 'Evoli',
          game: 'Violet',
          generation: 9.0,
          method: 'Wild',
          baseOdds: 4096.0,
          currentEncounters: dbCount,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final provider = ShinyHuntProvider(
      databaseService: gatedDb,
      enableTimer: false,
    );
    await provider.initialized;
    expect(provider.getHuntById('hunt-flush-race')!.currentEncounters, 10);

    // Trigger an auto increment (which starts flushPendingWrites immediately when enableTimer == false)
    provider.incrementAuto('hunt-flush-race');
    await Future<void>.delayed(Duration.zero);
    // At this point _pendingDirtyHuntIds is cleared, while saveCompleter is still pending (_flushInFlight != null)
    final reloadFuture = provider.loadHunts();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Complete DB save with 11 BEFORE loadHunts reads DB
    saveCompleter.complete();
    await reloadFuture;

    expect(provider.getHuntById('hunt-flush-race')!.currentEncounters, 11);
    provider.dispose();
  });
}

class _DelayedHuntDatabase extends Fake implements DatabaseService {
  final DatabaseService base;
  Future<List<ShinyHunt>> loadFuture;

  _DelayedHuntDatabase({required this.base, required this.loadFuture});

  bool _firstInitLoad = true;

  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) {
    if (_firstInitLoad) {
      _firstInitLoad = false;
      return base.getAllShinyHunts(includeDeleted: includeDeleted);
    }
    return loadFuture;
  }

  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) => base.saveShinyHunt(hunt);
}

class _FlushRaceHuntDatabase extends Fake implements DatabaseService {
  final Future<void> Function(ShinyHunt hunt) onSave;
  final Future<List<ShinyHunt>> Function() onLoad;

  _FlushRaceHuntDatabase({required this.onSave, required this.onLoad});

  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) =>
      onLoad();

  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) => onSave(hunt);
}
