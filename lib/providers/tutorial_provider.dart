import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  TutorialProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  int getFeatureStep(String id) => _prefs?.getInt(id) ?? 0;

  bool hasSeenFeature(String id) => _prefs?.getBool(id) ?? false;

  Future<void> markFeatureAsSeen(String id) async {
    await _prefs?.setBool(id, true);
    notifyListeners();
  }

  Future<void> resetTutorial(String id) async {
    await _prefs?.remove(id);
    notifyListeners();
  }

  Future<void> resetAllTutorials() async {
    final keys = _prefs?.getKeys() ?? {};
    for (String key in keys) {
      await _prefs?.remove(key);
    }
    notifyListeners();
  }

  Future<void> updateFatureStep(String id, int step) async {
    await _prefs?.setInt(id, step);
    notifyListeners();
  }
}
