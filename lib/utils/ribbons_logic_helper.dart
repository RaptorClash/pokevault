import '../models/pokemon.dart';
import '../models/ribbon.dart';

class RibbonLogicHelper {
  static const List<int> _mythicalIds = [
    151,
    251,
    385,
    386,
    489,
    490,
    491,
    492,
    493,
    494,
    647,
    648,
    649,
    719,
    720,
    721,
    801,
    802,
    807,
    808,
    809,
    893,
    898,
    1025,
  ];

  static const List<String> _partyMarks = [
    'destiny-mark',
    'curry-mark',
    'itemfinder-mark',
    'partner-mark',
    'gourmand-mark',
  ];

  static List<String> mapPokeApiToRibbonGames(List<String> pokeApiGroups) {
    Set<String> mapped = {};
    for (String group in pokeApiGroups) {
      switch (group) {
        case 'sword-shield':
          mapped.addAll(['sw', 'sh']);
          break;
        case 'brilliant-diamond-and-shining-pearl':
          mapped.addAll(['bd', 'sp']);
          break;
        case 'legends-arceus':
          mapped.add('pla');
          break;
        case 'scarlet-violet':
          mapped.addAll(['scar', 'vio']);
          break;
        case 'sun-moon':
          mapped.addAll(['sun', 'moon']);
          break;
        case 'ultra-sun-ultra-moon':
          mapped.addAll(['usun', 'umoon']);
          break;
        case 'x-y':
          mapped.addAll(['x', 'y']);
          break;
        case 'omega-ruby-alpha-sapphire':
          mapped.addAll(['or', 'as']);
          break;
        case 'diamond-pearl':
          mapped.addAll(['diamond', 'pearl']);
          break;
        case 'platinum':
          mapped.add('platinum');
          break;
        case 'heartgold-soulsilver':
          mapped.addAll(['heartgold', 'soulsilver']);
          break;
        case 'ruby-sapphire':
          mapped.addAll(['ruby', 'sapphire']);
          break;
        case 'emerald':
          mapped.add('emerald');
          break;
        case 'firered-leafgreen':
          mapped.addAll(['firered', 'leafgreen']);
          break;
        case 'colosseum':
          mapped.add('colosseum');
          break;
        case 'xd':
          mapped.add('xd');
          break;
      }
    }
    return mapped.toList();
  }

  static List<Ribbon> getValidRibbonsForPokemon(
    Pokemon pokemon,
    int baseId,
    List<Ribbon> allRibbons,
    List<String> availablePokeApiGames,
  ) {
    List<String> mappedGames = mapPokeApiToRibbonGames(availablePokeApiGames);

    return allRibbons.where((ribbon) {
      if (ribbon.isMark == 1 || ribbon.id.toLowerCase().contains('mark')) {
        bool inSwSh = mappedGames.contains('sw') || mappedGames.contains('sh');
        bool inSV = mappedGames.contains('scar') || mappedGames.contains('vio');
        bool inPLA = mappedGames.contains('pla');

        if (ribbon.id == 'alpha-mark') {
          if (!inPLA) return false;
        } else if (ribbon.id == 'curry-mark') {
          if (!inSwSh) return false;
        } else if ([
          'itemfinder-mark',
          'partner-mark',
          'gourmand-mark',
          'titan-mark',
          'mightiest-mark',
        ].contains(ribbon.id)) {
          if (!inSV) return false;
        } else {
          if (!inSwSh && !inSV) return false;
        }

        if (_mythicalIds.contains(pokemon.id) &&
            !_partyMarks.contains(ribbon.id)) {
          return false;
        }

        return true;
      }

      if (ribbon.availableGames.isNotEmpty) {
        bool isGameCompatible = ribbon.availableGames.any(
          (game) => mappedGames.contains(game),
        );

        bool isEventRibbon =
            ribbon.id.contains('classic') ||
            ribbon.id.contains('premier') ||
            ribbon.id.contains('event');

        if (!isGameCompatible && !isEventRibbon) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
