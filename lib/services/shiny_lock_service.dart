import '../models/dex_view_models.dart';
import 'database_service.dart';

/// Service to determine whether a Pokémon, form, or special encounter is shiny-locked.
class ShinyLockService {
  /// Known global shiny locks that can never be obtained shiny in any mainline game.
  static const Set<int> _globalLockIds = {
    494,  // Victini
    720,  // Hoopa
    789,  // Cosmog
    790,  // Cosmovum
    801,  // Magearna
    802,  // Marshadow
    891,  // Dakuma (Kubfu)
    892,  // Wulaosu (Urshifu)
    893,  // Zarude
    896,  // Polaross (Glastrier)
    897,  // Phantoross (Spectrier)
    898,  // Coronospa (Calyrex)
    1009, // Windewoge (Walking Wake)
    1010, // Eisenblatt (Iron Leaves)
    1014, // Boninu (Okidogi)
    1015, // Benesaru (Munkidori)
    1016, // Beatori (Fezandipiti)
    1017, // Ogerpon
    1020, // Keilflamme (Gouging Fire)
    1021, // Furienblitz (Raging Bolt)
    1022, // Eisenfels (Iron Boulder)
    1023, // Eisenhaupt (Iron Crown)
    1024, // Terapagos
    1025, // Infamomo (Pecharunt)
  };

  /// Known special obtainable IDs representing N's Pokémon from Pokémon Black 2 / White 2.
  static const Set<int> nPokemonSpecialIds = {
    325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338, 339,
  };

  /// Cosplay Pikachu forms introduced in ORAS (100% shiny-locked).
  static const Set<String> _cosplayPikachuForms = {
    'cosplay',
    'rock-star',
    'rockstar',
    'rock_star',
    'belle',
    'pop-star',
    'popstar',
    'pop_star',
    'phd',
    'libre',
  };

  /// Checks whether [formName] or [uniqueId] represents a Cosplay Pikachu form.
  static bool isCosplayPikachuForm(String? formName, [String? uniqueId]) {
    final fn = formName?.toLowerCase();
    if (fn != null && _cosplayPikachuForms.contains(fn)) return true;
    if (uniqueId != null) {
      final uidLower = uniqueId.toLowerCase();
      if (_cosplayPikachuForms.any((f) => uidLower.contains(f))) return true;
    }
    return false;
  }

  static final Set<int> _dynamicNPokemonSpecialIds = {...nPokemonSpecialIds};

  /// Asynchronously refreshes the dynamic set of N's Pokémon special IDs from the database.
  static Future<void> refreshDynamicLocks() async {
    try {
      final db = await DatabaseService.instance.appDatabase;
      final rows = await db.query(
        'special_obtainable',
        columns: ['id'],
        where: 'is_n_pokemon = 1',
      );
      for (var row in rows) {
        final id = (row['id'] as num?)?.toInt();
        if (id != null) {
          _dynamicNPokemonSpecialIds.add(id);
        }
      }
    } catch (_) {}
  }

  /// Checks whether [uniqueId] represents an N's Pokémon instance from B2W2.
  static bool isNPokemonId(String uniqueId) {
    if (uniqueId.isEmpty) return false;
    final cleanId = uniqueId.split('__').first.toLowerCase();

    // Guard: Unown (ID 201) has form 'n' ('201_n'), which is NOT N's Pokémon and can be shiny.
    if (cleanId == '201_n' ||
        cleanId.startsWith('201_n_') ||
        (cleanId.startsWith('201_') && !cleanId.contains('_special_'))) {
      return false;
    }

    // Explicit category / token check
    if (cleanId.contains('_n_pokemon') || cleanId == 'n_pokemon') {
      return true;
    }

    // Special obtainables: '${p.id}_special_${sId}_${specType}_${specRegion}_$specForm'
    // where specType is 'n' (producing '_special_${sId}_n_' or '_n_')
    if (cleanId.contains('_special_')) {
      if (cleanId.contains('_n_') ||
          cleanId.contains('_spec_n_') ||
          cleanId.contains('_special_n_')) {
        return true;
      }

      // Check if uniqueId contains a special obtainable ID known to be N's Pokémon
      final specialMatch = RegExp(r'_special_(\d+)').firstMatch(cleanId);
      if (specialMatch != null) {
        final sId = int.tryParse(specialMatch.group(1)!);
        if (sId != null && _dynamicNPokemonSpecialIds.contains(sId)) {
          return true;
        }
      }
      return false;
    }

    // Standalone uniqueIds with '_n_' (e.g. '509_n_unova')
    if (cleanId.contains('_n_')) {
      return true;
    }

    return false;
  }

  /// Checks whether [entry] represents N's Pokémon from B2W2.
  static bool isNPokemon(DexDisplayEntry entry) {
    if (entry.pokemon.id == 201) return false;

    if (isNPokemonId(entry.uniqueId)) {
      return true;
    }

    final suffixLower = entry.displaySuffix.toLowerCase();
    if (suffixLower.contains("n's pokémon") ||
        suffixLower.contains("n's pokemon") ||
        suffixLower.contains("ns pokémon") ||
        suffixLower.contains("ns pokemon")) {
      return true;
    }

    return false;
  }

  /// Checks whether [entry] represents an in-game trade with fixed DVs/PIDs.
  static bool isTradeLocked(DexDisplayEntry entry) {
    if (!entry.uniqueId.contains('_special_') || !entry.uniqueId.contains('_trade_')) {
      return false;
    }
    // Let's Go Alolan trades CAN be hunted shiny
    final uidLower = entry.uniqueId.toLowerCase();
    final suffixLower = entry.displaySuffix.toLowerCase();
    if (uidLower.contains('_trade_kanto_alola') ||
        suffixLower.contains("let's go") ||
        suffixLower.contains("lets go")) {
      return false;
    }
    return true;
  }

  /// Checks if [entry] is shiny-locked globally, by edition, or by in-game trade.
  static bool isShinyLocked(DexDisplayEntry entry, {String? dexRegion}) {
    final pid = entry.pokemon.id;
    final formName = entry.resolvedForm?.name.toLowerCase() ?? 'normal';
    final uidLower = entry.uniqueId.toLowerCase();

    // 1. Global locks by ID
    if (_globalLockIds.contains(pid)) return true;

    // 2. N's Pokémon (Black 2 / White 2 fixed DVs/PID, 100% shiny-locked)
    if (isNPokemon(entry)) return true;

    // 2. Specific form global locks
    if (pid == 658 && (formName == 'ash' || uidLower.contains('ash'))) {
      return true; // Ash-Greninja
    }
    if (pid == 670 && (formName.contains('eternal') || uidLower.contains('eternal') || uidLower.contains('ewig'))) {
      return true; // Eternal Floette
    }
    if (pid == 901 && (formName.contains('bloodmoon') || uidLower.contains('bloodmoon') || uidLower.contains('blutmond'))) {
      return true; // Bloodmoon Ursaluna
    }
    if (formName.contains('totem') || uidLower.contains('totem')) {
      return true; // Herrscher / Totem forms
    }
    if (pid == 25 && (formName.contains('cap') || uidLower.contains('cap'))) {
      if (formName == 'partner-cap' || uidLower.contains('partner-cap') || uidLower.contains('partner_cap')) {
        if (dexRegion != null) {
          final reg = dexRegion.toLowerCase();
          final isUsum = reg.contains('updated') || reg.contains('usum') || reg.contains('ultra');
          final isNational = reg.contains('national');
          if (!isUsum && !isNational) {
            return true;
          }
        }
        return false;
      }
      return true;
    }
    if (pid == 25 && isCosplayPikachuForm(formName, uidLower)) {
      return true; // Cosplay Pikachu (ORAS 100% shiny-locked)
    }
    if ((pid == 25 || pid == 133) &&
        (formName == 'starter' || uidLower.contains('starter'))) {
      return true; // Starter Pikachu / Starter Eevee (Let's Go 100% shiny-locked)
    }

    // 3. In-Game Trades (fixed DVs, except Let's Go)
    if (isTradeLocked(entry)) {
      return true;
    }

    // 4. Edition locks based on dex region
    if (dexRegion != null) {
      final reg = dexRegion.toLowerCase();
      // Gen 6 ORAS
      if ((reg.contains('hoenn') || reg.contains('omega') || reg.contains('alpha')) &&
          (pid == 382 || pid == 383 || pid == 384 || pid == 386)) {
        return true; // Kyogre, Groudon, Rayquaza, Deoxys in ORAS
      }
      // Gen 7 Sun/Moon
      if (reg.contains('alola') &&
          (pid >= 785 && pid <= 800)) {
        // Tapus, Cosmog line, Solgaleo/Lunala, UBs, Necrozma
        return true;
      }
      // Gen 8 SwSh
      if (reg.contains('galar') &&
          (pid == 888 || pid == 889 || pid == 890)) {
        return true; // Zacian, Zamazenta, Eternatus
      }
      // Gen 9 SV
      if (reg.contains('paldea') &&
          (pid == 1007 || pid == 1008 || (pid >= 1001 && pid <= 1004))) {
        return true; // Koraidon, Miraidon, Treasures of Ruin
      }
      // Gen 9.5 Legends Z-A
      if ((reg.contains('lumiose') || reg.contains('za') || reg.contains('z-a')) && pid == 719) {
        return true; // Diancie in PLZA
      }
    }

    return false;
  }

  /// Checks whether a Pokémon instance identified by [uniqueId] is shiny-locked.
  static bool isUniqueIdShinyLocked(String uniqueId, {String? dexRegion}) {
    final cleanId = uniqueId.split('__').first;

    // Check N's Pokémon
    if (isNPokemonId(cleanId)) return true;

    final parts = cleanId.split('_');
    final pid = int.tryParse(parts.first) ?? -1;
    if (pid == -1) return false;

    if (_globalLockIds.contains(pid)) return true;

    final uidLower = cleanId.toLowerCase();
    if (pid == 658 && uidLower.contains('ash')) return true;
    if (pid == 670 && (uidLower.contains('eternal') || uidLower.contains('ewig'))) return true;
    if (pid == 901 && (uidLower.contains('bloodmoon') || uidLower.contains('blutmond'))) return true;
    if (uidLower.contains('totem')) return true;
    if (pid == 25 && uidLower.contains('cap')) {
      if (uidLower.contains('partner-cap') || uidLower.contains('partner_cap')) {
        if (dexRegion != null) {
          final reg = dexRegion.toLowerCase();
          final isUsum = reg.contains('updated') || reg.contains('usum') || reg.contains('ultra');
          final isNational = reg.contains('national');
          if (!isUsum && !isNational) {
            return true;
          }
        }
        return false;
      }
      return true;
    }
    if (pid == 25) {
      if (isCosplayPikachuForm(null, uidLower)) {
        return true;
      }
      if (uidLower.contains('starter')) {
        return true;
      }
    }
    if (pid == 133 && uidLower.contains('starter')) {
      return true;
    }

    if (uidLower.contains('_special_') && uidLower.contains('_trade_')) {
      if (!uidLower.contains('_trade_kanto_alola')) {
        return true;
      }
    }

    if (dexRegion != null) {
      final reg = dexRegion.toLowerCase();
      if ((reg.contains('hoenn') || reg.contains('omega') || reg.contains('alpha')) &&
          (pid == 382 || pid == 383 || pid == 384 || pid == 386)) {
        return true;
      }
      if (reg.contains('alola') && (pid >= 785 && pid <= 800)) {
        return true;
      }
      if (reg.contains('galar') && (pid == 888 || pid == 889 || pid == 890)) {
        return true;
      }
      if (reg.contains('paldea') && (pid == 1007 || pid == 1008 || (pid >= 1001 && pid <= 1004))) {
        return true;
      }
      if ((reg.contains('lumiose') || reg.contains('za') || reg.contains('z-a')) && pid == 719) {
        return true;
      }
    }

    return false;
  }

  /// Asynchronous check against the offline reference SQLite database `shiny_locks`.
  static Future<bool> isShinyLockedAsync(DexDisplayEntry entry, {String? gameVersion}) async {
    if (isShinyLocked(entry)) return true;

    // Check database for special obtainable with is_n_pokemon == 1
    if (entry.uniqueId.contains('_special_')) {
      final match = RegExp(r'_special_(\d+)').firstMatch(entry.uniqueId);
      if (match != null) {
        final sId = int.tryParse(match.group(1)!);
        if (sId != null) {
          if (_dynamicNPokemonSpecialIds.contains(sId)) return true;
          try {
            final db = await DatabaseService.instance.appDatabase;
            final rows = await db.query(
              'special_obtainable',
              columns: ['is_n_pokemon'],
              where: 'id = ?',
              whereArgs: [sId],
              limit: 1,
            );
            if (rows.isNotEmpty && (rows.first['is_n_pokemon'] as num?)?.toInt() == 1) {
              _dynamicNPokemonSpecialIds.add(sId);
              return true;
            }
          } catch (_) {}
        }
      }
    }

    try {
      final locks = await DatabaseService.instance.getShinyLocks(entry.pokemon.id);
      if (locks.isEmpty) return false;

      final formName = entry.resolvedForm?.name.toLowerCase() ?? 'normal';
      for (var lock in locks) {
        final lockForm = lock['form_name']?.toString().toLowerCase() ?? 'normal';
        if (lockForm != 'all' && lockForm != formName) continue;

        final lockType = lock['lock_type']?.toString();
        if (lockType == 'global') return true;

        if (gameVersion != null) {
          final gv = lock['game_version']?.toString().toLowerCase() ?? '';
          if (gv == 'all' || gv.contains(gameVersion.toLowerCase())) {
            return true;
          }
        }
      }
    } catch (_) {}

    return false;
  }

  /// Returns a user-friendly explanatory reason for why the shiny toggle is locked.
  static String getShinyLockReason(
    DexDisplayEntry entry, {
    String? dexRegion,
    String lang = 'de',
  }) {
    if (isNPokemon(entry)) {
      return lang == 'de'
          ? "Shiny-Lock: N's Pokémon in Pokémon Schwarz 2 / Weiß 2 sind shiny-locked und können nie schillernd sein."
          : "Shiny-Lock: N's Pokémon in Pokémon Black 2 / White 2 are shiny-locked and can never be shiny.";
    }

    if (isTradeLocked(entry)) {
      return lang == 'de'
          ? 'In-Game Tausch: Dieses Pokémon besitzt feste Statuswerte und kann nicht schillernd sein.'
          : 'In-game trade: This Pokémon has fixed stats and cannot be shiny.';
    }

    if (entry.uniqueId.toLowerCase().contains('totem') ||
        (entry.resolvedForm?.name.toLowerCase().contains('totem') ?? false)) {
      return lang == 'de'
          ? 'Shiny-Lock: Herrscher-Pokémon (Totem) können nicht schillernd erhalten werden.'
          : 'Shiny-Lock: Totem Pokémon cannot be obtained shiny.';
    }

    if (entry.pokemon.id == 25 &&
        ((entry.resolvedForm?.name.toLowerCase().contains('cap') ?? false) ||
            entry.uniqueId.toLowerCase().contains('cap'))) {
      return lang == 'de'
          ? 'Shiny-Lock: Pikachu mit Kappe kann nicht schillernd erhalten werden (außer Partner-Kappe in USUM).'
          : 'Shiny-Lock: Cap Pikachu cannot be obtained shiny (except Partner Cap in USUM).';
    }

    if (entry.pokemon.id == 25 &&
        isCosplayPikachuForm(entry.resolvedForm?.name, entry.uniqueId)) {
      return lang == 'de'
          ? 'Shiny-Lock: Cosplay-Pikachu kann nicht schillernd erhalten werden.'
          : 'Shiny-Lock: Cosplay Pikachu cannot be obtained shiny.';
    }

    if ((entry.pokemon.id == 25 || entry.pokemon.id == 133) &&
        (entry.resolvedForm?.name.toLowerCase() == 'starter' ||
            entry.uniqueId.toLowerCase().contains('starter'))) {
      return lang == 'de'
          ? "Shiny-Lock: Starter-Pikachu und Starter-Evoli in Let's Go können nicht schillernd sein."
          : "Shiny-Lock: Starter Pikachu and Starter Eevee in Let's Go cannot be shiny.";
    }

    if (_globalLockIds.contains(entry.pokemon.id) ||
        (entry.pokemon.id == 901 && entry.uniqueId.contains('bloodmoon'))) {
      return lang == 'de'
          ? 'Shiny-Lock: Dieses Pokémon kann bisher in keinem Spiel regulär schillernd erhalten werden.'
          : 'Shiny-Lock: This Pokémon cannot be obtained shiny in any game yet.';
    }

    return lang == 'de'
        ? 'Shiny-Lock: An dieser Fundstelle oder in diesem Spiel ist das Pokémon gesperrt.'
        : 'Shiny-Lock: This Pokémon is locked in this encounter or version.';
  }
}
