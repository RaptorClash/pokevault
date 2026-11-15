import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/mobile_scanner/widgets/mobile_camera_pip_overlay.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_source.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_tracker_service.dart';
import 'package:pokevault/services/mobile_scanner/mobile_ocr_driver.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';

void main() {
  group('MobileCameraPipOverlay Widget Tests (TDD)', () {
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

    testWidgets('is draggable, shows latest encounter, and keeps background app interactive', (tester) async {
      int backgroundClicks = 0;
      int expandClicks = 0;

      service.startSession(
        coordinator: coordinator,
        cameraSource: source,
        dexId: 'dex_kanto',
      );
      service.setRegions([
        NormalizedScanRect(
          id: 'zone_a',
          role: CameraZoneRole.scan,
          left: 0.1,
          top: 0.7,
          width: 0.8,
          height: 0.2,
          colorHex: 0xFF10B981,
          label: 'Zone A',
        ),
      ]);
      service.handleScannerEvent(
        ScannerEvent(
          type: ScannerEventType.caught,
          pokemonId: 4,
          rawText: 'Glumanda wurde gefangen!',
          matchedName: 'Glumanda',
          isShiny: true,
          timestamp: DateTime(2026),
        ),
      );
      service.enterPipMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: ElevatedButton(
                    key: const Key('bg_app_button'),
                    onPressed: () => backgroundClicks++,
                    child: const Text('Dex-Box öffnen'),
                  ),
                ),
                MobileCameraPipOverlay(
                  service: service,
                  onExpand: () => expandClicks++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Background button remains clickable while PiP is floating
      await tester.tap(find.byKey(const Key('bg_app_button')));
      expect(backgroundClicks, 1);

      expect(find.byKey(const Key('mobile_pip_window')), findsOneWidget);
      expect(find.textContaining('Glumanda'), findsOneWidget);

      // Drag PiP window
      final beforePos = service.pipPosition;
      await tester.drag(find.byKey(const Key('mobile_pip_drag_area')), const Offset(-60, -80));
      await tester.pump();
      expect(service.pipPosition, isNot(equals(beforePos)));

      // Pause/Resume inside PiP
      await tester.tap(find.byKey(const Key('btn_pip_toggle_pause')));
      await tester.pump();
      expect(service.isPaused, isTrue);

      // Expand back to full scanner
      await tester.tap(find.byKey(const Key('btn_pip_expand')));
      await tester.pump();
      expect(expandClicks, 1);

      // Close stops tracking & hides PiP
      await tester.tap(find.byKey(const Key('btn_pip_close')));
      await tester.pump();
      expect(service.isPipVisible, isFalse);
      expect(find.byKey(const Key('mobile_pip_window')), findsNothing);
    });
  });
}
