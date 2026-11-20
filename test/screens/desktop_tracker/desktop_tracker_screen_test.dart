import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/dex_selection_modal.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/floating_overlay_hud.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/screen_snipping_overlay.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_system_snipping_service.dart';
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
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';

class MockCaptureDriver implements DesktopCaptureDriver {
  int captureCount = 0;
  Rect? lastCrop;
  ScreenRegion? lastScreenRegion;
  DesktopWindowInfo? lastWindow;

  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
    ScreenRegion? screenRegion,
  }) async {
    captureCount++;
    lastWindow = window;
    lastCrop = cropRegion;
    lastScreenRegion = screenRegion;
    return const CapturedFrame(
      width: 800,
      height: 600,
      bytes: [1, 2, 3],
    );
  }
}

class MockOcrDriver implements DesktopOcrDriver {
  String textToReturn = 'Glumanda wurde gefangen!';
  int ocrCount = 0;

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    ocrCount++;
    if (textToReturn.isEmpty) return [];
    return [textToReturn];
  }
}

class MockDexProvider extends Mock implements DexProvider {}

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  String currentLanguage = 'de';

  @override
  String pokemonLanguage = 'de';

  @override
  String get effectivePokemonLanguage => pokemonLanguage == 'auto' ? currentLanguage : pokemonLanguage;

  @override
  void setPokemonLanguage(String lang) {
    pokemonLanguage = lang;
    notifyListeners();
  }

  @override
  void setLanguage(String lang) {
    currentLanguage = lang;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserDex extends Fake implements UserDex {}

class FakeWindowsDesktopBridge implements DesktopPlatformBridge {
  final Future<bool> Function(NativeHudState state)? onShowHud;
  final Future<void> Function()? onHideHud;
  final List<({ScreenRegion? region, bool active})> borderCalls = [];

  FakeWindowsDesktopBridge({this.onShowHud, this.onHideHud});

  @override
  ValueChanged<NativeHudAction>? onHudAction;

  @override
  Future<void> setScanRegionBorder(
    ScreenRegion? region, {
    bool active = true,
  }) async {
    borderCalls.add((region: region, active: active));
  }

  @override
  Future<void> setOverlayBorders(List<OverlayBorderSpec> borders) async {
    if (borders.isEmpty) {
      borderCalls.add((region: null, active: false));
    } else {
      for (final b in borders) {
        borderCalls.add((region: b.region, active: true));
      }
    }
  }

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
    await onHideHud?.call();
  }

  @override
  Future<OcrRecognitionResult> recognizeText(
    CapturedFrame frame, {
    String? languageTag,
    String? preprocessProfile,
  }) async =>
      const OcrRecognitionResult();

  @override
  Future<bool> showFloatingHud(NativeHudState state) async {
    return (await onShowHud?.call(state)) ?? true;
  }

  @override
  Future<ScreenRegionCaptureResult?> startDesktopSnipping({
    bool hideAppWindow = false,
    String? hintLabel,
    String? confirmLabel,
    String? cancelLabel,
  }) async =>
      null;

  @override
  Future<bool> updateFloatingHud(NativeHudState state) async => true;
}

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
      await DesktopTrackerService.instance.stopTracking();
      await coordinator.dispose();
      await mockSource.dispose();
    });

    Widget createWidgetUnderTest({
      String? initialDexId,
      List<DesktopWindowInfo>? detectedWindows,
      DesktopWindowSource? windowSource,
      DesktopSystemSnippingService? snippingService,
    }) {
      return ChangeNotifierProvider<DexProvider>.value(
        value: mockDexProvider,
        child: MaterialApp(
          home: DesktopTrackerScreen(
            coordinator: coordinator,
            initialDexId: initialDexId,
            windowSource: windowSource,
            snippingService: snippingService,
            detectedWindows: detectedWindows ?? WindowDetector().getFallbackWindows(),
          ),
        ),
      );
    }

    testWidgets('Renders DesktopTrackerScreen with clean AppBar (NO redundant Nationaldex)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Desktop Tracker & Overlay'), findsOneWidget);
      // Redundant top-right AppBar Dex pill MUST be gone:
      expect(find.byKey(const Key('target_dex_pill')), findsNothing);

      // Window dropdown & controls should be present
      expect(find.byKey(const Key('emulator_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('card_active_target_dex')), findsOneWidget);
      expect(find.byKey(const Key('btn_open_floating_hud')), findsOneWidget);
      expect(find.byKey(const Key('btn_alert_settings')), findsOneWidget);
    });

    testWidgets('Pre-selects target dex from initialDexId and displays Dex Preview Card', (tester) async {
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

      await tester.scrollUntilVisible(markBtn, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(markBtn);
      await tester.pumpAndSettle();

      expect(kantoDex.caughtIds, contains('4'));
      verify(() => mockDexProvider.saveUserDexAndSync(kantoDex)).called(2);
    });

    testWidgets('Tapping Dex Preview Card opens DexSelectionModal and switches dex', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(initialDexId: 'dex_kanto'));
      await tester.pumpAndSettle();

      // Tap on Dex preview card
      await tester.tap(find.byKey(const Key('card_active_target_dex')));
      await tester.pumpAndSettle();

      expect(find.byType(DexSelectionModal), findsOneWidget);

      // Tap Johto Dex
      await tester.tap(find.text('Johto Living Dex'));
      await tester.pumpAndSettle();

      // Modal closed, Johto Dex is selected
      expect(find.byType(DexSelectionModal), findsNothing);
      expect(find.textContaining('Johto Living Dex'), findsWidgets);
    });

    testWidgets('Tapping Floating HUD button displays floating overlay HUD', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingOverlayHud), findsNothing);

      // Tap Floating HUD button in AppBar
      await tester.tap(find.byKey(const Key('btn_open_floating_hud')));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingOverlayHud), findsOneWidget);
    });

    testWidgets('Tapping Snipping button opens ScreenSnippingOverlay and saves crop', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final snippingBtn = find.byKey(const Key('btn_start_snipping'));
      expect(snippingBtn, findsOneWidget);
      await tester.tap(snippingBtn);
      await tester.pump();

      expect(find.byType(ScreenSnippingOverlay), findsOneWidget);

      // Drag to select rect (below AppBar and instruction bar)
      final gesture = await tester.startGesture(const Offset(100, 150));
      await tester.pump();
      await gesture.moveTo(const Offset(500, 300));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_confirm_snipping')));
      await tester.pumpAndSettle();

      // Snipping overlay closed and active mode label + snippet preview card updated
      expect(find.byType(ScreenSnippingOverlay), findsNothing);
      expect(find.textContaining('400×150'), findsWidgets);
      expect(
        tester.widget<Text>(find.byKey(const Key('label_active_scan_mode'))).data,
        contains('400×150'),
      );
    });

    testWidgets('Tapping Alert Settings opens Alert Settings Dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap alert settings button
      await tester.tap(find.byKey(const Key('btn_alert_settings')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alarm- & Signal-Einstellungen'), findsOneWidget);
      expect(find.byKey(const Key('switch_sound_shiny')), findsOneWidget);
      expect(find.byKey(const Key('switch_sound_alpha')), findsOneWidget);
      expect(find.byKey(const Key('switch_sound_normal')), findsOneWidget);
    });

    testWidgets('Refresh with changing window title does not crash dropdown assertion', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const initialWindows = [
        DesktopWindowInfo(
          id: 16404,
          title: '[92/60] melonDS 1.1',
          processName: 'melonDS.exe',
          emulatorType: EmulatorType.melonds,
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(detectedWindows: initialWindows));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emulator_dropdown')), findsOneWidget);
      expect(find.text('[92/60] melonDS 1.1'), findsOneWidget);
    });

    testWidgets('Target Dex Card calculates accurate progress and NEVER displays caught > total', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Dex with 1452 items in caughtIds (all base 1025 + extra forms/trades)
      final largeCaughtDex = UserDex(
        id: 'dex_national_large',
        title: 'Nationaldex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: false,
        includeGifts: false,
        isShinyDex: false,
        caughtIds: List.generate(1452, (i) => '${i + 1}'),
      );

      when(() => mockDexProvider.userDexes).thenReturn([largeCaughtDex]);

      await tester.pumpWidget(createWidgetUnderTest(initialDexId: 'dex_national_large'));
      await tester.pumpAndSettle();

      // Must NEVER display "1452 von 1025 gefangen"
      expect(find.text('1452 von 1025 gefangen'), findsNothing);
      expect(find.textContaining('1025 von 1025 gefangen'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
    });

    testWidgets('Scan Presets buttons for DS Top and Bottom screens update active scan mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // DS Top screen preset button
      final btnDsTop = find.byKey(const Key('btn_scan_mode_ds_top'));
      expect(btnDsTop, findsOneWidget);
      await tester.tap(btnDsTop);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('label_active_scan_mode')), findsOneWidget);
      expect(find.textContaining('DS Oben'), findsWidgets);

      // DS Bottom screen preset button
      final btnDsBottom = find.byKey(const Key('btn_scan_mode_ds_bottom'));
      expect(btnDsBottom, findsOneWidget);
      await tester.tap(btnDsBottom);
      await tester.pumpAndSettle();

      expect(find.textContaining('DS Unten'), findsWidgets);
    });

    testWidgets('Tapping "Jetzt scannen" triggers single scan and processes recognized text', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockCapture = MockCaptureDriver();
      final mockOcr = MockOcrDriver()..textToReturn = 'Ein wildes Pikachu erscheint!';
      final testSource = DesktopWindowSource(
        captureDriver: mockCapture,
        ocrDriver: mockOcr,
      );
      addTearDown(() async {
        await testSource.dispose();
      });

      await tester.pumpWidget(createWidgetUnderTest(windowSource: testSource));
      await tester.pumpAndSettle();

      final btnScanNow = find.byKey(const Key('btn_scan_now'));
      expect(btnScanNow, findsOneWidget);
      await tester.ensureVisible(btnScanNow);
      await tester.tap(btnScanNow);
      await tester.pumpAndSettle();

      expect(mockCapture.captureCount, greaterThanOrEqualTo(1));
      expect(mockOcr.ocrCount, greaterThanOrEqualTo(1));
      expect(find.text('Pikachu'), findsWidgets);
    });

    testWidgets('Dropdown contains Desktop / Primary Screen option and can be selected', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final dropdown = find.byKey(const Key('emulator_dropdown'));
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.textContaining('Desktop').last, findsOneWidget);
    });

    testWidgets('Removed Einzelbild (Win+Shift+S / Zwischenablage) and Schnelltest (OCR-Simulator) controls are absent', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_desktop_system_snipping')), findsNothing);
      expect(find.byKey(const Key('btn_paste_clipboard_screenshot')), findsNothing);
      expect(find.textContaining('Einzelbild:'), findsNothing);
      expect(find.textContaining('Schnelltest'), findsNothing);
      expect(find.textContaining('OCR-Simulator'), findsNothing);
    });

    testWidgets('Native desktopSnippingLauncher sets global multi-monitor ScreenRegion and shows coordinates preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final samplePng = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);

      final activeSource = DesktopWindowSource(
        captureDriver: MockCaptureDriver(),
        ocrDriver: MockOcrDriver(),
      );
      addTearDown(() async => await activeSource.dispose());

      int launchCount = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: WindowDetector().getFallbackWindows(),
              desktopSnippingLauncher: () async {
                launchCount++;
                return ScreenRegionCaptureResult(
                  region: ScreenRegion(
                    x: -1200,
                    y: 300,
                    width: 480,
                    height: 150,
                    isAbsoluteScreen: true,
                    label: 'Desktop-Snipping',
                  ),
                  previewBytes: samplePng,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_start_snipping')));
      await tester.pumpAndSettle();

      expect(launchCount, 1);
      expect(find.byType(ScreenSnippingOverlay), findsNothing);
      expect(activeSource.screenRegion, isNotNull);
      expect(activeSource.screenRegion!.x, -1200.0);
      expect(activeSource.screenRegion!.y, 300.0);
      expect(activeSource.screenRegion!.width, 480.0);
      expect(activeSource.screenRegion!.height, 150.0);
      expect(find.byKey(const Key('desktop_snippet_preview_card')), findsOneWidget);
      expect(find.textContaining('480×150'), findsWidgets);
    });

    testWidgets('Cancelling native desktopSnippingLauncher preserves existing scan region', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activeSource = DesktopWindowSource(
        captureDriver: MockCaptureDriver(),
        ocrDriver: MockOcrDriver(),
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: WindowDetector().getFallbackWindows(),
              desktopSnippingLauncher: () async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_start_snipping')));
      await tester.pumpAndSettle();

      expect(activeSource.screenRegion, isNull);
      expect(find.byKey(const Key('desktop_snippet_preview_card')), findsNothing);
    });

    testWidgets('Uses SettingsProvider effectivePokemonLanguage for OCR and updates dynamically on language change', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settingsProvider = MockSettingsProvider()..pokemonLanguage = 'de';
      final activeSource = DesktopWindowSource(
        captureDriver: MockCaptureDriver(),
        ocrDriver: MockOcrDriver(),
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: WindowDetector().getFallbackWindows(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(activeSource.ocrLanguageTag, 'de-DE');
      expect(find.byKey(const Key('badge_ocr_language')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('badge_ocr_language')),
          matching: find.textContaining('de-DE'),
        ),
        findsOneWidget,
      );

      settingsProvider.setPokemonLanguage('ja');
      await tester.pumpAndSettle();

      expect(activeSource.ocrLanguageTag, 'ja-JP');
      expect(
        find.descendant(
          of: find.byKey(const Key('badge_ocr_language')),
          matching: find.textContaining('ja-JP'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Native HUD bridge receives anchorRect from selected screenRegion or window bounds', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final shownStates = <NativeHudState>[];
      bool hidHud = false;

      final fakeBridge = FakeWindowsDesktopBridge(
        onShowHud: (s) async {
          shownStates.add(s);
          return true;
        },
        onHideHud: () async {
          hidHud = true;
        },
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              nativeBridge: fakeBridge,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 100,
                  hwnd: 555,
                  title: 'melonDS 1.1',
                  processName: 'melonDS.exe',
                  emulatorType: EmulatorType.melonds,
                  bounds: Rect.fromLTWH(200, 120, 1024, 768),
                  width: 1024,
                  height: 768,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_open_floating_hud')));
      await tester.pumpAndSettle();

      expect(shownStates, isNotEmpty);
      expect(shownStates.last.anchorRect, const Rect.fromLTWH(200, 120, 1024, 768));

      await tester.tap(find.byKey(const Key('btn_open_floating_hud')));
      await tester.pumpAndSettle();
      expect(hidHud, isTrue);
    });

    testWidgets('Does not auto-scan full desktop monitor on open when no emulator or custom region is active', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureDriver = MockCaptureDriver();
      final activeSource = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: MockOcrDriver(),
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: [DesktopWindowInfo.primaryScreen()],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('Pausiert'), findsOneWidget);
      expect(captureDriver.captureCount, 0);
    });

    testWidgets('Selecting desktop scan region auto-starts continuous OCR, updates live preview text, and sets native border', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureDriver = MockCaptureDriver();
      final ocrDriver = MockOcrDriver()..textToReturn = 'Route 2 · Hohes Gras';
      final activeSource = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
      );
      addTearDown(() async => await activeSource.dispose());

      final fakeBridge = FakeWindowsDesktopBridge();

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              nativeBridge: fakeBridge,
              detectedWindows: [DesktopWindowInfo.primaryScreen()],
              desktopSnippingLauncher: () async => ScreenRegionCaptureResult(
                region: ScreenRegion(
                  x: 120,
                  y: 420,
                  width: 500,
                  height: 140,
                  isAbsoluteScreen: true,
                  label: 'Live-OCR',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially paused on Desktop-only fallback
      expect(find.text('Pausiert'), findsOneWidget);

      final startSnippingBtn = find.byKey(const Key('btn_start_snipping'));
      await tester.ensureVisible(startSnippingBtn);
      await tester.tap(startSnippingBtn);
      await tester.pumpAndSettle();

      // Now live continuous OCR must be active + live recognized text shown + native border notified
      expect(find.text('OCR Aktiv'), findsOneWidget);
      expect(captureDriver.captureCount, greaterThanOrEqualTo(1));
      expect(
        find.descendant(
          of: find.byKey(const Key('desktop_snippet_preview_card')),
          matching: find.textContaining('Route 2 · Hohes Gras'),
        ),
        findsOneWidget,
      );
      expect(fakeBridge.borderCalls.any((b) => b.region != null && b.active), isTrue);
    });

    testWidgets('Target Dex avatar strips punctuation so Alola (US/UM Akala) renders AU instead of A(', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final alolaDex = UserDex(
        id: 'dex_alola_akala',
        title: 'Alola (US/UM Akala)',
        region: 'alola',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: const [],
      );
      when(() => mockDexProvider.userDexes).thenReturn([alolaDex]);

      await tester.pumpWidget(createWidgetUnderTest(initialDexId: 'dex_alola_akala'));
      await tester.pumpAndSettle();

      expect(find.text('A('), findsNothing);
      expect(find.text('AU'), findsOneWidget);
    });

    testWidgets('Window mode displays active scan preview card with window info and triggers live frame capture', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureDriver = MockCaptureDriver();
      final ocrDriver = MockOcrDriver()..textToReturn = 'Route 201';
      final activeSource = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 101,
                  hwnd: 777,
                  title: 'melonDS 1.1',
                  processName: 'melonDS.exe',
                  emulatorType: EmulatorType.melonds,
                  width: 960,
                  height: 1040,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('active_scan_preview_card')), findsOneWidget);
      expect(captureDriver.captureCount, greaterThanOrEqualTo(1));
      expect(find.textContaining('Route 201'), findsWidgets);
    });

    testWidgets('Custom desktop region shows clear source banner and allows switching back to window mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBridge = FakeWindowsDesktopBridge();
      final activeSource = DesktopWindowSource(
        captureDriver: MockCaptureDriver(),
        ocrDriver: MockOcrDriver(),
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              nativeBridge: fakeBridge,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 101,
                  hwnd: 777,
                  title: 'melonDS 1.1',
                  processName: 'melonDS.exe',
                  emulatorType: EmulatorType.melonds,
                  width: 960,
                  height: 1040,
                ),
              ],
              desktopSnippingLauncher: () async => ScreenRegionCaptureResult(
                region: ScreenRegion(
                  x: 200,
                  y: 300,
                  width: 500,
                  height: 180,
                  isAbsoluteScreen: true,
                  label: 'Desktop-Snipping',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_region_source_banner')), findsNothing);

      await tester.tap(find.byKey(const Key('btn_start_snipping')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_region_source_banner')), findsOneWidget);
      expect(find.byKey(const Key('btn_exit_custom_region')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_exit_custom_region')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_region_source_banner')), findsNothing);
      expect(find.byKey(const Key('active_scan_preview_card')), findsOneWidget);
      expect(fakeBridge.borderCalls.last.region, isNull);
    });

    testWidgets('Temporary OCR diagnostic logs panel is removed from DesktopTrackerScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureDriver = MockCaptureDriver();
      final ocrDriver = MockOcrDriver()..textToReturn = 'Ein wildes Pikachu erscheint!';
      final activeSource = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 101,
                  hwnd: 777,
                  title: 'melonDS 1.1',
                  processName: 'melonDS.exe',
                  emulatorType: EmulatorType.melonds,
                  width: 960,
                  height: 1040,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ocr_debug_logs_panel')), findsNothing);
      expect(find.byKey(const Key('btn_copy_ocr_logs')), findsNothing);
      expect(find.byKey(const Key('btn_clear_ocr_logs')), findsNothing);
    });

    testWidgets('Variable OCR refresh rate chips update activeSource.pollInterval and coordinator settings', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureDriver = MockCaptureDriver();
      final ocrDriver = MockOcrDriver()..textToReturn = '';
      final activeSource = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 101,
                  hwnd: 777,
                  title: 'melonDS 1.1',
                  processName: 'melonDS.exe',
                  emulatorType: EmulatorType.melonds,
                  width: 960,
                  height: 1040,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default 400ms
      expect(activeSource.pollInterval, const Duration(milliseconds: 400));
      expect(coordinator.settings.scanIntervalMs, 400);

      await tester.ensureVisible(find.byKey(const Key('refresh_rate_250')));
      await tester.tap(find.byKey(const Key('refresh_rate_250')));
      await tester.pumpAndSettle();

      expect(activeSource.pollInterval, const Duration(milliseconds: 250));
      expect(coordinator.settings.scanIntervalMs, 250);

      await tester.ensureVisible(find.byKey(const Key('refresh_rate_1200')));
      await tester.tap(find.byKey(const Key('refresh_rate_1200')));
      await tester.pumpAndSettle();

      expect(activeSource.pollInterval, const Duration(milliseconds: 1200));
      expect(coordinator.settings.scanIntervalMs, 1200);
    });

    testWidgets('Custom OCR patterns button opens dialog and adds new custom pattern to coordinator', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('btn_custom_patterns')));
      await tester.tap(find.byKey(const Key('btn_custom_patterns')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_patterns_dialog')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('custom_pattern_input')),
        'Klasse! {pokemon}',
      );
      await tester.tap(find.byKey(const Key('btn_add_custom_pattern')));
      await tester.pumpAndSettle();

      expect(coordinator.settings.customPatterns, hasLength(1));
      expect(coordinator.settings.customPatterns.first.template, 'Klasse! {pokemon}');
      expect(coordinator.settings.customPatterns.first.eventType, ScannerEventType.caught);
    });

    testWidgets('Selecting a Monitor shows safe Monitor preview card without auto-scanning OCR', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureDriver = MockCaptureDriver();
      final ocrDriver = MockOcrDriver()..textToReturn = 'Should not run OCR';
      final activeSource = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
      );
      addTearDown(() async => await activeSource.dispose());

      final monitor1 = DesktopWindowInfo.primaryScreen();
      const melon = DesktopWindowInfo(
        id: 101,
        hwnd: 777,
        title: 'melonDS 1.1',
        processName: 'melonDS.exe',
        emulatorType: EmulatorType.melonds,
        width: 960,
        height: 1040,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: [melon, monitor1],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch dropdown from melonDS to Monitor 1
      await tester.tap(find.byKey(const Key('emulator_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Bildschirm 1').last);
      await tester.pumpAndSettle();

      final ocrAfterSwitch = ocrDriver.ocrCount;
      final capturesAfterSwitch = captureDriver.captureCount;

      expect(find.text('Pausiert'), findsOneWidget);
      expect(find.byKey(const Key('active_scan_preview_card')), findsOneWidget);
      expect(find.byKey(const Key('btn_refresh_monitor_preview')), findsOneWidget);

      // Even after waiting longer than scanIntervalMs, OCR must remain idle on Monitor
      await tester.pump(const Duration(milliseconds: 900));
      expect(ocrDriver.ocrCount, ocrAfterSwitch);

      // Tapping Monitor preview refresh captures visual frame without running OCR
      await tester.tap(find.byKey(const Key('btn_refresh_monitor_preview')));
      await tester.pumpAndSettle();
      expect(captureDriver.captureCount, greaterThan(capturesAfterSwitch));
      expect(ocrDriver.ocrCount, ocrAfterSwitch);
    });

    testWidgets('Preprocess profile pills update coordinator settings and active source driver', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(coordinator.settings.preprocessProfile, OcrPreprocessProfile.standard);

      await tester.ensureVisible(find.byKey(const Key('profile_pixelArtDs')));
      await tester.tap(find.byKey(const Key('profile_pixelArtDs')));
      await tester.pumpAndSettle();

      expect(coordinator.settings.preprocessProfile, OcrPreprocessProfile.pixelArtDs);

      await tester.ensureVisible(find.byKey(const Key('profile_cameraDisplay')));
      await tester.tap(find.byKey(const Key('profile_cameraDisplay')));
      await tester.pumpAndSettle();

      expect(coordinator.settings.preprocessProfile, OcrPreprocessProfile.cameraDisplay);
    });

    testWidgets('Pattern Studio dedupes quick templates and evaluates text + photo sandbox', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final smartCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
          PokemonMatcherEntry(id: 560, name: 'Irokex', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await smartCoord.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: smartCoord,
              detectedWindows: const [],
              sandboxImagePicker: () async => const CapturedFrame(
                width: 100,
                height: 40,
                bytes: [1, 2, 3, 4],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('btn_custom_patterns')));
      await tester.tap(find.byKey(const Key('btn_custom_patterns')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_patterns_dialog')), findsOneWidget);

      // Select encounter pill + add quick template without duplicates
      await tester.tap(find.byKey(const Key('type_pill_encounter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_pat_wild')));
      await tester.pumpAndSettle();
      expect(smartCoord.settings.customPatterns, hasLength(1));

      // Tapping same quick preset again must NOT add duplicate
      await tester.tap(find.byKey(const Key('quick_pat_wild')));
      await tester.pumpAndSettle();
      expect(smartCoord.settings.customPatterns, hasLength(1));

      // Live Text Sandbox evaluates Black log against Smart-Search
      await tester.enterText(
        find.byKey(const Key('sandbox_text_input')),
        'Klasse!\nZr-rrokex wrde aefar«t!',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('sandbox_result_card')),
          matching: find.textContaining('Zurrokex'),
        ),
        findsOneWidget,
      );

      // Switch to Photo Sandbox tab & load photo frame
      await tester.tap(find.byKey(const Key('sandbox_tab_photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_sandbox_load_photo')));
      await tester.pumpAndSettle();
      expect(find.textContaining('100×40'), findsOneWidget);
    });

    testWidgets('Safe Event Correction preserves pre-existing & duplicate Dex entries and cleans up single-owner additions', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mutableDex = UserDex(
        id: 'dex_black',
        title: 'Einall Living Dex',
        region: 'unova',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: <String>['559'], // Zurrokex ALREADY in Dex before session!
        shinyIds: <String>['559'],
        alphaIds: <String>[],
      );
      when(() => mockDexProvider.userDexes).thenReturn([mutableDex]);
      when(() => mockDexProvider.allPokemon).thenReturn([
        Pokemon(
          id: 559,
          nameDe: 'Zurrokex',
          nameEn: 'Scraggy',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 180,
          evolutionChainId: 1,
          eggGroups: const [],
          weight: 11.8,
          speed: 48,
          forms: const [],
        ),
        Pokemon(
          id: 560,
          nameDe: 'Irokex',
          nameEn: 'Scrafty',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 90,
          evolutionChainId: 1,
          eggGroups: const [],
          weight: 30.0,
          speed: 58,
          forms: const [],
        ),
        Pokemon(
          id: 554,
          nameDe: 'Flampion',
          nameEn: 'Darumaka',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 120,
          evolutionChainId: 2,
          eggGroups: const [],
          weight: 37.5,
          speed: 50,
          forms: const [],
        ),
      ]);

      final smartCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
          PokemonMatcherEntry(id: 560, name: 'Irokex', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await smartCoord.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: smartCoord,
              initialDexId: 'dex_black',
              detectedWindows: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Case A: Pre-existing 559 event arrives, then user corrects it to 560 -> 559 MUST remain!
      await smartCoord.processText('Zurrokex wurde gefangen!');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_edit_event_0')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('correction_search_field')), 'Irokex');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_pick_pokemon_560')));
      await tester.pumpAndSettle();

      expect(mutableDex.caughtIds, contains('560'));
      expect(mutableDex.caughtIds, contains('559'));
      expect(mutableDex.shinyIds, contains('559'));

      // Case B: Brand-new 554 (Flampion) event arrives (auto-added 554), then corrected to 560 -> 554 IS cleaned up!
      await smartCoord.processText('✨ Flampion wurde gefangen!');
      await tester.pumpAndSettle();
      expect(mutableDex.caughtIds, contains('554'));
      expect(mutableDex.shinyIds, contains('554'));

      await tester.tap(find.byKey(const Key('btn_edit_event_0')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('correction_search_field')), 'Irokex');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_pick_pokemon_560')));
      await tester.pumpAndSettle();

      expect(mutableDex.caughtIds, isNot(contains('554')));
      expect(mutableDex.shinyIds, isNot(contains('554')));
      expect(mutableDex.caughtIds, contains('560'));
      expect(mutableDex.shinyIds, contains('560'));
    });

    testWidgets('Dual-Zone Live-Fokus preset pills & free snipping update activeSource Zone B without adding catches', (tester) async {
      tester.view.physicalSize = const Size(1400, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureDriver = MockCaptureDriver();
      final ocrDriver = MockOcrDriver()..textToReturn = '';
      final activeSource = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
      );
      addTearDown(() async => await activeSource.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              windowSource: activeSource,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 101,
                  hwnd: 777,
                  title: 'melonDS 1.1',
                  processName: 'melonDS.exe',
                  emulatorType: EmulatorType.melonds,
                  width: 960,
                  height: 1040,
                ),
              ],
              desktopSnippingLauncher: () async => ScreenRegionCaptureResult(
                region: ScreenRegion(
                  x: 1120,
                  y: 90,
                  width: 340,
                  height: 95,
                  isAbsoluteScreen: true,
                  label: 'Gegner-HUD',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('focus_preset_disabled')), findsOneWidget);
      expect(find.byKey(const Key('focus_preset_topLeft')), findsOneWidget);
      expect(find.byKey(const Key('focus_preset_topRight')), findsOneWidget);
      expect(find.byKey(const Key('focus_preset_topBanner')), findsOneWidget);
      expect(find.byKey(const Key('btn_live_focus_snipping')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('focus_preset_topRight')));
      await tester.tap(find.byKey(const Key('focus_preset_topRight')));
      await tester.pumpAndSettle();

      expect(activeSource.liveFocusPreset, LiveFocusPreset.topRight);
      expect(coordinator.settings.liveFocusPreset, LiveFocusPreset.topRight);

      await tester.ensureVisible(find.byKey(const Key('btn_live_focus_snipping')));
      await tester.tap(find.byKey(const Key('btn_live_focus_snipping')));
      await tester.pumpAndSettle();

      expect(activeSource.liveFocusPreset, LiveFocusPreset.customRegion);
      expect(activeSource.liveFocusScreenRegion, isNotNull);
      expect(activeSource.liveFocusScreenRegion!.x, 1120);
    });

    testWidgets('Multi-Encounter focus cards render side-by-side and Starter-Schutz blocks & unblocks ignored Pokemon', (tester) async {
      tester.view.physicalSize = const Size(1400, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mutableDex = UserDex(
        id: 'dex_black',
        title: 'Pokémon Schwarz',
        region: 'unova',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: <String>[],
        shinyIds: <String>[],
        alphaIds: <String>[],
      );
      when(() => mockDexProvider.userDexes).thenReturn([mutableDex]);
      when(() => mockDexProvider.allPokemon).thenReturn([
        Pokemon(
          id: 497,
          nameDe: 'Serpiroyal',
          nameEn: 'Serperior',
          hasGenderDifferences: false,
          genderRate: 1,
          captureRate: 45,
          evolutionChainId: 1,
          eggGroups: const [],
          weight: 63.0,
          speed: 113,
          forms: const [],
        ),
        Pokemon(
          id: 551,
          nameDe: 'Ganovil',
          nameEn: 'Sandile',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 180,
          evolutionChainId: 2,
          eggGroups: const [],
          weight: 15.2,
          speed: 65,
          forms: const [],
        ),
        Pokemon(
          id: 559,
          nameDe: 'Zurrokex',
          nameEn: 'Scraggy',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 180,
          evolutionChainId: 3,
          eggGroups: const [],
          weight: 11.8,
          speed: 48,
          forms: const [],
        ),
      ]);

      final multiCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 497, name: 'Serpiroyal', language: 'de'),
          PokemonMatcherEntry(id: 551, name: 'Ganovil', language: 'de'),
          PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await multiCoord.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: multiCoord,
              initialDexId: 'dex_black',
              detectedWindows: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Multi-Encounter from Zone B -> renders both enemies in Aktueller Live-Fokus
      await multiCoord.processFrameText(
        'Zurrokex Lv.16   Ganovil Lv.17',
        encounterOnly: true,
        allowMultiEncounter: true,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('focus_enemy_card_559')), findsOneWidget);
      expect(find.byKey(const Key('focus_enemy_card_551')), findsOneWidget);
      expect(mutableDex.caughtIds, isEmpty);

      // Starter/Team-Schutz via Event Correction dialog
      await multiCoord.processText('Serpiroyal wurde gefangen!');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_edit_event_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_ignore_team_pokemon_497')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_ignore_team_pokemon_497')));
      await tester.pumpAndSettle();

      expect(multiCoord.settings.ignoredPokemonIds, contains(497));
      expect(find.byKey(const Key('ignored_pokemon_chip_497')), findsOneWidget);
    });

    testWidgets('Unified Zone A/B cards, border visibility switch, multi-instance controls, and Top-10% sprite correction dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockDexProvider = MockDexProvider();
      final testDex = UserDex(
        id: 'dex_black',
        title: 'Nationaldex',
        region: 'national',
        isShinyDex: false,
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: const [],
      );
      when(() => mockDexProvider.userDexes).thenReturn([testDex]);
      when(() => mockDexProvider.allPokemon).thenReturn([
        Pokemon(id: 554, nameDe: 'Flampion', nameEn: 'Darumaka', hasGenderDifferences: false, genderRate: 4, captureRate: 120, evolutionChainId: 282, eggGroups: const [], weight: 37.5, speed: 50, forms: const []),
        Pokemon(id: 555, nameDe: 'Flampivian', nameEn: 'Darmanitan', hasGenderDifferences: false, genderRate: 4, captureRate: 60, evolutionChainId: 282, eggGroups: const [], weight: 92.9, speed: 95, forms: const []),
        Pokemon(id: 136, nameDe: 'Flamara', nameEn: 'Flareon', hasGenderDifferences: false, genderRate: 1, captureRate: 45, evolutionChainId: 67, eggGroups: const [], weight: 25.0, speed: 65, forms: const []),
        Pokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu', hasGenderDifferences: true, genderRate: 4, captureRate: 190, evolutionChainId: 10, eggGroups: const [], weight: 6.0, speed: 90, forms: const []),
      ]);

      final coord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 555, name: 'Flampivian', language: 'de'),
          PokemonMatcherEntry(id: 136, name: 'Flamara', language: 'de'),
          PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
        ]),
        settings: ScannerSettings.defaults().copyWith(
          liveFocusPreset: LiveFocusPreset.topBanner,
          showScreenBorders: true,
        ),
      );
      addTearDown(() async => await coord.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coord,
              initialDexId: 'dex_black',
              detectedWindows: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Identical Zone A & Zone B cards present
      expect(find.byKey(const Key('scan_zone_a_card')), findsOneWidget);
      expect(find.byKey(const Key('scan_zone_b_card')), findsOneWidget);

      // Border visibility switch toggles showScreenBorders
      final borderSwitch = find.byKey(const Key('switch_screen_borders'));
      expect(borderSwitch, findsOneWidget);
      await tester.ensureVisible(borderSwitch);
      await tester.tap(borderSwitch);
      await tester.pumpAndSettle();
      expect(coord.settings.showScreenBorders, isFalse);

      // Multi-Instance section & 2x2 quick split button
      expect(find.byKey(const Key('multi_instance_card')), findsOneWidget);

      // Process encounter -> open redesigned Event Correction Dialog with descending % + sprites + demoted ignore button
      await coord.processText('Ein wildes Fdlanp,io.n erscheint!');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_edit_event_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('correction_top_candidates_header')), findsOneWidget);
      expect(find.byKey(const Key('correction_pct_badge_554')), findsOneWidget);
      expect(find.byKey(const Key('btn_ignore_team_pokemon_554')), findsOneWidget);

      // Extra Pokémon outside Top-10 (#25 Pikachu) must NOT appear when search is empty, ONLY when searched!
      expect(find.byKey(const Key('edit_pick_pokemon_25')), findsNothing);
      await tester.enterText(find.byKey(const Key('correction_search_field')), 'Pikachu');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit_pick_pokemon_25')), findsOneWidget);
    });

    testWidgets('Coupled X-Instance cards support drawing Scan/Fokus independently, binding windows, and multi-border overlays', (tester) async {
      tester.view.physicalSize = const Size(1400, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBridge = FakeWindowsDesktopBridge();
      final mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn(const []);
      when(() => mockDexProvider.allPokemon).thenReturn(const []);

      final coord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await coord.dispose());

      int snipCount = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coord,
              nativeBridge: fakeBridge,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 101,
                  hwnd: 1001,
                  title: 'melonDS #1',
                  processName: 'melonDS.exe',
                  width: 960,
                  height: 1040,
                  bounds: Rect.fromLTWH(0, 0, 960, 1040),
                ),
                DesktopWindowInfo(
                  id: 202,
                  hwnd: 2002,
                  title: 'melonDS #2',
                  processName: 'melonDS.exe',
                  width: 960,
                  height: 1040,
                  bounds: Rect.fromLTWH(960, 0, 960, 1040),
                ),
              ],
              desktopSnippingLauncher: () async {
                snipCount++;
                return ScreenRegionCaptureResult(
                  region: ScreenRegion(
                    x: 100.0 * snipCount,
                    y: 200,
                    width: 300,
                    height: 90,
                    isAbsoluteScreen: true,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Legacy strip splitter buttons replaced by coupled "+ Instanz hinzufügen"
      expect(find.byKey(const Key('btn_multi_grid_1x2')), findsNothing);
      final addInstBtn = find.byKey(const Key('btn_multi_add_instance'));
      expect(addInstBtn, findsOneWidget);

      // Add Instanz #2 and Instanz #3
      await tester.ensureVisible(addInstBtn);
      await tester.tap(addInstBtn);
      await tester.pumpAndSettle();
      await tester.tap(addInstBtn);
      await tester.pumpAndSettle();

      expect(coord.settings.multiInstanceSlots, hasLength(2));
      expect(coord.settings.multiInstanceSlots[0].id, 2);
      expect(coord.settings.multiInstanceSlots[1].id, 3);
      expect(find.byKey(const Key('multi_instance_card_2')), findsOneWidget);
      expect(find.byKey(const Key('multi_instance_card_3')), findsOneWidget);

      // Draw Scan #2 and Fokus #2 independently -> coupled slot #2 gets both regions!
      final drawScan2 = find.byKey(const Key('btn_multi_draw_scan_2'));
      await tester.ensureVisible(drawScan2);
      await tester.tap(drawScan2);
      await tester.pumpAndSettle();

      final drawFocus2 = find.byKey(const Key('btn_multi_draw_focus_2'));
      await tester.ensureVisible(drawFocus2);
      await tester.tap(drawFocus2);
      await tester.pumpAndSettle();

      final slot2 = coord.settings.multiInstanceSlots.firstWhere((s) => s.id == 2);
      expect(slot2.scanRegion, isNotNull);
      expect(slot2.focusRegion, isNotNull);
      expect(slot2.hasScan, isTrue);
      expect(slot2.hasFocus, isTrue);

      // Toggle Scan #2 off -> Instanz #2 works as Fokus-only!
      final scanSwitch2 = find.byKey(const Key('switch_multi_scan_2'));
      await tester.ensureVisible(scanSwitch2);
      await tester.tap(scanSwitch2);
      await tester.pumpAndSettle();
      final updatedSlot2 = coord.settings.multiInstanceSlots.firstWhere((s) => s.id == 2);
      expect(updatedSlot2.scanEnabled, isFalse);
      expect(updatedSlot2.hasScan, isFalse);
      expect(updatedSlot2.hasFocus, isTrue);

      // Bind Instanz #3 to open program "melonDS #2" via dropdown
      final winDrop3 = find.byKey(const Key('dropdown_multi_window_3'));
      await tester.ensureVisible(winDrop3);
      await tester.tap(winDrop3);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('melonDS #2').last);
      await tester.pumpAndSettle();

      final slot3 = coord.settings.multiInstanceSlots.firstWhere((s) => s.id == 3);
      expect(slot3.windowHwnd, 2002);
      expect(slot3.windowTitle, 'melonDS #2');
      expect(slot3.hasScan, isTrue);
    });

    testWidgets('Clean headers (MULTI-INSTANZEN, SCAN-PROFIL), interactive (i) info boxes, and uncluttered Custom Scan Region UI', (tester) async {
      tester.view.physicalSize = const Size(1400, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn(const []);
      when(() => mockDexProvider.allPokemon).thenReturn(const []);

      final coord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const []),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await coord.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coord,
              detectedWindows: const [
                DesktopWindowInfo(
                  id: 101,
                  hwnd: 777,
                  title: 'melonDS 1.1',
                  processName: 'melonDS.exe',
                  emulatorType: EmulatorType.melonds,
                  width: 960,
                  height: 1040,
                ),
              ],
              desktopSnippingLauncher: () async => ScreenRegionCaptureResult(
                region: ScreenRegion(
                  x: 1574,
                  y: 249,
                  width: 271,
                  height: 315,
                  isAbsoluteScreen: true,
                  label: 'Desktop-Snipping',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Cleaned headings without parenthetical clutter
      expect(find.text('MULTI-INSTANZEN'), findsOneWidget);
      expect(find.text('MULTI-INSTANZEN (SHINY HUNTING)'), findsNothing);
      expect(find.text('SCAN-PROFIL'), findsOneWidget);
      expect(find.text('SCAN-PROFIL (BILD-OPTIMIERUNG)'), findsNothing);

      // 2. Interactive (i) info buttons toggle clear explanations for Zone A, Zone B, and Scan-Profil
      expect(find.byKey(const Key('info_box_zone_a')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('btn_info_zone_a')));
      await tester.tap(find.byKey(const Key('btn_info_zone_a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('info_box_zone_a')), findsOneWidget);

      expect(find.byKey(const Key('info_box_zone_b')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('btn_info_zone_b')));
      await tester.tap(find.byKey(const Key('btn_info_zone_b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('info_box_zone_b')), findsOneWidget);

      expect(find.byKey(const Key('info_box_scan_profile')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('btn_info_scan_profile')));
      await tester.tap(find.byKey(const Key('btn_info_scan_profile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('info_box_scan_profile')), findsOneWidget);

      // 3. Switching to custom scan region hides dimmed window dropdown & window preset grid cleanly
      await tester.ensureVisible(find.byKey(const Key('btn_start_snipping')));
      await tester.tap(find.byKey(const Key('btn_start_snipping')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_region_source_banner')), findsOneWidget);
      expect(find.text('Eigener Desktop-Bereich'), findsOneWidget);
      expect(find.byKey(const Key('emulator_dropdown')), findsNothing);
      expect(find.byKey(const Key('btn_scan_mode_full')), findsNothing);
      expect(find.byKey(const Key('btn_scan_mode_dialogue')), findsNothing);

      final modeText = tester.widget<Text>(find.byKey(const Key('label_active_scan_mode'))).data!;
      expect(modeText, '271×315 px');
      expect(find.text('Scan-Bereich neu zeichnen'), findsOneWidget);

      // Exiting custom region restores dropdown and preset buttons cleanly
      await tester.ensureVisible(find.byKey(const Key('btn_exit_custom_region')));
      await tester.tap(find.byKey(const Key('btn_exit_custom_region')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_region_source_banner')), findsNothing);
      expect(find.byKey(const Key('emulator_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('btn_scan_mode_full')), findsOneWidget);
    });
  });
}
