import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/persistent_tracker_dock.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_tracker_service.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/desktop_tracker/windows_desktop_bridge.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';

class _MockDexProvider extends Mock implements DexProvider {}

class _FakeDesktopBridge implements DesktopPlatformBridge {
  final List<List<OverlayBorderSpec>> overlayBorderCalls = [];
  int showHudCount = 0;
  int hideHudCount = 0;

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
    hideHudCount++;
  }

  @override
  Future<OcrRecognitionResult> recognizeText(
    CapturedFrame frame, {
    String? languageTag,
    String? preprocessProfile,
  }) async =>
      const OcrRecognitionResult();

  @override
  Future<void> setOverlayBorders(List<OverlayBorderSpec> borders) async {
    overlayBorderCalls.add(borders);
  }

  @override
  Future<void> setScanRegionBorder(
    ScreenRegion? region, {
    bool active = true,
  }) async {}

  @override
  Future<NativeCaptureAnalyzeResult?> captureAndAnalyze(
    NativeCaptureAnalyzeRequest request,
  ) async =>
      null;

  @override
  Future<void> clearNativeScanCache() async {}

  @override
  Future<bool> showFloatingHud(NativeHudState state) async {
    showHudCount++;
    return true;
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
  group('PersistentTrackerDock Widget Tests (TDD)', () {
    late UserDex mockDex;

    setUp(() {
      mockDex = UserDex(
        id: 'dex_nat',
        title: 'Nationaldex',
        region: 'national',
        isShinyDex: false,
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: ['1', '2'],
      );
    });

    testWidgets('Renders persistent dock with live encounter info and dex status', (tester) async {
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Glumanda',
        pokemonId: 4,
        isShiny: true,
        rawText: 'Ein wildes schillerndes Glumanda erscheint!',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PersistentTrackerDock(
              latestEvent: event,
              activeDex: mockDex,
              isScanningActive: true,
              onOpenHud: () {},
              onOpenSetup: () {},
              onTogglePause: () {},
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.textContaining('Glumanda'), findsOneWidget);
      expect(find.textContaining('Fehlt im Ziel-Dex'), findsOneWidget);
      expect(find.byKey(const Key('btn_dock_open_hud')), findsOneWidget);
      expect(find.byKey(const Key('btn_dock_open_setup')), findsOneWidget);
    });

    testWidgets('Triggers action callbacks on button taps', (tester) async {
      bool hudOpened = false;
      bool setupOpened = false;
      bool pauseToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PersistentTrackerDock(
              latestEvent: null,
              activeDex: mockDex,
              isScanningActive: true,
              onOpenHud: () => hudOpened = true,
              onOpenSetup: () => setupOpened = true,
              onTogglePause: () => pauseToggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_dock_open_hud')));
      await tester.pump();
      expect(hudOpened, isTrue);

      await tester.tap(find.byKey(const Key('btn_dock_open_setup')));
      await tester.pump();
      expect(setupOpened, isTrue);

      await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
      await tester.pump();
      expect(pauseToggled, isTrue);
    });

    testWidgets('shows HUD active state, LIVE/PAUSIERT badge, and quick + Eintragen action', (tester) async {
      bool markCaughtTapped = false;
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Pikachu',
        pokemonId: 25,
        rawText: 'Wildes Pikachu',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PersistentTrackerDock(
              latestEvent: event,
              activeDex: mockDex,
              isScanningActive: true,
              isHudVisible: true,
              activeSourceTitle: 'melonDS',
              onOpenHud: () {},
              onOpenSetup: () {},
              onTogglePause: () {},
              onMarkCaught: () => markCaughtTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.textContaining('HUD aktiv'), findsOneWidget);
      expect(find.textContaining('melonDS'), findsOneWidget);

      final markBtn = find.byKey(const Key('btn_dock_mark_caught'));
      expect(markBtn, findsOneWidget);
      await tester.tap(markBtn);
      await tester.pump();
      expect(markCaughtTapped, isTrue);
    });

    testWidgets('PersistentTrackerDockHost pauses without closing, resumes, and closes cleanly on X', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      addTearDown(TrackerPlatformHelper.resetDebugOverrides);
      addTearDown(() async {
        await DesktopTrackerService.instance.stopTracking();
      });

      final mockDexProvider = _MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn([mockDex]);
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);

      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const []),
        settings: ScannerSettings.defaults(),
      );
      DesktopTrackerService.instance.startTracking(
        coordinator: coordinator,
        dexId: mockDex.id,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: Scaffold(
              body: const Center(child: Text('Home')),
              bottomNavigationBar: PersistentTrackerDockHost(
                onOpenSetup: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PersistentTrackerDock), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      // Pause button MUST pause without closing/terminating the dock!
      await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
      await tester.pump();

      expect(find.byType(PersistentTrackerDock), findsOneWidget);
      expect(find.text('PAUSIERT'), findsOneWidget);
      expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
      expect(DesktopTrackerService.instance.isPaused, isTrue);

      // Resume button restores LIVE state
      await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
      await tester.pump();

      expect(find.byType(PersistentTrackerDock), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(DesktopTrackerService.instance.isPaused, isFalse);

      // Close (X) button terminates tracking and removes the dock
      await tester.tap(find.byKey(const Key('btn_dock_close')));
      await tester.pump();

      expect(DesktopTrackerService.instance.isTrackingActive, isFalse);
      expect(find.byType(PersistentTrackerDock), findsNothing);
      await coordinator.dispose();
    });

    testWidgets('PersistentTrackerDockHost pause and close buttons work across compact/wide widths without terminating on pause', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      addTearDown(TrackerPlatformHelper.resetDebugOverrides);
      addTearDown(() async {
        await DesktopTrackerService.instance.stopTracking();
      });

      final mockDexProvider = _MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn([mockDex]);
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);

      for (final width in [360.0, 500.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final coordinator = ScannerCoordinator(
          engine: OcrDetectionEngine(),
          matcher: PokemonFuzzyMatcher.withEntries(const []),
          settings: ScannerSettings.defaults(),
        );
        DesktopTrackerService.instance.startTracking(
          coordinator: coordinator,
          dexId: mockDex.id,
        );

        await tester.pumpWidget(
          ChangeNotifierProvider<DexProvider>.value(
            value: mockDexProvider,
            child: MaterialApp(
              home: Scaffold(
                body: const Center(child: Text('Home')),
                bottomNavigationBar: PersistentTrackerDockHost(
                  onOpenSetup: () {},
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Tap Pause -> must stay active and show PAUSIERT
        await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.isPaused, isTrue);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);

        // Tap Resume -> must stay active and unpause
        await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.isPaused, isFalse);

        // Tap Close (X) -> must stop tracking and hide dock
        await tester.tap(find.byKey(const Key('btn_dock_close')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isFalse);
        expect(find.byType(PersistentTrackerDock), findsNothing);
        await coordinator.dispose();
      }
    });

    testWidgets(
      'Navigation round-trip: DesktopTrackerScreen -> Back -> Dock Pause/Resume/Reopen/Close stops cleanly on X',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        TrackerPlatformHelper.debugIsDesktopOverride = () => true;
        addTearDown(TrackerPlatformHelper.resetDebugOverrides);
        addTearDown(() async {
          await DesktopTrackerService.instance.stopTracking();
        });

        final mockDexProvider = _MockDexProvider();
        when(() => mockDexProvider.userDexes).thenReturn([mockDex]);
        when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);

        final fakeBridge = _FakeDesktopBridge();
        final coordinator = ScannerCoordinator(
          engine: OcrDetectionEngine(),
          matcher: PokemonFuzzyMatcher.withEntries(const []),
          settings: ScannerSettings.defaults(),
        );
        addTearDown(() async {
          await coordinator.dispose();
        });

        const emulatorWindow = DesktopWindowInfo(
          id: 42,
          hwnd: 42,
          title: 'mGBA - Pokemon Smaragd',
          processName: 'mGBA.exe',
          isDesktopScreen: false,
        );

        Future<void> openTracker(BuildContext context) async {
          final existing = DesktopTrackerService.instance;
          final reusableSource = existing.isTrackingActive &&
                  existing.windowSource != null &&
                  !existing.windowSource!.isDisposed
              ? existing.windowSource
              : null;
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DesktopTrackerScreen(
                coordinator: coordinator,
                initialDexId: mockDex.id,
                detectedWindows: const [emulatorWindow],
                windowSource: reusableSource,
                nativeBridge: fakeBridge,
                keepTrackingInBackground: true,
              ),
            ),
          );
        }

        await tester.pumpWidget(
          ChangeNotifierProvider<DexProvider>.value(
            value: mockDexProvider,
            child: MaterialApp(
              home: Builder(
                builder: (homeContext) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('btn_open_tracker_home'),
                      onPressed: () => openTracker(homeContext),
                      child: const Text('Open Tracker'),
                    ),
                  ),
                  bottomNavigationBar: PersistentTrackerDockHost(
                    onOpenSetup: () => openTracker(homeContext),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Navigate to DesktopTrackerScreen
        await tester.tap(find.byKey(const Key('btn_open_tracker_home')));
        await tester.pumpAndSettle();
        expect(find.byType(DesktopTrackerScreen), findsOneWidget);

        final ownedSource = DesktopTrackerService.instance.windowSource;
        expect(ownedSource, isNotNull);

        // 2. Pop back to Home -> PersistentTrackerDock must remain visible
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(DesktopTrackerScreen), findsNothing);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.isPaused, isFalse);

        // 3. Tap Pause on Dock -> MUST pause without closing
        await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.isPaused, isTrue);
        expect(find.text('PAUSIERT'), findsOneWidget);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);

        // 4. Tap Resume on Dock -> LIVE again
        await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.isPaused, isFalse);
        expect(find.text('LIVE'), findsOneWidget);

        // 5. Re-open Setup from Dock, then pop back
        await tester.tap(find.byKey(const Key('btn_dock_open_setup')));
        await tester.pumpAndSettle();
        expect(find.byType(DesktopTrackerScreen), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(PersistentTrackerDock), findsOneWidget);
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);

        // 6. Tap Close (X) on Dock -> MUST stop tracking, dispose source, clear borders & hide HUD
        final hideBeforeClose = fakeBridge.hideHudCount;
        await tester.tap(find.byKey(const Key('btn_dock_close')));
        await tester.pumpAndSettle();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();

        expect(DesktopTrackerService.instance.isTrackingActive, isFalse);
        expect(find.byType(PersistentTrackerDock), findsNothing);
        expect(ownedSource!.isDisposed, isTrue);
        expect(fakeBridge.hideHudCount, greaterThan(hideBeforeClose));
        expect(fakeBridge.overlayBorderCalls.last, isEmpty);
      },
    );

    testWidgets('PersistentTrackerDock renders multi-encounter focus chips and per-enemy quick catch across narrow/wide widths', (tester) async {
      final markedIds = <int>[];
      final sleima = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Sleima',
        pokemonId: 88,
        rawText: 'Sleima\nZubat',
        timestamp: DateTime.now(),
      );
      final zubat = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Zubat',
        pokemonId: 41,
        encounterCount: 2,
        rawText: 'Sleima\nZubat',
        timestamp: DateTime.now(),
      );

      for (final width in [320.0, 540.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: PersistentTrackerDock(
                latestEvent: zubat,
                focusEvents: [sleima, zubat],
                activeDex: mockDex,
                isScanningActive: true,
                onOpenHud: () {},
                onOpenSetup: () {},
                onTogglePause: () {},
                onMarkEventCaught: (ev) {
                  if (ev.pokemonId != null) markedIds.add(ev.pokemonId!);
                },
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining('Sleima'), findsOneWidget);
        expect(find.textContaining('Zubat'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await tester.tap(find.byKey(const Key('btn_dock_mark_caught_41')));
      await tester.pump();
      expect(markedIds, [41]);
    });

    testWidgets(
      'Windows default desktop screen without emulator keeps dock alive on pop and supports Pause, HUD, and Close (X)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        TrackerPlatformHelper.debugIsDesktopOverride = () => true;
        addTearDown(TrackerPlatformHelper.resetDebugOverrides);
        addTearDown(() async {
          await DesktopTrackerService.instance.stopTracking();
        });

        final mockDexProvider = _MockDexProvider();
        when(() => mockDexProvider.userDexes).thenReturn([mockDex]);
        when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);

        final fakeBridge = _FakeDesktopBridge();
        final coordinator = ScannerCoordinator(
          engine: OcrDetectionEngine(),
          matcher: PokemonFuzzyMatcher.withEntries(const []),
          settings: ScannerSettings.defaults(),
        );
        addTearDown(() async {
          await coordinator.dispose();
        });

        final desktopMonitor = DesktopWindowInfo.primaryScreen();

        await tester.pumpWidget(
          ChangeNotifierProvider<DexProvider>.value(
            value: mockDexProvider,
            child: MaterialApp(
              home: Builder(
                builder: (homeContext) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('btn_open_desktop_only'),
                      onPressed: () {
                        Navigator.of(homeContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DesktopTrackerScreen(
                              coordinator: coordinator,
                              initialDexId: mockDex.id,
                              detectedWindows: [desktopMonitor],
                              nativeBridge: fakeBridge,
                              keepTrackingInBackground: true,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Tracker'),
                    ),
                  ),
                  bottomNavigationBar: PersistentTrackerDockHost(
                    onOpenSetup: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_open_desktop_only')));
        await tester.pumpAndSettle();
        expect(find.byType(DesktopTrackerScreen), findsOneWidget);

        // Immediately pop back without toggling scan or snipping
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(DesktopTrackerScreen), findsNothing);
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);

        // Pause / Resume must toggle PAUSIERT <-> LIVE without closing dock
        final wasInitiallyPaused = DesktopTrackerService.instance.isPaused;
        await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.isPaused, !wasInitiallyPaused);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);
        expect(
          find.text(wasInitiallyPaused ? 'LIVE' : 'PAUSIERT'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.isPaused, wasInitiallyPaused);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);
        expect(
          find.text(wasInitiallyPaused ? 'PAUSIERT' : 'LIVE'),
          findsOneWidget,
        );

        // HUD button must toggle HUD <-> HUD aktiv without closing dock
        await tester.tap(find.byKey(const Key('btn_dock_open_hud')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.showFloatingHud, isTrue);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);
        expect(find.text('HUD aktiv'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_dock_open_hud')));
        await tester.pump();
        expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
        expect(DesktopTrackerService.instance.showFloatingHud, isFalse);
        expect(find.byType(PersistentTrackerDock), findsOneWidget);
        expect(find.text('HUD'), findsOneWidget);

        // Close (X) button must terminate tracking and remove the dock
        await tester.tap(find.byKey(const Key('btn_dock_close')));
        await tester.pumpAndSettle();
        expect(DesktopTrackerService.instance.isTrackingActive, isFalse);
        expect(find.byType(PersistentTrackerDock), findsNothing);
      },
    );

    testWidgets(
      'Popping DesktopTrackerScreen with keepTrackingInBackground=false cleans up dock without locked-tree FlutterError',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        TrackerPlatformHelper.debugIsDesktopOverride = () => true;
        addTearDown(TrackerPlatformHelper.resetDebugOverrides);
        addTearDown(() async {
          await DesktopTrackerService.instance.stopTracking();
        });

        final mockDexProvider = _MockDexProvider();
        when(() => mockDexProvider.userDexes).thenReturn([mockDex]);
        when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);

        final fakeBridge = _FakeDesktopBridge();
        final coordinator = ScannerCoordinator(
          engine: OcrDetectionEngine(),
          matcher: PokemonFuzzyMatcher.withEntries(const []),
          settings: ScannerSettings.defaults(),
        );
        addTearDown(() async {
          await coordinator.dispose();
        });

        await tester.pumpWidget(
          ChangeNotifierProvider<DexProvider>.value(
            value: mockDexProvider,
            child: MaterialApp(
              home: Builder(
                builder: (homeContext) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('btn_open_no_keep_alive'),
                      onPressed: () {
                        Navigator.of(homeContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DesktopTrackerScreen(
                              coordinator: coordinator,
                              initialDexId: mockDex.id,
                              detectedWindows: [DesktopWindowInfo.primaryScreen()],
                              nativeBridge: fakeBridge,
                              keepTrackingInBackground: false,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Tracker'),
                    ),
                  ),
                  bottomNavigationBar: PersistentTrackerDockHost(
                    onOpenSetup: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_open_no_keep_alive')));
        await tester.pumpAndSettle();
        expect(find.byType(DesktopTrackerScreen), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();

        // Must NOT throw "setState() or markNeedsBuild() called when widget tree was locked"
        expect(tester.takeException(), isNull);
        expect(DesktopTrackerService.instance.isTrackingActive, isFalse);
        expect(find.byType(PersistentTrackerDock), findsNothing);
      },
    );

    testWidgets(
      'Switching LocaleSettings updates PersistentTrackerDock active and paused labels',
      (tester) async {
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.de));
        LocaleSettings.setLocaleSync(AppLocale.en);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: PersistentTrackerDock(
                latestEvent: null,
                isScanningActive: true,
                onOpenHud: () {},
                onOpenSetup: () {},
                onTogglePause: () {},
              ),
            ),
          ),
        );
        expect(find.text('Live tracker active'), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: PersistentTrackerDock(
                latestEvent: null,
                isScanningActive: false,
                onOpenHud: () {},
                onOpenSetup: () {},
                onTogglePause: () {},
              ),
            ),
          ),
        );
        expect(find.text('PAUSED'), findsOneWidget);
        expect(find.text('Tracker paused'), findsOneWidget);
      },
    );
  });
}
