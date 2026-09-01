import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEU
import 'package:pokevault/screens/home/home_screen.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/l10n/app_translations.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockTutorialProvider extends Mock implements TutorialProvider {}

void main() {
  group('HomeScreen Integration/UI Tests', () {
    late MockDexProvider mockDexProvider;
    late MockTutorialProvider mockTutorialProvider;

    setUp(() {
      // WICHTIG: Mock für SharedPreferences, damit _checkWebWarning() nicht crasht
      SharedPreferences.setMockInitialValues({});

      Translator.currentLanguage = 'de';
      mockDexProvider = MockDexProvider();
      mockTutorialProvider = MockTutorialProvider();

      when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
      when(() => mockDexProvider.userDexes).thenReturn([]);
      when(() => mockDexProvider.folders).thenReturn([]);
      when(() => mockDexProvider.structure).thenReturn({'root': []});
    });

    Widget buildHomeScreen() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(
              value: mockTutorialProvider,
            ),
          ],
          child: const HomeScreen(),
        ),
      );
    }

    testWidgets('Zeigt Lade-Screen an, wenn Migration läuft', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.isInitialized).thenReturn(false);
      when(() => mockDexProvider.isMigrating).thenReturn(true);

      await tester.pumpWidget(buildHomeScreen());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Daten werden'), findsOneWidget);
    });

    testWidgets(
      'Zeigt leeren Zustand (Pokéball Icon), wenn initialisiert aber leer',
      (WidgetTester tester) async {
        when(() => mockDexProvider.isInitialized).thenReturn(true);
        when(() => mockDexProvider.isMigrating).thenReturn(false);

        await tester.pumpWidget(buildHomeScreen());

        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.sort), findsOneWidget);
        expect(find.byIcon(Icons.catching_pokemon), findsOneWidget);
      },
    );
  });
}
