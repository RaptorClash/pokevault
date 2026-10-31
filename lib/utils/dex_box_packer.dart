import '../models/dex_view_models.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../i18n/strings.g.dart';
import 'isolate_translator.dart';
import 'dex_logic_helper.dart';

/// Handles organizing Pokémon display entries into standard or custom box collections.
class DexBoxPacker {
  /// Generates the list of [BoxData] instances for the given [entries] and [liveDex] configuration.
  static List<BoxData> generateBoxes(
    List<DexDisplayEntry> entries,
    bool separateForms,
    UserDex liveDex, {
    String? language,
  }) {
    final lang = language ??
        (LocaleSettings.currentLocale == AppLocale.de ? 'de' : 'en');
    final translator = IsolateTranslator(lang);
    if (liveDex.customBoxes.isNotEmpty) {
      List<BoxData> customBoxesList = [];
      for (var cb in liveDex.customBoxes) {
        List<DexDisplayEntry> boxEntries = [];
        for (var id in cb.pokemonIds) {
          if (id.isEmpty) {
            boxEntries.add(DexDisplayEntry.emptyEntry);
          } else if (DexLogicHelper.isPlaceholder(id)) {
            boxEntries.add(DexDisplayEntry.placeholderEntry(id));
          } else {
            try {
              final baseId = DexLogicHelper.getBaseId(id);
              DexDisplayEntry? originalEntry =
                  entries.where((e) => e.uniqueId == baseId).firstOrNull;
              if (originalEntry == null && baseId.contains('_special_')) {
                final parts = baseId.split('_special_');
                final pid = int.tryParse(parts[0]);
                if (pid != null) {
                  final specParts = parts[1].split('_');
                  final specType = specParts.length > 1 ? specParts[1] : '';
                  final specRegion = specParts.length > 2 ? specParts[2] : '';
                  originalEntry = entries.where((e) {
                    if (e.pokemon.id != pid) return false;
                    if (!e.uniqueId.contains('_special_')) return false;
                    final eSpecParts =
                        e.uniqueId.split('_special_')[1].split('_');
                    final eType =
                        eSpecParts.length > 1 ? eSpecParts[1] : '';
                    final eRegion =
                        eSpecParts.length > 2 ? eSpecParts[2] : '';
                    return (specType.isEmpty || eType == specType) &&
                        (specRegion.isEmpty || eRegion == specRegion);
                  }).firstOrNull;
                }
              }

              if (originalEntry != null) {
                final isShiny = DexLogicHelper.isPokemonShiny(liveDex, id);
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
              } else {
                boxEntries.add(DexDisplayEntry.emptyEntry);
              }
            } catch (_) {
              boxEntries.add(DexDisplayEntry.emptyEntry);
            }
          }
        }
        
        int capacity = cb.columns * cb.rows;
        while (boxEntries.length < capacity) {
          boxEntries.add(DexDisplayEntry.emptyEntry);
        }

        final isSpecialBox = DexLogicHelper.isSpecialBoxTitle(cb.title) ||
            boxEntries.any((e) => e.uniqueId.contains('_special_'));
        if (isSpecialBox) {
          final validEntries =
              boxEntries.where((e) => e.uniqueId.isNotEmpty).toList();
          final padCount = capacity - validEntries.length;
          boxEntries = [
            ...validEntries,
            ...List.generate(
              padCount > 0 ? padCount : 0,
              (_) => DexDisplayEntry.emptyEntry,
            ),
          ];

          cb.pokemonIds = [
            ...validEntries.map((e) => e.uniqueId),
            ...List.generate(padCount > 0 ? padCount : 0, (_) => ''),
          ];
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
        if (DexLogicHelper.getEntryCategoryId(entry, liveDex.region) == 'base') {
          baseEntries.add(entry);
        } else {
          formEntries.add(entry);
        }
      }
      List<List<DexDisplayEntry>> baseChunks = DexLogicHelper.chunkList(baseEntries, capacity);
      for (int i = 0; i < baseChunks.length; i++) {
        int start = i * capacity + 1;
        int end = start + baseChunks[i].length - 1;
        boxes.add(
          BoxData(
            translator.formatStandardBoxTitle(i, start, end),
            'kanto',
            baseChunks[i],
            crossAxis,
          ),
        );
      }
      if (formEntries.isNotEmpty) {
        List<List<DexDisplayEntry>> formChunks = DexLogicHelper.chunkList(
          formEntries,
          capacity,
        );
        int boxOffset = baseChunks.length;
        for (int i = 0; i < formChunks.length; i++) {
          String title = translator.formatFormBoxTitle(
            boxOffset + i + 1,
            i,
            formChunks.length,
          );
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
        String regionId = DexLogicHelper.getPokemonRegionId(entry.pokemon, form, liveDex);

        if (entry.uniqueId.contains('_special_')) {
          final parts = entry.uniqueId.split('_special_')[1].split('_');
          if (parts.length >= 3) {
            regionId = parts[2];
          }
        }

        String catId = DexLogicHelper.getEntryCategoryId(entry, liveDex.region);
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

        void buildChunks(String catId) {
          if (!cats.containsKey(catId)) return;
          List<List<DexDisplayEntry>> chunks = DexLogicHelper.chunkList(
            cats[catId]!,
            capacity,
          );
          for (int i = 0; i < chunks.length; i++) {
            String title = translator.formatCategoryBoxTitle(
              regionId,
              catId,
              chunkIndex: i,
              totalChunks: chunks.length,
            );
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

  /// Isolate task entrypoint for background box generation.
  static List<BoxData> generateBoxesIsolateTask(GenerateBoxesArgs args) {
    return generateBoxes(
      args.entries,
      args.separateForms,
      args.liveDex,
      language: args.language,
    );
  }
}
