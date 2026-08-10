import 'dart:collection';
import 'package:flutter/material.dart';
import '../data/dex_orders.dart';
import '../data/national_dex_data.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';
import '../utils/shiny_logic_helper.dart';

class BreedingCalculatorWidget extends StatefulWidget {
  final int initialTargetId;

  const BreedingCalculatorWidget({super.key, required this.initialTargetId});

  @override
  State<BreedingCalculatorWidget> createState() =>
      _BreedingCalculatorWidgetState();
}

class _BreedingCalculatorWidgetState extends State<BreedingCalculatorWidget> {
  int _startId = 130;
  late int _targetId;
  List<int>? _path;

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

    _calculatePath();
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

    eggGroups[172] = ['Field', 'Fairy']; // Pichu -> Pikachu
    eggGroups[173] = ['Fairy']; // Pii -> Piepi
    eggGroups[174] = ['Fairy']; // Fluffeluff -> Pummeluff
    eggGroups[236] = ['Human-Like']; // Rabauz -> Kicklee/Nockchan
    eggGroups[238] = ['Human-Like']; // Kussilla -> Rossana
    eggGroups[239] = ['Human-Like']; // Elekid -> Elektek
    eggGroups[240] = ['Human-Like']; // Magby -> Magmar

    return eggGroups;
  }

  void _calculatePath() {
    try {
      if (_startId == _targetId) {
        setState(() {
          _path = [_startId];
        });
        return;
      }

      if (_startId == 132) {
        setState(() {
          _path = [132, _targetId];
        });
        return;
      }

      var eggGroups = _getEggGroups();
      Queue<List<int>> queue = Queue();
      queue.add([_startId]);
      Set<int> visited = {_startId};

      List<int>? foundPath;

      while (queue.isNotEmpty) {
        var path = queue.removeFirst();
        var current = path.last;

        if (ShinyLogicHelper.isBaby(current)) continue;

        var currentGroups = eggGroups[current] ?? [];

        for (int nextId = 1; nextId <= 251; nextId++) {
          if (!ShinyLogicHelper.isBreedable(nextId) &&
              !ShinyLogicHelper.isBaby(nextId))
            continue;
          if (visited.contains(nextId)) continue;

          var nextGroups = eggGroups[nextId] ?? [];
          bool sharesGroup = currentGroups.any((g) => nextGroups.contains(g));

          if (sharesGroup) {
            var newPath = List<int>.from(path)..add(nextId);
            if (nextId == _targetId) {
              foundPath = newPath;
              break;
            }
            visited.add(nextId);
            queue.add(newPath);
          }
        }
        if (foundPath != null) break;
      }

      setState(() {
        _path = foundPath;
      });
    } catch (e) {
      NotificationHelper.showError('Fehler bei der Pfadberechnung: $e');
    }
  }

  Widget _buildPokemonAvatar(
    int id,
    bool isShiny,
    String gender, {
    bool isHighlight = false,
  }) {
    final String imgUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${isShiny ? "shiny/" : ""}$id.png';
    final String name = nationalPokemonDatabase
        .firstWhere((p) => p.id == id)
        .getName(Translator.currentLanguage);

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
      width: 75,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: isHighlight ? 56 : 48,
                height: isHighlight ? 56 : 48,
                decoration: BoxDecoration(
                  color: isShiny
                      ? Colors.amber.withOpacity(0.15)
                      : Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isShiny
                        ? Colors.amber
                        : Theme.of(context).dividerColor.withOpacity(0.5),
                    width: isHighlight ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.catching_pokemon, color: Colors.grey),
                  ),
                ),
              ),
              if (isShiny)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.amber, size: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (gender != 'any')
                Icon(genderIcon, color: genderColor, size: 14),
              if (gender != 'any') const SizedBox(width: 2),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required int parent1Id,
    required bool p1Shiny,
    required String p1Gender,
    required int parent2Id,
    required bool p2Shiny,
    required String p2Gender,
    required int childId,
    required bool cShiny,
    required String cGender,
    required bool isFinal,
  }) {
    String stepText = Translator.currentLanguage == 'de' ? 'Schritt' : 'Step';
    int baseChildId = ShinyLogicHelper.getBaseForm(childId);
    bool needsEvolution = baseChildId != childId;

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
            Text(
              '$stepText $stepNumber',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPokemonAvatar(parent1Id, p1Shiny, p1Gender),
                const Icon(Icons.add, color: Colors.grey, size: 20),
                _buildPokemonAvatar(parent2Id, p2Shiny, p2Gender),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.grey,
                  size: 24,
                ),
                _buildPokemonAvatar(
                  baseChildId,
                  cShiny,
                  cGender,
                  isHighlight: !needsEvolution,
                ),
              ],
            ),
            if (needsEvolution) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...ShinyLogicHelper.getEvolutionPath(baseChildId, childId).map((
                step,
              ) {
                int fromId = step['from'];
                int toId = step['to'];
                String req = Translator.get(step['req']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildPokemonAvatar(fromId, cShiny, cGender),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      _buildPokemonAvatar(
                        toId,
                        cShiny,
                        cGender,
                        isHighlight: toId == childId,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '($req)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Text(
                  isFinal
                      ? Translator.get('shiny_breed_success')
                      : Translator.get('shiny_breed_chance'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
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
      String nextName = nationalPokemonDatabase
          .firstWhere((p) => p.id == nextId)
          .getName(Translator.currentLanguage);
      String baseNextName = nationalPokemonDatabase
          .firstWhere((p) => p.id == baseNextId)
          .getName(Translator.currentLanguage);
      String stepDitto = Translator.get(
        'shiny_breed_step_ditto',
      ).replaceAll('{0}', nextName).replaceAll('{1}', baseNextName);

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
                    fontSize: 14,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPokemonAvatar(132, true, 'any'),
                    const Icon(Icons.add, color: Colors.grey, size: 20),
                    _buildPokemonAvatar(nextId, false, 'any'),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                    _buildPokemonAvatar(
                      baseNextId,
                      true,
                      'any',
                      isHighlight: baseNextId == nextId,
                    ),
                  ],
                ),
                if (baseNextId != nextId) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...ShinyLogicHelper.getEvolutionPath(baseNextId, nextId).map((
                    step,
                  ) {
                    int fromId = step['from'];
                    int toId = step['to'];
                    String req = Translator.get(step['req']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildPokemonAvatar(fromId, true, 'any'),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          _buildPokemonAvatar(
                            toId,
                            true,
                            'any',
                            isHighlight: toId == nextId,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '($req)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Text(
                      Translator.get('shiny_breed_success'),
                      style: const TextStyle(
                        fontSize: 12,
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

      bool isFinal = (i == _path!.length - 2);

      steps.add(
        _buildStepCard(
          stepNumber: stepCounter++,
          parent1Id: currentId,
          p1Shiny: true,
          p1Gender: 'm',
          parent2Id: nextId,
          p2Shiny: false,
          p2Gender: 'f',
          childId: nextId,
          cShiny: true,
          cGender: isFinal ? 'any' : 'f',
          isFinal: isFinal,
        ),
      );

      if (!isFinal) {
        steps.add(
          _buildStepCard(
            stepNumber: stepCounter++,
            parent1Id: nextId,
            p1Shiny: true,
            p1Gender: 'f',
            parent2Id: nextId,
            p2Shiny: false,
            p2Gender: 'm',
            childId: nextId,
            cShiny: true,
            cGender: 'm',
            isFinal: false,
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
                              prefixIcon: const Icon(Icons.search),
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
                                borderRadius: BorderRadius.circular(12),
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
                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$option.png',
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$_targetId.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.catching_pokemon,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '#${_targetId.toString().padLeft(3, '0')} ${targetPoke.getName(Translator.currentLanguage)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.flag, color: Colors.green),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
              ),

              const SizedBox(height: 24),

              if (_path == null)
                Text(
                  Translator.get('shiny_breed_no_path'),
                  style: const TextStyle(color: Colors.red),
                )
              else
                ..._buildPathSteps(),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get('shiny_breed_note'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
