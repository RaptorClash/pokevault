class DexGroup {
  final String nameKey;
  final List<String> dexKeys;
  final List<int> displayPokemonIds;

  DexGroup({
    required this.nameKey,
    required this.dexKeys,
    required this.displayPokemonIds,
  });
}

class DexGroupsData {
  static final List<DexGroup> groups = [
    DexGroup(
      nameKey: 'group_national',
      dexKeys: ['national_overall'],
      displayPokemonIds: [1, 152, 252, 387],
    ),
    DexGroup(
      nameKey: 'group_kanto',
      dexKeys: ['kanto', 'letsgo-kanto'],
      displayPokemonIds: [1, 4, 7, 25],
    ),
    DexGroup(
      nameKey: 'group_johto',
      dexKeys: ['original-johto', 'updated-johto'],
      displayPokemonIds: [152, 155, 158, 175],
    ),
    DexGroup(
      nameKey: 'group_hoenn',
      dexKeys: ['hoenn', 'updated-hoenn'],
      displayPokemonIds: [252, 255, 258, 280],
    ),
    DexGroup(
      nameKey: 'group_sinnoh',
      dexKeys: ['original-sinnoh', 'extended-sinnoh'],
      displayPokemonIds: [387, 390, 393, 396],
    ),
    DexGroup(
      nameKey: 'group_unova',
      dexKeys: ['original-unova', 'updated-unova'],
      displayPokemonIds: [495, 498, 501, 504],
    ),
    DexGroup(
      nameKey: 'group_kalos',
      dexKeys: ['kalos-central', 'kalos-coastal', 'kalos-mountain'],
      displayPokemonIds: [650, 653, 656, 659],
    ),
    DexGroup(
      nameKey: 'group_alola',
      dexKeys: [
        'original-alola',
        'updated-alola',
        'original-melemele',
        'original-akala',
        'original-ulaula',
        'original-poni',
        'updated-melemele',
        'updated-akala',
        'updated-ulaula',
        'updated-poni',
      ],
      displayPokemonIds: [722, 725, 728, 731],
    ),
    DexGroup(
      nameKey: 'group_galar',
      dexKeys: ['galar', 'isle-of-armor', 'crown-tundra'],
      displayPokemonIds: [810, 813, 816, 821],
    ),
    DexGroup(
      nameKey: 'group_hisui',
      dexKeys: ['hisui'],
      displayPokemonIds: [722, 155, 501, 899],
    ),
    DexGroup(
      nameKey: 'group_paldea',
      dexKeys: ['paldea', 'kitakami', 'blueberry'],
      displayPokemonIds: [906, 909, 912, 915],
    ),
    DexGroup(
      nameKey: 'group_lumiose',
      dexKeys: ['lumiose', 'lumiose-dimensions'],
      displayPokemonIds: [650, 653, 656, 150],
    ),
    DexGroup(
      nameKey: 'group_special',
      dexKeys: ['mega-dex', 'icognito-dex'],
      displayPokemonIds: [3, 6, 9, 201],
    ),
  ];

  static Map<String, bool> getAvailableFeatures(String dexKey) {
    return {
      'regional': [
        'alola',
        'updated-alola',
        'galar',
        'isle-of-armor',
        'crown-tundra',
        'hisui',
        'paldea',
        'kitakami',
        'blueberry',
        'national_overall',
      ].contains(dexKey),
      'mega': [
        'kalos-central',
        'kalos-coastal',
        'kalos-mountain',
        'hoenn',
        'updated-hoenn',
        'lumiose',
        'lumiose-dimensions',
        'national_overall',
        'mega-dex',
        'letsgo-kanto',
      ].contains(dexKey),
      'gmax': [
        'galar',
        'isle-of-armor',
        'crown-tundra',
        'national_overall',
      ].contains(dexKey),
      'other': true,
    };
  }
}
