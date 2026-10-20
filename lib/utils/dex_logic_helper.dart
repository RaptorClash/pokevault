import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../models/dex_view_models.dart';
import '../l10n/app_translations.dart';
import 'notification_helper.dart';
import '../services/database_service.dart';

/// Arguments bundle passed to background isolate for computing display entries.
class BuildEntriesArgs {
  /// The user's Pokédex configuration and status tracking.
  final UserDex liveDex;

  /// The master list of Pokémon definitions.
  final List<Pokemon> pokemonList;

  /// Active application language code (e.g. 'de', 'en').
  final String language;

  /// List of special obtainability entries from database.
  final List<Map<String, dynamic>> specialObtainables;

  /// Creates a [BuildEntriesArgs] isolate payload.
  BuildEntriesArgs(
    this.liveDex,
    this.pokemonList,
    this.language,
    this.specialObtainables,
  );
}

/// Arguments bundle passed to background isolate for generating box layouts.
class GenerateBoxesArgs {
  /// Prepared list of display entries to distribute across boxes.
  final List<DexDisplayEntry> entries;

  /// Whether regional/alternate forms should be placed in distinct boxes.
  final bool separateForms;

  /// The user's Pokédex configuration.
  final UserDex liveDex;

  /// Active application language code.
  final String language;

  /// Creates a [GenerateBoxesArgs] isolate payload.
  GenerateBoxesArgs(
    this.entries,
    this.separateForms,
    this.liveDex,
    this.language,
  );
}

class _ParsedBoxName {
  final String prefix;
  final int? index;
  final String? suffix;
  
  _ParsedBoxName(this.prefix, this.index, this.suffix);
  
  String get groupKey {
    if (suffix != null && !RegExp(r'^\(\s*\d+\s*-\s*\d+\s*\)$').hasMatch(suffix!)) {
      return '$prefix $suffix'.trim();
    }
    return prefix.trim();
  }
}

_ParsedBoxName _parseBoxName(String title) {
  final reg = RegExp(r'^(.*?)(?:\s+(\d+))?(?:\s*(\(.*?\)))?$');
  final match = reg.firstMatch(title);
  if (match != null) {
    String prefix = match.group(1)?.trim() ?? title;
    int? index = match.group(2) != null ? int.tryParse(match.group(2)!) : null;
    String? suffix = match.group(3)?.trim();
    return _ParsedBoxName(prefix, index, suffix);
  }
  return _ParsedBoxName(title, null, null);
}

/// Provides business logic for Pokédex filtering, box layout calculation,
/// caught status resolution, and instance migration.
class DexLogicHelper {
  static final List<int> _useHomeSpritesIds = [
    201,
    412,
    413,
    414,
    421,
    422,
    423,
    493,
    521,
    585,
    586,
    592,
    593,
    649,
    664,
    665,
    666,
    669,
    670,
    671,
    676,
    710,
    711,
    718,
    741,
    773,
    774,
    854,
    855,
    869,
    875,
    876,
    877,
    888,
    889,
    890,
    892,
    893,
    898,
    901,
    902,
    905,
    924,
    925,
    931,
    964,
    977,
    978,
    999,
    1011,
    1012,
    1017,
    1024,
  ];

  /// Asynchronously compiles the display entries for a given Pokédex configuration
  /// on a background isolate, catching and notifying of any errors.
  static Future<List<DexDisplayEntry>> buildEntriesInBackground(
    UserDex liveDex,
    List<Pokemon> pokemonList,
    String language,
    List<Map<String, dynamic>> specialObtainables,
  ) async {
    try {
      return await compute(
        _buildEntriesTask,
        BuildEntriesArgs(liveDex, pokemonList, language, specialObtainables),
      );
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_build_display_entries')} $e",
      );
      return [];
    }
  }

  static List<DexDisplayEntry> _buildEntriesTask(BuildEntriesArgs args) {
    Translator.currentLanguage = args.language;
    return buildDisplayEntries(
      args.liveDex,
      args.pokemonList,
      args.specialObtainables,
    );
  }

  /// Initializes a list of [CustomBoxState] boxes from the given [entries],
  /// assigning unique instance IDs (`__<timestamp>_<index>`) to each item.
  static List<CustomBoxState> initializeCustomBoxesFromEntries(
    UserDex dex,
    List<DexDisplayEntry> entries, {
    int boxCapacity = 30,
    List<BoxData>? boxes,
  }) {
    int c = 0;
    if (boxes != null && boxes.isNotEmpty) {
      return boxes.map((b) => CustomBoxState(
        title: b.title,
        pokemonIds: b.entries.map((e) {
          if (e.uniqueId.isEmpty) return '';
          if (e.uniqueId.contains('__')) return e.uniqueId;
          final instanceId = '${e.uniqueId}__${DateTime.now().millisecondsSinceEpoch}_${c++}';
          if (dex.caughtIds.contains(e.uniqueId) && !dex.caughtIds.contains(instanceId)) {
            dex.caughtIds.add(instanceId);
            DatabaseService.instance.savePokemonStatus(dex.id, instanceId, isCaught: true);
          }
          if (dex.shinyIds.contains(e.uniqueId) && !dex.shinyIds.contains(instanceId)) {
            dex.shinyIds.add(instanceId);
            DatabaseService.instance.savePokemonStatus(dex.id, instanceId, isShiny: true);
          }
          if (dex.alphaIds.contains(e.uniqueId) && !dex.alphaIds.contains(instanceId)) {
            dex.alphaIds.add(instanceId);
            DatabaseService.instance.savePokemonStatus(dex.id, instanceId, isAlpha: true);
          }
          return instanceId;
        }).toList(),
        regionKey: b.regionKey,
        columns: b.crossAxisCount,
        rows: (b.entries.isNotEmpty &&
                b.entries.length % b.crossAxisCount == 0 &&
                b.entries.length ~/ b.crossAxisCount > 0)
            ? b.entries.length ~/ b.crossAxisCount
            : 5,
      )).toList();
    }

    List<CustomBoxState> result = [];
    int boxNumber = 1;
    for (int i = 0; i < entries.length; i += boxCapacity) {
      final chunk = entries.sublist(
        i,
        (i + boxCapacity > entries.length) ? entries.length : i + boxCapacity,
      );
      final pIds = chunk.map((e) {
        if (e.uniqueId.isEmpty) return '';
        if (e.uniqueId.contains('__')) return e.uniqueId;
        final instanceId = '${e.uniqueId}__${DateTime.now().millisecondsSinceEpoch}_${c++}';
        if (dex.caughtIds.contains(e.uniqueId) && !dex.caughtIds.contains(instanceId)) {
          dex.caughtIds.add(instanceId);
          DatabaseService.instance.savePokemonStatus(dex.id, instanceId, isCaught: true);
        }
        if (dex.shinyIds.contains(e.uniqueId) && !dex.shinyIds.contains(instanceId)) {
          dex.shinyIds.add(instanceId);
          DatabaseService.instance.savePokemonStatus(dex.id, instanceId, isShiny: true);
        }
        if (dex.alphaIds.contains(e.uniqueId) && !dex.alphaIds.contains(instanceId)) {
          dex.alphaIds.add(instanceId);
          DatabaseService.instance.savePokemonStatus(dex.id, instanceId, isAlpha: true);
        }
        return instanceId;
      }).toList();
      result.add(CustomBoxState(
        title: 'Box $boxNumber',
        pokemonIds: pIds,
        regionKey: dex.region,
        columns: (boxCapacity == 20) ? 4 : 6,
        rows: 5,
      ));
      boxNumber++;
    }
    return result;
  }

  /// Migrates legacy 30-capacity custom boxes (columns: 5, rows: 6) to standard 6x5 dimensions.
  static bool migrateCustomBoxesDefaultDimensions(UserDex dex) {
    if (dex.customBoxes.isEmpty) return false;
    bool migrated = false;
    for (var box in dex.customBoxes) {
      if (box.columns == 5 && box.rows == 6) {
        box.columns = 6;
        box.rows = 5;
        migrated = true;
      }
    }
    return migrated;
  }

  /// Migrates legacy custom box items to unique composite instance IDs (`__<ts>_<hash>_<idx>`),
  /// preserving existing caught, shiny, and alpha statuses in SQLite.
  static bool migrateCustomBoxInstances(UserDex dex) {
    if (dex.customBoxes.isEmpty) return false;
    bool migrated = migrateCustomBoxesDefaultDimensions(dex);
    for (var box in dex.customBoxes) {
      for (int i = 0; i < box.pokemonIds.length; i++) {
        String id = box.pokemonIds[i];
        if (id.isNotEmpty && !DexLogicHelper.isPlaceholder(id)) {
          String newId = id;
          if (!id.contains('__')) {
            newId = '${id}__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}_$i';
            box.pokemonIds[i] = newId;
            migrated = true;
          }
          final baseId = DexLogicHelper.getBaseId(newId);
          final prefix = '${baseId}__';
          if (dex.caughtIds.contains(baseId) &&
              !dex.caughtIds.any((cid) => cid.startsWith(prefix))) {
            dex.caughtIds.add(newId);
            DatabaseService.instance.savePokemonStatus(dex.id, newId, isCaught: true);
            migrated = true;
          }
          if (dex.shinyIds.contains(baseId) &&
              !dex.shinyIds.any((sid) => sid.startsWith(prefix))) {
            dex.shinyIds.add(newId);
            DatabaseService.instance.savePokemonStatus(dex.id, newId, isShiny: true);
            migrated = true;
          }
          if (dex.alphaIds.contains(baseId) &&
              !dex.alphaIds.any((aid) => aid.startsWith(prefix))) {
            dex.alphaIds.add(newId);
            DatabaseService.instance.savePokemonStatus(dex.id, newId, isAlpha: true);
            migrated = true;
          }
        }
      }
    }
    return migrated;
  }

  /// Prunes in-memory collections of [dex] to remove any duplicate instances
  /// (IDs containing '__') that are not present in [activeUniqueIds].
  static void pruneOrphanedInstances(UserDex dex, Set<String> activeUniqueIds) {
    dex.caughtIds.removeWhere(
        (id) => id.contains('__') && !activeUniqueIds.contains(id));
    dex.shinyIds.removeWhere(
        (id) => id.contains('__') && !activeUniqueIds.contains(id));
    dex.alphaIds.removeWhere(
        (id) => id.contains('__') && !activeUniqueIds.contains(id));
    dex.caughtRibbons.removeWhere(
        (id, _) => id.contains('__') && !activeUniqueIds.contains(id));
    dex.caughtTeraTypes.removeWhere(
        (id, _) => id.contains('__') && !activeUniqueIds.contains(id));
    dex.caughtLanguages.removeWhere(
        (id, _) => id.contains('__') && !activeUniqueIds.contains(id));
  }

  /// Compresses and redistributes Pokémon across sequentially linked boxes when auto-flow is active.
  static void enforceAutoFlow(UserDex dex) {
    if (dex.customBoxes.isEmpty) return;
    
    // Check if autoFlow is enabled globally (stored in first box)
    bool isAutoFlow = dex.customBoxes.first.autoFlow;
    if (!isAutoFlow) return;

    Map<String, List<CustomBoxState>> groups = {};
    for (var box in dex.customBoxes) {
      final parsed = _parseBoxName(box.title);
      groups.putIfAbsent(parsed.groupKey, () => []).add(box);
    }
    
    List<CustomBoxState> newBoxes = [];
    Set<String> processedGroups = {};
    
    for (var originalBox in dex.customBoxes) {
      final parsed = _parseBoxName(originalBox.title);
      final key = parsed.groupKey;
      
      if (processedGroups.contains(key)) continue;
      processedGroups.add(key);
      
      List<CustomBoxState> groupBoxes = groups[key]!;
      List<String> allIds = [];
      for (var b in groupBoxes) {
        allIds.addAll(b.pokemonIds.where((id) => id.isNotEmpty));
      }
      
      bool usesRange = false;
      bool originallyHadIndex = false;
      if (groupBoxes.isNotEmpty) {
        final firstParsed = _parseBoxName(groupBoxes.first.title);
        if (firstParsed.suffix != null && RegExp(r'^\(\s*\d+\s*-\s*\d+\s*\)$').hasMatch(firstParsed.suffix!)) {
          usesRange = true;
        }
        if (firstParsed.index != null) {
          originallyHadIndex = true;
        }
      }
      
      int currentIdIdx = 0;
      int boxIdx = 0;
      
      while (currentIdIdx < allIds.length || boxIdx < groupBoxes.length) {
        CustomBoxState currentBox;
        if (boxIdx < groupBoxes.length) {
          currentBox = groupBoxes[boxIdx];
        } else {
          currentBox = CustomBoxState(
            title: '', // will be set below
            pokemonIds: [],
            columns: groupBoxes.last.columns,
            rows: groupBoxes.last.rows,
            autoFlow: true,
            regionKey: groupBoxes.last.regionKey,
          );
        }
        
        int capacity = currentBox.columns * currentBox.rows;
        int take = capacity;
        if (currentIdIdx + take > allIds.length) {
          take = allIds.length - currentIdIdx;
        }
        
        List<String> newIds = allIds.sublist(currentIdIdx, currentIdIdx + take);
        while (newIds.length < capacity) {
          newIds.add("");
        }
        currentBox.pokemonIds = newIds;
        
        int displayIndex = boxIdx + 1;
        
        if (boxIdx == 0 && currentIdIdx + take >= allIds.length && !usesRange && !originallyHadIndex && groupBoxes.length == 1) {
           currentBox.title = groupBoxes[0].title;
        } else {
           String newTitle = key;
           if (originallyHadIndex || groupBoxes.length > 1 || boxIdx > 0) {
             newTitle += ' $displayIndex';
           }
           
           if (usesRange) {
             int start = currentIdIdx + 1;
             int end = currentIdIdx + capacity;
             newTitle += ' ($start-$end)';
           }
           currentBox.title = newTitle;
        }
        
        newBoxes.add(currentBox);
        currentIdIdx += take;
        boxIdx++;
      }
    }
    
    dex.customBoxes = newBoxes;
  }

  /// Asynchronously generates standard box layouts for given entries on a background isolate.
  static Future<List<BoxData>> generateBoxesInBackground(
    List<DexDisplayEntry> entries,
    bool separateForms,
    UserDex liveDex,
    String language,
  ) async {
    try {
      return await compute(
        _generateBoxesTask,
        GenerateBoxesArgs(entries, separateForms, liveDex, language),
      );
    } catch (e) {
      NotificationHelper.showError("Fehler beim Boxen-Generieren: $e");
      return [];
    }
  }

  static List<BoxData> _generateBoxesTask(GenerateBoxesArgs args) {
    Translator.currentLanguage = args.language;
    return generateBoxes(args.entries, args.separateForms, args.liveDex);
  }

  /// Translates or capitalizes a Pokémon form identifier for localized user display.
  static String getFormDisplayName(String form) {
    try {
      final key = 'form_name_${form.toLowerCase()}';
      final translated = Translator.get(key);
      if (translated != key) return translated;
    } catch (e) {
      debugPrint("Fehler bei Form-Übersetzung: $e");
    }
    return form.isEmpty ? '' : form[0].toUpperCase() + form.substring(1);
  }

  /// Returns the highest Pokémon generation number associated with a Pokédex region.
  static int getMaxGenForDex(String region) {
    if (region.contains('national_overall')) return 99;
    if (region.contains('kanto')) return 1;
    if (region.contains('johto')) return 2;
    if (region.contains('hoenn')) return 3;
    if (region.contains('sinnoh')) return 4;
    if (region.contains('unova')) return 5;
    if (region.contains('kalos') || region.contains('lumiose')) return 6;
    if (region.contains('alola')) return 7;
    if (region.contains('galar') || region.contains('hisui')) return 8;
    return 9;
  }

  static String getRegionFromGame(String gameVer) {
    String g = gameVer.toLowerCase();
    if (g.contains('red') ||
        g.contains('blue') ||
        g.contains('yellow') ||
        g.contains('rot') ||
        g.contains('blau') ||
        g.contains('gelb') ||
        g.contains('feuerrot') ||
        g.contains('blattgrün') ||
        g.contains('let\'s go') ||
        g.contains('pikachu') ||
        g.contains('evoli')) {
      return 'kanto';
    }
    if (g.contains('gold') ||
        g.contains('silver') ||
        g.contains('crystal') ||
        g.contains('silber') ||
        g.contains('kristall') ||
        g.contains('heartgold') ||
        g.contains('soulsilver')) {
      return 'johto';
    }
    if (g.contains('ruby') ||
        g.contains('sapphire') ||
        g.contains('emerald') ||
        g.contains('rubin') ||
        g.contains('saphir') ||
        g.contains('smaragd') ||
        g.contains('omega') ||
        g.contains('alpha') ||
        g.contains('colosseum') ||
        g.contains('xd') ||
        g.contains('gale of darkness')) {
      return 'hoenn';
    }
    if (g.contains('diamond') ||
        g.contains('pearl') ||
        g.contains('platinum') ||
        g.contains('diamant') ||
        g.contains('platin') ||
        g.contains('strahlender') ||
        g.contains('leuchtende')) {
      return 'sinnoh';
    }
    if (g.contains('black') ||
        g.contains('white') ||
        g.contains('schwarz') ||
        g.contains('weiß') ||
        g.contains('weiss')) {
      return 'unova';
    }
    if (g.contains('x') || g.contains('y')) return 'kalos';
    if (g.contains('sun') ||
        g.contains('moon') ||
        g.contains('sonne') ||
        g.contains('mond')) {
      return 'alola';
    }
    if (g.contains('sword') ||
        g.contains('shield') ||
        g.contains('schwert') ||
        g.contains('schild')) {
      return 'galar';
    }
    if (g.contains('arceus') || g.contains('hisui')) return 'hisui';
    if (g.contains('scarlet') ||
        g.contains('violet') ||
        g.contains('karmesin') ||
        g.contains('purpur')) {
      return 'paldea';
    }
    if (g.contains('z-a')) return 'lumiose';
    return 'unknown';
  }

  static String getPokemonRegionId(Pokemon p, PokemonForm? f, UserDex liveDex) {
    if (f != null) {
      if (p.id == 25 && f.name.contains('cap')) return 'kanto';

      if (f.formType == 'gmax') {
        return liveDex.gmaxSort == 'mechanic' ? 'galar' : _getBaseRegion(p.id);
      }

      if (f.formType == 'mega') {
        if (liveDex.megaSort == 'mechanic') {
          List<int> orasMegas = [
            15,
            18,
            80,
            208,
            254,
            302,
            319,
            323,
            334,
            362,
            373,
            376,
            380,
            381,
            384,
            428,
            475,
            531,
            719,
          ];
          return orasMegas.contains(p.id) ? 'hoenn' : 'kalos';
        }
        return _getBaseRegion(p.id);
      }

      if (f.formType == 'regional') {
        if (liveDex.regionalSort == 'origin') return _getBaseRegion(p.id);

        if (f.name.contains('alola') || f.name.contains('totem')) {
          return 'alola';
        }
        if (f.name.contains('galar')) return 'galar';
        if (f.name.contains('hisui')) return 'hisui';
        if (f.name.contains('paldea')) return 'paldea';
      }
    }
    return _getBaseRegion(p.id);
  }

  static String _getBaseRegion(int id) {
    if (id <= 151) return 'kanto';
    if (id <= 251) return 'johto';
    if (id <= 386) return 'hoenn';
    if (id <= 493) return 'sinnoh';
    if (id <= 649) return 'unova';
    if (id <= 721) return 'kalos';
    if (id <= 807) return 'alola';
    if (id <= 809) return 'unknown';
    if (id <= 898) return 'galar';
    if (id <= 905) return 'hisui';
    return 'paldea';
  }

  static String getEntryCategoryId(DexDisplayEntry entry, String region) {
    final id = entry.pokemon.id;
    final uniqueId = getBaseId(entry.uniqueId).toLowerCase();

    if (uniqueId.contains('_special_')) {
      if (uniqueId.contains('_n_')) return 'n_pokemon';
      if (uniqueId.contains('_trade_')) return 'trades';
      if (uniqueId.contains('_colosseum_') || uniqueId.contains('_xd_')) {
        return 'orre';
      }
      if (uniqueId.contains('_gift_')) return 'gifts';
      return 'special';
    }

    bool isNativeReg(String formName) {
      if (region.contains('alola') && formName.contains('alola')) return true;
      if (region.contains('galar') && formName.contains('galar')) return true;
      if (region.contains('hisui') && formName.contains('hisui')) return true;
      if (region.contains('paldea') && formName.contains('paldea')) return true;
      return false;
    }

    bool hasNativeRegional = false;
    for (var f in entry.pokemon.forms) {
      if (f.formType == 'regional' && isNativeReg(f.name.toLowerCase())) {
        hasNativeRegional = true;
        break;
      }
    }

    String formName = uniqueId.contains('_')
        ? uniqueId.substring(uniqueId.indexOf('_') + 1)
        : 'normal';
    bool isBaseForm = false;

    if (hasNativeRegional) {
      if (isNativeReg(formName)) {
        isBaseForm = true;
      }
    } else {
      if (!uniqueId.contains('_')) {
        isBaseForm = true;
      } else {
        if (formName == 'normal' ||
            formName == 'male' ||
            (formName == 'm' && id != 201)) {
          isBaseForm = true;
        } else if (entry.pokemon.forms.isNotEmpty &&
            formName == entry.pokemon.forms.first.name.toLowerCase()) {
          isBaseForm = true;
        }
      }
    }

    if (isBaseForm) return 'base';
    if (id == 25 && uniqueId.contains('cap')) return 'cap';
    if (id == 201) return 'unown';
    if (id == 493) return 'arceus';
    if (id == 666) return 'vivillon';
    if (id == 676) return 'furfrou';
    if (id == 773) return 'silvally';
    if (id == 869) return 'alcremie';

    if ((uniqueId.endsWith('_f') || uniqueId.endsWith('_female')) &&
        id != 201) {
      return 'females';
    }

    if (uniqueId.contains('_')) {
      try {
        final form = entry.pokemon.forms.firstWhere(
          (f) => f.name.toLowerCase() == formName,
        );
        if (form.formType == 'gmax') return 'gmax';
        if (form.formType == 'regional') return 'regional';
        if (form.formType == 'mega') return 'mega';
        if (form.formType == 'normal') return 'alternate';
      } catch (_) {}
    }

    return 'alternate';
  }

  static List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  /// Extracts the base ID from a potentially composite instance ID.
  /// E.g. '1_normal__1728412345_0' -> '1_normal', '1_normal' -> '1_normal',
  /// 'shiny:1_normal' -> '1_normal'.
  static String getBaseId(String uniqueId) {
    if (uniqueId.isEmpty) return '';
    var clean = uniqueId;
    if (clean.startsWith('shiny:')) {
      clean = clean.substring(6);
    }
    final separatorIndex = clean.indexOf('__');
    if (separatorIndex != -1) {
      return clean.substring(0, separatorIndex);
    }
    return clean;
  }

  /// Resolves the matching [PokemonForm] for a given [uniqueId] and [pokemon].
  static PokemonForm? getEntryForm(Pokemon pokemon, String uniqueId) {
    if (pokemon.forms.isEmpty) return null;
    if (pokemon.forms.length == 1) return pokemon.forms.first;

    final baseId = getBaseId(uniqueId);
    if (baseId.contains('_special_')) {
      final parts = baseId.split('_special_')[1].split('_');
      if (parts.isNotEmpty) {
        final formName = parts.last.toLowerCase();
        final matched = pokemon.forms.where(
          (f) => f.name.toLowerCase() == formName,
        ).firstOrNull;
        if (matched != null) return matched;
      }
      return pokemon.forms.first;
    }

    final firstUnderscore = baseId.indexOf('_');
    if (firstUnderscore != -1) {
      final rawFormName = baseId.substring(firstUnderscore + 1).toLowerCase();
      if (rawFormName == 'm' || rawFormName == 'f') {
        return pokemon.forms.firstWhere(
          (f) => f.formType == 'normal',
          orElse: () => pokemon.forms.first,
        );
      }
      final exact = pokemon.forms.where(
        (f) => f.name.toLowerCase() == rawFormName,
      ).firstOrNull;
      if (exact != null) return exact;

      final fuzzy = pokemon.forms.where(
        (f) =>
            f.name.toLowerCase().startsWith(rawFormName) ||
            rawFormName.startsWith(f.name.toLowerCase()),
      ).firstOrNull;
      if (fuzzy != null) return fuzzy;
    }

    return pokemon.forms.firstWhere(
      (f) => f.formType == 'normal',
      orElse: () => pokemon.forms.first,
    );
  }

  /// Centralized check whether a [uniqueId] represents a fixed placeholder slot.
  static bool isPlaceholder(String? uniqueId) {
    if (uniqueId == null || uniqueId.isEmpty) return false;
    var clean = uniqueId;
    if (clean.startsWith('shiny:')) {
      clean = clean.substring(6);
    }
    return clean == 'placeholder' ||
        clean.startsWith('placeholder__') ||
        clean.startsWith('placeholder') ||
        clean == 'empty_placeholder' ||
        clean.startsWith('empty_placeholder');
  }

  /// Standardizes caught evaluation across the entire app by handling both
  /// canonical base IDs (e.g. '1_normal') and custom box instance IDs
  /// (e.g. '1_normal__1728412345_0').
  static bool isPokemonCaught(UserDex dex, String uniqueId) {
    if (uniqueId.isEmpty || isPlaceholder(uniqueId)) return false;
    if (dex.caughtIds.contains(uniqueId)) return true;
    final cleanId = uniqueId.startsWith('shiny:') ? uniqueId.substring(6) : uniqueId;
    if (dex.caughtIds.contains(cleanId)) return true;

    final isComposite = cleanId.contains('__');
    final baseId = getBaseId(cleanId);

    if (!isComposite) {
      final prefix = '${cleanId}__';
      return dex.caughtIds.any((id) => id.startsWith(prefix));
    }

    if (!dex.caughtIds.contains(baseId)) {
      return false;
    }

    // baseId is in caughtIds.
    // If instance-level tracking is active for this baseId (at least one instance is explicitly in caughtIds),
    // then only the instances explicitly in caughtIds are considered caught.
    final prefix = '${baseId}__';
    if (dex.caughtIds.any((id) => id.startsWith(prefix))) {
      return false;
    }

    // If no instance of baseId is explicitly in caughtIds, check customBoxes:
    if (dex.customBoxes.isNotEmpty) {
      final allInstancesOfBase = dex.customBoxes
          .expand((b) => b.pokemonIds)
          .where((id) => !isPlaceholder(id) && getBaseId(id) == baseId)
          .toList();

      if (allInstancesOfBase.isNotEmpty) {
        // The first/primary instance inherits caught status from baseId.
        // Duplicate/subsequent instances in custom boxes remain uncaught.
        return allInstancesOfBase.first == cleanId;
      }
    }

    // Default/standard boxes (or single instance outside customBoxes):
    return true;
  }

  /// Centralized helper to check if a Pokémon is marked as shiny in [dex].
  static bool isPokemonShiny(UserDex dex, String uniqueId) {
    if (uniqueId.isEmpty || isPlaceholder(uniqueId)) return false;
    if (uniqueId.startsWith('shiny:')) return true;
    if (dex.shinyIds.contains(uniqueId)) return true;
    final cleanId = uniqueId.startsWith('shiny:') ? uniqueId.substring(6) : uniqueId;
    if (dex.shinyIds.contains(cleanId)) return true;

    final isComposite = cleanId.contains('__');
    final baseId = getBaseId(cleanId);

    if (!isComposite) {
      final prefix = '${cleanId}__';
      return dex.shinyIds.any((id) => id.startsWith(prefix));
    }

    if (!dex.shinyIds.contains(baseId)) {
      return false;
    }

    final prefix = '${baseId}__';
    if (dex.shinyIds.any((id) => id.startsWith(prefix))) {
      return false;
    }

    if (dex.customBoxes.isNotEmpty) {
      final allInstancesOfBase = dex.customBoxes
          .expand((b) => b.pokemonIds)
          .where((id) => !isPlaceholder(id) && getBaseId(id) == baseId)
          .toList();

      if (allInstancesOfBase.isNotEmpty) {
        return allInstancesOfBase.first == cleanId;
      }
    }

    return true;
  }

  /// Centralized helper to check if a Pokémon is marked as alpha in [dex].
  static bool isPokemonAlpha(UserDex dex, String uniqueId) {
    if (uniqueId.isEmpty || isPlaceholder(uniqueId)) return false;
    if (dex.alphaIds.contains(uniqueId)) return true;
    final cleanId = uniqueId.startsWith('shiny:') ? uniqueId.substring(6) : uniqueId;
    if (dex.alphaIds.contains(cleanId)) return true;

    final isComposite = cleanId.contains('__');
    final baseId = getBaseId(cleanId);

    if (!isComposite) {
      final prefix = '${cleanId}__';
      return dex.alphaIds.any((id) => id.startsWith(prefix));
    }

    if (!dex.alphaIds.contains(baseId)) {
      return false;
    }

    final prefix = '${baseId}__';
    if (dex.alphaIds.any((id) => id.startsWith(prefix))) {
      return false;
    }

    if (dex.customBoxes.isNotEmpty) {
      final allInstancesOfBase = dex.customBoxes
          .expand((b) => b.pokemonIds)
          .where((id) => !isPlaceholder(id) && getBaseId(id) == baseId)
          .toList();

      if (allInstancesOfBase.isNotEmpty) {
        return allInstancesOfBase.first == cleanId;
      }
    }

    return true;
  }

  /// Ensures that if [baseId] is caught in [dex] (in legacy format without instance-level IDs),
  /// the existing primary instance in [dex.customBoxes] is explicitly recorded in [caughtIds]
  /// (and [shinyIds], [alphaIds]) before a new instance of [baseId] is inserted.
  static void ensurePrimaryInstancePersisted(UserDex dex, String baseId, [DatabaseService? databaseService]) {
    if (dex.customBoxes.isEmpty || baseId.isEmpty) return;
    final allInstances = dex.customBoxes
        .expand((b) => b.pokemonIds)
        .where((id) => !isPlaceholder(id) && getBaseId(id) == baseId)
        .toList();
    if (allInstances.isEmpty) return;
    final primary = allInstances.first;
    final prefix = '${baseId}__';
    final db = databaseService ?? DatabaseService.instance;

    if (dex.caughtIds.contains(baseId) && !dex.caughtIds.any((id) => id.startsWith(prefix))) {
      if (!dex.caughtIds.contains(primary)) {
        dex.caughtIds.add(primary);
        try {
          db.savePokemonStatus(dex.id, primary, isCaught: true).catchError((_) {});
        } catch (_) {}
      }
    }
    if (dex.shinyIds.contains(baseId) && !dex.shinyIds.any((id) => id.startsWith(prefix))) {
      if (!dex.shinyIds.contains(primary)) {
        dex.shinyIds.add(primary);
        try {
          db.savePokemonStatus(dex.id, primary, isShiny: true).catchError((_) {});
        } catch (_) {}
      }
    }
    if (dex.alphaIds.contains(baseId) && !dex.alphaIds.any((id) => id.startsWith(prefix))) {
      if (!dex.alphaIds.contains(primary)) {
        dex.alphaIds.add(primary);
        try {
          db.savePokemonStatus(dex.id, primary, isAlpha: true).catchError((_) {});
        } catch (_) {}
      }
    }
  }

  /// Returns the total count of caught Pokémon in [dex].
  /// Accurately counts caught box slots if custom boxes exist, or caught unique species.
  static int getCaughtCount(UserDex dex) {
    if (dex.customBoxes.isNotEmpty) {
      return dex.customBoxes
          .expand((b) => b.pokemonIds)
          .where((id) =>
              id.isNotEmpty &&
              !isPlaceholder(id) &&
              !dex.ignoredIds.contains(id) &&
              !dex.ignoredIds.contains(getBaseId(id)) &&
              isPokemonCaught(dex, id))
          .length;
    }
    return dex.caughtIds
        .map((id) => getBaseId(id))
        .where((id) =>
            id.isNotEmpty &&
            !isPlaceholder(id) &&
            !dex.ignoredIds.contains(id))
        .toSet()
        .length;
  }

  /// Groups [entries] into a list of [BoxData] representations,
  /// honoring custom box configurations or falling back to standard regional bucketing.
  static List<BoxData> generateBoxes(
    List<DexDisplayEntry> entries,
    bool separateForms,
    UserDex liveDex,
  ) {
    if (liveDex.customBoxes.isNotEmpty) {
      List<BoxData> customBoxesList = [];
      for (var cb in liveDex.customBoxes) {
        List<DexDisplayEntry> boxEntries = [];
        for (var id in cb.pokemonIds) {
          if (id.isEmpty) {
            boxEntries.add(DexDisplayEntry.emptyEntry);
          } else if (isPlaceholder(id)) {
            boxEntries.add(DexDisplayEntry.placeholderEntry(id));
          } else {
            try {
              final baseId = getBaseId(id);
              final originalEntry = entries.firstWhere((e) => e.uniqueId == baseId);
              final isShiny = isPokemonShiny(liveDex, id);
              String imgUrl = originalEntry.imageUrl;
              if (isShiny && !imgUrl.contains('/shiny/')) {
                if (imgUrl.contains('official-artwork/')) {
                  imgUrl = imgUrl.replaceFirst('official-artwork/', 'official-artwork/shiny/');
                } else if (imgUrl.contains('home/female/')) {
                  imgUrl = imgUrl.replaceFirst('home/female/', 'home/shiny/female/');
                } else if (imgUrl.contains('home/')) {
                  imgUrl = imgUrl.replaceFirst('home/', 'home/shiny/');
                }
              } else if (!isShiny && imgUrl.contains('/shiny/')) {
                if (imgUrl.contains('/shiny/female/')) {
                  imgUrl = imgUrl.replaceFirst('/shiny/female/', '/female/');
                } else {
                  imgUrl = imgUrl.replaceFirst('/shiny/', '/');
                }
              }
              boxEntries.add(DexDisplayEntry(
                pokemon: originalEntry.pokemon,
                uniqueId: id,
                displaySuffix: originalEntry.displaySuffix,
                imageUrl: imgUrl,
                form: originalEntry.form,
              ));
            } catch (_) {
              boxEntries.add(DexDisplayEntry.emptyEntry);
            }
          }
        }
        
        int capacity = cb.columns * cb.rows;
        while (boxEntries.length < capacity) {
          boxEntries.add(DexDisplayEntry.emptyEntry);
        }
        
        customBoxesList.add(BoxData(cb.title, cb.regionKey, boxEntries, cb.columns));
      }
      return customBoxesList;
    }

    List<BoxData> boxes = [];
    bool isOriginalKantoJohto =
        liveDex.region == 'kanto_regional' ||
        liveDex.region == 'johto_regional';
    int capacity = isOriginalKantoJohto ? 20 : 30;
    int crossAxis = isOriginalKantoJohto ? 4 : 6;

    if (!separateForms) {
      List<DexDisplayEntry> baseEntries = [];
      List<DexDisplayEntry> formEntries = [];
      for (var entry in entries) {
        if (getEntryCategoryId(entry, liveDex.region) == 'base') {
          baseEntries.add(entry);
        } else {
          formEntries.add(entry);
        }
      }
      List<List<DexDisplayEntry>> baseChunks = chunkList(baseEntries, capacity);
      for (int i = 0; i < baseChunks.length; i++) {
        int start = i * capacity + 1;
        int end = start + baseChunks[i].length - 1;
        boxes.add(
          BoxData(
            '${Translator.get('box')} ${i + 1} ($start-$end)',
            'kanto',
            baseChunks[i],
            crossAxis,
          ),
        );
      }
      if (formEntries.isNotEmpty) {
        List<List<DexDisplayEntry>> formChunks = chunkList(
          formEntries,
          capacity,
        );
        int boxOffset = baseChunks.length;
        String formLabel = Translator.currentLanguage == 'de'
            ? 'Formen'
            : 'Forms';
        for (int i = 0; i < formChunks.length; i++) {
          String title = formChunks.length == 1
              ? '${Translator.get('box')} ${boxOffset + i + 1} ($formLabel)'
              : '${Translator.get('box')} ${boxOffset + i + 1} ($formLabel ${i + 1})';
          boxes.add(BoxData(title, 'kanto', formChunks[i], crossAxis));
        }
      }
    } else {
      List<String> regionOrder = [
        'kanto',
        'johto',
        'hoenn',
        'sinnoh',
        'unova',
        'kalos',
        'alola',
        'unknown',
        'galar',
        'hisui',
        'paldea',
        'lumiose',
      ];
      Map<String, Map<String, List<DexDisplayEntry>>> structured = {};

      for (var entry in entries) {
        PokemonForm? form = entry.resolvedForm;
        String regionId = getPokemonRegionId(entry.pokemon, form, liveDex);

        if (entry.uniqueId.contains('_special_')) {
          final parts = entry.uniqueId.split('_special_')[1].split('_');
          if (parts.length >= 3) {
            regionId = parts[2];
          }
        }

        String catId = getEntryCategoryId(entry, liveDex.region);
        structured.putIfAbsent(regionId, () => {});
        structured[regionId]!.putIfAbsent(catId, () => []).add(entry);
      }

      List<String> presentRegions = structured.keys.toList();
      presentRegions.sort((a, b) {
        int indexA = regionOrder.indexOf(a);
        int indexB = regionOrder.indexOf(b);
        if (indexA == -1) indexA = 99;
        if (indexB == -1) indexB = 99;
        return indexA.compareTo(indexB);
      });

      for (String regionId in presentRegions) {
        var cats = structured[regionId]!;
        String localizedRegion = Translator.get('region_name_$regionId');
        if (localizedRegion == 'region_name_$regionId') {
          localizedRegion = regionId[0].toUpperCase() + regionId.substring(1);
        }

        void buildChunks(String catId) {
          if (!cats.containsKey(catId)) return;
          List<List<DexDisplayEntry>> chunks = chunkList(
            cats[catId]!,
            capacity,
          );
          for (int i = 0; i < chunks.length; i++) {
            String baseTitle;
            String localizedCat = Translator.get('cat_$catId');
            if (localizedCat == 'cat_$catId') localizedCat = catId;

            if (catId == 'n_pokemon') {
              baseTitle = "N's Pokémon";
            } else if (catId == 'trades') {
              baseTitle =
                  "$localizedRegion ${Translator.currentLanguage == 'de' ? 'Tausche' : 'Trades'}";
            } else if (catId == 'gifts') {
              baseTitle =
                  "$localizedRegion ${Translator.currentLanguage == 'de' ? 'Geschenke' : 'Gifts'}";
            } else if (catId == 'orre') {
              baseTitle = "$localizedRegion ${Translator.get('cat_orre')}";
            } else if (catId == 'arceus') {
              baseTitle = "$localizedRegion Arceus";
            } else if (catId == 'silvally') {
              baseTitle =
                  "$localizedRegion ${Translator.currentLanguage == 'de' ? 'Amigento' : 'Silvally'}";
            } else {
              baseTitle = (catId == 'base')
                  ? localizedRegion
                  : '$localizedRegion $localizedCat';
            }
            String title = chunks.length == 1
                ? baseTitle
                : '$baseTitle ${i + 1}';
            boxes.add(BoxData(title, regionId, chunks[i], crossAxis));
          }
        }

        List<String> strictCategoryOrder = [
          'base',
          'females',
          'regional',
          'mega',
          'gmax',
          'cap',
          'unown',
          'arceus',
          'vivillon',
          'furfrou',
          'silvally',
          'alcremie',
          'alternate',
          'trades',
          'gifts',
          'n_pokemon',
          'orre',
          'special',
        ];

        for (String catId in strictCategoryOrder) {
          buildChunks(catId);
        }

        for (String catId in cats.keys) {
          if (!strictCategoryOrder.contains(catId)) {
            buildChunks(catId);
          }
        }
      }
    }
    return boxes;
  }

  /// Constructs the flat list of [DexDisplayEntry] items for the current [liveDex],
  /// including base Pokémon, enabled regional/cosmetic forms, and special obtainables.
  static List<DexDisplayEntry> buildDisplayEntries(
    UserDex liveDex,
    List<Pokemon> pokemonList,
    List<Map<String, dynamic>> specialObtainables,
  ) {
    List<DexDisplayEntry> entries = [];
    int dexGen = getMaxGenForDex(liveDex.region);
    bool isNationalDex = liveDex.region == 'national_overall';
    bool isMegaDex = liveDex.region == 'mega_dex';
    bool isIcognitoDex = liveDex.region == 'icognito_dex';
    String shinyPath = liveDex.isShinyDex ? 'shiny/' : '';
    bool isMovesDex = liveDex.region == 'moves_dex';
    bool isAbilitiesDex = liveDex.region == 'abilities_dex';

    if (isMovesDex || isAbilitiesDex) {
      return [];
    }

    bool isNativeRegionalForm(PokemonForm f, String region) {
      if (f.formType != 'regional') return false;
      if (region.contains('alola') && f.name.contains('alola')) return true;
      if (region.contains('galar') && f.name.contains('galar')) return true;
      if (region.contains('hisui') && f.name.contains('hisui')) return true;
      if (region.contains('paldea') && f.name.contains('paldea')) return true;
      return false;
    }

    for (var p in pokemonList) {
      if (p.forms.isNotEmpty) {
        var sortedForms = List.of(p.forms);
        sortedForms.sort((a, b) {
          if (p.id == 718) {
            int wA = a.name.contains('10')
                ? 0
                : (a.name.contains('50') || a.name == 'normal' ? 1 : 2);
            int wB = b.name.contains('10')
                ? 0
                : (b.name.contains('50') || b.name == 'normal' ? 1 : 2);
            if (wA != wB) return wA.compareTo(wB);
          }
          int getWeight(PokemonForm form) {
            if (isNativeRegionalForm(form, liveDex.region)) return -1;
            if (form.formType == 'normal') return 0;
            if (form.formType == 'regional') return 1;
            if (form.formType == 'other') return 2;
            if (form.formType == 'mega') return 3;
            if (form.formType == 'gmax') return 4;
            return 5;
          }

          return getWeight(a).compareTo(getWeight(b));
        });

        bool hasExplicitGenderForms = p.forms.any(
          (f) => f.name == 'male' || f.name == 'female',
        );

        for (var form in sortedForms) {
          bool isBaseForm =
              form.name == 'normal' || p.forms.first.name == form.name;
          if ((p.id == 1007 || p.id == 1008 || p.id == 664 || p.id == 665) &&
              !isBaseForm) {
            continue;
          }
          if (isMegaDex && form.formType != 'mega') continue;

          bool isNativeRegional = isNativeRegionalForm(form, liveDex.region);
          if (form.formType == 'normal' &&
              !liveDex.includeRegional &&
              !isMegaDex) {
            bool hasNativeRegional = p.forms.any(
              (f) => isNativeRegionalForm(f, liveDex.region),
            );
            if (hasNativeRegional) continue;
          }

          if (form.formType == 'regional' &&
              !liveDex.includeRegional &&
              !isNativeRegional) {
            continue;
          }
          if (form.formType == 'mega' && !liveDex.includeMega && !isMegaDex) {
            continue;
          }
          if (form.formType == 'gmax' && !liveDex.includeGMax) continue;
          if (form.formType == 'other' &&
              !liveDex.includeOther &&
              !isIcognitoDex) {
            if (!isBaseForm) continue;
          }

          bool isWhitelistedForThisDex = form.exclusiveRegions.contains(
            liveDex.region,
          );
          if (form.exclusiveRegions.isNotEmpty &&
              !isNationalDex &&
              !isWhitelistedForThisDex) {
            continue;
          }

          if (!isNationalDex &&
              !isWhitelistedForThisDex &&
              form.minGen > dexGen &&
              !isMegaDex &&
              !isIcognitoDex) {
            continue;
          }

          bool hideSuffix = form.name == 'normal';
          String suffix = hideSuffix
              ? ''
              : ' (${getFormDisplayName(form.name)})';
          if (form.name == 'male' || form.name == 'female') {
            suffix = form.name == 'male' ? ' ♂' : ' ♀';
          }

          String specificImageUrl;
          if (_useHomeSpritesIds.contains(p.id) &&
              !hideSuffix &&
              form.name != 'normal') {
            String formSuffix = '';
            if (!isBaseForm || isIcognitoDex) {
              formSuffix = '-${form.name}';
              if (p.id == 774 && form.name.contains('meteor')) {
                formSuffix = '-meteor';
              }
              if (p.id == 718 && form.name.contains('10')) formSuffix = '-10';
              if (p.id == 718 && form.name.contains('complete')) {
                formSuffix = '-complete';
              }
              if (p.id == 201 && form.name == 'a') formSuffix = '';
            }
            specificImageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyPath${p.id}$formSuffix.png';
          } else {
            specificImageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath${form.imageId}.png';
          }

          if (form.formType == 'normal' &&
              liveDex.includeGenders &&
              p.hasGenderDifferences &&
              !hasExplicitGenderForms) {
            String homeFemalePath = liveDex.isShinyDex
                ? 'shiny/female'
                : 'female';
            entries.add(
              DexDisplayEntry(
                pokemon: p,
                uniqueId: '${p.id}_m',
                displaySuffix: ' ♂',
                imageUrl:
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath${p.id}.png',
                form: form,
              ),
            );
            entries.add(
              DexDisplayEntry(
                pokemon: p,
                uniqueId: '${p.id}_f',
                displaySuffix: ' ♀',
                imageUrl:
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$homeFemalePath/${p.id}.png',
                form: form,
              ),
            );
          } else {
            entries.add(
              DexDisplayEntry(
                pokemon: p,
                uniqueId: '${p.id}_${form.name}',
                displaySuffix: suffix,
                imageUrl: specificImageUrl,
                form: form,
              ),
            );
          }
        }
      } else {
        if (!isMegaDex) {
          if (liveDex.includeGenders && p.hasGenderDifferences) {
            String homeFemalePath = liveDex.isShinyDex
                ? 'shiny/female'
                : 'female';
            entries.add(
              DexDisplayEntry(
                pokemon: p,
                uniqueId: '${p.id}_m',
                displaySuffix: ' ♂',
                imageUrl:
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath${p.id}.png',
                form: p.forms.isNotEmpty ? p.forms.first : null,
              ),
            );
            entries.add(
              DexDisplayEntry(
                pokemon: p,
                uniqueId: '${p.id}_f',
                displaySuffix: ' ♀',
                imageUrl:
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$homeFemalePath/${p.id}.png',
                form: p.forms.isNotEmpty ? p.forms.first : null,
              ),
            );
          } else {
            entries.add(
              DexDisplayEntry(
                pokemon: p,
                uniqueId: '${p.id}_normal',
                displaySuffix: '',
                imageUrl:
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath${p.id}.png',
                form: p.forms.isNotEmpty ? p.forms.first : null,
              ),
            );
          }
        }
      }
    }

    if (liveDex.includeOther &&
        !isMegaDex &&
        !isMovesDex &&
        !isAbilitiesDex &&
        !isIcognitoDex) {
      for (var spec in specialObtainables) {
        int pId = (spec['pokemon_id'] as num?)?.toInt() ?? -1;
        int sId = (spec['id'] as num?)?.toInt() ?? -1;
        int isN = (spec['is_n_pokemon'] as num?)?.toInt() ?? 0;
        String obtainType = spec['obtain_type']?.toString() ?? '';
        String gameVer = spec['game_version']?.toString() ?? '';

        final p = pokemonList.where((poke) => poke.id == pId).firstOrNull;
        if (p != null) {
          String specType = obtainType;
          String specForm = spec['form']?.toString() ?? 'normal';

          if (isN == 1) specType = 'n';
          if (gameVer.toLowerCase().contains("let's go") &&
              obtainType == 'trade') {
            specForm = 'alola';
          }

          String specGameTag = '';
          if (gameVer.toLowerCase().contains('colosseum')) {
            specGameTag = 'colosseum';
          }
          if (gameVer.toLowerCase().contains('xd') ||
              gameVer.toLowerCase().contains('gale of darkness')) {
            specGameTag = 'xd';
          }
          if (specGameTag.isNotEmpty) specType = specGameTag;

          String suffix = '';
          if (isN == 1) {
            suffix = " (N's Pokémon)";
          } else if (obtainType == 'trade') {
            suffix = " (${Translator.get('cat_trades')} - $gameVer)";
          } else {
            suffix = " (${Translator.get('cat_gifts')} - $gameVer)";
          }

          String specRegion = getRegionFromGame(gameVer);
          String imageUrl =
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath${p.id}.png';

          final matchedSpecForm = p.forms.where(
            (f) => f.name.toLowerCase() == specForm.toLowerCase(),
          ).firstOrNull ?? (p.forms.isNotEmpty ? p.forms.first : null);

          entries.add(
            DexDisplayEntry(
              pokemon: p,
              uniqueId:
                  '${p.id}_special_${sId}_${specType}_${specRegion}_$specForm',
              displaySuffix: suffix,
              imageUrl: imageUrl,
              form: matchedSpecForm,
            ),
          );
        }
      }
    }
    return entries;
  }

  /// Evaluates whether a Pokémon entry is eligible for Alpha status
  /// based on whether it appears in the Hisui or Lumiose regional dexes.
  static Future<bool> isAlphaEligible(DexDisplayEntry entry) async {
    if (entry.uniqueId.contains('_special_')) {
      return false;
    }

    final db = await DatabaseService.instance.appDatabase;
    final specialCheck = await db.query(
      'special_dexes',
      columns: ['pokemon_id'],
      where: 'pokemon_id = ? AND (dex_name = ? OR dex_name = ?)',
      whereArgs: [entry.pokemon.id, 'legendary-dex', 'mythical-dex'],
      limit: 1,
    );
    if (specialCheck.isNotEmpty) return false;

    final regionCheck = await db.query(
      'dex_orders',
      columns: ['pokemon_id'],
      where:
          'pokemon_id = ? AND (dex_name = ? OR dex_name = ? OR dex_name = ?)',
      whereArgs: [
        entry.pokemon.id,
        'hisui_regional',
        'lumiose_regional',
        'lumiose_dimensions_regional',
      ],
      limit: 1,
    );
    return regionCheck.isNotEmpty;
  }
}

