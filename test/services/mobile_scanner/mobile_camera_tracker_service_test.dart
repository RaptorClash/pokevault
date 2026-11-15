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

void main() {
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
  });
}
