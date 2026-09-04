import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';
import '../services/google_drive_sync_service.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String currentLanguage = 'de';

  String _googleClientId = '';
  bool _autoSyncEnabled = false;

  String get googleClientId => _googleClientId;
  bool get autoSyncEnabled => _autoSyncEnabled;
  String _googleClientSecret = '';
  String get googleClientSecret => _googleClientSecret;

  Future<void> setGoogleClientId(String id) async {
    _googleClientId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('googleClientId', id);
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSyncEnabled', enabled);
  }

  Future<void> setGoogleClientSecret(String secret) async {
    _googleClientSecret = secret;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('googleClientSecret', secret);
  }

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    _googleClientId = prefs.getString('googleClientId') ?? '';
    _autoSyncEnabled = prefs.getBool('autoSyncEnabled') ?? false;
    _googleClientSecret = prefs.getString('googleClientSecret') ?? '';

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

    if (_googleClientId.isNotEmpty && _googleClientSecret.isNotEmpty) {
      bool restored = await GoogleDriveSyncService.instance.restoreSignIn(
        _googleClientId,
        _googleClientSecret,
      );
      if (restored) {
        notifyListeners();
      }
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
