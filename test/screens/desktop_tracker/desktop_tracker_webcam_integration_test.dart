import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOcrDriver implements LanguageAwareOcrDriver {
  String? _tag;
  final List<String> linesToReturn;

  _FakeOcrDriver({this.linesToReturn = const ['Wildes Pikachu']});

  @override
  String? get languageTag => _tag;

  @override
  void setLanguageTag(String? tag) => _tag = tag;

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async => linesToReturn;
}

void main() {
  group('DesktopWindowInfo.webcam & DesktopTrackerScreen Webcam Integration (TDD)', () {
    late _MockDexProvider mockDexProvider;
    late _MockSettingsProvider mockSettingsProvider;
    late ScannerCoordinator coordinator;
    late UserDex testDex;

    setUp(() {
      TrackerPlatformHelper.resetDebugOverrides();
      SharedPreferences.setMockInitialValues({});
      LocaleSettings.setLocale(AppLocale.de);

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
        caughtIds: [],
        shinyIds: [],
        alphaIds: [],
      );

      when(() => mockDexProvider.userDexes).thenReturn([testDex]);
      when(() => mockDexProvider.allPokemon).thenReturn([
        Pokemon(
          id: 25,
          nameDe: 'Pikachu',
          nameEn: 'Pikachu',
          names: const {'de': 'Pikachu', 'en': 'Pikachu'},
          genderRate: 4,
          captureRate: 190,
          hasGenderDifferences: false,
          evolutionChainId: 10,
          eggGroups: const ['Field'],
          weight: 60,
          speed: 90,
          forms: const [],
        ),
      ]);

      coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries([
          const PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
    });

    tearDown(() async {
      await coordinator.stop();
      TrackerPlatformHelper.resetDebugOverrides();
    });

    test('DesktopWindowInfo.webcam creates unique comparable camera source entries', () {
      final cam0 = DesktopWindowInfo.webcam(index: 0, name: 'Logitech Brio 4K');
      final cam1 = DesktopWindowInfo.webcam(index: 1, name: 'OBS Virtual Camera');
      final cam0Copy = DesktopWindowInfo.webcam(index: 0, name: 'Logitech Brio 4K');

      expect(cam0.isCameraSource, isTrue);
      expect(cam0.cameraIndex, 0);
      expect(cam0.title, contains('Logitech Brio 4K'));
      expect(cam0 == cam0Copy, isTrue);
      expect(cam0.hashCode, cam0Copy.hashCode);
      expect(cam0 == cam1, isFalse);
    });

    testWidgets('Windows DesktopTrackerScreen integrates webcams inside Scan-Quelle dropdown and toggles DesktopWebcamStage', (tester) async {
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      tester.view.physicalSize = const Size(1280, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final monitor = DesktopWindowInfo.primaryScreen();
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
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: DesktopTrackerScreen(
                coordinator: coordinator,
                detectedWindows: [monitor],
                availableCamerasOverride: usbCams,
                disableHardwareCamera: true,
                cameraOcrDriverOverride: _FakeOcrDriver(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially selected Monitor -> no webcam stage shown
      expect(find.byKey(const Key('emulator_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('desktop_webcam_stage')), findsNothing);

      // Open Scan-Quelle dropdown and select Logitech Brio 4K
      await tester.tap(find.byKey(const Key('emulator_dropdown')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Logitech Brio 4K'), findsWidgets);
      expect(find.textContaining('Elgato Cam Link 4K'), findsWidgets);

      await tester.tap(find.textContaining('Logitech Brio 4K').last);
      await tester.pumpAndSettle();

      // Right column now shows integrated DesktopWebcamStage above Live-Ereignisse
      expect(find.byKey(const Key('desktop_webcam_stage')), findsOneWidget);
      expect(find.text('Live-Ereignisse'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switching back to Monitor hides DesktopWebcamStage cleanly
      await tester.tap(find.byKey(const Key('emulator_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Bildschirm 1').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('desktop_webcam_stage')), findsNothing);
    });

    testWidgets('Web/Linux/macOS mode omits Windows monitor clutter and supports zero-webcam photo scan cleanly', (tester) async {
      TrackerPlatformHelper.debugIsWebOverride = () => true;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => false;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      tester.view.physicalSize = const Size(1280, 800);
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
              home: DesktopTrackerScreen(
                coordinator: coordinator,
                availableCamerasOverride: const [],
                disableHardwareCamera: true,
                cameraOcrDriverOverride: _FakeOcrDriver(linesToReturn: ['Wildes Pikachu']),
                sandboxImagePicker: () async => CapturedFrame(
                  width: 4,
                  height: 4,
                  bytes: Uint8List(64),
                  pixelFormat: 'bgra8888',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show webcam stage cleanly even when 0 webcams are plugged in
      expect(find.byKey(const Key('desktop_webcam_stage')), findsOneWidget);
      // Should NOT show Windows-only Floating HUD or Screen Borders toggle on Web/macOS/Linux
      expect(find.byKey(const Key('btn_open_floating_hud')), findsNothing);
      expect(find.byKey(const Key('switch_screen_borders')), findsNothing);

      // Trigger photo scan and confirm detection lands in Live-Ereignisse
      await tester.tap(find.byKey(const Key('btn_desktop_webcam_import_photo')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pikachu'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
