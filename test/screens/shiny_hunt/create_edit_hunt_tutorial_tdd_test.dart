import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/create_edit_hunt_dialog.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockShinyHuntProvider extends Mock implements ShinyHuntProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreateEditHuntDialog Tutorial TDD (Bild 3)', () {
    late MockDexProvider mockDexProvider;
    late MockShinyHuntProvider mockShinyHuntProvider;
    late MockSettingsProvider mockSettingsProvider;
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;

    setUp(() async {
      LocaleSettings.setLocale(AppLocale.de);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tutorialProvider = TutorialProvider(prefs);

      mockDexProvider = MockDexProvider();
      mockShinyHuntProvider = MockShinyHuntProvider();
      mockSettingsProvider = MockSettingsProvider();

      when(() => mockDexProvider.userDexes).thenReturn([UserDex.fallback('dex_1')]);
      when(() => mockDexProvider.allPokemon).thenReturn([
        Pokemon(
          id: 25,
          nameDe: 'Pikachu',
          nameEn: 'Pikachu',
          hasGenderDifferences: true,
          genderRate: 4,
          captureRate: 190,
          evolutionChainId: 10,
          eggGroups: ['Field'],
          weight: 6.0,
          speed: 90,
          forms: [],
        ),
      ]);
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    });

    testWidgets('CreateEditHuntDialog triggers tutorial explaining hunt parameters', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      expect(tutorialProvider.hasSeenFeature('create_hunt_dialog'), isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<ShinyHuntProvider>.value(value: mockShinyHuntProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateEditHuntDialog(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('create_hunt_dialog'));
      final titles = overlay.feature.steps.map((s) => s.titleKey).toList();
      expect(titles, contains('tutorial_hunt_pokemon_title'));
      expect(titles, contains('tutorial_hunt_game_method_title'));
      expect(titles, contains('tutorial_hunt_params_title'));
    });
  });
}
