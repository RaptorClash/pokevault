import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/utils/shiny_logic_helper.dart';

void main() {
  group('ShinyLogicHelper Tests', () {
    test('isHuntableInGen1 erkennt korrekte Pokémon', () {
      expect(ShinyLogicHelper.isHuntableInGen1(1), isTrue);
      expect(ShinyLogicHelper.isHuntableInGen1(150), isTrue);
      expect(ShinyLogicHelper.isHuntableInGen1(151), isFalse);
    });

    test('getSoftResetCombo gibt richtige Tastenkombinationen zurück', () {
      expect(
        ShinyLogicHelper.getSoftResetCombo('gen_1'),
        'A + B + Start + Select',
      );
      expect(
        ShinyLogicHelper.getSoftResetCombo('gen_7'),
        'L + R + Start + Select',
      );
      expect(ShinyLogicHelper.getSoftResetCombo('gen_9'), 'HOME -> X -> A');
      expect(ShinyLogicHelper.getSoftResetCombo('gen_unbekannt'), '');
    });

    test('isBreedable prüft Egg-Groups korrekt', () {
      final breedablePokemon = Pokemon(
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

      final legendPokemon = Pokemon(
        id: 144,
        nameDe: 'Arktos',
        nameEn: 'Articuno',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 3,
        evolutionChainId: 1,
        eggGroups: ['No Eggs Discovered'],
        weight: 55.4,
        speed: 85,
        forms: [],
      );

      final ditto = Pokemon(
        id: 132,
        nameDe: 'Ditto',
        nameEn: 'Ditto',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 35,
        evolutionChainId: 1,
        eggGroups: ['Ditto'],
        weight: 4.0,
        speed: 48,
        forms: [],
      );

      expect(ShinyLogicHelper.isBreedable(breedablePokemon), isTrue);
      expect(ShinyLogicHelper.isBreedable(legendPokemon), isFalse);
      expect(ShinyLogicHelper.isBreedable(ditto), isFalse);
    });

    test('isBaby erkennt Baby-Pokémon', () {
      expect(ShinyLogicHelper.isBaby(172), isTrue);
      expect(ShinyLogicHelper.isBaby(25), isFalse);
    });

    test('getAdultForBaby gibt korrekte Weiterentwicklung zurück', () {
      expect(ShinyLogicHelper.getAdultForBaby(172), 25);
      expect(ShinyLogicHelper.getAdultForBaby(175), 176);
      expect(ShinyLogicHelper.getAdultForBaby(25), 25);
    });

    test('getBaseForm navigiert den Stammbaum nach unten', () {
      expect(ShinyLogicHelper.getBaseForm(26), 172);
      expect(ShinyLogicHelper.getBaseForm(3), 1);
      expect(ShinyLogicHelper.getBaseForm(150), 150);
    });

    test('getEvolutionPath baut den korrekten Evolutions-Weg', () {
      final path = ShinyLogicHelper.getEvolutionPath(172, 26);

      expect(path.length, 2);

      expect(path[0]['from'], 172);
      expect(path[0]['to'], 25);
      expect(path[0]['req'], 'Friendship');

      expect(path[1]['from'], 25);
      expect(path[1]['to'], 26);
      expect(path[1]['req'], 'Thunder Stone');
    });

    test('getDefaultLevel gibt korrektes Level zurück', () {
      expect(ShinyLogicHelper.getDefaultLevel(1), 5);
      expect(ShinyLogicHelper.getDefaultLevel(150), 70);
      expect(ShinyLogicHelper.getDefaultLevel(999), 15);
    });
  });
}
