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

  GlobalKey get(Map<String, GlobalKey> map, String id) {
    return map.putIfAbsent(id, () => GlobalKey());
  }
}
