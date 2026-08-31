import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';

void main() {
  group('Pokemon Model Tests', () {
    test('getName gibt die korrekte Sprache zurück', () {
      final testPokemon = Pokemon(
        id: 1,
        nameDe: 'Bisasam',
        nameEn: 'Bulbasaur',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['Monster', 'Grass'],
        weight: 6.9,
        speed: 45,
        forms: [],
      );

      expect(testPokemon.getName('de'), equals('Bisasam'));
      expect(testPokemon.getName('en'), equals('Bulbasaur'));

      expect(testPokemon.getName('fr'), equals('Bulbasaur'));
    });

    test('Pokemon-Instanz verarbeitet Formen korrekt', () {
      final form = PokemonForm(
        name: 'alola',
        formType: 'regional',
        minGen: 7,
        imageId: 10101,
        types: ['ice', 'steel'],
        exclusiveRegions: ['alola_regional'],
      );

      final vulpix = Pokemon(
        id: 37,
        nameDe: 'Vulpix',
        nameEn: 'Vulpix',
        hasGenderDifferences: false,
        genderRate: 6,
        captureRate: 190,
        evolutionChainId: 15,
        eggGroups: ['Field'],
        weight: 9.9,
        speed: 65,
        forms: [form],
      );

      expect(vulpix.forms.length, equals(1));
      expect(vulpix.forms.first.name, equals('alola'));
      expect(vulpix.forms.first.types.contains('ice'), isTrue);
    });
  });
}
