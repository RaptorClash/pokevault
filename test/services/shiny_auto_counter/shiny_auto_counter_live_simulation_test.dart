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
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_tracker_service.dart';
import 'package:pokevault/services/desktop_tracker/desktop_window_source.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/feedback/scanner_feedback.dart';
import 'package:pokevault/services/scanner_core/media/frame_transition_detector.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_config.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_service.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_slot_state_machine.dart';

class _SimPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory dir;
  _SimPathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

class _SimMultiSlotSource
    implements VisualFrameScannerSource, FrameTransitionScannerSource {
  final StreamController<String> _text = StreamController<String>.broadcast();
  final StreamController<SlotVisualFrame> _visual =
      StreamController<SlotVisualFrame>.broadcast();
  final StreamController<FrameTransitionEvent> _transitions =
      StreamController<FrameTransitionEvent>.broadcast();
  bool _running = false;
  Map<int, SlotTransitionConfig> lastSlotConfigs = const {};

  @override
  Stream<String> get textStream => _text.stream;

  @override
  Stream<SlotVisualFrame> get visualFrameStream => _visual.stream;

  @override
  Stream<FrameTransitionEvent> get transitionStream => _transitions.stream;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async => _running = true;

  @override
  Future<void> stop() async => _running = false;

  @override
  void updateTransitionMinDuration(Duration duration) {}

  @override
  void updateTransitionThresholds({
    required int blackThreshold,
    required int whiteThreshold,
  }) {}

  @override
  void updateSlotTransitionConfigs(Map<int, SlotTransitionConfig> configs) {
    lastSlotConfigs = Map.unmodifiable(configs);
  }

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
    await _transitions.close();
  }
}

class _RecordingFeedback implements ScannerFeedback {
  int encounters = 0;
  int shinies = 0;

  @override
  Future<void> onCaught(ScannerEvent event) async {}

  @override
  Future<void> onEncounter(ScannerEvent event) async => encounters++;

  @override
  Future<void> onEvolved(ScannerEvent event) async {}

  @override
  Future<void> onShiny(ScannerEvent event) async => shinies++;
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

ScannerCoordinator _buildCoordinator(Duration Function() clock) {
  final matcher = PokemonFuzzyMatcher.withEntries(const [
    PokemonMatcherEntry(id: 150, name: 'Mewtu', language: 'de'),
    PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
    PokemonMatcherEntry(id: 41, name: 'Zubat', language: 'de'),
    PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
    PokemonMatcherEntry(id: 493, name: 'Arceus', language: 'de'),
  ]);
  return ScannerCoordinator(
    engine: OcrDetectionEngine(),
    matcher: matcher,
    elapsedClock: clock,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('pokevault_auto_live_sim_');
    PathProviderPlatform.instance = _SimPathProvider(tempDir);
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await DatabaseService.instance.clearUserData();
    await DesktopTrackerService.instance.stopTracking();
  });

  group('E2E Live Simulation: ShinyAutoCounterService', () {
    test(
      '4-slot concurrent hunts, per-hunt rules, double battle, frame-2 Shiny upgrade, fast-forward cooldown race, and visual heuristic baseline recovery',
      () async {
        var clock = Duration.zero;
        final provider = ShinyHuntProvider(
          databaseService: DatabaseService.instance,
          enableTimer: false,
        );
        await provider.initialized;

        await provider.createHunt(
          _makeHunt(id: 'hunt-sr', pokemonId: 150, pokemonName: 'Mewtu', method: 'Soft Reset'),
        );
        await provider.createHunt(
          _makeHunt(id: 'hunt-wild', pokemonId: 25, pokemonName: 'Pikachu', method: 'Wild'),
        );
        await provider.createHunt(
          _makeHunt(id: 'hunt-egg', pokemonId: 4, pokemonName: 'Glumanda', method: 'Masuda Method (Egg)'),
        );
        await provider.createHunt(
          _makeHunt(id: 'hunt-arceus', pokemonId: 493, pokemonName: 'Arceus', method: 'Outbreak'),
        );

        final coordinator = _buildCoordinator(() => clock);
        final source = _SimMultiSlotSource();
        await source.start();
        final feedback = _RecordingFeedback();
        final service = ShinyAutoCounterService.forTesting(
          elapsedClock: () => clock,
          feedback: feedback,
        );

        service.startSession(
          huntProvider: provider,
          coordinator: coordinator,
          source: source,
          defaultHuntId: 'hunt-sr',
          slotIds: const [1, 2, 3, 4],
          settings: const ShinyAutoCounterSettings(
            detectionMode: ShinyHuntDetectionMode.softReset,
            matchFilter: ShinyMatchFilter.targetPokemonOnly,
            minResetCooldownMs: 400,
            enableBlackScreenReset: true,
            enableWhiteScreenReset: false,
            autoPauseSlotOnShiny: true,
            slotToHuntOverrides: {
              1: 'hunt-sr',
              2: 'hunt-wild',
              3: 'hunt-egg',
              4: 'hunt-arceus',
            },
            huntSettingsOverrides: {
              'hunt-wild': ShinyAutoCounterSettings(
                detectionMode: ShinyHuntDetectionMode.wildEncounter,
                matchFilter: ShinyMatchFilter.allPokemon,
                useEventEncounterCount: true,
                minResetCooldownMs: 300,
                enableBlackScreenReset: true,
                enableColorDeviationShinyCheck: true,
                colorDeviationThreshold: 0.35,
              ),
              'hunt-egg': ShinyAutoCounterSettings(
                detectionMode: ShinyHuntDetectionMode.eggHatch,
                matchFilter: ShinyMatchFilter.targetPokemonOnly,
                minResetCooldownMs: 300,
              ),
              'hunt-arceus': ShinyAutoCounterSettings(
                detectionMode: ShinyHuntDetectionMode.screenTransitionOnly,
                enableBlackScreenReset: true,
                enableWhiteScreenReset: false,
                minResetCooldownMs: 300,
              ),
            },
          ),
        );

        // Verify distinct per-slot transition configs reached the source
        expect(source.lastSlotConfigs[4]?.blackThreshold, equals(18));
        expect(source.lastSlotConfigs[1]?.whiteThreshold, equals(240));

        // 1) Slot 1 decoy non-target skipped; Slot 2 double encounter (+2);
        //    Slot 3 egg prompt "Nanu?!" + hatch (+1); Slot 4 screen transition (+1)
        await coordinator.processFrameText('Ein wildes Zubat erscheint!', instanceIndex: 1);
        await coordinator.processFrameText(
          'Pikachu Lv.5\nPikachu Lv.5',
          encounterOnly: true,
          instanceIndex: 2,
        );
        await coordinator.processFrameText('Nanu?!', instanceIndex: 3);
        await coordinator.processFrameText(
          'Aus dem Ei ist ein Glumanda geschlüpft!',
          instanceIndex: 3,
        );
        await service.handleFrameTransition(
          FrameTransitionEvent(
            slotId: 4,
            type: FrameTransitionType.blackScreenEnded,
            durationMs: 420,
            averageLuma: 3,
            timestamp: DateTime.now(),
          ),
        );
        await service.waitForIdle();

        expect(provider.getHuntById('hunt-sr')!.currentEncounters, equals(0));
        expect(provider.getHuntById('hunt-wild')!.currentEncounters, equals(2));
        expect(provider.getHuntById('hunt-egg')!.currentEncounters, equals(1));
        expect(provider.getHuntById('hunt-arceus')!.currentEncounters, equals(1));

        // 2) Visual Shiny 700ms settle delay on Slot 2:
        //    Early +100ms red flash ignored; +750ms calm blue baseline learned over 3 encounters
        clock += const Duration(milliseconds: 750);
        source.emitVisualFrame(2, 30, 110, 235);
        await service.waitForIdle();

        for (int b = 0; b < 2; b++) {
          await coordinator.processFrameText('Du bist entkommen!', instanceIndex: 2);
          await service.handleFrameTransition(
            FrameTransitionEvent(
              slotId: 2,
              type: FrameTransitionType.blackScreenEnded,
              durationMs: 400,
              averageLuma: 2,
              timestamp: DateTime.now(),
            ),
          );
          clock += const Duration(milliseconds: 400);
          await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 2);
          await service.waitForIdle();
          clock += const Duration(milliseconds: 100);
          source.emitVisualFrame(2, 235, 35, 35); // pre-700ms flash ignored
          await service.waitForIdle();
          clock += const Duration(milliseconds: 650);
          source.emitVisualFrame(2, 30, 110, 235); // blue baseline
          await service.waitForIdle();
        }
        expect(provider.getHuntById('hunt-wild')!.currentEncounters, equals(4));
        expect(service.activeShinyAlertsNotifier.value, isEmpty);

        // False-positive shift -> alert -> dismiss via resumeShinyPausedSlot -> baseline re-learns
        await service.handleFrameTransition(
          FrameTransitionEvent(
            slotId: 2,
            type: FrameTransitionType.blackScreenEnded,
            durationMs: 400,
            averageLuma: 2,
            timestamp: DateTime.now(),
          ),
        );
        clock += const Duration(milliseconds: 400);
        await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 2);
        await service.waitForIdle();
        clock += const Duration(milliseconds: 750);
        source.emitVisualFrame(2, 35, 225, 65);
        await service.waitForIdle();
        expect(service.activeShinyAlertsNotifier.value.length, equals(1));
        expect(service.activeShinyAlertsNotifier.value.first.pokemonName, equals('Pikachu'));

        service.resumeShinyPausedSlot(2);
        expect(service.activeShinyAlertsNotifier.value, isEmpty);

        // After resuming & clearing detector baseline, next green encounter stays calm
        await coordinator.processFrameText('Du bist entkommen!', instanceIndex: 2);
        clock += const Duration(milliseconds: 400);
        await coordinator.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 2);
        await service.waitForIdle();
        clock += const Duration(milliseconds: 750);
        source.emitVisualFrame(2, 35, 225, 65);
        await service.waitForIdle();
        expect(service.activeShinyAlertsNotifier.value, isEmpty);

        // 3) Slot 1 fast-forward cooldown race + Frame-2 Shiny upgrade:
        //    Normal encounter -> quick black screen (< cooldown) -> cooldown expires -> early OCR triggers count
        await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
        await service.waitForIdle();
        expect(provider.getHuntById('hunt-sr')!.currentEncounters, equals(1));

        // Transition happens while minResetCooldownMs (400ms) hasn't elapsed yet -> enters rearmPending
        clock += const Duration(milliseconds: 100);
        await service.handleFrameTransition(
          FrameTransitionEvent(
            slotId: 1,
            type: FrameTransitionType.blackScreenEnded,
            durationMs: 400,
            averageLuma: 2,
            timestamp: DateTime.now(),
          ),
        );
        await service.waitForIdle();
        expect(
          service.slotStatesNotifier.value.firstWhere((s) => s.slotId == 1).phase,
          equals(ShinySlotPhase.rearmPending),
        );

        // Fast-forward past cooldown without another black screen -> early OCR still rearms & counts!
        clock += const Duration(milliseconds: 500);
        await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
        await service.waitForIdle();
        expect(provider.getHuntById('hunt-sr')!.currentEncounters, equals(2));

        // Frame-2 Shiny upgrade in the SAME battle (within re-recognition without black screen)
        clock += const Duration(milliseconds: 250);
        await coordinator.processFrameText('✨ Ein wildes Mewtu erscheint! ✨', instanceIndex: 1);
        await service.waitForIdle();

        // Count does NOT double-increment, and slot 1 pauses with Shiny Alert
        expect(provider.getHuntById('hunt-sr')!.currentEncounters, equals(2));
        expect(
          service.slotStatesNotifier.value.firstWhere((s) => s.slotId == 1).phase,
          equals(ShinySlotPhase.pausedByShiny),
        );
        expect(
          service.activeShinyAlertsNotifier.value.any((a) => a.slotId == 1 && a.isShiny),
          isTrue,
        );

        // 4) Phase Shiny detection on wild allPokemon hunt (hunting Pikachu, Shiny Zubat appears)
        clock += const Duration(milliseconds: 500);
        await coordinator.processFrameText('Du bist entkommen!', instanceIndex: 2);
        await service.handleFrameTransition(
          FrameTransitionEvent(
            slotId: 2,
            type: FrameTransitionType.blackScreenEnded,
            durationMs: 400,
            averageLuma: 2,
            timestamp: DateTime.now(),
          ),
        );
        clock += const Duration(milliseconds: 500);
        await coordinator.processFrameText('Ein wildes Shiny Zubat erscheint!', instanceIndex: 2);
        await service.waitForIdle();
        final phaseAlert = service.activeShinyAlertsNotifier.value
            .where((a) => a.slotId == 2)
            .firstOrNull;
        expect(phaseAlert, isNotNull);
        expect(phaseAlert!.pokemonName, equals('Zubat'));

        await service.stopSession();
        await source.dispose();
        await coordinator.dispose();
      },
    );

    test(
      'Unfocused desktop stopwatch ticks active auto-hunted hunts on AppLifecycleState.inactive, stops on pause, and Capture-Card activeSource stays exposed',
      () async {
        var clock = Duration.zero;
        final provider = ShinyHuntProvider(
          databaseService: DatabaseService.instance,
          enableTimer: true,
        );
        await provider.initialized;

        final h1 = _makeHunt(id: 'hunt-watch-1', pokemonId: 150, pokemonName: 'Mewtu');
        final h2 = _makeHunt(id: 'hunt-watch-2', pokemonId: 25, pokemonName: 'Pikachu', method: 'Wild');
        await provider.createHunt(h1);
        await provider.createHunt(h2);

        final coordinator = _buildCoordinator(() => clock);
        final windowSource = DesktopWindowSource(
          captureDriver: const DefaultDesktopCaptureDriver(),
          ocrDriver: DefaultDesktopOcrDriver(),
        );
        final captureCardSource = _SimMultiSlotSource();
        await captureCardSource.start();

        // Handoff to Capture-Card/Webcam source in DesktopTrackerService
        DesktopTrackerService.instance.startTracking(
          coordinator: coordinator,
          windowSource: windowSource,
          activeSource: captureCardSource,
          initiallyPaused: false,
        );
        expect(DesktopTrackerService.instance.activeSource, same(captureCardSource));

        final service = ShinyAutoCounterService.forTesting(
          elapsedClock: () => clock,
        );
        service.startSession(
          huntProvider: provider,
          coordinator: coordinator,
          source: DesktopTrackerService.instance.activeSource,
          defaultHuntId: h1.id,
          slotIds: const [1, 2],
          settings: const ShinyAutoCounterSettings(
            detectionMode: ShinyHuntDetectionMode.wildEncounter,
            slotToHuntOverrides: {1: 'hunt-watch-1', 2: 'hunt-watch-2'},
          ),
        );

        // Simulate user focusing Emulator/Capture window instead of PokéVault
        provider.didChangeAppLifecycleState(AppLifecycleState.inactive);
        final t1Before = provider.getHuntById(h1.id)!.totalTimeSeconds;
        final t2Before = provider.getHuntById(h2.id)!.totalTimeSeconds;

        await Future<void>.delayed(const Duration(milliseconds: 2250));
        expect(provider.getHuntById(h1.id)!.totalTimeSeconds, greaterThan(t1Before));
        expect(provider.getHuntById(h2.id)!.totalTimeSeconds, greaterThan(t2Before));

        // Global pause from Dock stops unfocused ticking
        service.setGlobalPause(true);
        final t1Paused = provider.getHuntById(h1.id)!.totalTimeSeconds;
        final t2Paused = provider.getHuntById(h2.id)!.totalTimeSeconds;

        await Future<void>.delayed(const Duration(milliseconds: 1300));
        expect(provider.getHuntById(h1.id)!.totalTimeSeconds, equals(t1Paused));
        expect(provider.getHuntById(h2.id)!.totalTimeSeconds, equals(t2Paused));

        await service.stopSession();
        await DesktopTrackerService.instance.stopTracking();
        await captureCardSource.dispose();
        await windowSource.dispose();
        await coordinator.dispose();
        provider.dispose();
      },
    );
  });
}
