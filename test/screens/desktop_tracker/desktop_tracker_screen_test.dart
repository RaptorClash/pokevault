import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/compact_mini_hud.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';

void main() {
  group('DesktopTrackerScreen Widget Tests (TDD)', () {
    late ScannerCoordinator coordinator;
    late MockScannerSource mockSource;

    setUp(() {
      mockSource = MockScannerSource();
      coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([
          const PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
          const PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      coordinator.bindSource(mockSource);
    });

    tearDown(() async {
      await coordinator.dispose();
      await mockSource.dispose();
    });

    testWidgets('Renders DesktopTrackerScreen with mode buttons and window selector', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopTrackerScreen(
            coordinator: coordinator,
            detectedWindows: const [
              DesktopWindowInfo(id: 1, title: 'mGBA - Pokemon Feuerrot', emulatorType: EmulatorType.mgba),
              DesktopWindowInfo(id: 2, title: 'Ryujinx - Pokémon Karmesin', emulatorType: EmulatorType.ryujinx),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Desktop Tracker & Overlay'), findsOneWidget);
      expect(find.byKey(const Key('tab_dashboard')), findsOneWidget);
      expect(find.byKey(const Key('tab_mini_hud')), findsOneWidget);
      expect(find.byKey(const Key('tab_silent')), findsOneWidget);
      expect(find.byKey(const Key('emulator_dropdown')), findsOneWidget);
    });

    testWidgets('Displays live scanner event when text is recognized', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopTrackerScreen(
            coordinator: coordinator,
            detectedWindows: const [
              DesktopWindowInfo(id: 1, title: 'mGBA - Pokemon Feuerrot', emulatorType: EmulatorType.mgba),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Process catch text through coordinator
      await coordinator.processText('Glumanda wurde gefangen!');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Glumanda'), findsWidgets);
      expect(find.textContaining('#004'), findsWidgets);
    });

    testWidgets('Toggles to CompactMiniHud mode on button tap', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopTrackerScreen(
            coordinator: coordinator,
            detectedWindows: const [
              DesktopWindowInfo(id: 1, title: 'mGBA - Pokemon Feuerrot', emulatorType: EmulatorType.mgba),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap mini-HUD tab
      await tester.tap(find.byKey(const Key('tab_mini_hud')));
      await tester.pumpAndSettle();

      expect(find.byType(CompactMiniHud), findsOneWidget);
    });
  });
}
