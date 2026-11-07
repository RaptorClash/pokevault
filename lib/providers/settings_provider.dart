import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/strings.g.dart';
import '../i18n/language_registry.g.dart';
import '../services/google_drive_sync_service.dart';
import 'dart:ui' as ui;

/// Provider managing persistent user preferences such as theme, language, and cloud credentials.
///
/// Persists values in [SharedPreferences] and keeps [LocaleSettings] in sync when language changes.
class SettingsProvider with ChangeNotifier {
  /// The active UI theme mode (light, dark, or system).
  ThemeMode themeMode = ThemeMode.system;

  /// The active App UI language code (e.g. `"de"`, `"en"`, `"fr"`).
  String currentLanguage = 'en';

  /// The selected Pokémon franchise language code (or `"auto"`).
  String pokemonLanguage = 'auto';

  /// Resolves the effective language code for Pokémon data.
  String get effectivePokemonLanguage =>
      LanguageRegistry.resolveEffectivePokemonLanguage(
        currentLanguage,
        pokemonLanguage,
      );

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

    currentLanguage = prefs.getString('language') ?? currentLanguage;
    pokemonLanguage = prefs.getString('pokemonLanguage') ?? 'auto';

    try {
      LocaleSettings.setLocaleRaw(currentLanguage);
    } catch (_) {
      LocaleSettings.setLocale(
        currentLanguage == 'de' ? AppLocale.de : AppLocale.en,
      );
    }

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

  /// Changes the active App UI language to [lang] (e.g. `"de"` or `"en"`) and updates translations.
  void setLanguage(String lang) {
    currentLanguage = lang;
    try {
      LocaleSettings.setLocaleRaw(lang);
    } catch (_) {
      LocaleSettings.setLocale(lang == 'de' ? AppLocale.de : AppLocale.en);
    }
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('language', lang);
    });
  }

  /// Changes the Pokémon data language to [lang] (e.g. `"auto"`, `"de"`, `"ja"`).
  void setPokemonLanguage(String lang) {
    pokemonLanguage = lang;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('pokemonLanguage', lang);
    });
  }

  /// Toggles between light and dark theme mode.
  void toggleTheme() async {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
