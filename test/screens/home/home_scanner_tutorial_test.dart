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
import 'package:pokevault/screens/home/home_screen.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';
import 'package:pokevault/widgets/tutorial/rotom_update_welcome_dialog.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

class _MockDexProvider extends Mock implements DexProvider {}
class _MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDexProvider mockDexProvider;
  late _MockSettingsProvider mockSettingsProvider;

  setUp(() {
    TutorialOverlay.resetShowing();
    TrackerPlatformHelper.resetDebugOverrides();
    LocaleSettings.setLocaleSync(AppLocale.de);

    mockDexProvider = _MockDexProvider();
    mockSettingsProvider = _MockSettingsProvider();

    when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
    when(() => mockSettingsProvider.googleClientId).thenReturn('');
    when(() => mockSettingsProvider.googleClientSecret).thenReturn('');
    when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('de');

    when(() => mockDexProvider.isInitialized).thenReturn(true);
    when(() => mockDexProvider.isMigrating).thenReturn(false);
    when(() => mockDexProvider.userDexes).thenReturn(<UserDex>[]);
    when(() => mockDexProvider.folders).thenReturn(<DexFolder>[]);
    when(() => mockDexProvider.structure).thenReturn({'root': <String>[]});
    when(() => mockDexProvider.allAvailableDexes).thenReturn({});
    when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);
  });

  tearDown(() {
    TutorialOverlay.resetShowing();
    TrackerPlatformHelper.resetDebugOverrides();
  });

  testWidgets('HomeScreen shows Scanner Update Dialog for v1.6 users and launches Delta-Tour on Scanner icon', (tester) async {
    TrackerPlatformHelper.debugIsMobileOverride = () => true;
    TrackerPlatformHelper.debugIsDesktopOverride = () => false;
    TrackerPlatformHelper.debugOverlaySupportedOverride = () => false;
    TrackerPlatformHelper.debugCameraSupportedOverride = () => true;

    SharedPreferences.setMockInitialValues({
      'home_screen': true,
      'v1_6_update_announced': true,
      'completed_tutorial_version': 2,
    });
    final prefs = await SharedPreferences.getInstance();
    final tutProvider = TutorialProvider(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
          ChangeNotifierProvider<TutorialProvider>.value(value: tutProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
        ],
        child: TranslationProvider(
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RotomUpdateWelcomeDialog), findsOneWidget);

    final startBtn = find.text('Neuheiten-Tour starten');
    await tester.ensureVisible(startBtn);
    await tester.tap(startBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RotomUpdateWelcomeDialog), findsNothing);
    expect(tutProvider.isScannerDeltaTourActive, isTrue);
    // HomeScreen v1.7 Delta Tour Step 1: Shiny Hunt overview
    expect(find.byType(TutorialOverlay), findsOneWidget);
    expect(find.text(t.tutorial_v17_home_shiny_title), findsOneWidget);

    await tester.tap(find.text(t.tutorial_next));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 2: Scanner icon highlight
    expect(find.text(t.tutorial_scanner_home_delta_title), findsOneWidget);

    // Tapping the highlighted Scanner action button ends Delta-Tour and launches MobileCameraTrackerScreen
    await tester.tap(find.byIcon(Icons.photo_camera_outlined), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tutProvider.isScannerDeltaTourActive, isFalse);
  });
}
