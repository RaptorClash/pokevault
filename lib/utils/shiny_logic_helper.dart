import '../models/pokemon.dart';

class Gen1Encounter {
  final String typeKey;
  final String detailsDe;
  final String detailsEn;

  const Gen1Encounter(this.typeKey, this.detailsDe, this.detailsEn);
}

class ShinyLogicHelper {
  static final Set<int> _huntableInGen1 = {
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    25,
    26,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    47,
    51,
    54,
    55,
    60,
    61,
    62,
    63,
    64,
    65,
    68,
    72,
    73,
    76,
    79,
    80,
    83,
    86,
    87,
    89,
    90,
    91,
    94,
    98,
    99,
    100,
    101,
    106,
    107,
    108,
    112,
    114,
    115,
    116,
    117,
    118,
    119,
    120,
    121,
    122,
    123,
    124,
    127,
    128,
    129,
    130,
    131,
    133,
    134,
    135,
    136,
    137,
    138,
    139,
    140,
    141,
    142,
    143,
    144,
    145,
    146,
    147,
    148,
    149,
    150,
  };

  static final Set<int> _evolvesFromHuntable = {
    2,
    3,
    5,
    6,
    8,
    9,
    26,
    30,
    31,
    33,
    34,
    36,
    38,
    55,
    61,
    62,
    64,
    65,
    73,
    80,
    87,
    91,
    99,
    101,
    117,
    119,
    121,
    130,
    134,
    135,
    136,
    139,
    141,
    148,
    149,
  };

  static bool isHuntableInGen1(int dexId) {
    return _huntableInGen1.contains(dexId);
  }

  static List<Gen1Encounter> getGen1Encounters(int dexId) {
    List<Gen1Encounter> encounters = List.from(
      _gen1SpecialEncounters[dexId] ?? [],
    );
    if (_evolvesFromHuntable.contains(dexId)) {
      encounters.add(
        const Gen1Encounter(
          'encounter_evolution',
          'Durch Entwicklung einer fangbaren Vorentwicklung',
          'By evolving a catchable pre-evolution',
        ),
      );
    }
    return encounters;
  }

  static int getDefaultLevel(int dexId) {
    const Map<int, int> levels = {
      1: 5, 4: 5, 7: 5, 25: 5, // Starter
      129: 5, // Karpador (Geschenk)
      63: 9, // Abra (Game Corner Red)
      35: 8, // Piepi (Game Corner Red)
      30: 22, 33: 22, 37: 18, 40: 22, // Nidorina, Nidorino, Vulpix, Knuddeluff
      137: 26, // Porygon
      147: 18, 148: 30, // Dratini, Dragonair
      123: 25, 127: 25, // Sichlor, Pinsir
      36: 23, // Pixi (Game Corner Jap. Blue)
      116: 18, // Seeper (Game Corner Jap. Blue)
      131: 15, // Lapras
      133: 25, // Evoli
      138: 30, 140: 30, 142: 30, // Fossilien
      106: 30, 107: 30, // Kicklee, Nockchan
      100: 40, 101: 40, // Voltobal, Lektrobal
      143: 30, // Relaxo
      144: 50, 145: 50, 146: 50, // Legendäre Vögel
      150: 70, // Mewtu
    };
    return levels[dexId] ??
        15;
  }

  static final Map<int, List<int>> gen1BaseStats = {
    1: [45, 49, 49, 45, 65],
    2: [60, 62, 63, 60, 80],
    3: [80, 82, 83, 80, 100],
    4: [39, 52, 43, 65, 50],
    5: [58, 64, 58, 80, 65],
    6: [78, 84, 78, 100, 85],
    7: [44, 48, 65, 43, 50],
    8: [59, 63, 80, 58, 65],
    9: [79, 83, 100, 78, 85],
    10: [45, 30, 35, 45, 20],
    11: [50, 20, 55, 30, 25],
    12: [60, 45, 50, 70, 80],
    13: [40, 35, 30, 50, 20],
    14: [45, 25, 50, 35, 25],
    15: [65, 80, 40, 75, 45],
    16: [40, 45, 40, 56, 35],
    17: [63, 60, 55, 71, 50],
    18: [83, 80, 75, 91, 70],
    19: [30, 56, 35, 72, 25],
    20: [55, 81, 60, 97, 50],
    21: [40, 60, 30, 70, 31],
    22: [65, 90, 65, 100, 61],
    23: [35, 60, 44, 55, 40],
    24: [60, 85, 69, 80, 65],
    25: [35, 55, 30, 90, 50],
    26: [60, 90, 55, 100, 90],
    27: [50, 75, 85, 40, 30],
    28: [75, 100, 110, 65, 55],
    29: [55, 47, 52, 41, 40],
    30: [70, 62, 67, 56, 55],
    31: [90, 82, 87, 76, 75],
    32: [46, 57, 40, 50, 40],
    33: [61, 72, 57, 65, 55],
    34: [81, 92, 77, 85, 85],
    35: [70, 45, 48, 35, 60],
    36: [95, 70, 73, 60, 85],
    37: [38, 41, 40, 65, 65],
    38: [73, 76, 75, 100, 100],
    39: [115, 45, 20, 20, 25],
    40: [140, 70, 45, 45, 50],
    41: [40, 45, 35, 55, 40],
    42: [75, 80, 70, 90, 75],
    43: [45, 50, 55, 30, 75],
    44: [60, 65, 70, 40, 85],
    45: [75, 80, 85, 50, 100],
    46: [35, 70, 55, 25, 55],
    47: [60, 95, 80, 30, 80],
    48: [60, 55, 50, 45, 40],
    49: [70, 65, 60, 90, 90],
    50: [10, 55, 25, 95, 45],
    51: [35, 80, 50, 120, 70],
    52: [40, 45, 35, 90, 40],
    53: [65, 70, 60, 115, 65],
    54: [50, 52, 48, 55, 50],
    55: [80, 82, 78, 85, 80],
    56: [40, 80, 35, 70, 35],
    57: [65, 105, 60, 95, 60],
    58: [55, 70, 45, 60, 50],
    59: [90, 110, 80, 95, 80],
    60: [40, 50, 40, 90, 40],
    61: [65, 65, 65, 90, 50],
    62: [90, 85, 95, 70, 70],
    63: [25, 20, 15, 90, 105],
    64: [40, 35, 30, 105, 120],
    65: [55, 50, 45, 120, 135],
    66: [70, 80, 50, 35, 35],
    67: [80, 100, 70, 45, 50],
    68: [90, 130, 80, 55, 65],
    69: [50, 75, 35, 40, 70],
    70: [65, 90, 50, 55, 85],
    71: [80, 105, 65, 70, 100],
    72: [40, 40, 35, 70, 100],
    73: [80, 70, 65, 100, 120],
    74: [40, 80, 100, 20, 30],
    75: [55, 95, 115, 35, 45],
    76: [80, 110, 130, 45, 55],
    77: [50, 85, 55, 90, 65],
    78: [65, 100, 70, 105, 80],
    79: [90, 65, 65, 15, 40],
    80: [95, 75, 110, 30, 80],
    81: [25, 35, 70, 45, 95],
    82: [50, 60, 95, 70, 120],
    83: [52, 65, 55, 60, 58],
    84: [35, 85, 45, 75, 35],
    85: [60, 110, 70, 100, 60],
    86: [65, 45, 55, 45, 70],
    87: [90, 70, 80, 70, 95],
    88: [80, 80, 50, 25, 40],
    89: [105, 105, 75, 50, 65],
    90: [30, 65, 100, 40, 45],
    91: [50, 95, 180, 70, 85],
    92: [30, 35, 30, 80, 100],
    93: [45, 50, 45, 95, 115],
    94: [60, 65, 60, 110, 130],
    95: [35, 45, 160, 70, 30],
    96: [60, 48, 45, 42, 90],
    97: [85, 73, 70, 67, 115],
    98: [30, 105, 90, 50, 25],
    99: [55, 130, 115, 75, 50],
    100: [40, 30, 50, 100, 55],
    101: [60, 50, 70, 140, 80],
    102: [60, 40, 80, 40, 60],
    103: [95, 95, 85, 55, 125],
    104: [50, 50, 95, 35, 40],
    105: [60, 80, 110, 45, 50],
    106: [50, 120, 53, 87, 35],
    107: [50, 105, 79, 76, 35],
    108: [90, 55, 75, 30, 60],
    109: [40, 65, 95, 35, 60],
    110: [65, 90, 120, 60, 85],
    111: [80, 85, 95, 25, 30],
    112: [105, 130, 120, 40, 45],
    113: [250, 5, 5, 50, 105],
    114: [65, 55, 115, 60, 100],
    115: [105, 95, 80, 90, 40],
    116: [30, 40, 70, 60, 70],
    117: [55, 65, 95, 85, 95],
    118: [45, 67, 60, 63, 50],
    119: [80, 92, 65, 68, 80],
    120: [30, 45, 55, 85, 70],
    121: [60, 75, 85, 115, 100],
    122: [40, 45, 65, 90, 100],
    123: [70, 110, 80, 105, 55],
    124: [65, 50, 35, 95, 95],
    125: [65, 83, 57, 105, 85],
    126: [65, 95, 57, 93, 85],
    127: [65, 125, 100, 85, 55],
    128: [75, 100, 95, 110, 70],
    129: [20, 10, 55, 80, 20],
    130: [95, 125, 79, 81, 100],
    131: [130, 85, 80, 60, 95],
    132: [48, 48, 48, 48, 48],
    133: [55, 55, 50, 55, 65],
    134: [130, 65, 60, 65, 110],
    135: [65, 65, 60, 130, 110],
    136: [65, 130, 60, 65, 110],
    137: [65, 60, 70, 40, 75],
    138: [35, 40, 100, 35, 90],
    139: [70, 60, 125, 55, 115],
    140: [30, 80, 90, 55, 45],
    141: [60, 115, 105, 80, 65],
    142: [80, 105, 65, 130, 60],
    143: [160, 110, 65, 30, 65],
    144: [90, 85, 100, 85, 125],
    145: [90, 90, 85, 100, 125],
    146: [90, 100, 90, 90, 125],
    147: [41, 64, 45, 50, 50],
    148: [61, 84, 65, 70, 70],
    149: [91, 134, 95, 80, 100],
    150: [106, 110, 90, 130, 154],
    151: [100, 100, 100, 100, 100],
  };

  static final Map<int, List<Gen1Encounter>> _gen1SpecialEncounters = {
    1: [
      Gen1Encounter(
        'encounter_gift',
        'Rot/Blau: Starter (Prof. Eich) | Gelb: Azuria City',
        'Red/Blue: Starter (Prof. Oak) | Yellow: Cerulean City',
      ),
    ],
    4: [
      Gen1Encounter(
        'encounter_gift',
        'Rot/Blau: Starter (Prof. Eich) | Gelb: Route 24',
        'Red/Blue: Starter (Prof. Oak) | Yellow: Route 24',
      ),
    ],
    7: [
      Gen1Encounter(
        'encounter_gift',
        'Rot/Blau: Starter (Prof. Eich) | Gelb: Orania City (Officer Rocky)',
        'Red/Blue: Starter (Prof. Oak) | Yellow: Vermilion City (Officer Jenny)',
      ),
    ],
    25: [
      Gen1Encounter(
        'encounter_gift',
        'Gelb: Starter (Prof. Eich)',
        'Yellow: Starter (Prof. Oak)',
      ),
      Gen1Encounter(
        'encounter_game_corner',
        'Jap. Blau (620 Münzen)',
        'Japanese Blue (620 coins)',
      ),
    ],
    29: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Unterführung (Tausche Nidoran♂)',
        'Red/Blue: Underground Path (Trade Nidoran♂)',
      ),
    ],
    30: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Route 11 (Tausche Nidorino)',
        'Red/Blue: Route 11 (Trade Nidorino)',
      ),
      Gen1Encounter(
        'encounter_game_corner',
        'Rot (1200 Münzen)',
        'Red (1200 coins)',
      ),
    ],
    32: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Rot/Grün: Unterführung (Tausche Nidoran♀)',
        'Japanese Red/Green: Underground Path (Trade Nidoran♀)',
      ),
    ],
    33: [
      Gen1Encounter(
        'encounter_game_corner',
        'Blau (1200 Münzen)',
        'Blue (1200 coins)',
      ),
    ],
    35: [
      Gen1Encounter(
        'encounter_game_corner',
        'Rot (500 Münzen), Blau (750 Münzen)',
        'Red (500 coins), Blue (750 coins)',
      ),
    ],
    36: [
      Gen1Encounter(
        'encounter_game_corner',
        'Jap. Blau (2880 Münzen)',
        'Japanese Blue (2880 coins)',
      ),
    ],
    37: [
      Gen1Encounter(
        'encounter_game_corner',
        'Gelb (1000 Münzen)',
        'Yellow (1000 coins)',
      ),
    ],
    40: [
      Gen1Encounter(
        'encounter_game_corner',
        'Gelb (2680 Münzen)',
        'Yellow (2680 coins)',
      ),
    ],
    47: [
      Gen1Encounter(
        'encounter_trade',
        'Gelb: Route 18 (Tausche Tangela)',
        'Yellow: Route 18 (Trade Tangela)',
      ),
    ],
    51: [
      Gen1Encounter(
        'encounter_trade',
        'Gelb: Route 11 (Tausche Schlurp)',
        'Yellow: Route 11 (Trade Lickitung)',
      ),
    ],
    54: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Azuria City, Safari-Zone, Route 24, 25 (Superangel)',
        'Red/Blue: Cerulean City, Safari Zone, Route 24, 25 (Super Rod)',
      ),
    ],
    60: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Blau: Unterführung (Tausche Rattfratz)',
        'Japanese Blue: Underground Path (Trade Rattata)',
      ),
      Gen1Encounter(
        'encounter_fishing',
        'R/B/G: Wasser & Statuen (Profiangel) | Rot/Blau: Alabastia, Vertania, Route 22 (Superangel) | Gelb: Vertania, Route 22, 23 (Superangel)',
        'R/B/Y: Water & Statues (Good Rod) | Red/Blue: Pallet, Viridian, Route 22 (Super Rod) | Yellow: Viridian, Route 22, 23 (Super Rod)',
      ),
    ],
    61: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Prismania, Route 10 (Superangel) | Gelb: Route 22, 23 (Superangel)',
        'Red/Blue: Celadon, Route 10 (Super Rod) | Yellow: Route 22, 23 (Super Rod)',
      ),
    ],
    63: [
      Gen1Encounter(
        'encounter_game_corner',
        'Rot (180 Münzen), Blau (120 Münzen), Gelb (230 Münzen), Jap. Blau (150 Münzen)',
        'Red (180 coins), Blue (120 coins), Yellow (230 coins), Jap. Blue (150 coins)',
      ),
    ],
    68: [
      Gen1Encounter(
        'encounter_trade',
        'Gelb: Unterführung (Tausche Tragosso, entwickelt sich)',
        'Yellow: Underground Path (Trade Cubone, evolves)',
      ),
    ],
    72: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Alabastia, Vertania, Route 12, 13, 17, 18 (Superangel) | Gelb: Alabastia, Orania, Zinnoberinsel, Route 11, 13, 17-21 (Superangel)',
        'Red/Blue: Pallet, Viridian, Routes 12, 13, 17, 18 (Super Rod) | Yellow: Pallet, Vermilion, Cinnabar, Routes 11, 13, 17-21 (Super Rod)',
      ),
    ],
    73: [
      Gen1Encounter(
        'encounter_fishing',
        'Gelb: Route 19, 20, 21 (Superangel)',
        'Yellow: Routes 19, 20, 21 (Super Rod)',
      ),
    ],
    76: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Blau: Zinnoberinsel (Tausche Kadabra, entwickelt sich)',
        'Japanese Blue: Cinnabar Island (Trade Kadabra, evolves)',
      ),
    ],
    79: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Blau: Zinnoberinsel (Tausche Jurob)',
        'Japanese Blue: Cinnabar Island (Trade Seel)',
      ),
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Prismania, Safari-Zone, Route 10 (Superangel)',
        'Red/Blue: Celadon, Safari Zone, Route 10 (Super Rod)',
      ),
    ],
    80: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Geheimdungeon, Route 23 (Superangel)',
        'Red/Blue: Cerulean Cave, Route 23 (Super Rod)',
      ),
    ],
    83: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Orania City (Tausche Habitak) | Jap. Blau: Orania City (Tausche Taubsi)',
        'Red/Blue: Vermilion City (Trade Spearow) | Japanese Blue: Vermilion City (Trade Pidgey)',
      ),
    ],
    86: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Zinnoberinsel (Tausche Ponita)',
        'Red/Blue: Cinnabar Island (Trade Ponyta)',
      ),
    ],
    87: [
      Gen1Encounter(
        'encounter_trade',
        'Gelb: Zinnoberinsel (Tausche Fukano)',
        'Yellow: Cinnabar Island (Trade Growlithe)',
      ),
    ],
    89: [
      Gen1Encounter(
        'encounter_trade',
        'Gelb: Zinnoberinsel (Tausche Kangama)',
        'Yellow: Cinnabar Island (Trade Kangaskhan)',
      ),
    ],
    90: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Orania, Zinnoberinsel, Seeschauminseln, Route 6, 11, 19-21 (Superangel) | Gelb: Orania Hafen, Route 17, 18 (Superangel)',
        'Red/Blue: Vermilion, Cinnabar, Seafoam, Routes 6, 11, 19-21 (Super Rod) | Yellow: Vermilion Harbor, Routes 17, 18 (Super Rod)',
      ),
    ],
    94: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Blau: Azuria City (Tausche Maschock, entwickelt sich)',
        'Japanese Blue: Cerulean City (Trade Machoke, evolves)',
      ),
    ],
    98: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Blau: Zinnoberinsel (Tausche Fukano)',
        'Japanese Blue: Cinnabar Island (Trade Growlithe)',
      ),
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Azuria, Orania, Fuchsania, Safari-Zone, Route 6, 11-13, 17, 18, 24, 25 (Superangel) | Gelb: Seeschauminseln, Route 10, 25 (Superangel)',
        'Red/Blue: Cerulean, Vermilion, Fuchsia, Safari Zone, Routes 6, 11-13, 17, 18, 24, 25 (Super Rod) | Yellow: Seafoam, Routes 10, 25 (Super Rod)',
      ),
    ],
    99: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Geheimdungeon, Route 23 (Superangel) | Gelb: Seeschauminseln, Route 10, 25 (Superangel)',
        'Red/Blue: Cerulean Cave, Route 23 (Super Rod) | Yellow: Seafoam, Routes 10, 25 (Super Rod)',
      ),
    ],
    100: [
      Gen1Encounter(
        'encounter_stationary',
        'R/B/G: Kraftwerk (Falsche Items)',
        'R/B/Y: Power Plant (Fake items)',
      ),
    ],
    101: [
      Gen1Encounter(
        'encounter_stationary',
        'R/B/G: Kraftwerk (Falsche Items)',
        'R/B/Y: Power Plant (Fake items)',
      ),
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Zinnoberinsel (Tausche Raichu)',
        'Red/Blue: Cinnabar Island (Trade Raichu)',
      ),
    ],
    106: [
      Gen1Encounter(
        'encounter_gift',
        'R/B/G: Kampf-Dojo (Saffronia City)',
        'R/B/Y: Fighting Dojo (Saffron City)',
      ),
    ],
    107: [
      Gen1Encounter(
        'encounter_gift',
        'R/B/G: Kampf-Dojo (Saffronia City)',
        'R/B/Y: Fighting Dojo (Saffron City)',
      ),
    ],
    108: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Route 18 (Tausche Lahmus)',
        'Red/Blue: Route 18 (Trade Slowbro)',
      ),
    ],
    112: [
      Gen1Encounter(
        'encounter_trade',
        'Gelb: Zinnoberinsel (Tausche Entoron)',
        'Yellow: Cinnabar Island (Trade Golduck)',
      ),
    ],
    114: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Zinnoberinsel (Tausche Bluzuk)',
        'Red/Blue: Cinnabar Island (Trade Venonat)',
      ),
    ],
    115: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Blau: Route 11 (Tausche Rizeros)',
        'Japanese Blue: Route 11 (Trade Rhydon)',
      ),
    ],
    116: [
      Gen1Encounter(
        'encounter_game_corner',
        'Jap. Blau (1000 Münzen)',
        'Japanese Blue (1000 coins)',
      ),
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Zinnoberinsel, Seeschauminseln, Route 19-21 (Superangel) | Gelb: Orania City, Route 10-13 (Superangel)',
        'Red/Blue: Cinnabar, Seafoam, Routes 19-21 (Super Rod) | Yellow: Vermilion City, Routes 10-13 (Super Rod)',
      ),
    ],
    117: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Geheimdungeon, Route 23 (Superangel) | Gelb: Route 12, 13 (Superangel)',
        'Red/Blue: Cerulean Cave, Route 23 (Super Rod) | Yellow: Routes 12, 13 (Super Rod)',
      ),
    ],
    118: [
      Gen1Encounter(
        'encounter_fishing',
        'R/B/G: Wasser & Statuen (Profiangel) | Rot/Blau: Azuria, Fuchsania, Zinnober, Seeschaum., Route 12, 13, 17-22, 24 (Superangel) | Gelb: Azuria, Geheimdungeon, Prismania, Route 6, 24 (Superangel)',
        'R/B/Y: Water & Statues (Good Rod) | Red/Blue: Cerulean, Fuchsia, Cinnabar, Seafoam, R. 12, 13, 17-22, 24 (Super Rod) | Yellow: Cerulean, Cerulean Cave, Celadon, R. 6, 24 (Super Rod)',
      ),
    ],
    119: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Geheimdungeon, Fuchsania, Route 23 (Superangel) | Gelb: Azuria City, Geheimdungeon, Route 24 (Superangel)',
        'Red/Blue: Cerulean Cave, Fuchsia, Route 23 (Super Rod) | Yellow: Cerulean City, Cerulean Cave, Route 24 (Super Rod)',
      ),
    ],
    120: [
      Gen1Encounter(
        'encounter_fishing',
        'Rot/Blau: Zinnober, Seeschauminseln, Route 19-21 (Superangel) | Gelb: Alabastia, Orania Hafen, Zinnober, Seeschauminseln, Route 19-21 (Superangel)',
        'Red/Blue: Cinnabar, Seafoam, Routes 19-21 (Super Rod) | Yellow: Pallet, Vermilion Harbor, Cinnabar, Seafoam, Routes 19-21 (Super Rod)',
      ),
    ],
    122: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Route 2 (Tausche Abra) | Gelb: Route 2 (Tausche Piepi) | Jap. Blau: Route 2 (Tausche Pummeluff)',
        'Red/Blue: Route 2 (Trade Abra) | Yellow: Route 2 (Trade Clefairy) | Japanese Blue: Route 2 (Trade Jigglypuff)',
      ),
    ],
    123: [
      Gen1Encounter(
        'encounter_game_corner',
        'Rot (5500 Münzen), Gelb (6500 Münzen)',
        'Red (5500 coins), Yellow (6500 coins)',
      ),
    ],
    124: [
      Gen1Encounter(
        'encounter_trade',
        'Rot/Blau: Azuria City (Tausche Quaputzi)',
        'Red/Blue: Cerulean City (Trade Poliwhirl)',
      ),
    ],
    127: [
      Gen1Encounter(
        'encounter_game_corner',
        'Blau (2500 Münzen), Gelb (6500 Münzen)',
        'Blue (2500 coins), Yellow (6500 coins)',
      ),
    ],
    128: [
      Gen1Encounter(
        'encounter_trade',
        'Jap. Blau: Route 18 (Tausche Snobilikat)',
        'Japanese Blue: Route 18 (Trade Persian)',
      ),
    ],
    129: [
      Gen1Encounter(
        'encounter_gift',
        'R/B/G: Route 4 PKMN-Center (500 PokéDollar)',
        'R/B/Y: Route 4 PKMN Center (500 Money)',
      ),
      Gen1Encounter(
        'encounter_fishing',
        'R/B/G: Jedes Wasser & Statuen (Angel) | Rot/Blau: Fuchsania, Route 12, 13, 17, 18 (Superangel) | Gelb: Fuchsania, Safari-Zone (Superangel)',
        'R/B/Y: Any water & Statues (Old Rod) | Red/Blue: Fuchsia, Routes 12, 13, 17, 18 (Super Rod) | Yellow: Fuchsia, Safari Zone (Super Rod)',
      ),
    ],
    130: [
      Gen1Encounter(
        'encounter_fishing',
        'Gelb: Fuchsania City (Superangel)',
        'Yellow: Fuchsia City (Super Rod)',
      ),
    ],
    131: [
      Gen1Encounter('encounter_gift', 'R/B/G: Silph Co.', 'R/B/Y: Silph Co.'),
    ],
    133: [
      Gen1Encounter(
        'encounter_gift',
        'R/B/G: Prismania City Villa',
        'R/B/Y: Celadon Mansion',
      ),
    ],
    137: [
      Gen1Encounter(
        'encounter_game_corner',
        'Rot (9999 Münzen), Blau (6500 Münzen), Gelb (9999 Münzen), Jap. Blau (8300 Münzen)',
        'Red (9999 coins), Blue (6500 coins), Yellow (9999 coins), Jap. Blue (8300 coins)',
      ),
    ],
    138: [
      Gen1Encounter(
        'encounter_gift',
        'R/B/G: Helixfossil (Zinnoberinsel)',
        'R/B/Y: Helix Fossil (Cinnabar Island)',
      ),
    ],
    140: [
      Gen1Encounter(
        'encounter_gift',
        'R/B/G: Domfossil (Zinnoberinsel)',
        'R/B/Y: Dome Fossil (Cinnabar Island)',
      ),
    ],
    142: [
      Gen1Encounter(
        'encounter_gift',
        'R/B/G: Altbernstein (Zinnoberinsel)',
        'R/B/Y: Old Amber (Cinnabar Island)',
      ),
    ],
    143: [
      Gen1Encounter(
        'encounter_stationary',
        'R/B/G: Route 12 & 16 (Pokéflöte)',
        'R/B/Y: Route 12 & 16 (Poké Flute)',
      ),
    ],
    144: [
      Gen1Encounter(
        'encounter_stationary',
        'R/B/G: Seeschauminseln',
        'R/B/Y: Seafoam Islands',
      ),
    ],
    145: [
      Gen1Encounter(
        'encounter_stationary',
        'R/B/G: Kraftwerk',
        'R/B/Y: Power Plant',
      ),
    ],
    146: [
      Gen1Encounter(
        'encounter_stationary',
        'R/B/G: Siegesstraße',
        'R/B/Y: Victory Road',
      ),
    ],
    147: [
      Gen1Encounter(
        'encounter_game_corner',
        'Rot (2800 Münzen), Blau (4600 Münzen)',
        'Red (2800 coins), Blue (4600 coins)',
      ),
      Gen1Encounter(
        'encounter_fishing',
        'R/B/G: Safari-Zone (Superangel)',
        'R/B/Y: Safari Zone (Super Rod)',
      ),
    ],
    148: [
      Gen1Encounter(
        'encounter_game_corner',
        'Jap. Blau (5400 Münzen)',
        'Japanese Blue (5400 coins)',
      ),
      Gen1Encounter(
        'encounter_fishing',
        'Gelb: Safari-Zone Bereich 1 (Superangel)',
        'Yellow: Safari Zone Area 1 (Super Rod)',
      ),
    ],
    150: [
      Gen1Encounter(
        'encounter_stationary',
        'R/B/G: Geheimdungeon (Azuria-Höhle)',
        'R/B/Y: Cerulean Cave',
      ),
    ],
    151: [
      Gen1Encounter(
        'encounter_glitch',
        'Rot/Blau: 8F Item Underflow Glitch',
        'Red/Blue: 8F Item Underflow Glitch',
      ),
    ],
  };
}
