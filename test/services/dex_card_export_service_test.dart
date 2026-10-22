import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_progress_models.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/services/dex_card_export_service.dart';

void main() {
  group('DexCardExportService Tests', () {
    test('generateShareText for 100% complete dex (German)', () {
      final dex = UserDex(
        id: 'kanto_dex',
        title: 'Kanto Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: List.generate(151, (i) => '${i + 1}'),
        shinyIds: ['6', '25'],
        alphaIds: ['143'],
      );

      const stats = DexProgressStats(
        totalCount: 151,
        caughtCount: 151,
        percentage: 100.0,
        shinyCount: 2,
        alphaCount: 1,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final text = DexCardExportService.generateShareText(dex, stats, language: 'de');

      expect(text, contains('Kanto Living Dex'));
      expect(text, contains('151 / 151'));
      expect(text, contains('100.0%'));
      expect(text, contains('2'));
      expect(text, contains('PokéVault'));
    });

    test('generateShareText for partial progress dex (English)', () {
      final dex = UserDex(
        id: 'johto_dex',
        title: 'Johto Journey',
        region: 'johto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['152', '155'],
      );

      const stats = DexProgressStats(
        totalCount: 100,
        caughtCount: 42,
        percentage: 42.0,
        shinyCount: 5,
        alphaCount: 0,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final text = DexCardExportService.generateShareText(dex, stats, language: 'en');

      expect(text, contains('Johto Journey'));
      expect(text, contains('42 / 100'));
      expect(text, contains('42.0%'));
      expect(text, contains('PokéVault'));
    });

    test('sanitizeFileName removes invalid characters', () {
      final clean = DexCardExportService.sanitizeFileName('Kanto: Living/Dex *Special*?');
      expect(clean.contains(':'), isFalse);
      expect(clean.contains('/'), isFalse);
      expect(clean.contains('*'), isFalse);
      expect(clean.contains('?'), isFalse);
    });
  });
}
