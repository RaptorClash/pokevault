import 'dart:math';
import 'package:flutter/material.dart';
import '../../../l10n/app_translations.dart';
import '../../../models/pokemon.dart';
import '../../../data/encounters_data.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../utils/notification_helper.dart';
import '../../../utils/catch_rate/models.dart';
import '../../../utils/catch_rate/strategy_base.dart';
import 'catch_rate_ui_components.dart';

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
    return hasEncounter || isStatic || gen == _minGen;
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (val) {
        onChanged(val);
        _updateResult();
      },
    );
  }

  Widget _buildSlider(
    String titleKey,
    int value,
    int min,
    int max,
    Color color,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleKey.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(Translator.get(titleKey).replaceAll('{0}', '$value')),
        ],
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: color,
          label: '$value',
          onChanged: (val) {
            onChanged(val.toInt());
            _updateResult();
          },
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        items: items,
        onChanged: (val) {
          if (val != null) {
            onChanged(val);
            _updateResult();
          }
        },
      ),
    );
  }

  Widget _buildHeader(List<BallOption> currentBalls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${Translator.get('calc_base_rate')}: ${_currentResult.baseRate}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          initialValue: _selectedGen,
          decoration: InputDecoration(
            labelText: Translator.get('generation'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          initialValue: currentBalls.any((b) => b.id == _selectedBallId)
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
      ],
    );
  }

  Widget _buildBattleConditions() {
    String t(String key, String fallback) =>
        Translator.get(key) != key ? Translator.get(key) : fallback;

    return Card(
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
                if (_currentStrategy.showPowerOptions)
                  _buildDropdown<double>(
                    _selectedGen == 7.5
                        ? Translator.get('calc_berry_let_go')
                        : Translator.get('calc_bonus_power'),
                    _powerBonus,
                    _currentStrategy.getPowerOptions(),
                    (v) => _powerBonus = v,
                  ),
                if (_currentStrategy.showMaxRaid) ...[
                  _buildSwitch(
                    Translator.get('calc_max_raid'),
                    _isMaxRaid,
                    (v) => _isMaxRaid = v,
                  ),
                  if (_isMaxRaid) ...[
                    _buildSwitch(
                      Translator.get('calc_max_raid_guest'),
                      _isGuest,
                      (v) => _isGuest = v,
                    ),
                    _buildSwitch(
                      Translator.get('calc_max_raid_gmax'),
                      _isGigantamax,
                      (v) => _isGigantamax = v,
                    ),
                  ],
                ],
                if (_currentStrategy.isArceus)
                  _buildDropdown<int>(
                    Translator.get('calc_hisui_status'),
                    _hisuiCatchStatus,
                    [
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
                    (v) => _hisuiCatchStatus = v,
                  ),
                if (_currentStrategy.showFlying)
                  _buildSwitch(
                    Translator.get('calc_flying'),
                    _isFlying,
                    (v) => _isFlying = v,
                  ),
                if (_currentStrategy.showUnnoticed)
                  _buildSwitch(
                    t('calc_unnoticed', 'Unbemerkt'),
                    _isUnnoticed,
                    (v) => _isUnnoticed = v,
                  ),
                if (_currentStrategy.showBackstrike)
                  _buildSwitch(
                    t('calc_backstrike', 'Rückenangriff'),
                    _isBackstrike,
                    (v) => _isBackstrike = v,
                  ),
                if (_currentStrategy.showTargetShiny)
                  _buildSwitch(
                    t('calc_target_shiny', 'Ziel ist Shiny'),
                    _isTargetShiny,
                    (v) => _isTargetShiny = v,
                  ),
                if (_currentStrategy.showCatchWindow)
                  _buildSwitch(
                    t('calc_catch_window', 'Fangfenster (betäubt)'),
                    _isCatchWindow,
                    (v) => _isCatchWindow = v,
                  ),
                if (_currentStrategy.showAlpha)
                  _buildSwitch(
                    t('calc_alpha', 'Alpha Pokémon'),
                    _isAlpha,
                    (v) => _isAlpha = v,
                  ),
                if (_currentStrategy.showDarkGrass)
                  _buildSwitch(
                    Translator.get('calc_dark_grass'),
                    _isDarkGrass,
                    (v) => _isDarkGrass = v,
                  ),
                if (_currentStrategy.showEnemyLevel)
                  _buildSlider(
                    'calc_enemy_level',
                    _enemyLevel,
                    1,
                    100,
                    Colors.redAccent,
                    (v) => _enemyLevel = v,
                  ),
                if (_currentStrategy.showOwnLevel)
                  _buildSlider(
                    'calc_own_level',
                    _ownLevel,
                    1,
                    100,
                    Colors.blueAccent,
                    (v) => _ownLevel = v,
                  ),
                if (_currentStrategy.showTurnCount)
                  _buildSlider(
                    'calc_turn_count',
                    _turnCount,
                    1,
                    30,
                    Theme.of(context).colorScheme.primary,
                    (v) => _turnCount = v,
                  ),
                if (_currentStrategy.showMissingBadges)
                  _buildDropdown<int>(
                    t('calc_missing_badges', 'Fehlende Orden'),
                    _missingBadges,
                    List.generate(
                      9,
                      (i) => DropdownMenuItem(value: i, child: Text('$i')),
                    ),
                    (v) => _missingBadges = v,
                  ),
                if (_currentStrategy.showZaRank)
                  _buildDropdown<int>(
                    t('calc_za_rank', 'Z-A Royale Rang'),
                    _zaRank,
                    [
                      const DropdownMenuItem(value: 0, child: Text('Z')),
                      const DropdownMenuItem(value: 1, child: Text('Y')),
                      const DropdownMenuItem(value: 2, child: Text('X')),
                      const DropdownMenuItem(value: 3, child: Text('W')),
                      const DropdownMenuItem(value: 4, child: Text('V')),
                      const DropdownMenuItem(value: 5, child: Text('F')),
                      const DropdownMenuItem(value: 6, child: Text('E')),
                      const DropdownMenuItem(value: 7, child: Text('D')),
                      const DropdownMenuItem(value: 8, child: Text('C')),
                      const DropdownMenuItem(value: 9, child: Text('B')),
                      const DropdownMenuItem(value: 10, child: Text('A')),
                    ],
                    (v) => _zaRank = v,
                  ),
                if (_currentStrategy.showPlushLevel)
                  _buildDropdown<int>(
                    t('calc_plush_level', 'Plüsch Level'),
                    _plushLevel,
                    [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(t('calc_plush_none', 'Keins')),
                      ),
                      const DropdownMenuItem(
                        value: 1,
                        child: Text('Level 1 (+10%)'),
                      ),
                      const DropdownMenuItem(
                        value: 2,
                        child: Text('Level 2 (+20%)'),
                      ),
                      const DropdownMenuItem(
                        value: 3,
                        child: Text('Level 3 (+35%)'),
                      ),
                    ],
                    (v) => _plushLevel = v,
                  ),
                if (_currentStrategy.showDonutPenalty)
                  _buildDropdown<int>(
                    t('calc_donut_penalty', 'Donut Malus'),
                    _donutPenalty,
                    [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(t('calc_donut_none', 'Keiner')),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(t('calc_donut_minus1', '-1 Stern')),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(t('calc_donut_minus2', '-2 Sterne')),
                      ),
                    ],
                    (v) => _donutPenalty = v,
                  ),
                if (_currentStrategy.showFishing)
                  _buildSwitch(
                    'Angel-Begegnung?',
                    _isFishing,
                    (v) => _isFishing = v,
                  ),
                if (_currentStrategy.showSurfing)
                  _buildSwitch(
                    'Surfen / Tauchen Begegnung?',
                    _isSurfingOrDiving,
                    (v) => _isSurfingOrDiving = v,
                  ),
                if (_currentStrategy.showNightEncounter)
                  _buildSwitch(
                    Translator.get('calc_night_cave'),
                    _isNightOrCave,
                    (v) => _isNightOrCave = v,
                  ),
                if (_currentStrategy.showLoveCondition)
                  _buildSwitch(
                    Translator.get('calc_love_condition'),
                    _isLoveConditionMet,
                    (v) => _isLoveConditionMet = v,
                  ),
                if (_currentStrategy.showRepeatCondition)
                  _buildSwitch(
                    Translator.get('calc_already_caught'),
                    _isAlreadyCaught,
                    (v) => _isAlreadyCaught = v,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final currentBalls = _currentStrategy.getAvailableBalls();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(currentBalls),
          if (hasBattleConditions) ...[
            const SizedBox(height: 12),
            _buildBattleConditions(),
          ],
          if (_currentStrategy.showHpAndStatus && !_isMaxRaid) ...[
            const SizedBox(height: 12),
            CatchRateHpStatusWidget(
              statusType: _statusType,
              hpPercent: _hpPercent,
              onStatusChanged: (val) {
                _statusType = val;
                _updateResult();
              },
              onHpChanged: (val) {
                _hpPercent = val;
                _updateResult();
              },
            ),
          ],
          if (_currentStrategy.showCritSettings) ...[
            const SizedBox(height: 8),
            CatchRateCritSettingsWidget(
              dexMultiplier: _dexMultiplier,
              hasCatchingCharm: _hasCatchingCharm,
              selectedGen: _selectedGen,
              dexMultipliers: _dexMultipliers,
              onDexMultiplierChanged: (val) {
                _dexMultiplier = val;
                _updateResult();
              },
              onCatchingCharmChanged: (val) {
                _hasCatchingCharm = val;
                _updateResult();
              },
            ),
          ],
          const SizedBox(height: 24),
          CatchRateResultCard(
            result: _currentResult,
            strategy: _currentStrategy,
          ),
        ],
      ),
    );
  }
}
