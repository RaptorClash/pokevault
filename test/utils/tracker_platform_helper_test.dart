import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pokevault/screens/dex/widgets/dex_app_bar_actions.dart';
import 'package:pokevault/screens/home/home_screen.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

class _MockDexProvider extends Mock implements DexProvider {}

class _MockTutorialProvider extends Mock implements TutorialProvider {}

class _MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  group('TrackerPlatformHelper & Platform Gating Tests (TDD)', () {
    late _MockDexProvider mockDexProvider;
    late _MockTutorialProvider mockTutorialProvider;
    late _MockSettingsProvider mockSettingsProvider;

    setUp(() {
      TrackerPlatformHelper.resetDebugOverrides();
      SharedPreferences.setMockInitialValues({});
      LocaleSettings.setLocale(AppLocale.de);
      TutorialOverlay.resetShowing();

      mockDexProvider = _MockDexProvider();
      mockTutorialProvider = _MockTutorialProvider();
      mockSettingsProvider = _MockSettingsProvider();

      when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
      when(() => mockTutorialProvider.getFeatureStep(any())).thenReturn(0);
      when(() => mockTutorialProvider.shouldShowV16UpdatePrompt).thenReturn(false);
      when(() => mockTutorialProvider.isDeltaTourActive).thenReturn(false);

      when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
      when(() => mockSettingsProvider.googleClientId).thenReturn('');
      when(() => mockSettingsProvider.googleClientSecret).thenReturn('');
      when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('de');

      when(() => mockDexProvider.isInitialized).thenReturn(true);
      when(() => mockDexProvider.isMigrating).thenReturn(false);
      when(() => mockDexProvider.userDexes).thenReturn(<UserDex>[]);
      when(() => mockDexProvider.folders).thenReturn(<DexFolder>[]);
      when(() => mockDexProvider.structure).thenReturn({'root': []});
      when(() => mockDexProvider.allAvailableDexes).thenReturn(const {});
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);
    });

    tearDown(() {
      TrackerPlatformHelper.resetDebugOverrides();
    });

    test('debug overrides cleanly toggle isDesktop and isMobile', () {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      expect(TrackerPlatformHelper.isDesktop, isTrue);
      expect(TrackerPlatformHelper.isMobile, isFalse);

      TrackerPlatformHelper.debugIsDesktopOverride = () => false;
      TrackerPlatformHelper.debugIsMobileOverride = () => true;
      expect(TrackerPlatformHelper.isDesktop, isFalse);
      expect(TrackerPlatformHelper.isMobile, isTrue);

      TrackerPlatformHelper.debugIsWebOverride = () => true;
      expect(TrackerPlatformHelper.isWeb, isTrue);

      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;
      expect(TrackerPlatformHelper.isDesktopOverlaySupported, isTrue);
      expect(TrackerPlatformHelper.isCameraTrackerSupported, isTrue);

      TrackerPlatformHelper.resetDebugOverrides();
      // Test runner runs on desktop host (Windows/Linux/macOS)
      expect(TrackerPlatformHelper.isDesktop || TrackerPlatformHelper.isMobile, isTrue);
    });

    testWidgets('HomeScreen on Windows shows 1 Tracker icon and opens unified DesktopTrackerScreen directly', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugIsWebOverride = () => false;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: TranslationProvider(
            child: const MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.track_changes), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.track_changes));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tracker_chooser_overlay')), findsNothing);
      expect(find.text('Desktop Tracker & Overlay'), findsOneWidget);
    });

    testWidgets('HomeScreen shows Camera/Webcam icon on Web/Linux/macOS and opens DesktopTrackerScreen directly', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => false;
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugIsWebOverride = () => true;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => false;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: TranslationProvider(
            child: const MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.track_changes), findsNothing);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('desktop_webcam_stage')), findsOneWidget);
    });

    testWidgets('HomeScreen hides Desktop Tracker icon on mobile and shows Camera Scanner icon', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => false;
      TrackerPlatformHelper.debugIsMobileOverride = () => true;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => false;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: TranslationProvider(
            child: const MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.track_changes), findsNothing);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);

      // Ctrl+Shift+O on mobile must NOT navigate to DesktopTrackerScreen
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(find.text('Desktop Tracker & Overlay'), findsNothing);
    });

    testWidgets('DexAppBarActions renders Desktop or Mobile scanner action strictly per callback', (tester) async {
      int desktopTapped = 0;
      int mobileTapped = 0;

      // Mobile wide mode
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(800, 600)),
              child: Scaffold(
                appBar: AppBar(
                  actions: [
                    DexAppBarActions(
                      isEditMode: false,
                      isBoxView: false,
                      separateForms: false,
                      onOpenDesktopTracker: null,
                      onOpenMobileScanner: () => mobileTapped++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.track_changes), findsNothing);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      expect(mobileTapped, 1);

      // Mobile narrow mode (menu item instead of AppBar icon)
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(360, 600)),
              child: Scaffold(
                appBar: AppBar(
                  actions: [
                    DexAppBarActions(
                      isEditMode: false,
                      isBoxView: false,
                      separateForms: false,
                      onOpenDesktopTracker: null,
                      onOpenMobileScanner: () => mobileTapped++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      expect(find.text('Desktop Tracker & Overlay'), findsNothing);
      expect(find.text('Kamera-Tracker'), findsOneWidget);
      await tester.tap(find.text('Kamera-Tracker'));
      await tester.pumpAndSettle();
      expect(mobileTapped, 2);

      // Desktop wide mode
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(800, 600)),
              child: Scaffold(
                appBar: AppBar(
                  actions: [
                    DexAppBarActions(
                      isEditMode: false,
                      isBoxView: false,
                      separateForms: false,
                      onOpenDesktopTracker: () => desktopTapped++,
                      onOpenMobileScanner: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
      await tester.tap(find.byIcon(Icons.track_changes));
      expect(desktopTapped, 1);
    });
  });
}
