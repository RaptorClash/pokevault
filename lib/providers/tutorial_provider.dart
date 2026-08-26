import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/notification_helper.dart';
import '../l10n/app_translations.dart';

class TutorialProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  TutorialProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error')} TutorialProvider init: $e",
      );
    }
  }

  bool hasSeenFeature(String featureId) {
    if (!_isInitialized) return false;
    return _prefs.getBool('tutorial_seen_$featureId') ?? false;
  }

  Future<void> markFeatureAsSeen(String featureId) async {
    try {
      await _prefs.setBool('tutorial_seen_$featureId', true);
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error')} $e");
    }
  }

  Future<void> resetTutorial(String featureId) async {
    try {
      await _prefs.remove('tutorial_seen_$featureId');
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error')} $e");
    }
  }

  Future<void> resetAllTutorials() async {
    try {
      final keys = _prefs.getKeys().where(
        (k) => k.startsWith('tutorial_seen_'),
      );
      for (var key in keys) {
        await _prefs.remove(key);
      }
      notifyListeners();
      NotificationHelper.showSuccess(
        Translator.get('tutorial_replay_all_success'),
      );
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error')} $e");
    }
  }

  int getFeatureStep(String featureId) {
    return _prefs.getInt('tutorial_step_$featureId') ?? 0;
  }

  Future<void> updateFatureStep(String featureId, int step) async {
    await _prefs.setInt('tutorial_step_$featureId', step);
    notifyListeners();
  }
}
