import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  TutorialProvider(this._prefs);

  int getFeatureStep(String id) => _prefs.getInt(id) ?? 0;

  bool hasSeenFeature(String id) {
    if (_prefs.getBool('skip_all_tutorials') == true) {
      return true;
    }
    return _prefs.getBool(id) ?? false;
  }

  Future<void> markFeatureAsSeen(String id) async {
    await _prefs.setBool(id, true);
    notifyListeners();
  }

  Future<void> resetTutorial(String id) async {
    await _prefs.remove(id);
    notifyListeners();
  }

  Future<void> resetAllTutorials() async {
    final allKeys = _prefs.getKeys();

    final systemKeys = [
      'migrated_to_sqlite_v2',
      'drive_access_token',
      'drive_refresh_token',
      'drive_expiry',
      'themeMode',
      'theme_mode',
      'language',
      'current_language',
      'google_client_id',
      'google_client_secret',
      'saved_dexes',
      'saved_folders',
      'saved_structure',
    ];

    for (String key in allKeys) {
      if (!systemKeys.contains(key)) {
        await _prefs.remove(
          key,
        );
      }
    }

    await _prefs.setBool('migrated_to_sqlite_v2', true);

    notifyListeners();
  }

  Future<void> updateFatureStep(String id, int step) async {
    await _prefs.setInt(id, step);
    notifyListeners();
  }

  Future<void> skipAllTutorials() async {
    await _prefs.setBool('skip_all_tutorials', true);
    notifyListeners();
  }
}
