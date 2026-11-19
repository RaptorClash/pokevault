import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_tracker_service.dart';
import 'package:pokevault/services/desktop_tracker/desktop_window_source.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/desktop_tracker/windows_desktop_bridge.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';

class _FakeBridge implements DesktopPlatformBridge {
  bool hudVisible = false;
  int clearedBordersCount = 0;
  @override
  ValueChanged<NativeHudAction>? onHudAction;
  @override
  Future<CapturedFrame?> captureRegion(ScreenRegion region) async => null;
  @override
  Future<CapturedFrame?> captureWindow(
    DesktopWindowInfo window, {
    Rect? cropRegion,
  }) async =>
      null;
  @override
  Future<List<DesktopWindowInfo>> enumerateWindowsAndMonitors() async =>
      const [];
  @override
  Future<void> hideFloatingHud() async {
    hudVisible = false;
  }
  @override
  Future<OcrRecognitionResult> recognizeText(
    CapturedFrame frame, {
    String? languageTag,
    String? preprocessProfile,
  }) async =>
      const OcrRecognitionResult(lines: []);
  @override
  Future<void> setOverlayBorders(List<OverlayBorderSpec> borders) async {
    if (borders.isEmpty) clearedBordersCount++;
  }
  @override
  Future<void> setScanRegionBorder(ScreenRegion? region, {bool active = true}) async {
    if (region == null) clearedBordersCount++;
  }
  @override
  Future<bool> showFloatingHud(NativeHudState state) async {
    hudVisible = true;
    return true;
  }
  @override
  Future<ScreenRegionCaptureResult?> startDesktopSnipping({bool hideAppWindow = false}) async => null;
  @override
  Future<bool> updateFloatingHud(NativeHudState state) async => true;
}

void main() {
  group('DesktopTrackerService Tests (TDD)', () {
    late DesktopTrackerService service;

    setUp(() {
      service = DesktopTrackerService();
    });

    tearDown(() async {
      await service.stopTracking();
    });

    test('Initial state is inactive with no active tracking', () {
      expect(service.isTrackingActive, isFalse);
      expect(service.latestEvent, isNull);
      expect(service.showFloatingHud, isFalse);
    });

    test('Starting tracking activates service and updates coordinator', () {
      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([]),
        settings: ScannerSettings.defaults(),
      );

      service.startTracking(coordinator: coordinator, dexId: 'dex_kanto');

      expect(service.isTrackingActive, isTrue);
      expect(service.activeDexId, 'dex_kanto');
      expect(service.coordinator, equals(coordinator));
    });

    test('Stopping tracking cleans up and resets state', () async {
      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([]),
        settings: ScannerSettings.defaults(),
      );

      service.startTracking(coordinator: coordinator);
      expect(service.isTrackingActive, isTrue);

      await service.stopTracking();
      expect(service.isTrackingActive, isFalse);
      expect(service.latestEvent, isNull);
    });

    test('Processes events and notifies listeners', () {
      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([]),
        settings: ScannerSettings.defaults(),
      );

      service.startTracking(coordinator: coordinator);

      ScannerEvent? notifiedEvent;
      service.latestEventNotifier.addListener(() {
        notifiedEvent = service.latestEventNotifier.value;
      });

      final testEvent = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Pikachu',
        pokemonId: 25,
        rawText: 'Ein wildes Pikachu erscheint!',
        timestamp: DateTime.now(),
      );

      service.handleScannerEvent(testEvent);

      expect(notifiedEvent, isNotNull);
      expect(notifiedEvent!.matchedName, 'Pikachu');
      expect(service.latestEvent, equals(testEvent));
    });

    test('Toggles pause and floating HUD visibility correctly', () {
      expect(service.showFloatingHud, isFalse);
      service.toggleFloatingHud();
      expect(service.showFloatingHud, isTrue);
      service.toggleFloatingHud();
      expect(service.showFloatingHud, isFalse);

      service.isPaused = false;
      service.togglePause();
      expect(service.isPaused, isTrue);
      service.togglePause();
      expect(service.isPaused, isFalse);
    });

    test('stopTracking clears native borders, hides HUD, and disposes owned windowSource', () async {
      final fakeBridge = _FakeBridge();
      final source = DesktopWindowSource(
        captureDriver: const DefaultDesktopCaptureDriver(),
        ocrDriver: DefaultDesktopOcrDriver(),
      );
      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([]),
        settings: ScannerSettings.defaults(),
      );
      coordinator.bindSource(source);

      service.configureNativeHudBridge(bridge: fakeBridge);
      service.startTracking(
        coordinator: coordinator,
        windowSource: source,
        ownsWindowSource: true,
      );
      await service.setFloatingHudVisible(true);
      expect(fakeBridge.hudVisible, isTrue);

      await service.stopTracking();
      expect(fakeBridge.hudVisible, isFalse);
      expect(fakeBridge.clearedBordersCount, greaterThanOrEqualTo(2));
      expect(source.isDisposed, isTrue);
      await coordinator.dispose();
    });

    test('recentEvents caches emitted events across Setup screen reopens', () {
      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([]),
        settings: ScannerSettings.defaults(),
      );
      service.startTracking(coordinator: coordinator);
      final ev = ScannerEvent(
        type: ScannerEventType.caught,
        matchedName: 'Glumanda',
        pokemonId: 4,
        rawText: 'Glumanda gefangen!',
        timestamp: DateTime.now(),
      );
      service.recordUiEvent(ev);
      expect(service.recentEvents.length, 1);
      expect(service.recentEvents.first.matchedName, 'Glumanda');
    });
  });
}
