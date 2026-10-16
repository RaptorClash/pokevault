import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/utils/shiny_logic_helper.dart';

void main() {
  group('ShinyLogicHelper Tests', () {
    const preEvolutions = <int, Map<String, dynamic>>{
      26: {'pre': 25, 'req': 'Thunder Stone'},
      25: {'pre': 172, 'req': 'Friendship'},
      3: {'pre': 2, 'req': 'Level 32'},
      2: {'pre': 1, 'req': 'Level 16'},
    };

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
      expect(ShinyLogicHelper.getBaseForm(26, preEvolutions), 172);
      expect(ShinyLogicHelper.getBaseForm(3, preEvolutions), 1);
      expect(ShinyLogicHelper.getBaseForm(150, preEvolutions), 150);
    });

    test('getEvolutionPath baut den korrekten Evolutions-Weg', () {
      final path = ShinyLogicHelper.getEvolutionPath(172, 26, preEvolutions);

      expect(path.length, 2);

      expect(path[0]['from'], 172);
      expect(path[0]['to'], 25);
      expect(path[0]['req'], 'Friendship');

      expect(path[1]['from'], 25);
      expect(path[1]['to'], 26);
      expect(path[1]['req'], 'Thunder Stone');
    });
  });
}
