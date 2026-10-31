import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/utils/isolate_translator.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Stress Test: Pure Dart & Concurrent Isolate Execution', () {
    test('Can instantiate and query IsolateTranslator across 20 concurrent background isolates', () async {
      final futures = <Future<Map<String, dynamic>>>[];

      for (int i = 0; i < 20; i++) {
        final lang = i.isEven ? 'de' : 'en';
        final future = Isolate.run<Map<String, dynamic>>(() {
          // Inside a fresh background isolate - no WidgetsFlutterBinding
          final translator = IsolateTranslator(lang);
          return {
            'lang': translator.language,
            'isDe': translator.isDe,
            'region_unova': translator.getRegionName('unova'),
            'form_primal': translator.getFormDisplayName('primal'),
            'box_title': translator.formatStandardBoxTitle(0, 1, 30),
            'form_box': translator.formatFormBoxTitle(1, 0, 1),
            'trades': translator.getCategoryName('trades'),
          };
        });
        futures.add(future);
      }

      final results = await Future.wait(futures);
      expect(results.length, equals(20));

      for (int i = 0; i < 20; i++) {
        final res = results[i];
        if (i.isEven) {
          expect(res['lang'], equals('de'));
          expect(res['isDe'], isTrue);
          expect(res['region_unova'], equals('Einall'));
          expect(res['form_primal'], equals('Protomorphose'));
          expect(res['box_title'], equals('Box 1 (1-30)'));
          expect(res['form_box'], equals('Box 1 (Formen)'));
          expect(res['trades'], equals('Tausche'));
        } else {
          expect(res['lang'], equals('en'));
          expect(res['isDe'], isFalse);
          expect(res['region_unova'], equals('Unova'));
          expect(res['form_primal'], equals('Primal'));
          expect(res['box_title'], equals('Box 1 (1-30)'));
          expect(res['form_box'], equals('Box 1 (Forms)'));
          expect(res['trades'], equals('Trades'));
        }
      }
    });

    test('Zero Flutter framework dependency: IsolateTranslator functions in standalone isolate without Flutter bindings', () async {
      final result = await Isolate.run(() {
        final de = IsolateTranslator('de');
        final en = IsolateTranslator('en');
        return {
          'de_box': de.boxLabel,
          'en_box': en.boxLabel,
          'de_region': de.getRegionName('paldea'),
          'en_region': en.getRegionName('paldea'),
        };
      });

      expect(result['de_box'], equals('Box'));
      expect(result['en_box'], equals('Box'));
      expect(result['de_region'], equals('Paldea'));
      expect(result['en_region'], equals('Paldea'));
    });
  });

  group('Adversarial Boundary Test: Extreme & Bizarre Inputs', () {
    final de = IsolateTranslator('de');
    final en = IsolateTranslator('en');

    group('formatStandardBoxTitle boundary cases', () {
      test('handles extremely large integers without overflow or crash', () {
        const largeInt = 9223372036854775806; // Near 64-bit max
        expect(
          de.formatStandardBoxTitle(1000000, 100000000, 200000000),
          equals('Box 1000001 (100000000-200000000)'),
        );
        expect(
          en.formatStandardBoxTitle(1000000, 100000000, 200000000),
          equals('Box 1000001 (100000000-200000000)'),
        );
        expect(
          de.formatStandardBoxTitle(largeInt - 1, largeInt, largeInt),
          equals('Box 9223372036854775806 (9223372036854775806-9223372036854775806)'),
        );
      });

      test('handles negative and zero indices gracefully without throwing', () {
        expect(de.formatStandardBoxTitle(-1, -30, -1), equals('Box 0 (-30--1)'));
        expect(en.formatStandardBoxTitle(-100, 0, 0), equals('Box -99 (0-0)'));
        expect(de.formatStandardBoxTitle(0, 0, 0), equals('Box 1 (0-0)'));
      });
    });

    group('formatFormBoxTitle boundary cases', () {
      test('handles chunkIndex and totalChunks edge cases', () {
        // totalChunks <= 0 should format with chunkIndex + 1 without crashing
        expect(de.formatFormBoxTitle(1, 0, 0), equals('Box 1 (Formen 1)'));
        expect(en.formatFormBoxTitle(1, -2, -1), equals('Box 1 (Forms -1)'));
        expect(de.formatFormBoxTitle(999999, 99, 100), equals('Box 999999 (Formen 100)'));
        expect(en.formatFormBoxTitle(999999, 99, 100), equals('Box 999999 (Forms 100)'));
      });
    });

    group('getRegionName boundary cases', () {
      test('handles empty, whitespace, and mixed case strings', () {
        expect(de.getRegionName(''), equals(''));
        expect(en.getRegionName(''), equals(''));
        expect(de.getRegionName('uNoVa'), equals('Einall'));
        expect(en.getRegionName('UNOVA'), equals('Unova'));
        expect(de.getRegionName('kAnTo'), equals('Kanto'));
        expect(en.getRegionName('pAlDeA'), equals('Paldea'));
      });

      test('handles arbitrary unrecognized regions without throwing', () {
        expect(de.getRegionName('unknown_custom_region'), equals('Unknown_custom_region'));
        expect(en.getRegionName('unknown_custom_region'), equals('Unknown_custom_region'));
        expect(de.getRegionName('123'), equals('123'));
        expect(de.getRegionName('a'), equals('A'));
      });
    });

    group('getFormDisplayName boundary cases', () {
      test('handles empty, mixed casing, hyphens and underscores', () {
        expect(de.getFormDisplayName(''), equals(''));
        expect(en.getFormDisplayName(''), equals(''));
        expect(de.getFormDisplayName('pRiMaL'), equals('Protomorphose'));
        expect(en.getFormDisplayName('PRIMAL'), equals('Primal'));
        expect(de.getFormDisplayName('gMaX'), equals('Gigadynamax'));
        expect(en.getFormDisplayName('GMAX'), equals('Gigantamax'));
        expect(de.getFormDisplayName('tOtEm'), equals('Herrscher'));
        expect(en.getFormDisplayName('TOTEM'), equals('Totem'));
      });

      test('handles hyphens vs underscores interchangeably', () {
        expect(de.getFormDisplayName('spiky-eared'), equals('Strubbelohr'));
        expect(de.getFormDisplayName('spiky_eared'), equals('Strubbelohr'));
        expect(en.getFormDisplayName('spiky-eared'), equals('Spiky-eared'));
        expect(en.getFormDisplayName('spiky_eared'), equals('Spiky-eared'));

        expect(de.getFormDisplayName('original-cap'), equals('Original-Cap'));
        expect(de.getFormDisplayName('original_cap'), equals('Original-Cap'));
        expect(de.getFormDisplayName('poke-ball'), equals('Poké Ball'));
        expect(de.getFormDisplayName('poke_ball'), equals('Poké Ball'));
      });

      test('handles weird characters and numeric form names safely', () {
        expect(de.getFormDisplayName('10%'), equals('10%'));
        expect(de.getFormDisplayName('50%'), equals('50%'));
        expect(de.getFormDisplayName('100%'), equals('100%'));
        expect(de.getFormDisplayName('???'), equals('???'));
        expect(de.getFormDisplayName('x'), equals('X'));
      });
    });

    group('get() generic translation lookup boundary cases', () {
      test('handles empty key and cat_ prefix edge cases', () {
        expect(de.get(''), equals(''));
        expect(en.get(''), equals(''));
        expect(de.get('', fallback: 'fb'), equals('fb'));
        expect(de.get('cat_'), equals('cat_'));
        expect(de.get('cat_unknown_category_xyz'), equals('cat_unknown_category_xyz'));
        expect(en.get('cat_unknown_category_xyz'), equals('cat_unknown_category_xyz'));
        expect(de.getCategoryName('unknown_category_xyz'), equals('unknown_category_xyz'));
        expect(en.getCategoryName('unknown_category_xyz'), equals('unknown_category_xyz'));
      });

      test('handles hyphen-to-underscore mapping for generic keys', () {
        expect(de.get('form-name-primal'), equals('Protomorphose'));
        expect(en.get('form-name-primal'), equals('Primal'));
        expect(de.get('region-name-unova'), equals('Einall'));
        expect(en.get('region-name-unova'), equals('Unova'));
      });

      test('maps special categories via get correctly', () {
        expect(de.get('cat_gifts'), equals('Geschenke'));
        expect(en.get('cat_gifts'), equals('Gifts'));
        expect(de.get('cat_trades'), equals('Tausche'));
        expect(en.get('cat_trades'), equals('Trades'));
        expect(de.get('box'), equals('Box'));
        expect(en.get('box'), equals('Box'));
      });
    });

    group('formatCategoryBoxTitle boundary cases', () {
      test('handles empty region and empty category', () {
        expect(de.formatCategoryBoxTitle('', ''), equals(' '));
        expect(en.formatCategoryBoxTitle('', ''), equals(' '));
        expect(de.formatCategoryBoxTitle('', '', chunkIndex: 1, totalChunks: 2), equals('  2'));
      });

      test('handles all special categories with various chunk indices', () {
        final specialCats = [
          'n_pokemon',
          'trades',
          'gifts',
          'orre',
          'furfrou',
          'silvally',
          'arceus',
          'base',
          'mega',
          'custom_category',
        ];

        for (final cat in specialCats) {
          final deSingle = de.formatCategoryBoxTitle('kanto', cat);
          final deMulti = de.formatCategoryBoxTitle('kanto', cat, chunkIndex: 2, totalChunks: 3);
          final enSingle = en.formatCategoryBoxTitle('kanto', cat);
          final enMulti = en.formatCategoryBoxTitle('kanto', cat, chunkIndex: 2, totalChunks: 3);

          expect(deSingle, isNotEmpty);
          expect(deMulti, endsWith(' 3'));
          expect(enSingle, isNotEmpty);
          expect(enMulti, endsWith(' 3'));
        }
      });
    });
  });

  group('Adversarial Stress Test: Rapid Locale Switching & Provider State', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Rapid consecutive LocaleSettings.setLocale switching preserves consistency between t and currentLocale', () {
      for (int i = 0; i < 200; i++) {
        final targetLocale = i.isEven ? AppLocale.de : AppLocale.en;
        LocaleSettings.setLocale(targetLocale);

        expect(LocaleSettings.currentLocale, equals(targetLocale));
        if (targetLocale == AppLocale.de) {
          expect(t.cancel, equals('Abbrechen'));
          expect(t.settings, equals('Einstellungen'));
        } else {
          expect(t.cancel, equals('Cancel'));
          expect(t.settings, equals('Settings'));
        }
      }
    });

    test('SettingsProvider rapidly switching language remains consistent and in-sync with LocaleSettings', () async {
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      for (int i = 0; i < 50; i++) {
        final lang = i.isEven ? 'de' : 'en';
        provider.setLanguage(lang);

        expect(provider.currentLanguage, equals(lang));
        expect(
          LocaleSettings.currentLocale,
          equals(lang == 'de' ? AppLocale.de : AppLocale.en),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), equals('en'));
    });

    test('Interleaved asynchronous locale switching does not throw or corrupt state', () async {
      final futures = <Future<void>>[];

      for (int i = 0; i < 50; i++) {
        final locale = i.isEven ? AppLocale.de : AppLocale.en;
        futures.add(
          Future.delayed(Duration(milliseconds: i % 5), () {
            LocaleSettings.setLocale(locale);
          }),
        );
      }

      await Future.wait(futures);

      // Verify final state is valid and responsive
      expect(LocaleSettings.currentLocale, isIn([AppLocale.de, AppLocale.en]));
      expect(t.cancel, isIn(['Abbrechen', 'Cancel']));
    });
  });
}
