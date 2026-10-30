import '../services/database_service.dart';
import '../models/pokemon.dart';
import '../models/dex_view_models.dart';

/// Provides game-specific shiny hunting mechanics, soft-reset button shortcuts,
/// breeding eligibility checks, and evolutionary path traversal.
class ShinyLogicHelper {
  /// Checks whether [entry] represents the Partner Cap Pikachu form.
  static bool isPartnerCapPikachu(DexDisplayEntry entry) {
    if (entry.pokemon.id != 25) return false;
    final formName = entry.resolvedForm?.name.toLowerCase() ?? '';
    final uid = entry.uniqueId.toLowerCase();
    return formName == 'partner-cap' ||
        uid.contains('partner-cap') ||
        uid.contains('partner_cap');
  }

  /// Checks whether [entry] represents any Cap Pikachu form.
  static bool isAnyCapPikachu(DexDisplayEntry entry) {
    if (entry.pokemon.id != 25) return false;
    final formName = entry.resolvedForm?.name.toLowerCase() ?? '';
    final uid = entry.uniqueId.toLowerCase();
    return formName.contains('cap') || uid.contains('cap');
  }

  /// Returns an explanatory note for Partner Cap Pikachu shiny appearance and recognition.
  static String getPartnerCapShinyNote({String lang = 'de'}) {
    return lang == 'de'
        ? 'Hinweis: Das schillernde Partner-Kappe Pikachu besitzt exakt dieselben Sprite-Farben wie die reguläre Form. Es ist ausschließlich am schillernden Stern im Bericht sowie an der Stern-Animation beim Rauslassen / Betreten des Kampfes zu erkennen.'
        : 'Note: Shiny Partner Cap Pikachu has identical sprite colors as regular Pikachu. It is only distinguishable by the shiny star on the summary screen and the sparkle animation when entering battle / sent out.';
  }
  /// Determines whether a Pokémon encounter in a given generation is stationary or a gift.
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

    if (gen == 'gen_1' && [143, 144, 145, 146, 150].contains(dexId)) {
      return true;
    }
    if (gen == 'gen_2' &&
        [130, 131, 143, 185, 243, 244, 245, 249, 250, 251].contains(dexId)) {
      return true;
    }

    return false;
  }

  /// Returns the hardware button combination used to soft-reset the game in [gen].
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

  /// Checks whether a Pokémon is capable of breeding eggs.
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

  /// Checks whether a Pokémon is classified as a baby species.
  static bool isBaby(int dexId) {
    return [172, 173, 174, 175, 236, 238, 239, 240].contains(dexId);
  }

  /// Resolves the adult stage corresponding to a baby Pokémon species.
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

  /// Traverses backwards through pre-evolutions to find the root evolutionary species.
  static int getBaseForm(int id, Map<int, Map<String, dynamic>> preEvolutions) {
    int curr = id;
    while (preEvolutions.containsKey(curr)) {
      curr = preEvolutions[curr]!['pre'];
    }
    return curr;
  }

  /// Traces the sequence of evolution steps required to reach [targetId] from [baseId].
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

  /// Loads encounter data and regional distribution flags for Generation 8 titles.
  static Future<Map<String, dynamic>> fetchGen8Data(int id) async {
    final encounters = await DatabaseService.instance.getEncounters(id);
    final db = await DatabaseService.instance.appDatabase;

    final hisuiCheck = await db.query(
      'dex_orders',
      columns: ['pokemon_id'],
      where: 'pokemon_id = ? AND dex_name = ?',
      whereArgs: [id, 'hisui_regional'],
      limit: 1,
    );

    final swshCheck = await db.query(
      'dex_orders',
      columns: ['pokemon_id'],
      where: 'pokemon_id = ? AND dex_name IN (?, ?, ?)',
      whereArgs: [
        id,
        'galar_regional',
        'isle_of_armor_regional',
        'crown_tundra_regional',
      ],
      limit: 1,
    );

    return {
      'encounters': encounters,
      'isHisui': hisuiCheck.isNotEmpty,
      'isSwSh': swshCheck.isNotEmpty,
      'isBDSP': id <= 493,
    };
  }

  /// Loads encounter data and regional distribution flags for Generation 9 titles.
  static Future<Map<String, dynamic>> fetchGen9Data(int id) async {
    final encounters = await DatabaseService.instance.getEncounters(id);
    final db = await DatabaseService.instance.appDatabase;

    final svCheck = await db.query(
      'dex_orders',
      columns: ['pokemon_id'],
      where: 'pokemon_id = ? AND dex_name IN (?, ?, ?)',
      whereArgs: [
        id,
        'paldea_regional',
        'kitakami_regional',
        'blueberry_regional',
      ],
      limit: 1,
    );

    final plzaCheck = await db.query(
      'dex_orders',
      columns: ['pokemon_id'],
      where: 'pokemon_id = ? AND dex_name IN (?, ?)',
      whereArgs: [id, 'lumiose_regional', 'lumiose_dimensions_regional'],
      limit: 1,
    );

    return {
      'encounters': encounters,
      'isSV': svCheck.isNotEmpty,
      'isPLZA': plzaCheck.isNotEmpty,
    };
  }
}
