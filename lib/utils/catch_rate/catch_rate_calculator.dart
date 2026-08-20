import 'dart:math';
import 'package:flutter/material.dart';

import '../../../l10n/app_translations.dart';
import '../../../models/pokemon.dart';
import '../../../data/encounters_data.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../utils/notification_helper.dart';
import '../../../utils/catch_rate/models.dart';
import '../../../utils/catch_rate/strategy_base.dart';

class CatchRateCalculator extends StatefulWidget {
  final Pokemon pokemon;
  const CatchRateCalculator({super.key, required this.pokemon});

  @override
  State<CatchRateCalculator> createState() => _CatchRateCalculatorState();
}

class _CatchRateCalculatorState extends State<CatchRateCalculator> {
  late double _minGen;
  List<double> _availableGens = [];
  double _selectedGen = 9.0;

  double _hpPercent = 100.0;
  String _selectedBallId = 'poke';
  int _statusType = 0;
  int _turnCount = 1;
  int _enemyLevel = 50;
  int _ownLevel = 100;
  bool _isFishing = false;
  bool _isSurfingOrDiving = false;
  bool _isNightOrCave = false;
  bool _isLoveConditionMet = false;
  bool _isAlreadyCaught = false;
  bool _isDarkGrass = false;
  int _hisuiCatchStatus = 0;
  bool _isFlying = false;
  double _powerBonus = 1.0;
  double _dexMultiplier = 0.0;
  bool _hasCatchingCharm = false;

  bool _isMaxRaid = false;
  bool _isGigantamax = false;
  bool _isGuest = false;
  bool _isBackstrike = false;
  bool _isCatchWindow = false;
  bool _isAlpha = false;
  bool _isUnnoticed = false;
  int _zaRank = 10;
  int _plushLevel = 0;
  int _donutPenalty = 0;
  int _missingBadges = 0;
  bool _isTargetShiny = false;

  late CatchRateResult _currentResult;
  late CatchRateStrategy _currentStrategy;

  final Map<double, String> _genNames = {
    1.0: 'Gen 1 (Rot/Blau/Gelb)',
    2.0: 'Gen 2 (Gold/Silber/Kristall)',
    3.0: 'Gen 3 & 4 (R/S/S/D/P/P)',
    5.0: 'Gen 5 (Schwarz/Weiß 1&2)',
    6.0: 'Gen 6 & 7 (X/Y/S/M)',
    7.5: 'Gen 7.5 (Let\'s Go)',
    8.0: 'Gen 8 (Schwert/Schild)',
    8.5: 'Gen 8.5 (Legenden: Arceus)',
    9.0: 'Gen 9 (Karmesin/Purpur)',
    9.5: 'Gen 9.5 (Legenden: Z-A)',
  };

  final Map<double, String> _dexMultipliers = {
    0.0: '< 30 gefangen (0.0x)',
    0.5: '30+ gefangen (0.5x)',
    1.0: '150+ gefangen (1.0x)',
    1.5: '300+ gefangen (1.5x)',
    2.0: '450+ gefangen (2.0x)',
    2.5: '600+ gefangen (2.5x)',
  };

  @override
  void initState() {
    super.initState();
    _minGen = _getMinGenForPokemon(widget.pokemon.id);

    _availableGens = _genNames.keys
        .where((g) => _canShowGen(g, widget.pokemon.id))
        .toList();

    if (_availableGens.isEmpty) {
      _availableGens.add(max(_minGen, 9.0));
    }

    _selectedGen = _availableGens.last;

    _initStrategyAndCalculate();
  }

  void _initStrategyAndCalculate() {
    try {
      _currentStrategy = CatchRateStrategyFactory.getStrategy(_selectedGen);
      _updateResult();
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_calc_catch_rate')} $e",
      );
    }
  }

  void _updateResult() {
    try {
      final params = CatchRateParams(
        pokemon: widget.pokemon,
        ballId: _selectedBallId,
        hpPercent: _hpPercent,
        statusType: _statusType,
        turnCount: _turnCount,
        enemyLevel: _enemyLevel,
        ownLevel: _ownLevel,
        isFishing: _isFishing,
        isSurfingOrDiving: _isSurfingOrDiving,
        isNightOrCave: _isNightOrCave,
        isLoveConditionMet: _isLoveConditionMet,
        isAlreadyCaught: _isAlreadyCaught,
        isDarkGrass: _isDarkGrass,
        hisuiCatchStatus: _hisuiCatchStatus,
        isFlying: _isFlying,
        powerBonus: _powerBonus,
        dexMultiplier: _dexMultiplier,
        hasCatchingCharm: _hasCatchingCharm,
        isMaxRaid: _isMaxRaid,
        isGigantamax: _isGigantamax,
        isGuest: _isGuest,
        isBackstrike: _isBackstrike,
        isCatchWindow: _isCatchWindow,
        isAlpha: _isAlpha,
        isUnnoticed: _isUnnoticed,
        zaRank: _zaRank,
        plushLevel: _plushLevel,
        donutPenalty: _donutPenalty,
        missingBadges: _missingBadges,
        isTargetShiny: _isTargetShiny,
      );

      setState(() {
        _currentResult = _currentStrategy.calculate(params);
      });
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_calc_catch_rate')} $e",
      );
    }
  }

  double _getMinGenForPokemon(int id) {
    if (id <= 151) return 1.0;
    if (id <= 251) return 2.0;
    if (id <= 386) return 3.0;
    if (id <= 493) return 4.0;
    if (id <= 649) return 5.0;
    if (id <= 721) return 6.0;
    if (id <= 809) return 7.0;
    if (id <= 905) return 8.0;
    return 9.0;
  }

  bool _canShowGen(double gen, int pokeId) {
    if (gen == 7.5) {
      return pokeId <= 151 || pokeId == 808 || pokeId == 809;
    }
    if (gen == 9.5) return true;

    String genKey = 'gen_${gen.toInt()}';
    final encMap = encountersDatabase[pokeId];
    bool hasEncounter = false;

    if (encMap != null && encMap.containsKey(genKey)) {
      if (gen == 8.5) {
        hasEncounter = encMap[genKey]!.keys.any(
          (k) => k.contains('legends-arceus'),
        );
      } else if (gen == 8.0) {
        hasEncounter = encMap[genKey]!.keys.any(
          (k) => !k.contains('legends-arceus'),
        );
      } else {
        hasEncounter = true;
      }
    }

    bool isStatic = ShinyLogicHelper.isStaticEncounter(pokeId, genKey);
    return hasEncounter || isStatic;
  }

  @override
  Widget build(BuildContext context) {
    bool isGuaranteed = _currentResult.catchChance >= 100.0;
    final currentBalls = _currentStrategy.getAvailableBalls();
    bool hasBattleConditions =
        _currentStrategy.showPowerOptions ||
        _currentStrategy.showEnemyLevel ||
        _currentStrategy.showOwnLevel ||
        _currentStrategy.showTurnCount ||
        _currentStrategy.showFishing ||
        _currentStrategy.showSurfing ||
        _currentStrategy.showNightEncounter ||
        _currentStrategy.showLoveCondition ||
        _currentStrategy.showRepeatCondition ||
        _currentStrategy.showDarkGrass ||
        _currentStrategy.isArceus ||
        _currentStrategy.showFlying ||
        _currentStrategy.showMaxRaid ||
        _currentStrategy.showBackstrike ||
        _currentStrategy.showCatchWindow ||
        _currentStrategy.showAlpha ||
        _currentStrategy.showZaRank ||
        _currentStrategy.showPlushLevel ||
        _currentStrategy.showDonutPenalty ||
        _currentStrategy.showMissingBadges ||
        _currentStrategy.showTargetShiny ||
        _currentStrategy.showUnnoticed;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${Translator.get('calc_base_rate')}: ${_currentResult.baseRate}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (_currentResult.baseRate != widget.pokemon.captureRate)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 32.0),
              child: Text(
                Translator.get(
                  'calc_modified_rate',
                ).replaceAll('{0}', widget.pokemon.captureRate.toString()),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),

          DropdownButtonFormField<double>(
            value: _selectedGen,
            decoration: InputDecoration(
              labelText: Translator.get('generation'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            items: _availableGens.map((gen) {
              return DropdownMenuItem<double>(
                value: gen,
                child: Text(_genNames[gen] ?? 'Gen $gen'),
              );
            }).toList(),
            onChanged: (val) {
              try {
                if (val != null) {
                  _selectedGen = val;
                  _powerBonus = 1.0;
                  _currentStrategy = CatchRateStrategyFactory.getStrategy(
                    _selectedGen,
                  );
                  final newBalls = _currentStrategy.getAvailableBalls();
                  if (!newBalls.any((b) => b.id == _selectedBallId)) {
                    _selectedBallId = newBalls.first.id;
                  }
                  _updateResult();
                }
              } catch (e) {
                NotificationHelper.showError(
                  "${Translator.get('error_calc_catch_rate_ui')} $e",
                );
              }
            },
          ),

          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: currentBalls.any((b) => b.id == _selectedBallId)
                ? _selectedBallId
                : currentBalls.first.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText:
                  Translator.get('pokeball_bonus') +
                  (_selectedBallId != 'master' &&
                          _selectedBallId != 'origin' &&
                          _selectedBallId != 'heavy' &&
                          _selectedBallId != 'safari' &&
                          _selectedBallId != 'cherish'
                      ? ' (Bonus: ${_currentResult.bonus.toStringAsFixed(2)}x)'
                      : ''),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            items: currentBalls.map((ball) {
              return DropdownMenuItem<String>(
                value: ball.id,
                child: Row(
                  children: [
                    Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/${ball.spriteId}.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.catching_pokemon, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ball.nameKey != 'ball_${ball.id}'
                          ? ball.nameKey
                          : ball.nameKey.replaceAll('ball_', '').toUpperCase(),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              try {
                if (val != null) {
                  _selectedBallId = val;
                  _updateResult();
                }
              } catch (e) {
                NotificationHelper.showError(
                  "${Translator.get('error_calc_catch_rate_ui')} $e",
                );
              }
            },
          ),
          if (hasBattleConditions) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.sports_martial_arts),
                title: Text(
                  Translator.get('calc_battle_conditions'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStrategy.showPowerOptions) ...[
                          DropdownButtonFormField<double>(
                            value: _powerBonus,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: _selectedGen == 7.5
                                  ? Translator.get('calc_berry_let_go')
                                  : Translator.get('calc_bonus_power'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            items: _currentStrategy.getPowerOptions(),
                            onChanged: (val) {
                              if (val != null) {
                                _powerBonus = val;
                                _updateResult();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_currentStrategy.showMaxRaid) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_max_raid')),
                            value: _isMaxRaid,
                            onChanged: (val) {
                              _isMaxRaid = val;
                              _updateResult();
                            },
                          ),
                          if (_isMaxRaid) ...[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                Translator.get('calc_max_raid_guest'),
                              ),
                              value: _isGuest,
                              onChanged: (val) {
                                _isGuest = val;
                                _updateResult();
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(Translator.get('calc_max_raid_gmax')),
                              value: _isGigantamax,
                              onChanged: (val) {
                                _isGigantamax = val;
                                _updateResult();
                              },
                            ),
                          ],
                        ],
                        if (_currentStrategy.isArceus) ...[
                          DropdownButtonFormField<int>(
                            value: _hisuiCatchStatus,
                            decoration: InputDecoration(
                              labelText: Translator.get('calc_hisui_status'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text(Translator.get('hisui_status_0')),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text(Translator.get('hisui_status_1')),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(Translator.get('hisui_status_2')),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(Translator.get('hisui_status_3')),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _hisuiCatchStatus = val;
                                _updateResult();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_currentStrategy.showFlying) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_flying')),
                            value: _isFlying,
                            onChanged: (val) {
                              _isFlying = val;
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showUnnoticed) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              Translator.get('calc_unnoticed') !=
                                      'calc_unnoticed'
                                  ? Translator.get('calc_unnoticed')
                                  : 'Unbemerkt',
                            ),
                            value: _isUnnoticed,
                            onChanged: (val) {
                              _isUnnoticed = val;
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showBackstrike) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              Translator.get('calc_backstrike') !=
                                      'calc_backstrike'
                                  ? Translator.get('calc_backstrike')
                                  : 'Rückenangriff',
                            ),
                            value: _isBackstrike,
                            onChanged: (val) {
                              _isBackstrike = val;
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showTargetShiny) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              Translator.get('calc_target_shiny') !=
                                      'calc_target_shiny'
                                  ? Translator.get('calc_target_shiny')
                                  : 'Ziel ist Shiny',
                            ),
                            value: _isTargetShiny,
                            onChanged: (val) {
                              _isTargetShiny = val;
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showCatchWindow) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              Translator.get('calc_catch_window') !=
                                      'calc_catch_window'
                                  ? Translator.get('calc_catch_window')
                                  : 'Fangfenster (betäubt)',
                            ),
                            value: _isCatchWindow,
                            onChanged: (val) {
                              _isCatchWindow = val;
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showAlpha) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              Translator.get('calc_alpha') != 'calc_alpha'
                                  ? Translator.get('calc_alpha')
                                  : 'Alpha Pokémon',
                            ),
                            value: _isAlpha,
                            onChanged: (val) {
                              _isAlpha = val;
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showDarkGrass) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_dark_grass')),
                            value: _isDarkGrass,
                            onChanged: (val) {
                              _isDarkGrass = val;
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showEnemyLevel) ...[
                          Text(
                            Translator.get(
                              'calc_enemy_level',
                            ).replaceAll('{0}', '$_enemyLevel'),
                          ),
                          Slider(
                            value: _enemyLevel.toDouble(),
                            min: 1,
                            max: 100,
                            divisions: 99,
                            activeColor: Colors.redAccent,
                            label: '$_enemyLevel',
                            onChanged: (val) {
                              _enemyLevel = val.toInt();
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showOwnLevel) ...[
                          Text(
                            Translator.get(
                              'calc_own_level',
                            ).replaceAll('{0}', '$_ownLevel'),
                          ),
                          Slider(
                            value: _ownLevel.toDouble(),
                            min: 1,
                            max: 100,
                            divisions: 99,
                            activeColor: Colors.blueAccent,
                            label: '$_ownLevel',
                            onChanged: (val) {
                              _ownLevel = val.toInt();
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showTurnCount) ...[
                          const SizedBox(height: 8),
                          Text(
                            Translator.get(
                              'calc_turn_count',
                            ).replaceAll('{0}', '$_turnCount'),
                          ),
                          Slider(
                            value: _turnCount.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '$_turnCount',
                            onChanged: (val) {
                              _turnCount = val.toInt();
                              _updateResult();
                            },
                          ),
                        ],
                        if (_currentStrategy.showMissingBadges) ...[
                          DropdownButtonFormField<int>(
                            value: _missingBadges,
                            decoration: InputDecoration(
                              labelText:
                                  Translator.get('calc_missing_badges') !=
                                      'calc_missing_badges'
                                  ? Translator.get('calc_missing_badges')
                                  : 'Fehlende Orden',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            items: List.generate(
                              9,
                              (i) =>
                                  DropdownMenuItem(value: i, child: Text('$i')),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                _missingBadges = val;
                                _updateResult();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_currentStrategy.showZaRank) ...[
                          DropdownButtonFormField<int>(
                            value: _zaRank,
                            decoration: InputDecoration(
                              labelText:
                                  Translator.get('calc_za_rank') !=
                                      'calc_za_rank'
                                  ? Translator.get('calc_za_rank')
                                  : 'Z-A Royale Rang',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            items: [
                              DropdownMenuItem(value: 0, child: Text('Z')),
                              DropdownMenuItem(value: 1, child: Text('Y')),
                              DropdownMenuItem(value: 2, child: Text('X')),
                              DropdownMenuItem(value: 3, child: Text('W')),
                              DropdownMenuItem(value: 4, child: Text('V')),
                              DropdownMenuItem(value: 5, child: Text('F')),
                              DropdownMenuItem(value: 6, child: Text('E')),
                              DropdownMenuItem(value: 7, child: Text('D')),
                              DropdownMenuItem(value: 8, child: Text('C')),
                              DropdownMenuItem(value: 9, child: Text('B')),
                              DropdownMenuItem(value: 10, child: Text('A')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _zaRank = val;
                                _updateResult();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_currentStrategy.showPlushLevel) ...[
                          DropdownButtonFormField<int>(
                            value: _plushLevel,
                            decoration: InputDecoration(
                              labelText:
                                  Translator.get('calc_plush_level') !=
                                      'calc_plush_level'
                                  ? Translator.get('calc_plush_level')
                                  : 'Plüsch Level',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text(
                                  Translator.get('calc_plush_none') !=
                                          'calc_plush_none'
                                      ? Translator.get('calc_plush_none')
                                      : 'Keins',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('Level 1 (+10%)'),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text('Level 2 (+20%)'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('Level 3 (+35%)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _plushLevel = val;
                                _updateResult();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_currentStrategy.showDonutPenalty) ...[
                          DropdownButtonFormField<int>(
                            value: _donutPenalty,
                            decoration: InputDecoration(
                              labelText:
                                  Translator.get('calc_donut_penalty') !=
                                      'calc_donut_penalty'
                                  ? Translator.get('calc_donut_penalty')
                                  : 'Donut Malus',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text(
                                  Translator.get('calc_donut_none') !=
                                          'calc_donut_none'
                                      ? Translator.get('calc_donut_none')
                                      : 'Keiner',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  Translator.get('calc_donut_minus1') !=
                                          'calc_donut_minus1'
                                      ? Translator.get('calc_donut_minus1')
                                      : '-1 Stern',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(
                                  Translator.get('calc_donut_minus2') !=
                                          'calc_donut_minus2'
                                      ? Translator.get('calc_donut_minus2')
                                      : '-2 Sterne',
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _donutPenalty = val;
                                _updateResult();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_currentStrategy.showFishing)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Angel-Begegnung?'),
                            value: _isFishing,
                            onChanged: (val) {
                              _isFishing = val;
                              _updateResult();
                            },
                          ),
                        if (_currentStrategy.showSurfing)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Surfen / Tauchen Begegnung?'),
                            value: _isSurfingOrDiving,
                            onChanged: (val) {
                              _isSurfingOrDiving = val;
                              _updateResult();
                            },
                          ),
                        if (_currentStrategy.showNightEncounter)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_night_cave')),
                            value: _isNightOrCave,
                            onChanged: (val) {
                              _isNightOrCave = val;
                              _updateResult();
                            },
                          ),
                        if (_currentStrategy.showLoveCondition)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_love_condition')),
                            value: _isLoveConditionMet,
                            onChanged: (val) {
                              _isLoveConditionMet = val;
                              _updateResult();
                            },
                          ),
                        if (_currentStrategy.showRepeatCondition)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_already_caught')),
                            value: _isAlreadyCaught,
                            onChanged: (val) {
                              _isAlreadyCaught = val;
                              _updateResult();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_currentStrategy.showHpAndStatus && !_isMaxRaid) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _statusType,
              decoration: InputDecoration(
                labelText: Translator.get('status_condition'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(Translator.get('status_none')),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(Translator.get('status_par_psn_brn')),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(Translator.get('status_slp_frz')),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  _statusType = val;
                  _updateResult();
                }
              },
            ),
            const SizedBox(height: 16),
            Text('${Translator.get('hp_percent')}: ${_hpPercent.toInt()}%'),
            Slider(
              value: _hpPercent,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              activeColor: _hpPercent > 50
                  ? Colors.green
                  : (_hpPercent > 20 ? Colors.orange : Colors.red),
              label: '${_hpPercent.toInt()}%',
              onChanged: (val) {
                _hpPercent = val;
                _updateResult();
              },
            ),
          ],
          if (_currentStrategy.showCritSettings) ...[
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: ExpansionTile(
                leading: const Icon(Icons.star_border),
                title: Text(
                  Translator.get('calc_crit_settings'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DropdownButtonFormField<double>(
                          value: _dexMultiplier,
                          decoration: InputDecoration(
                            labelText: Translator.get('dex_caught'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            prefixIcon: const Icon(Icons.menu_book),
                          ),
                          items: _dexMultipliers.entries.map((entry) {
                            return DropdownMenuItem<double>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _dexMultiplier = val;
                              _updateResult();
                            }
                          },
                        ),
                        if (_selectedGen >= 8.0) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('catching_charm')),
                            secondary: const Icon(Icons.key),
                            value: _hasCatchingCharm,
                            onChanged: (val) {
                              _hasCatchingCharm = val;
                              _updateResult();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isGuaranteed
                  ? Colors.green.withOpacity(0.2)
                  : Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGuaranteed
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                if (_currentResult.glitchText != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bug_report,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentResult.glitchText!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  Translator.get('catch_chance'),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuaranteed
                      ? Translator.get('guaranteed_catch')
                      : '~ ${_currentResult.catchChance.toStringAsFixed(1)} %',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isGuaranteed
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (_currentStrategy.showCritSettings &&
                    _currentResult.critChance > 0 &&
                    !isGuaranteed) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    Translator.get('critical_catch_chance'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '~ ${_currentResult.critChance.toStringAsFixed(2)} %',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
