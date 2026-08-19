import 'dart:math';
import '../models/pokemon.dart';
import '../data/catch_data.dart';
import '../l10n/app_translations.dart';

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

class CatchRateLogic {
  static CatchRateResult calculate({
    required Pokemon pokemon,
    required double selectedGen,
    required String selectedBallId,
    required double hpPercent,
    required int statusType,
    required int turnCount,
    required int enemyLevel,
    required int ownLevel,
    required bool isFishing,
    required bool isSurfingOrDiving,
    required bool isNightOrCave,
    required bool isLoveConditionMet,
    required bool isAlreadyCaught,
    required bool isDarkGrass,
    required int hisuiCatchStatus,
    required bool isFlying,
    required double powerBonus,
    required double dexMultiplier,
    required bool hasCatchingCharm,
  }) {
    try {
      double catchChance = 0.0;
      double critChance = 0.0;
      String? glitchWarning;
      double ballBonus = 1.0;
      int modifiedBaseRate = pokemon.captureRate;

      if (selectedBallId == 'master' ||
          selectedBallId == 'cherish' ||
          selectedBallId == 'park' ||
          selectedBallId == 'origin' ||
          (selectedBallId == 'dream' && selectedGen == 5.0)) {
        return CatchRateResult(
          catchChance: 100.0,
          critChance: 0.0,
          bonus: 1.0,
          baseRate: modifiedBaseRate,
        );
      }

      if (selectedGen == 7.5 || (selectedGen == 8.5 && hisuiCatchStatus > 0)) {
        hpPercent = 100.0;
        statusType = 0;
      }

      double weight = catchDataDatabase[pokemon.id]?['weight'] ?? 50.0;
      int speed = catchDataDatabase[pokemon.id]?['speed'] ?? 50;
      List<String> types = pokemon.forms.isNotEmpty
          ? pokemon.forms.first.types
          : [];

      if (selectedGen == 1.0 && selectedBallId == 'great') {
        glitchWarning = Translator.get('glitch_gen1_great');
      } else if (selectedGen == 2.0 && selectedBallId == 'love') {
        glitchWarning = Translator.get('glitch_gen2_love');
      } else if (selectedGen == 2.0 && selectedBallId == 'moon') {
        glitchWarning = Translator.get('glitch_gen2_moon');
      } else if (selectedGen == 2.0 && selectedBallId == 'fast') {
        glitchWarning = Translator.get('glitch_gen2_fast');
      }

      double hisuiModifier = 1.0;
      bool isUnnoticedForBall = false;
      if (selectedGen == 8.5) {
        if (hisuiCatchStatus == 1) {
          hisuiModifier = 1.5;
          isUnnoticedForBall = true;
        } else if (hisuiCatchStatus == 2) {
          hisuiModifier = 2.0;
          isUnnoticedForBall = true;
        } else if (hisuiCatchStatus == 3) {
          hisuiModifier = 1.25;
          isUnnoticedForBall = true;
        }
      }

      switch (selectedBallId) {
        case 'great':
        case 'safari':
        case 'sport':
          ballBonus = 1.5;
          break;
        case 'ultra':
          ballBonus = 2.0;
          break;
        case 'fast':
          if (selectedGen == 2.0) {
            if ([81, 82, 88, 89, 114].contains(pokemon.id)) ballBonus = 4.0;
          } else {
            if (speed >= 100) ballBonus = 4.0;
          }
          break;
        case 'love':
          if (selectedGen == 2.0) {
            ballBonus = isLoveConditionMet ? 8.0 : 1.0;
          } else {
            ballBonus = isLoveConditionMet ? 8.0 : 1.0;
          }
          break;
        case 'moon':
          if (selectedGen == 2.0) {
            ballBonus = 1.0;
          } else {
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
            ].contains(pokemon.id)) {
              ballBonus = 4.0;
            }
          }
          break;
        case 'heavy':
          int modifier = 0;
          if (selectedGen >= 7.0) {
            if (weight < 100.0)
              modifier = -20;
            else if (weight < 200.0)
              modifier = 0;
            else if (weight < 300.0)
              modifier = 20;
            else
              modifier = 30;
          } else {
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
          }
          modifiedBaseRate = max(1, modifiedBaseRate + modifier);
          ballBonus = 1.0;
          break;
        case 'lure':
          if (isFishing) {
            if (selectedGen >= 8.0)
              ballBonus = 4.0;
            else if (selectedGen == 7.0)
              ballBonus = 5.0;
            else
              ballBonus = 3.0;
          }
          break;
        case 'level':
          if (ownLevel > enemyLevel * 4)
            ballBonus = 8.0;
          else if (ownLevel > enemyLevel * 2)
            ballBonus = 4.0;
          else if (ownLevel > enemyLevel)
            ballBonus = 2.0;
          else
            ballBonus = 1.0;
          break;
        case 'net':
          if (types.contains('water') || types.contains('bug')) {
            ballBonus = (selectedGen >= 7.0) ? 3.5 : 3.0;
          }
          break;
        case 'dive':
          if (isSurfingOrDiving) ballBonus = 3.5;
          break;
        case 'nest':
          if (selectedGen >= 7.0) {
            ballBonus = max(1.0, 8.0 - (810.0 / 4096.0) * (enemyLevel - 1));
          } else if (selectedGen >= 5.0) {
            ballBonus = max(1.0, (41.0 - enemyLevel) / 10.0);
          } else {
            ballBonus = max(1.0, (40.0 - enemyLevel) / 10.0);
          }
          break;
        case 'timer':
          if (selectedGen >= 5.0) {
            ballBonus = min(4.0, 1.0 + (turnCount * (1229.0 / 4096.0)));
          } else {
            ballBonus = min(4.0, (turnCount + 10.0) / 10.0);
          }
          break;
        case 'quick':
          if (turnCount == 1) ballBonus = (selectedGen >= 5.0) ? 5.0 : 4.0;
          break;
        case 'dusk':
          if (isNightOrCave) ballBonus = (selectedGen >= 7.0) ? 3.0 : 3.5;
          break;
        case 'repeat':
          if (isAlreadyCaught) ballBonus = (selectedGen >= 7.0) ? 3.5 : 3.0;
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
          ].contains(pokemon.id)) {
            ballBonus = 5.0;
          } else {
            ballBonus = 410.0 / 4096.0;
          }
          break;
        case 'dream':
          if (selectedGen >= 8.0 && statusType == 2) ballBonus = 4.0;
          break;

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
          ballBonus = isUnnoticedForBall ? 1.25 : 1.0;
          break;
        case 'leaden':
          ballBonus = isUnnoticedForBall ? 2.0 : 1.75;
          break;
        case 'gigaton':
          ballBonus = isUnnoticedForBall ? 2.75 : 2.5;
          break;
        case 'feather':
          ballBonus = isFlying ? 1.25 : 0.5;
          break;
        case 'wing':
          ballBonus = isFlying ? 2.0 : 1.25;
          break;
        case 'jet':
          ballBonus = isFlying ? 2.75 : 2.0;
          break;
      }

      double grassModifier = 1.0;
      if (selectedGen == 5.0 && isDarkGrass) {
        if (dexMultiplier >= 2.5)
          grassModifier = 1.0;
        else if (dexMultiplier >= 2.0)
          grassModifier = 3686.0 / 4096.0;
        else if (dexMultiplier >= 1.5)
          grassModifier = 3277.0 / 4096.0;
        else if (dexMultiplier >= 1.0)
          grassModifier = 2867.0 / 4096.0;
        else if (dexMultiplier >= 0.5)
          grassModifier = 2048.0 / 4096.0;
        else
          grassModifier = 1229.0 / 4096.0;
      }

      if (selectedGen == 1.0) {
        int statusS = statusType == 2 ? 25 : (statusType == 1 ? 12 : 0);
        double ballFactor = selectedBallId == 'poke'
            ? 256.0
            : (selectedBallId == 'great' ? 201.0 : 151.0);
        double hpDivisor = selectedBallId == 'great' ? 8.0 : 12.0;
        double hpFactor = min(
          255.0,
          (100.0 / max(1.0, hpPercent)) * (1020.0 / hpDivisor),
        );

        double p1 = statusS / ballFactor;
        double p2 =
            min(modifiedBaseRate + 1.0, ballFactor - statusS) / ballFactor;
        double p3 = (hpFactor + 1) / 256.0;
        catchChance = (p1 + p2 * p3) * 100;
      } else if (selectedGen == 2.0) {
        int sBonus = statusType == 2 ? 10 : 0;
        double x =
            max(
              1.0,
              ((300.0 - 2.0 * hpPercent) * modifiedBaseRate * ballBonus) /
                  300.0,
            ) +
            sBonus;
        catchChance = ((x + 1) / 256.0) * 100;
      } else {
        double sBonus = statusType == 2 ? 2.5 : (statusType == 1 ? 1.5 : 1.0);
        if (selectedGen <= 4.0) {
          sBonus = statusType == 2 ? 2.0 : (statusType == 1 ? 1.5 : 1.0);
        }

        double x =
            (((300.0 - 2.0 * hpPercent) *
                    modifiedBaseRate *
                    ballBonus *
                    grassModifier) /
                300.0) *
            sBonus *
            powerBonus *
            hisuiModifier;

        if (selectedGen >= 8.0 && selectedGen != 8.5 && ownLevel < enemyLevel) {
          x *= (410.0 / 4096.0);
        }

        if (x >= 255.0) {
          catchChance = 100.0;
        } else {
          double y = 1048560.0 / sqrt(sqrt(16711680.0 / x));
          double chancePerShake = y / 65536.0;
          catchChance = pow(chancePerShake, 4) * 100;

          if (selectedGen >= 5.0 && selectedGen != 7.5 && selectedGen != 8.5) {
            double cc = (min(255.0, x) * dexMultiplier) / 6.0;
            if (hasCatchingCharm && selectedGen >= 8.0) {
              critChance = (1 - pow(1 - (cc / 256.0), 2)) * 100;
            } else if (hasCatchingCharm) {
              critChance = (min(256.0, cc * 2) / 256.0) * 100;
            } else {
              critChance = (cc / 256.0) * 100;
            }
            double pCrit = critChance / 100.0;
            catchChance =
                (pCrit * chancePerShake +
                    (1 - pCrit) * pow(chancePerShake, 4)) *
                100;
          }
        }
      }

      return CatchRateResult(
        catchChance: catchChance.clamp(0.0, 100.0),
        critChance: critChance.clamp(0.0, 100.0),
        glitchText: glitchWarning,
        bonus: ballBonus,
        baseRate: modifiedBaseRate,
      );
    } catch (e) {
      return CatchRateResult(
        catchChance: 0.0,
        critChance: 0.0,
        glitchText: "${Translator.get('error')} $e",
        bonus: 1.0,
        baseRate: pokemon.captureRate,
      );
    }
  }
}
