import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';
import '../../utils/shiny_logic_helper.dart';
import '../../utils/breeding_logic_helper.dart';
import '../../providers/dex_provider.dart';
import 'widgets/breeding_step_card.dart';
import '../../services/database_service.dart';
import 'widgets/breeding_calc/pokemon_autocomplete_field.dart';
import 'widgets/breeding_calc/target_pokemon_display.dart';
import 'widgets/breeding_calc/breeding_mechanics_info.dart';

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

  bool _isCalculating = false;
  Map<int, Map<String, dynamic>> _preEvolutions = {};

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

  Future<void> _calculatePath() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      final dexProvider = Provider.of<DexProvider>(context, listen: false);
      final liveDex = dexProvider.userDexes.firstWhere(
        (d) => d.id == widget.dexId,
      );

      final preEvos = await DatabaseService.instance.getGen12PreEvolutions();
      _preEvolutions = preEvos;

      Set<int> caughtBaseIds = {};
      if (_useOnlyCaught) {
        for (String uniqueId in liveDex.caughtIds) {
          int id = int.tryParse(uniqueId.split('_')[0]) ?? -1;
          if (id != -1) {
            caughtBaseIds.add(id);
            caughtBaseIds.add(ShinyLogicHelper.getBaseForm(id, preEvos));
          }
        }
      }

      final args = BreedingCalcArgs(
        startId: _startId,
        targetId: _targetId,
        useOnlyCaught: _useOnlyCaught,
        caughtBaseIds: caughtBaseIds,
        allPokemon: dexProvider.allPokemon,
        preEvolutions: preEvos,
      );

      final finalPaths = await BreedingLogicHelper.calculatePathsInBackground(
        args,
      );

      if (mounted) {
        setState(() {
          if (finalPaths.isNotEmpty) {
            _allPaths = finalPaths;
            _selectedPathIndex = 0;
            _path = _allPaths![0];
          } else {
            _allPaths = [];
            _path = null;
          }
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
        NotificationHelper.showError('Fehler bei der Pfadberechnung: $e');
      }
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
        ShinyLogicHelper.getBaseForm(nextId, _preEvolutions),
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
          preEvolutions: _preEvolutions,
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
          .where(
            (p) => p.id == ShinyLogicHelper.getBaseForm(nextId, _preEvolutions),
          )
          .firstOrNull;

      bool isFemaleShiny = baseNextPoke != null && baseNextPoke.genderRate != 1;

      int p1Id;
      if (i == 0) {
        p1Id = currentId;
      } else {
        int prevId = _path![i];
        int prevBase = ShinyLogicHelper.getBaseForm(prevId, _preEvolutions);
        p1Id = ShinyLogicHelper.isBaby(prevBase) ? prevId : prevBase;
      }

      int breedNextId = ShinyLogicHelper.isBaby(nextId)
          ? ShinyLogicHelper.getAdultForBaby(nextId)
          : nextId;

      steps.add(
        BreedingStepCard(
          stepNumber: stepCounter++,
          parent1Id: p1Id,
          p1Shiny: true,
          p1Gender: 'm',
          p1Carrier: false,
          parent2Id: breedNextId,
          p2Shiny: false,
          p2Gender: 'f',
          p2Carrier: false,
          childId: nextId,
          cShiny: isFemaleShiny,
          cGender: 'f',
          cCarrier: !isFemaleShiny,
          isFinal: isFinalNode && isFemaleShiny,
          preEvolutions: _preEvolutions,
        ),
      );

      if (!isFinalNode || !isFemaleShiny) {
        int carrierId =
            ShinyLogicHelper.isBaby(
              ShinyLogicHelper.getBaseForm(nextId, _preEvolutions),
            )
            ? breedNextId
            : ShinyLogicHelper.getBaseForm(nextId, _preEvolutions);
        steps.add(
          BreedingStepCard(
            stepNumber: stepCounter++,
            parent1Id: carrierId,
            p1Shiny: isFemaleShiny,
            p1Gender: 'f',
            p1Carrier: !isFemaleShiny,
            parent2Id: breedNextId,
            p2Shiny: false,
            p2Gender: 'm',
            p2Carrier: false,
            childId: nextId,
            cShiny: true,
            cGender: 'm',
            cCarrier: false,
            isFinal: isFinalNode,
            preEvolutions: _preEvolutions,
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
                  Translator.get(
                    'only_caught_pokemon',
                    fallback: 'Nur gefangene Pokémon für Route verwenden',
                  ),
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

              PokemonAutocompleteField(
                startId: _startId,
                validStartIds: _validStartIds,
                getDisplayName: _getPokemonDisplayName,
                onSelected: (int val) {
                  if (val != _startId) {
                    setState(() {
                      _startId = val;
                      _calculatePath();
                    });
                  }
                },
              ),

              const SizedBox(height: 16),
              Text(
                Translator.get('shiny_breed_target'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TargetPokemonDisplay(
                targetId: _targetId,
                targetName: targetPoke != null
                    ? targetPoke.getName(Translator.currentLanguage)
                    : '???',
              ),

              const SizedBox(height: 24),
              const BreedingMechanicsInfo(),
              const SizedBox(height: 16),

              if (_isCalculating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
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
                            _preEvolutions,
                          );
                          routeName =
                              'Via ${_getPokemonNameOnly(intermediateBase)}';
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
                        ? Translator.get(
                            'no_path_impossible',
                            fallback:
                                'Unmöglich! Du MUSST ein Shiny Ditto verwenden!',
                          )
                        : (_useOnlyCaught
                              ? Translator.get(
                                  'no_path_caught',
                                  fallback:
                                      'Keine Route mit deinen gefangenen Pokémon gefunden.',
                                )
                              : Translator.get('shiny_breed_no_path')),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (_path == null)
                  Text(
                    _useOnlyCaught
                        ? Translator.get(
                            'no_path_caught',
                            fallback:
                                'Keine Route mit deinen gefangenen Pokémon gefunden.',
                          )
                        : Translator.get('shiny_breed_no_path'),
                    style: const TextStyle(color: Colors.red),
                  )
                else
                  ..._buildPathSteps(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
