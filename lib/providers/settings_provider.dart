import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String currentLanguage = 'de';

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    currentLanguage = prefs.getString('language') ?? 'de';
    Translator.currentLanguage = currentLanguage;

    String tm = 'system';
    try {
      tm = prefs.getString('themeMode') ?? 'system';
    } catch (_) {
      int oldTheme = prefs.getInt('themeMode') ?? 0;
      if (oldTheme == 1)
        tm = 'light';
      else if (oldTheme == 2)
        tm = 'dark';
      await prefs.setString('themeMode', tm);
    }

    if (tm == 'light') {
      themeMode = ThemeMode.light;
    } else if (tm == 'dark') {
      themeMode = ThemeMode.dark;
    }

    notifyListeners();
  }

  void setLanguage(String lang) async {
    currentLanguage = lang;
    Translator.currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  void toggleTheme() async {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }
}
