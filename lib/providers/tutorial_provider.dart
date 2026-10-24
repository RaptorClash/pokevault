import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_step.dart';

/// Manages the state of onboarding hints, feature guides, and tutorials.
///
/// Persists completion flags and multi-step progress in [SharedPreferences].
class TutorialProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  /// Current major tutorial version (v1.6 is version 2).
  static const int currentTutorialVersion = 2;

  bool _isDeltaTourActive = false;

  /// Whether the v1.6 delta walkthrough is currently in progress.
  bool get isDeltaTourActive => _isDeltaTourActive;

  /// Creates a [TutorialProvider] with the given [SharedPreferences] instance.
  TutorialProvider(this._prefs) {
    _initVersionTracking();
  }

  void _initVersionTracking() {
    if (!_prefs.containsKey('completed_tutorial_version')) {
      if (_prefs.getBool('home_screen') == true) {
        _prefs.setInt('completed_tutorial_version', 1);
      } else {
        _prefs.setInt('completed_tutorial_version', 0);
        _prefs.setBool('v1_6_update_announced', true);
      }
    }
  }

  /// Retrieves the current step number reached in a multi-step feature walkthrough.
  int getFeatureStep(String id) => _prefs.getInt(id) ?? 0;

  /// Checks whether a specific feature guide has already been shown or dismissed.
  bool hasSeenFeature(String id) {
    if (_prefs.getBool('skip_all_tutorials') == true) {
      return true;
    }
    return _prefs.getBool(id) ?? false;
  }

  /// Highest completed tutorial version (defaults to 1 for existing users who saw home_screen).
  int get completedTutorialVersion =>
      _prefs.getInt('completed_tutorial_version') ?? 0;

  /// Whether the v1.6 update announcement has already been shown or dismissed.
  bool get isV16UpdateAnnounced =>
      _prefs.getBool('v1_6_update_announced') ?? false;

  /// Whether the v1.6 update announcement dialog should be displayed.
  bool get shouldShowV16UpdatePrompt {
    if (_prefs.getBool('skip_all_tutorials') == true) {
      return false;
    }
    if (isV16UpdateAnnounced) {
      return false;
    }
    return completedTutorialVersion >= 1;
  }

  /// Dismisses the v1.6 update prompt without starting the tour.
  Future<void> dismissV16UpdatePrompt() async {
    await _prefs.setBool('v1_6_update_announced', true);
    notifyListeners();
  }

  /// Marks the v1.6 tutorial as completely finished.
  Future<void> completeV16Tutorial() async {
    await _prefs.setInt('completed_tutorial_version', currentTutorialVersion);
    await _prefs.setBool('v1_6_update_announced', true);
    _isDeltaTourActive = false;
    notifyListeners();
  }

  /// Starts the v1.6 Delta Walkthrough by resetting v1.6 keys and activating delta tour.
  Future<void> startV16DeltaTour() async {
    await dismissV16UpdatePrompt();

    // Reset v1.6 chapter keys for guided experience
    final v16Keys = [
      'box_management',
      'box_drag_shift',
      'shiny_hunt_hub',
      'shiny_hunt_counter',
      'dex_statistics',
      'completion_card',
      'gender_differences',
      'special_obtainable',
      'route_tracker',
      'controls_guide',
      'dex_appbar_tools',
    ];

    for (final key in v16Keys) {
      await _prefs.remove(key);
    }

    _isDeltaTourActive = true;
    notifyListeners();
  }

  /// Ends the delta tour mode.
  void endDeltaTour() {
    _isDeltaTourActive = false;
    notifyListeners();
  }

  /// Checks whether all required feature keys for a given chapter are seen.
  bool isChapterCompleted(String chapterId) {
    if (_prefs.getBool('skip_all_tutorials') == true) return true;

    final chapter = TutorialChapters.all.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => TutorialChapter(
        id: chapterId,
        titleKey: '',
        descKey: '',
        icon: Icons.help_outline,
        requiredFeatureKeys: [chapterId],
        stepCount: 1,
      ),
    );

    for (final key in chapter.requiredFeatureKeys) {
      if (!hasSeenFeature(key)) {
        return false;
      }
    }
    return true;
  }

  /// Resets all feature keys associated with a chapter.
  Future<void> resetChapter(String chapterId) async {
    final chapter = TutorialChapters.all.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => TutorialChapter(
        id: chapterId,
        titleKey: '',
        descKey: '',
        icon: Icons.help_outline,
        requiredFeatureKeys: [chapterId],
        stepCount: 1,
      ),
    );

    for (final key in chapter.requiredFeatureKeys) {
      await _prefs.remove(key);
    }
    notifyListeners();
  }

  /// Marks all feature keys of a chapter as seen.
  Future<void> markChapterSeen(String chapterId) async {
    final chapter = TutorialChapters.all.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => TutorialChapter(
        id: chapterId,
        titleKey: '',
        descKey: '',
        icon: Icons.help_outline,
        requiredFeatureKeys: [chapterId],
        stepCount: 1,
      ),
    );

    for (final key in chapter.requiredFeatureKeys) {
      await _prefs.setBool(key, true);
    }
    notifyListeners();
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
    await _prefs.setBool('v1_6_update_announced', true);
    await _prefs.setInt('completed_tutorial_version', 0);

    _isDeltaTourActive = false;
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
    _isDeltaTourActive = false;
    notifyListeners();
  }
}
