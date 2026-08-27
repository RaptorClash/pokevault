import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';
import '../../utils/shiny_logic_helper.dart';
import '../../providers/dex_provider.dart';
import 'widgets/breeding_data.dart';
import 'widgets/breeding_step_card.dart';

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

  @override
  void initState() {
    super.initState();
    _targetId = widget.initialTargetId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<DexProvider>(context, listen: false);
    final targetPoke = provider.allPokemon
        .where((p) => p.id == _targetId)
        .firstOrNull;
    if (_targetId > 251 ||
        (targetPoke != null &&
            !ShinyLogicHelper.isBreedable(targetPoke) &&
            !ShinyLogicHelper.isBaby(_targetId))) {
      _targetId = 1;
    }
    if (_targetId == _startId) {
      _startId = 4;
    }
    if (_allPaths == null) {
      _calculatePath();
    }
  }

  List<int> get _validStartIds {
    final provider = Provider.of<DexProvider>(context, listen: false);
    List<int> ids = [];
    for (var p in provider.allPokemon) {
      if (p.id <= 251 &&
          (ShinyLogicHelper.isBreedable(p) ||
              ShinyLogicHelper.isBaby(p.id) ||
              p.id == 132)) {
        ids.add(p.id);
      }
    }
    return ids;
  }

  String _getPokemonDisplayName(int id) {
    final provider = Provider.of<DexProvider>(context, listen: false);
    final p = provider.allPokemon.where((p) => p.id == id).firstOrNull;
    if (p == null) return '#${id.toString().padLeft(3, '0')} ???';
    return '#${id.toString().padLeft(3, '0')} ${p.getName(Translator.currentLanguage)}';
  }

  String _getPokemonNameOnly(int id) {
    final provider = Provider.of<DexProvider>(context, listen: false);
    final p = provider.allPokemon.where((p) => p.id == id).firstOrNull;
    if (p == null) return '???';
    return p.getName(Translator.currentLanguage);
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

      var eggGroups = BreedingData.getEggGroups(dexProvider);
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
          final nextPoke = dexProvider.allPokemon
              .where((p) => p.id == nextId)
              .firstOrNull;
          if (nextPoke == null) continue;
          if (!ShinyLogicHelper.isBreedable(nextPoke) &&
              !ShinyLogicHelper.isBaby(nextId)) {
            continue;
          }

          int baseNextId = ShinyLogicHelper.getBaseForm(nextId);
          final baseNextPoke = dexProvider.allPokemon
              .where((p) => p.id == baseNextId)
              .firstOrNull;

          if (_useOnlyCaught &&
              nextId != _targetId &&
              !caughtBaseIds.contains(baseNextId)) {
            continue;
          }

          if (baseNextPoke != null) {
            if (nextId == _targetId) {
              if (_startId != 132 &&
                  (baseNextPoke.genderRate == -1 ||
                      baseNextPoke.genderRate == 0)) {
                continue;
              }
            } else {
              if (baseNextPoke.genderRate == -1 ||
                  baseNextPoke.genderRate == 0 ||
                  baseNextPoke.genderRate == 8) {
                continue;
              }
            }
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
      String nextName = _getPokemonNameOnly(nextId);
      String baseNextName = _getPokemonNameOnly(
        ShinyLogicHelper.getBaseForm(nextId),
      );
      String stepDitto = Translator.get(
        'shiny_breed_step_ditto',
      ).replaceAll('{0}', nextName).replaceAll('{1}', baseNextName);

      steps.add(
        BreedingStepCard(
          stepNumber: stepCounter++,
          parent1Id: 132,
          p1Shiny: true,
          p1Gender: 'any',
          p1Carrier: false,
          parent2Id: nextId,
          p2Shiny: false,
          p2Gender: 'any',
          p2Carrier: false,
          childId: nextId,
          cShiny: true,
          cGender: 'any',
          cCarrier: false,
          isFinal: true,
          dittoHint: stepDitto,
        ),
      );
      return steps;
    }

    for (int i = 0; i < _path!.length - 1; i++) {
      int currentId = _path![i];
      int nextId = _path![i + 1];
      bool isFinalNode = (i == _path!.length - 2);

      final dexProvider = Provider.of<DexProvider>(context, listen: false);
      final baseNextPoke = dexProvider.allPokemon
          .where((p) => p.id == ShinyLogicHelper.getBaseForm(nextId))
          .firstOrNull;
      bool isFemaleShiny = baseNextPoke != null && baseNextPoke.genderRate != 1;

      int p1Id;
      if (i == 0) {
        p1Id = currentId;
      } else {
        int prevId = _path![i];
        int prevBase = ShinyLogicHelper.getBaseForm(prevId);
        p1Id = ShinyLogicHelper.isBaby(prevBase) ? prevId : prevBase;
      }

      steps.add(
        BreedingStepCard(
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
          BreedingStepCard(
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
    final provider = context.watch<DexProvider>();
    final targetPoke = provider.allPokemon
        .where((p) => p.id == _targetId)
        .firstOrNull;

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
                                        color: Colors.amber.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.amber.withValues(
                                            alpha: 0.5,
                                          ),
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
                                  .withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
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
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
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
                        '#${_targetId.toString().padLeft(3, '0')} ${targetPoke != null ? targetPoke.getName(Translator.currentLanguage) : '???'}',
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
                ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.3),
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
