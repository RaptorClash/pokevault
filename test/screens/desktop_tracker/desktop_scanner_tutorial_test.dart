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
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';
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

      await tester.tap(find.text('Überspringen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
