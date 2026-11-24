import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/mobile_scanner/mobile_camera_tracker_screen.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_source.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_tracker_service.dart';
import 'package:pokevault/services/mobile_scanner/mobile_ocr_driver.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';

class _MockDexProvider extends Mock implements DexProvider {}

class _MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  String currentLanguage = 'de';

  @override
  String pokemonLanguage = 'de';

  @override
  String get effectivePokemonLanguage =>
      pokemonLanguage == 'auto' ? currentLanguage : pokemonLanguage;

  @override
  void setPokemonLanguage(String lang) {
    pokemonLanguage = lang;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserDex extends Fake implements UserDex {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserDex());
  });

  group('MobileCameraTrackerScreen Tests (TDD & Adversarial)', () {
    late _MockDexProvider mockDexProvider;
    late _MockSettingsProvider mockSettingsProvider;
    late UserDex testDex;
    late ScannerCoordinator coordinator;
    late MobileCameraSource cameraSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LocaleSettings.setLocaleSync(AppLocale.de);
      await MobileCameraTrackerService.instance.stopSession();

      mockDexProvider = _MockDexProvider();
      mockSettingsProvider = _MockSettingsProvider();
      testDex = UserDex(
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
        shinyIds: [],
        alphaIds: [],
      );

      when(() => mockDexProvider.userDexes).thenReturn([testDex]);
      when(() => mockDexProvider.allPokemon).thenReturn([
        Pokemon(
          id: 1,
          nameDe: 'Bisasam',
          nameEn: 'Bulbasaur',
          names: const {'de': 'Bisasam', 'en': 'Bulbasaur'},
          hasGenderDifferences: false,
          genderRate: 1,
          captureRate: 45,
          evolutionChainId: 1,
          eggGroups: const ['monster', 'plant'],
          weight: 6.9,
          speed: 45,
          forms: const [],
        ),
        Pokemon(
          id: 4,
          nameDe: 'Glumanda',
          nameEn: 'Charmander',
          names: const {'de': 'Glumanda', 'en': 'Charmander'},
          hasGenderDifferences: false,
          genderRate: 1,
          captureRate: 45,
          evolutionChainId: 2,
          eggGroups: const ['monster', 'dragon'],
          weight: 8.5,
          speed: 65,
          forms: const [],
        ),
        Pokemon(
          id: 25,
          nameDe: 'Pikachu',
          nameEn: 'Pikachu',
          names: const {'de': 'Pikachu', 'en': 'Pikachu'},
          hasGenderDifferences: true,
          genderRate: 4,
          captureRate: 190,
          evolutionChainId: 10,
          eggGroups: const ['ground', 'fairy'],
          weight: 6.0,
          speed: 90,
          forms: const [],
        ),
      ]);
      when(() => mockDexProvider.allAvailableDexes).thenReturn({
        'kanto': [1, 4, 25],
      });
      when(() => mockDexProvider.saveUserDexAndSync(any())).thenAnswer((_) async {});

      final matcher = PokemonFuzzyMatcher.withEntries(const [
        PokemonMatcherEntry(id: 1, name: 'Bisasam', language: 'de'),
        PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
        PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
      ]);
      coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: matcher,
        settings: ScannerSettings.defaults().copyWith(
          preprocessProfile: OcrPreprocessProfile.cameraDisplay,
        ),
        encounterCooldown: Duration.zero,
      );
      cameraSource = MobileCameraSource(
        ocrDriver: MobileOcrDriver(
          customRecognizer: (_, _) async => ['Klasse! Glumanda wurde gefangen!'],
        ),
      );
    });

    tearDown(() async {
      await MobileCameraTrackerService.instance.stopSession();
      await coordinator.dispose();
      await cameraSource.dispose();
    });

    Widget buildScreen({
      Future<CapturedFrame?> Function()? photoPicker,
      bool simulatePermissionDenied = false,
      Size viewportSize = const Size(390, 844),
      ThemeData? theme,
      List<CameraDescription> availableCamerasOverride = const [],
      bool initialSplitView = false,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: theme ?? ThemeData.light(),
            home: MediaQuery(
              data: MediaQueryData(size: viewportSize),
              child: MobileCameraTrackerScreen(
                coordinator: coordinator,
                cameraSource: cameraSource,
                initialDexId: testDex.id,
                disableHardwareCamera: true,
                simulatePermissionDenied: simulatePermissionDenied,
                photoFramePicker: photoPicker,
                initialSplitView: initialSplitView,
                availableCamerasOverride: availableCamerasOverride,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('switches between Fullscreen and Split-Screen, Auto and Draw modes, and scans photo into Dex', (tester) async {
      final sampleFrame = CapturedFrame(
        width: 16,
        height: 16,
        bytes: Uint8List.fromList(List.filled(16 * 16 * 4, 200)),
        pixelFormat: 'bgra8888',
      );

      await tester.pumpWidget(buildScreen(photoPicker: () async => sampleFrame));
      await tester.pump();

      // Default fullscreen view renders camera viewport & mode toggles
      expect(find.byKey(const Key('mobile_camera_preview_surface')), findsOneWidget);
      expect(find.byKey(const Key('btn_scan_mode_auto')), findsOneWidget);
      expect(find.byKey(const Key('btn_scan_mode_draw')), findsOneWidget);

      // Toggle to Draw Rectangles mode
      await tester.tap(find.byKey(const Key('btn_scan_mode_draw')));
      await tester.pump();
      expect(cameraSource.scanMode, MobileCameraScanMode.customRegions);

      // Toggle back to Auto mode and scan a photo frame
      await tester.tap(find.byKey(const Key('btn_scan_mode_auto')));
      await tester.pump();
      expect(cameraSource.scanMode, MobileCameraScanMode.autoFull);

      await tester.tap(find.byKey(const Key('btn_import_photo_scan')));
      await tester.pumpAndSettle();

      // Glumanda (#4) should be recognized and auto-marked in testDex
      expect(testDex.caughtIds, contains('4'));
      expect(find.textContaining('Glumanda'), findsWidgets);

      // Switch to Split-Screen view and verify tabs
      await tester.tap(find.byKey(const Key('btn_toggle_split_view')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('split_tab_focus')), findsOneWidget);
      expect(find.byKey(const Key('split_tab_zones')), findsOneWidget);
      expect(find.byKey(const Key('split_tab_feed')), findsOneWidget);

      await tester.tap(find.byKey(const Key('split_tab_feed')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Glumanda'), findsWidgets);
    });

    testWidgets('activates PiP overlay mode when tapping PiP minimize button', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('btn_launch_cam'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MobileCameraTrackerScreen(
                              coordinator: coordinator,
                              cameraSource: cameraSource,
                              initialDexId: testDex.id,
                              disableHardwareCamera: true,
                            ),
                          ),
                        );
                      },
                      child: const Text('Launch'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_launch_cam')));
      await tester.pumpAndSettle();
      expect(find.byType(MobileCameraTrackerScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_minimize_to_pip')));
      await tester.pumpAndSettle();

      expect(find.byType(MobileCameraTrackerScreen), findsNothing);
      expect(MobileCameraTrackerService.instance.isPipVisible, isTrue);
    });

    testWidgets('adversarial: 320x480 narrow viewport, landscape 800x360, and permission denied show no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildScreen(
          simulatePermissionDenied: true,
          viewportSize: const Size(320, 480),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('camera_permission_denied_banner')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Landscape 800x360 in Split-Screen
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpWidget(buildScreen(viewportSize: const Size(800, 360)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_toggle_split_view')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses unified app ThemeData (Light & Dark) across Scaffold, toolbar, brush bar, and collapsed bottom bar', (tester) async {
      final lightTheme = ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
      );

      await tester.pumpWidget(buildScreen(theme: lightTheme));
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_scan_mode_draw')));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFFF7F7F8));

      final topToolbar = tester.widget<Container>(
        find.byKey(const Key('mobile_tracker_top_toolbar')),
      );
      final topDeco = topToolbar.decoration as BoxDecoration?;
      expect(topToolbar.color ?? topDeco?.color, lightTheme.colorScheme.surface);

      final brushBar = tester.widget<Container>(
        find.byKey(const Key('mobile_draw_brush_bar')),
      );
      final brushDeco = brushBar.decoration as BoxDecoration?;
      expect(
        brushBar.color ?? brushDeco?.color,
        isNot(const Color(0xFF151824)),
      );

      final collapsedBar = tester.widget<Container>(
        find.byKey(const Key('mobile_collapsed_bottom_bar')),
      );
      final collapsedDeco = collapsedBar.decoration as BoxDecoration?;
      expect(
        collapsedBar.color ?? collapsedDeco?.color,
        isNot(const Color(0xFF141724)),
      );

      // Verify Dark Mode switches consistently without exceptions
      final darkTheme = ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpWidget(buildScreen(theme: darkTheme));
      await tester.pumpAndSettle();
      final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(darkScaffold.backgroundColor, const Color(0xFF121212));
      expect(tester.takeException(), isNull);
    });

    testWidgets('manages Multi-Instance cards with Zone A (Scan) & Zone B (Fokus), camera dropdown, and multi-focus cards', (tester) async {
      const cameras = [
        CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
      ];

      await tester.pumpWidget(
        buildScreen(
          initialSplitView: true,
          availableCamerasOverride: cameras,
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Zonen & Kamera tab
      await tester.tap(find.byKey(const Key('split_tab_zones')));
      await tester.pumpAndSettle();

      // Verify Camera selector dropdown lists available cameras
      expect(find.byKey(const Key('dropdown_mobile_camera_selector')), findsOneWidget);

      // Add Instanz #2
      final addBtn = find.byKey(const Key('btn_mobile_multi_add_instance'));
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile_multi_card_2')), findsOneWidget);
      expect(find.byKey(const Key('btn_mobile_multi_draw_scan_2')), findsOneWidget);
      expect(find.byKey(const Key('btn_mobile_multi_draw_focus_2')), findsOneWidget);

      // Tap Scan zeichnen for Instanz #2 and draw on canvas
      await tester.ensureVisible(find.byKey(const Key('btn_mobile_multi_draw_scan_2')));
      await tester.tap(find.byKey(const Key('btn_mobile_multi_draw_scan_2')));
      await tester.pumpAndSettle();

      final canvasFinder = find.byKey(const Key('camera_region_canvas'));
      final topLeft = tester.getTopLeft(canvasFinder);
      await tester.timedDragFrom(
        topLeft + const Offset(20, 110),
        const Offset(120, 50),
        const Duration(milliseconds: 100),
      );
      await tester.pumpAndSettle();

      // Tap Fokus zeichnen for Instanz #2 and draw Zone B on canvas
      await tester.ensureVisible(find.byKey(const Key('btn_mobile_multi_draw_focus_2')));
      await tester.tap(find.byKey(const Key('btn_mobile_multi_draw_focus_2')));
      await tester.pumpAndSettle();

      await tester.timedDragFrom(
        topLeft + const Offset(20, 20),
        const Offset(120, 45),
        const Duration(milliseconds: 100),
      );
      await tester.pumpAndSettle();

      expect(cameraSource.regions.any((r) => r.id == 'multi_2_scan' && !r.encounterOnly), isTrue);
      expect(cameraSource.regions.any((r) => r.id == 'multi_2_focus' && r.encounterOnly), isTrue);

      // Trigger multi-instance focus events on coordinator and verify multi-focus cards in Fokus & Dex
      await coordinator.processFrameText(
        'Wildes Pikachu',
        encounterOnly: true,
        instanceIndex: 1,
        instanceColorHex: 0xFF10B981,
      );
      await coordinator.processFrameText(
        'Wildes Bisasam',
        encounterOnly: true,
        instanceIndex: 2,
        instanceColorHex: 0xFFA855F7,
      );
      await tester.tap(find.byKey(const Key('split_tab_focus')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile_multi_focus_grid')), findsOneWidget);
      expect(find.textContaining('Pikachu'), findsWidgets);
      expect(find.textContaining('Bisasam'), findsWidgets);

      // Remove Instanz #2 cleans up both Zone A and Zone B
      await tester.tap(find.byKey(const Key('split_tab_zones')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('btn_mobile_multi_remove_2')));
      await tester.tap(find.byKey(const Key('btn_mobile_multi_remove_2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile_multi_card_2')), findsNothing);
      expect(cameraSource.regions.where((r) => r.slotId == 2), isEmpty);
    });

    testWidgets('renders multiple external/virtual cameras on wide desktop viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const usbCams = [
        CameraDescription(
          name: 'Logitech Brio 4K',
          lensDirection: CameraLensDirection.external,
          sensorOrientation: 0,
        ),
        CameraDescription(
          name: 'Elgato Cam Link 4K',
          lensDirection: CameraLensDirection.external,
          sensorOrientation: 0,
        ),
        CameraDescription(
          name: 'OBS Virtual Camera',
          lensDirection: CameraLensDirection.external,
          sensorOrientation: 0,
        ),
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: MobileCameraTrackerScreen(
                coordinator: coordinator,
                cameraSource: cameraSource,
                disableHardwareCamera: true,
                initialSplitView: true,
                availableCamerasOverride: usbCams,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('split_tab_zones')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_mobile_camera_selector')), findsOneWidget);
      expect(find.textContaining('Logitech Brio 4K'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles tiny 320x480 viewport and runtime DE <-> EN language switch without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: MobileCameraTrackerScreen(
                coordinator: coordinator,
                cameraSource: cameraSource,
                disableHardwareCamera: true,
                initialSplitView: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      mockSettingsProvider.setPokemonLanguage('en');
      LocaleSettings.setLocaleSync(AppLocale.en);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders draw brush bar in landscape split-screen when customRegions is active', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildScreen(
          viewportSize: const Size(800, 360),
          initialSplitView: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_scan_mode_draw')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile_draw_brush_bar')), findsOneWidget);
    });

    testWidgets('triggers Mobile Scanner TutorialOverlay on first open and via help button without desktop steps', (tester) async {
      TutorialOverlay.resetShowing();
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: MobileCameraTrackerScreen(
                coordinator: coordinator,
                cameraSource: cameraSource,
                disableHardwareCamera: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Auto-triggered Mobile Scanner Tutorial should be visible
      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(find.byKey(const Key('btn_mobile_scanner_help')), findsOneWidget);
      // Must NOT talk about Windows / Emulator window capture
      expect(find.textContaining('Emulator-Fenster'), findsNothing);

      // Dismiss tutorial by skipping
      await tester.tap(find.text('Überspringen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TutorialOverlay), findsNothing);
      expect(tutProvider.hasSeenFeature('mobile_scanner_tour'), isTrue);

      // Help button replays the tour on demand
      await tester.tap(find.byKey(const Key('btn_mobile_scanner_help')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TutorialOverlay), findsOneWidget);

      await tester.tap(find.text('Überspringen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
