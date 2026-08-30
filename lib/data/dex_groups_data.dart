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
      dexKeys: ['kanto_regional', 'letsgo_kanto_regional'],
      displayPokemonIds: [1, 4, 7, 25],
    ),
    DexGroup(
      nameKey: 'group_johto',
      dexKeys: ['johto_regional', 'updated_johto_regional'],
      displayPokemonIds: [152, 155, 158, 175],
    ),
    DexGroup(
      nameKey: 'group_hoenn',
      dexKeys: ['hoenn_regional', 'updated_hoenn_regional'],
      displayPokemonIds: [252, 255, 258, 280],
    ),
    DexGroup(
      nameKey: 'group_sinnoh',
      dexKeys: ['sinnoh_regional', 'extended_sinnoh_regional'],
      displayPokemonIds: [387, 390, 393, 396],
    ),
    DexGroup(
      nameKey: 'group_unova',
      dexKeys: ['unova_regional', 'updated_unova_regional'],
      displayPokemonIds: [495, 498, 501, 504],
    ),
    DexGroup(
      nameKey: 'group_kalos',
      dexKeys: [
        'kalos_central_regional',
        'kalos_coastal_regional',
        'kalos_mountain_regional',
        'lumiose_regional',
        'lumiose_dimensions_regional',
      ],
      displayPokemonIds: [650, 653, 656, 659],
    ),
    DexGroup(
      nameKey: 'group_alola',
      dexKeys: [
        'alola_regional',
        'melemele_regional',
        'akala_regional',
        'ulaula_regional',
        'poni_regional',
        'updated_alola_regional',
        'updated_melemele_regional',
        'updated_akala_regional',
        'updated_ulaula_regional',
        'updated_poni_regional',
      ],
      displayPokemonIds: [722, 725, 728, 731],
    ),
    DexGroup(
      nameKey: 'group_galar',
      dexKeys: [
        'galar_regional',
        'isle_of_armor_regional',
        'crown_tundra_regional',
      ],
      displayPokemonIds: [810, 813, 816, 821],
    ),
    DexGroup(
      nameKey: 'group_hisui',
      dexKeys: ['hisui_regional'],
      displayPokemonIds: [722, 155, 501, 899],
    ),
    DexGroup(
      nameKey: 'group_paldea',
      dexKeys: ['paldea_regional', 'kitakami_regional', 'blueberry_regional'],
      displayPokemonIds: [906, 909, 912, 915],
    ),
    DexGroup(
      nameKey: 'group_special',
      dexKeys: ['mega_dex', 'icognito_dex'],
      displayPokemonIds: [3, 6, 9, 201],
    ),
  ];

  static Map<String, bool> getAvailableFeatures(String dexKey) {
    return {
      'regional': [
        'alola_regional',
        'updated_alola_regional',
        'galar_regional',
        'isle_of_armor_regional',
        'crown_tundra_regional',
        'hisui_regional',
        'paldea_regional',
        'kitakami_regional',
        'blueberry_regional',
        'national_overall',
      ].contains(dexKey),
      'mega': [
        'kalos_central_regional',
        'kalos_coastal_regional',
        'kalos_mountain_regional',
        'hoenn_regional',
        'updated_hoenn_regional',
        'lumiose_regional',
        'lumiose_dimensions_regional',
        'national_overall',
        'mega_dex',
        'letsgo_kanto_regional',
      ].contains(dexKey),
      'gmax': [
        'galar_regional',
        'isle_of_armor_regional',
        'crown_tundra_regional',
        'national_overall',
      ].contains(dexKey),
      'other': true,
    };
  }
}
