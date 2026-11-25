import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/desktop_tracker_dialogs.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/desktop_webcam_stage.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/live_frame_thumbnail.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/dex_selection_modal.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/floating_overlay_hud.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/persistent_tracker_dock.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/windows_desktop_bridge.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  group('DesktopTracker Adversarial & Boundary Tests', () {
    late ScannerCoordinator coordinator;
    late MockScannerSource mockSource;
    late MockDexProvider mockDexProvider;

    setUp(() {
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;
      mockSource = MockScannerSource();
      mockDexProvider = MockDexProvider();

      when(() => mockDexProvider.userDexes).thenReturn(<UserDex>[]);
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);

      coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([]),
        settings: ScannerSettings.defaults(),
      );
      coordinator.bindSource(mockSource);
    });

    tearDown(() async {
      TrackerPlatformHelper.resetDebugOverrides();
      await coordinator.dispose();
      await mockSource.dispose();
    });

    testWidgets('320x480 extreme narrow viewport: DesktopTrackerScreen renders with NO RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              detectedWindows: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Desktop Tracker & Overlay'), findsOneWidget);
    });

    testWidgets('Empty State: Handles 0 windows, 0 dexes, and null events gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockDexProvider.userDexes).thenReturn(<UserDex>[]);

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              detectedWindows: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kein Dex ausgewählt'), findsOneWidget);
    });

    testWidgets('DexSelectionModal handles empty search result without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DexSelectionModal(
              userDexes: const [],
              onDexSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kein passender Pokédex gefunden.'), findsOneWidget);
    });

    testWidgets('FloatingOverlayHud handles very long Pokémon names in compact mode', (tester) async {
      final longNameEvent = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Bisaflor Gigadynamax-Form Shiny Spezial',
        pokemonId: 3,
        isShiny: true,
        rawText: 'Ein wildes Bisaflor erscheint!',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: FloatingOverlayHud(
                latestEvent: longNameEvent,
                isCompact: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Bisaflor'), findsOneWidget);
    });

    testWidgets('PersistentTrackerDock handles extreme 320px width without overflow', (tester) async {
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Glumanda',
        pokemonId: 4,
        isShiny: true,
        rawText: 'Glumanda',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: PersistentTrackerDock(
                latestEvent: event,
                isScanningActive: true,
                onOpenHud: () {},
                onOpenSetup: () {},
                onTogglePause: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Glumanda'), findsOneWidget);
    });

    testWidgets('Rapid double-tap on Desktop Snipping ignores duplicate concurrent launches', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final completer = Completer<ScreenRegionCaptureResult?>();
      int launchCount = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              detectedWindows: const [],
              desktopSnippingLauncher: () {
                launchCount++;
                return completer.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.byKey(const Key('btn_start_snipping'));
      await tester.tap(btn);
      await tester.pump();
      await tester.tap(btn);
      await tester.pump();

      expect(launchCount, 1);
      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('320x480 narrow viewport with active desktop snippet preview renders with NO RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              detectedWindows: const [],
              desktopSnippingLauncher: () async => ScreenRegionCaptureResult(
                region: ScreenRegion(
                  x: 100,
                  y: 200,
                  width: 500,
                  height: 150,
                  isAbsoluteScreen: true,
                  label: 'Desktop-Snipping',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('btn_start_snipping')));
      await tester.tap(find.byKey(const Key('btn_start_snipping')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('desktop_snippet_preview_card')), findsOneWidget);
    });

    testWidgets('320x480 extreme narrow viewport: Pattern Studio & Smart-Match event render cleanly with NO overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final smartCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
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
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await smartCoord.processText('Klasse!\nZr-rrokex wrde aefar«t!');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(const Key('btn_custom_patterns')));
      await tester.tap(find.byKey(const Key('btn_custom_patterns')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_patterns_dialog')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320x480 extreme narrow viewport: Multi-Encounter focus cards, Zone-B presets & ignored team chips render with NO overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final multiCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 497, name: 'Serpiroyal', language: 'de'),
          PokemonMatcherEntry(id: 551, name: 'Ganovil', language: 'de'),
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
        ]),
        settings: ScannerSettings.defaults().copyWith(
          liveFocusPreset: LiveFocusPreset.topBanner,
          ignoredPokemonIds: const [497],
        ),
      );
      addTearDown(() async => await multiCoord.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: multiCoord,
              detectedWindows: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await multiCoord.processFrameText(
        'Zurrokex Lv.16   Flampion Lv.16   Ganovil Lv.17',
        encounterOnly: true,
        allowMultiEncounter: true,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('focus_enemy_card_559')), findsOneWidget);
      expect(find.byKey(const Key('focus_enemy_card_554')), findsOneWidget);
      expect(find.byKey(const Key('focus_enemy_card_551')), findsOneWidget);
      expect(find.byKey(const Key('ignored_pokemon_chip_497')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Adversarial 320x480 narrow viewport with Zone B, Multi-Instance grid, and Border toggle never overflows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn(const []);
      when(() => mockDexProvider.allPokemon).thenReturn(const []);

      final coord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
        ]),
        settings: ScannerSettings.defaults().copyWith(
          liveFocusPreset: LiveFocusPreset.topBanner,
          multiInstanceSlots: [
            MultiInstanceSlot(
              id: 2,
              label: '#2',
              colorHex: 0xFFA855F7,
              scanEnabled: true,
              scanRegion: ScreenRegion(x: 0, y: 300, width: 400, height: 100, isAbsoluteScreen: true),
              focusPreset: LiveFocusPreset.customRegion,
              focusRegion: ScreenRegion(x: 20, y: 20, width: 200, height: 60, isAbsoluteScreen: true),
            ),
            const MultiInstanceSlot(
              id: 3,
              label: '#3',
              colorHex: 0xFFEC4899,
              windowHwnd: 2002,
              windowTitle: 'melonDS #2',
              scanEnabled: false,
              focusPreset: LiveFocusPreset.topLeft,
            ),
          ],
        ),
      );
      addTearDown(() async => await coord.dispose());

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coord,
              detectedWindows: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scan_zone_a_card')), findsOneWidget);
      expect(find.byKey(const Key('scan_zone_b_card')), findsOneWidget);
      expect(find.byKey(const Key('multi_instance_card')), findsOneWidget);

      // Opening all (i) info banners on narrow 320x480 screen must never overflow
      for (final infoKey in const [
        Key('btn_info_zone_a'),
        Key('btn_info_zone_b'),
        Key('btn_info_scan_profile'),
      ]) {
        final finder = find.byKey(infoKey);
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('info_box_zone_a')), findsOneWidget);
      expect(find.byKey(const Key('info_box_zone_b')), findsOneWidget);
      expect(find.byKey(const Key('info_box_scan_profile')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320x480 narrow viewport: DesktopWebcamStage idle and error states render with NO RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final err in <String?>[
        null,
        'Kamera-Berechtigung wurde verweigert — bitte Zugriff in den Systemeinstellungen erlauben.',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DesktopWebcamStage(
                  cameraTitle: '📷 Webcam / Foto-Scan',
                  cameraController: null,
                  isInitializing: false,
                  errorText: err,
                  isPermissionDenied: err != null,
                  isTrackingActive: true,
                  hasMultipleCameras: false,
                  isEditingRegions: false,
                  scanMode: MobileCameraScanMode.autoFull,
                  autoPreset: ScanRegionPreset.fullWindow,
                  regions: const [],
                  activeBrushRole: CameraZoneRole.scan,
                  onRegionsChanged: (_) {},
                  onToggleEditRegions: () {},
                  onImportPhoto: () {},
                  onRetryCamera: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('320x480 extreme narrow viewport in non-Windows Webcam mode renders with NO RenderFlex overflow', (tester) async {
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => false;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: DesktopTrackerScreen(
              coordinator: coordinator,
              detectedWindows: const [],
              availableCamerasOverride: const [],
              disableHardwareCamera: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Webcam Tracker'), findsOneWidget);
      expect(find.byKey(const Key('desktop_webcam_stage')), findsOneWidget);
    });

    testWidgets('320x480 extreme narrow viewport: SelfScanOverlapDialog & LiveFrameThumbnail(maxDecodeWidth) render with NO overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bigBgra = CapturedFrame(
        width: 120,
        height: 80,
        bytes: List<int>.filled(120 * 80 * 4, 180),
        pixelFormat: 'bgra8888',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 60,
                  height: 36,
                  child: LiveFrameThumbnail(
                    liveFrame: bigBgra,
                    fallbackPngBytes: null,
                    fallbackIcon: Icons.crop_free,
                    maxDecodeWidth: 64,
                  ),
                ),
                Builder(
                  builder: (ctx) => ElevatedButton(
                    key: const Key('open_overlap_dialog'),
                    onPressed: () =>
                        DesktopTrackerDialogs.showSelfScanOverlapDialog(ctx),
                    child: const Text('Open'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_overlap_dialog')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dialog_self_scan_overlap')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
