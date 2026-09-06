import '../services/database_service.dart';
import '../models/pokemon.dart';

class ShinyLogicHelper {
  static Future<bool> isStaticEncounter(int dexId, String gen) async {
    final encounters = await DatabaseService.instance.getEncounters(dexId);
    if (encounters != null && encounters.containsKey(gen)) {
      for (var locs in encounters[gen]!.values) {
        for (var loc in locs) {
          if (loc.contains('(Gift)') ||
              loc.contains('(Starter)') ||
              loc.contains('(Fossil)') ||
              loc.contains('(Fighting Dojo)') ||
              loc.contains('(Stationary)')) {
            return true;
          }
        }
      }
    }

    if (gen == 'gen_1' && [143, 144, 145, 146, 150].contains(dexId))
      return true;
    if (gen == 'gen_2' &&
        [130, 131, 143, 185, 243, 244, 245, 249, 250, 251].contains(dexId))
      return true;

    return false;
  }

  static String getSoftResetCombo(String gen) {
    switch (gen) {
      case 'gen_1':
      case 'gen_2':
      case 'gen_3':
        return 'A + B + Start + Select';
      case 'gen_4':
      case 'gen_5':
      case 'gen_6':
      case 'gen_7':
        return 'L + R + Start + Select';
      case 'gen_8':
      case 'gen_9':
        return 'HOME -> X -> A';
      default:
        return '';
    }
  }

  static bool isBreedable(Pokemon pokemon) {
    bool hasNoEggs = pokemon.eggGroups.any((g) {
      final lower = g.toLowerCase();
      return lower.contains('no-eggs') ||
          lower.contains('undiscovered') ||
          lower.contains('no eggs');
    });

    if (hasNoEggs) return false;

    bool isDitto = pokemon.eggGroups.any(
      (g) => g.toLowerCase().contains('ditto'),
    );
    if (isDitto) return false;

    return true;
  }

  static bool isBaby(int dexId) {
    return [172, 173, 174, 175, 236, 238, 239, 240].contains(dexId);
  }

  static int getAdultForBaby(int babyId) {
    const Map<int, int> babyToAdult = {
      172: 25,
      173: 35,
      174: 39,
      175: 176,
      236: 106,
      238: 124,
      239: 125,
      240: 126,
    };
    return babyToAdult[babyId] ?? babyId;
  }

  static int getBaseForm(int id, Map<int, Map<String, dynamic>> preEvolutions) {
    int curr = id;
    while (preEvolutions.containsKey(curr)) {
      curr = preEvolutions[curr]!['pre'];
    }
    return curr;
  }

  static List<Map<String, dynamic>> getEvolutionPath(
    int baseId,
    int targetId,
    Map<int, Map<String, dynamic>> preEvolutions,
  ) {
    List<int> chain = [];
    int curr = targetId;
    while (curr != baseId && preEvolutions.containsKey(curr)) {
      chain.insert(0, curr);
      curr = preEvolutions[curr]!['pre'];
    }
    List<Map<String, dynamic>> steps = [];
    for (int id in chain) {
      steps.add({
        'from': preEvolutions[id]!['pre'],
        'to': id,
        'req': preEvolutions[id]!['req'],
      });
    }
    return steps;
  }
}
