import 'package:flutter/material.dart';

import 'models.dart';
import 'strategies_classic.dart';
import 'strategies_modern.dart';
import 'strategies_special.dart';
import '../../i18n/strings.g.dart';

/// Base contract for generation-specific catch rate calculation algorithms.
///
/// Encapsulates the specific capture mathematical model, available Pokéballs,
/// modifier powers (e.g. O-Powers, Rotom Catch), and game mechanics UI toggles.
abstract class CatchRateStrategy {
  /// The Pokémon generation number this strategy models (e.g. 1.0, 7.5 for LGPE, 8.5 for PLA).
  final double gen;

  /// Creates a [CatchRateStrategy] for generation [gen].
  CatchRateStrategy(this.gen);

  /// Computes the exact catch probability and shake check chances given [params].
  CatchRateResult calculate(CatchRateParams params);

  /// Returns the set of Pokéball options legal and available in this generation.
  List<BallOption> getAvailableBalls();

  /// Dropdown options for capture power boosts (O-Power, Roto Catch, Sandwich Catching Power).
  List<DropdownMenuItem<double>> getPowerOptions() => [
    DropdownMenuItem(
      value: 1.0,
      child: Text(t.calc_power_none),
    ),
  ];

  /// Whether capture power modifiers should be exposed in the UI.
  bool get showPowerOptions => false;

  /// Whether the opposing Pokémon's level affects capture rate.
  bool get showEnemyLevel => false;

  /// Whether the player's active Pokémon's level affects capture rate (e.g. Level Ball).
  bool get showOwnLevel => false;

  /// Whether the elapsed turn count affects capture rate (e.g. Quick Ball, Timer Ball).
  bool get showTurnCount => false;

  /// Whether fishing encounters affect capture rate (e.g. Lure Ball, Net Ball).
  bool get showFishing => false;

  /// Whether surfing encounters affect capture rate (e.g. Net Ball).
  bool get showSurfing => false;

  /// Whether nighttime or dark environments affect capture rate (e.g. Dusk Ball, Moon Ball).
  bool get showNightEncounter => false;

  /// Whether opposing gender checks affect capture rate (e.g. Love Ball).
  bool get showLoveCondition => false;

  /// Whether species-already-registered checks affect capture rate (e.g. Repeat Ball).
  bool get showRepeatCondition => false;

  /// Whether dark grass encounters affect capture rate in Generation 5.
  bool get showDarkGrass => false;

  /// Whether Legends Arceus mechanics apply.
  bool get isArceus => false;

  /// Whether airborne target status affects capture mechanics.
  bool get showFlying => false;

  /// Whether HP percentage and status conditions affect capture rate.
  bool get showHpAndStatus => true;

  /// Whether critical capture settings apply.
  bool get showCritSettings => false;

  /// Whether Dynamax/Gigantamax Max Raid battle modifiers apply.
  bool get showMaxRaid => false;

  /// Whether backstrike bonus applies (Legends: Arceus).
  bool get showBackstrike => false;

  /// Whether dynamic catch window modifiers apply (Legends: Z-A).
  bool get showCatchWindow => false;

  /// Whether Alpha Pokémon catch penalties apply.
  bool get showAlpha => false;

  /// Whether Z-A rank modifiers apply.
  bool get showZaRank => false;

  /// Whether plush level modifiers apply.
  bool get showPlushLevel => false;

  /// Whether donut lure penalty modifiers apply.
  bool get showDonutPenalty => false;

  /// Whether missing gym badges penalize capture rates (Gen 8+).
  bool get showMissingBadges => false;

  /// Whether shiny targets receive distinct catch bonuses.
  bool get showTargetShiny => false;

  /// Whether sneaking up unnoticed provides capture rate bonuses.
  bool get showUnnoticed => false;
}

/// Factory that resolves the appropriate [CatchRateStrategy] for a given [gen].
class CatchRateStrategyFactory {
  /// Returns the strategy implementation matching generation [gen].
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
