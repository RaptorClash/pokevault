import 'dart:math';
import 'package:flutter/material.dart';

import 'models.dart';
import 'strategy_base.dart';
import '../../l10n/app_translations.dart';

class Gen75Strategy extends CatchRateStrategy {
  Gen75Strategy() : super(7.5);

  @override
  bool get showPowerOptions => true;
  @override
  bool get showHpAndStatus => false;

  @override
  List<BallOption> getAvailableBalls() => [
    BallOption('poke', Translator.get('ball_poke_ball'), 'poke-ball'),
    BallOption('great', Translator.get('ball_great_ball'), 'great-ball'),
    BallOption('ultra', Translator.get('ball_ultra_ball'), 'ultra-ball'),
    BallOption('premier', Translator.get('ball_premier_ball'), 'premier-ball'),
    BallOption('master', Translator.get('ball_master_ball'), 'master-ball'),
  ];

  @override
  List<DropdownMenuItem<double>> getPowerOptions() => [
    DropdownMenuItem(
      value: 1.0,
      child: Text(Translator.get('calc_power_none')),
    ),
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
  ];

  @override
  CatchRateResult calculate(CatchRateParams params) {
    if (params.ballId == 'master') {
      return CatchRateResult(
        catchChance: 100.0,
        critChance: 0.0,
        bonus: 1.0,
        baseRate: params.pokemon.captureRate,
      );
    }

    double ballBonus = 1.0;
    if (params.ballId == 'great') ballBonus = 1.5;
    if (params.ballId == 'ultra') ballBonus = 2.0;

    double x =
        (params.pokemon.captureRate * ballBonus * params.powerBonus) / 3.0;
    double catchChance = x >= 255 ? 100.0 : (x / 255.0) * 100;

    return CatchRateResult(
      catchChance: catchChance.clamp(0.0, 100.0),
      critChance: 0.0,
      bonus: ballBonus,
      baseRate: params.pokemon.captureRate,
    );
  }
}

class Gen85Strategy extends CatchRateStrategy {
  Gen85Strategy() : super(8.5);

  @override
  bool get isArceus => true;
  @override
  bool get showFlying => true;
  @override
  bool get showHpAndStatus => false;

  @override
  List<BallOption> getAvailableBalls() => [
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

  @override
  CatchRateResult calculate(CatchRateParams params) {
    if (params.ballId == 'origin') {
      return CatchRateResult(
        catchChance: 100.0,
        critChance: 0.0,
        bonus: 1.0,
        baseRate: params.pokemon.captureRate,
      );
    }

    bool isUnnoticed = params.hisuiCatchStatus > 0;

    double hisuiModifier = 1.0;
    if (params.hisuiCatchStatus == 1) {
      hisuiModifier = 1.5;
    } else if (params.hisuiCatchStatus == 2)
      hisuiModifier = 2.0;
    else if (params.hisuiCatchStatus == 3)
      hisuiModifier = 1.25;

    double ballBonus = 1.0;
    switch (params.ballId) {
      case 'poke_hisui':
        ballBonus = 0.75;
        break;
      case 'great_hisui':
        ballBonus = 1.5;
        break;
      case 'ultra_hisui':
        ballBonus = 2.25;
        break;
      case 'heavy_hisui':
        ballBonus = isUnnoticed ? 1.25 : 1.0;
        break;
      case 'leaden':
        ballBonus = isUnnoticed ? 2.0 : 1.75;
        break;
      case 'gigaton':
        ballBonus = isUnnoticed ? 2.75 : 2.5;
        break;
      case 'feather':
        ballBonus = params.isFlying ? 1.25 : 0.5;
        break;
      case 'wing':
        ballBonus = params.isFlying ? 2.0 : 1.25;
        break;
      case 'jet':
        ballBonus = params.isFlying ? 2.75 : 2.0;
        break;
    }

    double x = params.pokemon.captureRate * ballBonus * hisuiModifier;

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
}

class Gen95Strategy extends CatchRateStrategy {
  Gen95Strategy() : super(9.5);

  @override
  bool get showPowerOptions => true;
  @override
  bool get showHpAndStatus => true;
  @override
  bool get showTargetShiny => true;
  @override
  bool get showBackstrike => true;
  @override
  bool get showAlpha => true;
  @override
  bool get showCatchWindow => true;
  @override
  bool get showZaRank => true;
  @override
  bool get showDonutPenalty => true;
  @override
  bool get showEnemyLevel => true;
  @override
  bool get showUnnoticed => true;

  @override
  List<BallOption> getAvailableBalls() => [
    BallOption('poke', Translator.get('ball_poke_ball'), 'poke-ball'),
    BallOption('great', Translator.get('ball_great_ball'), 'great-ball'),
    BallOption('ultra', Translator.get('ball_ultra_ball'), 'ultra-ball'),
    BallOption('master', Translator.get('ball_master_ball'), 'master-ball'),
    BallOption('level', Translator.get('ball_level_ball'), 'level-ball'),
    BallOption('love', Translator.get('ball_love_ball'), 'love-ball'),
    BallOption('quick', Translator.get('ball_quick_ball'), 'quick-ball'),
    BallOption('timer', Translator.get('ball_timer_ball'), 'timer-ball'),
  ];

  @override
  List<DropdownMenuItem<double>> getPowerOptions() => [
    DropdownMenuItem(
      value: 1.0,
      child: Text(Translator.get('calc_power_none')),
    ),
    const DropdownMenuItem(value: 1.1, child: Text('Catching Power Lv. 1')),
    const DropdownMenuItem(value: 1.25, child: Text('Catching Power Lv. 2')),
    const DropdownMenuItem(value: 2.0, child: Text('Catching Power Lv. 3')),
  ];

  @override
  CatchRateResult calculate(CatchRateParams params) {
    if (params.ballId == 'master') {
      return CatchRateResult(
        catchChance: 100.0,
        critChance: 0.0,
        bonus: 1.0,
        baseRate: params.pokemon.captureRate,
      );
    }

    int modifiedRate = params.pokemon.captureRate;
    if (params.pokemon.id == 374) modifiedRate = 20;
    if (modifiedRate == 255) modifiedRate = 765;

    double ballBonus = 1.0;
    switch (params.ballId) {
      case 'great':
        ballBonus = 1.5;
        break;
      case 'ultra':
        ballBonus = 2.0;
        break;
      case 'quick':
        if (params.turnCount == 1) ballBonus = 5.0;
        break;
      case 'timer':
        ballBonus = min(4.0, 1.0 + (params.turnCount * (1229.0 / 4096.0)));
        break;
      case 'level':
        if ((params.ownLevel ~/ 4) > params.enemyLevel) {
          ballBonus = 8.0;
        } else if ((params.ownLevel ~/ 2) > params.enemyLevel)
          ballBonus = 4.0;
        else if (params.ownLevel > params.enemyLevel)
          ballBonus = 2.0;
        break;
      case 'love':
        ballBonus = params.isLoveConditionMet ? 8.0 : 1.0;
        break;
    }

    double statusBonus = 1.0;
    if (params.isCatchWindow) {
      statusBonus = params.isAlpha ? 3.0 : 1.2;
    } else {
      if (params.statusType == 2) {
        statusBonus = 1.5;
      } else if (params.statusType == 1)
        statusBonus = 1.2;
    }

    double shinyBonus = params.isTargetShiny ? 3.0 : 1.0;
    double behaviorBonus = params.isUnnoticed ? 1.5 : 1.0;
    double backstrikeBonus =
        (params.isBackstrike && !params.isCatchWindow && params.isUnnoticed)
        ? 2.0
        : 1.0;
    double alphaPenalty = params.isAlpha ? 0.5 : 1.0;

    int rankPoke = ((params.enemyLevel - 1) ~/ 10) + 1;
    if (params.isAlpha) rankPoke += 4;
    if (rankPoke > 10) rankPoke = 10;

    int rank = params.zaRank - rankPoke + 1;
    if (rank > 0) rank = 0;
    if (rank < -5) rank = -5;

    double rankPenalty = 1.0;
    if (rank == -1) {
      rankPenalty = 0.7;
    } else if (rank == -2)
      rankPenalty = 0.5;
    else if (rank == -3)
      rankPenalty = 0.3;
    else if (rank <= -4)
      rankPenalty = 0.1;

    double plushBonus = 1.0;
    if (params.plushLevel == 1) {
      plushBonus = 1.1;
    } else if (params.plushLevel == 2)
      plushBonus = 1.2;
    else if (params.plushLevel == 3)
      plushBonus = 1.35;

    double donutPenaltyVal = 1.0;
    if (params.donutPenalty == 1) {
      donutPenaltyVal = 0.9;
    } else if (params.donutPenalty == 2)
      donutPenaltyVal = 0.3;

    double hpFactor = (3.0 * 100.0 - 2.0 * params.hpPercent) / (3.0 * 100.0);

    double a =
        hpFactor *
        modifiedRate *
        ballBonus *
        statusBonus *
        shinyBonus *
        behaviorBonus *
        backstrikeBonus *
        alphaPenalty *
        rankPenalty *
        plushBonus *
        donutPenaltyVal;
    double aCapped = min(255.0, a);

    double c =
        (1.0 -
            pow(
              (65536.0 - pow(aCapped + 1.0, 2)).floorToDouble() / 65536.0,
              3,
            )) *
        100.0;

    double powerVal = 0.0;
    if (params.powerBonus == 1.1) powerVal = 10.0;
    if (params.powerBonus == 1.25) powerVal = 20.0;
    if (params.powerBonus == 2.0) powerVal = 30.0;

    double donutPowerBonus = 0.0;
    if (powerVal > 0) {
      double d = (100.0 - c) / 100.0;
      double e = c + powerVal;
      double fVal = (100.0 - e) / 100.0;
      donutPowerBonus =
          (pow(fVal, 1.0 / 3.0) * -65535.0).floorToDouble() -
          (pow(d, 1.0 / 3.0) * -65535.0).floorToDouble();
    }

    double inner = (65536.0 - pow(aCapped + 1.0, 2)).floorToDouble();
    double b = 65535.0 - (inner - donutPowerBonus);

    double shakeChance = min(1.0, max(0.0, b / 65535.0));
    double catchChance = (1.0 - pow(1.0 - shakeChance, 3)) * 100.0;

    if (aCapped >= 255.0) catchChance = 100.0;

    return CatchRateResult(
      catchChance: catchChance.clamp(0.0, 100.0),
      critChance: 0.0,
      bonus: ballBonus,
      baseRate: modifiedRate,
    );
  }
}
