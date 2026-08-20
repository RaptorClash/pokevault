import 'dart:math';
import '../../data/catch_data.dart';
import '../../l10n/app_translations.dart';
import 'models.dart';
import 'strategy_base.dart';

class Gen1Strategy extends CatchRateStrategy {
  Gen1Strategy() : super(1.0);

  @override
  List<BallOption> getAvailableBalls() => [
    BallOption('poke', Translator.get('ball_poke_ball'), 'poke-ball'),
    BallOption('great', Translator.get('ball_great_ball'), 'great-ball'),
    BallOption('ultra', Translator.get('ball_ultra_ball'), 'ultra-ball'),
    BallOption('master', Translator.get('ball_master_ball'), 'master-ball'),
    BallOption('safari', Translator.get('ball_safari_ball'), 'safari-ball'),
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

    String? glitchWarning;
    if (params.ballId == 'great')
      glitchWarning = Translator.get('glitch_gen1_great');

    int statusS = params.statusType == 2
        ? 25
        : (params.statusType == 1 ? 12 : 0);
    double ballFactor = params.ballId == 'poke'
        ? 256.0
        : (params.ballId == 'great' ? 201.0 : 151.0);
    double hpDivisor = params.ballId == 'great' ? 8.0 : 12.0;

    double hpFactor = min(
      255.0,
      (100.0 / max(1.0, params.hpPercent)) * (1020.0 / hpDivisor),
    );
    double p1 = statusS / ballFactor;
    double p2 =
        min(params.pokemon.captureRate + 1.0, ballFactor - statusS) /
        ballFactor;
    double p3 = (hpFactor + 1) / 256.0;

    double catchChance = (p1 + p2 * p3) * 100;

    return CatchRateResult(
      catchChance: catchChance.clamp(0.0, 100.0),
      critChance: 0.0,
      glitchText: glitchWarning,
      bonus: 1.0,
      baseRate: params.pokemon.captureRate,
    );
  }
}

class Gen2Strategy extends CatchRateStrategy {
  Gen2Strategy() : super(2.0);

  @override
  bool get showEnemyLevel => true;
  @override
  bool get showOwnLevel => true;
  @override
  bool get showFishing => true;
  @override
  bool get showLoveCondition => true;

  @override
  List<BallOption> getAvailableBalls() => [
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

    String? glitchWarning;
    if (params.ballId == 'love')
      glitchWarning = Translator.get('glitch_gen2_love');
    if (params.ballId == 'moon')
      glitchWarning = Translator.get('glitch_gen2_moon');
    if (params.ballId == 'fast')
      glitchWarning = Translator.get('glitch_gen2_fast');

    double ballBonus = 1.0;
    int baseRate = params.pokemon.captureRate;
    int modifiedBaseRate = baseRate;

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
        if ([81, 82, 88, 89, 114].contains(params.pokemon.id)) ballBonus = 4.0;
        break;
      case 'love':
        ballBonus = params.isLoveConditionMet ? 8.0 : 1.0;
        break;
      case 'moon':
        ballBonus = 1.0;
        break;
      case 'lure':
        if (params.isFishing) ballBonus = 3.0;
        break;
      case 'level':
        if (params.ownLevel > params.enemyLevel * 4)
          ballBonus = 8.0;
        else if (params.ownLevel > params.enemyLevel * 2)
          ballBonus = 4.0;
        else if (params.ownLevel > params.enemyLevel)
          ballBonus = 2.0;
        break;
      case 'heavy':
        double weight = catchDataDatabase[params.pokemon.id]?['weight'] ?? 50.0;
        int modifier = 0;
        if (weight < 102.4)
          modifier = -20;
        else if (weight < 204.8)
          modifier = 0;
        else if (weight < 307.2)
          modifier = 20;
        else if (weight < 409.6)
          modifier = 30;
        else
          modifier = 40;

        modifiedBaseRate = max(1, baseRate + modifier);
        break;
    }

    int finalModifiedRate = max(
      1,
      min(255, (modifiedBaseRate * ballBonus).floor()),
    );

    int sBonus = params.statusType == 2 ? 10 : 0;
    double x =
        max(
          1.0,
          ((300.0 - 2.0 * params.hpPercent) * finalModifiedRate) / 300.0,
        ) +
        sBonus;
    double catchChance = ((x + 1) / 256.0) * 100;

    return CatchRateResult(
      catchChance: catchChance.clamp(0.0, 100.0),
      critChance: 0.0,
      glitchText: glitchWarning,
      bonus: ballBonus,
      baseRate: finalModifiedRate,
    );
  }
}
