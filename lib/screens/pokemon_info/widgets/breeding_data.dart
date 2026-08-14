import '../../../data/dex_orders.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../l10n/app_translations.dart';

class BreedingData {
  static final Set<int> genderless = {
    81,
    82,
    100,
    101,
    120,
    121,
    132,
    137,
    201,
    233,
    243,
    244,
    245,
    249,
    250,
    251,
  };
  static final Set<int> onlyMale = {32, 33, 34, 106, 107, 128, 236, 237};
  static final Set<int> onlyFemale = {29, 30, 31, 113, 115, 124, 238, 241, 242};
  static final Set<int> lowFemaleRatio = {
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    133,
    134,
    135,
    136,
    138,
    139,
    140,
    141,
    142,
    143,
    152,
    153,
    154,
    155,
    156,
    157,
    158,
    159,
    160,
    175,
    176,
    196,
    197,
  };
  static final Set<int> ratio75m = {
    58,
    59,
    63,
    64,
    65,
    66,
    67,
    68,
    125,
    126,
    239,
    240,
  };
  static final Set<int> ratio25m = {
    35,
    36,
    37,
    38,
    39,
    40,
    173,
    174,
    209,
    210,
    222,
  };

  static Map<int, List<String>> getEggGroups() {
    Map<int, List<String>> eggGroups = {};
    void addGroups(List<int> ids, String group) {
      for (int id in ids) {
        if (id > 251) continue;
        eggGroups.putIfAbsent(id, () => []).add(group);
      }
    }

    addGroups(ordereggmonster, 'Monster');
    addGroups(ordereggplant, 'Plant');
    addGroups(ordereggdragon, 'Dragon');
    addGroups(ordereggwater1, 'Water 1');
    addGroups(ordereggbug, 'Bug');
    addGroups(ordereggflying, 'Flying');
    addGroups(ordereggground, 'Field');
    addGroups(ordereggfairy, 'Fairy');
    addGroups(orderegghumanshape, 'Human-Like');
    addGroups(ordereggwater3, 'Water 3');
    addGroups(ordereggmineral, 'Mineral');
    addGroups(ordereggindeterminate, 'Amorphous');
    addGroups(ordereggwater2, 'Water 2');
    eggGroups[172] = ['Field', 'Fairy'];
    eggGroups[173] = ['Fairy'];
    eggGroups[174] = ['Fairy'];
    eggGroups[236] = ['Human-Like'];
    eggGroups[238] = ['Human-Like'];
    eggGroups[239] = ['Human-Like'];
    eggGroups[240] = ['Human-Like'];
    return eggGroups;
  }

  static String getRealOdds(int pokeId, String requiredGender) {
    String oddsBase = '1:64';
    if (requiredGender == 'any') return oddsBase;
    int base = ShinyLogicHelper.getBaseForm(pokeId);
    if (onlyMale.contains(base) || onlyFemale.contains(base)) return oddsBase;

    String totalOdds = '1:128';
    if (lowFemaleRatio.contains(base)) {
      if (requiredGender == 'm') return '~ 1:73';
      return Translator.get('impossible') != 'impossible'
          ? Translator.get('impossible')
          : 'Unmöglich!';
    } else if (ratio75m.contains(base)) {
      if (requiredGender == 'm') return '~ 1:85';
      return '1:256';
    } else if (ratio25m.contains(base)) {
      if (requiredGender == 'm') return '1:256';
      return '~ 1:85';
    }
    return totalOdds;
  }

  static List<int> getFullFamily(int id) {
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
    family.removeWhere((fid) => !ShinyLogicHelper.isBreedable(fid));
    family.sort();
    return family;
  }
}
