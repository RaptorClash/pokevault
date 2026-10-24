import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/dex/box_edit_screen.dart';
import 'package:pokevault/screens/dex/box_content_edit_screen.dart';
import 'package:pokevault/screens/dex/pokemon_search_selection.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BoxEdit & BoxContentEdit Tutorial TDD', () {
    late MockDexProvider mockDexProvider;
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;
    late UserDex testDex;

    setUp(() async {
      LocaleSettings.setLocale(AppLocale.de);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tutorialProvider = TutorialProvider(prefs);
      mockDexProvider = MockDexProvider();

      testDex = UserDex.fallback('dex_1');
      testDex.customBoxes = [
        CustomBoxState(
          title: 'Box 1',
          pokemonIds: ['25'],
          columns: 6,
          rows: 5,
        ),
      ];

      when(() => mockDexProvider.userDexes).thenReturn([testDex]);
    });

    testWidgets('BoxEditScreen triggers box_edit_screen tutorial', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      expect(tutorialProvider.hasSeenFeature('box_edit_screen'), isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: MaterialApp(
            home: BoxEditScreen(
              dex: testDex,
              initialBoxes: const [],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('box_edit_screen'));
    });

    testWidgets('BoxContentEditScreen triggers box_content_edit tutorial', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      expect(tutorialProvider.hasSeenFeature('box_content_edit'), isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: MaterialApp(
            home: BoxContentEditScreen(
              dex: testDex,
              boxIndex: 0,
              allAvailableEntries: const [],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('box_content_edit'));
    });

    testWidgets('PokemonSearchSelectionScreen triggers pokemon_search_selection tutorial', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      expect(tutorialProvider.hasSeenFeature('pokemon_search_selection'), isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: const MaterialApp(
            home: PokemonSearchSelectionScreen(
              allAvailableEntries: [],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('pokemon_search_selection'));
    });
  });
}
