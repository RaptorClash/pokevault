import 'dart:math';
import 'package:flutter/material.dart';
import '../../../l10n/app_translations.dart';
import '../../../models/pokemon.dart';
import '../../../data/encounters_data.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../utils/catch_rate_logic.dart';

class BallOption {
  final String id;
  final String nameKey;
  final String spriteId;
  BallOption(this.id, this.nameKey, this.spriteId);
}

class CatchRateCalculator extends StatefulWidget {
  final Pokemon pokemon;
  const CatchRateCalculator({super.key, required this.pokemon});

  @override
  State<CatchRateCalculator> createState() => _CatchRateCalculatorState();
}

class _CatchRateCalculatorState extends State<CatchRateCalculator> {
  late double _minGen;
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

  late CatchRateResult _currentResult;

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

    List<double> availableGens = _genNames.keys
        .where((g) => _canShowGen(g, widget.pokemon.id))
        .toList();
    if (availableGens.isNotEmpty) {
      _selectedGen = availableGens.last;
    } else {
      _selectedGen = max(_minGen, 9.0);
    }

    _updateResult();
  }

  void _updateResult() {
    setState(() {
      _currentResult = CatchRateLogic.calculate(
        pokemon: widget.pokemon,
        selectedGen: _selectedGen,
        selectedBallId: _selectedBallId,
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
      );
    });
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

    return hasEncounter || isStatic || gen == _minGen;
  }

  List<BallOption> _getBallsForGen() {
    if (_selectedGen == 8.5) {
      return [
        BallOption(
          'poke_hisui',
          Translator.get('ball_poke_hisui'),
          'poke-ball-hisui',
        ),
        BallOption(
          'great_hisui',
          Translator.get('ball_great_hisui'),
          'great-ball-hisui',
        ),
        BallOption(
          'ultra_hisui',
          Translator.get('ball_ultra_hisui'),
          'ultra-ball-hisui',
        ),
        BallOption(
          'heavy_hisui',
          Translator.get('ball_heavy_hisui'),
          'heavy-ball-hisui',
        ),
        BallOption('leaden', Translator.get('ball_leaden'), 'leaden-ball'),
        BallOption('gigaton', Translator.get('ball_gigaton'), 'gigaton-ball'),
        BallOption('feather', Translator.get('ball_feather'), 'feather-ball'),
        BallOption('wing', Translator.get('ball_wing'), 'wing-ball'),
        BallOption('jet', Translator.get('ball_jet'), 'jet-ball'),
        BallOption('origin', Translator.get('ball_origin'), 'origin-ball'),
      ];
    }

    if (_selectedGen == 7.5) {
      return [
        BallOption('poke', Translator.get('ball_poke_ball'), 'poke-ball'),
        BallOption('great', Translator.get('ball_great_ball'), 'great-ball'),
        BallOption('ultra', Translator.get('ball_ultra_ball'), 'ultra-ball'),
        BallOption(
          'premier',
          Translator.get('ball_premier_ball'),
          'premier-ball',
        ),
        BallOption('master', Translator.get('ball_master_ball'), 'master-ball'),
      ];
    }

    List<BallOption> balls = [
      BallOption('poke', Translator.get('ball_poke_ball'), 'poke-ball'),
      BallOption('great', Translator.get('ball_great_ball'), 'great-ball'),
      BallOption('ultra', Translator.get('ball_ultra_ball'), 'ultra-ball'),
      BallOption('master', Translator.get('ball_master_ball'), 'master-ball'),
      BallOption('safari', Translator.get('ball_safari_ball'), 'safari-ball'),
    ];

    if (_selectedGen >= 2.0) {
      balls.addAll([
        BallOption('fast', Translator.get('ball_fast_ball'), 'fast-ball'),
        BallOption('level', Translator.get('ball_level_ball'), 'level-ball'),
        BallOption('lure', Translator.get('ball_lure_ball'), 'lure-ball'),
        BallOption('heavy', Translator.get('ball_heavy_ball'), 'heavy-ball'),
        BallOption('love', Translator.get('ball_love_ball'), 'love-ball'),
        BallOption('friend', Translator.get('ball_friend_ball'), 'friend-ball'),
        BallOption('moon', Translator.get('ball_moon_ball'), 'moon-ball'),
        BallOption('sport', Translator.get('ball_sport_ball'), 'sport-ball'),
      ]);
    }
    if (_selectedGen >= 3.0) {
      balls.addAll([
        BallOption('net', Translator.get('ball_net_ball'), 'net-ball'),
        BallOption('dive', Translator.get('ball_dive_ball'), 'dive-ball'),
        BallOption('nest', Translator.get('ball_nest_ball'), 'nest-ball'),
        BallOption('timer', Translator.get('ball_timer_ball'), 'timer-ball'),
        BallOption(
          'premier',
          Translator.get('ball_premier_ball'),
          'premier-ball',
        ),
        BallOption('repeat', Translator.get('ball_repeat_ball'), 'repeat-ball'),
        BallOption('luxury', Translator.get('ball_luxury_ball'), 'luxury-ball'),
      ]);
    }
    if (_selectedGen >= 4.0) {
      balls.addAll([
        BallOption('dusk', Translator.get('ball_dusk_ball'), 'dusk-ball'),
        BallOption('heal', Translator.get('ball_heal_ball'), 'heal-ball'),
        BallOption('quick', Translator.get('ball_quick_ball'), 'quick-ball'),
        BallOption(
          'cherish',
          Translator.get('ball_cherish_ball'),
          'cherish-ball',
        ),
      ]);
    }
    if (_selectedGen >= 5.0) {
      balls.add(
        BallOption('dream', Translator.get('ball_dream_ball'), 'dream-ball'),
      );
    }
    if (_selectedGen >= 7.0) {
      balls.add(
        BallOption('beast', Translator.get('ball_beast_ball'), 'beast-ball'),
      );
    }
    return balls;
  }

  List<DropdownMenuItem<double>> _getPowerOptions() {
    List<DropdownMenuItem<double>> options = [
      DropdownMenuItem(
        value: 1.0,
        child: Text(Translator.get('calc_power_none')),
      ),
    ];
    if (_selectedGen == 5.0) {
      options.addAll([
        DropdownMenuItem(
          value: 1.1,
          child: Text(Translator.get('calc_power_pass1')),
        ),
        DropdownMenuItem(
          value: 1.2,
          child: Text(Translator.get('calc_power_pass2')),
        ),
        DropdownMenuItem(
          value: 1.3,
          child: Text(Translator.get('calc_power_pass3')),
        ),
      ]);
    } else if (_selectedGen == 6.0) {
      options.addAll([
        DropdownMenuItem(
          value: 1.5,
          child: Text(Translator.get('calc_power_o1')),
        ),
        DropdownMenuItem(
          value: 2.0,
          child: Text(Translator.get('calc_power_o2')),
        ),
        DropdownMenuItem(
          value: 2.5,
          child: Text(Translator.get('calc_power_o3')),
        ),
      ]);
    } else if (_selectedGen == 7.0) {
      options.addAll([
        DropdownMenuItem(
          value: 2.5,
          child: Text(Translator.get('calc_power_roto')),
        ),
      ]);
    } else if (_selectedGen == 7.5) {
      options.addAll([
        DropdownMenuItem(
          value: 1.5,
          child: Row(
            children: [
              Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/razz-berry.png',
                width: 24,
                height: 24,
                errorBuilder: (c, e, s) => const Icon(Icons.grass, size: 20),
              ),
              const SizedBox(width: 8),
              Text(Translator.get('berry_razz')),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 2.25,
          child: Row(
            children: [
              Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/silver-razz-berry.png',
                width: 24,
                height: 24,
                errorBuilder: (c, e, s) => const Icon(Icons.grass, size: 20),
              ),
              const SizedBox(width: 8),
              Text(Translator.get('berry_silver_razz')),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 2.5,
          child: Row(
            children: [
              Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/golden-razz-berry.png',
                width: 24,
                height: 24,
                errorBuilder: (c, e, s) => const Icon(Icons.grass, size: 20),
              ),
              const SizedBox(width: 8),
              Text(Translator.get('berry_golden_razz')),
            ],
          ),
        ),
      ]);
    } else if (_selectedGen >= 9.0) {
      options.addAll([
        DropdownMenuItem(
          value: 1.1,
          child: Text(Translator.get('calc_power_sand1')),
        ),
        DropdownMenuItem(
          value: 1.25,
          child: Text(Translator.get('calc_power_sand2')),
        ),
        DropdownMenuItem(
          value: 2.0,
          child: Text(Translator.get('calc_power_sand3')),
        ),
      ]);
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    bool isGuaranteed = _currentResult.catchChance >= 100.0;
    final currentBalls = _getBallsForGen();

    bool showPowerOptions =
        (_selectedGen >= 5.0 && _selectedGen != 8.0 && _selectedGen != 8.5) ||
        _selectedGen == 7.5;
    bool showEnemyLevel =
        _selectedBallId == 'nest' ||
        _selectedBallId == 'level' ||
        (_selectedGen >= 8.0 && _selectedGen != 8.5);
    bool showOwnLevel =
        _selectedBallId == 'level' ||
        (_selectedGen >= 8.0 && _selectedGen != 8.5);
    bool showTurnCount =
        _selectedBallId == 'timer' || _selectedBallId == 'quick';
    bool showFishing = _selectedBallId == 'lure';
    bool showSurfing = _selectedBallId == 'dive';
    bool showNightEncounter = _selectedBallId == 'dusk';
    bool showLoveCondition = _selectedBallId == 'love' && _selectedGen > 2.0;
    bool showRepeatCondition = _selectedBallId == 'repeat';
    bool showDarkGrass = _selectedGen == 5.0;

    bool isArceus = _selectedGen == 8.5;
    bool showFlying =
        isArceus &&
        (_selectedBallId == 'feather' ||
            _selectedBallId == 'wing' ||
            _selectedBallId == 'jet');

    bool showHpAndStatus =
        _selectedGen != 7.5 && !(isArceus && _hisuiCatchStatus > 0);

    bool hasBattleConditions =
        showPowerOptions ||
        showEnemyLevel ||
        showOwnLevel ||
        showTurnCount ||
        showFishing ||
        showSurfing ||
        showNightEncounter ||
        showLoveCondition ||
        showRepeatCondition ||
        showDarkGrass ||
        isArceus ||
        showFlying;

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
            items: _genNames.entries
                .where((entry) => _canShowGen(entry.key, widget.pokemon.id))
                .map((entry) {
                  return DropdownMenuItem<double>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                })
                .toList(),
            onChanged: (val) {
              if (val != null) {
                _selectedGen = val;
                _powerBonus = 1.0;
                final newBalls = _getBallsForGen();
                if (!newBalls.any((b) => b.id == _selectedBallId)) {
                  _selectedBallId = newBalls.first.id;
                }
                _updateResult();
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
              if (val != null) {
                _selectedBallId = val;
                _updateResult();
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
                        if (showPowerOptions) ...[
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
                            items: _getPowerOptions(),
                            onChanged: (val) {
                              if (val != null) {
                                _powerBonus = val;
                                _updateResult();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (isArceus) ...[
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

                        if (showFlying) ...[
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
                        if (showDarkGrass) ...[
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
                        if (showEnemyLevel) ...[
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
                        if (showOwnLevel) ...[
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
                        if (showTurnCount) ...[
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
                        if (showFishing)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Angel-Begegnung?'),
                            value: _isFishing,
                            onChanged: (val) {
                              _isFishing = val;
                              _updateResult();
                            },
                          ),
                        if (showSurfing)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Surfen / Tauchen Begegnung?'),
                            value: _isSurfingOrDiving,
                            onChanged: (val) {
                              _isSurfingOrDiving = val;
                              _updateResult();
                            },
                          ),
                        if (showNightEncounter)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_night_cave')),
                            value: _isNightOrCave,
                            onChanged: (val) {
                              _isNightOrCave = val;
                              _updateResult();
                            },
                          ),
                        if (showLoveCondition)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Translator.get('calc_love_condition')),
                            value: _isLoveConditionMet,
                            onChanged: (val) {
                              _isLoveConditionMet = val;
                              _updateResult();
                            },
                          ),
                        if (showRepeatCondition)
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

          if (showHpAndStatus) ...[
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

          if (_selectedGen >= 5.0 &&
              _selectedGen != 7.5 &&
              _selectedGen != 8.5 &&
              _selectedBallId != 'master') ...[
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
                if (_selectedGen >= 5.0 &&
                    _selectedGen != 7.5 &&
                    _selectedGen != 8.5 &&
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
