import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_dex.dart';
import '../models/pokemon.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';
import 'pokemon_info_screen.dart';
import 'ignored_list_screen.dart';

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

class BoxData {
  final String title;
  final String regionKey;
  final List<DexDisplayEntry> entries;
  final int crossAxisCount;

  BoxData(this.title, this.regionKey, this.entries, this.crossAxisCount);
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
  bool _isBoxView = false;
  bool _separateForms = true;
  bool _isLoadingPrefs = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBoxView = prefs.getBool('box_view_${widget.initialDex.id}') ?? false;
      _separateForms =
          prefs.getBool('separate_forms_${widget.initialDex.id}') ?? true;
      _isLoadingPrefs = false;
    });
  }

  Future<void> _toggleBoxView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBoxView = !_isBoxView;
      prefs.setBool('box_view_${widget.initialDex.id}', _isBoxView);
    });
  }

  Future<void> _toggleSeparateForms() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _separateForms = !_separateForms;
      prefs.setBool('separate_forms_${widget.initialDex.id}', _separateForms);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showQuickNavDialog(List<BoxData> boxes) {
    final Map<String, int> regionFirstIndices = {};
    for (int i = 0; i < boxes.length; i++) {
      if (!regionFirstIndices.containsKey(boxes[i].regionKey)) {
        regionFirstIndices[boxes[i].regionKey] = i;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Translator.get('jump_to_region')),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: regionFirstIndices.entries.map((entry) {
                  String regionKey = entry.key;
                  int boxIndex = entry.value;
                  String regionName = Translator.get('region_name_$regionKey');
                  if (regionName == 'region_name_$regionKey') {
                    regionName =
                        regionKey[0].toUpperCase() + regionKey.substring(1);
                  }

                  return ActionChip(
                    label: Text(
                      regionName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    onPressed: () {
                      Navigator.pop(context);
                      _pageController.jumpToPage(boxIndex);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFormDisplayName(String form, DexProvider provider) {
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

  String _getPokemonRegionId(Pokemon p, PokemonForm? f) {
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

  String _getEntryCategoryId(DexDisplayEntry entry) {
    final id = entry.pokemon.id;
    final uniqueId = entry.uniqueId.toLowerCase();

    bool isBaseForm = false;
    if (!uniqueId.contains('_')) {
      isBaseForm = true;
    } else {
      String formName = uniqueId.substring(uniqueId.indexOf('_') + 1);
      if (formName == 'normal' || formName == 'm' || formName == 'male') {
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

    if (uniqueId.endsWith('_f') || uniqueId.endsWith('_female'))
      return 'females';

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

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
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

  List<BoxData> _generateBoxes(
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

      // 1. Liste sauber in Basis-Pokémon und Formen aufteilen
      for (var entry in entries) {
        if (_getEntryCategoryId(entry) == 'base') {
          baseEntries.add(entry);
        } else {
          formEntries.add(entry);
        }
      }

      // 2. Basis-Pokémon in die klassischen 30er-Boxen abfüllen
      List<List<DexDisplayEntry>> baseChunks = _chunkList(
        baseEntries,
        capacity,
      );
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
        List<List<DexDisplayEntry>> formChunks = _chunkList(
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
        String regionId = _getPokemonRegionId(entry.pokemon, form);
        String catId = _getEntryCategoryId(entry);

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
        if (localizedRegion == 'region_name_$regionId')
          localizedRegion = regionId[0].toUpperCase() + regionId.substring(1);

        void buildChunks(String catId) {
          if (!cats.containsKey(catId)) return;

          List<List<DexDisplayEntry>> chunks = _chunkList(
            cats[catId]!,
            capacity,
          );
          for (int i = 0; i < chunks.length; i++) {
            String baseTitle;
            bool isSpecial = [
              'cap',
              'unown',
              'vivillon',
              'alcremie',
              'gmax',
              'regional',
              'mega',
            ].contains(catId);
            String localizedCat = Translator.get('cat_$catId');
            if (localizedCat == 'cat_$catId') localizedCat = catId;

            if (catId == 'base') {
              baseTitle = localizedRegion;
            } else if (isSpecial) {
              baseTitle = '$localizedRegion $localizedCat';
            } else {
              baseTitle = '$localizedRegion $localizedCat';
            }

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
        for (String sc in specialCats) {
          buildChunks(sc);
        }

        buildChunks('alternate');
      }
    }
    return boxes;
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
            if (form.exclusiveRegions.isNotEmpty) {
              if (!isNationalDex && !isWhitelistedForThisDex) continue;
            }
            if (!isNationalDex &&
                !isWhitelistedForThisDex &&
                form.minGen > dexGen &&
                !isMegaDex &&
                !isIcognitoDex)
              continue;

            bool hideSuffix = form.name == 'normal';
            String suffix = hideSuffix
                ? ''
                : ' (${_getFormDisplayName(form.name, provider)})';
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
                if (p.id == 774 && form.name.contains('meteor'))
                  formSuffix = '-meteor';
                if (p.id == 718 && form.name.contains('10')) formSuffix = '-10';
                if (p.id == 718 && form.name.contains('complete'))
                  formSuffix = '-complete';
                if (p.id == 201 && form.name == 'a') formSuffix = '';
              }
              specificImageUrl =
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/${p.id}$formSuffix.png';
            } else {
              specificImageUrl =
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${form.imageId}.png';
            }

            if (form.formType == 'normal' &&
                liveDex.includeGenders &&
                p.hasGenderDifferences &&
                !hasExplicitGenderForms) {
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_m',
                  displaySuffix: ' ♂',
                  imageUrl: p.imageUrl,
                ),
              );
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_f',
                  displaySuffix: ' ♀',
                  imageUrl:
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/female/${p.id}.png',
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
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_m',
                  displaySuffix: ' ♂',
                  imageUrl: p.imageUrl,
                ),
              );
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_f',
                  displaySuffix: ' ♀',
                  imageUrl:
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/female/${p.id}.png',
                ),
              );
            } else {
              entries.add(
                DexDisplayEntry(
                  pokemon: p,
                  uniqueId: '${p.id}_normal',
                  displaySuffix: '',
                  imageUrl: p.imageUrl,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere(
      (d) => d.id == widget.initialDex.id,
      orElse: () => widget.initialDex,
    );

    List<DexDisplayEntry> rawEntries = [];
    try {
      rawEntries = _buildDisplayEntries(liveDex, provider);
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error')} $e");
    }

    final caughtCount = liveDex.caughtIds.length;

    final filteredList = rawEntries.where((entry) {
      if (liveDex.ignoredIds.contains(entry.uniqueId)) return false;

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

    final totalCount = rawEntries
        .where((e) => !liveDex.ignoredIds.contains(e.uniqueId))
        .length;
    final List<BoxData> boxes = _generateBoxes(
      filteredList,
      _separateForms,
      liveDex,
    );

    final List<DexDisplayEntry> displayList = [];
    for (var box in boxes) {
      displayList.addAll(box.entries);
    }

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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: Translator.get('tooltip_view_sort'),
            onSelected: (value) {
              if (value == 'toggle_view') _toggleBoxView();
              if (value == 'toggle_sort') _toggleSeparateForms();
              if (value == 'ignored_list') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IgnoredListScreen(
                      dexId: liveDex.id,
                      allRawEntries: rawEntries,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_view',
                child: Row(
                  children: [
                    Icon(_isBoxView ? Icons.list : Icons.grid_view, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isBoxView
                          ? Translator.get('view_list')
                          : Translator.get('view_box'),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_sort',
                child: Row(
                  children: [
                    Icon(
                      _separateForms
                          ? Icons.format_list_numbered
                          : Icons.category,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _separateForms
                          ? Translator.get('sort_dex')
                          : Translator.get('sort_forms'),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'ignored_list',
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      Translator.get('ignored_list_title') !=
                              'ignored_list_title'
                          ? Translator.get('ignored_list_title')
                          : 'Ausgeblendete Pokémon',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
            child: _isBoxView
                ? _buildBoxView(boxes, liveDex, provider)
                : _buildListView(displayList, liveDex, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxView(
    List<BoxData> boxes,
    UserDex liveDex,
    DexProvider provider,
  ) {
    if (boxes.isEmpty) {
      return Center(child: Text(Translator.get('empty_box')));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double boxMaxWidth = screenWidth > 1200
        ? 1100
        : (screenWidth > 800 ? 800 : double.infinity);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: boxMaxWidth),
        child: PageView.builder(
          controller: _pageController,
          itemCount: boxes.length,
          itemBuilder: (context, boxIndex) {
            final box = boxes[boxIndex];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            if (_pageController.hasClients &&
                                _pageController.page! > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_separateForms && boxes.length > 1) {
                              _showQuickNavDialog(boxes);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  box.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_separateForms && boxes.length > 1)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            if (_pageController.hasClients &&
                                _pageController.page! < boxes.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: box.crossAxisCount,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = box.entries[index];
                      final isCaught = liveDex.caughtIds.contains(
                        entry.uniqueId,
                      );
                      final isShiny = liveDex.shinyIds.contains(entry.uniqueId);

                      return GestureDetector(
                        onTap: () =>
                            provider.togglePokemon(liveDex.id, entry.uniqueId),
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => PokemonInfoScreen(
                                entry: entry,
                                dexId: liveDex.id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCaught
                                ? Colors.green.withOpacity(0.15)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCaught
                                  ? Colors.green
                                  : Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.3),
                              width: isCaught ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: ColorFiltered(
                                  colorFilter: isCaught
                                      ? const ColorFilter.mode(
                                          Colors.transparent,
                                          BlendMode.dst,
                                        )
                                      : const ColorFilter.matrix(<double>[
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0,
                                          0,
                                          0,
                                          1,
                                          0,
                                        ]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Image.network(
                                      entry.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Image.network(
                                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${entry.pokemon.id}.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(
                                                  Icons.catching_pokemon,
                                                  size: 24,
                                                ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isCaught || isShiny)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Column(
                                    children: [
                                      if (isCaught)
                                        const Icon(
                                          Icons.catching_pokemon,
                                          color: Colors.green,
                                          size: 14,
                                        ),
                                      if (isShiny)
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: box.entries.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(
    List<DexDisplayEntry> displayList,
    UserDex liveDex,
    DexProvider provider,
  ) {
    if (displayList.isEmpty) {
      return Center(child: Text(Translator.get('empty_box')));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    int listColumns = screenWidth > 1200
        ? 8
        : (screenWidth > 900 ? 6 : (screenWidth > 600 ? 5 : 3));

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: listColumns,
        childAspectRatio: 0.80,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final entry = displayList[index];
        final isCaught = liveDex.caughtIds.contains(entry.uniqueId);
        final isShiny = liveDex.shinyIds.contains(entry.uniqueId);

        return GestureDetector(
          onTap: () => provider.togglePokemon(liveDex.id, entry.uniqueId),
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) =>
                    PokemonInfoScreen(entry: entry, dexId: liveDex.id),
              ),
            );
          },
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
                            : const ColorFilter.matrix(<double>[
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ]),
                        child: Image.network(
                          entry.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${entry.pokemon.id}.png',
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.catching_pokemon,
                                  size: 30,
                                ),
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
                          entry.pokemon.getName(provider.currentLanguage) +
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
                if (isCaught || isShiny)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Column(
                      children: [
                        if (isCaught)
                          const Icon(
                            Icons.catching_pokemon,
                            color: Colors.green,
                            size: 20,
                          ),
                        if (isShiny)
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
