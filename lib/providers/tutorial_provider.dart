import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the state of onboarding hints, feature guides, and tutorials.
///
/// Persists completion flags and multi-step progress in [SharedPreferences].
class TutorialProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  /// Creates a [TutorialProvider] with the given [SharedPreferences] instance.
  TutorialProvider(this._prefs);

  /// Retrieves the current step number reached in a multi-step feature walkthrough.
  int getFeatureStep(String id) => _prefs.getInt(id) ?? 0;

  /// Checks whether a specific feature guide has already been shown or dismissed.
  bool hasSeenFeature(String id) {
    if (_prefs.getBool('skip_all_tutorials') == true) {
      return true;
    }
    return _prefs.getBool(id) ?? false;
  }

  /// Marks a specific feature walkthrough or tooltip as seen.
  Future<void> markFeatureAsSeen(String id) async {
    await _prefs.setBool(id, true);
    notifyListeners();
  }

  /// Resets the seen state for a specific tutorial feature.
  Future<void> resetTutorial(String id) async {
    await _prefs.remove(id);
    notifyListeners();
  }

  /// Resets all tutorial and walkthrough flags without clearing user preferences.
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
        await _prefs.remove(key);
      }
    }

    await _prefs.setBool('migrated_to_sqlite_v2', true);

    notifyListeners();
  }

  /// Updates the progress step index of an active multi-step walkthrough.
  Future<void> updateFatureStep(String id, int step) async {
    await _prefs.setInt(id, step);
    notifyListeners();
  }

  /// Globally disables all in-app tutorials and tooltips.
  Future<void> skipAllTutorials() async {
    await _prefs.setBool('skip_all_tutorials', true);
    notifyListeners();
  }
}
