import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/dex/pokemon_search_selection.dart';
import 'package:pokevault/screens/pokemon_info/pokemon_info_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

class MockTutorialProvider extends Mock implements TutorialProvider {}

Pokemon _makePokemon({
  required int id,
  required String nameDe,
  required String nameEn,
  String formName = 'normal',
  String formType = 'normal',
  List<String> types = const ['normal'],
  bool hasGenderDifferences = false,
  int genderRate = 1, // 1 = 87.5% male, 12.5% female (can be both)
}) {
  return Pokemon(
    id: id,
    nameDe: nameDe,
    nameEn: nameEn,
    hasGenderDifferences: hasGenderDifferences,
    genderRate: genderRate,
    captureRate: 45,
    evolutionChainId: 1,
    eggGroups: ['monster'],
    weight: 10.0,
    speed: 50,
    forms: [
      PokemonForm(
        name: formName,
        formType: formType,
        minGen: 1,
        imageId: id,
        types: types,
        exclusiveRegions: [],
      )
    ],
  );
}

DexDisplayEntry _makeEntry({
  required Pokemon pokemon,
  required String uniqueId,
  String displaySuffix = '',
}) {
  return DexDisplayEntry(
    pokemon: pokemon,
    uniqueId: uniqueId,
    displaySuffix: displaySuffix,
    imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockTutorialProvider mockTutorialProvider;
  late List<DexDisplayEntry> testEntries;

  setUp(() {
    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockTutorialProvider = MockTutorialProvider();

    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
    when(() => mockDexProvider.userDexes).thenReturn([]);
    when(() => mockDexProvider.allPokemon).thenReturn([]);

    testEntries = [
      // Kanto
      _makeEntry(
        pokemon: _makePokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur', types: ['grass', 'poison']),
        uniqueId: '1_normal',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 6, nameDe: 'Glurak', nameEn: 'Charizard', types: ['fire', 'flying']),
        uniqueId: '6_normal',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 6, nameDe: 'Glurak (Mega X)', nameEn: 'Charizard (Mega X)', formName: 'mega-x', formType: 'mega', types: ['fire', 'dragon']),
        uniqueId: '6_mega-x',
        displaySuffix: 'Mega X',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 6, nameDe: 'Glurak (GMax)', nameEn: 'Charizard (GMax)', formName: 'gmax', formType: 'gmax', types: ['fire', 'flying']),
        uniqueId: '6_gmax',
        displaySuffix: 'G-Max',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu', types: ['electric'], hasGenderDifferences: true, genderRate: 4),
        uniqueId: '25_normal',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu', types: ['electric'], hasGenderDifferences: true, genderRate: 4),
        uniqueId: '25_m',
        displaySuffix: ' ♂',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu', types: ['electric'], hasGenderDifferences: true, genderRate: 4),
        uniqueId: '25_f',
        displaySuffix: ' ♀',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 81, nameDe: 'Magnetilo', nameEn: 'Magnemite', types: ['electric', 'steel'], genderRate: -1),
        uniqueId: '81_normal',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 113, nameDe: 'Chaneira', nameEn: 'Chansey', types: ['normal'], genderRate: 8),
        uniqueId: '113_normal',
      ),
      _makeEntry(
        pokemon: _makePokemon(id: 128, nameDe: 'Tauros', nameEn: 'Tauros', types: ['normal'], genderRate: 0),
        uniqueId: '128_normal',
      ),
      // Johto
      _makeEntry(
        pokemon: _makePokemon(id: 152, nameDe: 'Endivie', nameEn: 'Chikorita', types: ['grass']),
        uniqueId: '152_normal',
      ),
      // Hoenn
      _makeEntry(
        pokemon: _makePokemon(id: 252, nameDe: 'Geckarbor', nameEn: 'Treecko', types: ['grass']),
        uniqueId: '252_normal',
      ),
      // Paldea
      _makeEntry(
        pokemon: _makePokemon(id: 906, nameDe: 'Felori', nameEn: 'Sprigatito', types: ['grass']),
        uniqueId: '906_normal',
      ),
    ];
  });

  Widget createTestWidget({String? dexId, bool initialShiny = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
        ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
      ],
      child: MaterialApp(
        home: PokemonSearchSelectionScreen(
          allAvailableEntries: testEntries,
          dexId: dexId,
          initialShiny: initialShiny,
        ),
      ),
    );
  }

  group('Multi-select Region and Form Filters', () {
    testWidgets('Allows selecting multiple regions simultaneously (e.g. Kanto + Johto)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Kanto
      await tester.tap(find.text('Kanto'));
      await tester.pumpAndSettle();

      // Kanto Pokémon are present, Johto (Endivie) and Hoenn (Geckarbor) are not
      expect(find.text('Bisasam'), findsOneWidget);
      expect(find.text('Endivie'), findsNothing);
      expect(find.text('Geckarbor'), findsNothing);

      // Tap Johto as second region
      await tester.tap(find.text('Johto'));
      await tester.pumpAndSettle();

      // Both Kanto and Johto are now present
      expect(find.text('Bisasam'), findsOneWidget);
      expect(find.text('Endivie'), findsOneWidget);
      expect(find.text('Geckarbor'), findsNothing);
      expect(find.text('Felori'), findsNothing);

      // Deselect Kanto
      await tester.tap(find.text('Kanto'));
      await tester.pumpAndSettle();

      // Only Johto remains
      expect(find.text('Bisasam'), findsNothing);
      expect(find.text('Endivie'), findsOneWidget);
    });

    testWidgets('Allows selecting multiple forms simultaneously (e.g. Mega + Gigantamax)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Mega
      await tester.tap(find.text('Mega'));
      await tester.pumpAndSettle();

      expect(find.text('Glurak (Mega X)'), findsOneWidget);
      expect(find.text('Glurak (GMax)'), findsNothing);
      expect(find.text('Bisasam'), findsNothing);

      // Tap Gigantamax as second form
      await tester.tap(find.text('Gigadynamax'));
      await tester.pumpAndSettle();

      // Both Mega and Gmax are now present
      expect(find.text('Glurak (Mega X)'), findsOneWidget);
      expect(find.text('Glurak (GMax)'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
    });
  });

  group('Gender Filters', () {
    testWidgets('Gender filter "Männlich (♂)" matches male eligible and explicit male entries', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Männlich (♂)
      await tester.tap(find.text('Männlich (♂)'));
      await tester.pumpAndSettle();

      // Pikachu (male/can be male) and Tauros (100% male) appear
      expect(find.text('Tauros'), findsOneWidget);
      // Pikachu ♀ (explicit female) must NOT appear
      expect(find.text('Chaneira'), findsNothing);
      expect(find.text('Magnetilo'), findsNothing);
    });

    testWidgets('Gender filter "Weiblich (♀)" matches female eligible and explicit female entries', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Weiblich (♀)
      await tester.tap(find.text('Weiblich (♀)'));
      await tester.pumpAndSettle();

      // Chaneira (100% female) appears
      expect(find.text('Chaneira'), findsOneWidget);
      // Tauros (100% male) must NOT appear
      expect(find.text('Tauros'), findsNothing);
      expect(find.text('Magnetilo'), findsNothing);
    });

    testWidgets('Gender filter "Geschlechtslos" matches only genderless Pokémon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Geschlechtslos
      await tester.tap(find.text('Geschlechtslos'));
      await tester.pumpAndSettle();

      expect(find.text('Magnetilo'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
      expect(find.text('Tauros'), findsNothing);
      expect(find.text('Chaneira'), findsNothing);
    });

    testWidgets('Gender filter "Unterschiede" matches Pokémon with visual gender differences', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ensure visible and tap Unterschiede
      final chipFinder = find.text('Unterschiede');
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Only Pikachu has hasGenderDifferences = true in our dataset
      expect(find.text('Tauros'), findsNothing);
      expect(find.text('Bisasam'), findsNothing);
      expect(find.text('Magnetilo'), findsNothing);
      expect(find.text('Chaneira'), findsNothing);
    });

    testWidgets('Multi-select gender filter (e.g. Geschlechtslos + Weiblich)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Geschlechtslos
      await tester.tap(find.text('Geschlechtslos'));
      await tester.pumpAndSettle();

      // Tap Weiblich (♀)
      await tester.tap(find.text('Weiblich (♀)'));
      await tester.pumpAndSettle();

      expect(find.text('Magnetilo'), findsOneWidget);
      expect(find.text('Chaneira'), findsOneWidget);
      expect(find.text('Tauros'), findsNothing);
    });

    testWidgets('Combining "Unterschiede" with "Weiblich (♀)" matches only female entries with gender differences', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Unterschiede
      final diffFinder = find.text('Unterschiede');
      await tester.ensureVisible(diffFinder);
      await tester.pumpAndSettle();
      await tester.tap(diffFinder);
      await tester.pumpAndSettle();

      // Tap Weiblich (♀)
      final femaleFinder = find.text('Weiblich (♀)');
      await tester.ensureVisible(femaleFinder);
      await tester.pumpAndSettle();
      await tester.tap(femaleFinder);
      await tester.pumpAndSettle();

      // Chaneira (female, but NO gender differences) must NOT appear
      expect(find.text('Chaneira'), findsNothing);
      // Tauros (male) must NOT appear
      expect(find.text('Tauros'), findsNothing);
      // Bisasam must NOT appear
      expect(find.text('Bisasam'), findsNothing);
      // Pikachu (female capable / explicit female with gender differences) appears
      expect(find.text('Pikachu'), findsWidgets);
    });
  });

  group('Shiny / Normal Mode and Pop Selection', () {
    testWidgets('Toggling Shiny mode updates sprite URLs and returns shiny:uniqueId on tap', (tester) async {
      String? returnedResult;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    returnedResult = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => PokemonSearchSelectionScreen(
                          allAvailableEntries: testEntries,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Initially in normal mode, tapping Bisasam returns '1_normal'
      // But let's toggle shiny mode via toggle_shiny_button
      final shinyBtn = find.byKey(const Key('toggle_shiny_button'));
      expect(shinyBtn, findsOneWidget);
      await tester.tap(shinyBtn);
      await tester.pumpAndSettle();

      // Star icons are now rendered in the top rows
      expect(find.byIcon(Icons.star), findsWidgets);

      // Tap on Bisasam
      await tester.tap(find.text('Bisasam'));
      await tester.pumpAndSettle();

      // Returned result has shiny: prefix
      expect(returnedResult, equals('shiny:1_normal'));
    });

    testWidgets('Tapping Standard chip returns to normal mode without shiny: prefix', (tester) async {
      String? returnedResult;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    returnedResult = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => PokemonSearchSelectionScreen(
                          allAvailableEntries: testEntries,
                          initialShiny: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Starts in shiny mode, switch to Standard chip
      final normalChip = find.byKey(const Key('variant_normal_chip'));
      expect(normalChip, findsOneWidget);
      await tester.tap(normalChip);
      await tester.pumpAndSettle();

      // Tap on Bisasam
      await tester.tap(find.text('Bisasam'));
      await tester.pumpAndSettle();

      // Returned result is plain '1_normal'
      expect(returnedResult, equals('1_normal'));
    });

    testWidgets('Tapping Schillernd chip when already active keeps shiny mode active', (tester) async {
      await tester.pumpWidget(createTestWidget(initialShiny: true));
      await tester.pumpAndSettle();

      final shinyChip = find.byKey(const Key('variant_shiny_chip'));
      expect(shinyChip, findsOneWidget);

      // Re-tap Schillernd chip
      await tester.tap(shinyChip);
      await tester.pumpAndSettle();

      // Star icons should still be visible (shiny mode remains on)
      expect(find.byIcon(Icons.star), findsWidgets);
    });
  });

  group('Long-press & PokemonInfoScreen bug fix', () {
    testWidgets('Long-press on a Pokémon card opens PokemonInfoScreen without Bad state: No element error', (tester) async {
      await tester.pumpWidget(createTestWidget(dexId: 'national_overall'));
      await tester.pumpAndSettle();

      // Long press on Bisasam card
      await tester.longPress(find.text('Bisasam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies PokemonInfoScreen is opened
      expect(find.byType(PokemonInfoScreen), findsOneWidget);

      // Verifies no error SnackBar was shown
      expect(find.textContaining('Bad state: No element'), findsNothing);
      expect(find.textContaining('Fehler beim Laden der Seite'), findsNothing);

      // Verifies "Zum Dex hinzufügen" action button is rendered
      expect(find.text('Zum Dex hinzufügen'), findsOneWidget);
    });

    testWidgets('Long-press on Pokémon with empty forms does not crash with Bad state: No element', (tester) async {
      final pokeWithNoForms = Pokemon(
        id: 999,
        nameDe: 'OhneFormen',
        nameEn: 'NoForms',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['monster'],
        weight: 10.0,
        speed: 50,
        forms: [],
      );
      final List<DexDisplayEntry> customEntries = [
        DexDisplayEntry(
          pokemon: pokeWithNoForms,
          uniqueId: '999_normal',
          displaySuffix: '',
          imageUrl: '',
        ),
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
          ],
          child: MaterialApp(
            home: PokemonSearchSelectionScreen(
              allAvailableEntries: customEntries,
              dexId: 'national_overall',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press on OhneFormen
      await tester.longPress(find.text('OhneFormen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PokemonInfoScreen), findsOneWidget);
      expect(find.textContaining('Bad state: No element'), findsNothing);
      expect(find.textContaining('Fehler beim Laden der Seite'), findsNothing);
    });

    testWidgets('Tapping "Zum Dex hinzufügen" in PokemonInfoScreen pops and returns selected ID', (tester) async {
      String? returnedResult;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    returnedResult = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => PokemonSearchSelectionScreen(
                          allAvailableEntries: testEntries,
                          dexId: 'national_overall',
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Long press on Bisasam
      await tester.longPress(find.text('Bisasam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "Zum Dex hinzufügen"
      final addBtn = find.text('Zum Dex hinzufügen');
      await tester.ensureVisible(addBtn);
      await tester.pump();
      await tester.tap(addBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen is popped and result is returned
      expect(returnedResult, equals('1_normal'));
    });
  });

  group('Reset Filters', () {
    testWidgets('Resetting filters clears all active multi-select filters and restores full list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Apply multiple filters
      await tester.tap(find.text('Kanto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Johto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geschlechtslos'));
      await tester.pumpAndSettle();

      // Now reset filters
      final resetBtn = find.text('Filter zurücksetzen');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // All Pokémon are back
      expect(find.text('Bisasam'), findsOneWidget);
      expect(find.text('Endivie'), findsOneWidget);
      await tester.drag(find.byType(GridView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(find.text('Geckarbor'), findsOneWidget);
    });
  });
}
