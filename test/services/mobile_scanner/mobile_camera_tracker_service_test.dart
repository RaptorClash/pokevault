import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_source.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_tracker_service.dart';
import 'package:pokevault/services/mobile_scanner/mobile_ocr_driver.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_service.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('MobileCameraTrackerService Tests (TDD)', () {
    late MobileCameraTrackerService service;
    late ScannerCoordinator coordinator;
    late MobileCameraSource source;

    setUp(() async {
      service = MobileCameraTrackerService.instance;
      await service.stopSession();
      coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
        ]),
      );
      source = MobileCameraSource(
        ocrDriver: MobileOcrDriver(customRecognizer: (_, _) async => const []),
      );
    });

    tearDown(() async {
      await service.stopSession();
      await coordinator.dispose();
      await source.dispose();
    });

    test('manages session lifecycle, PiP transitions, and clamped drag position', () async {
      service.startSession(
        coordinator: coordinator,
        cameraSource: source,
        dexId: 'dex_kanto',
      );

      expect(service.isTrackingActive, isTrue);
      expect(service.activeDexId, 'dex_kanto');
      expect(service.isPipVisible, isFalse);

      service.enterPipMode();
      expect(service.isPipVisible, isTrue);
      expect(service.viewMode, MobileScannerViewMode.pip);

      // Extreme out-of-bounds drag should clamp safely inside screen bounds
      service.updatePipPosition(
        const Offset(-500, 5000),
        screenSize: const Size(390, 844),
        safePadding: const EdgeInsets.only(top: 44, bottom: 34),
        pipSize: const Size(164, 140),
      );
      final clamped = service.pipPosition;
      expect(clamped.dx, greaterThanOrEqualTo(8));
      expect(clamped.dy, lessThanOrEqualTo(844 - 34 - 140));

      service.exitPipMode(targetMode: MobileScannerViewMode.split);
      expect(service.isPipVisible, isFalse);
      expect(service.viewMode, MobileScannerViewMode.split);
    });

    test('toggles pause, scan mode, regions, and stores latest events cleanly', () async {
      service.startSession(
        coordinator: coordinator,
        cameraSource: source,
        dexId: 'dex_kanto',
      );

      service.setScanMode(MobileCameraScanMode.customRegions);
      expect(service.scanMode, MobileCameraScanMode.customRegions);
      expect(source.scanMode, MobileCameraScanMode.customRegions);

      final rect = NormalizedScanRect(
        id: 'zone_a',
        role: CameraZoneRole.scan,
        left: 0.1,
        top: 0.7,
        width: 0.8,
        height: 0.2,
        colorHex: 0xFF10B981,
        label: 'Zone A',
      );
      service.addOrUpdateRegion(rect);
      expect(service.regions, [rect]);
      expect(source.regions, [rect]);

      final ev = ScannerEvent(
        type: ScannerEventType.caught,
        pokemonId: 4,
        rawText: 'Glumanda wurde gefangen!',
        matchedName: 'Glumanda',
        isShiny: true,
        timestamp: DateTime(2026),
      );
      service.handleScannerEvent(ev);
      expect(service.latestEvent?.pokemonId, 4);

      service.togglePause();
      expect(service.isPaused, isTrue);
      service.togglePause();
      expect(service.isPaused, isFalse);

      await service.stopSession();
      expect(service.isTrackingActive, isFalse);
      expect(service.isPipVisible, isFalse);
      expect(service.latestEvent, isNull);
    });

    test('stopSession invokes onDisableWakelock callback exactly once when PiP closes', () async {
      int wakelockDisableCount = 0;
      service.startSession(
        coordinator: coordinator,
        cameraSource: source,
        dexId: 'dex_kanto',
      );
      service.attachPipCallbacks(
        onDisableWakelock: () async {
          wakelockDisableCount++;
        },
      );
      service.enterPipMode();

      await service.stopSession();
      expect(wakelockDisableCount, 1);

      // Stopping again must not invoke stale callback
      await service.stopSession();
      expect(wakelockDisableCount, 1);
    });

    test('setRegions & setScanMode sync slot additions/removals live to ShinyAutoCounterService', () async {
      SharedPreferences.setMockInitialValues({});
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final provider = ShinyHuntProvider(
        databaseService: DatabaseService.instance,
        enableTimer: false,
      );
      await provider.initialized;
      final now = DateTime.now();
      await provider.createHunt(
        ShinyHunt(
          id: 'mob-hunt',
          title: 'Glumanda',
          pokemonId: 4,
          pokemonName: 'Glumanda',
          game: 'Violet',
          generation: 9.0,
          method: 'Wild',
          baseOdds: 4096.0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      service.startSession(
        coordinator: coordinator,
        cameraSource: source,
        dexId: 'dex_kanto',
      );
      final autoCounter = ShinyAutoCounterService.instance;
      autoCounter.startSession(
        huntProvider: provider,
        coordinator: coordinator,
        source: source,
        defaultHuntId: 'mob-hunt',
        slotIds: const [1],
      );

      service.setScanMode(MobileCameraScanMode.customRegions);
      service.setRegions([
        NormalizedScanRect(
          id: 'multi_2_scan',
          role: CameraZoneRole.multiInstance,
          slotId: 2,
          left: 0.0,
          top: 0.5,
          width: 0.5,
          height: 0.5,
          colorHex: 0xFFA855F7,
          label: '#2',
        ),
      ]);
      expect(autoCounter.slotStatesNotifier.value.map((s) => s.slotId), equals([2]));

      service.togglePause();
      expect(autoCounter.isPaused, isTrue);
      service.togglePause();
      expect(autoCounter.isPaused, isFalse);

      await autoCounter.stopSession();
      provider.dispose();
    });
  });
}
