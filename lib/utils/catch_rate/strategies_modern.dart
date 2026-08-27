import 'dart:math';
import 'package:flutter/material.dart';

import 'models.dart';
import 'strategy_base.dart';
import '../../data/catch_data.dart';
import '../../l10n/app_translations.dart';

abstract class ModernStrategyBase extends CatchRateStrategy {
  ModernStrategyBase(super.gen);

  @override
  bool get showEnemyLevel => true;
  @override
  bool get showOwnLevel => true;
  @override
  bool get showTurnCount => true;
  @override
  bool get showFishing => true;
  @override
  bool get showSurfing => true;
  @override
  bool get showNightEncounter => true;
  @override
  bool get showLoveCondition => true;
  @override
  bool get showRepeatCondition => true;

  @override
  List<BallOption> getAvailableBalls() {
    List<BallOption> balls = [
      BallOption('poke', Translator.get('ball_poke_ball'), 'poke-ball'),
      BallOption('great', Translator.get('ball_great_ball'), 'great-ball'),
      BallOption('ultra', Translator.get('ball_ultra_ball'), 'ultra-ball'),
      BallOption('master', Translator.get('ball_master_ball'), 'master-ball'),
      BallOption('safari', Translator.get('ball_safari_ball'), 'safari-ball'),
      BallOption('fast', Translator.get('ball_fast_ball'), 'fast-ball'),
      BallOption('level', Translator.get('ball_level_ball'), 'level-ball'),
      BallOption('lure', Translator.get('ball_lure_ball'), 'lure-ball'),
      BallOption('heavy', Translator.get('ball_heavy_ball'), 'heavy-ball'),
      BallOption('love', Translator.get('ball_love_ball'), 'love-ball'),
      BallOption('friend', Translator.get('ball_friend_ball'), 'friend-ball'),
      BallOption('moon', Translator.get('ball_moon_ball'), 'moon-ball'),
      BallOption('sport', Translator.get('ball_sport_ball'), 'sport-ball'),
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
    ];

    if (gen >= 4.0) {
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
    if (gen >= 5.0) {
      balls.add(
        BallOption('dream', Translator.get('ball_dream_ball'), 'dream-ball'),
      );
    }
    if (gen >= 7.0) {
      balls.add(
        BallOption('beast', Translator.get('ball_beast_ball'), 'beast-ball'),
      );
    }
    return balls;
  }

  BallEffectResult applyBallEffects(CatchRateParams params) {
    double ballBonus = 1.0;
    int modifiedBaseRate = params.pokemon.captureRate;
    double weight = catchDataDatabase[params.pokemon.id]?['weight'] ?? 50.0;
    int speed = catchDataDatabase[params.pokemon.id]?['speed'] ?? 50;
    List<String> types = params.pokemon.forms.isNotEmpty
        ? params.pokemon.forms.first.types
        : [];

    switch (params.ballId) {
      case 'great':
      case 'safari':
      case 'sport':
        ballBonus = 1.5;
        break;
      case 'ultra':
        ballBonus = 2.0;
        break;
      case 'fast':
        if (speed >= 100) ballBonus = 4.0;
        break;
      case 'love':
        ballBonus = params.isLoveConditionMet ? 8.0 : 1.0;
        break;
      case 'moon':
        if ([
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          39,
          40,
          300,
          301,
          517,
          518,
        ].contains(params.pokemon.id)) {
          ballBonus = 4.0;
        }
        break;
      case 'heavy':
        int modifier = 0;
        if (gen >= 7.0) {
          if (weight < 100.0) {
            modifier = -20;
          } else if (weight < 200.0)
            modifier = 0;
          else if (weight < 300.0)
            modifier = 20;
          else
            modifier = 30;
        } else {
          if (weight < 102.4) {
            modifier = -20;
          } else if (weight < 204.8)
            modifier = 0;
          else if (weight < 307.2)
            modifier = 20;
          else if (weight < 409.6)
            modifier = 30;
          else
            modifier = 40;
        }
        modifiedBaseRate = max(1, modifiedBaseRate + modifier);
        break;
      case 'lure':
        if (params.isFishing) {
          if (gen >= 8.0) {
            ballBonus = 4.0;
          } else if (gen == 7.0)
            ballBonus = 5.0;
          else
            ballBonus = 3.0;
        }
        break;
      case 'level':
        if ((params.ownLevel ~/ 4) > params.enemyLevel) {
          ballBonus = 8.0;
        } else if ((params.ownLevel ~/ 2) > params.enemyLevel)
          ballBonus = 4.0;
        else if (params.ownLevel > params.enemyLevel)
          ballBonus = 2.0;
        break;
      case 'net':
        if (types.contains('water') || types.contains('bug')) {
          ballBonus = (gen >= 7.0) ? 3.5 : 3.0;
        }
        break;
      case 'dive':
        if (params.isSurfingOrDiving) ballBonus = 3.5;
        break;
      case 'nest':
        if (gen >= 7.0) {
          ballBonus = max(
            1.0,
            8.0 - (810.0 / 4096.0) * (params.enemyLevel - 1),
          );
        } else if (gen >= 5.0)
          ballBonus = max(1.0, (41.0 - params.enemyLevel) / 10.0);
        else
          ballBonus = max(1.0, (40.0 - params.enemyLevel) / 10.0);
        break;
      case 'timer':
        if (gen >= 5.0) {
          ballBonus = min(4.0, 1.0 + (params.turnCount * (1229.0 / 4096.0)));
        } else {
          ballBonus = min(4.0, (params.turnCount + 10.0) / 10.0);
        }
        break;
      case 'quick':
        if (params.turnCount == 1) ballBonus = (gen >= 5.0) ? 5.0 : 4.0;
        break;
      case 'dusk':
        if (params.isNightOrCave) ballBonus = (gen >= 7.0) ? 3.0 : 3.5;
        break;
      case 'repeat':
        if (params.isAlreadyCaught) ballBonus = (gen >= 7.0) ? 3.5 : 3.0;
        break;
      case 'beast':
        if ([
          793,
          794,
          795,
          796,
          797,
          798,
          799,
          803,
          804,
          805,
          806,
        ].contains(params.pokemon.id)) {
          ballBonus = 5.0;
        } else {
          ballBonus = 410.0 / 4096.0;
        }
        break;
      case 'dream':
        if (gen >= 8.0 && params.statusType == 2) ballBonus = 4.0;
        break;
    }

    bool isUltraBeast = [
      793,
      794,
      795,
      796,
      797,
      798,
      799,
      803,
      804,
      805,
      806,
    ].contains(params.pokemon.id);
    if (isUltraBeast && params.ballId != 'beast') {
      ballBonus = 410.0 / 4096.0;
    }

    return BallEffectResult(ballBonus, modifiedBaseRate);
  }

  double getDifficultyModifier(CatchRateParams params) {
    if (gen == 8.0 &&
        params.missingBadges > 0 &&
        params.enemyLevel > params.ownLevel) {
      return 410.0 / 4096.0;
    }
    if (gen == 9.0) {
      return pow(0.8, params.missingBadges).toDouble();
    }
    return 1.0;
  }

  double getLevelModifier(CatchRateParams params) {
    if (gen == 8.0) {
      return max((30.0 - params.enemyLevel) / 10.0, 1.0);
    }
    if (gen == 9.0 && params.enemyLevel < 13) {
      return max((36.0 - 2.0 * params.enemyLevel) / 10.0, 1.0);
    }
    return 1.0;
  }

  @override
  CatchRateResult calculate(CatchRateParams params) {
    if (params.ballId == 'master' ||
        params.ballId == 'cherish' ||
        params.ballId == 'park' ||
        (params.ballId == 'dream' && gen == 5.0)) {
      return CatchRateResult(
        catchChance: 100.0,
        critChance: 0.0,
        bonus: 1.0,
        baseRate: params.pokemon.captureRate,
      );
    }

    final ballEffects = applyBallEffects(params);
    double ballBonus = ballEffects.bonus;
    int modifiedBaseRate = ballEffects.baseRate;

    bool isAprikoko = [
      'fast',
      'level',
      'lure',
      'heavy',
      'love',
      'friend',
      'moon',
    ].contains(params.ballId);
    if (gen <= 4.0 && isAprikoko) {
      modifiedBaseRate = min(255, (modifiedBaseRate * ballBonus).floor());
      ballBonus = 1.0;
    }

    double grassModifier = 1.0;
    if (gen == 5.0 && params.isDarkGrass) {
      if (params.dexMultiplier >= 2.5) {
        grassModifier = 1.0;
      } else if (params.dexMultiplier >= 2.0)
        grassModifier = 3686.0 / 4096.0;
      else if (params.dexMultiplier >= 1.5)
        grassModifier = 3277.0 / 4096.0;
      else if (params.dexMultiplier >= 1.0)
        grassModifier = 2867.0 / 4096.0;
      else if (params.dexMultiplier >= 0.5)
        grassModifier = 2048.0 / 4096.0;
      else
        grassModifier = 1229.0 / 4096.0;
    }

    double sBonus = params.statusType == 2
        ? 2.5
        : (params.statusType == 1 ? 1.5 : 1.0);
    if (gen <= 4.0) {
      sBonus = params.statusType == 2
          ? 2.0
          : (params.statusType == 1 ? 1.5 : 1.0);
    }

    double diffMod = getDifficultyModifier(params);
    double lvlMod = getLevelModifier(params);

    double miscBonus = params.powerBonus;
    if (gen == 9.0 && params.isBackstrike) {
      miscBonus *= 2.0;
    }

    double x =
        (((300.0 - 2.0 * params.hpPercent) *
                modifiedBaseRate *
                ballBonus *
                grassModifier) /
            300.0) *
        sBonus *
        miscBonus *
        diffMod *
        lvlMod;

    if (gen >= 8.0 && params.ownLevel < params.enemyLevel) {
      x *= (410.0 / 4096.0);
    }

    double catchChance = 0.0;
    double critChance = 0.0;

    if (x >= 255.0) {
      catchChance = 100.0;
    } else {
      double y = 1048560.0 / sqrt(sqrt(16711680.0 / x));
      double chancePerShake = y / 65536.0;

      if (gen >= 5.0) {
        double cc = (min(255.0, x) * params.dexMultiplier) / 6.0;
        if (params.hasCatchingCharm && gen >= 8.0) {
          critChance = (1 - pow(1 - (cc / 256.0), 2)) * 100;
        } else if (params.hasCatchingCharm) {
          critChance = (min(256.0, cc * 2) / 256.0) * 100;
        } else {
          critChance = (cc / 256.0) * 100;
        }

        double pCrit = critChance / 100.0;
        int numShakes = (gen == 5.0) ? 3 : 4;
        catchChance =
            (pCrit * chancePerShake +
                (1 - pCrit) * pow(chancePerShake, numShakes)) *
            100;
      } else {
        catchChance = pow(chancePerShake, 4) * 100;
      }
    }

    return CatchRateResult(
      catchChance: catchChance.clamp(0.0, 100.0),
      critChance: critChance.clamp(0.0, 100.0),
      bonus: ballBonus,
      baseRate: modifiedBaseRate,
    );
  }
}

class Gen34Strategy extends ModernStrategyBase {
  Gen34Strategy(super.gen);
  @override
  bool get showPowerOptions => false;
  @override
  bool get showCritSettings => false;
}

class Gen5Strategy extends ModernStrategyBase {
  Gen5Strategy() : super(5.0);
  @override
  bool get showPowerOptions => true;
  @override
  bool get showDarkGrass => true;
  @override
  bool get showCritSettings => true;

  @override
  List<DropdownMenuItem<double>> getPowerOptions() => [
    DropdownMenuItem(
      value: 1.0,
      child: Text(Translator.get('calc_power_none')),
    ),
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
  ];
}

class Gen67Strategy extends ModernStrategyBase {
  Gen67Strategy(super.gen);
  @override
  bool get showPowerOptions => true;
  @override
  bool get showCritSettings => true;

  @override
  List<DropdownMenuItem<double>> getPowerOptions() {
    var opts = [
      DropdownMenuItem(
        value: 1.0,
        child: Text(Translator.get('calc_power_none')),
      ),
    ];
    if (gen == 6.0) {
      opts.addAll([
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
    } else {
      opts.add(
        DropdownMenuItem(
          value: 2.5,
          child: Text(Translator.get('calc_power_roto')),
        ),
      );
    }
    return opts;
  }
}

class Gen8Strategy extends ModernStrategyBase {
  Gen8Strategy() : super(8.0);
  @override
  bool get showCritSettings => true;
  @override
  bool get showMaxRaid => true;
  @override
  bool get showMissingBadges => true;

  @override
  CatchRateResult calculate(CatchRateParams params) {
    if (params.isMaxRaid) {
      if (!params.isGuest) {
        return CatchRateResult(
          catchChance: 100.0,
          critChance: 0.0,
          bonus: 1.0,
          baseRate: params.pokemon.captureRate,
        );
      }
      double difficulty = params.isGigantamax ? (291.0 / 4096.0) : 2.0;
      double ballBonus = applyBallEffects(params).bonus;

      if (params.ballId == 'quick') {
        ballBonus = 1.0;
      }

      double x = params.pokemon.captureRate * ballBonus * difficulty;
      double catchChance = 0.0;
      if (x >= 255.0) {
        catchChance = 100.0;
      } else {
        double y = 1048560.0 / sqrt(sqrt(16711680.0 / x));
        double chancePerShake = y / 65536.0;
        catchChance = pow(chancePerShake, 4) * 100;
      }
      return CatchRateResult(
        catchChance: catchChance.clamp(0.0, 100.0),
        critChance: 0.0,
        bonus: ballBonus,
        baseRate: params.pokemon.captureRate,
      );
    }
    return super.calculate(params);
  }
}

class Gen9Strategy extends ModernStrategyBase {
  Gen9Strategy() : super(9.0);
  @override
  bool get showPowerOptions => true;
  @override
  bool get showCritSettings => true;
  @override
  bool get showBackstrike => true;
  @override
  bool get showMissingBadges => true;

  @override
  List<DropdownMenuItem<double>> getPowerOptions() => [
    DropdownMenuItem(
      value: 1.0,
      child: Text(Translator.get('calc_power_none')),
    ),
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
  ];
}
