import 'package:flutter/material.dart';

class PokemonInfoKeys {
  final GlobalKey appBarKey = GlobalKey();
  final Map<String, GlobalKey> shinyToggle = {};
  final Map<String, GlobalKey> basicInfo = {};
  final Map<String, GlobalKey> caughtStatus = {};
  final Map<String, GlobalKey> shinyStatus = {};
  final Map<String, GlobalKey> alphaToggle = {};
  final Map<String, GlobalKey> alphaStatus = {};
  final Map<String, GlobalKey> breeding = {};
  final Map<String, GlobalKey> catchCalc = {};
  final Map<String, GlobalKey> matchingBalls = {};
  final Map<String, GlobalKey> encounters = {};
  final Map<String, GlobalKey> shinyGuide = {};
  final Map<String, GlobalKey> ignoreBtn = {};
  final Map<String, GlobalKey> ribbons = {};
  final Map<String, GlobalKey> tera = {};
  final Map<String, GlobalKey> marks = {};
  final Map<String, GlobalKey> language = {};
  final Map<String, GlobalKey> genderDifferences = {};
  final Map<String, GlobalKey> specialObtainable = {};
  final Map<String, GlobalKey> shinyHuntBtn = {};

  GlobalKey get(Map<String, GlobalKey> map, String id) {
    return map.putIfAbsent(id, () => GlobalKey());
  }

  /// Prunes cached GlobalKeys for pages that have moved out of the PageView viewport window,
  /// preventing unbounded GlobalKey leakages.
  void prune(Set<String> activeIds) {
    shinyToggle.removeWhere((id, _) => !activeIds.contains(id));
    basicInfo.removeWhere((id, _) => !activeIds.contains(id));
    caughtStatus.removeWhere((id, _) => !activeIds.contains(id));
    shinyStatus.removeWhere((id, _) => !activeIds.contains(id));
    alphaToggle.removeWhere((id, _) => !activeIds.contains(id));
    alphaStatus.removeWhere((id, _) => !activeIds.contains(id));
    breeding.removeWhere((id, _) => !activeIds.contains(id));
    catchCalc.removeWhere((id, _) => !activeIds.contains(id));
    matchingBalls.removeWhere((id, _) => !activeIds.contains(id));
    encounters.removeWhere((id, _) => !activeIds.contains(id));
    shinyGuide.removeWhere((id, _) => !activeIds.contains(id));
    ignoreBtn.removeWhere((id, _) => !activeIds.contains(id));
    ribbons.removeWhere((id, _) => !activeIds.contains(id));
    tera.removeWhere((id, _) => !activeIds.contains(id));
    marks.removeWhere((id, _) => !activeIds.contains(id));
    language.removeWhere((id, _) => !activeIds.contains(id));
    genderDifferences.removeWhere((id, _) => !activeIds.contains(id));
    specialObtainable.removeWhere((id, _) => !activeIds.contains(id));
    shinyHuntBtn.removeWhere((id, _) => !activeIds.contains(id));
  }
}
