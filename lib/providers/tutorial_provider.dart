import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_step.dart';

/// Manages the state of onboarding hints, feature guides, and tutorials.
///
/// Persists completion flags and multi-step progress in [SharedPreferences].
class TutorialProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  /// Current major tutorial version (v1.6 = 2, Scanner Update = 3).
  static const int currentTutorialVersion = 3;

  bool _isDeltaTourActive = false;
  bool _isScannerDeltaTourActive = false;

  /// Whether the v1.6 delta walkthrough is currently in progress.
  bool get isDeltaTourActive => _isDeltaTourActive;

  /// Whether the Scanner delta walkthrough is currently in progress.
  bool get isScannerDeltaTourActive => _isScannerDeltaTourActive;

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
        _prefs.setBool('scanner_update_announced', true);
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

  /// Whether the Scanner update announcement has already been shown or dismissed.
  bool get isScannerUpdateAnnounced =>
      _prefs.getBool('scanner_update_announced') ?? false;

  /// Whether the Scanner update announcement dialog should be displayed.
  bool get shouldShowScannerUpdatePrompt {
    if (_prefs.getBool('skip_all_tutorials') == true) {
      return false;
    }
    if (isScannerUpdateAnnounced || shouldShowV16UpdatePrompt) {
      return false;
    }
    return completedTutorialVersion >= 1 &&
        completedTutorialVersion < currentTutorialVersion;
  }

  /// Dismisses the v1.6 update prompt without starting the tour.
  Future<void> dismissV16UpdatePrompt() async {
    await _prefs.setBool('v1_6_update_announced', true);
    notifyListeners();
  }

  /// Dismisses the Scanner update prompt without starting the tour.
  Future<void> dismissScannerUpdatePrompt() async {
    await _prefs.setBool('scanner_update_announced', true);
    notifyListeners();
  }

  /// Marks the v1.6 tutorial as completely finished.
  Future<void> completeV16Tutorial() async {
    await _prefs.setInt('completed_tutorial_version', 2);
    await _prefs.setBool('v1_6_update_announced', true);
    _isDeltaTourActive = false;
    notifyListeners();
  }

  /// Marks the Scanner tutorial (v3) as completely finished.
  Future<void> completeScannerTutorial() async {
    await _prefs.setInt('completed_tutorial_version', currentTutorialVersion);
    await _prefs.setBool('v1_6_update_announced', true);
    await _prefs.setBool('scanner_update_announced', true);
    _isScannerDeltaTourActive = false;
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

  /// Starts the v1.7 Delta Walkthrough (Scanner + Multi-Hunt Dashboard & Auto-Counter)
  /// by resetting all v1.7 tour and delta spotlight keys.
  Future<void> startV17DeltaTour() async {
    await dismissScannerUpdatePrompt();
    await _prefs.remove('skip_all_tutorials');
    const v17Keys = [
      'mobile_scanner_tour',
      'desktop_scanner_tour',
      'shiny_hunt_hub_v17_delta',
      'shiny_hunt_counter_v17_delta',
      'multi_hunt_dashboard',
      'shiny_auto_counter_setup',
      'shiny_auto_counter_bar',
    ];
    for (final key in v17Keys) {
      await _prefs.remove(key);
    }
    _isScannerDeltaTourActive = true;
    notifyListeners();
  }

  /// Starts the Scanner / v1.7 Delta Walkthrough (delegates to [startV17DeltaTour]).
  Future<void> startScannerDeltaTour() => startV17DeltaTour();

  /// Resets all live tutorial flags for [chapterId] (including companion keys
  /// and global skip flag) so the user can replay the real interactive Rotom tour.
  Future<void> prepareChapterForLiveReplay(String chapterId) async {
    await _prefs.remove('skip_all_tutorials');

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

    const companionKeys = <String, List<String>>{
      'module_home': [
        'home_screen',
        'open_dex',
        'home_organize_part1',
        'home_organize_part2',
        'home_settings_intro',
        'home_bottom_sheet',
      ],
      'module_create_dex': ['create_dex_sheet'],
      'module_dex_screen': ['dex_screen', 'ignored_pokemon', 'dex_appbar_tools'],
      'module_box_management': [
        'box_management',
        'box_drag_shift',
        'box_edit_screen',
        'box_content_edit',
        'dex_appbar_tools',
      ],
      'module_shiny_hunt': [
        'shiny_hunt_hub',
        'shiny_hunt_counter',
        'create_hunt_dialog',
        'shiny_hunt_hub_v17_delta',
        'shiny_hunt_counter_v17_delta',
      ],
      'module_stats_share': ['dex_statistics', 'completion_card', 'dex_appbar_tools'],
      'module_pokemon_info': [
        'pokemon_details',
        'gender_differences',
        'special_obtainable',
      ],
      'module_route_tracker': ['route_tracker', 'dex_appbar_tools'],
      'module_controls': ['controls_guide'],
      'module_backup_sync': ['settings_screen', 'cloud_sync', 'data_backup'],
      'module_scanner_mobile': ['mobile_scanner_tour'],
      'module_scanner_desktop': ['desktop_scanner_tour'],
      'module_shiny_auto_counter': [
        'multi_hunt_dashboard',
        'shiny_auto_counter_setup',
        'shiny_auto_counter_bar',
      ],
    };

    final keysToClear = <String>{
      ...chapter.requiredFeatureKeys,
      ...?companionKeys[chapterId],
    };

    for (final key in keysToClear) {
      await _prefs.remove(key);
    }
    notifyListeners();
  }

  /// Ends the delta tour mode.
  void endDeltaTour() {
    _isDeltaTourActive = false;
    notifyListeners();
  }

  /// Ends the Scanner delta tour mode.
  void endScannerDeltaTour() {
    _isScannerDeltaTourActive = false;
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
      final isProtected = systemKeys.contains(key) || key.startsWith('pokevault_');
      if (!isProtected) {
        await _prefs.remove(key);
      }
    }

    await _prefs.setBool('migrated_to_sqlite_v2', true);
    await _prefs.setBool('v1_6_update_announced', true);
    await _prefs.setBool('scanner_update_announced', true);
    await _prefs.setInt('completed_tutorial_version', 0);

    _isDeltaTourActive = false;
    _isScannerDeltaTourActive = false;
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
    _isScannerDeltaTourActive = false;
    notifyListeners();
  }
}
