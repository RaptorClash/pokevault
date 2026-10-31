import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/screens/home/home_screen.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/widgets/tutorial/rotom_update_welcome_dialog.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockTutorialProvider extends Mock implements TutorialProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  group('HomeScreen Integration/UI Tests', () {
    late MockDexProvider mockDexProvider;
    late MockTutorialProvider mockTutorialProvider;
    late MockSettingsProvider mockSettingsProvider;

    final kantoDex = UserDex(
      id: 'dex_kanto',
      title: 'Kanto Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['1', '4'],
    );

    final johtoDex = UserDex(
      id: 'dex_johto',
      title: 'Johto Living Dex',
      region: 'johto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['152', '155', '158'],
    );

    final subDex = UserDex(
      id: 'dex_sub',
      title: 'SubFolder Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['7'],
    );

    final folder1 = DexFolder(id: 'folder_1', title: 'Mein Ordner');

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LocaleSettings.setLocale(AppLocale.de);

      mockDexProvider = MockDexProvider();
      mockTutorialProvider = MockTutorialProvider();
      mockSettingsProvider = MockSettingsProvider();
      TutorialOverlay.resetShowing();

      when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
      when(() => mockTutorialProvider.getFeatureStep(any())).thenReturn(0);
      when(() => mockTutorialProvider.shouldShowV16UpdatePrompt).thenReturn(false);
      when(() => mockTutorialProvider.isDeltaTourActive).thenReturn(false);

      when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
      when(() => mockSettingsProvider.googleClientId).thenReturn('');
      when(() => mockSettingsProvider.googleClientSecret).thenReturn('');

      when(() => mockDexProvider.isInitialized).thenReturn(true);
      when(() => mockDexProvider.isMigrating).thenReturn(false);
      when(() => mockDexProvider.userDexes).thenReturn([kantoDex, johtoDex, subDex]);
      when(() => mockDexProvider.folders).thenReturn([folder1]);
      when(() => mockDexProvider.structure).thenReturn({
        'root': ['dex_kanto', 'dex_johto', 'folder_1'],
        'folder_1': ['dex_sub'],
      });
      when(() => mockDexProvider.allAvailableDexes).thenReturn({
        'kanto': [1, 4, 7],
        'johto': [152, 155, 158],
      });
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);
    });

    Widget buildHomeScreen({String currentFolderId = 'root'}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
          ChangeNotifierProvider<TutorialProvider>.value(
            value: mockTutorialProvider,
          ),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider,
          ),
        ],
        child: MaterialApp(
          home: HomeScreen(currentFolderId: currentFolderId),
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
        when(() => mockDexProvider.userDexes).thenReturn([]);
        when(() => mockDexProvider.folders).thenReturn([]);
        when(() => mockDexProvider.structure).thenReturn({'root': []});

        await tester.pumpWidget(buildHomeScreen());

        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.sort), findsOneWidget);
        expect(find.byIcon(Icons.catching_pokemon), findsOneWidget);
        expect(find.textContaining('Noch kein Dex vorhanden'), findsOneWidget);
      },
    );

    testWidgets('Zeigt Dex-Karten und Ordner auf Root-Ebene an', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Kanto Dex'), findsOneWidget);
      expect(find.text('Johto Living Dex'), findsOneWidget);
      expect(find.text('Mein Ordner'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB oeffnet BottomSheet mit Optionen Neuer Pokédex und Neuer Ordner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Neuen Pokédex erstellen'), findsOneWidget);
      expect(find.text('Neuer Ordner'), findsOneWidget);

      // Tapping Neuer Ordner closes menu and opens dialog
      await tester.tap(find.text('Neuer Ordner'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Ordnername'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Ordner-Navigation oeffnet Ordner und Breadcrumb fuehrt zurueck', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Tap on folder icon button to open folder
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Inside folder_1, subDex is visible
      expect(find.text('SubFolder Dex'), findsOneWidget);
      expect(find.text('Kanto Dex'), findsNothing);

      // Breadcrumb shows 'Mein Ordner' and back arrow is present
      expect(find.text('Mein Ordner'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Tap back arrow to return to root
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Kanto Dex'), findsOneWidget);
      expect(find.text('Mein Ordner'), findsOneWidget);
    });

    testWidgets('Suche filtert Dexe nach Name und zeigt Kein Ergebnis wenn leer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'johto');
      await tester.pumpAndSettle();

      expect(find.text('Johto Living Dex'), findsOneWidget);
      expect(find.text('Kanto Dex'), findsNothing);

      // Enter unmatched search query
      await tester.enterText(find.byType(TextField), 'xyznonsense');
      await tester.pumpAndSettle();

      expect(find.text('Kanto Dex'), findsNothing);
      expect(find.text('Johto Living Dex'), findsNothing);
      expect(find.text('Mein Ordner'), findsNothing);

      // Clear search query
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Kanto Dex'), findsOneWidget);
      expect(find.text('Johto Living Dex'), findsOneWidget);
    });

    testWidgets('Sortiermenue aendert Sortiermodus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      expect(find.text('Manuell'), findsOneWidget);
      expect(find.text('A-Z'), findsOneWidget);
      expect(find.text('Meiste Gefangen'), findsOneWidget);
      expect(find.text('Nach Region'), findsOneWidget);

      // Select 'A-Z'
      await tester.tap(find.text('A-Z'));
      await tester.pumpAndSettle();

      // Items should be displayed in a ListView now (not ReorderableListView)
      expect(find.text('Johto Living Dex'), findsOneWidget);
      expect(find.text('Kanto Dex'), findsOneWidget);
    });

    testWidgets('Selection Mode: LongPress aktiviert Mehrfachauswahl und Loeschen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Long press on Kanto Dex
      await tester.longPress(find.text('Kanto Dex'));
      await tester.pumpAndSettle();

      // Selection mode active
      expect(find.text('1 ausgewählt'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.drive_file_move_outline), findsOneWidget);

      // Tap Johto Dex to add to selection
      await tester.tap(find.text('Johto Living Dex'));
      await tester.pumpAndSettle();
      expect(find.text('2 ausgewählt'), findsOneWidget);

      // Tap delete icon to open batch delete dialog
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Dexe löschen?'), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Tap close icon in AppBar to exit selection mode
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('1 ausgewählt'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Tastatur Backspace navigiert zurueck aus Unterordner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Navigate into folder
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();
      expect(find.text('SubFolder Dex'), findsOneWidget);

      // Send Backspace key event
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Should be back at root
      expect(find.text('Kanto Dex'), findsOneWidget);
      expect(find.text('Mein Ordner'), findsOneWidget);
    });

    testWidgets('Shows RotomUpdateWelcomeDialog when shouldShowV16UpdatePrompt is true', (
      WidgetTester tester,
    ) async {
      when(() => mockTutorialProvider.shouldShowV16UpdatePrompt).thenReturn(true);
      when(() => mockTutorialProvider.dismissV16UpdatePrompt()).thenAnswer((_) async {});
      when(() => mockTutorialProvider.startV16DeltaTour()).thenAnswer((_) async {});

      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(RotomUpdateWelcomeDialog), findsOneWidget);
      expect(find.textContaining('v1.6'), findsWidgets);
    });

    testWidgets('Shows Delta Tour starting with Shiny Hunt icon and advancing to newest dex', (
      WidgetTester tester,
    ) async {
      when(() => mockTutorialProvider.isDeltaTourActive).thenReturn(true);
      when(() => mockTutorialProvider.endDeltaTour()).thenAnswer((_) async {});

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      // Step 1: Shiny Hunt icon in AppBar
      expect(find.text(t.tutorial_v16_tour_shiny_title), findsOneWidget);

      // Tap 'Weiter' button to advance to step 2
      final nextBtn = find.text('Weiter');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Newest Dex card
      expect(find.text(t.tutorial_v16_tour_dex_title), findsOneWidget);
    });

    testWidgets('Shows Delta Tour starting with Shiny Hunt icon and advancing to FAB when dexes empty', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.userDexes).thenReturn([]);
      when(() => mockDexProvider.folders).thenReturn([]);
      when(() => mockDexProvider.structure).thenReturn({'root': []});
      when(() => mockTutorialProvider.isDeltaTourActive).thenReturn(true);
      when(() => mockTutorialProvider.endDeltaTour()).thenAnswer((_) async {});

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      // Step 1: Shiny Hunt icon in AppBar
      expect(find.text(t.tutorial_v16_tour_shiny_title), findsOneWidget);

      // Tap 'Weiter' button to advance to step 2
      final nextBtn = find.text('Weiter');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: FAB "+" button
      expect(find.text(t.tutorial_v16_tour_fab_title), findsOneWidget);
    });
  });
}
