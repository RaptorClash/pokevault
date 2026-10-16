import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

void main() {
  test('Test custom_empty dex generation', () {
    UserDex dex = UserDex(
      id: 'test',
      title: 'test',
      region: 'custom_empty',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: [],
      shinyIds: [],
      ignoredIds: [],
      customBoxes: []
    );

    List<Pokemon> pokemonList = [
      Pokemon(
        id: 1,
        nameDe: 'Bisasam',
        nameEn: 'Bulbasaur',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['monster', 'plant'],
        weight: 69.0,
        speed: 45,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 1,
            types: ['grass', 'poison'],
            exclusiveRegions: [],
          )
        ]
      )
    ];

    var entries = DexLogicHelper.buildDisplayEntries(dex, pokemonList, []);
    print('Entries length: ${entries.length}');
  });
}
