import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Language Tests (TDD)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferences.resetStatic();
    });

    test('defaults to auto pokemonLanguage and correctly resolves effectivePokemonLanguage', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.pokemonLanguage, 'auto');
      // effectivePokemonLanguage follows currentLanguage if franchise language, else 'en'
      if (provider.currentLanguage == 'de') {
        expect(provider.effectivePokemonLanguage, 'de');
      } else {
        expect(provider.effectivePokemonLanguage, 'en');
      }
    });

    test('loads saved pokemonLanguage from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'language': 'de',
        'pokemonLanguage': 'ja',
      });

      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentLanguage, 'de');
      expect(provider.pokemonLanguage, 'ja');
      expect(provider.effectivePokemonLanguage, 'ja');
    });

    test('setLanguage updates currentLanguage and notifies listeners', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setLanguage('fr');
      expect(provider.currentLanguage, 'fr');
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), 'fr');
    });

    test('setPokemonLanguage updates pokemonLanguage and notifies listeners', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPokemonLanguage('ko');
      expect(provider.pokemonLanguage, 'ko');
      expect(provider.effectivePokemonLanguage, 'ko');
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pokemonLanguage'), 'ko');
    });

    test('effectivePokemonLanguage falls back to en for non-franchise app languages when auto', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setLanguage('pt');
      provider.setPokemonLanguage('auto');

      expect(provider.currentLanguage, 'pt');
      expect(provider.pokemonLanguage, 'auto');
      expect(provider.effectivePokemonLanguage, 'en');
    });

    test('first launch dynamically resolves supported device languages (e.g. fr, es, ja)', () async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferences.resetStatic();
      TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
          const Locale('fr');

      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentLanguage, 'fr');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), 'fr');
    });

    test('first launch resolves Chinese script tags (zh-Hans / zh-Hant)', () async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferences.resetStatic();
      TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentLanguage, 'zh-Hant');
    });

    test('first launch falls back to en for unsupported device language', () async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferences.resetStatic();
      TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
          const Locale('xx');

      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentLanguage, 'en');
    });
  });
}
