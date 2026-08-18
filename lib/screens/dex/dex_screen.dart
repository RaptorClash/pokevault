import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_dex.dart';
import '../../models/pokemon.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../l10n/app_translations.dart';
import '../../utils/dex_logic_helper.dart';
import '../ignored_list/ignored_list_screen.dart';
import 'dex_box_view.dart';
import 'dex_list_view.dart';
import 'route_tracker_screen.dart';

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

  late List<DexDisplayEntry> _rawEntries;

  @override
  void initState() {
    super.initState();
    _loadPrefs();

    _rawEntries = DexLogicHelper.buildDisplayEntries(
      widget.initialDex,
      context.read<DexProvider>(),
      widget.pokemonList,
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
    _pageController.dispose();
    super.dispose();
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
    final filteredList = _rawEntries.where((entry) {
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

    final totalCount = _rawEntries
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
