import '../models/dex_view_models.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../i18n/strings.g.dart';
import 'isolate_translator.dart';
import 'dex_logic_helper.dart';

/// Builds and compiles display entries for a given Pokédex configuration.
class DexEntryBuilder {
  /// Pokémon IDs that must prefer Pokemon HOME sprites for forms.
  static final List<int> useHomeSpritesIds = [
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

  /// Constructs the flat list of [DexDisplayEntry] items for the current [liveDex],
  /// including base Pokémon, enabled regional/cosmetic forms, and special obtainables.
  static List<DexDisplayEntry> buildDisplayEntries(
    UserDex liveDex,
    List<Pokemon> pokemonList,
    List<Map<String, dynamic>> specialObtainables, {
    String? language,
  }) {
    final lang = language ??
        (LocaleSettings.currentLocale == AppLocale.de ? 'de' : 'en');
    final translator = IsolateTranslator(lang);
    List<DexDisplayEntry> entries = [];
    int dexGen = DexLogicHelper.getMaxGenForDex(liveDex.region);
    bool isNationalDex = liveDex.region == 'national_overall';
    bool isMegaDex = liveDex.region == 'mega_dex';
    bool isIcognitoDex = liveDex.region == 'icognito_dex';
    bool isGlitchDex = liveDex.region == 'glitch_dex';
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
      if (isGlitchDex) {
        if (p.id != 151 && (p.id < 252 || p.id > 257)) {
          continue;
        }
      }
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
          if (isGlitchDex) {
            if (p.id == 151 && form.name != 'normal') continue;
            if (p.id >= 252 && p.id <= 257 && form.name != 'vc_glitch') continue;
          } else {
            if ((form.name == 'vc_glitch' || form.name.contains('glitch')) &&
                !liveDex.includeGlitch) {
              continue;
            }
          }
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
              !isIcognitoDex &&
              !isGlitchDex &&
              !(liveDex.includeGlitch && (form.name == 'vc_glitch' || form.name.contains('glitch')))) {
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
              !isIcognitoDex &&
              !isGlitchDex &&
              !(liveDex.includeGlitch && (form.name == 'vc_glitch' || form.name.contains('glitch')))) {
            continue;
          }

          bool hideSuffix = form.name == 'normal';
          String suffix = hideSuffix
              ? ''
              : ' (${translator.getFormDisplayName(form.name)})';
          if (form.name == 'male' || form.name == 'female') {
            suffix = form.name == 'male' ? ' ♂' : ' ♀';
          }

          String specificImageUrl;
          if (useHomeSpritesIds.contains(p.id) &&
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

    if (!isMegaDex &&
        !isMovesDex &&
        !isAbilitiesDex &&
        !isIcognitoDex &&
        !isGlitchDex) {
      final seenSpecial = <String>{};
      for (var spec in specialObtainables) {
        int pId = (spec['pokemon_id'] as num?)?.toInt() ?? -1;
        int sId = (spec['id'] as num?)?.toInt() ?? -1;
        int isN = (spec['is_n_pokemon'] as num?)?.toInt() ?? 0;
        String obtainType = spec['obtain_type']?.toString() ?? '';
        String gameVer = spec['game_version']?.toString() ?? '';

        if (obtainType == 'trade' && !liveDex.includeTrades) continue;
        if (obtainType == 'gift' && !liveDex.includeGifts) continue;
        if (obtainType != 'trade' &&
            obtainType != 'gift' &&
            !liveDex.includeOther) {
          continue;
        }

        final p = pokemonList.where((poke) => poke.id == pId).firstOrNull;
        if (p != null) {
          String specType = obtainType;
          String specForm = spec['form']?.toString() ?? 'normal';

          if (isN == 1) specType = 'n';
          final gvLower = gameVer.toLowerCase().replaceAll('’', "'");
          if (gvLower.contains("let's go") && obtainType == 'trade') {
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

          String specRegion = DexLogicHelper.getRegionFromGame(gameVer);

          // Deduplicate multi-source/scraped duplicates (e.g. Togetic or Larvitar across wikis)
          final dedupKey = '$pId-$obtainType-$specForm-$specType-$specRegion';
          if (seenSpecial.contains(dedupKey)) {
            continue;
          }
          seenSpecial.add(dedupKey);

          final matchedSpecForm = p.forms.where(
            (f) => f.name.toLowerCase() == specForm.toLowerCase(),
          ).firstOrNull ?? (p.forms.isNotEmpty ? p.forms.first : null);

          String suffix = '';
          final formPrefix = (matchedSpecForm != null &&
                  matchedSpecForm.name.toLowerCase() != 'normal')
              ? ' (${translator.getFormDisplayName(matchedSpecForm.name)})'
              : '';
          if (isN == 1) {
            suffix = "$formPrefix (N's Pokémon)";
          } else if (obtainType == 'trade') {
            suffix = "$formPrefix (${translator.tradesLabel} - $gameVer)";
          } else {
            suffix = "$formPrefix (${translator.giftsLabel} - $gameVer)";
          }

          final formImgId = (matchedSpecForm != null && matchedSpecForm.imageId > 0)
              ? matchedSpecForm.imageId
              : p.id;
          String imageUrl;
          if (useHomeSpritesIds.contains(p.id) &&
              matchedSpecForm != null &&
              matchedSpecForm.name != 'normal') {
            imageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyPath${p.id}-${matchedSpecForm.name}.png';
          } else {
            imageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath$formImgId.png';
          }

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

  /// Isolate task entrypoint for background display entry compilation.
  static List<DexDisplayEntry> buildEntriesIsolateTask(BuildEntriesArgs args) {
    return buildDisplayEntries(
      args.liveDex,
      args.pokemonList,
      args.specialObtainables,
      language: args.language,
    );
  }
}
