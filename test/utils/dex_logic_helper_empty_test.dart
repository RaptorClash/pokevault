import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import '../e2e/helpers/e2e_test_helper.dart';

void main() {
  test('Test custom_empty dex generation with buildDisplayEntries', () {
    final dex = createTestUserDex(
      id: 'test_empty',
      title: 'Empty Dex',
      region: 'custom_empty',
    );

    final pokemonList = [
      createTestPokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur'),
    ];

    final entries = DexLogicHelper.buildDisplayEntries(dex, pokemonList, []);
    expect(entries.length, equals(1));
    expect(entries.first.pokemon.id, equals(1));
    expect(entries.first.uniqueId, equals('1_normal'));
    expect(entries.first.pokemon.nameEn, equals('Bulbasaur'));
  });

  test('Test custom_empty dex custom boxes generation from entries', () {
    final dex = createTestUserDex(
      id: 'test_custom',
      title: 'Custom Boxes Dex',
      region: 'custom_empty',
    );

    final poke = createTestPokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur');
    final List<DexDisplayEntry> entries = [
      createTestEntry(pokemon: poke, uniqueId: '1_normal'),
    ];

    final boxes = DexLogicHelper.initializeCustomBoxesFromEntries(dex, entries);
    expect(boxes.length, equals(1));
    expect(boxes.first.pokemonIds.length, equals(1));
    expect(boxes.first.pokemonIds.first.startsWith('1_normal__'), isTrue);
  });

  test('Test custom_empty dex produces empty entries and empty boxes when input is empty', () {
    final dex = createTestUserDex(
      id: 'test_truly_empty',
      title: 'Truly Empty Dex',
      region: 'custom_empty',
    );

    final entries = DexLogicHelper.buildDisplayEntries(dex, [], []);
    expect(entries, isEmpty);

    final boxes = DexLogicHelper.initializeCustomBoxesFromEntries(dex, []);
    expect(boxes, isEmpty);
  });
}
