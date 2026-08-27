import '../../../models/pokemon.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../l10n/app_translations.dart';
import '../../../providers/dex_provider.dart';

class BreedingData {
  static Map<int, List<String>> getEggGroups(DexProvider provider) {
    Map<int, List<String>> eggGroups = {};
    for (var p in provider.allPokemon) {
      eggGroups[p.id] = p.eggGroups;
    }
    return eggGroups;
  }

  static String getRealOdds(Pokemon p, String requiredGender) {
    String oddsBase = '1:64';
    if (requiredGender == 'any') return oddsBase;
    if (p.genderRate == 0 || p.genderRate == 8) return oddsBase;

    String totalOdds = '1:128';
    if (p.genderRate == 1) {
      if (requiredGender == 'm') return '~ 1:73';
      return Translator.get('impossible') != 'impossible'
          ? Translator.get('impossible')
          : 'Unmöglich!';
    } else if (p.genderRate == 2) {
      if (requiredGender == 'm') return '~ 1:85';
      return '1:256';
    } else if (p.genderRate == 6) {
      if (requiredGender == 'm') return '1:256';
      return '~ 1:85';
    }
    return totalOdds;
  }

  static List<int> getFullFamily(int id, DexProvider provider) {
    int baseId = ShinyLogicHelper.getBaseForm(id);
    List<int> family = [baseId];

    List<int> stage1 = ShinyLogicHelper.gen12PreEvolutions.entries
        .where((e) => e.value['pre'] == baseId)
        .map((e) => e.key)
        .toList();
    family.addAll(stage1);

    for (int s1 in stage1) {
      List<int> stage2 = ShinyLogicHelper.gen12PreEvolutions.entries
          .where((e) => e.value['pre'] == s1)
          .map((e) => e.key)
          .toList();
      family.addAll(stage2);
    }

    family.removeWhere((fid) {
      final p = provider.allPokemon.where((poke) => poke.id == fid).firstOrNull;
      if (p == null) return true;
      return !ShinyLogicHelper.isBreedable(p);
    });
    family.sort();
    return family;
  }
}
