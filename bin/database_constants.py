EXCEL_PATH = 'bin/Legal_Matching_Pokeballs.xlsx'
CUSTOM_JSON_PATH = 'bin/custom_matching_balls.json'
LOCAL_BULBA_PATH = 'bin/List of Ribbons in the games - Bulbapedia, the community-driven Pokémon encyclopedia.html'
LOCAL_POKEWIKI_PATH = 'bin/Liste aller Bänder – PokéWiki.html'
LOCAL_MARKS_PATH = 'bin/Zeichen – PokéWiki.html'

BULBAPEDIA_URL = "https://bulbapedia.bulbagarden.net/wiki/List_of_Ribbons_in_the_games"
POKEWIKI_URL = "https://www.pokewiki.de/Liste_aller_B%C3%A4nder"
POKEWIKI_MARKS_URL = "https://www.pokewiki.de/Zeichen"

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

MARK_DE_TO_EN_ID = {
    "Mittags-Zeichen": "lunchtime-mark", "Mitternachts-Zeichen": "midnight-mark", "Abenddämmerungs-Zeichen": "dusk-mark",
    "Morgendämmerungs-Zeichen": "dawn-mark", "Wolken-Zeichen": "cloudy-mark", "Regen-Zeichen": "rainy-mark",
    "Gewitter-Zeichen": "stormy-mark", "Schneefall-Zeichen": "snowy-mark", "Schneesturm-Zeichen": "blizzard-mark",
    "Dürre-Zeichen": "dry-mark", "Sandsturm-Zeichen": "sandstorm-mark", "Nebel-Zeichen": "misty-mark",
    "Schicksals-Zeichen": "destiny-mark", "Angel-Zeichen": "fishing-mark", "Curry-Zeichen": "curry-mark",
    "Gängigkeits-Zeichen": "uncommon-mark", "Raritäts-Zeichen": "rare-mark", "Raufbold-Zeichen": "rowdy-mark",
    "Sorglos-Zeichen": "absent-minded-mark", "Spannungs-Zeichen": "jittery-mark", "Vorfreude-Zeichen": "excited-mark",
    "Charisma-Zeichen": "charismatic-mark", "Gelassenheits-Zeichen": "calmness-mark", "Hitzkopf-Zeichen": "intense-mark",
    "Achtlos-Zeichen": "zoned-out-mark", "Glücklichkeits-Zeichen": "joyful-mark", "Wut-Zeichen": "angry-mark",
    "Lächel-Zeichen": "smiley-mark", "Trübsal-Zeichen": "teary-mark", "Heiterkeits-Zeichen": "upbeat-mark",
    "Missmut-Zeichen": "peeved-mark", "Verstands-Zeichen": "intellectual-mark", "Impulsiv-Zeichen": "ferocious-mark",
    "Listigkeits-Zeichen": "crafty-mark", "Grimmig-Zeichen": "scowling-mark", "Sanftmut-Zeichen": "kindhearted-mark",
    "Panik-Zeichen": "flustered-mark", "Ansporn-Zeichen": "pumped-up-mark", "Lustlos-Zeichen": "zero-energy-mark",
    "Selbstvertrauens-Zeichen": "prideful-mark", "Selbstzweifel-Zeichen": "unsure-mark", "Arglos-Zeichen": "humble-mark",
    "Scheinheilig-Zeichen": "thorny-mark", "Elan-Zeichen": "vigor-mark", "Formtief-Zeichen": "slump-mark",
    "Riesen-Zeichen": "jumbo-mark", "Winzlings-Zeichen": "teensy-mark", "Aufsammler-Zeichen": "itemfinder-mark",
    "Partner-Zeichen": "partner-mark", "Gourmet-Zeichen": "gourmand-mark", "Elite-Zeichen": "alpha-mark",
    "Titanen-Zeichen": "mightiest-mark", "Herrscher-Zeichen": "titan-mark"
}

GEN1_BASE_STATS = {
    1: [45, 49, 49, 45, 65], 2: [60, 62, 63, 60, 80], 3: [80, 82, 83, 80, 100], 4: [39, 52, 43, 65, 50],
    5: [58, 64, 58, 80, 65], 6: [78, 84, 78, 100, 85], 7: [44, 48, 65, 43, 50], 8: [59, 63, 80, 58, 65],
    9: [79, 83, 100, 78, 85], 10: [45, 30, 35, 45, 20], 11: [50, 20, 55, 30, 25], 12: [60, 45, 50, 70, 80],
    13: [40, 35, 30, 50, 20], 14: [45, 25, 50, 35, 25], 15: [65, 80, 40, 75, 45], 16: [40, 45, 40, 56, 35],
    17: [63, 60, 55, 71, 50], 18: [83, 80, 75, 91, 70], 19: [30, 56, 35, 72, 25], 20: [55, 81, 60, 97, 50],
    21: [40, 60, 30, 70, 31], 22: [65, 90, 65, 100, 61], 23: [35, 60, 44, 55, 40], 24: [60, 85, 69, 80, 65],
    25: [35, 55, 30, 90, 50], 26: [60, 90, 55, 100, 90], 27: [50, 75, 85, 40, 30], 28: [75, 100, 110, 65, 55],
    29: [55, 47, 52, 41, 40], 30: [70, 62, 67, 56, 55], 31: [90, 82, 87, 76, 75], 32: [46, 57, 40, 50, 40],
    33: [61, 72, 57, 65, 55], 34: [81, 92, 77, 85, 85], 35: [70, 45, 48, 35, 60], 36: [95, 70, 73, 60, 85],
    37: [38, 41, 40, 65, 65], 38: [73, 76, 75, 100, 100], 39: [115, 45, 20, 20, 25], 40: [140, 70, 45, 45, 50],
    41: [40, 45, 35, 55, 40], 42: [75, 80, 70, 90, 75], 43: [45, 50, 55, 30, 75], 44: [60, 65, 70, 40, 85],
    45: [75, 80, 85, 50, 100], 46: [35, 70, 55, 25, 55], 47: [60, 95, 80, 30, 80], 48: [60, 55, 50, 45, 40],
    49: [70, 65, 60, 90, 90], 50: [10, 55, 25, 95, 45], 51: [35, 80, 50, 120, 70], 52: [40, 45, 35, 90, 40],
    53: [65, 70, 60, 115, 65], 54: [50, 52, 48, 55, 50], 55: [80, 82, 78, 85, 80], 56: [40, 80, 35, 70, 35],
    57: [65, 105, 60, 95, 60], 58: [55, 70, 45, 60, 50], 59: [90, 110, 80, 95, 80], 60: [40, 50, 40, 90, 40],
    61: [65, 65, 65, 90, 50], 62: [90, 85, 95, 70, 70], 63: [25, 20, 15, 90, 105], 64: [40, 35, 30, 105, 120],
    65: [55, 50, 45, 120, 135], 66: [70, 80, 50, 35, 35], 67: [80, 100, 70, 45, 50], 68: [90, 130, 80, 55, 65],
    69: [50, 75, 35, 40, 70], 70: [65, 90, 50, 55, 85], 71: [80, 105, 65, 70, 100], 72: [40, 40, 35, 70, 100],
    73: [80, 70, 65, 100, 120], 74: [40, 80, 100, 20, 30], 75: [55, 95, 115, 35, 45], 76: [80, 110, 130, 45, 55],
    77: [50, 85, 55, 90, 65], 78: [65, 100, 70, 105, 80], 79: [90, 65, 65, 15, 40], 80: [95, 75, 110, 30, 80],
    81: [25, 35, 70, 45, 95], 82: [50, 60, 95, 70, 120], 83: [52, 65, 55, 60, 58], 84: [35, 85, 45, 75, 35],
    85: [60, 110, 70, 100, 60], 86: [65, 45, 55, 45, 70], 87: [90, 70, 80, 70, 95], 88: [80, 80, 50, 25, 40],
    89: [105, 105, 75, 50, 65], 90: [30, 65, 100, 40, 45], 91: [50, 95, 180, 70, 85], 92: [30, 35, 30, 80, 100],
    93: [45, 50, 45, 95, 115], 94: [60, 65, 60, 110, 130], 95: [35, 45, 160, 70, 30], 96: [60, 48, 45, 42, 90],
    97: [85, 73, 70, 67, 115], 98: [30, 105, 90, 50, 25], 99: [55, 130, 115, 75, 50], 100: [40, 30, 50, 100, 55],
    101: [60, 50, 70, 140, 80], 102: [60, 40, 80, 40, 60], 103: [95, 95, 85, 55, 125], 104: [50, 50, 95, 35, 40],
    105: [60, 80, 110, 45, 50], 106: [50, 120, 53, 87, 35], 107: [50, 105, 79, 76, 35], 108: [90, 55, 75, 30, 60],
    109: [40, 65, 95, 35, 60], 110: [65, 90, 120, 60, 85], 111: [80, 85, 95, 25, 30], 112: [105, 130, 120, 40, 45],
    113: [250, 5, 5, 50, 105], 114: [65, 55, 115, 60, 100], 115: [105, 95, 80, 90, 40], 116: [30, 40, 70, 60, 70],
    117: [55, 65, 95, 85, 95], 118: [45, 67, 60, 63, 50], 119: [80, 92, 65, 68, 80], 120: [30, 45, 55, 85, 70],
    121: [60, 75, 85, 115, 100], 122: [40, 45, 65, 90, 100], 123: [70, 110, 80, 105, 55], 124: [65, 50, 35, 95, 95],
    125: [65, 83, 57, 105, 85], 126: [65, 95, 57, 93, 85], 127: [65, 125, 100, 85, 55], 128: [75, 100, 95, 110, 70],
    129: [20, 10, 55, 80, 20], 130: [95, 125, 79, 81, 100], 131: [130, 85, 80, 60, 95], 132: [48, 48, 48, 48, 48],
    133: [55, 55, 50, 55, 65], 134: [130, 65, 60, 65, 110], 135: [65, 65, 60, 130, 110], 136: [65, 130, 60, 65, 110],
    137: [65, 60, 70, 40, 75], 138: [35, 40, 100, 35, 90], 139: [70, 60, 125, 55, 115], 140: [30, 80, 90, 55, 45],
    141: [60, 115, 105, 80, 65], 142: [80, 105, 65, 130, 60], 143: [160, 110, 65, 30, 65], 144: [90, 85, 100, 85, 125],
    145: [90, 90, 85, 100, 125], 146: [90, 100, 90, 90, 125], 147: [41, 64, 45, 50, 50], 148: [61, 84, 65, 70, 70],
    149: [91, 134, 95, 80, 100], 150: [106, 110, 90, 130, 154], 151: [100, 100, 100, 100, 100],
}

GEN12_PRE_EVOLUTIONS = {
    2: {'pre': 1, 'req': 'Level 16'}, 3: {'pre': 2, 'req': 'Level 32'}, 5: {'pre': 4, 'req': 'Level 16'},
    6: {'pre': 5, 'req': 'Level 36'}, 8: {'pre': 7, 'req': 'Level 16'}, 9: {'pre': 8, 'req': 'Level 36'},
    11: {'pre': 10, 'req': 'Level 7'}, 12: {'pre': 11, 'req': 'Level 10'}, 14: {'pre': 13, 'req': 'Level 7'},
    15: {'pre': 14, 'req': 'Level 10'}, 17: {'pre': 16, 'req': 'Level 18'}, 18: {'pre': 17, 'req': 'Level 36'},
    20: {'pre': 19, 'req': 'Level 20'}, 22: {'pre': 21, 'req': 'Level 20'}, 24: {'pre': 23, 'req': 'Level 22'},
    25: {'pre': 172, 'req': 'Friendship'}, 26: {'pre': 25, 'req': 'Thunder Stone'}, 28: {'pre': 27, 'req': 'Level 22'},
    30: {'pre': 29, 'req': 'Level 16'}, 31: {'pre': 30, 'req': 'Moon Stone'}, 33: {'pre': 32, 'req': 'Level 16'},
    34: {'pre': 33, 'req': 'Moon Stone'}, 35: {'pre': 173, 'req': 'Friendship'}, 36: {'pre': 35, 'req': 'Moon Stone'},
    38: {'pre': 37, 'req': 'Fire Stone'}, 39: {'pre': 174, 'req': 'Friendship'}, 40: {'pre': 39, 'req': 'Moon Stone'},
    42: {'pre': 41, 'req': 'Level 22'}, 169: {'pre': 42, 'req': 'Friendship'}, 44: {'pre': 43, 'req': 'Level 21'},
    45: {'pre': 44, 'req': 'Leaf Stone'}, 182: {'pre': 44, 'req': 'Sun Stone'}, 47: {'pre': 46, 'req': 'Level 24'},
    49: {'pre': 48, 'req': 'Level 31'}, 51: {'pre': 50, 'req': 'Level 26'}, 53: {'pre': 52, 'req': 'Level 28'},
    55: {'pre': 54, 'req': 'Level 33'}, 57: {'pre': 56, 'req': 'Level 28'}, 59: {'pre': 58, 'req': 'Fire Stone'},
    61: {'pre': 60, 'req': 'Level 25'}, 62: {'pre': 61, 'req': 'Water Stone'}, 186: {'pre': 61, 'req': 'Trade w/ King\'s Rock'},
    64: {'pre': 63, 'req': 'Level 16'}, 65: {'pre': 64, 'req': 'Trade'}, 67: {'pre': 66, 'req': 'Level 28'},
    68: {'pre': 67, 'req': 'Trade'}, 70: {'pre': 69, 'req': 'Level 21'}, 71: {'pre': 70, 'req': 'Leaf Stone'},
    73: {'pre': 72, 'req': 'Water Stone'}, 75: {'pre': 74, 'req': 'Level 25'}, 76: {'pre': 75, 'req': 'Trade'},
    78: {'pre': 77, 'req': 'Level 40'}, 80: {'pre': 79, 'req': 'Level 37'}, 199: {'pre': 80, 'req': 'Trade w/ King\'s Rock'},
    82: {'pre': 81, 'req': 'Level 30'}, 85: {'pre': 84, 'req': 'Level 31'}, 87: {'pre': 86, 'req': 'Level 34'},
    89: {'pre': 88, 'req': 'Level 38'}, 91: {'pre': 90, 'req': 'Water Stone'}, 93: {'pre': 92, 'req': 'Level 25'},
    94: {'pre': 93, 'req': 'Trade'}, 97: {'pre': 96, 'req': 'Level 33'}, 99: {'pre': 98, 'req': 'Level 28'},
    101: {'pre': 100, 'req': 'Level 30'}, 103: {'pre': 102, 'req': 'Level 34'}, 105: {'pre': 104, 'req': 'Level 28'},
    106: {'pre': 236, 'req': 'Level 20 (Atk > Def)'}, 107: {'pre': 236, 'req': 'Level 20 (Atk < Def)'}, 237: {'pre': 236, 'req': 'Level 20 (Atk = Def)'},
    110: {'pre': 109, 'req': 'Level 35'}, 112: {'pre': 111, 'req': 'Level 42'}, 113: {'pre': 250, 'req': 'Level 5'},
    114: {'pre': 113, 'req': 'Friendship'}, 117: {'pre': 116, 'req': 'Level 32'}, 230: {'pre': 117, 'req': 'Trade w/ Dragon Scale'},
    119: {'pre': 118, 'req': 'Level 33'}, 121: {'pre': 120, 'req': 'Water Stone'}, 124: {'pre': 238, 'req': 'Level 30'},
    125: {'pre': 239, 'req': 'Level 30'}, 126: {'pre': 240, 'req': 'Level 30'}, 130: {'pre': 129, 'req': 'Level 20'},
    134: {'pre': 133, 'req': 'Water Stone'}, 135: {'pre': 133, 'req': 'Thunder Stone'}, 136: {'pre': 133, 'req': 'Fire Stone'},
    196: {'pre': 133, 'req': 'Friendship (Day)'}, 197: {'pre': 133, 'req': 'Friendship (Night)'}, 233: {'pre': 137, 'req': 'Trade w/ Up-Grade'},
    139: {'pre': 138, 'req': 'Level 40'}, 141: {'pre': 140, 'req': 'Level 40'}, 148: {'pre': 147, 'req': 'Level 30'},
    149: {'pre': 148, 'req': 'Level 55'}, 153: {'pre': 152, 'req': 'Level 16'}, 154: {'pre': 153, 'req': 'Level 32'},
    156: {'pre': 155, 'req': 'Level 14'}, 157: {'pre': 156, 'req': 'Level 36'}, 159: {'pre': 158, 'req': 'Level 18'},
    160: {'pre': 159, 'req': 'Level 30'}, 162: {'pre': 161, 'req': 'Level 15'}, 164: {'pre': 163, 'req': 'Level 20'},
    166: {'pre': 165, 'req': 'Level 18'}, 168: {'pre': 167, 'req': 'Level 22'}, 171: {'pre': 170, 'req': 'Level 27'},
    176: {'pre': 175, 'req': 'Friendship'}, 178: {'pre': 177, 'req': 'Level 25'}, 180: {'pre': 179, 'req': 'Level 15'},
    181: {'pre': 180, 'req': 'Level 30'}, 184: {'pre': 183, 'req': 'Level 18'}, 188: {'pre': 187, 'req': 'Level 18'},
    189: {'pre': 188, 'req': 'Level 27'}, 192: {'pre': 191, 'req': 'Sun Stone'}, 195: {'pre': 194, 'req': 'Level 20'},
    205: {'pre': 204, 'req': 'Level 31'}, 210: {'pre': 209, 'req': 'Level 23'}, 212: {'pre': 123, 'req': 'Trade w/ Metal Coat'},
    217: {'pre': 216, 'req': 'Level 30'}, 219: {'pre': 218, 'req': 'Level 38'}, 221: {'pre': 220, 'req': 'Level 33'},
    224: {'pre': 223, 'req': 'Level 25'}, 229: {'pre': 228, 'req': 'Level 24'}, 232: {'pre': 231, 'req': 'Level 25'},
    242: {'pre': 113, 'req': 'Friendship'}, 247: {'pre': 246, 'req': 'Level 20'}, 248: {'pre': 247, 'req': 'Level 55'},
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