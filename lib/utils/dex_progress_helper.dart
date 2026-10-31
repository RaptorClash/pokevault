import 'package:flutter/material.dart';
import '../models/dex_progress_models.dart';
import '../models/dex_view_models.dart';
import '../models/user_dex.dart';
import 'dex_logic_helper.dart';
import 'isolate_translator.dart';

/// Helper for calculating detailed completion statistics, generation breakdowns,
/// type coverage, and variant distributions for a Pokédex.
class DexProgressHelper {
  static const Map<String, Color> typeColors = {
    'normal': Color(0xFFA8A77A),
    'fire': Color(0xFFEE8130),
    'water': Color(0xFF6390F0),
    'electric': Color(0xFFF7D02C),
    'grass': Color(0xFF7AC74C),
    'ice': Color(0xFF96D9D6),
    'fighting': Color(0xFFC22E28),
    'poison': Color(0xFFA33EA1),
    'ground': Color(0xFFE2BF65),
    'flying': Color(0xFFA98FF3),
    'psychic': Color(0xFFF95587),
    'bug': Color(0xFFA6B91A),
    'rock': Color(0xFFB6A136),
    'ghost': Color(0xFF735797),
    'dragon': Color(0xFF6F35FC),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB7B7CE),
    'fairy': Color(0xFFD685AD),
  };

  static const List<String> canonicalTypes = [
    'normal',
    'fire',
    'water',
    'electric',
    'grass',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  ];

  static const Map<String, String> typeNamesDe = {
    'normal': 'Normal',
    'fire': 'Feuer',
    'water': 'Wasser',
    'electric': 'Elektro',
    'grass': 'Pflanze',
    'ice': 'Eis',
    'fighting': 'Kampf',
    'poison': 'Gift',
    'ground': 'Boden',
    'flying': 'Flug',
    'psychic': 'Psycho',
    'bug': 'Käfer',
    'rock': 'Gestein',
    'ghost': 'Geist',
    'dragon': 'Drache',
    'dark': 'Unlicht',
    'steel': 'Stahl',
    'fairy': 'Fee',
  };

  static const Map<String, String> typeNamesEn = {
    'normal': 'Normal',
    'fire': 'Fire',
    'water': 'Water',
    'electric': 'Electric',
    'grass': 'Grass',
    'ice': 'Ice',
    'fighting': 'Fighting',
    'poison': 'Poison',
    'ground': 'Ground',
    'flying': 'Flying',
    'psychic': 'Psychic',
    'bug': 'Bug',
    'rock': 'Rock',
    'ghost': 'Ghost',
    'dragon': 'Dragon',
    'dark': 'Dark',
    'steel': 'Steel',
    'fairy': 'Fairy',
  };

  static const Map<int, ({String key, String nameDe, String nameEn, String subtitle, Color color, int minId, int maxId})>
      generations = {
    1: (
      key: 'gen_1',
      nameDe: 'Gen 1: Kanto',
      nameEn: 'Gen 1: Kanto',
      subtitle: '(#001 - #151)',
      color: Color(0xFFEF5350),
      minId: 1,
      maxId: 151,
    ),
    2: (
      key: 'gen_2',
      nameDe: 'Gen 2: Johto',
      nameEn: 'Gen 2: Johto',
      subtitle: '(#152 - #251)',
      color: Color(0xFFFFB300),
      minId: 152,
      maxId: 251,
    ),
    3: (
      key: 'gen_3',
      nameDe: 'Gen 3: Hoenn',
      nameEn: 'Gen 3: Hoenn',
      subtitle: '(#252 - #386)',
      color: Color(0xFF42A5F5),
      minId: 252,
      maxId: 386,
    ),
    4: (
      key: 'gen_4',
      nameDe: 'Gen 4: Sinnoh',
      nameEn: 'Gen 4: Sinnoh',
      subtitle: '(#387 - #493)',
      color: Color(0xFFAB47BC),
      minId: 387,
      maxId: 493,
    ),
    5: (
      key: 'gen_5',
      nameDe: 'Gen 5: Einall',
      nameEn: 'Gen 5: Unova',
      subtitle: '(#494 - #649)',
      color: Color(0xFF78909C),
      minId: 494,
      maxId: 649,
    ),
    6: (
      key: 'gen_6',
      nameDe: 'Gen 6: Kalos',
      nameEn: 'Gen 6: Kalos',
      subtitle: '(#650 - #721)',
      color: Color(0xFF26A69A),
      minId: 650,
      maxId: 721,
    ),
    7: (
      key: 'gen_7',
      nameDe: 'Gen 7: Alola',
      nameEn: 'Gen 7: Alola',
      subtitle: '(#722 - #809)',
      color: Color(0xFFFF7043),
      minId: 722,
      maxId: 809,
    ),
    8: (
      key: 'gen_8',
      nameDe: 'Gen 8: Galar',
      nameEn: 'Gen 8: Galar',
      subtitle: '(#810 - #905)',
      color: Color(0xFF5C6BC0),
      minId: 810,
      maxId: 905,
    ),
    9: (
      key: 'gen_9',
      nameDe: 'Gen 9: Paldea',
      nameEn: 'Gen 9: Paldea',
      subtitle: '(#906 - #1025)',
      color: Color(0xFFEC407A),
      minId: 906,
      maxId: 1025,
    ),
  };

  /// Calculates complete dex statistics.
  static DexProgressStats calculate(
    UserDex dex,
    List<DexDisplayEntry> entries, {
    String language = 'de',
  }) {
    // 1. Filter out placeholder, dummy, or ignored entries
    final validEntries = entries.where((e) {
      if (e.uniqueId.isEmpty) return false;
      if (e.isPlaceholder || DexLogicHelper.isPlaceholder(e.uniqueId)) return false;
      if (e.pokemon.id <= 0) return false;
      if (dex.ignoredIds.contains(e.uniqueId)) return false;
      return true;
    }).toList();

    if (validEntries.isEmpty) {
      return DexProgressStats.empty();
    }

    final totalCount = validEntries.length;
    int caughtCount = 0;
    int shinyCount = 0;
    int alphaCount = 0;

    // Trackers for generations (1..9)
    final genTotals = <int, int>{};
    final genCaughts = <int, int>{};

    // Trackers for types
    final typeTotals = <String, int>{};
    final typeCaughts = <String, int>{};

    // Trackers for variants
    int regularTotal = 0;
    int regularCaught = 0;
    int regionalTotal = 0;
    int regionalCaught = 0;
    int megaTotal = 0;
    int megaCaught = 0;
    int gmaxTotal = 0;
    int gmaxCaught = 0;

    for (final entry in validEntries) {
      final isCaught = DexLogicHelper.isPokemonCaught(dex, entry.uniqueId);
      final isShiny = DexLogicHelper.isPokemonShiny(dex, entry.uniqueId);
      final isAlpha = DexLogicHelper.isPokemonAlpha(dex, entry.uniqueId);

      if (isCaught) caughtCount++;
      if (isShiny) shinyCount++;
      if (isAlpha) alphaCount++;

      // --- Generation resolution ---
      final gen = _resolveGeneration(entry.pokemon.id);
      if (gen != null) {
        genTotals[gen] = (genTotals[gen] ?? 0) + 1;
        if (isCaught) {
          genCaughts[gen] = (genCaughts[gen] ?? 0) + 1;
        }
      }

      // --- Types resolution ---
      final form = entry.resolvedForm;
      final rawTypes = (form != null && form.types.isNotEmpty)
          ? form.types
          : (entry.pokemon.forms.isNotEmpty ? entry.pokemon.forms.first.types : <String>[]);

      for (final type in rawTypes) {
        final cleanType = type.toLowerCase().trim();
        if (cleanType.isNotEmpty) {
          typeTotals[cleanType] = (typeTotals[cleanType] ?? 0) + 1;
          if (isCaught) {
            typeCaughts[cleanType] = (typeCaughts[cleanType] ?? 0) + 1;
          }
        }
      }

      // --- Variant resolution ---
      final formType = (form?.formType ?? 'normal').toLowerCase();
      final formName = (form?.name ?? 'normal').toLowerCase();

      final isRegional = formType == 'regional' ||
          formName.contains('alola') ||
          formName.contains('galar') ||
          formName.contains('hisui') ||
          formName.contains('paldea');
      final isMega = formType == 'mega' || formName.contains('mega');
      final isGmax = formType == 'gmax' || formName.contains('gmax');

      if (isRegional) {
        regionalTotal++;
        if (isCaught) regionalCaught++;
      } else if (isMega) {
        megaTotal++;
        if (isCaught) megaCaught++;
      } else if (isGmax) {
        gmaxTotal++;
        if (isCaught) gmaxCaught++;
      } else {
        regularTotal++;
        if (isCaught) regularCaught++;
      }
    }

    // --- Build Generation Items (only those present in dex) ---
    final generationStats = <ProgressItem>[];
    for (int g = 1; g <= 9; g++) {
      final total = genTotals[g] ?? 0;
      if (total > 0) {
        final caught = genCaughts[g] ?? 0;
        final info = generations[g]!;
        final name = language == 'de' ? info.nameDe : info.nameEn;
        generationStats.add(
          ProgressItem.create(
            key: info.key,
            name: name,
            subtitle: info.subtitle,
            caught: caught,
            total: total,
            color: info.color,
          ),
        );
      }
    }

    // --- Build Type Items (only those present in dex, in canonical order) ---
    final typeStats = <ProgressItem>[];
    for (final type in canonicalTypes) {
      final total = typeTotals[type] ?? 0;
      if (total > 0) {
        final caught = typeCaughts[type] ?? 0;
        final name = language == 'de'
            ? (typeNamesDe[type] ?? type)
            : (typeNamesEn[type] ?? type);
        typeStats.add(
          ProgressItem.create(
            key: type,
            name: name,
            caught: caught,
            total: total,
            color: typeColors[type] ?? const Color(0xFFA8A77A),
          ),
        );
      }
    }

    // --- Build Variant Items ---
    final variantStats = <ProgressItem>[];

    if (regularTotal > 0) {
      variantStats.add(
        ProgressItem.create(
          key: 'regular',
          name: _translate('variant_regular', language),
          caught: regularCaught,
          total: regularTotal,
          color: const Color(0xFF10B981),
        ),
      );
    }

    if (regionalTotal > 0) {
      variantStats.add(
        ProgressItem.create(
          key: 'regional',
          name: _translate('variant_regional', language),
          caught: regionalCaught,
          total: regionalTotal,
          color: const Color(0xFF0284C7),
        ),
      );
    }

    if (megaTotal > 0) {
      variantStats.add(
        ProgressItem.create(
          key: 'mega',
          name: _translate('variant_mega', language),
          caught: megaCaught,
          total: megaTotal,
          color: const Color(0xFF9333EA),
        ),
      );
    }

    if (gmaxTotal > 0) {
      variantStats.add(
        ProgressItem.create(
          key: 'gmax',
          name: _translate('variant_gmax', language),
          caught: gmaxCaught,
          total: gmaxTotal,
          color: const Color(0xFFE11D48),
        ),
      );
    }

    // Shiny collection across current Dex entries
    variantStats.add(
      ProgressItem.create(
        key: 'shiny',
        name: _translate('variant_shinies', language),
        caught: shinyCount,
        total: totalCount,
        color: const Color(0xFFF59E0B),
      ),
    );

    // Alpha collection across current Dex entries
    variantStats.add(
      ProgressItem.create(
        key: 'alpha',
        name: _translate('variant_alpha', language),
        caught: alphaCount,
        total: totalCount,
        color: const Color(0xFFEF4444),
      ),
    );

    final overallPercentage = (caughtCount / totalCount) * 100.0;

    return DexProgressStats(
      totalCount: totalCount,
      caughtCount: caughtCount,
      percentage: overallPercentage,
      shinyCount: shinyCount,
      alphaCount: alphaCount,
      generationStats: generationStats,
      typeStats: typeStats,
      variantStats: variantStats,
    );
  }

  static int? _resolveGeneration(int id) {
    if (id >= 1 && id <= 151) return 1;
    if (id >= 152 && id <= 251) return 2;
    if (id >= 252 && id <= 386) return 3;
    if (id >= 387 && id <= 493) return 4;
    if (id >= 494 && id <= 649) return 5;
    if (id >= 650 && id <= 721) return 6;
    if (id >= 722 && id <= 809) return 7;
    if (id >= 810 && id <= 905) return 8;
    if (id >= 906 && id <= 1025) return 9;
    if (id > 1025) return 9;
    return null;
  }

  static String _translate(String key, String language) {
    return IsolateTranslator(language).get(key);
  }
}
