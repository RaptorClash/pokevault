import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dex_view_models.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../l10n/app_translations.dart';

class RawEncounter {
  final String version;
  final String location;
  final DexDisplayEntry entry;

  RawEncounter({
    required this.version,
    required this.location,
    required this.entry,
  });
}

class RouteTrackerScreen extends StatefulWidget {
  final UserDex liveDex;
  final List<DexDisplayEntry> displayEntries;

  const RouteTrackerScreen({
    super.key,
    required this.liveDex,
    required this.displayEntries,
  });

  @override
  State<RouteTrackerScreen> createState() => _RouteTrackerScreenState();
}

class _RouteTrackerScreenState extends State<RouteTrackerScreen> {
  bool _isLoading = true;
  List<RawEncounter> _allEncounters = [];

  Set<String> _selectedGames = {};
  bool _hideCompleted = false;
  List<String> _availableGames = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _availableGames = _getGamesForRegion(widget.liveDex.region);
    _selectedGames = _availableGames.toSet();
    _loadRouteDataOptimized();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getGamesForRegion(String region) {
    final reg = region.toLowerCase();

    if (reg.contains('national') ||
        reg.contains('mega') ||
        reg.contains('icognito')) {
      return [
        'red',
        'blue',
        'yellow',
        'gold',
        'silver',
        'crystal',
        'ruby',
        'sapphire',
        'emerald',
        'firered',
        'leafgreen',
        'diamond',
        'pearl',
        'platinum',
        'heartgold',
        'soulsilver',
        'black',
        'white',
        'black-2',
        'white-2',
        'x',
        'y',
        'omega-ruby',
        'alpha-sapphire',
        'sun',
        'moon',
        'ultra-sun',
        'ultra-moon',
        'lets-go-pikachu',
        'lets-go-eevee',
        'sword',
        'shield',
        'the-isle-of-armor-sword',
        'the-isle-of-armor-shield',
        'the-crown-tundra-sword',
        'the-crown-tundra-shield',
        'brilliant-diamond',
        'shining-pearl',
        'legends-arceus',
        'scarlet',
        'violet',
        'the-teal-mask-scarlet',
        'the-teal-mask-violet',
        'the-indigo-disk-scarlet',
        'the-indigo-disk-violet',
        'legends-z-a',
      ];
    }

    if (reg.contains('kanto')) {
      return [
        'red',
        'blue',
        'yellow',
        'firered',
        'leafgreen',
        'lets-go-pikachu',
        'lets-go-eevee',
      ];
    }
    if (reg.contains('johto')) {
      return ['gold', 'silver', 'crystal', 'heartgold', 'soulsilver'];
    }
    if (reg.contains('hoenn')) {
      return ['ruby', 'sapphire', 'emerald', 'omega-ruby', 'alpha-sapphire'];
    }
    if (reg.contains('sinnoh')) {
      return [
        'diamond',
        'pearl',
        'platinum',
        'brilliant-diamond',
        'shining-pearl',
      ];
    }
    if (reg.contains('unova')) {
      return ['black', 'white', 'black-2', 'white-2'];
    }
    if (reg.contains('kalos') || reg.contains('lumiose')) {
      return ['x', 'y', 'legends-z-a'];
    }
    if (reg.contains('alola') ||
        reg.contains('melemele') ||
        reg.contains('akala') ||
        reg.contains('ulaula') ||
        reg.contains('poni')) {
      return ['sun', 'moon', 'ultra-sun', 'ultra-moon'];
    }
    if (reg.contains('galar') ||
        reg.contains('armor') ||
        reg.contains('tundra')) {
      return [
        'sword',
        'shield',
        'the-isle-of-armor-sword',
        'the-isle-of-armor-shield',
        'the-crown-tundra-sword',
        'the-crown-tundra-shield',
      ];
    }
    if (reg.contains('hisui')) return ['legends-arceus'];
    if (reg.contains('paldea') ||
        reg.contains('kitakami') ||
        reg.contains('blueberry')) {
      return [
        'scarlet',
        'violet',
        'the-teal-mask-scarlet',
        'the-teal-mask-violet',
        'the-indigo-disk-scarlet',
        'the-indigo-disk-violet',
      ];
    }

    return [];
  }

  int _getGenForGame(String game) {
    if (['red', 'blue', 'yellow'].contains(game)) return 1;
    if (['gold', 'silver', 'crystal'].contains(game)) return 2;
    if ([
      'ruby',
      'sapphire',
      'emerald',
      'firered',
      'leafgreen',
    ].contains(game)) {
      return 3;
    }
    if ([
      'diamond',
      'pearl',
      'platinum',
      'heartgold',
      'soulsilver',
    ].contains(game)) {
      return 4;
    }
    if (['black', 'white', 'black-2', 'white-2'].contains(game)) return 5;
    if (['x', 'y', 'omega-ruby', 'alpha-sapphire'].contains(game)) return 6;
    if ([
      'sun',
      'moon',
      'ultra-sun',
      'ultra-moon',
      'lets-go-pikachu',
      'lets-go-eevee',
    ].contains(game)) {
      return 7;
    }
    if ([
      'sword',
      'shield',
      'the-isle-of-armor-sword',
      'the-isle-of-armor-shield',
      'the-crown-tundra-sword',
      'the-crown-tundra-shield',
      'brilliant-diamond',
      'shining-pearl',
      'legends-arceus',
    ].contains(game)) {
      return 8;
    }
    if ([
      'scarlet',
      'violet',
      'the-teal-mask-scarlet',
      'the-teal-mask-violet',
      'the-indigo-disk-scarlet',
      'the-indigo-disk-violet',
      'legends-z-a',
    ].contains(game)) {
      return 9;
    }
    return 0;
  }

  String _getTranslatedGameName(String game) {
    String key = 'version_$game';
    String translated = Translator.get(key);

    if (translated == key) {
      return game
          .split('-')
          .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
          .join(' ');
    }
    return translated;
  }

  Future<void> _loadRouteDataOptimized() async {
    List<RawEncounter> tempEncounters = [];
    final db = await DatabaseService.instance.appDatabase;

    final uniqueIds = widget.displayEntries
        .map((e) => e.pokemon.id)
        .toSet()
        .toList();
    Map<int, List<DexDisplayEntry>> entriesById = {};
    for (var entry in widget.displayEntries) {
      entriesById.putIfAbsent(entry.pokemon.id, () => []).add(entry);
    }

    for (int i = 0; i < uniqueIds.length; i += 900) {
      final chunk = uniqueIds.sublist(
        i,
        i + 900 > uniqueIds.length ? uniqueIds.length : i + 900,
      );
      final placeholders = List.filled(chunk.length, '?').join(',');

      final maps = await db.query(
        'encounters',
        where: 'pokemon_id IN ($placeholders)',
        whereArgs: chunk,
      );

      for (var map in maps) {
        int pId = map['pokemon_id'] as int;
        String version = map['version'].toString();

        if (!_availableGames.contains(version)) continue;

        String locDataStr = map['location_data'].toString();
        List<String> locs = locDataStr.split('|||||');

        for (var locStr in locs) {
          String baseLoc = locStr
              .split('|||')[0]
              .replaceAll(RegExp(r'\s*\(.*\)'), '')
              .trim();
          if (baseLoc.isNotEmpty) {
            for (var entry in entriesById[pId] ?? []) {
              tempEncounters.add(
                RawEncounter(version: version, location: baseLoc, entry: entry),
              );
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _allEncounters = tempEncounters;
        _isLoading = false;
      });
    }
  }

  Map<String, List<DexDisplayEntry>> _getFilteredRoutes(
    String currentLanguage,
  ) {
    Map<String, List<DexDisplayEntry>> map = {};

    for (var enc in _allEncounters) {
      if (_selectedGames.contains(enc.version)) {
        bool matchesSearch = true;

        if (_searchQuery.isNotEmpty) {
          final locMatch = enc.location.toLowerCase().contains(_searchQuery);
          final pokeMatch = enc.entry.pokemon
              .getName(currentLanguage)
              .toLowerCase()
              .contains(_searchQuery);
          matchesSearch = locMatch || pokeMatch;
        }

        if (matchesSearch) {
          map.putIfAbsent(enc.location, () => []);
          if (!map[enc.location]!.any(
            (e) => e.uniqueId == enc.entry.uniqueId,
          )) {
            map[enc.location]!.add(enc.entry);
          }
        }
      }
    }

    if (_hideCompleted) {
      map.removeWhere((loc, entries) {
        return entries.every(
          (e) => widget.liveDex.caughtIds.contains(e.uniqueId),
        );
      });
    }

    var sortedKeys = map.keys.toList()..sort();
    Map<String, List<DexDisplayEntry>> sortedMap = {};
    for (var k in sortedKeys) {
      sortedMap[k] = map[k]!;
    }

    return sortedMap;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final routesMap = _getFilteredRoutes(settingsProvider.currentLanguage);

    return Scaffold(
      appBar: AppBar(title: Text(Translator.get('route_tracker_title'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16.0),
              itemCount: routesMap.isEmpty ? 3 : routesMap.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _buildSearchBar();
                if (index == 1) return _buildFilterHeader(context);

                if (routesMap.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        Translator.get(
                          'no_encounters_found',
                          fallback: 'Keine Fundorte gefunden.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final routeName = routesMap.keys.elementAt(index - 2);
                final entries = routesMap[routeName]!;
                int caughtCount = entries
                    .where((e) => widget.liveDex.caughtIds.contains(e.uniqueId))
                    .length;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      routeName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$caughtCount / ${entries.length} ${Translator.get('caught', fallback: 'gefangen')}',
                      style: TextStyle(
                        color: caughtCount == entries.length
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: entries.map((entry) {
                      bool isCaught = widget.liveDex.caughtIds.contains(
                        entry.uniqueId,
                      );
                      return ListTile(
                        leading: Image.network(
                          entry.imageUrl,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.catching_pokemon,
                                color: Colors.grey,
                              ),
                        ),
                        title: Text(
                          entry.pokemon.getName(
                                settingsProvider.currentLanguage,
                              ) +
                              entry.displaySuffix,
                        ),
                        subtitle: Text(
                          '#${entry.pokemon.id.toString().padLeft(3, '0')}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.catching_pokemon,
                            color: isCaught ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            provider.togglePokemon(
                              widget.liveDex.id,
                              entry.uniqueId,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: Translator.get(
            'search_route_pokemon',
            fallback: 'Suche Route oder Pokémon...',
          ),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    Map<int, List<String>> gamesByGen = {};
    for (var game in _availableGames) {
      int gen = _getGenForGame(game);
      gamesByGen.putIfAbsent(gen, () => []).add(game);
    }
    var sortedGens = gamesByGen.keys.toList()..sort();

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              Translator.get(
                'hide_completed_routes',
                fallback: 'Fertige Routen ausblenden',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            value: _hideCompleted,
            onChanged: (val) {
              setState(() {
                _hideCompleted = val;
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(height: 1),

          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(
                Icons.tune,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                Translator.get(
                  'games_filter_title',
                  fallback: 'Spiele & Editionen filtern',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Translator.get(
                              'visible_editions',
                              fallback: 'Sichtbare Editionen',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedGames.clear();
                                  });
                                },
                                child: Text(
                                  Translator.get('none', fallback: 'Keine'),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedGames = _availableGames.toSet();
                                  });
                                },
                                child: Text(
                                  Translator.get('all', fallback: 'Alle'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...sortedGens.map((gen) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  Translator.get(
                                    'generation_x',
                                    fallback: 'Generation {0}',
                                  ).replaceAll('{0}', gen.toString()),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: gamesByGen[gen]!.map((game) {
                                  final isSelected = _selectedGames.contains(
                                    game,
                                  );
                                  return FilterChip(
                                    label: Text(
                                      _getTranslatedGameName(game),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedGames.add(game);
                                        } else {
                                          _selectedGames.remove(game);
                                        }
                                      });
                                    },
                                    selectedColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    checkmarkColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
