import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/dex/dex_list_view.dart';
import 'package:pokevault/screens/dex/pokemon_search_selection.dart';
import 'package:pokevault/screens/dex/widgets/search/pokemon_search_tile.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_info_widgets.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}
class MockTutorialProvider extends Mock implements TutorialProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockTutorialProvider mockTutorialProvider;

  final bulbasaur = Pokemon.fromMap({
    'id': 1,
    'name_de': 'Bisasam',
    'name_en': 'Bulbasaur',
    'name_fr': 'Bulbizarre',
    'name_ja': 'フシギダネ',
    'has_gender_differences': 0,
    'gender_rate': 1,
    'capture_rate': 45,
    'evolution_chain_id': 1,
    'egg_groups': 'monster,plant',
    'weight': 6.9,
    'speed': 45,
    'catch_rate_tags': '',
  });

  final bulbasaurEntry = DexDisplayEntry(
    pokemon: bulbasaur,
    uniqueId: '1',
    displaySuffix: '',
    imageUrl: '',
  );

  final testDex = UserDex.fallback('test_dex');

  setUp(() {
    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockTutorialProvider = MockTutorialProvider();

    when(() => mockDexProvider.userDexes).thenReturn([testDex]);
    when(() => mockDexProvider.allPokemon).thenReturn([bulbasaur]);
    when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
    when(() => mockSettingsProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockSettingsProvider.googleClientId).thenReturn('');
    when(() => mockSettingsProvider.googleClientSecret).thenReturn('');
    when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
        ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Pokemon Language UI Wiring Tests (Strict TDD)', () {
    testWidgets('DexListView renders pokemon name using effectivePokemonLanguage (English)', (tester) async {
      // User has German UI, but chose English Pokemon Language
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockSettingsProvider.pokemonLanguage).thenReturn('en');
      when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('en');

      await tester.pumpWidget(createTestWidget(
        DexListView(
          liveDex: testDex,
          displayList: [bulbasaurEntry],
          provider: mockDexProvider,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must display English name 'Bulbasaur', NOT German name 'Bisasam'
      expect(find.text('Bulbasaur'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
    });

    testWidgets('DexListView renders pokemon name using effectivePokemonLanguage (Japanese)', (tester) async {
      // User has German UI, but chose Japanese Pokemon Language
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockSettingsProvider.pokemonLanguage).thenReturn('ja');
      when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('ja');

      await tester.pumpWidget(createTestWidget(
        DexListView(
          liveDex: testDex,
          displayList: [bulbasaurEntry],
          provider: mockDexProvider,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must display Japanese name 'フシギダネ', NOT German name 'Bisasam'
      expect(find.text('フシギダネ'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
    });

    testWidgets('PokemonBasicInfoWidget renders pokemon name using effectivePokemonLanguage (French)', (tester) async {
      // User has German UI, but chose French Pokemon Language
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockSettingsProvider.pokemonLanguage).thenReturn('fr');
      when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('fr');

      await tester.pumpWidget(createTestWidget(
        PokemonBasicInfoWidget(
          basicInfoKey: GlobalKey(),
          entry: bulbasaurEntry,
          currentForm: null,
          provider: mockDexProvider,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must display French name 'Bulbizarre', NOT German name 'Bisasam'
      expect(find.text('Bulbizarre'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
    });

    testWidgets('PokemonSearchTile renders pokemon name using effectivePokemonLanguage (Japanese)', (tester) async {
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockSettingsProvider.pokemonLanguage).thenReturn('ja');
      when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('ja');

      await tester.pumpWidget(createTestWidget(
        PokemonSearchTile(
          pokemon: bulbasaur,
          entry: bulbasaurEntry,
          onTap: () {},
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must display Japanese name 'フシギダネ', NOT 'Bisasam'
      expect(find.text('フシギダネ'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
    });

    testWidgets('PokemonSearchTile renders pokemon name using effectivePokemonLanguage (French)', (tester) async {
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockSettingsProvider.pokemonLanguage).thenReturn('fr');
      when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('fr');

      await tester.pumpWidget(createTestWidget(
        PokemonSearchTile(
          pokemon: bulbasaur,
          entry: bulbasaurEntry,
          onTap: () {},
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must display French name 'Bulbizarre', NOT 'Bisasam'
      expect(find.text('Bulbizarre'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
    });

    testWidgets('PokemonSearchSelectionScreen filters matching Pokemon by multi-language names', (tester) async {
      when(() => mockSettingsProvider.currentLanguage).thenReturn('fr');
      when(() => mockSettingsProvider.pokemonLanguage).thenReturn('fr');
      when(() => mockSettingsProvider.effectivePokemonLanguage).thenReturn('fr');

      await tester.pumpWidget(createTestWidget(
        PokemonSearchSelectionScreen(
          allAvailableEntries: [bulbasaurEntry],
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Enter French search query 'Bulbizarre'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'bulbizarre');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Bulbasaur tile should still be in filtered results
      expect(find.byType(PokemonSearchTile), findsOneWidget);
      expect(find.text('Bulbizarre'), findsOneWidget);

      // Enter Japanese search query 'フシギダネ'
      await tester.enterText(searchField, 'フシギダネ');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.byType(PokemonSearchTile), findsOneWidget);

      // Enter query that does not match any name
      await tester.enterText(searchField, 'nonexistentpoke');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.byType(PokemonSearchTile), findsNothing);
    });
  });
}
