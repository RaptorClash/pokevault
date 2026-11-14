import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_tracker_service.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';

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
  });
}
