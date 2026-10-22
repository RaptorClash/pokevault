import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/dex/pokemon_search_selection.dart';
import 'package:mocktail/mocktail.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  Pokemon createTestPokemon(int id, String name) {
    return Pokemon(
      id: id,
      nameDe: name,
      nameEn: name,
      hasGenderDifferences: false,
      genderRate: 4,
      captureRate: 45,
      evolutionChainId: 1,
      eggGroups: ['Monster'],
      weight: 10.0,
      speed: 50,
      forms: [],
    );
  }

  DexDisplayEntry createEntry(int id, String name) {
    return DexDisplayEntry(
      uniqueId: '$id',
      pokemon: createTestPokemon(id, name),
      displaySuffix: '',
      imageUrl: 'https://example.com/$id.png',
    );
  }

  final testEntries = [
    createEntry(1, 'Bisasam'),
    createEntry(4, 'Glumanda'),
    createEntry(7, 'Schiggy'),
  ];

  late MockDexProvider mockProvider;

  setUp(() {
    mockProvider = MockDexProvider();
    when(() => mockProvider.userDexes).thenReturn([
      UserDex(
        id: 'kanto',
        title: 'Kanto',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      ),
    ]);
  });

  Widget buildScreen({
    bool allowNone = false,
    bool showPlaceholder = true,
  }) {
    return ChangeNotifierProvider<DexProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        home: PokemonSearchSelectionScreen(
          allAvailableEntries: testEntries,
          allowNone: allowNone,
          showPlaceholder: showPlaceholder,
        ),
      ),
    );
  }

  group('PokemonSearchSelectionScreen allowNone and showPlaceholder Tests', () {
    testWidgets('when allowNone is true, renders "Kein Pokémon" AppBar button and pops "none" on tap', (tester) async {
      String? poppedResult;

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  poppedResult = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => PokemonSearchSelectionScreen(
                        allAvailableEntries: testEntries,
                        allowNone: true,
                        showPlaceholder: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('select_none_pokemon_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('select_none_pokemon_button')));
      await tester.pumpAndSettle();

      expect(poppedResult, 'none');
    });

    testWidgets('when showPlaceholder is false, does NOT render placeholder button or card', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          allowNone: true,
          showPlaceholder: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('insert_placeholder_button')), findsNothing);
      expect(find.byKey(const Key('pokemon_search_placeholder_card')), findsNothing);
    });

    testWidgets('when allowNone is true, renders "Kein Pokémon" card in grid and pops "none"', (tester) async {
      String? poppedResult;

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  poppedResult = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => PokemonSearchSelectionScreen(
                        allAvailableEntries: testEntries,
                        allowNone: true,
                        showPlaceholder: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pokemon_search_none_card')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pokemon_search_none_card')));
      await tester.pumpAndSettle();

      expect(poppedResult, 'none');
    });
  });
}
