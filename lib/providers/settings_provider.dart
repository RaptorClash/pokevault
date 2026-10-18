import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_translations.dart';
import '../services/google_drive_sync_service.dart';
import 'dart:ui' as ui;

/// Provider managing persistent user preferences such as theme, language, and cloud credentials.
///
/// Persists values in [SharedPreferences] and keeps [Translator] in sync when language changes.
class SettingsProvider with ChangeNotifier {
  /// The active UI theme mode (light, dark, or system).
  ThemeMode themeMode = ThemeMode.system;

  /// The active two-letter ISO language code (`"de"` or `"en"`).
  String currentLanguage = 'en';

  String _googleClientId = '';
  bool _autoSyncEnabled = false;

  /// Google OAuth2 Client ID for Drive synchronization.
  String get googleClientId => _googleClientId;

  /// Whether automated background sync is enabled on state mutations.
  bool get autoSyncEnabled => _autoSyncEnabled;
  String _googleClientSecret = '';

  /// Google OAuth2 Client Secret for Drive synchronization.
  String get googleClientSecret => _googleClientSecret;

  /// Updates and persists the Google OAuth2 [id].
  Future<void> setGoogleClientId(String id) async {
    _googleClientId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('googleClientId', id);
  }

  /// Enables or disables automated background cloud sync.
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSyncEnabled', enabled);
  }

  /// Updates and persists the Google OAuth2 client [secret].
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

    if (prefs.containsKey('language')) {
      currentLanguage = prefs.getString('language')!;
    } else {
      final deviceLanguageCode =
          ui.PlatformDispatcher.instance.locale.languageCode;

      if (deviceLanguageCode == 'de') {
        currentLanguage = 'de';
      } else {
        currentLanguage = 'en';
      }
      await prefs.setString('language', currentLanguage);
    }

    Translator.currentLanguage = currentLanguage;

    currentLanguage = prefs.getString('language') ?? 'de';
    Translator.currentLanguage = currentLanguage;

    String tm = 'system';
    try {
      tm = prefs.getString('themeMode') ?? 'system';
    } catch (_) {
      int oldTheme = prefs.getInt('themeMode') ?? 0;
      if (oldTheme == 1) {
        tm = 'light';
      } else if (oldTheme == 2) {
        tm = 'dark';
      }
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

  /// Changes the active language to [lang] (e.g. `"de"` or `"en"`) and updates translations.
  void setLanguage(String lang) async {
    currentLanguage = lang;
    Translator.currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  /// Toggles between light and dark theme mode.
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
