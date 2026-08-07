import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_dex.dart';
import '../models/pokemon.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';

class DexDisplayEntry {
  final Pokemon pokemon;
  final String uniqueId;
  final String displaySuffix;
  final String imageUrl;

  DexDisplayEntry({
    required this.pokemon,
    required this.uniqueId,
    required this.displaySuffix,
    required this.imageUrl,
  });
}

class DexScreen extends StatefulWidget {
  final UserDex initialDex;
  final List<Pokemon> pokemonList;

  const DexScreen({
    super.key,
    required this.initialDex,
    required this.pokemonList,
  });

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  String _searchQuery = '';
  String _filter = 'all';

  String _getFormDisplayName(String form, DexProvider provider) {
    try {
      final key = 'form_name_${form.toLowerCase()}';
      final translated = Translator.get(key);
      if (translated != key) {
        return translated;
      }
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_get_form_display_name')} $e",
      );
    }
    return form.isEmpty ? '' : form[0].toUpperCase() + form.substring(1);
  }

  int _getMaxGenForDex(String region) {
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

List<DexDisplayEntry> _buildDisplayEntries(
    UserDex liveDex,
    DexProvider provider,
  ) {
    List<DexDisplayEntry> entries = [];
    try {
      int dexGen = _getMaxGenForDex(liveDex.region);
      bool isNationalDex = liveDex.region == 'national_overall';
      bool isMegaDex = liveDex.region == 'mega_dex';
      bool isIcognitoDex = liveDex.region == 'icognito_dex';

      List<int> useHomeSpritesIds = [
        201, 412, 413, 414, 421, 422, 423, 493, 585, 586, 592, 593, 649, 664, 
        665, 666, 669, 670, 671, 676, 710, 711, 718, 741, 773, 774, 854, 855, 
        869, 875, 876, 877, 888, 889, 890, 892, 893, 898, 901, 902, 905, 924, 
        925, 931, 964, 977, 978, 999, 1011, 1012, 1017, 1024
      ];

      bool isNativeRegionalForm(PokemonForm f, String region) {
        if (f.formType != 'regional') return false;
        if (region.contains('alola') && f.name.contains('alola')) return true;
        if (region.contains('galar') && f.name.contains('galar')) return true;
        if (region.contains('hisui') && f.name.contains('hisui')) return true;
        if (region.contains('paldea') && f.name.contains('paldea')) return true;
        return false;
      }

      for (var p in widget.pokemonList) {
        if (p.forms.isNotEmpty) {
          var sortedForms = List.of(p.forms);
          
          sortedForms.sort((a, b) {
            if (p.id == 718) {
              int wA = a.name.contains('10') ? 0 : (a.name.contains('50') || a.name == 'normal' ? 1 : 2);
              int wB = b.name.contains('10') ? 0 : (b.name.contains('50') || b.name == 'normal' ? 1 : 2);
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

          bool hasExplicitGenderForms = p.forms.any((f) => f.name == 'male' || f.name == 'female');

          for (var form in sortedForms) {
            bool isBaseForm = form.name == 'normal' || p.forms.first.name == form.name;

            if ((p.id == 1007 || p.id == 1008 || p.id == 664 || p.id == 665) && !isBaseForm) {
              continue;
            }

            if (isMegaDex && form.formType != 'mega') continue;

            bool isNativeRegional = isNativeRegionalForm(form, liveDex.region);

            if (form.formType == 'normal' && !liveDex.includeRegional && !isMegaDex) {
              bool hasNativeRegional = p.forms.any((f) => isNativeRegionalForm(f, liveDex.region));
              if (hasNativeRegional) continue;
            }

            if (form.formType == 'regional' && !liveDex.includeRegional && !isNativeRegional) continue;
            if (form.formType == 'mega' && !liveDex.includeMega && !isMegaDex) continue;
            if (form.formType == 'gmax' && !liveDex.includeGMax) continue;

            if (form.formType == 'other' && !liveDex.includeOther && !isIcognitoDex) {
              if (!isBaseForm) continue;
            }

            bool isWhitelistedForThisDex = form.exclusiveRegions.contains(liveDex.region);
            if (form.exclusiveRegions.isNotEmpty) {
              if (!isNationalDex && !isWhitelistedForThisDex) continue;
            }
            if (!isNationalDex && !isWhitelistedForThisDex && form.minGen > dexGen && !isMegaDex && !isIcognitoDex) {
              continue;
            }

            bool hideSuffix = form.name == 'normal' || (isBaseForm && !liveDex.includeOther && !isIcognitoDex && form.formType == 'other');
            
            // Wenn die Form "male" oder "female" in der API heißt, generieren wir daraus die sauberen Symbole ♂ / ♀
            String suffix = hideSuffix ? '' : ' (${_getFormDisplayName(form.name, provider)})';
            if (form.name == 'male' || form.name == 'female') {
               suffix = form.name == 'male' ? ' ♂' : ' ♀';
            }

            String specificImageUrl;
            if (useHomeSpritesIds.contains(p.id) && !hideSuffix && form.name != 'normal') {
               String formSuffix = '';
               if (!isBaseForm || isIcognitoDex) {
                 formSuffix = '-${form.name}';
                 // Besonderheiten der HOME-Dateinamen abfangen
                 if (p.id == 774 && form.name.contains('meteor')) formSuffix = '-meteor';
                 if (p.id == 718 && form.name.contains('10')) formSuffix = '-10';
                 if (p.id == 718 && form.name.contains('complete')) formSuffix = '-complete';
                 if (p.id == 201 && form.name == 'a') formSuffix = '';
               }
               specificImageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/${p.id}$formSuffix.png';
            } else {
               specificImageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${form.imageId}.png';
            }

            if (form.formType == 'normal' && liveDex.includeGenders && p.hasGenderDifferences && !hasExplicitGenderForms) {
              entries.add(DexDisplayEntry(pokemon: p, uniqueId: '${p.id}_m', displaySuffix: ' ♂', imageUrl: p.imageUrl));
              entries.add(DexDisplayEntry(pokemon: p, uniqueId: '${p.id}_f', displaySuffix: ' ♀', imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/female/${p.id}.png'));
            } else {
              entries.add(DexDisplayEntry(pokemon: p, uniqueId: '${p.id}_${form.name}', displaySuffix: suffix, imageUrl: specificImageUrl));
            }
          }
        } else {
          if (!isMegaDex) {
            if (liveDex.includeGenders && p.hasGenderDifferences) {
              entries.add(DexDisplayEntry(pokemon: p, uniqueId: '${p.id}_m', displaySuffix: ' ♂', imageUrl: p.imageUrl));
              entries.add(DexDisplayEntry(pokemon: p, uniqueId: '${p.id}_f', displaySuffix: ' ♀', imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/female/${p.id}.png'));
            } else {
              entries.add(DexDisplayEntry(pokemon: p, uniqueId: '${p.id}_normal', displaySuffix: '', imageUrl: p.imageUrl));
            }
          }
        }
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_build_display_entries')} $e");
    }
    return entries;
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere(
      (d) => d.id == widget.initialDex.id,
      orElse: () => widget.initialDex,
    );

    final allEntries = _buildDisplayEntries(liveDex, provider);
    final caughtCount = liveDex.caughtIds.length;
    final totalCount = allEntries.length;

    final filteredList = allEntries.where((entry) {
      final baseName = entry.pokemon.getName(provider.currentLanguage);
      final fullName = baseName + entry.displaySuffix;

      final matchesSearch =
          fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.pokemon.id.toString().contains(_searchQuery);

      final isCaught = liveDex.caughtIds.contains(entry.uniqueId);

      if (_filter == 'caught' && !isCaught) return false;
      if (_filter == 'uncaught' && isCaught) return false;

      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(liveDex.title, style: const TextStyle(fontSize: 18)),
            Text(
              '$caughtCount / $totalCount ${Translator.get('caught')}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: Translator.get('search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(Translator.get('filter_all')),
                    ),
                    DropdownMenuItem(
                      value: 'caught',
                      child: Text(Translator.get('filter_caught')),
                    ),
                    DropdownMenuItem(
                      value: 'uncaught',
                      child: Text(Translator.get('filter_missing')),
                    ),
                  ],
                  onChanged: (val) => setState(() => _filter = val ?? 'all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.80,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final entry = filteredList[index];
                final isCaught = liveDex.caughtIds.contains(entry.uniqueId);

                return GestureDetector(
                  onTap: () =>
                      provider.togglePokemon(liveDex.id, entry.uniqueId),
                  child: Card(
                    color: isCaught
                        ? Colors.green.withOpacity(0.15)
                        : Theme.of(context).cardColor,
                    elevation: isCaught ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isCaught ? Colors.green : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#${entry.pokemon.id.toString().padLeft(3, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: ColorFiltered(
                                colorFilter: isCaught
                                    ? const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.dst,
                                      )
                                    : const ColorFilter.mode(
                                        Colors.grey,
                                        BlendMode.saturation,
                                      ),
                                child: Image.network(
                                  entry.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.catching_pokemon,
                                        size: 40,
                                      ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 4.0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  entry.pokemon.getName(
                                        provider.currentLanguage,
                                      ) +
                                      entry.displaySuffix,
                                  style: TextStyle(
                                    fontWeight: isCaught
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isCaught)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(
                              Icons.catching_pokemon,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
