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
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/services/desktop_tracker/desktop_tracker_service.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';
import 'package:pokevault/models/tutorial_step.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

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

void main() {
  group('DesktopTrackerScreen Scanner Tutorial Tests (TDD)', () {
    late _MockDexProvider mockDexProvider;
    late _MockSettingsProvider mockSettingsProvider;
    late ScannerCoordinator coordinator;
    late UserDex testDex;

    setUp(() {
      TutorialOverlay.resetShowing();
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
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
    });

    tearDown(() async {
      TutorialOverlay.resetShowing();
      await DesktopTrackerService.instance.stopTracking();
      await coordinator.stop();
      await coordinator.dispose();
      TrackerPlatformHelper.resetDebugOverrides();
    });

    testWidgets('auto-starts Desktop+Camera tutorial on first open and allows replay via help button', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
              home: DesktopTrackerScreen(
                coordinator: coordinator,
                disableHardwareCamera: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(find.byKey(const Key('btn_desktop_scanner_help')), findsOneWidget);

      await tester.tap(find.text('Überspringen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TutorialOverlay), findsNothing);
      expect(tutProvider.hasSeenFeature('desktop_scanner_tour'), isTrue);

      await tester.tap(find.byKey(const Key('btn_desktop_scanner_help')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TutorialOverlay), findsOneWidget);

      // Step through granular Desktop sections (Source -> Target Dex -> Borders -> Zone A -> Zone B -> Multi -> HUD -> Feed/OCR)
      expect(find.textContaining('Schritt 1 von 8'), findsOneWidget);
      await tester.tap(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.textContaining('Schritt 2 von 8'), findsOneWidget);

      await tester.tap(find.text('Überspringen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('transitioning from HomeScreen Delta-Tour onTargetTap does not get blocked by _isShowing', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;
      TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final launcherKey = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    actions: [
                      IconButton(
                        key: launcherKey,
                        icon: const Icon(Icons.track_changes),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DesktopTrackerScreen(
                                coordinator: coordinator,
                                disableHardwareCamera: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  body: ElevatedButton(
                    onPressed: () {
                      TutorialOverlay.show(
                        context,
                        TutorialFeature(
                          id: 'delta_test',
                          nameKey: 'tutorial_scanner_tour_btn',
                          steps: [
                            TutorialStep(
                              targetKey: launcherKey,
                              titleKey: 'tutorial_scanner_home_delta_title',
                              textKey: 'tutorial_scanner_home_delta_text',
                              requireTargetTap: true,
                              onTargetTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DesktopTrackerScreen(
                                      coordinator: coordinator,
                                      disableHardwareCamera: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        () {},
                      );
                    },
                    child: const Text('Start Delta'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Delta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TutorialOverlay), findsOneWidget);

      await tester.tap(find.byIcon(Icons.track_changes), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DesktopTrackerScreen), findsOneWidget);
      // DesktopTrackerScreen's own TutorialOverlay MUST appear immediately!
      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(find.textContaining('Schritt 1 von 8'), findsOneWidget);
    });

    testWidgets('keepTrackingInBackground preserves active coordinator when DesktopTrackerScreen pops', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      await tutProvider.markFeatureAsSeen('desktop_scanner_tour');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DesktopTrackerScreen(
                            coordinator: coordinator,
                            disableHardwareCamera: true,
                            keepTrackingInBackground: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Tracker'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Tracker'));
      await tester.pumpAndSettle();
      expect(find.byType(DesktopTrackerScreen), findsOneWidget);
      expect(find.byType(TutorialOverlay), findsNothing);

      // Pop back to Home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopTrackerScreen), findsNothing);
      expect(DesktopTrackerService.instance.isTrackingActive, isTrue);

      await tester.runAsync(() => DesktopTrackerService.instance.stopTracking());
      await tester.pump();
    });

    testWidgets('pausing inside DesktopTrackerScreen and popping preserves paused session in dock instead of terminating', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugOverlaySupportedOverride = () => true;

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      await tutProvider.markFeatureAsSeen('desktop_scanner_tour');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutProvider),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DesktopTrackerScreen(
                            coordinator: coordinator,
                            disableHardwareCamera: true,
                            keepTrackingInBackground: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Tracker'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Tracker'));
      await tester.pumpAndSettle();
      expect(find.byType(DesktopTrackerScreen), findsOneWidget);

      // Pause inside DesktopTrackerScreen
      final pauseFinder = find.text('Pausieren');
      expect(pauseFinder, findsOneWidget);
      await tester.ensureVisible(pauseFinder);
      await tester.pump();
      await tester.tap(pauseFinder);
      await tester.pump();
      expect(find.text('Fortsetzen'), findsOneWidget);

      // Pop back -> must keep tracking session alive as PAUSED, NOT terminate
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopTrackerScreen), findsNothing);
      expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
      expect(DesktopTrackerService.instance.isPaused, isTrue);

      await tester.runAsync(() => DesktopTrackerService.instance.stopTracking());
      await tester.pump();
    });
  });
}
