import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../models/dex_view_models.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';
import 'notification_helper.dart';

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

  static String getFormDisplayName(String form, DexProvider provider) {
    try {
      final key = 'form_name_${form.toLowerCase()}';
      final translated = Translator.get(key);
      if (translated != key) return translated;
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_get_form_display_name')} $e",
      );
    }
    return form.isEmpty ? '' : form[0].toUpperCase() + form.substring(1);
  }

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

  static String getPokemonRegionId(Pokemon p, PokemonForm? f) {
    if (f != null) {
      if (p.id == 25 && f.name.contains('cap')) return 'kanto';
      if (f.formType == 'gmax') return 'galar';
      if (f.name.contains('alola') || f.name.contains('totem')) return 'alola';
      if (f.name.contains('galar')) return 'galar';
      if (f.name.contains('hisui')) return 'hisui';
      if (f.name.contains('paldea')) return 'paldea';
    }
    int id = p.id;
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

  static String getEntryCategoryId(DexDisplayEntry entry) {
    final id = entry.pokemon.id;
    final uniqueId = entry.uniqueId.toLowerCase();
    bool isBaseForm = false;

    if (!uniqueId.contains('_')) {
      isBaseForm = true;
    } else {
      String formName = uniqueId.substring(uniqueId.indexOf('_') + 1);
      if (formName == 'normal' ||
          formName == 'male' ||
          (formName == 'm' && id != 201)) {
        isBaseForm = true;
      } else if (entry.pokemon.forms.isNotEmpty &&
          formName == entry.pokemon.forms.first.name.toLowerCase()) {
        isBaseForm = true;
      }
    }

    if (isBaseForm) return 'base';

    if (id == 25 && uniqueId.contains('cap')) return 'cap';
    if (id == 201) return 'unown';
    if (id == 666) return 'vivillon';
    if (id == 869) return 'alcremie';

    if ((uniqueId.endsWith('_f') || uniqueId.endsWith('_female')) &&
        id != 201) {
      return 'females';
    }

    if (uniqueId.contains('_')) {
      String formName = uniqueId.substring(uniqueId.indexOf('_') + 1);
      try {
        final form = entry.pokemon.forms.firstWhere(
          (f) => f.name.toLowerCase() == formName,
        );
        if (form.formType == 'gmax') return 'gmax';
        if (form.formType == 'regional') return 'regional';
        if (form.formType == 'mega') return 'mega';
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

  static List<BoxData> generateBoxes(
    List<DexDisplayEntry> entries,
    bool separateForms,
    UserDex liveDex,
  ) {
    List<BoxData> boxes = [];
    bool isOriginalKantoJohto =
        liveDex.region == 'kanto_regional' ||
        liveDex.region == 'johto_regional';
    int capacity = isOriginalKantoJohto ? 20 : 30;
    int crossAxis = isOriginalKantoJohto ? 5 : 6;

    if (!separateForms) {
      List<DexDisplayEntry> baseEntries = [];
      List<DexDisplayEntry> formEntries = [];

      for (var entry in entries) {
        if (getEntryCategoryId(entry) == 'base') {
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
      ];
      Map<String, Map<String, List<DexDisplayEntry>>> structured = {};

      for (var entry in entries) {
        PokemonForm? form;
        if (entry.uniqueId.contains('_')) {
          String formName = entry.uniqueId.substring(
            entry.uniqueId.indexOf('_') + 1,
          );
          try {
            form = entry.pokemon.forms.firstWhere((f) => f.name == formName);
          } catch (_) {}
        }

        String regionId = getPokemonRegionId(entry.pokemon, form);
        String catId = getEntryCategoryId(entry);

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

            baseTitle = (catId == 'base')
                ? localizedRegion
                : '$localizedRegion $localizedCat';
            String title = chunks.length == 1
                ? baseTitle
                : '$baseTitle ${i + 1}';
            boxes.add(BoxData(title, regionId, chunks[i], crossAxis));
          }
        }

        buildChunks('base');
        buildChunks('females');
        List<String> specialCats =
            cats.keys
                .where((c) => c != 'base' && c != 'females' && c != 'alternate')
                .toList()
              ..sort();
        for (String sc in specialCats) buildChunks(sc);
        buildChunks('alternate');
      }
    }
    return boxes;
  }

  static List<DexDisplayEntry> buildDisplayEntries(
    UserDex liveDex,
    DexProvider provider,
    List<Pokemon> pokemonList,
  ) {
    List<DexDisplayEntry> entries = [];

    try {
      int dexGen = getMaxGenForDex(liveDex.region);
      bool isNationalDex = liveDex.region == 'national_overall';
      bool isMegaDex = liveDex.region == 'mega_dex';
      bool isIcognitoDex = liveDex.region == 'icognito_dex';

      String shinyPath = liveDex.isShinyDex ? 'shiny/' : '';

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
            int getWeight(String type) {
              if (type == 'normal') return 0;
              if (type == 'regional') return 1;
              if (type == 'other') return 2;
              if (type == 'mega') return 3;
              if (type == 'gmax') return 4;
              return 5;
            }

            return getWeight(a.formType).compareTo(getWeight(b.formType));
          });

          bool hasExplicitGenderForms = p.forms.any(
            (f) => f.name == 'male' || f.name == 'female',
          );

          for (var form in sortedForms) {
            bool isBaseForm =
                form.name == 'normal' || p.forms.first.name == form.name;

            if ((p.id == 1007 || p.id == 1008 || p.id == 664 || p.id == 665) &&
                !isBaseForm)
              continue;

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
                !isNativeRegional)
              continue;

            if (form.formType == 'mega' && !liveDex.includeMega && !isMegaDex)
              continue;

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
                !isWhitelistedForThisDex)
              continue;

            if (!isNationalDex &&
                !isWhitelistedForThisDex &&
                form.minGen > dexGen &&
                !isMegaDex &&
                !isIcognitoDex)
              continue;

            bool hideSuffix = form.name == 'normal';
            String suffix = hideSuffix
                ? ''
                : ' (${getFormDisplayName(form.name, provider)})';

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
                if (p.id == 774 && form.name.contains('meteor'))
                  formSuffix = '-meteor';
                if (p.id == 718 && form.name.contains('10')) formSuffix = '-10';
                if (p.id == 718 && form.name.contains('complete'))
                  formSuffix = '-complete';
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
                ),
              );
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_f',
                  displaySuffix: ' ♀',
                  imageUrl:
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$homeFemalePath/${p.id}.png',
                ),
              );
            } else {
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_${form.name}',
                  displaySuffix: suffix,
                  imageUrl: specificImageUrl,
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
                ),
              );
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_f',
                  displaySuffix: ' ♀',
                  imageUrl:
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$homeFemalePath/${p.id}.png',
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
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_build_display_entries')} $e",
      );
    }
    return entries;
  }
}
