import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/screens/dex/widgets/search/pokemon_search_tile.dart';

void main() {
  Pokemon createDummyPokemon({int id = 25, String name = 'Pikachu'}) {
    return Pokemon(
      id: id,
      nameDe: name,
      nameEn: name,
      hasGenderDifferences: false,
      genderRate: 4,
      captureRate: 190,
      evolutionChainId: 10,
      eggGroups: ['field', 'fairy'],
      weight: 6.0,
      speed: 90,
      forms: [
        PokemonForm(
          name: 'default',
          formType: 'default',
          minGen: 1,
          imageId: id,
          types: ['electric'],
          exclusiveRegions: [],
        ),
      ],
    );
  }

  DexDisplayEntry createDummyEntry(Pokemon pokemon) {
    return DexDisplayEntry(
      pokemon: pokemon,
      uniqueId: '${pokemon.id}',
      displaySuffix: '',
      imageUrl: 'https://example.com/sprite.png',
    );
  }

  Widget buildTestWidget({
    required Pokemon pokemon,
    required DexDisplayEntry entry,
    bool isShiny = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 150,
            height: 180,
            child: PokemonSearchTile(
              pokemon: pokemon,
              entry: entry,
              isShiny: isShiny,
              onTap: onTap ?? () {},
              onLongPress: onLongPress ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('PokemonSearchTile TDD Tests', () {
    testWidgets('Renders Pokémon name, formatted ID, and handles tap', (tester) async {
      final poke = createDummyPokemon(id: 25, name: 'Pikachu');
      final entry = createDummyEntry(poke);
      bool tapped = false;

      await tester.pumpWidget(buildTestWidget(
        pokemon: poke,
        entry: entry,
        onTap: () => tapped = true,
      ));

      expect(find.text('Pikachu'), findsOneWidget);
      expect(find.text('#025'), findsOneWidget);

      await tester.tap(find.text('Pikachu'));
      expect(tapped, isTrue);
    });

    testWidgets('Renders shiny star indicator when isShiny is true', (tester) async {
      final poke = createDummyPokemon(id: 133, name: 'Evoli');
      final entry = createDummyEntry(poke);

      await tester.pumpWidget(buildTestWidget(
        pokemon: poke,
        entry: entry,
        isShiny: true,
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Long press gesture triggers onLongPress callback', (tester) async {
      final poke = createDummyPokemon(id: 1, name: 'Bisasam');
      final entry = createDummyEntry(poke);
      bool longPressed = false;

      await tester.pumpWidget(buildTestWidget(
        pokemon: poke,
        entry: entry,
        onLongPress: () => longPressed = true,
      ));

      await tester.longPress(find.text('Bisasam'));
      expect(longPressed, isTrue);
    });
  });
}
