import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/l10n/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initialisiert mit Standardwerten wenn SharedPreferences leer sind', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.googleClientId, isEmpty);
      expect(provider.googleClientSecret, isEmpty);
      expect(provider.autoSyncEnabled, isFalse);
      expect(provider.themeMode, equals(ThemeMode.system));
      expect(provider.currentLanguage, isIn(['de', 'en']));
    });

    test('Liest existierende Werte aus SharedPreferences korrekt aus', () async {
      SharedPreferences.setMockInitialValues({
        'googleClientId': 'test_client_id_123',
        'googleClientSecret': 'test_secret_456',
        'autoSyncEnabled': true,
        'language': 'de',
        'themeMode': 'dark',
      });

      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.googleClientId, equals('test_client_id_123'));
      expect(provider.googleClientSecret, equals('test_secret_456'));
      expect(provider.autoSyncEnabled, isTrue);
      expect(provider.currentLanguage, equals('de'));
      expect(Translator.currentLanguage, equals('de'));
      expect(provider.themeMode, equals(ThemeMode.dark));
    });

    test('Liest altes int-basiertes themeMode Format (1=light, 2=dark)', () async {
      SharedPreferences.setMockInitialValues({
        'themeMode': 1,
      });

      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.themeMode, equals(ThemeMode.light));
    });

    test('setGoogleClientId speichert Wert und benachrichtigt Listener', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setGoogleClientId('new_id');
      expect(provider.googleClientId, equals('new_id'));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('googleClientId'), equals('new_id'));
    });

    test('setAutoSyncEnabled speichert Wert und benachrichtigt Listener', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setAutoSyncEnabled(true);
      expect(provider.autoSyncEnabled, isTrue);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('autoSyncEnabled'), isTrue);
    });

    test('setGoogleClientSecret speichert Wert und benachrichtigt Listener', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setGoogleClientSecret('secret_xyz');
      expect(provider.googleClientSecret, equals('secret_xyz'));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('googleClientSecret'), equals('secret_xyz'));
    });

    test('setLanguage aktualisiert currentLanguage und Translator', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setLanguage('de');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.currentLanguage, equals('de'));
      expect(Translator.currentLanguage, equals('de'));

      provider.setLanguage('en');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.currentLanguage, equals('en'));
      expect(Translator.currentLanguage, equals('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), equals('en'));
    });

    test('toggleTheme schaltet zwischen dark und light Mode um', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.themeMode, equals(ThemeMode.dark));

      provider.toggleTheme();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.themeMode, equals(ThemeMode.light));

      provider.toggleTheme();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.themeMode, equals(ThemeMode.dark));
    });
  });
}
