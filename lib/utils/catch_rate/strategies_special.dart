import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'strategy_base.dart';
import '../../l10n/app_translations.dart';

class Gen75Strategy extends CatchRateStrategy {
  Gen75Strategy() : super(7.5);

  @override bool get showPowerOptions => true;
  @override bool get showHpAndStatus => false;

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
    DropdownMenuItem(value: 1.0, child: Text(Translator.get('calc_power_none'))),
    DropdownMenuItem(value: 1.5, child: Row(children: [Image.network('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/razz-berry.png', width: 24, height: 24, errorBuilder: (c,e,s)=>const Icon(Icons.grass, size: 20)), const SizedBox(width: 8), Text(Translator.get('berry_razz'))])),
    DropdownMenuItem(value: 2.25, child: Row(children: [Image.network('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/silver-razz-berry.png', width: 24, height: 24, errorBuilder: (c,e,s)=>const Icon(Icons.grass, size: 20)), const SizedBox(width: 8), Text(Translator.get('berry_silver_razz'))])),
    DropdownMenuItem(value: 2.5, child: Row(children: [Image.network('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/golden-razz-berry.png', width: 24, height: 24, errorBuilder: (c,e,s)=>const Icon(Icons.grass, size: 20)), const SizedBox(width: 8), Text(Translator.get('berry_golden_razz'))])),
  ];

  @override
  CatchRateResult calculate(CatchRateParams params) {
    if (params.ballId == 'master') {
      return CatchRateResult(catchChance: 100.0, critChance: 0.0, bonus: 1.0, baseRate: params.pokemon.captureRate);
    }
    
    double ballBonus = 1.0;
    if (params.ballId == 'great') ballBonus = 1.5;
    if (params.ballId == 'ultra') ballBonus = 2.0;

    double x = (params.pokemon.captureRate * ballBonus * params.powerBonus) / 3.0;
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

  @override bool get isArceus => true;
  @override bool get showFlying => true;
  @override bool get showHpAndStatus => false;

  @override
  List<BallOption> getAvailableBalls() => [
    BallOption('poke_hisui', Translator.get('ball_poke_hisui'), 'poke-ball-hisui'),
    BallOption('great_hisui', Translator.get('ball_great_hisui'), 'great-ball-hisui'),
    BallOption('ultra_hisui', Translator.get('ball_ultra_hisui'), 'ultra-ball-hisui'),
    BallOption('heavy_hisui', Translator.get('ball_heavy_hisui'), 'heavy-ball-hisui'),
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
      return CatchRateResult(catchChance: 100.0, critChance: 0.0, bonus: 1.0, baseRate: params.pokemon.captureRate);
    }

    bool isUnnoticed = params.hisuiCatchStatus > 0;
    double hisuiModifier = 1.0;
    if (params.hisuiCatchStatus == 1) hisuiModifier = 1.5;
    else if (params.hisuiCatchStatus == 2) hisuiModifier = 2.0;
    else if (params.hisuiCatchStatus == 3) hisuiModifier = 1.25;

    double ballBonus = 1.0;
    switch (params.ballId) {
      case 'poke_hisui': ballBonus = 0.75; break;
      case 'great_hisui': ballBonus = 1.5; break;
      case 'ultra_hisui': ballBonus = 2.25; break;
      case 'heavy_hisui': ballBonus = isUnnoticed ? 1.25 : 1.0; break;
      case 'leaden': ballBonus = isUnnoticed ? 2.0 : 1.75; break;
      case 'gigaton': ballBonus = isUnnoticed ? 2.75 : 2.5; break;
      case 'feather': ballBonus = params.isFlying ? 1.25 : 0.5; break;
      case 'wing': ballBonus = params.isFlying ? 2.0 : 1.25; break;
      case 'jet': ballBonus = params.isFlying ? 2.75 : 2.0; break;
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