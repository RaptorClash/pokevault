import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pokemon.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../data/encounters_data.dart';
import '../../l10n/app_translations.dart';

class RoutePokemonEncounter {
  final Pokemon pokemon;
  final String method;
  int minLevel = 999;
  int maxLevel = -1;
  int totalChance = 0;

  final List<DexDisplayEntry> targets = [];
  final Set<String> _processedLocStrs = {};

  RoutePokemonEncounter(this.pokemon, this.method);

  void addData(String locStr, String lvlStr, String chanceStr) {
    if (_processedLocStrs.contains(locStr)) return;
    _processedLocStrs.add(locStr);

    if (lvlStr.isNotEmpty) {
      var parts = lvlStr.split('-');
      int? lMin = int.tryParse(parts[0]);
      int? lMax = parts.length > 1 ? int.tryParse(parts[1]) : lMin;

      if (lMin != null && lMin < minLevel) minLevel = lMin;
      if (lMax != null && lMax > maxLevel) maxLevel = lMax;
    }

    int? c = int.tryParse(chanceStr.replaceAll(RegExp(r'[^0-9]'), ''));
    if (c != null) {
      totalChance += c;
    }
  }

  String get levelText {
    if (minLevel == 999 || maxLevel == -1) return '';
    if (minLevel == maxLevel) return 'Lv. $minLevel';
    return 'Lv. $minLevel-$maxLevel';
  }

  String get chanceText {
    if (totalChance == 0) return '';
    return '${totalChance > 100 ? 100 : totalChance} %';
  }
}

class RouteTrackerScreen extends StatefulWidget {
  final String dexId;
  final List<DexDisplayEntry> rawEntries;

  const RouteTrackerScreen({
    super.key,
    required this.dexId,
    required this.rawEntries,
  });

  @override
  State<RouteTrackerScreen> createState() => _RouteTrackerScreenState();
}

class _RouteTrackerScreenState extends State<RouteTrackerScreen> {
  String? _selectedVersion;
  List<String> _availableVersions = [];
  bool _hideCaught = false;

  final Map<String, String> _versionToGenMap = {
    'red': 'Gen 1',
    'blue': 'Gen 1',
    'yellow': 'Gen 1',
    'gold': 'Gen 2',
    'silver': 'Gen 2',
    'crystal': 'Gen 2',
    'ruby': 'Gen 3',
    'sapphire': 'Gen 3',
    'emerald': 'Gen 3',
    'firered': 'Gen 3',
    'leafgreen': 'Gen 3',
    'diamond': 'Gen 4',
    'pearl': 'Gen 4',
    'platinum': 'Gen 4',
    'heartgold': 'Gen 4',
    'soulsilver': 'Gen 4',
    'black': 'Gen 5',
    'white': 'Gen 5',
    'black-2': 'Gen 5',
    'white-2': 'Gen 5',
    'x': 'Gen 6',
    'y': 'Gen 6',
    'omega-ruby': 'Gen 6',
    'alpha-sapphire': 'Gen 6',
    'sun': 'Gen 7',
    'moon': 'Gen 7',
    'ultra-sun': 'Gen 7',
    'ultra-moon': 'Gen 7',
    'lets-go-pikachu': 'Gen 7',
    'lets-go-eevee': 'Gen 7',
    'sword': 'Gen 8',
    'shield': 'Gen 8',
    'the-isle-of-armor-sword': 'Gen 8',
    'the-isle-of-armor-shield': 'Gen 8',
    'the-crown-tundra-sword': 'Gen 8',
    'the-crown-tundra-shield': 'Gen 8',
    'brilliant-diamond': 'Gen 8',
    'shining-pearl': 'Gen 8',
    'legends-arceus': 'Gen 8',
    'scarlet': 'Gen 9',
    'violet': 'Gen 9',
    'the-teal-mask-scarlet': 'Gen 9',
    'the-teal-mask-violet': 'Gen 9',
    'the-indigo-disk-scarlet': 'Gen 9',
    'the-indigo-disk-violet': 'Gen 9',
    'colosseum': 'Spin-off',
    'xd': 'Spin-off',
  };

  @override
  void initState() {
    super.initState();
    _computeAvailableVersions();
  }

  bool _isValidEncounterForVersion(DexDisplayEntry entry, String version) {
    if (entry.uniqueId.contains('_mega') || entry.uniqueId.contains('_gmax')) {
      return false;
    }
    if (entry.uniqueId == '670_eternal') return false;

    String genStr = _versionToGenMap[version] ?? 'Gen 9';
    int currentGenNum =
        int.tryParse(genStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9;

    String formName = 'normal';
    if (entry.uniqueId.contains('_')) {
      formName = entry.uniqueId.substring(entry.uniqueId.indexOf('_') + 1);
      if (formName == 'm' || formName == 'f') formName = 'normal';
    }

    int minGen = 1;
    bool isRegional = false;
    try {
      final form = entry.pokemon.forms.firstWhere((f) => f.name == formName);
      minGen = form.minGen;
      isRegional = form.formType == 'regional';
    } catch (_) {}

    if (currentGenNum < minGen) return false;

    if (isRegional) {
      if (formName.contains('alola') &&
          !(version.contains('sun') ||
              version.contains('moon') ||
              version.contains('lets-go'))) {
        return false;
      }
      if (formName.contains('galar') &&
          !(version.contains('sword') || version.contains('shield'))) {
        return false;
      }
      if (formName.contains('hisui') && !(version.contains('legends'))) {
        return false;
      }
      if (formName.contains('paldea') &&
          !(version.contains('scarlet') || version.contains('violet'))) {
        return false;
      }
    }

    return true;
  }

  List<String> _getAllowedVersionsForDex(String region) {
    if (region.contains('kanto')) {
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
    if (region.contains('johto')) {
      return ['gold', 'silver', 'crystal', 'heartgold', 'soulsilver'];
    }
    if (region.contains('hoenn')) {
      return ['ruby', 'sapphire', 'emerald', 'omega-ruby', 'alpha-sapphire'];
    }
    if (region.contains('sinnoh')) {
      return [
        'diamond',
        'pearl',
        'platinum',
        'brilliant-diamond',
        'shining-pearl',
      ];
    }
    if (region.contains('unova')) {
      return ['black', 'white', 'black-2', 'white-2'];
    }
    if (region.contains('kalos') || region.contains('lumiose')) {
      return ['x', 'y'];
    }
    if (region.contains('alola')) {
      return ['sun', 'moon', 'ultra-sun', 'ultra-moon'];
    }
    if (region.contains('galar') ||
        region.contains('armor') ||
        region.contains('tundra')) {
      return [
        'sword',
        'shield',
        'the-isle-of-armor-sword',
        'the-isle-of-armor-shield',
        'the-crown-tundra-sword',
        'the-crown-tundra-shield',
      ];
    }
    if (region.contains('hisui')) return ['legends-arceus'];
    if (region.contains('paldea') ||
        region.contains('kitakami') ||
        region.contains('blueberry')) {
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

  void _computeAvailableVersions() {
    final provider = Provider.of<DexProvider>(context, listen: false);
    final liveDex = provider.userDexes.firstWhere((d) => d.id == widget.dexId);
    final allowedVersions = _getAllowedVersionsForDex(liveDex.region);

    Set<String> vSet = {};
    for (var entry in widget.rawEntries) {
      if (entry.uniqueId.contains('_mega') || entry.uniqueId.contains('_gmax')) {
        continue;
      }

      final encs = encountersDatabase[entry.pokemon.id];
      if (encs != null) {
        for (var genMap in encs.values) {
          for (var version in genMap.keys) {
            if (allowedVersions.isEmpty || allowedVersions.contains(version)) {
              if (_isValidEncounterForVersion(entry, version)) {
                vSet.add(version);
              }
            }
          }
        }
      }
    }

    _availableVersions = vSet.toList()..sort();
    if (_availableVersions.isNotEmpty) {
      _selectedVersion = _availableVersions.first;
    }
  }

  void _showVersionSelectionSheet() {
    Map<String, List<String>> groupedVersions = {};
    for (String v in _availableVersions) {
      String gen = _versionToGenMap[v] ?? 'Andere';
      groupedVersions.putIfAbsent(gen, () => []).add(v);
    }

    List<String> sortedGens = groupedVersions.keys.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    Translator.get('select_version'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sortedGens.length,
                    itemBuilder: (ctx, index) {
                      String gen = sortedGens[index];
                      List<String> games = groupedVersions[gen]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              gen,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: games.map((v) {
                              String vName = Translator.get('version_$v');
                              if (vName == 'version_$v') vName = v;
                              bool isSelected = _selectedVersion == v;

                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ChoiceChip(
                                  label: Text(vName),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedVersion = v;
                                      });
                                      Navigator.pop(ctx);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _getLocationWeight(String loc) {
    final l = loc.toLowerCase();
    if (l.contains('roaming')) return 5;
    if (l.contains('friend safari') || l.contains('max lair')) return 4;
    if (l.contains('route')) return 1;
    if (l.contains('city') || l.contains('town') || l.contains('island')) {
      return 2;
    }
    return 3;
  }

  int _compareLocations(String a, String b) {
    int weightA = _getLocationWeight(a);
    int weightB = _getLocationWeight(b);

    if (weightA != weightB) {
      return weightA.compareTo(weightB);
    }

    if (weightA == 1) {
      final reg = RegExp(r'\d+');
      final matchA = reg.firstMatch(a);
      final matchB = reg.firstMatch(b);
      if (matchA != null && matchB != null) {
        int numA = int.parse(matchA.group(0)!);
        int numB = int.parse(matchB.group(0)!);
        if (numA != numB) return numA.compareTo(numB);
      }
    }

    return _translateLoc(a).compareTo(_translateLoc(b));
  }

  String _translateLoc(String loc) {
    String transBase = Translator.get(loc);
    if (transBase == loc) {
      transBase = Translator.get('loc_$loc');
      if (transBase == 'loc_$loc') {
        return loc;
      }
    }
    return transBase;
  }

  String _translateMethod(String method) {
    if (method.isEmpty) return '';
    String tMethod = Translator.get('method_$method');
    if (tMethod == 'method_$method') {
      tMethod = Translator.get(method);
      if (tMethod == method) return method;
    }
    return tMethod;
  }

  String _getLabelForEntry(DexDisplayEntry entry) {
    if (entry.uniqueId.endsWith('_m')) return '♂';
    if (entry.uniqueId.endsWith('_f')) return '♀';
    if (entry.displaySuffix.isNotEmpty) {
      return entry.displaySuffix.replaceAll('(', '').replaceAll(')', '').trim();
    }
    return 'Standard';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere((d) => d.id == widget.dexId);

    Map<String, Map<String, RoutePokemonEncounter>> locationMap = {};

    if (_selectedVersion != null) {
      for (var entry in widget.rawEntries) {
        if (liveDex.ignoredIds.contains(entry.uniqueId)) continue;
        if (!_isValidEncounterForVersion(entry, _selectedVersion!)) continue;

        final encs = encountersDatabase[entry.pokemon.id];
        if (encs == null) continue;

        for (var gen in encs.values) {
          if (gen.containsKey(_selectedVersion)) {
            for (var locStr in gen[_selectedVersion]!) {
              var parts = locStr.split('|||');
              String locName = parts[0];
              String method = parts.length > 1 ? parts[1] : '';
              String lvl = parts.length > 2 ? parts[2] : '';
              String chance = parts.length > 3 ? parts[3] : '';

              locationMap.putIfAbsent(locName, () => {});

              String aggKey = '${entry.pokemon.id}_$method';
              locationMap[locName]!.putIfAbsent(
                aggKey,
                () => RoutePokemonEncounter(entry.pokemon, method),
              );

              var routeEnc = locationMap[locName]![aggKey]!;
              if (!routeEnc.targets.contains(entry)) {
                routeEnc.targets.add(entry);
              }

              routeEnc.addData(locStr, lvl, chance);
            }
          }
        }
      }
    }

    locationMap.forEach((locName, encMap) {
      encMap.removeWhere((aggKey, enc) {
        bool allCaught = enc.targets.every(
          (t) => liveDex.caughtIds.contains(t.uniqueId),
        );
        return _hideCaught && allCaught;
      });
    });
    locationMap.removeWhere((locName, encMap) => encMap.isEmpty);

    final sortedLocations = locationMap.keys.toList()..sort(_compareLocations);

    String currentVersionName = _selectedVersion != null
        ? Translator.get('version_$_selectedVersion')
        : 'Keine';
    if (currentVersionName == 'version_$_selectedVersion') {
      currentVersionName = _selectedVersion!;
    }

    return Scaffold(
      appBar: AppBar(title: Text(Translator.get('route_tracker'))),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              children: [
                if (_availableVersions.isNotEmpty)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.videogame_asset,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        Translator.get('select_version'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        currentVersionName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.expand_more),
                      onTap: _showVersionSelectionSheet,
                    ),
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    Translator.get('hide_caught'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: _hideCaught,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    setState(() {
                      _hideCaught = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: sortedLocations.isEmpty
                ? Center(
                    child: Text(
                      Translator.get('route_tracker_empty'),
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedLocations.length,
                    itemBuilder: (context, index) {
                      String rawLocName = sortedLocations[index];
                      List<RoutePokemonEncounter> encounters =
                          locationMap[rawLocName]!.values.toList();

                      bool allCaught = encounters.every(
                        (e) => e.targets.every(
                          (t) => liveDex.caughtIds.contains(t.uniqueId),
                        ),
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: allCaught
                                ? Colors.green
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          leading: Icon(
                            allCaught ? Icons.check_circle : Icons.map,
                            color: allCaught
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            _translateLoc(rawLocName),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: allCaught ? Colors.green : null,
                            ),
                          ),
                          subtitle: Text('${encounters.length} Pokémon-Arten'),
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: encounters.length,
                              separatorBuilder: (context, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, encIndex) {
                                final enc = encounters[encIndex];
                                bool rowAllCaught = enc.targets.every(
                                  (t) => liveDex.caughtIds.contains(t.uniqueId),
                                );

                                String methodText = _translateMethod(
                                  enc.method,
                                );
                                String lvlText = enc.levelText;
                                String chanceText = enc.chanceText;

                                List<String> subParts = [];
                                if (methodText.isNotEmpty) {
                                  subParts.add(methodText);
                                }
                                if (lvlText.isNotEmpty) subParts.add(lvlText);
                                if (chanceText.isNotEmpty) {
                                  subParts.add(chanceText);
                                }

                                return ListTile(
                                  tileColor: rowAllCaught
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : null,
                                  leading: Image.network(
                                    enc.targets.first.imageUrl,
                                    width: 48,
                                    height: 48,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.catching_pokemon),
                                  ),
                                  title: Text(
                                    enc.pokemon.getName(
                                      provider.currentLanguage,
                                    ),
                                    style: TextStyle(
                                      fontWeight: rowAllCaught
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subParts.join(' • '),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (enc.targets.length > 1) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: enc.targets.map((t) {
                                            bool isTargetCaught = liveDex
                                                .caughtIds
                                                .contains(t.uniqueId);
                                            return FilterChip(
                                              label: Text(
                                                _getLabelForEntry(t),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                              selected: isTargetCaught,
                                              showCheckmark: false,
                                              selectedColor: Colors.green
                                                  .withValues(alpha: 0.3),
                                              side: BorderSide(
                                                color: isTargetCaught
                                                    ? Colors.green
                                                    : Theme.of(
                                                        context,
                                                      ).dividerColor,
                                              ),
                                              onSelected: (val) {
                                                provider.togglePokemon(
                                                  widget.dexId,
                                                  t.uniqueId,
                                                );
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: enc.targets.length == 1
                                      ? Checkbox(
                                          value: rowAllCaught,
                                          activeColor: Colors.green,
                                          onChanged: (val) {
                                            provider.togglePokemon(
                                              widget.dexId,
                                              enc.targets.first.uniqueId,
                                            );
                                          },
                                        )
                                      : null,
                                  onTap: enc.targets.length == 1
                                      ? () {
                                          provider.togglePokemon(
                                            widget.dexId,
                                            enc.targets.first.uniqueId,
                                          );
                                        }
                                      : null,
                                );
                              },
                            ),
                          ],
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
