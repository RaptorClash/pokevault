import 'package:flutter/material.dart';

import 'models.dart';
import 'strategies_classic.dart';
import 'strategies_modern.dart';
import 'strategies_special.dart';
import '../../l10n/app_translations.dart';

abstract class CatchRateStrategy {
  final double gen;

  CatchRateStrategy(this.gen);

  CatchRateResult calculate(CatchRateParams params);
  List<BallOption> getAvailableBalls();

  List<DropdownMenuItem<double>> getPowerOptions() => [
    DropdownMenuItem(
      value: 1.0,
      child: Text(Translator.get('calc_power_none')),
    ),
  ];

  bool get showPowerOptions => false;
  bool get showEnemyLevel => false;
  bool get showOwnLevel => false;
  bool get showTurnCount => false;
  bool get showFishing => false;
  bool get showSurfing => false;
  bool get showNightEncounter => false;
  bool get showLoveCondition => false;
  bool get showRepeatCondition => false;
  bool get showDarkGrass => false;
  bool get isArceus => false;
  bool get showFlying => false;
  bool get showHpAndStatus => true;
  bool get showCritSettings => false;

  bool get showMaxRaid => false;
  bool get showBackstrike => false;
  bool get showCatchWindow => false;
  bool get showAlpha => false;
  bool get showZaRank => false;
  bool get showPlushLevel => false;
  bool get showDonutPenalty => false;
  bool get showMissingBadges => false;
  bool get showTargetShiny => false;
  bool get showUnnoticed => false;
}

class CatchRateStrategyFactory {
  static CatchRateStrategy getStrategy(double gen) {
    if (gen == 1.0) return Gen1Strategy();
    if (gen == 2.0) return Gen2Strategy();
    if (gen == 3.0 || gen == 4.0) return Gen34Strategy(gen);
    if (gen == 5.0) return Gen5Strategy();
    if (gen == 6.0 || gen == 7.0) return Gen67Strategy(gen);
    if (gen == 7.5) return Gen75Strategy();
    if (gen == 8.0) return Gen8Strategy();
    if (gen == 8.5) return Gen85Strategy();
    if (gen == 9.0) return Gen9Strategy();
    if (gen == 9.5) return Gen95Strategy();

    return Gen9Strategy();
  }
}
