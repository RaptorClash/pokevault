import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_dex.dart';
import '../../models/pokemon.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../l10n/app_translations.dart';
import '../../utils/dex_logic_helper.dart';
import '../../utils/notification_helper.dart';
import '../../screens/pokemon_info/widgets/breeding_data.dart';
import '../../utils/shiny_logic_helper.dart';
import '../ignored_list/ignored_list_screen.dart';
import 'dex_box_view.dart';
import 'dex_list_view.dart';
import 'route_tracker_screen.dart';
import '../pokemon_info/pokemon_info_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';
  String _lastSearchQuery = '';
  String _lastFilter = 'all';
  bool _isBoxView = false;
  bool _separateForms = true;
  bool _isLoadingPrefs = true;
  final PageController _pageController = PageController();
  late List<DexDisplayEntry> _rawEntries;

  Timer? _debounce;

  final GlobalKey _firstPokemonKey = GlobalKey();
  final GlobalKey _sortMenuKey = GlobalKey();
  final GlobalKey _fakeMenuBoxKey = GlobalKey();
  final GlobalKey _fakeMenuFormsKey = GlobalKey();
  final GlobalKey _fakeMenuIgnoredKey = GlobalKey();
  final GlobalKey _searchBarKey = GlobalKey();

  bool _showFakeMenu = false;
  String? _tutorialTargetId;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _rawEntries = DexLogicHelper.buildDisplayEntries(
      widget.initialDex,
      context.read<DexProvider>(),
      widget.pokemonList,
    );

    final baseList = _rawEntries
        .where((e) => !widget.initialDex.ignoredIds.contains(e.uniqueId))
        .toList();
    if (baseList.isNotEmpty) {
      _tutorialTargetId = baseList.first.uniqueId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  void _showTutorialIfNeeded() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    final dexProvider = Provider.of<DexProvider>(context, listen: false);

    if (!tutProvider.hasSeenFeature('dex_screen')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'dex_screen',
          nameKey: 'tutorial_feature_details',
          steps: [
            TutorialStep(
              targetKey: null,
              titleKey: 'tutorial_dex_intro_title',
              textKey: 'tutorial_dex_intro_text',
            ),
            TutorialStep(
              targetKey: _firstPokemonKey,
              titleKey: 'tutorial_dex_tap_title',
              textKey: 'tutorial_dex_tap_text',
              requireTargetTap: true,
              onTargetTap: () {
                try {
                  final baseList = _rawEntries
                      .where(
                        (e) =>
                            !widget.initialDex.ignoredIds.contains(e.uniqueId),
                      )
                      .toList();
                  if (baseList.isNotEmpty) {
                    dexProvider.togglePokemon(
                      widget.initialDex.id,
                      baseList.first.uniqueId,
                    );
                  }
                } catch (e) {
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              },
            ),
            TutorialStep(
              targetKey: _sortMenuKey,
              titleKey: 'tutorial_dex_menu_title',
              textKey: 'tutorial_dex_menu_text',
              requireTargetTap: true,
              onTargetTap: () {
                try {
                  setState(() => _showFakeMenu = true);
                } catch (e) {
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              },
            ),
            TutorialStep(
              targetKey: _fakeMenuFormsKey,
              titleKey: 'tutorial_dex_menu_forms_title',
              textKey: 'tutorial_dex_menu_forms_text',
              requireTargetTap: true,
              onTargetTap: () {
                try {
                  _toggleSeparateForms();
                } catch (e) {
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              },
            ),
            TutorialStep(
              targetKey: _fakeMenuBoxKey,
              titleKey: 'tutorial_dex_menu_box_title',
              textKey: 'tutorial_dex_menu_box_text',
              requireTargetTap: true,
              onTargetTap: () {
                try {
                  setState(() => _showFakeMenu = false);
                  _toggleBoxView();
                } catch (e) {
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              },
            ),
            TutorialStep(
              targetKey: _searchBarKey,
              titleKey: 'tutorial_dex_search_title',
              textKey: 'tutorial_dex_search_text',
              requireTargetTap: false,
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('dex_screen'),
      );
    } else if (tutProvider.hasSeenFeature('pokemon_details') &&
        !tutProvider.hasSeenFeature('ignored_pokemon')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'ignored_pokemon',
          nameKey: 'tutorial_feature_details',
          steps: [
            TutorialStep(
              targetKey: _sortMenuKey,
              titleKey: 'tutorial_dex_menu_ignored_title',
              textKey: 'tutorial_dex_menu_ignored_text',
              requireTargetTap: true,
              onTargetTap: () {
                setState(() => _showFakeMenu = true);
              },
            ),
            TutorialStep(
              targetKey: _fakeMenuIgnoredKey,
              titleKey: 'tutorial_dex_menu_ignored_btn_title',
              textKey: 'tutorial_dex_menu_ignored_btn_text',
              requireTargetTap: true,
              onTargetTap: () {
                setState(() => _showFakeMenu = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IgnoredListScreen(
                      dexId: widget.initialDex.id,
                      allRawEntries: _rawEntries,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _showTutorialIfNeeded();
                });
              },
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('ignored_pokemon'),
      );
    }
  }

  void _showMachomeiFoundTutorial() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    final dexProvider = Provider.of<DexProvider>(context, listen: false);

    final baseList = _rawEntries
        .where((e) => !widget.initialDex.ignoredIds.contains(e.uniqueId))
        .toList();
    final filtered = baseList
        .where((e) => _matchesSearch(e, widget.initialDex, dexProvider))
        .toList();

    if (filtered.isNotEmpty) {
      setState(() {
        _tutorialTargetId = filtered.first.uniqueId;
      });
    }

    TutorialOverlay.show(
      context,
      TutorialFeature(
        id: 'dex_machomei_found',
        nameKey: 'tutorial_feature_details',
        steps: [
          TutorialStep(
            targetKey: _firstPokemonKey,
            titleKey: 'tutorial_longpress_title',
            textKey: 'tutorial_longpress_text',
            requireTargetTap: true,
            preCalculateDelayMilliseconds: 800,
            onTargetTap: () {
              try {
                final listToUse = filtered.isNotEmpty ? filtered : baseList;
                if (listToUse.isNotEmpty) {
                  int targetIndex = listToUse.indexWhere(
                    (e) => e.uniqueId == _tutorialTargetId,
                  );
                  if (targetIndex == -1) targetIndex = 0;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => PokemonInfoScreen(
                        entries: listToUse,
                        initialIndex: targetIndex,
                        dexId: widget.initialDex.id,
                        isBoxView: _isBoxView,
                      ),
                    ),
                  ).then((_) {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                    if (mounted) _showTutorialIfNeeded();
                  });
                }
              } catch (e) {
                NotificationHelper.showError('${Translator.get('error')} $e');
              }
            },
          ),
        ],
      ),
      () => tutProvider.markFeatureAsSeen('dex_machomei_found'),
    );
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
    _debounce?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(
    DexDisplayEntry entry,
    UserDex liveDex,
    DexProvider provider,
  ) {
    if (_searchQuery.trim().isEmpty) return true;

    String formName = 'normal';
    if (entry.uniqueId.contains('_')) {
      formName = entry.uniqueId.substring(entry.uniqueId.indexOf('_') + 1);
      if (formName == 'm' || formName == 'f') formName = 'normal';
    }

    PokemonForm? form;
    try {
      form = entry.pokemon.forms.firstWhere((f) => f.name == formName);
    } catch (_) {}

    String regionId = DexLogicHelper.getPokemonRegionId(entry.pokemon, form);

    final orTerms = _searchQuery.toLowerCase().split(',');
    for (String orTerm in orTerms) {
      if (orTerm.trim().isEmpty) continue;

      final andTerms = orTerm.split('&');
      bool allAndsMatch = true;

      for (String term in andTerms) {
        term = term.trim();
        if (term.isEmpty) continue;

        bool match = false;

        final rangeMatch = RegExp(r'^#?(\d+)\s*-\s*#?(\d+)$').firstMatch(term);
        if (rangeMatch != null) {
          int min = int.parse(rangeMatch.group(1)!);
          int max = int.parse(rangeMatch.group(2)!);
          if (entry.pokemon.id >= min && entry.pokemon.id <= max) match = true;
        } else {
          final exactMatch = RegExp(r'^#?(\d+)$').firstMatch(term);
          if (exactMatch != null) {
            if (entry.pokemon.id == int.parse(exactMatch.group(1)!)) {
              match = true;
            }
          } else if (term == 'shiny') {
            if (liveDex.shinyIds.contains(entry.uniqueId)) match = true;
          } else if (term == 'caught') {
            if (liveDex.caughtIds.contains(entry.uniqueId)) match = true;
          } else if (term == 'uncaught' || term == 'missing') {
            if (!liveDex.caughtIds.contains(entry.uniqueId)) match = true;
          } else if (term == 'mega' || term == 'gmax') {
            if (entry.uniqueId.contains(term)) match = true;
          } else {
            final regionKeys = [
              'kanto',
              'johto',
              'hoenn',
              'sinnoh',
              'unova',
              'kalos',
              'alola',
              'galar',
              'hisui',
              'paldea',
            ];
            String? matchedRegion;
            for (var r in regionKeys) {
              if (term == r ||
                  term == Translator.get('group_$r').toLowerCase() ||
                  term == Translator.get('region_name_$r').toLowerCase()) {
                matchedRegion = r;
                break;
              }
            }

            if (matchedRegion != null) {
              if (regionId == matchedRegion) match = true;
            } else if (term.startsWith('+')) {
              String familyTarget = term.substring(1).trim();
              if (familyTarget.isNotEmpty) {
                final targetPoke = widget.pokemonList
                    .where(
                      (p) =>
                          p.getName(provider.currentLanguage).toLowerCase() ==
                          familyTarget,
                    )
                    .firstOrNull;

                if (targetPoke != null) {
                  final family = BreedingData.getFullFamily(targetPoke.id);
                  if (family.contains(
                    ShinyLogicHelper.getBaseForm(entry.pokemon.id),
                  )) {
                    match = true;
                  } else if (entry.pokemon.id == targetPoke.id) {
                    match = true;
                  }
                }
              }
            } else {
              final types = form?.types ?? [];
              bool typeMatch = types.any(
                (t) =>
                    t.toLowerCase() == term ||
                    Translator.get('type_$t').toLowerCase() == term,
              );

              if (typeMatch) {
                match = true;
              } else {
                final baseName = entry.pokemon
                    .getName(provider.currentLanguage)
                    .toLowerCase();
                final fullName = (baseName + entry.displaySuffix).toLowerCase();

                if (term.contains('*')) {
                  try {
                    String rStr =
                        '^' +
                        term
                            .split('*')
                            .map((s) => RegExp.escape(s))
                            .join('.*') +
                        '\$';
                    if (RegExp(rStr).hasMatch(fullName) ||
                        RegExp(rStr).hasMatch(baseName))
                      match = true;
                  } catch (_) {
                    if (fullName.contains(term)) match = true;
                  }
                } else {
                  if (fullName.contains(term) ||
                      entry.pokemon.id.toString() == term)
                    match = true;
                }
              }
            }
          }
        }

        if (!match) {
          allAndsMatch = false;
          break;
        }
      }

      if (allAndsMatch) return true;
    }
    return false;
  }

  void _showSearchHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          Translator.get('search_help_title') != 'search_help_title'
              ? Translator.get('search_help_title')
              : 'Such-Befehle',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _helpItem(
                '15 / #15',
                Translator.get('search_help_id') != 'search_help_id'
                    ? Translator.get('search_help_id')
                    : 'Sucht exakt nach einer ID.',
              ),
              _helpItem(
                '1-151',
                Translator.get('search_help_range') != 'search_help_range'
                    ? Translator.get('search_help_range')
                    : 'Zeigt Pok mon im ID-Bereich.',
              ),
              _helpItem(
                'shiny, caught, missing',
                Translator.get('search_help_status') != 'search_help_status'
                    ? Translator.get('search_help_status')
                    : 'Filtert nach Status.',
              ),
              _helpItem(
                'kanto, alola, mega',
                Translator.get('search_help_forms') != 'search_help_forms'
                    ? Translator.get('search_help_forms')
                    : 'Filtert nach Regionen oder Formen.',
              ),
              _helpItem(
                '+Bisasam',
                Translator.get('search_help_family') != 'search_help_family'
                    ? Translator.get('search_help_family')
                    : 'Zeigt die Entwicklungsreihe.',
              ),
              _helpItem(
                'Pika* / *chu',
                Translator.get('search_help_wildcard') != 'search_help_wildcard'
                    ? Translator.get('search_help_wildcard')
                    : 'Wildcard-Suche.',
              ),
              _helpItem(
                'shiny & kanto',
                Translator.get('search_help_and') != 'search_help_and'
                    ? Translator.get('search_help_and')
                    : 'Mit "&" m ssen beide Begriffe zutreffen.',
              ),
              _helpItem(
                '1-9, Evoli',
                Translator.get('search_help_or') != 'search_help_or'
                    ? Translator.get('search_help_or')
                    : 'Mit "," reicht ein Treffer (ODER).',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          children: [
            TextSpan(
              text: '$title\n',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextSpan(
              text: desc,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
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

    final caughtCount = liveDex.caughtIds.length;
    final baseList = _rawEntries
        .where((e) => !liveDex.ignoredIds.contains(e.uniqueId))
        .toList();

    final filteredList = baseList.where((entry) {
      final isCaught = liveDex.caughtIds.contains(entry.uniqueId);
      if (_filter == 'caught' && !isCaught) return false;
      if (_filter == 'uncaught' && isCaught) return false;

      return _matchesSearch(entry, liveDex, provider);
    }).toList();

    final totalCount = baseList.length;

    final List<BoxData> boxes = DexLogicHelper.generateBoxes(
      baseList,
      _separateForms,
      liveDex,
    );

    final bool isSearchActive =
        _searchQuery.trim().isNotEmpty || _filter != 'all';
    final Set<String> highlightedIds = filteredList
        .map((e) => e.uniqueId)
        .toSet();

    if (isSearchActive &&
        (_searchQuery != _lastSearchQuery || _filter != _lastFilter)) {
      _lastSearchQuery = _searchQuery;
      _lastFilter = _filter;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isBoxView && _pageController.hasClients) {
          int currentPage = _pageController.page?.round() ?? 0;
          if (boxes.isNotEmpty && currentPage < boxes.length) {
            bool currentHasMatch = boxes[currentPage].entries.any(
              (e) => highlightedIds.contains(e.uniqueId),
            );
            if (!currentHasMatch) {
              int firstMatchIndex = boxes.indexWhere(
                (box) =>
                    box.entries.any((e) => highlightedIds.contains(e.uniqueId)),
              );
              if (firstMatchIndex != -1) {
                _pageController.animateToPage(
                  firstMatchIndex,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              }
            }
          }
        }
      });
    } else if (!isSearchActive) {
      _lastSearchQuery = _searchQuery;
      _lastFilter = _filter;
    }

    Widget bodyContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: _searchBarKey,
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: Translator.get('search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () => _showSearchHelpDialog(context),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      setState(() => _searchQuery = val);

                      final tutProvider = Provider.of<TutorialProvider>(
                        context,
                        listen: false,
                      );
                      if (tutProvider.hasSeenFeature('dex_screen') &&
                          !tutProvider.hasSeenFeature('dex_machomei_found')) {
                        final q = val.toLowerCase().trim();
                        if (q == 'machomei' ||
                            q == 'machamp' ||
                            q == '068' ||
                            q == '68' ||
                            q == '#068') {
                          _showMachomeiFoundTutorial();
                        }
                      }
                    });
                  },
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
              ? DexBoxView(
                  firstItemKey: _firstPokemonKey,
                  tutorialTargetId: _tutorialTargetId,
                  boxes: boxes,
                  liveDex: liveDex,
                  provider: provider,
                  pageController: _pageController,
                  separateForms: _separateForms,
                  highlightedIds: highlightedIds,
                  isSearchActive: isSearchActive,
                )
              : DexListView(
                  firstItemKey: _firstPokemonKey,
                  tutorialTargetId: _tutorialTargetId,
                  displayList: filteredList,
                  liveDex: liveDex,
                  provider: provider,
                ),
        ),
      ],
    );

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
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: Translator.get('route_tracker'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouteTrackerScreen(
                    dexId: liveDex.id,
                    rawEntries: _rawEntries,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            key: _sortMenuKey,
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
                      allRawEntries: _rawEntries,
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
                          : 'Ausgeblendete Pokemon',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          bodyContent,
          if (_showFakeMenu)
            Positioned(
              top: 0,
              right: 8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        key: _fakeMenuBoxKey,
                        onTap: () {
                          setState(() => _showFakeMenu = false);
                          _toggleBoxView();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _isBoxView ? Icons.list : Icons.grid_view,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBoxView
                                    ? Translator.get('view_list')
                                    : Translator.get('view_box'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        key: _fakeMenuFormsKey,
                        onTap: () {
                          _toggleSeparateForms();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                      ),
                      const Divider(height: 1),
                      InkWell(
                        key: _fakeMenuIgnoredKey,
                        onTap: () {
                          setState(() => _showFakeMenu = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IgnoredListScreen(
                                dexId: liveDex.id,
                                allRawEntries: _rawEntries,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) _showTutorialIfNeeded();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_off, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                Translator.get('ignored_list_title') !=
                                        'ignored_list_title'
                                    ? Translator.get('ignored_list_title')
                                    : 'Ausgeblendete Pokemon',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
