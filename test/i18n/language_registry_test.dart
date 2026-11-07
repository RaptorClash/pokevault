import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/language_registry.g.dart';

void main() {
  group('LanguageRegistry Tests', () {
    test('contains all 13 supported App languages', () {
      const appLanguages = LanguageRegistry.supportedAppLanguages;
      expect(appLanguages.length, 13);

      final codes = appLanguages.map((l) => l.code).toSet();
      expect(
        codes,
        containsAll([
          'de',
          'en',
          'fr',
          'es',
          'it',
          'ja',
          'ko',
          'zh-Hans',
          'zh-Hant',
          'pt',
          'nl',
          'pl',
          'ru',
        ]),
      );
    });

    test('exactly 9 languages are marked as Pokemon franchise languages', () {
      final pokeLanguages = LanguageRegistry.supportedPokemonLanguages;
      expect(pokeLanguages.length, 9);

      final pokeCodes = pokeLanguages.map((l) => l.code).toSet();
      expect(
        pokeCodes,
        containsAll([
          'de',
          'en',
          'fr',
          'es',
          'it',
          'ja',
          'ko',
          'zh-Hans',
          'zh-Hant',
        ]),
      );

      // Verify that non-franchise languages are false
      expect(LanguageRegistry.isPokemonFranchise('pt'), isFalse);
      expect(LanguageRegistry.isPokemonFranchise('nl'), isFalse);
      expect(LanguageRegistry.isPokemonFranchise('pl'), isFalse);
      expect(LanguageRegistry.isPokemonFranchise('ru'), isFalse);
    });

    test('findByCode returns correct language metadata and handles case', () {
      final de = LanguageRegistry.findByCode('de');
      expect(de, isNotNull);
      expect(de!.code, 'de');
      expect(de.flag, '🇩🇪');
      expect(de.nameNative, 'Deutsch');
      expect(de.isPokemonFranchise, isTrue);

      final ja = LanguageRegistry.findByCode('JA');
      expect(ja, isNotNull);
      expect(ja!.code, 'ja');
      expect(ja.flag, '🇯🇵');
      expect(ja.nameNative, '日本語');

      final unknown = LanguageRegistry.findByCode('xyz');
      expect(unknown, isNull);
    });

    test('resolveEffectivePokemonLanguage resolves auto mode correctly', () {
      // If auto and app is franchise language -> uses app language
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('de', 'auto'), 'de');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('ja', 'auto'), 'ja');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('fr', 'auto'), 'fr');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('zh-Hans', 'auto'), 'zh-Hans');

      // If auto and app is NOT franchise language -> fallbacks to English ('en')
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('pt', 'auto'), 'en');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('nl', 'auto'), 'en');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('pl', 'auto'), 'en');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('ru', 'auto'), 'en');

      // Explicit pokemon language overrides app language
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('de', 'ja'), 'ja');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('fr', 'de'), 'de');
      expect(LanguageRegistry.resolveEffectivePokemonLanguage('pt', 'fr'), 'fr');
    });
  });
}
