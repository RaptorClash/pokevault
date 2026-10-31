import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/utils/isolate_translator.dart';

void main() {
  group('IsolateTranslator - Constructor & Locale Initialization', () {
    test('default constructor initializes with German (de) locale', () {
      final translator = IsolateTranslator();
      expect(translator.language, equals('de'));
      expect(translator.isDe, isTrue);
    });

    test('explicit German constructor initializes correctly', () {
      final translator = IsolateTranslator('de');
      expect(translator.language, equals('de'));
      expect(translator.isDe, isTrue);
    });

    test('explicit English constructor initializes correctly', () {
      final translator = IsolateTranslator('en');
      expect(translator.language, equals('en'));
      expect(translator.isDe, isFalse);
    });

    test('case-insensitivity of language codes', () {
      final deUpper = IsolateTranslator('DE');
      expect(deUpper.isDe, isTrue);

      final enUpper = IsolateTranslator('EN');
      expect(enUpper.isDe, isFalse);
    });

    test('two instances with different locales remain completely independent', () {
      final deTranslator = IsolateTranslator('de');
      final enTranslator = IsolateTranslator('en');

      expect(deTranslator.isDe, isTrue);
      expect(enTranslator.isDe, isFalse);
      expect(deTranslator.getRegionName('unova'), equals('Einall'));
      expect(enTranslator.getRegionName('unova'), equals('Unova'));
    });
  });

  group('IsolateTranslator - Generic Key Lookup (get)', () {
    final deTranslator = IsolateTranslator('de');
    final enTranslator = IsolateTranslator('en');

    test('retrieves existing keys correctly in German', () {
      expect(deTranslator.get('box'), equals('Box'));
      expect(deTranslator.get('cat_gifts'), equals('Geschenke'));
      expect(deTranslator.get('form_name_primal'), equals('Protomorphose'));
    });

    test('retrieves existing keys correctly in English', () {
      expect(enTranslator.get('box'), equals('Box'));
      expect(enTranslator.get('cat_gifts'), equals('Gifts'));
      expect(enTranslator.get('form_name_primal'), equals('Primal'));
    });

    test('normalizes hyphenated keys to snake_case automatically', () {
      expect(deTranslator.get('form_name_spiky-eared'), equals('Strubbelohr'));
      expect(enTranslator.get('form_name_spiky-eared'), equals('Spiky-eared'));
      expect(deTranslator.get('form_name_mega-x'), equals('Mega X'));
      expect(enTranslator.get('form_name_mega-x'), equals('Mega X'));
    });

    test('returns fallback value if key does not exist', () {
      expect(deTranslator.get('non_existent_key_xyz', fallback: 'CustomFallback'), equals('CustomFallback'));
      expect(enTranslator.get('non_existent_key_xyz', fallback: 'CustomFallback'), equals('CustomFallback'));
    });

    test('returns key itself if key does not exist and no fallback is given', () {
      expect(deTranslator.get('unknown_key_123'), equals('unknown_key_123'));
      expect(enTranslator.get('unknown_key_123'), equals('unknown_key_123'));
    });
  });

  group('IsolateTranslator - Region Name Translations (getRegionName)', () {
    final de = IsolateTranslator('de');
    final en = IsolateTranslator('en');

    test('translates all canonical Pokémon regions in German and English', () {
      final regions = {
        'kanto': {'de': 'Kanto', 'en': 'Kanto'},
        'johto': {'de': 'Johto', 'en': 'Johto'},
        'hoenn': {'de': 'Hoenn', 'en': 'Hoenn'},
        'sinnoh': {'de': 'Sinnoh', 'en': 'Sinnoh'},
        'unova': {'de': 'Einall', 'en': 'Unova'},
        'kalos': {'de': 'Kalos', 'en': 'Kalos'},
        'alola': {'de': 'Alola', 'en': 'Alola'},
        'galar': {'de': 'Galar', 'en': 'Galar'},
        'hisui': {'de': 'Hisui', 'en': 'Hisui'},
        'paldea': {'de': 'Paldea', 'en': 'Paldea'},
        'unknown': {'de': 'Unbekannt', 'en': 'Unknown'},
      };

      for (final entry in regions.entries) {
        final regionId = entry.key;
        final expectedDe = entry.value['de']!;
        final expectedEn = entry.value['en']!;

        expect(de.getRegionName(regionId), equals(expectedDe), reason: 'DE failed for region $regionId');
        expect(en.getRegionName(regionId), equals(expectedEn), reason: 'EN failed for region $regionId');
      }
    });

    test('translates lumiose region with city suffix support', () {
      expect(de.getRegionName('lumiose'), anyOf(equals('Illumina'), equals('Illumina City')));
      expect(en.getRegionName('lumiose'), anyOf(equals('Lumiose'), equals('Lumiose City')));
    });

    test('handles case-insensitivity of regionId input', () {
      expect(de.getRegionName('UNOVA'), equals('Einall'));
      expect(en.getRegionName('UnOvA'), equals('Unova'));
      expect(de.getRegionName('HoEnN'), equals('Hoenn'));
      expect(en.getRegionName('kAlOs'), equals('Kalos'));
    });

    test('falls back to capitalized regionId for unregistered or custom regions', () {
      expect(de.getRegionName('pasio'), equals('Pasio'));
      expect(en.getRegionName('pasio'), equals('Pasio'));
      expect(de.getRegionName('custom_region'), equals('Custom_region'));
    });

    test('returns empty string for empty regionId input', () {
      expect(de.getRegionName(''), equals(''));
      expect(en.getRegionName(''), equals(''));
    });
  });

  group('IsolateTranslator - Form Display Names (getFormDisplayName)', () {
    final de = IsolateTranslator('de');
    final en = IsolateTranslator('en');

    test('translates special and mega forms correctly in German and English', () {
      expect(de.getFormDisplayName('primal'), equals('Protomorphose'));
      expect(en.getFormDisplayName('primal'), equals('Primal'));

      expect(de.getFormDisplayName('mega'), equals('Mega'));
      expect(en.getFormDisplayName('mega'), equals('Mega'));

      expect(de.getFormDisplayName('gmax'), equals('Gigadynamax'));
      expect(en.getFormDisplayName('gmax'), equals('Gigantamax'));

      expect(de.getFormDisplayName('totem'), equals('Herrscher'));
      expect(en.getFormDisplayName('totem'), equals('Totem'));
    });

    test('translates regional form names correctly', () {
      expect(de.getFormDisplayName('alola'), equals('Alola'));
      expect(en.getFormDisplayName('alola'), equals('Alola'));
      expect(de.getFormDisplayName('galar'), equals('Galar'));
      expect(en.getFormDisplayName('galar'), equals('Galar'));
      expect(de.getFormDisplayName('hisui'), equals('Hisui'));
      expect(en.getFormDisplayName('hisui'), equals('Hisui'));
      expect(de.getFormDisplayName('paldea'), equals('Paldea'));
      expect(en.getFormDisplayName('paldea'), equals('Paldea'));
    });

    test('handles hyphenated form names with normalization', () {
      expect(de.getFormDisplayName('spiky-eared'), equals('Strubbelohr'));
      expect(en.getFormDisplayName('spiky-eared'), equals('Spiky-eared'));

      expect(de.getFormDisplayName('mega-x'), equals('Mega X'));
      expect(en.getFormDisplayName('mega-x'), equals('Mega X'));

      expect(de.getFormDisplayName('mega-y'), equals('Mega Y'));
      expect(en.getFormDisplayName('mega-y'), equals('Mega Y'));

      expect(de.getFormDisplayName('original-cap'), equals('Original-Cap'));
      expect(en.getFormDisplayName('original-cap'), equals('Original-Cap'));

      expect(de.getFormDisplayName('poke-ball'), equals('Poké Ball'));
      expect(en.getFormDisplayName('poke-ball'), equals('Poké Ball'));
    });

    test('handles case-insensitivity of form input', () {
      expect(de.getFormDisplayName('PRIMAL'), equals('Protomorphose'));
      expect(en.getFormDisplayName('PrImAl'), equals('Primal'));
      expect(de.getFormDisplayName('GMAX'), equals('Gigadynamax'));
      expect(en.getFormDisplayName('GMAX'), equals('Gigantamax'));
    });

    test('falls back to capitalized form string for unknown forms', () {
      expect(de.getFormDisplayName('custom_form'), equals('Custom_form'));
      expect(en.getFormDisplayName('custom_form'), equals('Custom_form'));
    });

    test('returns empty string for empty form input', () {
      expect(de.getFormDisplayName(''), equals(''));
      expect(en.getFormDisplayName(''), equals(''));
    });
  });

  group('IsolateTranslator - Fixed Labels & Getters', () {
    final de = IsolateTranslator('de');
    final en = IsolateTranslator('en');

    test('getBoxLabel and boxLabel getter return Box in both languages', () {
      expect(de.getBoxLabel(), equals('Box'));
      expect(de.boxLabel, equals('Box'));
      expect(en.getBoxLabel(), equals('Box'));
      expect(en.boxLabel, equals('Box'));
    });

    test('getFormsLabel and formsLabel getter return localized labels', () {
      expect(de.getFormsLabel(), equals('Formen'));
      expect(de.formsLabel, equals('Formen'));
      expect(en.getFormsLabel(), equals('Forms'));
      expect(en.formsLabel, equals('Forms'));
    });

    test('getTradesLabel and tradesLabel getter return localized labels', () {
      expect(de.getTradesLabel(), equals('Tausche'));
      expect(de.tradesLabel, equals('Tausche'));
      expect(en.getTradesLabel(), equals('Trades'));
      expect(en.tradesLabel, equals('Trades'));
    });

    test('getGiftsLabel and giftsLabel getter return localized labels', () {
      expect(de.getGiftsLabel(), equals('Geschenke'));
      expect(de.giftsLabel, equals('Geschenke'));
      expect(en.getGiftsLabel(), equals('Gifts'));
      expect(en.giftsLabel, equals('Gifts'));
    });
  });

  group('IsolateTranslator - Category Names (getCategoryName)', () {
    final de = IsolateTranslator('de');
    final en = IsolateTranslator('en');

    test('translates standard and special category IDs in German', () {
      expect(de.getCategoryName('trades'), equals('Tausche'));
      expect(de.getCategoryName('gifts'), equals('Geschenke'));
      expect(de.getCategoryName('orre'), equals('Colosseum & XD'));
      expect(de.getCategoryName('furfrou'), equals('Coiffwaff'));
      expect(de.getCategoryName('silvally'), equals('Amigento'));
      expect(de.getCategoryName('arceus'), equals('Arceus'));
      expect(de.getCategoryName('n_pokemon'), equals("N's Pokémon"));
      expect(de.getCategoryName('mega'), equals('Mega'));
    });

    test('translates standard and special category IDs in English', () {
      expect(en.getCategoryName('trades'), equals('Trades'));
      expect(en.getCategoryName('gifts'), equals('Gifts'));
      expect(en.getCategoryName('orre'), equals('Colosseum & XD'));
      expect(en.getCategoryName('furfrou'), equals('Furfrou'));
      expect(en.getCategoryName('silvally'), equals('Silvally'));
      expect(en.getCategoryName('arceus'), equals('Arceus'));
      expect(en.getCategoryName('n_pokemon'), equals("N's Pokémon"));
      expect(en.getCategoryName('mega'), equals('Mega'));
    });

    test('falls back to category ID if unregistered', () {
      expect(de.getCategoryName('unmapped_cat'), equals('unmapped_cat'));
      expect(en.getCategoryName('unmapped_cat'), equals('unmapped_cat'));
    });
  });

  group('IsolateTranslator - Dynamic Box Title Formatting', () {
    final de = IsolateTranslator('de');
    final en = IsolateTranslator('en');

    group('formatStandardBoxTitle', () {
      test('formats standard sequential box headers correctly', () {
        expect(de.formatStandardBoxTitle(0, 1, 30), equals('Box 1 (1-30)'));
        expect(en.formatStandardBoxTitle(0, 1, 30), equals('Box 1 (1-30)'));

        expect(de.formatStandardBoxTitle(1, 31, 60), equals('Box 2 (31-60)'));
        expect(en.formatStandardBoxTitle(1, 31, 60), equals('Box 2 (31-60)'));

        expect(de.formatStandardBoxTitle(4, 121, 150), equals('Box 5 (121-150)'));
        expect(en.formatStandardBoxTitle(4, 121, 150), equals('Box 5 (121-150)'));
      });

      test('formats large dex range boundaries without overflow', () {
        expect(de.formatStandardBoxTitle(33, 991, 1020), equals('Box 34 (991-1020)'));
        expect(en.formatStandardBoxTitle(33, 991, 1020), equals('Box 34 (991-1020)'));
      });
    });

    group('formatFormBoxTitle', () {
      test('single chunk form box title does not append chunk index', () {
        expect(de.formatFormBoxTitle(5, 0, 1), equals('Box 5 (Formen)'));
        expect(en.formatFormBoxTitle(5, 0, 1), equals('Box 5 (Forms)'));
      });

      test('multi chunk form box title appends 1-based chunk index', () {
        expect(de.formatFormBoxTitle(5, 0, 2), equals('Box 5 (Formen 1)'));
        expect(de.formatFormBoxTitle(6, 1, 2), equals('Box 6 (Formen 2)'));

        expect(en.formatFormBoxTitle(5, 0, 2), equals('Box 5 (Forms 1)'));
        expect(en.formatFormBoxTitle(6, 1, 2), equals('Box 6 (Forms 2)'));
      });

      test('handles 3+ chunk boundaries', () {
        expect(de.formatFormBoxTitle(10, 2, 3), equals('Box 10 (Formen 3)'));
        expect(en.formatFormBoxTitle(10, 2, 3), equals('Box 10 (Forms 3)'));
      });
    });

    group('formatCategoryBoxTitle', () {
      test("formats N's Pokémon category title across locales", () {
        expect(de.formatCategoryBoxTitle('unova', 'n_pokemon'), equals("N's Pokémon"));
        expect(en.formatCategoryBoxTitle('unova', 'n_pokemon'), equals("N's Pokémon"));

        // Multi-chunk N's Pokemon
        expect(de.formatCategoryBoxTitle('unova', 'n_pokemon', chunkIndex: 1, totalChunks: 2), equals("N's Pokémon 2"));
        expect(en.formatCategoryBoxTitle('unova', 'n_pokemon', chunkIndex: 1, totalChunks: 2), equals("N's Pokémon 2"));
      });

      test('formats standard trades category title with localized region', () {
        expect(de.formatCategoryBoxTitle('kanto', 'trades'), equals('Kanto Tausche'));
        expect(en.formatCategoryBoxTitle('kanto', 'trades'), equals('Kanto Trades'));

        expect(de.formatCategoryBoxTitle('unova', 'trades'), equals('Einall Tausche'));
        expect(en.formatCategoryBoxTitle('unova', 'trades'), equals('Unova Trades'));
      });

      test('formats Lumiose trades with (Z-A) suffix', () {
        expect(
          de.formatCategoryBoxTitle('lumiose', 'trades'),
          anyOf(equals('Illumina Tausche (Z-A)'), equals('Illumina City Tausche (Z-A)')),
        );
        expect(
          en.formatCategoryBoxTitle('lumiose', 'trades'),
          anyOf(equals('Lumiose Trades (Z-A)'), equals('Lumiose City Trades (Z-A)')),
        );
      });

      test('formats gifts category title with localized region', () {
        expect(de.formatCategoryBoxTitle('johto', 'gifts'), equals('Johto Geschenke'));
        expect(en.formatCategoryBoxTitle('johto', 'gifts'), equals('Johto Gifts'));
      });

      test('formats Orre category title with Colosseum & XD and Trades label', () {
        expect(de.formatCategoryBoxTitle('hoenn', 'orre'), equals('Hoenn Colosseum & XD Tausche'));
        expect(en.formatCategoryBoxTitle('hoenn', 'orre'), equals('Hoenn Colosseum & XD Trades'));
      });

      test('formats Furfrou category title with Coiffwaff in German and Furfrou in English', () {
        expect(de.formatCategoryBoxTitle('kalos', 'furfrou'), equals('Kalos Coiffwaff'));
        expect(en.formatCategoryBoxTitle('kalos', 'furfrou'), equals('Kalos Furfrou'));
      });

      test('formats Silvally category title with Amigento in German and Silvally in English', () {
        expect(de.formatCategoryBoxTitle('alola', 'silvally'), equals('Alola Amigento'));
        expect(en.formatCategoryBoxTitle('alola', 'silvally'), equals('Alola Silvally'));
      });

      test('formats Arceus category title with localized region', () {
        expect(de.formatCategoryBoxTitle('sinnoh', 'arceus'), equals('Sinnoh Arceus'));
        expect(en.formatCategoryBoxTitle('sinnoh', 'arceus'), equals('Sinnoh Arceus'));
      });

      test('formats base category title as localized region name only', () {
        expect(de.formatCategoryBoxTitle('kanto', 'base'), equals('Kanto'));
        expect(en.formatCategoryBoxTitle('kanto', 'base'), equals('Kanto'));
        expect(de.formatCategoryBoxTitle('unova', 'base'), equals('Einall'));
        expect(en.formatCategoryBoxTitle('unova', 'base'), equals('Unova'));
      });

      test('formats general category titles with localized region and category', () {
        expect(de.formatCategoryBoxTitle('kalos', 'mega'), equals('Kalos Mega'));
        expect(en.formatCategoryBoxTitle('kalos', 'mega'), equals('Kalos Mega'));
      });

      test('appends 1-based index suffix when totalChunks > 1', () {
        expect(de.formatCategoryBoxTitle('kanto', 'trades', chunkIndex: 0, totalChunks: 2), equals('Kanto Tausche 1'));
        expect(de.formatCategoryBoxTitle('kanto', 'trades', chunkIndex: 1, totalChunks: 2), equals('Kanto Tausche 2'));

        expect(en.formatCategoryBoxTitle('kanto', 'trades', chunkIndex: 0, totalChunks: 2), equals('Kanto Trades 1'));
        expect(en.formatCategoryBoxTitle('kanto', 'trades', chunkIndex: 1, totalChunks: 2), equals('Kanto Trades 2'));

        expect(
          de.formatCategoryBoxTitle('lumiose', 'trades', chunkIndex: 1, totalChunks: 2),
          anyOf(equals('Illumina Tausche (Z-A) 2'), equals('Illumina City Tausche (Z-A) 2')),
        );
        expect(
          en.formatCategoryBoxTitle('lumiose', 'trades', chunkIndex: 1, totalChunks: 2),
          anyOf(equals('Lumiose Trades (Z-A) 2'), equals('Lumiose City Trades (Z-A) 2')),
        );
      });
    });
  });
}
