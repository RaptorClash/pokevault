import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';

class ThemeProvider extends ChangeNotifier {
  static const Color defaultLightPrimary = Color(0xFFE53935);
  static const Color defaultDarkPrimary = Color(0xFF9575CD);
  static const Color defaultLightBg = Color(0xFFF7F7F8);
  static const Color defaultDarkBg = Color(0xFF121212);

  Color _lightPrimaryColor = defaultLightPrimary;
  Color _darkPrimaryColor = defaultDarkPrimary;
  Color _lightBackgroundColor = defaultLightBg;
  Color _darkBackgroundColor = defaultDarkBg;

  List<Color> _customColors = [];

  ThemeProvider() {
    _loadPreferences();
  }

  Color get lightPrimaryColor => _lightPrimaryColor;
  Color get darkPrimaryColor => _darkPrimaryColor;
  Color get lightBackgroundColor => _lightBackgroundColor;
  Color get darkBackgroundColor => _darkBackgroundColor;
  List<Color> get customColors => _customColors;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey('lightPrimary')) {
        _lightPrimaryColor = Color(prefs.getInt('lightPrimary')!);
      }
      if (prefs.containsKey('darkPrimary')) {
        _darkPrimaryColor = Color(prefs.getInt('darkPrimary')!);
      }
      if (prefs.containsKey('lightBg')) {
        _lightBackgroundColor = Color(prefs.getInt('lightBg')!);
      }
      if (prefs.containsKey('darkBg')) {
        _darkBackgroundColor = Color(prefs.getInt('darkBg')!);
      }
      if (prefs.containsKey('customColors')) {
        List<String> colorsString = prefs.getStringList('customColors')!;
        _customColors = colorsString.map((c) => Color(int.parse(c))).toList();
      }

      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_load_prefs')} $e");
    }
  }

  Future<void> updateThemeColor(Color newColor, bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isDarkMode) {
        _darkPrimaryColor = newColor;
        await prefs.setInt('darkPrimary', newColor.value);
      } else {
        _lightPrimaryColor = newColor;
        await prefs.setInt('lightPrimary', newColor.value);
      }
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_update_theme_color')} $e",
      );
    }
  }

  Future<void> updateBackgroundColor(Color newColor, bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isDarkMode) {
        _darkBackgroundColor = newColor;
        await prefs.setInt('darkBg', newColor.value);
      } else {
        _lightBackgroundColor = newColor;
        await prefs.setInt('lightBg', newColor.value);
      }
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_update_background_color')} $e",
      );
    }
  }

  Future<void> addCustomColor(Color color) async {
    try {
      if (!_customColors.contains(color)) {
        _customColors.add(color);
        final prefs = await SharedPreferences.getInstance();
        List<String> colorsString = _customColors
            .map((c) => c.value.toString())
            .toList();
        await prefs.setStringList('customColors', colorsString);
        notifyListeners();
      }
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_add_custom_color')} $e",
      );
    }
  }

  Future<void> resetToDefault() async {
    try {
      _lightPrimaryColor = defaultLightPrimary;
      _darkPrimaryColor = defaultDarkPrimary;
      _lightBackgroundColor = defaultLightBg;
      _darkBackgroundColor = defaultDarkBg;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lightPrimary');
      await prefs.remove('darkPrimary');
      await prefs.remove('lightBg');
      await prefs.remove('darkBg');

      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_reset_to_default')} $e");
    }
  }
}