import 'package:flutter/material.dart';

class PokemonInfoKeys {
  final GlobalKey appBarKey = GlobalKey();

  final Map<String, GlobalKey> shinyToggle = {};
  final Map<String, GlobalKey> basicInfo = {};
  final Map<String, GlobalKey> caughtStatus = {};
  final Map<String, GlobalKey> shinyStatus = {};
  final Map<String, GlobalKey> breeding = {};
  final Map<String, GlobalKey> catchCalc = {};
  final Map<String, GlobalKey> matchingBalls = {};
  final Map<String, GlobalKey> encounters = {};
  final Map<String, GlobalKey> shinyGuide = {};
  final Map<String, GlobalKey> ignoreBtn = {};

  GlobalKey get(Map<String, GlobalKey> map, String id) {
    return map.putIfAbsent(id, () => GlobalKey());
  }
}
