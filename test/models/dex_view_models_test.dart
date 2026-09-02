import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/dex_view_models.dart';

void main() {
  final dummyPokemon = Pokemon(
    id: 1,
    nameDe: 'Bisasam',
    nameEn: 'Bulbasaur',
    hasGenderDifferences: false,
    genderRate: -1,
    captureRate: 45,
    evolutionChainId: 1,
    eggGroups: [],
    weight: 6.9,
    speed: 45,
    forms: [],
  );

  group('DexDisplayEntry Tests', () {
    test('Klasse instanziiert korrekt und speichert alle Parameter', () {
      final entry = DexDisplayEntry(
        pokemon: dummyPokemon,
        uniqueId: 'bulbasaur_normal',
        displaySuffix: '',
        imageUrl: 'assets/pokemon/1.png',
      );

      expect(entry.pokemon, dummyPokemon);
      expect(entry.uniqueId, 'bulbasaur_normal');
      expect(entry.displaySuffix, '');
      expect(entry.imageUrl, 'assets/pokemon/1.png');
    });
  });

  group('BoxData Tests', () {
    test('Klasse instanziiert korrekt und speichert alle Parameter', () {
      final entry = DexDisplayEntry(
        pokemon: dummyPokemon,
        uniqueId: 'bulbasaur_normal',
        displaySuffix: '',
        imageUrl: 'assets/pokemon/1.png',
      );

      final boxData = BoxData('Kanto Box 1', 'kanto', [entry], 3);

      expect(boxData.title, 'Kanto Box 1');
      expect(boxData.regionKey, 'kanto');
      expect(boxData.entries.length, 1);
      expect(boxData.entries.first.uniqueId, 'bulbasaur_normal');
      expect(boxData.crossAxisCount, 3);
    });
  });
}
