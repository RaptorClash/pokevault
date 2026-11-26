import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/feedback/scanner_feedback.dart';
import 'package:pokevault/services/scanner_core/media/frame_transition_detector.dart';
import 'package:pokevault/services/scanner_core/media/visual_shiny_detector.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_config.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_service.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_slot_state_machine.dart';

class _MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory dir;
  _MockPathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

class _FakeVisualSource implements VisualFrameScannerSource {
  final StreamController<String> _text = StreamController<String>.broadcast();
  final StreamController<SlotVisualFrame> _visual =
      StreamController<SlotVisualFrame>.broadcast();
  bool _running = false;

  @override
  Stream<String> get textStream => _text.stream;

  @override
  Stream<SlotVisualFrame> get visualFrameStream => _visual.stream;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async => _running = true;

  @override
  Future<void> stop() async => _running = false;

  void emitVisualFrame(int slotId, int r, int g, int b) {
    final bytes = Uint8List(32 * 32 * 4);
    for (int i = 0; i < bytes.length; i += 4) {
      bytes[i] = b;
      bytes[i + 1] = g;
      bytes[i + 2] = r;
      bytes[i + 3] = 255;
    }
    _visual.add(
      SlotVisualFrame(
        slotId: slotId,
        frame: CapturedFrame(
          width: 32,
          height: 32,
          bytes: bytes,
          pixelFormat: 'bgra8888',
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _running = false;
    await _text.close();
    await _visual.close();
  }
}

class _FakeTransitionSource implements FrameTransitionScannerSource {
  final StreamController<String> _text = StreamController<String>.broadcast();
  final StreamController<FrameTransitionEvent> _transitions =
      StreamController<FrameTransitionEvent>.broadcast();
  bool _running = false;
  Duration? lastMinDuration;
  int? lastBlackThreshold;
  int? lastWhiteThreshold;
  Map<int, SlotTransitionConfig> lastSlotConfigs = const {};

  @override
  Stream<String> get textStream => _text.stream;

  @override
  Stream<FrameTransitionEvent> get transitionStream => _transitions.stream;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async => _running = true;

  @override
  Future<void> stop() async => _running = false;

  @override
  void updateTransitionMinDuration(Duration duration) {
    lastMinDuration = duration;
  }

  @override
  void updateTransitionThresholds({
    required int blackThreshold,
    required int whiteThreshold,
  }) {
    lastBlackThreshold = blackThreshold;
    lastWhiteThreshold = whiteThreshold;
  }

  @override
  void updateSlotTransitionConfigs(Map<int, SlotTransitionConfig> configs) {
    lastSlotConfigs = Map.unmodifiable(configs);
  }

  @override
  Future<void> dispose() async {
    _running = false;
    await _text.close();
    await _transitions.close();
  }
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

    test('Paused hunt is strictly ignored: no increment, no log, no slot lock, no negative undo', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-p', pokemonId: 150, pokemonName: 'Mewtu'));
      await provider.pauseHunt('hunt-p');

      final coordinator = buildTestCoordinator(() => clock);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-p',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
        ),
      );

      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
      await service.waitForIdle();

      expect(provider.getHuntById('hunt-p')!.currentEncounters, equals(0));
      expect(service.recentLogs, isEmpty);
      expect(service.undoLastCount(), isFalse);
      expect(service.slotStatesNotifier.value.first.phase.name, equals('armed'));

      await service.stopSession();
      await coordinator.dispose();
    });

    test('Zombie-session protection & pattern cleanup on source stop / coordinator dispose', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-z', pokemonId: 150, pokemonName: 'Mewtu'));

      final coordinator = buildTestCoordinator(() => clock);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-z',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          customResetPatterns: ['Press A Custom'],
        ),
      );
      expect(service.isRunning, isTrue);

      await coordinator.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(service.isRunning, isFalse);

      // Restart with new coordinator and verify stopSession restores coordinator custom patterns
      final coord2 = buildTestCoordinator(() => clock);
      service.startSession(
        huntProvider: provider,
        coordinator: coord2,
        defaultHuntId: 'hunt-z',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          customResetPatterns: ['Press A Custom'],
        ),
      );
      expect(coord2.engine.detectResetCue('Press A Custom'), isNot(ResetCue.none));
      await service.stopSession();
      expect(coord2.engine.detectResetCue('Press A Custom'), equals(ResetCue.none));
      await coord2.dispose();
    });

    test('Double-shiny alert protection, undo slot re-arm, live hunt sync, and rearmAllSlots', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-ds', pokemonId: 150, pokemonName: 'Mewtu'));
      await provider.createHunt(_makeHunt(id: 'hunt-del', pokemonId: 4, pokemonName: 'Glumanda'));

      final coordinator = buildTestCoordinator(() => clock);
      // Default SystemSound feedback when feedback is null must not throw
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-ds',
        slotIds: const [1, 2, 3],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          autoPauseSlotOnShiny: true,
          playSoundOnCount: true,
          playSoundOnShiny: true,
          slotToHuntOverrides: {3: 'hunt-del'},
        ),
      );

      // Slot 1 & 2 both hit shiny
      await coordinator.processFrameText('Wildes ✨ Mewtu erscheint!', instanceIndex: 1);
      await coordinator.processFrameText('Wildes ✨ Mewtu erscheint!', instanceIndex: 2);
      await service.waitForIdle();

      expect(service.latestShinyAlertNotifier.value?.slotId, equals(2));

      // Resuming Slot 2 must keep shiny alert active for Slot 1!
      service.resumeShinyPausedSlot(2);
      expect(service.latestShinyAlertNotifier.value?.slotId, equals(1));

      // Normal encounter on Slot 2 -> counted -> undo re-arms Slot 2 immediately
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 2);
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-ds')!.currentEncounters, equals(3));

      expect(service.undoLastCount(), isTrue);
      expect(provider.getHuntById('hunt-ds')!.currentEncounters, equals(2));
      final slot2AfterUndo = service.slotStatesNotifier.value.firstWhere((s) => s.slotId == 2);
      expect(slot2AfterUndo.phase.name, equals('armed'));
      expect(slot2AfterUndo.sessionCount, equals(1));

      // rearmAllSlots leaves Slot 1 pausedByShiny while re-arming others
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 2);
      await service.waitForIdle();
      service.rearmAllSlots();
      final s1 = service.slotStatesNotifier.value.firstWhere((s) => s.slotId == 1);
      final s2 = service.slotStatesNotifier.value.firstWhere((s) => s.slotId == 2);
      expect(s1.phase.name, equals('pausedByShiny'));
      expect(s2.phase.name, equals('armed'));

      // Deleting hunt-del prunes stale override
      await provider.deleteHunt('hunt-del');
      await Future<void>.delayed(Duration.zero);
      expect(service.settings.slotToHuntOverrides.containsKey(3), isFalse);

      await service.stopSession();
      await coordinator.dispose();
    });

    test('Single-screen (instanceIndex: null) clears battle lock & dlg_ cooldown on rearm, undo, and blackScreen', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-ss', pokemonId: 150, pokemonName: 'Mewtu'));

      final coordinator = buildTestCoordinator(() => clock);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-ss',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
          minResetCooldownMs: 300,
        ),
      );

      // 1. Encounter on single-screen (instanceIndex: null) -> counts 1
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!');
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-ss')!.currentEncounters, equals(1));

      // 2. Manual rearmSlot(1) -> same Mewtu within 500ms (< 1500ms duplicateCooldown & < 20m battleTimeout) MUST count!
      service.rearmSlot(1);
      clock += const Duration(milliseconds: 500);
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!');
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-ss')!.currentEncounters, equals(2));

      // 3. Undo -> immediate same Mewtu within 200ms MUST count back to 2!
      expect(service.undoLastCount(), isTrue);
      expect(provider.getHuntById('hunt-ss')!.currentEncounters, equals(1));
      clock += const Duration(milliseconds: 200);
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!');
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-ss')!.currentEncounters, equals(2));

      // 4. Black screen transition (slotId: 0) -> after 400ms (>= minResetCooldownMs, < 1500ms duplicateCooldown) MUST count!
      await service.handleFrameTransition(
        FrameTransitionEvent(
          slotId: 0,
          type: FrameTransitionType.blackScreenEnded,
          durationMs: 400,
          averageLuma: 3,
          timestamp: DateTime.now(),
        ),
      );
      clock += const Duration(milliseconds: 400);
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!');
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-ss')!.currentEncounters, equals(3));

      await service.stopSession();
      await coordinator.dispose();
    });

    test('rearmPending automatically promotes to armed via timer without requiring another event', () async {
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-tm', pokemonId: 25, pokemonName: 'Pikachu', method: 'Wild'));

      final coordinator = buildTestCoordinator(() => const Duration(seconds: 1));
      final service = ShinyAutoCounterService.forTesting();

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-tm',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          minResetCooldownMs: 200,
        ),
      );

      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(service.slotStatesNotifier.value.first.phase, equals(ShinySlotPhase.counted));

      await coordinator.processFrameText('Du bist entkommen!', instanceIndex: 1);
      await service.waitForIdle();
      expect(service.slotStatesNotifier.value.first.phase, equals(ShinySlotPhase.rearmPending));

      // Wait past minResetCooldownMs (200ms) with NO additional event
      final armedCompleter = Completer<void>();
      void onSlotUpdate() {
        final slots = service.slotStatesNotifier.value;
        if (slots.isNotEmpty &&
            slots.first.phase == ShinySlotPhase.armed &&
            !armedCompleter.isCompleted) {
          armedCompleter.complete();
        }
      }

      service.slotStatesNotifier.addListener(onSlotUpdate);
      onSlotUpdate();
      try {
        await armedCompleter.future.timeout(const Duration(seconds: 2));
      } finally {
        service.slotStatesNotifier.removeListener(onSlotUpdate);
      }
      expect(service.slotStatesNotifier.value.first.phase, equals(ShinySlotPhase.armed));

      await service.stopSession();
      await coordinator.dispose();
    });

    test('coordinator.updateSettings preserves auto-counter custom triggers and reset events do not pollute activeFocusStream', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-pat', pokemonId: 150, pokemonName: 'Mewtu'));

      final coordinator = buildTestCoordinator(() => clock);
      final focusEvents = <List<ScannerEvent>>[];
      final focusSub = coordinator.activeFocusStream.listen(focusEvents.add);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-pat',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          customTriggerPatterns: [
            CustomOcrPattern(
              id: 'trig_custom_1',
              template: 'ROM INTRO STARTER',
              eventType: ScannerEventType.encounter,
            ),
          ],
          customResetPatterns: ['TITLE SCREEN RESET'],
        ),
      );

      // Update scanner settings independently -> must NOT wipe auto-counter patterns
      coordinator.updateSettings(ScannerSettings.defaults().copyWith(detectShinies: false));

      await coordinator.processFrameText('ROM INTRO STARTER', instanceIndex: 1);
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-pat')!.currentEncounters, equals(1));

      // Reset event must NOT pollute activeFocusStream
      final focusCountBefore = focusEvents.length;
      await coordinator.processFrameText('TITLE SCREEN RESET', instanceIndex: 1);
      await service.waitForIdle();
      expect(focusEvents.length, equals(focusCountBefore));

      await focusSub.cancel();
      await service.stopSession();
      await coordinator.dispose();
    });

    test('ensureSettingsLoaded prevents updateHuntSettings after restart from overwriting saved prefs, and assignSlotToHunt persists', () async {
      SharedPreferences.setMockInitialValues({});
      const initialSaved = ShinyAutoCounterSettings(
        playSoundOnCount: true,
        minResetCooldownMs: 2400,
        huntSettingsOverrides: {
          'hunt-a': ShinyAutoCounterSettings(
            detectionMode: ShinyHuntDetectionMode.eggHatch,
            matchFilter: ShinyMatchFilter.allPokemon,
          ),
        },
      );
      await ShinyAutoCounterSettings.saveToPrefs(initialSaved);

      // Fresh service simulating app restart
      final freshService = ShinyAutoCounterService.forTesting();
      await freshService.ensureSettingsLoaded();
      freshService.updateHuntSettings(
        'hunt-b',
        const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.screenTransitionOnly,
        ),
      );
      freshService.assignSlotToHunt(2, 'hunt-b');
      await Future<void>.delayed(Duration.zero);

      final reloaded = await ShinyAutoCounterSettings.loadFromPrefs();
      expect(reloaded, isNotNull);
      expect(reloaded!.playSoundOnCount, isTrue);
      expect(reloaded.minResetCooldownMs, equals(2400));
      expect(reloaded.huntSettingsOverrides.containsKey('hunt-a'), isTrue);
      expect(reloaded.huntSettingsOverrides.containsKey('hunt-b'), isTrue);
      expect(reloaded.slotToHuntOverrides[2], equals('hunt-b'));
    });

    test('armPendingSession + attachIfPending automatically binds when coordinator starts', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-pend', pokemonId: 150, pokemonName: 'Mewtu'));

      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);
      expect(service.hasPendingSessionNotifier.value, isFalse);

      service.armPendingSession(
        huntProvider: provider,
        defaultHuntId: 'hunt-pend',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
        ),
      );
      expect(service.hasPendingSessionNotifier.value, isTrue);
      expect(service.isRunning, isFalse);

      final coordinator = buildTestCoordinator(() => clock);
      final attached = service.attachIfPending(coordinator: coordinator);
      expect(attached, isTrue);
      expect(service.hasPendingSessionNotifier.value, isFalse);
      expect(service.isRunning, isTrue);

      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-pend')!.currentEncounters, equals(1));

      await service.stopSession();
      await coordinator.dispose();
    });

    test('Beta visual shiny config roundtrip + backward compatibility with legacy maps', () {
      const cfg = ShinyAutoCounterSettings(
        enableSparkleDelayShinyCheck: true,
        sparkleDelayThresholdMs: 1350,
        enableColorDeviationShinyCheck: true,
        colorDeviationThreshold: 0.42,
      );
      final map = cfg.toMap();
      final restored = ShinyAutoCounterSettings.fromMap(map);
      expect(restored.enableSparkleDelayShinyCheck, isTrue);
      expect(restored.sparkleDelayThresholdMs, equals(1350));
      expect(restored.enableColorDeviationShinyCheck, isTrue);
      expect(restored.colorDeviationThreshold, closeTo(0.42, 0.001));

      final legacy = ShinyAutoCounterSettings.fromMap(const {'detectionMode': 'softReset'});
      expect(legacy.enableSparkleDelayShinyCheck, isFalse);
      expect(legacy.sparkleDelayThresholdMs, equals(1500));
      expect(legacy.enableColorDeviationShinyCheck, isFalse);
      expect(legacy.colorDeviationThreshold, closeTo(0.38, 0.001));
    });

    test('Sparkle-Delay heuristic pauses slot and emits activeShinyAlertsNotifier entry with sparkleDelay source', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-sd', pokemonId: 150, pokemonName: 'Mewtu'));

      final coordinator = buildTestCoordinator(() => clock);
      final feedback = _CountingFeedback();
      final service = ShinyAutoCounterService.forTesting(
        elapsedClock: () => clock,
        feedback: feedback,
      );

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-sd',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          minResetCooldownMs: 200,
          enableSparkleDelayShinyCheck: true,
          sparkleDelayThresholdMs: 1000,
        ),
      );

      // 3 normal cycles (~1400ms from encounter to battleMenu)
      for (int i = 0; i < 3; i++) {
        await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
        await service.waitForIdle();
        clock += const Duration(milliseconds: 1400);
        await coordinator.processFrameText('Was soll Glumanda tun?', instanceIndex: 1);
        await service.waitForIdle();
        expect(service.activeShinyAlertsNotifier.value, isEmpty);

        // Reset + rearm
        await coordinator.processFrameText('Weiter', instanceIndex: 1);
        await service.waitForIdle();
        clock += const Duration(milliseconds: 400);
      }

      // 4th encounter with +1400ms sparkle delay (2800ms total)
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      clock += const Duration(milliseconds: 2800);
      await coordinator.processFrameText('Was soll Glumanda tun?', instanceIndex: 1);
      await service.waitForIdle();

      expect(service.slotStatesNotifier.value.first.phase, equals(ShinySlotPhase.pausedByShiny));
      expect(service.activeShinyAlertsNotifier.value.length, equals(1));
      expect(
        service.activeShinyAlertsNotifier.value.first.detectionSource,
        equals(ShinyDetectionSource.sparkleDelay),
      );
      expect(feedback.shinies, equals(1));

      await service.stopSession();
      expect(service.latestShinyAlertNotifier.value, isNull);
      expect(service.activeShinyAlertsNotifier.value, isEmpty);
      await coordinator.dispose();
    });

    test('Color-Deviation heuristic via VisualFrameScannerSource pauses slot and tracks multi-slot active alerts', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-cd', pokemonId: 25, pokemonName: 'Pikachu', method: 'Wild'));

      final coordinator = buildTestCoordinator(() => clock);
      final source = _FakeVisualSource();
      await source.start();
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        source: source,
        defaultHuntId: 'hunt-cd',
        slotIds: const [1, 2],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          minResetCooldownMs: 200,
          enableColorDeviationShinyCheck: true,
          colorDeviationThreshold: 0.35,
        ),
      );

      // 3 normal blue frames on slot 1 (after 700ms battle-intro settle window)
      for (int i = 0; i < 3; i++) {
        await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
        await service.waitForIdle();
        clock += const Duration(milliseconds: 750);
        source.emitVisualFrame(1, 30, 110, 235);
        await service.waitForIdle();
        await coordinator.processFrameText('Du bist entkommen!', instanceIndex: 1);
        await service.waitForIdle();
        clock += const Duration(milliseconds: 400);
      }

      // 4th encounter on slot 1 with green shiny sprite frame
      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      clock += const Duration(milliseconds: 750);
      source.emitVisualFrame(1, 30, 220, 65);
      await service.waitForIdle();

      // Simultaneous OCR shiny on slot 2
      await coordinator.processFrameText('Wildes ✨ Pikachu erscheint!', instanceIndex: 2);
      await service.waitForIdle();

      expect(service.activeShinyAlertsNotifier.value.length, equals(2));
      final alert1 = service.activeShinyAlertsNotifier.value.firstWhere((e) => e.slotId == 1);
      final alert2 = service.activeShinyAlertsNotifier.value.firstWhere((e) => e.slotId == 2);
      expect(alert1.detectionSource, equals(ShinyDetectionSource.colorDeviation));
      expect(alert2.detectionSource, equals(ShinyDetectionSource.ocrText));

      // Resuming slot 1 keeps slot 2 active in both notifiers
      service.resumeShinyPausedSlot(1);
      expect(service.activeShinyAlertsNotifier.value.length, equals(1));
      expect(service.activeShinyAlertsNotifier.value.first.slotId, equals(2));
      expect(service.latestShinyAlertNotifier.value?.slotId, equals(2));

      await service.stopSession();
      expect(service.activeShinyAlertsNotifier.value, isEmpty);
      expect(service.latestShinyAlertNotifier.value, isNull);
      await source.dispose();
      await coordinator.dispose();
    });

    test('syncSlots live-adds/removes slots preserving existing state and pushes per-slot transition configs', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-a', pokemonId: 150, pokemonName: 'Mewtu'));
      await provider.createHunt(_makeHunt(id: 'hunt-b', pokemonId: 25, pokemonName: 'Pikachu'));

      final coordinator = buildTestCoordinator(() => clock);
      final source = _FakeTransitionSource();
      await source.start();
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        source: source,
        defaultHuntId: 'hunt-a',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          blackLumaThreshold: 18,
          whiteLumaThreshold: 240,
          transitionMinDurationMs: 300,
          slotToHuntOverrides: {2: 'hunt-b'},
          huntSettingsOverrides: {
            'hunt-b': ShinyAutoCounterSettings(
              blackLumaThreshold: 55,
              whiteLumaThreshold: 205,
              transitionMinDurationMs: 450,
            ),
          },
        ),
      );

      // Slot 1 counts once -> phase=counted, sessionCount=1
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(service.slotStatesNotifier.value.single.phase, equals(ShinySlotPhase.counted));
      expect(service.slotStatesNotifier.value.single.sessionCount, equals(1));
      expect(source.lastSlotConfigs[0]?.blackThreshold, equals(18));
      expect(source.lastSlotConfigs[1]?.blackThreshold, equals(18));

      // Live-add Slots 2 and 3 via syncSlots -> Slot 1 preserves phase/count, Slot 2 gets hunt-b thresholds
      service.syncSlots(
        slotIds: const [1, 2, 3],
        slotColorOverrides: const {1: 0xFF112233, 2: 0xFF445566, 3: 0xFF778899},
      );
      expect(service.slotStatesNotifier.value.map((s) => s.slotId).toList(), equals([1, 2, 3]));
      final slot1 = service.slotStatesNotifier.value.firstWhere((s) => s.slotId == 1);
      expect(slot1.phase, equals(ShinySlotPhase.counted));
      expect(slot1.sessionCount, equals(1));
      expect(source.lastSlotConfigs[2]?.blackThreshold, equals(55));
      expect(source.lastSlotConfigs[2]?.whiteThreshold, equals(205));
      expect(
        source.lastSlotConfigs[2]?.minTransitionDuration,
        equals(const Duration(milliseconds: 450)),
      );

      // Shiny on Slot 2 -> active alert exists; removing Slot 2 clears alert & slot cleanly
      await coordinator.processFrameText('Wildes ✨ Pikachu erscheint!', instanceIndex: 2);
      await service.waitForIdle();
      expect(service.activeShinyAlertsNotifier.value.any((a) => a.slotId == 2), isTrue);

      service.syncSlots(slotIds: const [1, 3]);
      expect(service.slotStatesNotifier.value.map((s) => s.slotId).toList(), equals([1, 3]));
      expect(service.activeShinyAlertsNotifier.value.any((a) => a.slotId == 2), isFalse);
      expect(source.lastSlotConfigs.containsKey(2), isFalse);

      await service.stopSession();
      await source.dispose();
      await coordinator.dispose();
    });

    test('Rearm cooldown race: OCR during rearmPending does not poison coordinator battle state after promotion', () async {
      final coordinator = buildTestCoordinator(() => Duration.zero);
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-race', pokemonId: 4, pokemonName: 'Glumanda'));

      // Real-clock service so _rearmTimers schedules and fires naturally
      final service = ShinyAutoCounterService.forTesting();
      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-race',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
          minResetCooldownMs: 220,
        ),
      );

      // Encounter 1 counted -> enters counted phase
      await coordinator.processFrameText('Ein wildes Glumanda erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-race')!.currentEncounters, equals(1));

      // Black screen triggers rearmPending (220ms)
      await service.handleFrameTransition(
        FrameTransitionEvent(
          slotId: 1,
          type: FrameTransitionType.blackScreenEnded,
          durationMs: 400,
          averageLuma: 2,
          timestamp: DateTime.now(),
        ),
      );
      expect(service.slotStatesNotifier.value.single.phase, equals(ShinySlotPhase.rearmPending));

      // Early OCR arrives BEFORE 220ms cooldown expires -> rejected by state machine,
      // which MUST NOT leave coordinator _activeBattlesBySlot poisoned for Glumanda!
      await coordinator.processFrameText('Ein wildes Glumanda erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-race')!.currentEncounters, equals(1));

      // Wait for real _rearmTimers to promote rearmPending -> armed
      await Future<void>.delayed(const Duration(milliseconds: 280));
      expect(service.slotStatesNotifier.value.single.phase, equals(ShinySlotPhase.armed));

      // Same-species encounter arriving after cooldown MUST be counted (not swallowed by coordinator)
      await coordinator.processFrameText('Ein wildes Glumanda erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(provider.getHuntById('hunt-race')!.currentEncounters, equals(2));

      await service.stopSession();
      await coordinator.dispose();
    });

    test('loadHunts while loading does not prune overrides and completing hunt clears pausedByShiny', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      final hunt = _makeHunt(id: 'hunt-keep', pokemonId: 150, pokemonName: 'Mewtu');
      await provider.createHunt(hunt);

      final coordinator = buildTestCoordinator(() => clock);
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      const savedSettings = ShinyAutoCounterSettings(
        detectionMode: ShinyHuntDetectionMode.softReset,
        slotToHuntOverrides: {2: 'hunt-keep'},
        huntSettingsOverrides: {
          'hunt-keep': ShinyAutoCounterSettings(minResetCooldownMs: 2500),
        },
      );
      await ShinyAutoCounterSettings.saveToPrefs(savedSettings);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        defaultHuntId: 'hunt-keep',
        slotIds: const [1, 2],
        settings: savedSettings,
      );

      // Start loadHunts() -> provider.isLoading becomes true briefly while _hunts could still be loading
      final loadFut = provider.loadHunts();
      await loadFut;
      expect(service.settings.slotToHuntOverrides[2], equals('hunt-keep'));
      expect(service.settings.huntSettingsOverrides.containsKey('hunt-keep'), isTrue);

      // Trigger shiny on slot 1 -> pausedByShiny
      await coordinator.processFrameText('Wildes ✨ Mewtu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      expect(service.activeShinyAlertsNotifier.value, isNotEmpty);

      // Completing the hunt automatically clears pausedByShiny alerts for that hunt
      await provider.completeHunt('hunt-keep');
      await service.waitForIdle();
      expect(service.activeShinyAlertsNotifier.value, isEmpty);
      expect(
        service.slotStatesNotifier.value.every((s) => s.phase != ShinySlotPhase.pausedByShiny),
        isTrue,
      );

      await service.stopSession();
      await coordinator.dispose();
    });

    test('Color deviation enforces 700ms settle delay, resets baseline on resumeShinyPausedSlot, and drops frames when idle', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-vis', pokemonId: 25, pokemonName: 'Pikachu', method: 'Wild'));

      final coordinator = buildTestCoordinator(() => clock);
      final source = _FakeVisualSource();
      await source.start();
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        source: source,
        defaultHuntId: 'hunt-vis',
        slotIds: const [1],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          minResetCooldownMs: 200,
          enableColorDeviationShinyCheck: true,
          colorDeviationThreshold: 0.35,
        ),
      );

      // Build 3 blue baseline frames (with 700ms settle)
      for (int i = 0; i < 3; i++) {
        await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
        await service.waitForIdle();
        // Frame at +100ms is BEFORE 700ms settle -> must be ignored (e.g. battle intro flash)
        clock += const Duration(milliseconds: 100);
        source.emitVisualFrame(1, 230, 40, 40);
        await service.waitForIdle();
        // Frame at +750ms IS sampled for baseline
        clock += const Duration(milliseconds: 650);
        source.emitVisualFrame(1, 30, 110, 235);
        await service.waitForIdle();
        await coordinator.processFrameText('Du bist entkommen!', instanceIndex: 1);
        await service.waitForIdle();
        clock += const Duration(milliseconds: 400);
      }

      // 4th encounter: red flash at +100ms ignored, green frame at +750ms triggers false/shiny alert
      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      clock += const Duration(milliseconds: 100);
      source.emitVisualFrame(1, 230, 40, 40);
      await service.waitForIdle();
      expect(service.activeShinyAlertsNotifier.value, isEmpty);

      clock += const Duration(milliseconds: 650);
      source.emitVisualFrame(1, 30, 220, 65);
      await service.waitForIdle();
      expect(service.activeShinyAlertsNotifier.value.length, equals(1));

      // Dismissing / resuming resets the color baseline so shifting lighting (green) does NOT lock future encounters
      service.resumeShinyPausedSlot(1);
      expect(service.activeShinyAlertsNotifier.value, isEmpty);

      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      clock += const Duration(milliseconds: 750);
      source.emitVisualFrame(1, 30, 220, 65);
      await service.waitForIdle();
      expect(service.activeShinyAlertsNotifier.value, isEmpty);

      await service.stopSession();
      await source.dispose();
      await coordinator.dispose();
    });

    test('undoEntry on older log preserves pausedByShiny, sessionGeneration discards stale queued tasks, and single slot 2 syncs slotConfigs[0]', () async {
      var clock = Duration.zero;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-u', pokemonId: 25, pokemonName: 'Pikachu', method: 'Wild'));

      final coordinator = buildTestCoordinator(() => clock);
      final source = _FakeTransitionSource();
      await source.start();
      final service = ShinyAutoCounterService.forTesting(elapsedClock: () => clock);

      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        source: source,
        defaultHuntId: 'hunt-u',
        slotIds: const [2],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          blackLumaThreshold: 42,
          minResetCooldownMs: 200,
          autoPauseSlotOnShiny: true,
        ),
      );

      // Single non-1 slot (Slot 2) must also configure slotConfigs[0]
      expect(source.lastSlotConfigs[0]?.blackThreshold, equals(42));
      expect(source.lastSlotConfigs[2]?.blackThreshold, equals(42));

      // Encounter 1 (non-shiny)
      await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 2);
      await service.waitForIdle();
      final firstEntryId = service.recentLogs.first.id;
      await coordinator.processFrameText('Du bist entkommen!', instanceIndex: 2);
      await service.waitForIdle();
      clock += const Duration(milliseconds: 300);

      // Encounter 2 (shiny -> pausedByShiny)
      await coordinator.processFrameText('Wildes ✨ Pikachu erscheint!', instanceIndex: 2);
      await service.waitForIdle();
      expect(service.slotStatesNotifier.value.single.phase, equals(ShinySlotPhase.pausedByShiny));

      // Undoing older entry 1 must NOT silently unpause active pausedByShiny slot
      expect(service.undoEntry(firstEntryId), isTrue);
      expect(service.slotStatesNotifier.value.single.phase, equals(ShinySlotPhase.pausedByShiny));

      // Stop and restart immediately -> old session logs/tasks do not leak into new session
      await service.stopSession();
      service.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        source: source,
        defaultHuntId: 'hunt-u',
        slotIds: const [1],
      );
      expect(service.recentLogs, isEmpty);

      await service.stopSession();
      await source.dispose();
      await coordinator.dispose();
    });

    test('ShinyHuntProvider: unfocused desktop ticks all active auto-hunted hunts and flushPendingWrites preserves dirty IDs on DB error', () async {
      final failingDb = _FailingSaveDatabaseService();
      final failProvider = ShinyHuntProvider(
        databaseService: failingDb,
        enableTimer: true,
      );
      await failProvider.initialized;
      await failProvider.createHunt(_makeHunt(id: 'h-err', pokemonId: 4, pokemonName: 'Glumanda'));
      failProvider.incrementAuto('h-err');

      failingDb.failSave = true;
      await expectLater(failProvider.flushPendingWrites(), throwsStateError);
      // Dirty ID must NOT be lost on error — retrying when DB recovers must persist the updated count!
      failingDb.failSave = false;
      await failProvider.flushPendingWrites();
      expect(failingDb.savedCounts['h-err'], equals(1));
      failProvider.dispose();

      // Multi-hunt stopwatch ticking while unfocused on Desktop (AppLifecycleState.inactive)
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: true,
      );
      await provider.initialized;
      await provider.createHunt(_makeHunt(id: 'hunt-1', pokemonId: 150, pokemonName: 'Mewtu'));
      await provider.createHunt(_makeHunt(id: 'hunt-2', pokemonId: 4, pokemonName: 'Glumanda'));

      // Simulate user clicking into emulator on Windows (AppLifecycleState.inactive)
      provider.didChangeAppLifecycleState(AppLifecycleState.inactive);
      provider.setAutoCounterActiveHunts({'hunt-1', 'hunt-2'}, isRunningAndUnpaused: true);
      provider.registerInteraction();

      await Future<void>.delayed(const Duration(milliseconds: 1150));
      expect(provider.getHuntById('hunt-1')!.totalTimeSeconds, greaterThanOrEqualTo(1));
      expect(provider.getHuntById('hunt-2')!.totalTimeSeconds, greaterThanOrEqualTo(1));
      provider.dispose();
    });
  });
}

class _FailingSaveDatabaseService extends Fake implements DatabaseService {
  bool failSave = false;
  final Map<String, int> savedCounts = {};

  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async => [];

  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) async {
    if (failSave) throw StateError('SQLITE_BUSY');
    savedCounts[hunt.id] = hunt.currentEncounters;
  }
}
