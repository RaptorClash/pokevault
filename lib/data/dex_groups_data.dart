import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';

class DexGroup {
  final String nameKey;
  final List<int> displayPokemonIds;
  final List<String> dexKeys;

  DexGroup(this.nameKey, this.displayPokemonIds, this.dexKeys);
}

class DexGroupsData {
  static final List<DexGroup> groups = [
    DexGroup('group_national', [151, 251, 385, 493], ['national_overall']),
    DexGroup('group_kanto', [3, 6, 9, 25], ['kanto_regional', 'letsgo_kanto_regional']),
    DexGroup('group_johto', [250, 249, 245, 251], ['johto_regional', 'updated_johto_regional']),
    DexGroup('group_hoenn', [382, 383, 384, 386], ['hoenn_regional', 'updated_hoenn_regional']),
    DexGroup('group_sinnoh', [483, 484, 487, 448], ['sinnoh_regional', 'extended_sinnoh_regional']),
    DexGroup('group_unova', [643, 644, 646, 494], ['unova_regional', 'updated_unova_regional']),
    DexGroup(
      'group_kalos',
      [716, 717, 718, 719],
      ['kalos_central_regional', 'kalos_coastal_regional', 'kalos_mountain_regional', 'lumiose_regional', 'lumiose_dimensions_regional'],
    ),
    DexGroup(
      'group_alola',
      [791, 792, 800, 773],
      ['alola_regional', 'melemele_regional', 'akala_regional', 'ulaula_regional', 'poni_regional', 'updated_alola_regional', 'updated_melemele_regional', 'updated_akala_regional', 'updated_ulaula_regional', 'updated_poni_regional'],
    ),
    DexGroup(
      'group_galar',
      [888, 889, 890, 493],
      ['galar_regional', 'isle_of_armor_regional', 'crown_tundra_regional', 'hisui_regional'],
    ),
    DexGroup('group_paldea', [1007, 1008, 1017, 1024], ['paldea_regional', 'kitakami_regional', 'blueberry_regional']),
    DexGroup('region_special_dex', [150, 201, 719, 448], ['mega_dex', 'icognito_dex'])
  ];

  static Map<String, bool> getAvailableFeatures(String dexKey) {
    try {
      if (dexKey == 'national_overall') return {'regional': true, 'mega': true, 'gmax': true};
      if (dexKey == 'letsgo_kanto_regional') return {'regional': true, 'mega': true, 'gmax': false};
      if (dexKey == 'updated_hoenn_regional') return {'regional': false, 'mega': true, 'gmax': false};
      if (dexKey.contains('kalos') || dexKey.contains('lumiose')) return {'regional': false, 'mega': true, 'gmax': false};
      if (dexKey.contains('alola') || dexKey.contains('melemele') || dexKey.contains('akala') || dexKey.contains('ulaula') || dexKey.contains('poni')) return {'regional': true, 'mega': true, 'gmax': false};
      if (dexKey.contains('galar') || dexKey.contains('armor') || dexKey.contains('tundra')) return {'regional': true, 'mega': false, 'gmax': true};
      if (dexKey.contains('hisui') || dexKey.contains('paldea') || dexKey.contains('kitakami') || dexKey.contains('blueberry')) return {'regional': true, 'mega': false, 'gmax': false};
      if (dexKey == 'mega_dex') return {'regional': false, 'mega': true, 'gmax': false};
      if (dexKey == 'icognito_dex') return {'regional': false, 'mega': false, 'gmax': false};
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_getting_available_features')} $e");
    }
    return {'regional': false, 'mega': false, 'gmax': false};
  }
}