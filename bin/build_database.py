import urllib.request
import json
import sqlite3
import os
import re
import time
import openpyxl

EXCEL_PATH = 'bin/Legal_Matching_Pokeballs.xlsx'
CUSTOM_JSON_PATH = 'bin/custom_matching_balls.json'

FORM_WHITELIST = {
    "172_spiky-eared": ["updated_johto_regional"],
    "25_cosplay": ["updated_hoenn_regional"],
    "25_rockstar": ["updated_hoenn_regional"],
    "25_belle": ["updated_hoenn_regional"],
    "25_popstar": ["updated_hoenn_regional"],
    "25_phd": ["updated_hoenn_regional"],
    "25_libre": ["updated_hoenn_regional"],
    "25_starter": ["kanto_regional"],
    "133_starter": ["kanto_regional"],
    "670_eternal": ["kalos_central_regional", "kalos_coastal_regional", "kalos_mountain_regional", "lumiose_regional"],
}

VERSION_TO_GEN = {
    'red': 'gen_1', 'blue': 'gen_1', 'yellow': 'gen_1',
    'gold': 'gen_2', 'silver': 'gen_2', 'crystal': 'gen_2',
    'ruby': 'gen_3', 'sapphire': 'gen_3', 'emerald': 'gen_3', 'firered': 'gen_3', 'leafgreen': 'gen_3', 'colosseum': 'gen_3', 'xd': 'gen_3',
    'diamond': 'gen_4', 'pearl': 'gen_4', 'platinum': 'gen_4', 'heartgold': 'gen_4', 'soulsilver': 'gen_4',
    'black': 'gen_5', 'white': 'gen_5', 'black-2': 'gen_5', 'white-2': 'gen_5',
    'x': 'gen_6', 'y': 'gen_6', 'omega-ruby': 'gen_6', 'alpha-sapphire': 'gen_6',
    'sun': 'gen_7', 'moon': 'gen_7', 'ultra-sun': 'gen_7', 'ultra-moon': 'gen_7', 'lets-go-pikachu': 'gen_7', 'lets-go-eevee': 'gen_7',
    'sword': 'gen_8', 'shield': 'gen_8', 'the-isle-of-armor-sword': 'gen_8', 'the-isle-of-armor-shield': 'gen_8', 'the-crown-tundra-sword': 'gen_8', 'the-crown-tundra-shield': 'gen_8', 'brilliant-diamond': 'gen_8', 'shining-pearl': 'gen_8', 'legends-arceus': 'gen_8',
    'scarlet': 'gen_9', 'violet': 'gen_9', 'the-teal-mask-scarlet': 'gen_9', 'the-teal-mask-violet': 'gen_9', 'the-indigo-disk-scarlet': 'gen_9', 'the-indigo-disk-violet': 'gen_9', 'legends-z-a': 'gen_9',
}

HARDCODED_ORDERS = {
    'lumiose': [152, 153, 154, 498, 499, 500, 158, 159, 160, 661, 662, 663, 659, 660, 664, 665, 666, 13, 14, 15, 16, 17, 18, 179, 180, 181, 504, 505, 406, 315, 407, 129, 130, 688, 689, 120, 121, 669, 670, 671, 672, 673, 677, 678, 667, 668, 674, 675, 568, 569, 702, 172, 25, 26, 173, 35, 36, 167, 168, 23, 24, 63, 64, 65, 92, 93, 94, 543, 544, 545, 679, 680, 681, 69, 70, 71, 511, 512, 513, 514, 515, 516, 307, 308, 309, 310, 280, 281, 282, 475, 228, 229, 333, 334, 531, 682, 683, 684, 685, 133, 134, 135, 136, 196, 197, 470, 471, 700, 427, 428, 353, 354, 582, 583, 584, 322, 323, 449, 450, 529, 530, 551, 552, 553, 66, 67, 68, 443, 444, 445, 703, 302, 303, 359, 447, 448, 79, 80, 199, 318, 319, 602, 603, 604, 147, 148, 149, 1, 2, 3, 4, 5, 6, 7, 8, 9, 618, 676, 686, 687, 690, 691, 692, 693, 704, 705, 706, 225, 361, 362, 478, 459, 460, 712, 713, 123, 212, 127, 214, 587, 701, 708, 709, 559, 560, 714, 715, 707, 607, 608, 609, 142, 696, 697, 698, 699, 95, 208, 304, 305, 306, 694, 695, 710, 711, 246, 247, 248, 656, 657, 658, 870, 650, 651, 652, 227, 653, 654, 655, 371, 372, 373, 115, 780, 374, 375, 376, 716, 717, 718, 719, 150],
    'mega-dex': [3, 6, 9, 15, 18, 65, 80, 94, 115, 127, 130, 142, 150, 181, 208, 212, 214, 229, 248, 254, 257, 260, 282, 302, 303, 306, 308, 310, 319, 323, 334, 354, 359, 362, 373, 376, 380, 381, 382, 383, 384, 428, 445, 448, 460, 475, 719],
    'icognito-dex': [201],
}

REGIONAL_ENDPOINTS = {
    'kanto': 'kanto_regional', 'letsgo-kanto': 'letsgo_kanto_regional', 'original-johto': 'johto_regional',
    'updated-johto': 'updated_johto_regional', 'hoenn': 'hoenn_regional', 'updated-hoenn': 'updated_hoenn_regional',
    'original-sinnoh': 'sinnoh_regional', 'extended-sinnoh': 'extended_sinnoh_regional', 'original-unova': 'unova_regional',
    'updated-unova': 'updated_unova_regional', 'kalos-central': 'kalos_central_regional', 'kalos-coastal': 'kalos_coastal_regional',
    'kalos-mountain': 'kalos_mountain_regional', 'original-alola': 'alola_regional', 'original-melemele': 'melemele_regional',
    'original-akala': 'akala_regional', 'original-ulaula': 'ulaula_regional', 'original-poni': 'poni_regional',
    'updated-alola': 'updated_alola_regional', 'updated-melemele': 'updated_melemele_regional', 'updated-akala': 'updated_akala_regional',
    'updated-ulaula': 'updated_ulaula_regional', 'updated-poni': 'updated_poni_regional', 'galar': 'galar_regional',
    'isle-of-armor': 'isle_of_armor_regional', 'crown-tundra': 'crown_tundra_regional', 'hisui': 'hisui_regional',
    'paldea': 'paldea_regional', 'kitakami': 'kitakami_regional', 'blueberry': 'blueberry_regional', 'lumiose': 'lumiose_regional',
    'lumiose-dimensions': 'lumiose_dimensions_regional', 'mega-dex': 'mega_dex', 'icognito-dex': 'icognito_dex',
}

TYPE_BALL_MAPPING = {
    'normal': 'premier_ball', 'fire': 'fast_ball', 'water': 'lure_ball', 'electric': 'quick_ball',
    'grass': 'friend_ball', 'ice': 'dive_ball', 'fighting': 'level_ball', 'poison': 'timer_ball',
    'ground': 'safari_ball', 'flying': 'repeat_ball', 'psychic': 'dream_ball', 'bug': 'net_ball',
    'rock': 'ultra_ball', 'ghost': 'dusk_ball', 'dragon': 'great_ball', 'dark': 'luxury_ball',
    'steel': 'heavy_ball', 'fairy': 'love_ball'
}

GEN1_BASE_STATS = {
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
}

GEN12_PRE_EVOLUTIONS = {
    2: {'pre': 1, 'req': 'Level 16'},
    3: {'pre': 2, 'req': 'Level 32'},
    5: {'pre': 4, 'req': 'Level 16'},
    6: {'pre': 5, 'req': 'Level 36'},
    8: {'pre': 7, 'req': 'Level 16'},
    9: {'pre': 8, 'req': 'Level 36'},
    11: {'pre': 10, 'req': 'Level 7'},
    12: {'pre': 11, 'req': 'Level 10'},
    14: {'pre': 13, 'req': 'Level 7'},
    15: {'pre': 14, 'req': 'Level 10'},
    17: {'pre': 16, 'req': 'Level 18'},
    18: {'pre': 17, 'req': 'Level 36'},
    20: {'pre': 19, 'req': 'Level 20'},
    22: {'pre': 21, 'req': 'Level 20'},
    24: {'pre': 23, 'req': 'Level 22'},
    25: {'pre': 172, 'req': 'Friendship'},
    26: {'pre': 25, 'req': 'Thunder Stone'},
    28: {'pre': 27, 'req': 'Level 22'},
    30: {'pre': 29, 'req': 'Level 16'},
    31: {'pre': 30, 'req': 'Moon Stone'},
    33: {'pre': 32, 'req': 'Level 16'},
    34: {'pre': 33, 'req': 'Moon Stone'},
    35: {'pre': 173, 'req': 'Friendship'},
    36: {'pre': 35, 'req': 'Moon Stone'},
    38: {'pre': 37, 'req': 'Fire Stone'},
    39: {'pre': 174, 'req': 'Friendship'},
    40: {'pre': 39, 'req': 'Moon Stone'},
    42: {'pre': 41, 'req': 'Level 22'},
    169: {'pre': 42, 'req': 'Friendship'},
    44: {'pre': 43, 'req': 'Level 21'},
    45: {'pre': 44, 'req': 'Leaf Stone'},
    182: {'pre': 44, 'req': 'Sun Stone'},
    47: {'pre': 46, 'req': 'Level 24'},
    49: {'pre': 48, 'req': 'Level 31'},
    51: {'pre': 50, 'req': 'Level 26'},
    53: {'pre': 52, 'req': 'Level 28'},
    55: {'pre': 54, 'req': 'Level 33'},
    57: {'pre': 56, 'req': 'Level 28'},
    59: {'pre': 58, 'req': 'Fire Stone'},
    61: {'pre': 60, 'req': 'Level 25'},
    62: {'pre': 61, 'req': 'Water Stone'},
    186: {'pre': 61, 'req': 'Trade w/ King\'s Rock'},
    64: {'pre': 63, 'req': 'Level 16'},
    65: {'pre': 64, 'req': 'Trade'},
    67: {'pre': 66, 'req': 'Level 28'},
    68: {'pre': 67, 'req': 'Trade'},
    70: {'pre': 69, 'req': 'Level 21'},
    71: {'pre': 70, 'req': 'Leaf Stone'},
    73: {'pre': 72, 'req': 'Water Stone'},
    75: {'pre': 74, 'req': 'Level 25'},
    76: {'pre': 75, 'req': 'Trade'},
    78: {'pre': 77, 'req': 'Level 40'},
    80: {'pre': 79, 'req': 'Level 37'},
    199: {'pre': 80, 'req': 'Trade w/ King\'s Rock'},
    82: {'pre': 81, 'req': 'Level 30'},
    85: {'pre': 84, 'req': 'Level 31'},
    87: {'pre': 86, 'req': 'Level 34'},
    89: {'pre': 88, 'req': 'Level 38'},
    91: {'pre': 90, 'req': 'Water Stone'},
    93: {'pre': 92, 'req': 'Level 25'},
    94: {'pre': 93, 'req': 'Trade'},
    97: {'pre': 96, 'req': 'Level 33'},
    99: {'pre': 98, 'req': 'Level 28'},
    101: {'pre': 100, 'req': 'Level 30'},
    103: {'pre': 102, 'req': 'Level 34'},
    105: {'pre': 104, 'req': 'Level 28'},
    106: {'pre': 236, 'req': 'Level 20 (Atk > Def)'},
    107: {'pre': 236, 'req': 'Level 20 (Atk < Def)'},
    237: {'pre': 236, 'req': 'Level 20 (Atk = Def)'},
    110: {'pre': 109, 'req': 'Level 35'},
    112: {'pre': 111, 'req': 'Level 42'},
    113: {'pre': 250, 'req': 'Level 5'},
    114: {'pre': 113, 'req': 'Friendship'},
    117: {'pre': 116, 'req': 'Level 32'},
    230: {'pre': 117, 'req': 'Trade w/ Dragon Scale'},
    119: {'pre': 118, 'req': 'Level 33'},
    121: {'pre': 120, 'req': 'Water Stone'},
    124: {'pre': 238, 'req': 'Level 30'},
    125: {'pre': 239, 'req': 'Level 30'},
    126: {'pre': 240, 'req': 'Level 30'},
    130: {'pre': 129, 'req': 'Level 20'},
    134: {'pre': 133, 'req': 'Water Stone'},
    135: {'pre': 133, 'req': 'Thunder Stone'},
    136: {'pre': 133, 'req': 'Fire Stone'},
    196: {'pre': 133, 'req': 'Friendship (Day)'},
    197: {'pre': 133, 'req': 'Friendship (Night)'},
    233: {'pre': 137, 'req': 'Trade w/ Up-Grade'},
    139: {'pre': 138, 'req': 'Level 40'},
    141: {'pre': 140, 'req': 'Level 40'},
    148: {'pre': 147, 'req': 'Level 30'},
    149: {'pre': 148, 'req': 'Level 55'},
    153: {'pre': 152, 'req': 'Level 16'},
    154: {'pre': 153, 'req': 'Level 32'},
    156: {'pre': 155, 'req': 'Level 14'},
    157: {'pre': 156, 'req': 'Level 36'},
    159: {'pre': 158, 'req': 'Level 18'},
    160: {'pre': 159, 'req': 'Level 30'},
    162: {'pre': 161, 'req': 'Level 15'},
    164: {'pre': 163, 'req': 'Level 20'},
    166: {'pre': 165, 'req': 'Level 18'},
    168: {'pre': 167, 'req': 'Level 22'},
    171: {'pre': 170, 'req': 'Level 27'},
    176: {'pre': 175, 'req': 'Friendship'},
    178: {'pre': 177, 'req': 'Level 25'},
    180: {'pre': 179, 'req': 'Level 15'},
    181: {'pre': 180, 'req': 'Level 30'},
    184: {'pre': 183, 'req': 'Level 18'},
    188: {'pre': 187, 'req': 'Level 18'},
    189: {'pre': 188, 'req': 'Level 27'},
    192: {'pre': 191, 'req': 'Sun Stone'},
    195: {'pre': 194, 'req': 'Level 20'},
    205: {'pre': 204, 'req': 'Level 31'},
    210: {'pre': 209, 'req': 'Level 23'},
    212: {'pre': 123, 'req': 'Trade w/ Metal Coat'},
    217: {'pre': 216, 'req': 'Level 30'},
    219: {'pre': 218, 'req': 'Level 38'},
    221: {'pre': 220, 'req': 'Level 33'},
    224: {'pre': 223, 'req': 'Level 25'},
    229: {'pre': 228, 'req': 'Level 24'},
    232: {'pre': 231, 'req': 'Level 25'},
    242: {'pre': 113, 'req': 'Friendship'},
    247: {'pre': 246, 'req': 'Level 20'},
    248: {'pre': 247, 'req': 'Level 55'},
}

DEFAULT_LEVELS = {
    1: 5, 4: 5, 7: 5, 25: 5, 129: 5, 63: 9, 35: 8, 30: 22, 33: 22, 37: 18, 40: 22, 137: 26, 
    147: 18, 148: 30, 123: 25, 127: 25, 36: 23, 116: 18, 131: 15, 133: 25, 138: 30, 140: 30, 
    142: 30, 106: 30, 107: 30, 100: 40, 101: 40, 143: 30, 144: 50, 145: 50, 146: 50, 150: 70
}

SHINY_CATEGORIES = {
    'gen1_huntable': [1, 2, 3, 4, 5, 6, 7, 8, 9, 25, 26, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 47, 51, 54, 55, 60, 61, 62, 63, 64, 65, 68, 72, 73, 76, 79, 80, 83, 86, 87, 89, 90, 91, 94, 98, 99, 100, 101, 106, 107, 108, 112, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 127, 128, 129, 130, 131, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150],
    'legendary_mythical': [144, 145, 146, 150, 151, 243, 244, 245, 249, 250, 251, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649, 716, 717, 718, 719, 720, 721, 772, 773, 785, 786, 787, 788, 789, 790, 791, 792, 793, 794, 795, 796, 797, 798, 799, 800, 801, 802, 803, 804, 805, 806, 807, 888, 889, 890, 891, 892, 893, 894, 895, 896, 897, 898, 905, 1001, 1002, 1003, 1004, 1007, 1008, 1014, 1015, 1016, 1017, 1024],
    'gen5_locks': [494, 643, 644, 647, 648, 649],
    'gen6_locks': [144, 145, 146, 150, 382, 383, 384, 386, 716, 717, 718, 719, 720, 721],
    'warp_ride': [195, 219, 271, 274, 277, 308, 326, 334, 419, 423, 450, 452, 460, 469, 531, 558, 561, 581, 618, 695, 144, 145, 146, 150, 243, 244, 245, 249, 250, 377, 378, 379, 380, 381, 382, 383, 384, 480, 481, 482, 483, 484, 485, 486, 487, 488, 638, 639, 640, 641, 642, 643, 644, 645, 646, 716, 717],
    'gen7_locks': [718, 785, 786, 787, 788, 789, 790, 791, 792, 800, 801, 802, 807],
    'gen75_locks': [151],
    'ultra_beast': [793, 794, 795, 796, 797, 798, 799, 803, 804, 805, 806],
    'alolan_base': [19, 20, 26, 27, 28, 37, 38, 50, 51, 52, 53, 74, 75, 76, 88, 89, 103, 105],
    'gen8_locks': [151, 772, 773, 789, 790, 803, 804, 888, 889, 890, 891, 892, 893, 896, 897, 898],
    'pla_locks': [480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 641, 642, 645, 905],
    'sv_locks': [144, 145, 146, 243, 244, 245, 249, 250, 380, 381, 382, 383, 384, 638, 639, 640, 643, 644, 646, 648, 791, 792, 800, 891, 896, 897, 901, 1001, 1002, 1003, 1004, 1007, 1008, 1009, 1010, 1014, 1015, 1016, 1017, 1020, 1021, 1022, 1023, 1024, 1025],
    'plza_locks': [359, 382, 383, 384, 398, 448, 485, 491, 669, 678, 716, 717, 718, 977]
}

def fetch_json(url):
    for _ in range(3):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                return json.loads(response.read().decode())
        except Exception:
            time.sleep(1)
    return None

def clean_location(raw_loc):
    loc = raw_loc.lower()
    loc = re.sub(r'-?area$', '', loc)
    loc = re.sub(r'-?(south|north|east|west)-towards.*$', '', loc)
    loc = re.sub(r'-?(before|after)-galactic-intervention$', '', loc)
    loc = re.sub(r'^(kanto|johto|hoenn|sinnoh|unova|kalos|alola|galar|paldea|hisui)-', '', loc)
    loc = loc.replace('sea-route-', 'Sea Route ').replace('route-', 'Route ')
    if '-' in loc or ' ' in loc:
        loc = ' '.join([w.capitalize() for w in re.split(r'[- ]', loc) if w])
    else:
        if loc: loc = loc.capitalize()
    return loc.strip()

def parse_chain(node):
    species_url = node['species']['url']
    species_id = int(species_url.strip('/').split('/')[-1])
    evolves_to = [parse_chain(n) for n in node.get('evolves_to', [])]
    details = []
    for d in node.get('evolution_details', []):
        details.append({
            'trigger': d['trigger']['name'] if d.get('trigger') else None,
            'min_level': d.get('min_level'),
            'item': d['item']['name'] if d.get('item') else None,
            'held_item': d['held_item']['name'] if d.get('held_item') else None,
            'min_happiness': d.get('min_happiness'),
            'time_of_day': d.get('time_of_day'),
            'known_move': d['known_move']['name'] if d.get('known_move') else None,
            'location': d['location']['name'] if d.get('location') else None,
        })
    return {
        'species_id': species_id,
        'is_baby': node.get('is_baby', False),
        'details': details,
        'evolves_to': evolves_to
    }

def get_gen_by_id(pid):
    if pid <= 151: return 1
    if pid <= 251: return 2
    if pid <= 386: return 3
    if pid <= 493: return 4
    if pid <= 649: return 5
    if pid <= 721: return 6
    if pid <= 809: return 7
    if pid <= 905: return 8
    return 9

def get_url(cell_value):
    if not isinstance(cell_value, str):
        return None
    match = re.search(r'(https?://[^\s"<>&\u0027\)]+)', cell_value)
    return match.group(1) if match else None

def get_form(name, is_direct=False):
    name = str(name).lower().replace('é', 'e').replace('è', 'e').strip()
    
    if is_direct:
        return re.sub(r'\s+', '-', name).replace("'", "")
        
    if 'alola' in name: return 'alola'
    if 'galar' in name: return 'galar'
    if 'hisui' in name: return 'hisui'
    if 'paldea' in name: return 'paldea'
    
    name_check = name.replace('*', '').strip()
    words = name_check.replace('(', ' ').replace(')', ' ').split()
    if 'mega' in words:
        if 'x' in words or 'x)' in name_check: return 'mega-x'
        if 'y' in words or 'y)' in name_check: return 'mega-y'
        return 'mega'
        
    if 'primal' in name: return 'primal'
    if 'gmax' in name or 'gigantamax' in name: return 'gmax'
    
    if '(' in name:
        form_part = name.split('(')[1].replace(')', '').strip()
        form_part = form_part.lower().replace('é', 'e').replace('è', 'e')
        
        base_forms = [
            'no plate', 'altered', 'land', 'incarnate', 'aria', 'ordinary',
            'shield', '50%', 'confined', 'baile', 'midday', 'solo', 'red core',
            'disguised', 'amped', 'ice face', 'full belly', 'single strike',
            'hero', 'chest', 'family of four', 'green plumage', 'curly', 'plant', 'west',
            'spring', 'normal', 'base', 'standard', 'red-striped', 'red meteor', 'red',
            'natural'
        ]
        if form_part in base_forms:
            return 'normal'
            
        return re.sub(r'\s+', '-', form_part).replace("'", "")
        
    return 'normal'

def to_key(name):
    return name.lower().replace('é', 'e').replace('è', 'e').replace(' ', '_').strip()

def main():
    os.makedirs('assets/db', exist_ok=True)

    if os.path.exists('assets/db/pokedex.sqlite'):
            os.remove('assets/db/pokedex.sqlite')

    conn = sqlite3.connect('assets/db/pokedex.sqlite')
    c = conn.cursor()

    print("Erstelle Tabellen...")
    c.executescript('''
        CREATE TABLE IF NOT EXISTS pokemon (
            id INTEGER PRIMARY KEY, name_de TEXT, name_en TEXT,
            has_gender_differences INTEGER, gender_rate INTEGER, capture_rate INTEGER,
            evolution_chain_id INTEGER, egg_groups TEXT, weight REAL, speed INTEGER,
            catch_rate_tags TEXT
        );
        CREATE TABLE IF NOT EXISTS forms (
            id INTEGER PRIMARY KEY AUTOINCREMENT, pokemon_id INTEGER, name TEXT,
            form_type TEXT, min_gen INTEGER, image_id INTEGER, types TEXT, exclusive_regions TEXT
        );
        CREATE TABLE IF NOT EXISTS encounters (
            pokemon_id INTEGER, gen TEXT, version TEXT, location_data TEXT
        );
        CREATE TABLE IF NOT EXISTS evolutions (
            chain_id INTEGER PRIMARY KEY, chain_json TEXT
        );
        CREATE TABLE IF NOT EXISTS dex_orders (
            dex_name TEXT, pokemon_id INTEGER, order_index INTEGER
        );
        CREATE TABLE IF NOT EXISTS special_dexes (
            dex_name TEXT, pokemon_id INTEGER
        );
        CREATE TABLE IF NOT EXISTS ball_urls (
            ball_name TEXT PRIMARY KEY, image_url TEXT
        );
        CREATE TABLE IF NOT EXISTS matching_balls (
            unique_id TEXT PRIMARY KEY, normal_balls TEXT, shiny_balls TEXT
        );

        CREATE TABLE IF NOT EXISTS gen1_base_stats (
            id INTEGER PRIMARY KEY,
            hp INTEGER, atk INTEGER, def INTEGER, spc INTEGER, spe INTEGER
        );

        CREATE TABLE IF NOT EXISTS gen12_pre_evolutions (
            id INTEGER PRIMARY KEY,
            pre_id INTEGER,
            req TEXT
        );

        CREATE TABLE IF NOT EXISTS default_levels (
            pokemon_id INTEGER PRIMARY KEY, 
            default_level INTEGER
        );
        CREATE TABLE IF NOT EXISTS shiny_categories (
            pokemon_id INTEGER, 
            category TEXT
        );
    ''')

    print("\nSchreibe Gen 1 Base Stats und Gen 1/2 Pre-Evolutions in die DB...")
    for poke_id, stats in GEN1_BASE_STATS.items():
        c.execute('INSERT INTO gen1_base_stats VALUES (?, ?, ?, ?, ?, ?)', (poke_id, stats[0], stats[1], stats[2], stats[3], stats[4]))

    for poke_id, data in GEN12_PRE_EVOLUTIONS.items():
        c.execute('INSERT INTO gen12_pre_evolutions VALUES (?, ?, ?)', (poke_id, data['pre'], data['req']))

    for pid, lvl in DEFAULT_LEVELS.items():
        c.execute('INSERT INTO default_levels VALUES (?, ?)', (pid, lvl))

    for cat, pids in SHINY_CATEGORIES.items():
        for pid in pids:
            c.execute('INSERT INTO shiny_categories VALUES (?, ?)', (pid, cat))

    print("\n1. Verarbeite Matching Pokeballs (Excel & JSON)...")
    actual_path = EXCEL_PATH
    if not os.path.exists(actual_path):
        for file in os.listdir('.'):
            if 'Legal_Matching' in file and file.endswith('.xlsx'):
                actual_path = file
                break
        for file in os.listdir('bin'):
            if 'Legal_Matching' in file and file.endswith('.xlsx'):
                actual_path = f"bin/{file}"
                break
    
    url_to_key = {}
    key_to_url = {}
    balls_database = {}

    if os.path.exists(actual_path):
        try:
            wb = openpyxl.load_workbook(actual_path, data_only=False)
            
            intro_sheet = wb['Intro']
            for row in intro_sheet.iter_rows(min_row=1, max_row=100, values_only=True):
                for col in range(len(row) - 1):
                    url = get_url(row[col])
                    if url:
                        name = str(row[col+1]).replace('"', '').strip()
                        if 'ball' in name.lower():
                            key = to_key(name)
                            url_to_key[url] = key
                            key_to_url[key] = url

            url_to_key['https://i.imgur.com/eru43o1.png'] = 'strange_ball'
            key_to_url['strange_ball'] = 'https://i.imgur.com/eru43o1.png'
            url_to_key['https://i.imgur.com/aeqHLEh.png'] = 'cherish_ball'
            key_to_url['cherish_ball'] = 'https://i.imgur.com/aeqHLEh.png'

            for sheet_name in wb.sheetnames:
                if sheet_name in ['Intro', 'Vivillon', 'Alcremie']: continue
                sheet = wb[sheet_name]
                rows = list(sheet.iter_rows(values_only=True))
                
                for r in range(0, len(rows), 7):
                    if r >= len(rows): break
                    row_0 = rows[r]
                    for col in range(len(row_0) - 1):
                        id_val = str(row_0[col] or '').strip()
                        id_match = re.sub(r'[^0-9]', '', id_val)
                        if not id_match: continue
                        
                        poke_id = int(id_match)
                        name_str = str(row_0[col+1] or '').replace('*', '').strip()
                        form = get_form(name_str)
                        unique_id = f"{poke_id}_{form}".replace("'", "")
                        
                        normal_balls, shiny_balls = [], []
                        for offset in [1, 2, 3]:
                            if r + offset < len(rows) and col < len(rows[r+offset]):
                                url = get_url(rows[r+offset][col])
                                if url and url in url_to_key and url_to_key[url] not in normal_balls:
                                    normal_balls.append(url_to_key[url])
                        
                        for offset in [4, 5, 6]:
                            if r + offset < len(rows) and col < len(rows[r+offset]):
                                url = get_url(rows[r+offset][col])
                                if url and url in url_to_key and url_to_key[url] not in shiny_balls:
                                    shiny_balls.append(url_to_key[url])
                        
                        norm_str = ",".join(normal_balls) if normal_balls else "any_ball"
                        shin_str = ",".join(shiny_balls) if shiny_balls else "any_ball"
                        balls_database[unique_id] = {'normal': norm_str, 'shiny': shin_str}

            if 'Vivillon' in wb.sheetnames:
                viv_rows = list(wb['Vivillon'].iter_rows(values_only=True))
                viv_forms = ['meadow', 'icy-snow', 'polar', 'tundra', 'continental', 'garden', 'elegant', 'modern', 'marine', 'archipelago', 'high-plains', 'sandstorm', 'river', 'monsoon', 'savanna', 'sun', 'ocean', 'jungle', 'fancy', 'poke-ball']
                
                for r in range(len(viv_rows)):
                    row_data = viv_rows[r]
                    for c_idx in range(len(row_data)):
                        cell_val = str(row_data[c_idx] or '').lower().strip()
                        if not cell_val or len(cell_val) < 3 or 'example' in cell_val or 'note' in cell_val: continue
                        
                        detected = next((v for v in viv_forms if v.replace('-', ' ') in cell_val.replace('-', ' ') or v.replace('-', '') in cell_val.replace('-', '')), None)
                        if detected:
                            unique_id = f"666_{detected}"
                            normal_balls, shiny_balls = [], []
                            for r_offset in range(1, 4):
                                if r + r_offset < len(viv_rows):
                                    for c_offset in [c_idx-1, c_idx, c_idx+1]:
                                        if 0 <= c_offset < len(viv_rows[r + r_offset]):
                                            url = get_url(viv_rows[r + r_offset][c_offset])
                                            if url and url in url_to_key:
                                                if r_offset == 1 and url_to_key[url] not in normal_balls: normal_balls.append(url_to_key[url])
                                                elif r_offset >= 2 and url_to_key[url] not in shiny_balls: shiny_balls.append(url_to_key[url])
                            
                            norm_str = ",".join(normal_balls) if normal_balls else "any_ball"
                            shin_str = ",".join(shiny_balls) if shiny_balls else (norm_str if normal_balls else "any_ball")
                            if normal_balls or unique_id not in balls_database:
                                balls_database[unique_id] = {'normal': norm_str, 'shiny': shin_str}

            if 'Alcremie' in wb.sheetnames:
                alc_rows = list(wb['Alcremie'].iter_rows(values_only=True))
                for r in range(len(alc_rows)):
                    row_data = alc_rows[r]
                    if not row_data or not row_data[0]: continue
                    
                    cell_val = str(row_data[0]).lower().strip()
                    if not cell_val or len(cell_val) < 4 or 'note' in cell_val: continue
                    
                    form = None
                    if 'ruby' in cell_val and 'swirl' in cell_val: form = 'ruby-swirl'
                    elif 'ruby' in cell_val: form = 'ruby-cream'
                    elif 'caramel' in cell_val: form = 'caramel-swirl'
                    elif 'rainbow' in cell_val: form = 'rainbow-swirl'
                    elif 'vanilla' in cell_val: form = 'vanilla-cream'
                    elif 'matcha' in cell_val: form = 'matcha-cream'
                    elif 'mint' in cell_val: form = 'mint-cream'
                    elif 'lemon' in cell_val: form = 'lemon-cream'
                    elif 'salted' in cell_val: form = 'salted-cream'
                    
                    if form:
                        unique_id = f"869_{form}"
                        normal_balls, shiny_balls = [], []
                        
                        for c_idx in range(1, len(row_data)):
                            url = get_url(row_data[c_idx])
                            if url and url in url_to_key and url_to_key[url] not in normal_balls: normal_balls.append(url_to_key[url])
                            
                        if r + 1 < len(alc_rows):
                            for c_idx in range(1, len(alc_rows[r+1])):
                                url = get_url(alc_rows[r+1][c_idx])
                                if url and url in url_to_key and url_to_key[url] not in shiny_balls: shiny_balls.append(url_to_key[url])
                        
                        norm_str = ",".join(normal_balls) if normal_balls else "any_ball"
                        shin_str = ",".join(shiny_balls) if shiny_balls else "any_ball"
                        
                        if normal_balls or unique_id not in balls_database:
                            balls_database[unique_id] = {'normal': norm_str, 'shiny': shin_str}

        except Exception as e:
            print(f"Fehler beim Laden/Parsen der Excel-Datei: {e}")

    if os.path.exists(CUSTOM_JSON_PATH):
        try:
            with open(CUSTOM_JSON_PATH, 'r', encoding='utf-8') as f:
                custom_data = json.load(f)
                for unique_id, data in custom_data.items():
                    norm_str = ",".join(data.get('normal', [])) if data.get('normal') else "any_ball"
                    shin_str = ",".join(data.get('shiny', [])) if data.get('shiny') else "any_ball"
                    balls_database[unique_id] = {'normal': norm_str, 'shiny': shin_str}
        except Exception as e:
            print(f"Fehler beim Laden der Custom JSON: {e}")

    print("\n2. Hole Pokemon Daten (Basis, Formen, Encounters, Speed/Weight)...")
    custom_enc = {}
    if os.path.exists('bin/custom_encounters.json'):
        try:
            with open('bin/custom_encounters.json', 'r', encoding='utf-8') as f:
                custom_enc = json.load(f)
        except Exception as e:
            print(f"Fehler beim Laden von custom_encounters.json: {e}")

    expected_app_uids = set()

    for i in range(1, 1026):
        try:
            species = fetch_json(f"https://pokeapi.co/api/v2/pokemon-species/{i}")
            poke = fetch_json(f"https://pokeapi.co/api/v2/pokemon/{i}")
            if not species or not poke: continue

            has_gender_diff = species.get('has_gender_differences', False)

            name_de = name_en = "Unknown"
            for n in species.get('names', []):
                if n['language']['name'] == 'de': name_de = n['name']
                if n['language']['name'] == 'en': name_en = n['name']
            
            weight = poke.get('weight', 0) / 10.0
            speed = next((s['base_stat'] for s in poke.get('stats', []) if s['stat']['name'] == 'speed'), 0)
            egg_groups = ",".join([eg['name'] for eg in species.get('egg_groups', [])])
            evo_chain_id = int(species['evolution_chain']['url'].strip('/').split('/')[-1]) if species.get('evolution_chain') else -1
            
            tags = []
            if i in [793, 794, 795, 796, 797, 798, 799, 803, 804, 805, 806]: 
                tags.append('ultra_beast')
            if i in [81, 82, 88, 89, 114]: 
                tags.append('fast_ball_gen2')
            if i in [29, 30, 31, 32, 33, 34, 35, 36, 39, 40, 300, 301, 517, 518]: 
                tags.append('moon_ball')
            catch_rate_tags = ",".join(tags)

            c.execute('''INSERT INTO pokemon
                (id, name_de, name_en, has_gender_differences, gender_rate, capture_rate, evolution_chain_id, egg_groups, weight, speed, catch_rate_tags)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                (i, name_de, name_en, 1 if has_gender_diff else 0,
                 species.get('gender_rate', -1), species.get('capture_rate', 255), evo_chain_id, egg_groups, weight, speed, catch_rate_tags))

            varieties = species.get('varieties', [])
            if not varieties:
                expected_app_uids.add(f"{i}_normal")

            for variety in varieties:
                v_poke = fetch_json(variety['pokemon']['url'])
                if not v_poke: continue
                v_id = v_poke.get('id', i)
                
                forms_list = v_poke.get('forms', [])
                if not forms_list:
                    expected_app_uids.add(f"{i}_normal")

                for form_obj in forms_list:
                    f_data = fetch_json(form_obj['url'])
                    if not f_data: continue
                    
                    types = ",".join([t['type']['name'] for t in f_data.get('types', [])] if f_data.get('types') else [t['type']['name'] for t in v_poke.get('types', [])])
                    raw_name = f_data.get('name', '')
                    clean_form = raw_name.replace(species['name'], '').lstrip('-').strip() or 'normal'
                    expected_app_uids.add(f"{i}_{clean_form}")
                    
                    form_type = 'other'
                    min_gen = get_gen_by_id(i)

                    if f_data.get('version_group'):
                        gen_str = VERSION_TO_GEN.get(f_data['version_group']['name'], '').split('_')[-1]
                        if gen_str.isdigit():
                            min_gen = int(gen_str)

                    if clean_form == 'normal': 
                        form_type = 'normal'

                    elif any(x in clean_form for x in ['alola', 'galar', 'hisui', 'paldea']): form_type = 'regional'
                    elif 'mega' in clean_form or 'primal' in clean_form: form_type = 'mega'
                    elif 'gmax' in clean_form: form_type = 'gmax'
                    
                    exclusives = ",".join(FORM_WHITELIST.get(f"{i}_{clean_form}", []))
                    c.execute('''INSERT INTO forms (pokemon_id, name, form_type, min_gen, image_id, types, exclusive_regions)
                                 VALUES (?, ?, ?, ?, ?, ?, ?)''',
                              (i, clean_form, form_type, min_gen, v_id, types, exclusives))

            if has_gender_diff:
                expected_app_uids.add(f"{i}_m")
                expected_app_uids.add(f"{i}_f")

            encounters = fetch_json(f"https://pokeapi.co/api/v2/pokemon/{i}/encounters") or []
            enc_data = {}
            
            if str(i) in custom_enc:
                for gen, vmap in custom_enc[str(i)].items(): enc_data[gen] = vmap
                
            for enc in encounters:
                raw_loc = enc['location_area']['name']
                clean_loc = clean_location(raw_loc)
                
                for v_detail in enc.get('version_details', []):
                    version = v_detail['version']['name']
                    if '-japan' in version: continue
                    gen = VERSION_TO_GEN.get(version, 'gen_unknown')
                    
                    chance_agg = {}
                    for detail in v_detail.get('encounter_details', []):
                        method = detail['method']['name']
                        min_l, max_l = detail['min_level'], detail['max_level']
                        lvl_str = str(min_l) if min_l == max_l else f"{min_l}-{max_l}"
                        key = f"{method}|||{lvl_str}"
                        chance_agg[key] = chance_agg.get(key, 0) + detail['chance']
                        
                    for key, total_chance in chance_agg.items():
                        method, lvl_str = key.split('|||')
                        final_loc = f"{clean_loc}|||{method}|||{lvl_str}|||{total_chance}"
                        
                        if gen not in enc_data: enc_data[gen] = {}
                        if version not in enc_data[gen]: enc_data[gen][version] = []
                        if final_loc not in enc_data[gen][version]: enc_data[gen][version].append(final_loc)

            for gen, vmap in enc_data.items():
                for version, locs in vmap.items():
                    locs_str = "|||||".join(locs)
                    c.execute('INSERT INTO encounters (pokemon_id, gen, version, location_data) VALUES (?, ?, ?, ?)', (i, gen, version, locs_str))

            if species.get('is_legendary'): c.execute('INSERT INTO special_dexes (dex_name, pokemon_id) VALUES (?, ?)', ('legendary-dex', i))
            if species.get('is_mythical'): c.execute('INSERT INTO special_dexes (dex_name, pokemon_id) VALUES (?, ?)', ('mythical-dex', i))
            for eg in species.get('egg_groups', []): c.execute('INSERT INTO special_dexes (dex_name, pokemon_id) VALUES (?, ?)', (f"egg-{eg['name']}", i))
            
            if i % 50 == 0:
                print(f"  ... {i}/1025 bearbeitet")
                conn.commit()
                
        except Exception as e:
            print(f"Fehler bei Pokemon ID {i}: {e}")
            
    conn.commit()

    print("\n3. Führe API Form/Geschlechter-Fallbacks durch...")
    for uid in expected_app_uids:
        if uid not in balls_database or balls_database[uid]['normal'] == "any_ball":
            parts = uid.split('_', 1)
            if not parts[0].isdigit(): continue
            poke_id = int(parts[0])
            
            fallback_data = None
            base_key = f"{poke_id}_normal"
            
            if base_key in balls_database and balls_database[base_key]['normal'] != "any_ball":
                fallback_data = balls_database[base_key]
            else:
                for db_uid, db_data in balls_database.items():
                    if db_uid.startswith(f"{poke_id}_") and db_data['normal'] != "any_ball":
                        fallback_data = db_data
                        break
            
            if fallback_data:
                balls_database[uid] = {'normal': fallback_data['normal'], 'shiny': fallback_data['shiny']}
            else:
                balls_database[uid] = {'normal': 'any_ball', 'shiny': 'any_ball'}

    for poke_id in [493, 773]:
        for type_name, ball_key in TYPE_BALL_MAPPING.items():
            balls_database[f"{poke_id}_{type_name}"] = {'normal': ball_key, 'shiny': ball_key}
            if type_name == 'normal': balls_database[f"{poke_id}_normal"] = {'normal': ball_key, 'shiny': ball_key}

    print("Schreibe Matching Balls in die Datenbank...")
    for key, url in key_to_url.items():
        c.execute("INSERT OR IGNORE INTO ball_urls (ball_name, image_url) VALUES (?, ?)", (key, url))

    for uid, data in balls_database.items():
        c.execute("INSERT OR REPLACE INTO matching_balls (unique_id, normal_balls, shiny_balls) VALUES (?, ?, ?)", (uid, data['normal'], data['shiny']))
    conn.commit()

    print("\n4. Hole Evolutionsketten (1-550)...")
    for i in range(1, 551):
        try:
            chain_data = fetch_json(f"https://pokeapi.co/api/v2/evolution-chain/{i}")
            if chain_data and chain_data.get('chain'):
                parsed_chain = parse_chain(chain_data['chain'])
                c.execute('INSERT INTO evolutions (chain_id, chain_json) VALUES (?, ?)', (i, json.dumps(parsed_chain)))
            if i % 50 == 0: print(f"  ... {i}/550 geprueft")
        except Exception as e:
            print(f"Fehler bei Evolutionskette ID {i}: {e}")
            
    conn.commit()

    print("\n5. Lade Pokedex-Reihenfolgen...")
    try:
        for dex_name, map_key in REGIONAL_ENDPOINTS.items():
            if dex_name in HARDCODED_ORDERS:
                for idx, pid in enumerate(HARDCODED_ORDERS[dex_name]):
                    c.execute('INSERT INTO dex_orders (dex_name, pokemon_id, order_index) VALUES (?, ?, ?)', (map_key, pid, idx))
            else:
                dex_data = fetch_json(f"https://pokeapi.co/api/v2/pokedex/{dex_name}")
                if dex_data and dex_data.get('pokemon_entries'):
                    for idx, entry in enumerate(dex_data['pokemon_entries']):
                        url_parts = entry['pokemon_species']['url'].strip('/').split('/')
                        pid = int(url_parts[-1])
                        c.execute('INSERT INTO dex_orders (dex_name, pokemon_id, order_index) VALUES (?, ?, ?)', (map_key, pid, idx))
                        
        national_max = {'kanto': 151, 'johto': 251, 'hoenn': 386, 'sinnoh': 493, 'unova': 649, 'kalos': 721, 'alola': 809, 'galar': 905, 'paldea': 1025}
        for region, mx in national_max.items():
            for i in range(1, mx + 1):
                c.execute('INSERT INTO dex_orders (dex_name, pokemon_id, order_index) VALUES (?, ?, ?)', (f"{region}_national", i, i-1))
    except Exception as e:
        print(f"Fehler beim Laden der Dex-Reihenfolgen: {e}")

    conn.commit()
    conn.close()
    print("\nFertig! Datenbank 'assets/db/pokedex.sqlite' wurde inkl. Matching Balls erfolgreich erstellt!")

if __name__ == "__main__":
    main()