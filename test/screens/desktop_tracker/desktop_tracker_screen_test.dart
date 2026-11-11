import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/compact_mini_hud.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';

class MockDexProvider extends Mock implements DexProvider {}

class FakeUserDex extends Fake implements UserDex {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserDex());
  });

  group('DesktopTrackerScreen Widget Tests (TDD)', () {
    late ScannerCoordinator coordinator;
    late MockScannerSource mockSource;
    late MockDexProvider mockDexProvider;

    final kantoDex = UserDex(
      id: 'dex_kanto',
      title: 'Kanto Living Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['1'],
    );

    final johtoDex = UserDex(
      id: 'dex_johto',
      title: 'Johto Living Dex',
      region: 'johto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['152'],
    );

    setUp(() {
      mockSource = MockScannerSource();
      mockDexProvider = MockDexProvider();

      when(() => mockDexProvider.userDexes).thenReturn([kantoDex, johtoDex]);
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);
      when(() => mockDexProvider.saveUserDexAndSync(any()))
          .thenAnswer((_) async {});

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

    Widget createWidgetUnderTest({
      String? initialDexId,
      List<DesktopWindowInfo>? detectedWindows,
    }) {
      return ChangeNotifierProvider<DexProvider>.value(
        value: mockDexProvider,
        child: MaterialApp(
          home: DesktopTrackerScreen(
            coordinator: coordinator,
            initialDexId: initialDexId,
            detectedWindows: detectedWindows ?? const [
              DesktopWindowInfo(id: 1, title: 'mGBA - Pokemon Feuerrot', emulatorType: EmulatorType.mgba),
              DesktopWindowInfo(id: 2, title: 'Ryujinx - Pokémon Karmesin', emulatorType: EmulatorType.ryujinx),
            ],
          ),
        ),
      );
    }

    testWidgets('Renders DesktopTrackerScreen with mode buttons and window selector', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Desktop Tracker & Overlay'), findsOneWidget);
      expect(find.byKey(const Key('tab_dashboard')), findsOneWidget);
      expect(find.byKey(const Key('tab_mini_hud')), findsOneWidget);
      expect(find.byKey(const Key('tab_silent')), findsOneWidget);
      expect(find.byKey(const Key('emulator_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('target_dex_dropdown')), findsOneWidget);
    });

    testWidgets('Pre-selects target dex from initialDexId', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(initialDexId: 'dex_johto'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Johto Living Dex'), findsWidgets);
    });

    testWidgets('Displays live scanner event and marks caught in target dex', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(initialDexId: 'dex_kanto'));
      await tester.pumpAndSettle();

      // Process catch text through coordinator
      await coordinator.processText('Glumanda wurde gefangen!');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Glumanda'), findsWidgets);

      // Verify "In Ziel-Dex eintragen" button is visible and tap it
      final markBtn = find.byKey(const Key('btn_mark_caught_in_dex'));
      expect(markBtn, findsOneWidget);

      await tester.tap(markBtn);
      await tester.pumpAndSettle();

      expect(kantoDex.caughtIds, contains('4'));
      verify(() => mockDexProvider.saveUserDexAndSync(kantoDex)).called(2);
    });

    testWidgets('Toggles to CompactMiniHud mode on button tap', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap mini-HUD tab
      await tester.tap(find.byKey(const Key('tab_mini_hud')));
      await tester.pumpAndSettle();

      expect(find.byType(CompactMiniHud), findsOneWidget);
    });
  });
}
