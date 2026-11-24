import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/feedback/scanner_feedback.dart';
import 'package:pokevault/services/scanner_core/media/frame_transition_detector.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_config.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_service.dart';

class _MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory dir;
  _MockPathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

class _CountingFeedback implements ScannerFeedback {
  int encounters = 0;
  int shinies = 0;
  @override
  Future<void> onCaught(event) async {}
  @override
  Future<void> onEncounter(event) async => encounters++;
  @override
  Future<void> onEvolved(event) async {}
  @override
  Future<void> onShiny(event) async => shinies++;
}

ShinyHunt _makeHunt({
  required String id,
  required int pokemonId,
  required String pokemonName,
  String method = 'Soft Reset',
}) {
  final now = DateTime.now();
  return ShinyHunt(
    id: id,
    title: pokemonName,
    pokemonId: pokemonId,
    pokemonName: pokemonName,
    game: 'SoulSilver',
    generation: 4.0,
    method: method,
    baseOdds: 8192.0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('pokevault_auto_counter_srv_');
    PathProviderPlatform.instance = _MockPathProvider(tempDir);
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await DatabaseService.instance.clearUserData();
  });

  ScannerCoordinator buildTestCoordinator(Duration Function() clock) {
    final matcher = PokemonFuzzyMatcher.withEntries(const [
      PokemonMatcherEntry(id: 150, name: 'Mewtu', language: 'de'),
      PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
      PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
      PokemonMatcherEntry(id: 41, name: 'Zubat', language: 'de'),
    ]);
    return ScannerCoordinator(
      engine: OcrDetectionEngine(),
      matcher: matcher,
      elapsedClock: clock,
    );
  }

  group('ShinyAutoCounterService', () {
    test('Concurrency stress: 4 parallel slots across 25 cycles each produce exact 100 increments with zero race loss', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-mewtwo', pokemonId: 150, pokemonName: 'Mewtu'));

      final coordinator = buildTestCoordinator(() => clock);
      final feedback = _CountingFeedback();
      final service = ShinyAutoCounterService.forTesting(
        elapsedClock: () => clock,
        feedback: feedback,
      );

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-mewtwo',
        slotIds: const [1, 2, 3, 4],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
          minResetCooldownMs: 500,
          playSoundOnCount: true,
        ),
      );

      for (int cycle = 0; cycle < 25; cycle++) {
        // Fire all 4 slots concurrently
        await Future.wait([
          for (int s = 1; s <= 4; s++)
            coordinator.processFrameText(
              'Ein wildes Mewtu erscheint!',
              instanceIndex: s,
              instanceColorHex: 0xFFA855F7,
            ),
        ]);

        // Advance time and fire 4 concurrent black-screen transitions
        clock += const Duration(milliseconds: 200);
        await Future.wait([
          for (int s = 1; s <= 4; s++)
            service.handleFrameTransition(
              FrameTransitionEvent(
                slotId: s,
                type: FrameTransitionType.blackScreenEnded,
                durationMs: 400,
                averageLuma: 2,
                timestamp: DateTime.now(),
              ),
            ),
        ]);
        clock += const Duration(milliseconds: 600);
      }

      expect(provider.getHuntById('hunt-mewtwo')!.currentEncounters, equals(100));
      expect(feedback.encounters, equals(100));
      expect(service.recentLogs.length, equals(50)); // Ring buffer capped at 50

      await service.stopSession();
      await coordinator.dispose();
    });

    test('Multi-Hunt routing assigns specific slots to distinct hunts and falls back to default', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-a', pokemonId: 150, pokemonName: 'Mewtu'));
      await provider.createHunt(_makeHunt(id: 'hunt-b', pokemonId: 4, pokemonName: 'Glumanda'));

      final coordinator = buildTestCoordinator(() => clock);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-a',
        slotIds: const [1, 2, 3],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          matchFilter: ShinyMatchFilter.allPokemon,
          slotToHuntOverrides: {2: 'hunt-b'},
        ),
      );

      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
      await coordinator.processFrameText('Ein wildes Zubat erscheint!', instanceIndex: 2);
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 3);
      await service.waitForIdle();

      expect(provider.getHuntById('hunt-a')!.currentEncounters, equals(2));
      expect(provider.getHuntById('hunt-b')!.currentEncounters, equals(1));

      await service.stopSession();
      await coordinator.dispose();
    });

    test('Undo reverses exact delta and clamps cleanly at zero', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-u', pokemonId: 41, pokemonName: 'Zubat', method: 'Wild'));

      final coordinator = buildTestCoordinator(() => clock);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-u',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          matchFilter: ShinyMatchFilter.allPokemon,
          useEventEncounterCount: true,
        ),
      );

      await coordinator.processFrameText(
        'Eine Horde wilder Zubat erscheint!',
        instanceIndex: 1,
      );
      await service.waitForIdle();
      // Verify at least 1 incremented
      final countAfter = provider.getHuntById('hunt-u')!.currentEncounters;
      expect(countAfter, greaterThanOrEqualTo(1));

      final undone = service.undoLastCount();
      expect(undone, isTrue);
      expect(provider.getHuntById('hunt-u')!.currentEncounters, equals(0));
      // Repeating undo when nothing left returns false and keeps >= 0
      expect(service.undoLastCount(), isFalse);
      expect(provider.getHuntById('hunt-u')!.currentEncounters, equals(0));

      await service.stopSession();
      await coordinator.dispose();
    });

    test('Per-hunt rules: automatic method defaults and explicit updateHuntSettings isolate parallel hunts', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(
        _makeHunt(id: 'hunt-egg', pokemonId: 4, pokemonName: 'Glumanda', method: 'Masuda-Methode'),
      );
      await provider.createHunt(
        _makeHunt(id: 'hunt-sr', pokemonId: 150, pokemonName: 'Mewtu', method: 'Soft Reset'),
      );

      final coordinator = buildTestCoordinator(() => clock);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      // Start session without overriding settings -> automatic per-hunt method defaults
      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-egg',
        slotIds: const [1, 2],
        settings: const ShinyAutoCounterSettings(
          usePerHuntMethodDefaults: true,
          slotToHuntOverrides: {1: 'hunt-egg', 2: 'hunt-sr'},
        ),
      );

      // Wild encounter on slot 1 (eggHatch mode) should NOT count
      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
      // Egg hatched on slot 1 counts for hunt-egg
      await coordinator.processFrameText('Glumanda ist aus dem Ei geschlüpft!', instanceIndex: 1);
      // Non-target Rattfratz on slot 2 (softReset + targetPokemonOnly) should NOT count; Mewtu counts
      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 2);
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 2);
      await service.waitForIdle();

      expect(provider.getHuntById('hunt-egg')!.currentEncounters, equals(1));
      expect(provider.getHuntById('hunt-sr')!.currentEncounters, equals(1));

      // Now explicitly override hunt-egg to wildEncounter + allPokemon without affecting hunt-sr
      service.updateHuntSettings(
        'hunt-egg',
        const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          matchFilter: ShinyMatchFilter.allPokemon,
        ),
      );
      service.rearmSlot(1);

      await coordinator.processFrameText('Ein wildes Zubat erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-egg')!.currentEncounters, equals(2));
      expect(provider.getHuntById('hunt-sr')!.currentEncounters, equals(1));

      // Serialization roundtrip preserves huntSettingsOverrides
      final map = service.settings.toMap();
      final restored = ShinyAutoCounterSettings.fromMap(map);
      expect(restored.huntSettingsOverrides.containsKey('hunt-egg'), isTrue);
      expect(
        restored.huntSettingsOverrides['hunt-egg']!.detectionMode,
        equals(ShinyHuntDetectionMode.wildEncounter),
      );

      await service.stopSession();
      await coordinator.dispose();
    });
  });
}
