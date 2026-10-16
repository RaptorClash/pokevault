import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/ribbon.dart';
import 'package:pokevault/utils/ribbons_logic_helper.dart';

Ribbon _createRibbon({
  required String id,
  int isMark = 0,
  List<String> availableGames = const [],
}) {
  return Ribbon(
    id: id,
    nameEn: id,
    nameDe: id,
    descEn: 'Desc $id',
    descDe: 'Desc $id',
    titleDe: 'Title $id',
    locationDe: 'Loc $id',
    imageUrl: 'https://example.com/$id.png',
    isMark: isMark,
    minGen: 3,
    availableGames: availableGames,
  );
}

Pokemon _createPoke({required int id, String name = 'Pikachu'}) {
  return Pokemon(
    id: id,
    nameDe: name,
    nameEn: name,
    hasGenderDifferences: false,
    genderRate: 4,
    captureRate: 45,
    evolutionChainId: 1,
    eggGroups: ['field'],
    weight: 6.0,
    speed: 90,
    forms: [],
  );
}

void main() {
  group('RibbonLogicHelper Tests', () {
    test('mapPokeApiToRibbonGames maps all recognized game groups correctly', () {
      final input = [
        'sword-shield',
        'brilliant-diamond-and-shining-pearl',
        'legends-arceus',
        'scarlet-violet',
        'sun-moon',
        'ultra-sun-ultra-moon',
        'x-y',
        'omega-ruby-alpha-sapphire',
        'diamond-pearl',
        'platinum',
        'heartgold-soulsilver',
        'ruby-sapphire',
        'emerald',
        'firered-leafgreen',
        'colosseum',
        'xd',
        'unknown-game-group',
      ];

      final mapped = RibbonLogicHelper.mapPokeApiToRibbonGames(input);

      expect(mapped, containsAll([
        'sw', 'sh',
        'bd', 'sp',
        'pla',
        'scar', 'vio',
        'sun', 'moon',
        'usun', 'umoon',
        'x', 'y',
        'or', 'as',
        'diamond', 'pearl',
        'platinum',
        'heartgold', 'soulsilver',
        'ruby', 'sapphire',
        'emerald',
        'firered', 'leafgreen',
        'colosseum',
        'xd',
      ]));
      expect(mapped.contains('unknown-game-group'), isFalse);
    });

    test('getValidRibbonsForPokemon filters Alpha mark correctly (only in PLA)', () {
      final alphaMark = _createRibbon(id: 'alpha-mark', isMark: 1);
      final poke = _createPoke(id: 25);

      // In SwSh only -> should not have alpha mark
      final resultSwSh = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [alphaMark],
        ['sword-shield'],
      );
      expect(resultSwSh, isEmpty);

      // In Legends Arceus -> should have alpha mark
      final resultPLA = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [alphaMark],
        ['legends-arceus'],
      );
      expect(resultPLA, contains(alphaMark));
    });

    test('getValidRibbonsForPokemon filters Curry mark correctly (only in SwSh)', () {
      final curryMark = _createRibbon(id: 'curry-mark', isMark: 1);
      final poke = _createPoke(id: 25);

      // In SV only -> false
      final resultSV = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [curryMark],
        ['scarlet-violet'],
      );
      expect(resultSV, isEmpty);

      // In SwSh -> true
      final resultSwSh = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [curryMark],
        ['sword-shield'],
      );
      expect(resultSwSh, contains(curryMark));
    });

    test('getValidRibbonsForPokemon filters SV-exclusive marks correctly', () {
      final marks = [
        _createRibbon(id: 'itemfinder-mark', isMark: 1),
        _createRibbon(id: 'partner-mark', isMark: 1),
        _createRibbon(id: 'gourmand-mark', isMark: 1),
        _createRibbon(id: 'titan-mark', isMark: 1),
        _createRibbon(id: 'mightiest-mark', isMark: 1),
      ];
      final poke = _createPoke(id: 25);

      final resultSwSh = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        marks,
        ['sword-shield'],
      );
      expect(resultSwSh, isEmpty);

      final resultSV = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        marks,
        ['scarlet-violet'],
      );
      expect(resultSV, hasLength(5));
    });

    test('getValidRibbonsForPokemon restricts marks on mythical Pokémon to party marks', () {
      final mew = _createPoke(id: 151, name: 'Mew'); // 151 is in _mythicalIds
      final lunchMark = _createRibbon(id: 'lunchtime-mark', isMark: 1);
      final destinyMark = _createRibbon(id: 'destiny-mark', isMark: 1); // in _partyMarks
      final curryMark = _createRibbon(id: 'curry-mark', isMark: 1); // in _partyMarks

      final results = RibbonLogicHelper.getValidRibbonsForPokemon(
        mew,
        151,
        [lunchMark, destinyMark, curryMark],
        ['sword-shield'],
      );

      // lunchtime-mark is NOT a party mark, so excluded for Mythical
      expect(results.contains(lunchMark), isFalse);
      // destiny-mark and curry-mark ARE party marks
      expect(results.contains(destinyMark), isTrue);
      expect(results.contains(curryMark), isTrue);
    });

    test('getValidRibbonsForPokemon filters standard ribbons by availableGames', () {
      final sinnohChampRibbon = _createRibbon(
        id: 'sinnoh-champ-ribbon',
        isMark: 0,
        availableGames: ['diamond', 'pearl', 'platinum', 'bd', 'sp'],
      );
      final poke = _createPoke(id: 25);

      // If available games is only scarlet-violet, sinnoh champ ribbon is incompatible
      final resultSV = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [sinnohChampRibbon],
        ['scarlet-violet'],
      );
      expect(resultSV, isEmpty);

      // If available games includes brilliant-diamond-and-shining-pearl, it matches 'bd'/'sp'
      final resultBDSP = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [sinnohChampRibbon],
        ['brilliant-diamond-and-shining-pearl'],
      );
      expect(resultBDSP, contains(sinnohChampRibbon));
    });

    test('Event ribbons (classic, premier, event) bypass game compatibility checks', () {
      final classicRibbon = _createRibbon(
        id: 'classic-ribbon',
        isMark: 0,
        availableGames: ['diamond'], // Incompatible with SV
      );
      final premierRibbon = _createRibbon(
        id: 'premier-ribbon',
        isMark: 0,
        availableGames: ['ruby'],
      );
      final eventRibbon = _createRibbon(
        id: 'special-event-ribbon',
        isMark: 0,
        availableGames: ['x'],
      );
      final poke = _createPoke(id: 25);

      final results = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [classicRibbon, premierRibbon, eventRibbon],
        ['scarlet-violet'], // None match the availableGames directly
      );

      expect(results, containsAll([classicRibbon, premierRibbon, eventRibbon]));
    });

    test('Ribbons with empty availableGames are included by default', () {
      final genericRibbon = _createRibbon(
        id: 'generic-ribbon',
        isMark: 0,
        availableGames: [],
      );
      final poke = _createPoke(id: 25);

      final results = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [genericRibbon],
        ['sword-shield'],
      );

      expect(results, contains(genericRibbon));
    });

    test('Standard marks require SwSh or SV compatibility and exclude pre-Gen 8 games', () {
      final rareMark = _createRibbon(id: 'rare-mark', isMark: 1);
      final poke = _createPoke(id: 25);

      // In Sun/Moon only (Gen 7) -> marks did not exist yet, so false
      final resultGen7 = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [rareMark],
        ['sun-moon'],
      );
      expect(resultGen7, isEmpty);

      // In SwSh (Gen 8) -> true
      final resultSwSh = RibbonLogicHelper.getValidRibbonsForPokemon(
        poke,
        25,
        [rareMark],
        ['sword-shield'],
      );
      expect(resultSwSh, contains(rareMark));
    });
  });
}
