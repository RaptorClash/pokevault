import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dex_orders.dart';
import '../data/national_dex_data.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';
import '../utils/shiny_logic_helper.dart';
import '../providers/dex_provider.dart';

class BreedingCalculatorWidget extends StatefulWidget {
  final int initialTargetId;
  final String dexId;

  const BreedingCalculatorWidget({
    super.key,
    required this.initialTargetId,
    required this.dexId,
  });

  @override
  State<BreedingCalculatorWidget> createState() =>
      _BreedingCalculatorWidgetState();
}

class _BreedingCalculatorWidgetState extends State<BreedingCalculatorWidget> {
  int _startId = 130;
  late int _targetId;
  List<int>? _path;
  List<List<int>>? _allPaths;
  int _selectedPathIndex = 0;
  bool _useOnlyCaught = false;

  final Set<int> _genderless = {
    81,
    82,
    100,
    101,
    120,
    121,
    132,
    137,
    201,
    233,
    243,
    244,
    245,
    249,
    250,
    251,
  };
  final Set<int> _onlyMale = {32, 33, 34, 106, 107, 128, 236, 237};
  final Set<int> _onlyFemale = {29, 30, 31, 113, 115, 124, 238, 241, 242};

  final Set<int> _lowFemaleRatio = {
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    133,
    134,
    135,
    136,
    138,
    139,
    140,
    141,
    142,
    143,
    152,
    153,
    154,
    155,
    156,
    157,
    158,
    159,
    160,
    175,
    176,
    196,
    197,
  };

  final Set<int> _ratio75m = {
    58,
    59,
    63,
    64,
    65,
    66,
    67,
    68,
    125,
    126,
    239,
    240,
  };

  final Set<int> _ratio25m = {35, 36, 37, 38, 39, 40, 173, 174, 209, 210, 222};

  @override
  void initState() {
    super.initState();
    _targetId = widget.initialTargetId;
    if (_targetId > 251 ||
        (!ShinyLogicHelper.isBreedable(_targetId) &&
            !ShinyLogicHelper.isBaby(_targetId))) {
      _targetId = 1;
    }
    if (_targetId == _startId) {
      _startId = 4;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allPaths == null) {
      _calculatePath();
    }
  }

  List<int> get _validStartIds {
    List<int> ids = [];
    for (int i = 1; i <= 251; i++) {
      if (ShinyLogicHelper.isBreedable(i) ||
          ShinyLogicHelper.isBaby(i) ||
          i == 132) {
        ids.add(i);
      }
    }
    return ids;
  }

  String _getPokemonDisplayName(int id) {
    final p = nationalPokemonDatabase.firstWhere((p) => p.id == id);
    return '#${id.toString().padLeft(3, '0')} ${p.getName(Translator.currentLanguage)}';
  }

  String _getPokemonNameOnly(int id) {
    final p = nationalPokemonDatabase.firstWhere((p) => p.id == id);
    return p.getName(Translator.currentLanguage);
  }

  Map<int, List<String>> _getEggGroups() {
    Map<int, List<String>> eggGroups = {};
    void addGroups(List<int> ids, String group) {
      for (int id in ids) {
        if (id > 251) continue;
        eggGroups.putIfAbsent(id, () => []).add(group);
      }
    }

    addGroups(ordereggmonster, 'Monster');
    addGroups(ordereggplant, 'Plant');
    addGroups(ordereggdragon, 'Dragon');
    addGroups(ordereggwater1, 'Water 1');
    addGroups(ordereggbug, 'Bug');
    addGroups(ordereggflying, 'Flying');
    addGroups(ordereggground, 'Field');
    addGroups(ordereggfairy, 'Fairy');
    addGroups(orderegghumanshape, 'Human-Like');
    addGroups(ordereggwater3, 'Water 3');
    addGroups(ordereggmineral, 'Mineral');
    addGroups(ordereggindeterminate, 'Amorphous');
    addGroups(ordereggwater2, 'Water 2');

    eggGroups[172] = ['Field', 'Fairy'];
    eggGroups[173] = ['Fairy'];
    eggGroups[174] = ['Fairy'];
    eggGroups[236] = ['Human-Like'];
    eggGroups[238] = ['Human-Like'];
    eggGroups[239] = ['Human-Like'];
    eggGroups[240] = ['Human-Like'];

    return eggGroups;
  }

  void _calculatePath() {
    try {
      if (_startId == _targetId) {
        setState(() {
          _allPaths = [
            [_startId],
          ];
          _selectedPathIndex = 0;
          _path = _allPaths![0];
        });
        return;
      }

      if (_startId == 132) {
        setState(() {
          _allPaths = [
            [132, _targetId],
          ];
          _selectedPathIndex = 0;
          _path = _allPaths![0];
        });
        return;
      }

      final dexProvider = Provider.of<DexProvider>(context, listen: false);
      final liveDex = dexProvider.userDexes.firstWhere(
        (d) => d.id == widget.dexId,
      );

      Set<int> caughtBaseIds = {};
      if (_useOnlyCaught) {
        for (String uniqueId in liveDex.caughtIds) {
          int id = int.tryParse(uniqueId.split('_')[0]) ?? -1;
          if (id != -1) {
            caughtBaseIds.add(id);
            caughtBaseIds.add(ShinyLogicHelper.getBaseForm(id));
          }
        }
      }

      var eggGroups = _getEggGroups();

      Map<int, List<List<int>>> pathsToNode = {
        _startId: [
          [_startId],
        ],
      };

      Queue<int> queue = Queue();
      queue.add(_startId);

      int? targetDepth;

      while (queue.isNotEmpty) {
        int current = queue.removeFirst();
        int currentDepth = pathsToNode[current]!.first.length;

        if (targetDepth != null && currentDepth >= targetDepth) continue;
        if (ShinyLogicHelper.isBaby(current)) continue;

        var currentGroups = eggGroups[current] ?? [];

        for (int nextId = 1; nextId <= 251; nextId++) {
          if (!ShinyLogicHelper.isBreedable(nextId) &&
              !ShinyLogicHelper.isBaby(nextId))
            continue;

          int baseNextId = ShinyLogicHelper.getBaseForm(nextId);

          if (_useOnlyCaught &&
              nextId != _targetId &&
              !caughtBaseIds.contains(baseNextId))
            continue;

          if (nextId == _targetId) {
            if (_startId != 132 &&
                (_genderless.contains(baseNextId) ||
                    _onlyMale.contains(baseNextId)))
              continue;
          } else {
            if (_genderless.contains(baseNextId) ||
                _onlyMale.contains(baseNextId) ||
                _onlyFemale.contains(baseNextId))
              continue;
          }

          var nextGroups = eggGroups[nextId] ?? [];
          bool sharesGroup = currentGroups.any((g) => nextGroups.contains(g));

          if (sharesGroup) {
            bool isNewNode = !pathsToNode.containsKey(nextId);
            bool isSameDepth =
                !isNewNode &&
                pathsToNode[nextId]!.first.length == currentDepth + 1;

            if (isNewNode || isSameDepth) {
              if (isNewNode) pathsToNode[nextId] = [];

              for (var p in pathsToNode[current]!) {
                if (!p.contains(nextId)) {
                  pathsToNode[nextId]!.add(List<int>.from(p)..add(nextId));
                }
              }

              if (isNewNode) {
                if (nextId == _targetId) {
                  targetDepth = currentDepth + 1;
                } else {
                  queue.add(nextId);
                }
              }
            }
          }
        }
      }

      List<List<int>> validPaths = pathsToNode[_targetId] ?? [];

      Map<String, List<int>> uniquePathsMap = {};
      for (var p in validPaths) {
        String routeKey = 'direct';
        if (p.length > 2) {
          int intermediateBase = ShinyLogicHelper.getBaseForm(p[1]);
          routeKey = 'via_$intermediateBase';
        }
        if (!uniquePathsMap.containsKey(routeKey) ||
            p.length < uniquePathsMap[routeKey]!.length) {
          uniquePathsMap[routeKey] = p;
        }
      }

      List<List<int>> finalPaths = uniquePathsMap.values.toList();
      finalPaths.sort((a, b) => a.length.compareTo(b.length));

      if (finalPaths.length > 5) finalPaths = finalPaths.sublist(0, 5);

      setState(() {
        if (finalPaths.isNotEmpty) {
          _allPaths = finalPaths;
          _selectedPathIndex = 0;
          _path = _allPaths![0];
        } else {
          _allPaths = [];
          _path = null;
        }
      });
    } catch (e) {
      NotificationHelper.showError('Fehler bei der Pfadberechnung: $e');
    }
  }

  String _getRealOdds(int pokeId, String requiredGender) {
    String oddsBase = '1:64';
    if (requiredGender == 'any') return oddsBase;

    int base = ShinyLogicHelper.getBaseForm(pokeId);
    if (_onlyMale.contains(base) || _onlyFemale.contains(base)) return oddsBase;

    String totalOdds = '1:128';

    if (_lowFemaleRatio.contains(base)) {
      if (requiredGender == 'm')
        totalOdds = '~ 1:73';
      else
        return Translator.get('impossible') != 'impossible'
            ? Translator.get('impossible')
            : 'Unmöglich!';
    } else if (_ratio75m.contains(base)) {
      if (requiredGender == 'm')
        totalOdds = '~ 1:85';
      else
        totalOdds = '1:256';
    } else if (_ratio25m.contains(base)) {
      if (requiredGender == 'm')
        totalOdds = '1:256';
      else
        totalOdds = '~ 1:85';
    }

    return totalOdds;
  }

  List<int> _getFullFamily(int id) {
    int baseId = ShinyLogicHelper.getBaseForm(id);
    List<int> family = [baseId];

    List<int> stage1 = ShinyLogicHelper.gen12PreEvolutions.entries
        .where((e) => e.value['pre'] == baseId)
        .map((e) => e.key)
        .toList();
    family.addAll(stage1);

    for (int s1 in stage1) {
      List<int> stage2 = ShinyLogicHelper.gen12PreEvolutions.entries
          .where((e) => e.value['pre'] == s1)
          .map((e) => e.key)
          .toList();
      family.addAll(stage2);
    }

    family.removeWhere((fid) => !ShinyLogicHelper.isBreedable(fid));
    family.sort();
    return family;
  }

  Widget _buildPokemonAvatar(
    int id,
    bool isShiny,
    String gender, {
    bool isHighlight = false,
    bool isCarrier = false,
    double sizeScale = 1.0,
  }) {
    bool showAsShiny = isShiny && !isCarrier;
    final String imgUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${showAsShiny ? "shiny/" : ""}$id.png';
    final String name = _getPokemonNameOnly(id);

    IconData genderIcon = Icons.transgender;
    Color genderColor = Colors.grey;
    if (gender == 'm') {
      genderIcon = Icons.male;
      genderColor = Colors.blueAccent;
    } else if (gender == 'f') {
      genderIcon = Icons.female;
      genderColor = Colors.pinkAccent;
    }

    return SizedBox(
      width: 80 * sizeScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: (isHighlight ? 60 : 52) * sizeScale,
                height: (isHighlight ? 60 : 52) * sizeScale,
                decoration: BoxDecoration(
                  color: showAsShiny
                      ? Colors.amber.withOpacity(0.15)
                      : (isCarrier
                            ? Colors.blue.withOpacity(0.15)
                            : Theme.of(context).colorScheme.surface),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: showAsShiny
                        ? Colors.amber
                        : (isCarrier
                              ? Colors.blue
                              : Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.5)),
                    width: isHighlight ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(4.0 * sizeScale),
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.catching_pokemon,
                      color: Colors.grey,
                      size: 24 * sizeScale,
                    ),
                  ),
                ),
              ),
              if (showAsShiny)
                Container(
                  padding: EdgeInsets.all(2 * sizeScale),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 14 * sizeScale,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6 * sizeScale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (gender != 'any')
                Icon(genderIcon, color: genderColor, size: 14 * sizeScale),
              if (gender != 'any') SizedBox(width: 2 * sizeScale),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: (12 * sizeScale).clamp(9.0, 14.0),
                    fontWeight: isHighlight
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (isCarrier)
            Text(
              Translator.get('carrier') != 'carrier'
                  ? Translator.get('carrier')
                  : '(Trägerin)',
              style: TextStyle(
                fontSize: 10 * sizeScale,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFamilyAvatarRow(
    int id,
    bool isShiny,
    String gender, {
    bool isCarrier = false,
  }) {
    List<int> family = _getFullFamily(id);
    if (family.length <= 1) {
      return _buildPokemonAvatar(
        family.first,
        isShiny,
        gender,
        isCarrier: isCarrier,
      );
    }

    String oneOfText = Translator.currentLanguage == 'de'
        ? 'Eines davon:'
        : 'One of these:';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            oneOfText,
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: family
                .map(
                  (fid) => _buildPokemonAvatar(
                    fid,
                    isShiny,
                    gender,
                    isCarrier: isCarrier,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionUI(
    int fromId,
    int toId,
    bool cShiny,
    String cGender,
    int childId,
    String req,
    bool isMobile,
    bool isCarrier,
  ) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upgrade,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  Translator.get('shiny_breed_evo_step'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPokemonAvatar(
              fromId,
              cShiny,
              cGender,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.arrow_downward_rounded,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            _buildPokemonAvatar(
              toId,
              cShiny,
              cGender,
              isHighlight: toId == childId,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            const SizedBox(height: 8),
            Text(
              '($req)',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Icon(
              Icons.upgrade,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            Text(
              Translator.get('shiny_breed_evo_step'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            _buildPokemonAvatar(
              fromId,
              cShiny,
              cGender,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.grey,
              size: 20,
            ),
            _buildPokemonAvatar(
              toId,
              cShiny,
              cGender,
              isHighlight: toId == childId,
              sizeScale: 0.9,
              isCarrier: isCarrier,
            ),
            Text(
              '($req)',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStepCard({
    required int stepNumber,
    required int parent1Id,
    required bool p1Shiny,
    required String p1Gender,
    required bool p1Carrier,
    required int parent2Id,
    required bool p2Shiny,
    required String p2Gender,
    required bool p2Carrier,
    required int childId,
    required bool cShiny,
    required String cGender,
    required bool cCarrier,
    required bool isFinal,
  }) {
    String stepText = Translator.currentLanguage == 'de' ? 'Schritt' : 'Step';
    int baseChildId = ShinyLogicHelper.getBaseForm(childId);

    bool needsEvolution =
        baseChildId != childId &&
        (isFinal || ShinyLogicHelper.isBaby(baseChildId));

    bool isMobile = MediaQuery.of(context).size.width < 600;

    var g1 = _getEggGroups()[ShinyLogicHelper.getBaseForm(parent1Id)] ?? [];
    var g2 = _getEggGroups()[ShinyLogicHelper.getBaseForm(parent2Id)] ?? [];
    String sharedGroup = g1.firstWhere(
      (g) => g2.contains(g),
      orElse: () => 'Unbekannt',
    );

    String transGroup = Translator.get(
      'region_egg_${sharedGroup.toLowerCase()}',
    );
    if (transGroup.startsWith('region_egg_')) transGroup = sharedGroup;

    String realOdds = cCarrier
        ? (Translator.get('chance_carrier') != 'chance_carrier'
              ? Translator.get('chance_carrier')
              : 'Chance: 1:2 (Gen-Trägerin)')
        : _getRealOdds(childId, cGender);

    Widget p1Widget = p1Shiny || p1Carrier
        ? _buildPokemonAvatar(
            parent1Id,
            p1Shiny,
            p1Gender,
            isCarrier: p1Carrier,
          )
        : _buildFamilyAvatarRow(
            parent1Id,
            p1Shiny,
            p1Gender,
            isCarrier: p1Carrier,
          );

    Widget p2Widget = p2Shiny || p2Carrier
        ? _buildPokemonAvatar(
            parent2Id,
            p2Shiny,
            p2Gender,
            isCarrier: p2Carrier,
          )
        : _buildFamilyAvatarRow(
            parent2Id,
            p2Shiny,
            p2Gender,
            isCarrier: p2Carrier,
          );

    Widget childWidget = _buildPokemonAvatar(
      baseChildId,
      cShiny,
      cGender,
      isHighlight: !needsEvolution,
      isCarrier: cCarrier,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$stepText $stepNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (sharedGroup != 'Unbekannt' && parent1Id != 132)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      transGroup,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            isMobile
                ? Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        p1Widget,
                        const SizedBox(height: 12),
                        const Icon(Icons.add, color: Colors.grey, size: 24),
                        const SizedBox(height: 12),
                        p2Widget,
                        const SizedBox(height: 12),
                        const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 12),
                        childWidget,
                      ],
                    ),
                  )
                : Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        p1Widget,
                        const Icon(Icons.add, color: Colors.grey, size: 24),
                        p2Widget,
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.grey,
                          size: 32,
                        ),
                        childWidget,
                      ],
                    ),
                  ),
            if (needsEvolution) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...ShinyLogicHelper.getEvolutionPath(baseChildId, childId).map((
                step,
              ) {
                int fromId = step['from'];
                int toId = step['to'];
                String req = Translator.get(step['req']);
                return _buildEvolutionUI(
                  fromId,
                  toId,
                  cShiny,
                  cGender,
                  childId,
                  req,
                  isMobile,
                  cCarrier,
                );
              }),
            ],
            if (cCarrier)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Translator.get('shiny_breed_carrier_note') !=
                                  'shiny_breed_carrier_note'
                              ? Translator.get('shiny_breed_carrier_note')
                              : 'Hinweis: Da weibliche Shinys bei dieser Spezies unmöglich sind, erhältst du eine normale Gen-Trägerin. Prüfe sie beim Pensionsleiter mit dem Vater ("Sie zeigen kein Interesse").',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cCarrier
                      ? Colors.blue.withOpacity(0.15)
                      : (realOdds.contains('1:')
                            ? Colors.amber.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cCarrier
                        ? Colors.blue.withOpacity(0.5)
                        : (realOdds.contains('1:')
                              ? Colors.amber.withOpacity(0.5)
                              : Colors.red),
                  ),
                ),
                child: Text(
                  isFinal && !cCarrier
                      ? '${Translator.get('shiny_breed_chance')}: $realOdds (${Translator.currentLanguage == 'de' ? 'Ziel erreicht!' : 'Goal reached!'})'
                      : (cCarrier
                            ? realOdds
                            : (realOdds.contains('1:')
                                  ? '${Translator.get('shiny_breed_chance')}: $realOdds'
                                  : realOdds)),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cCarrier
                        ? Colors.blue
                        : (realOdds.contains('1:') ? Colors.amber : Colors.red),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPathSteps() {
    if (_path!.length == 1) {
      return [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            Translator.currentLanguage == 'de'
                ? 'Start- und Ziel-Pokémon sind identisch!'
                : 'Start and Target Pokémon are identical!',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    List<Widget> steps = [];
    int stepCounter = 1;

    if (_startId == 132) {
      int nextId = _path![1];
      int baseNextId = ShinyLogicHelper.getBaseForm(nextId);
      String nextName = _getPokemonNameOnly(nextId);
      String baseNextName = _getPokemonNameOnly(baseNextId);

      String stepDitto = Translator.get(
        'shiny_breed_step_ditto',
      ).replaceAll('{0}', nextName).replaceAll('{1}', baseNextName);

      bool isMobile = MediaQuery.of(context).size.width < 600;
      String realOdds = _getRealOdds(nextId, 'any');

      steps.add(
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Translator.currentLanguage == 'de' ? 'Schritt' : 'Step'} 1',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stepDitto,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                isMobile
                    ? Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildPokemonAvatar(132, true, 'any'),
                            const SizedBox(height: 12),
                            const Icon(Icons.add, color: Colors.grey, size: 24),
                            const SizedBox(height: 12),
                            _buildFamilyAvatarRow(nextId, false, 'any'),
                            const SizedBox(height: 12),
                            const Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.grey,
                              size: 28,
                            ),
                            const SizedBox(height: 12),
                            _buildPokemonAvatar(
                              baseNextId,
                              true,
                              'any',
                              isHighlight: baseNextId == nextId,
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildPokemonAvatar(132, true, 'any'),
                            const Icon(Icons.add, color: Colors.grey, size: 24),
                            _buildFamilyAvatarRow(nextId, false, 'any'),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.grey,
                              size: 32,
                            ),
                            _buildPokemonAvatar(
                              baseNextId,
                              true,
                              'any',
                              isHighlight: baseNextId == nextId,
                            ),
                          ],
                        ),
                      ),
                if (baseNextId != nextId) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  ...ShinyLogicHelper.getEvolutionPath(baseNextId, nextId).map((
                    step,
                  ) {
                    int fromId = step['from'];
                    int toId = step['to'];
                    String req = Translator.get(step['req']);
                    return _buildEvolutionUI(
                      fromId,
                      toId,
                      true,
                      'any',
                      nextId,
                      req,
                      isMobile,
                      false,
                    );
                  }),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${Translator.get('shiny_breed_chance')}: $realOdds (${Translator.currentLanguage == 'de' ? 'Ziel erreicht!' : 'Goal reached!'})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return steps;
    }

    for (int i = 0; i < _path!.length - 1; i++) {
      int currentId = _path![i];
      int nextId = _path![i + 1];
      bool isFinalNode = (i == _path!.length - 2);

      bool isFemaleShiny = !_lowFemaleRatio.contains(
        ShinyLogicHelper.getBaseForm(nextId),
      );

      int p1Id;
      if (i == 0) {
        p1Id = currentId;
      } else {
        int prevId = _path![i];
        int prevBase = ShinyLogicHelper.getBaseForm(prevId);
        p1Id = ShinyLogicHelper.isBaby(prevBase) ? prevId : prevBase;
      }

      steps.add(
        _buildStepCard(
          stepNumber: stepCounter++,
          parent1Id: p1Id,
          p1Shiny: true,
          p1Gender: 'm',
          p1Carrier: false,
          parent2Id: nextId,
          p2Shiny: false,
          p2Gender: 'f',
          p2Carrier: false,
          childId: nextId,
          cShiny: isFemaleShiny,
          cGender: 'f',
          cCarrier: !isFemaleShiny,
          isFinal: isFinalNode && isFemaleShiny,
        ),
      );

      if (!isFinalNode || !isFemaleShiny) {
        int carrierId =
            ShinyLogicHelper.isBaby(ShinyLogicHelper.getBaseForm(nextId))
            ? nextId
            : ShinyLogicHelper.getBaseForm(nextId);

        steps.add(
          _buildStepCard(
            stepNumber: stepCounter++,
            parent1Id: carrierId,
            p1Shiny: isFemaleShiny,
            p1Gender: 'f',
            p1Carrier: !isFemaleShiny,
            parent2Id: nextId,
            p2Shiny: false,
            p2Gender: 'm',
            p2Carrier: false,
            childId: nextId,
            cShiny: true,
            cGender: 'm',
            cCarrier: false,
            isFinal: isFinalNode,
          ),
        );
      }
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final targetPoke = nationalPokemonDatabase.firstWhere(
      (p) => p.id == _targetId,
    );

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.egg, color: Colors.amber),
      title: Text(
        Translator.get('shiny_breed_calc_title'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
                title: Text(
                  Translator.get('only_caught_pokemon') != 'only_caught_pokemon'
                      ? Translator.get('only_caught_pokemon')
                      : 'Nur gefangene Pokémon für Route verwenden',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: _useOnlyCaught,
                onChanged: (val) {
                  setState(() {
                    _useOnlyCaught = val ?? false;
                    _calculatePath();
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                Translator.get('shiny_breed_start'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<int>(
                    initialValue: TextEditingValue(
                      text: _getPokemonDisplayName(_startId),
                    ),
                    displayStringForOption: _getPokemonDisplayName,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _validStartIds;
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return _validStartIds.where((id) {
                        return _getPokemonDisplayName(
                          id,
                        ).toLowerCase().contains(query);
                      });
                    },
                    onSelected: (int val) {
                      if (val != _startId) {
                        setState(() {
                          _startId = val;
                          _calculatePath();
                        });
                      }
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: Translator.get('search_hint'),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 22,
                                horizontal: 16,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 12.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search, size: 26),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.amber.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Image.network(
                                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$_startId.png',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) =>
                                            const SizedBox(
                                              width: 36,
                                              height: 36,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        controller.clear();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 250,
                              maxWidth: constraints.maxWidth,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final int option = options.elementAt(index);
                                return ListTile(
                                  leading: Image.network(
                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$option.png',
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.catching_pokemon),
                                  ),
                                  title: Text(_getPokemonDisplayName(option)),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                Translator.get('shiny_breed_target'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                        ),
                      ),
                      child: Image.network(
                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$_targetId.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.catching_pokemon,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '#${_targetId.toString().padLeft(3, '0')} ${targetPoke.getName(Translator.currentLanguage)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Icon(Icons.flag, color: Colors.green, size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.3),
                  ),
                ),
                child: ExpansionTile(
                  leading: Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    Translator.get('shiny_breed_mechanics_title') !=
                            'shiny_breed_mechanics_title'
                        ? Translator.get('shiny_breed_mechanics_title')
                        : 'Wichtige Zucht-Mechaniken (Gen 2)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Translator.get('shiny_breed_female_note'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Translator.get(
                                            'shiny_breed_mechanics_dv_passing',
                                          ) !=
                                          'shiny_breed_mechanics_dv_passing'
                                      ? Translator.get(
                                          'shiny_breed_mechanics_dv_passing',
                                        )
                                      : 'Warum dieser Geschlechter-Wechsel? In Gen 2 wird der Shiny-Status immer an das *andere* Geschlecht vererbt.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Translator.get(
                                            'shiny_breed_dv_conflict_text',
                                          ) !=
                                          'shiny_breed_dv_conflict_text'
                                      ? Translator.get(
                                          'shiny_breed_dv_conflict_text',
                                        )
                                      : 'Achtung: Inzest-Sperre bei gleichen DVs beachten!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_allPaths != null && _allPaths!.length > 1) ...[
                Text(
                  Translator.currentLanguage == 'de'
                      ? 'Alternative Routen'
                      : 'Alternative Routes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_allPaths!.length, (index) {
                      var p = _allPaths![index];
                      bool isSelected = index == _selectedPathIndex;

                      String routeName = Translator.currentLanguage == 'de'
                          ? 'Direkt'
                          : 'Direct';
                      if (p.length > 2) {
                        int intermediateBase = ShinyLogicHelper.getBaseForm(
                          p[1],
                        );
                        String pokeName = _getPokemonNameOnly(intermediateBase);
                        routeName = 'Via $pokeName';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(routeName),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              _selectedPathIndex = index;
                              _path = _allPaths![index];
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_allPaths != null && _allPaths!.isEmpty)
                Text(
                  _startId != 132
                      ? (Translator.get('no_path_impossible') !=
                                'no_path_impossible'
                            ? Translator.get('no_path_impossible')
                            : 'Unmöglich! Du MUSST ein Shiny Ditto verwenden!')
                      : (_useOnlyCaught
                            ? (Translator.get('no_path_caught') !=
                                      'no_path_caught'
                                  ? Translator.get('no_path_caught')
                                  : 'Keine Route mit deinen gefangenen Pokémon gefunden.')
                            : Translator.get('shiny_breed_no_path')),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (_path == null)
                Text(
                  _useOnlyCaught
                      ? (Translator.get('no_path_caught') != 'no_path_caught'
                            ? Translator.get('no_path_caught')
                            : 'Keine Route mit deinen gefangenen Pokémon gefunden.')
                      : Translator.get('shiny_breed_no_path'),
                  style: const TextStyle(color: Colors.red),
                )
              else
                ..._buildPathSteps(),
            ],
          ),
        ),
      ],
    );
  }
}
