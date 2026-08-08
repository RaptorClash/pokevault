import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_dex.dart';
import '../models/pokemon.dart';
import '../models/dex_view_models.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';
import '../utils/dex_logic_helper.dart';
import 'pokemon_info_screen.dart';
import 'ignored_list_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere(
      (d) => d.id == widget.initialDex.id,
      orElse: () => widget.initialDex,
    );

    List<DexDisplayEntry> rawEntries = [];
    try {
      rawEntries = DexLogicHelper.buildDisplayEntries(
        liveDex,
        provider,
        widget.pokemonList,
      );
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
    final List<BoxData> boxes = DexLogicHelper.generateBoxes(
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
                          : 'Ausgeblendete Pokemon',
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
                ? DexBoxView(
                    boxes: boxes,
                    liveDex: liveDex,
                    provider: provider,
                    pageController: _pageController,
                    separateForms: _separateForms,
                  )
                : DexListView(
                    displayList: displayList,
                    liveDex: liveDex,
                    provider: provider,
                  ),
          ),
        ],
      ),
    );
  }
}

class DexBoxView extends StatelessWidget {
  final List<BoxData> boxes;
  final UserDex liveDex;
  final DexProvider provider;
  final PageController pageController;
  final bool separateForms;

  const DexBoxView({
    super.key,
    required this.boxes,
    required this.liveDex,
    required this.provider,
    required this.pageController,
    required this.separateForms,
  });

  void _showQuickNavDialog(BuildContext context) {
    final Map<String, int> regionFirstIndices = {};
    for (int i = 0; i < boxes.length; i++) {
      if (!regionFirstIndices.containsKey(boxes[i].regionKey)) {
        regionFirstIndices[boxes[i].regionKey] = i;
      }
    }
    showDialog(
      context: context,
      builder: (ctx) {
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
                      ctx,
                    ).colorScheme.surfaceContainerHighest,
                    onPressed: () {
                      Navigator.pop(ctx);
                      pageController.jumpToPage(boxIndex);
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

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return Center(child: Text(Translator.get('empty_box')));

    double screenWidth = MediaQuery.of(context).size.width;
    double boxMaxWidth = screenWidth > 1200
        ? 1100
        : (screenWidth > 800 ? 800 : double.infinity);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: boxMaxWidth),
        child: PageView.builder(
          controller: pageController,
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
                            if (pageController.hasClients &&
                                pageController.page! > 0) {
                              pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            if (separateForms && boxes.length > 1)
                              _showQuickNavDialog(context);
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
                                if (separateForms && boxes.length > 1)
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
                            if (pageController.hasClients &&
                                pageController.page! < boxes.length - 1) {
                              pageController.nextPage(
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
                                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${liveDex.isShinyDex ? 'shiny/' : ''}${entry.pokemon.id}.png',
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
}

class DexListView extends StatelessWidget {
  final List<DexDisplayEntry> displayList;
  final UserDex liveDex;
  final DexProvider provider;

  const DexListView({
    super.key,
    required this.displayList,
    required this.liveDex,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (displayList.isEmpty)
      return Center(child: Text(Translator.get('empty_box')));

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
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${liveDex.isShinyDex ? 'shiny/' : ''}${entry.pokemon.id}.png',
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.catching_pokemon,
                                  size: 24,
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
