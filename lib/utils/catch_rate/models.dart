import '../../models/pokemon.dart';

class CatchRateResult {
  final double catchChance;
  final double critChance;
  final String? glitchText;
  final double bonus;
  final int baseRate;

  CatchRateResult({
    required this.catchChance,
    required this.critChance,
    this.glitchText,
    required this.bonus,
    required this.baseRate,
  });
}

class CatchRateParams {
  final Pokemon pokemon;
  final String ballId;
  final double hpPercent;
  final int statusType;
  final int turnCount;
  final int enemyLevel;
  final int ownLevel;
  final bool isFishing;
  final bool isSurfingOrDiving;
  final bool isNightOrCave;
  final bool isLoveConditionMet;
  final bool isAlreadyCaught;
  final bool isDarkGrass;
  final int hisuiCatchStatus;
  final bool isFlying;
  final double powerBonus;
  final double dexMultiplier;
  final bool hasCatchingCharm;

  CatchRateParams({
    required this.pokemon,
    required this.ballId,
    required this.hpPercent,
    required this.statusType,
    required this.turnCount,
    required this.enemyLevel,
    required this.ownLevel,
    required this.isFishing,
    required this.isSurfingOrDiving,
    required this.isNightOrCave,
    required this.isLoveConditionMet,
    required this.isAlreadyCaught,
    required this.isDarkGrass,
    required this.hisuiCatchStatus,
    required this.isFlying,
    required this.powerBonus,
    required this.dexMultiplier,
    required this.hasCatchingCharm,
  });
}

class BallOption {
  final String id;
  final String nameKey;
  final String spriteId;

  BallOption(this.id, this.nameKey, this.spriteId);
}

class BallEffectResult {
  final double bonus;
  final int baseRate;
  BallEffectResult(this.bonus, this.baseRate);
}