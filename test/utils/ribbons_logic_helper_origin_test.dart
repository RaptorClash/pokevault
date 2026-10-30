import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/ribbon.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import 'package:pokevault/utils/ribbons_logic_helper.dart';

void main() {
  group('RibbonLogicHelper Origin Generation Filtering Tests (TDD)', () {
    late Pokemon poliwhirl;
    late List<Ribbon> allRibbons;

    setUp(() {
      poliwhirl = Pokemon(
        id: 61,
        nameDe: 'Quaputzi',
        nameEn: 'Poliwhirl',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 120,
        evolutionChainId: 26,
        eggGroups: ['water1'],
        weight: 20.0,
        speed: 90,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 61,
            types: ['water'],
            exclusiveRegions: [],
          ),
        ],
      );

      allRibbons = [
        Ribbon(
          id: 'champion-ribbon-hoenn',
          nameEn: 'Champion Ribbon',
          nameDe: 'Band des Champs (Hoenn)',
          descEn: 'Ribbon awarded for clearing the Pokémon League.',
          descDe: 'Band für den Sieg über den Champ in Hoenn.',
          titleDe: '',
          locationDe: '',
          imageUrl: '',
          isMark: 0,
          minGen: 3,
          availableGames: ['ruby', 'sapphire', 'emerald'],
        ),
        Ribbon(
          id: 'sinnoh-champ-ribbon',
          nameEn: 'Sinnoh Champ Ribbon',
          nameDe: 'Band des Champs (Sinnoh)',
          descEn: 'Ribbon awarded for beating the Sinnoh League.',
          descDe: 'Band für den Champ von Sinnoh.',
          titleDe: '',
          locationDe: '',
          imageUrl: '',
          isMark: 0,
          minGen: 4,
          availableGames: ['diamond', 'pearl', 'platinum'],
        ),
        Ribbon(
          id: 'kalos-champ-ribbon',
          nameEn: 'Kalos Champ Ribbon',
          nameDe: 'Band des Champs (Kalos)',
          descEn: 'Ribbon awarded for beating the Kalos League.',
          descDe: 'Band für den Champ von Kalos.',
          titleDe: '',
          locationDe: '',
          imageUrl: '',
          isMark: 0,
          minGen: 6,
          availableGames: ['x', 'y'],
        ),
        Ribbon(
          id: 'alola-champion-ribbon',
          nameEn: 'Alola Champion Ribbon',
          nameDe: 'Alola-Champ-Band',
          descEn: 'A Ribbon awarded for defeating the Pokémon League in Alola.',
          descDe: 'Band für den Sieg über die Alola-Pokémon-Liga.',
          titleDe: '',
          locationDe: '',
          imageUrl: '',
          isMark: 0,
          minGen: 7,
          availableGames: ['sun', 'moon', 'usun', 'umoon'],
        ),
        Ribbon(
          id: 'battle-tree-master-ribbon',
          nameEn: 'Battle Tree Master Ribbon',
          nameDe: 'Kampfbaum-Meisterband',
          descEn: 'A Ribbon awarded for defeating the Battle Tree Master.',
          descDe: 'Band für den Sieg über eine Koryphäe am Kampfbaum.',
          titleDe: '',
          locationDe: '',
          imageUrl: '',
          isMark: 0,
          minGen: 7,
          availableGames: ['sun', 'moon', 'usun', 'umoon'],
        ),
        Ribbon(
          id: 'effort-ribbon',
          nameEn: 'Effort Ribbon',
          nameDe: 'Fleiß-Band',
          descEn: 'Ribbon awarded for being an exceptionally hard worker.',
          descDe: 'Band für außergewöhnlichen Fleiß.',
          titleDe: '',
          locationDe: '',
          imageUrl: '',
          isMark: 0,
          minGen: 3,
          availableGames: [
            'ruby', 'sapphire', 'emerald', 'diamond', 'pearl', 'platinum',
            'heartgold', 'soulsilver', 'x', 'y', 'or', 'as',
            'sun', 'moon', 'usun', 'umoon', 'sw', 'sh', 'bd', 'sp', 'scar', 'vio'
          ],
        ),
      ];
    });

    test('DexLogicHelper.getOriginGeneration identifies origin gen from uniqueId', () {
      expect(
        DexLogicHelper.getOriginGeneration('61_special_128_trade_alola_normal'),
        7.0,
      );
      expect(
        DexLogicHelper.getOriginGeneration('133_special_50_gift_kanto_normal'),
        1.0,
      );
      expect(
        DexLogicHelper.getOriginGeneration('25_normal'),
        null,
      );
    });

    test('getValidRibbonsForPokemon excludes pre-Gen 7 ribbons when originGen is 7.0', () {
      final allAvailablePokeApiGames = [
        'ruby-sapphire',
        'emerald',
        'diamond-pearl',
        'platinum',
        'x-y',
        'sun-moon',
        'ultra-sun-ultra-moon',
        'sword-shield',
      ];

      // Without originGen: Hoenn, Sinnoh, Kalos Champion ribbons are included
      final unconstrained = RibbonLogicHelper.getValidRibbonsForPokemon(
        poliwhirl,
        61,
        allRibbons,
        allAvailablePokeApiGames,
      );
      expect(unconstrained.any((r) => r.id == 'champion-ribbon-hoenn'), isTrue);
      expect(unconstrained.any((r) => r.id == 'sinnoh-champ-ribbon'), isTrue);
      expect(unconstrained.any((r) => r.id == 'kalos-champ-ribbon'), isTrue);
      expect(unconstrained.any((r) => r.id == 'alola-champion-ribbon'), isTrue);
      expect(unconstrained.any((r) => r.id == 'effort-ribbon'), isTrue);

      // With originGen: 7.0 -> Hoenn, Sinnoh, Kalos Champion ribbons are strictly excluded!
      final gen7OriginRibbons = RibbonLogicHelper.getValidRibbonsForPokemon(
        poliwhirl,
        61,
        allRibbons,
        allAvailablePokeApiGames,
        originGen: 7,
      );

      expect(gen7OriginRibbons.any((r) => r.id == 'champion-ribbon-hoenn'), isFalse);
      expect(gen7OriginRibbons.any((r) => r.id == 'sinnoh-champ-ribbon'), isFalse);
      expect(gen7OriginRibbons.any((r) => r.id == 'kalos-champ-ribbon'), isFalse);

      // Gen 7+ ribbons and cross-gen ribbons available in Gen 7+ must remain:
      expect(gen7OriginRibbons.any((r) => r.id == 'alola-champion-ribbon'), isTrue);
      expect(gen7OriginRibbons.any((r) => r.id == 'battle-tree-master-ribbon'), isTrue);
      expect(gen7OriginRibbons.any((r) => r.id == 'effort-ribbon'), isTrue);
    });
  });
}
