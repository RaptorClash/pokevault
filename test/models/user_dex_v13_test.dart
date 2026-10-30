import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';

void main() {
  group('UserDex Model V13 Tests (Glitch Pokémon & Default False for Trades/Gifts)', () {
    test('Default values for includeTrades, includeGifts and includeGlitch are false', () {
      final dex = UserDex(
        id: 'test_default_v13',
        title: 'Default V13 Test Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      expect(dex.includeTrades, isFalse, reason: 'Trades must be disabled by default');
      expect(dex.includeGifts, isFalse, reason: 'Gifts must be disabled by default');
      expect(dex.includeGlitch, isFalse, reason: 'Glitch must be disabled by default');
    });

    test('UserDex.fallback has includeTrades, includeGifts, and includeGlitch as false', () {
      final fallback = UserDex.fallback('fallback_id');
      expect(fallback.includeTrades, isFalse);
      expect(fallback.includeGifts, isFalse);
      expect(fallback.includeGlitch, isFalse);
    });

    test('toMap and fromMap serialize and deserialize include_glitch, include_trades, and include_gifts', () {
      final dex = UserDex(
        id: 'test_glitch_custom',
        title: 'Custom Glitch Dex',
        region: 'johto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: true,
        includeGifts: false,
        includeGlitch: true,
        isShinyDex: false,
      );

      final map = dex.toMap();
      expect(map['include_trades'], 1);
      expect(map['include_gifts'], 0);
      expect(map['include_glitch'], 1);

      final restored = UserDex.fromMap(map);
      expect(restored.includeTrades, isTrue);
      expect(restored.includeGifts, isFalse);
      expect(restored.includeGlitch, isTrue);
    });

    test('toJson and fromJson serialize and deserialize includeGlitch, includeTrades, and includeGifts', () {
      final dex = UserDex(
        id: 'test_json',
        title: 'JSON Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: false,
        includeGifts: true,
        includeGlitch: true,
        isShinyDex: false,
      );

      final json = dex.toJson();
      expect(json['includeTrades'], isFalse);
      expect(json['includeGifts'], isTrue);
      expect(json['includeGlitch'], isTrue);

      final restored = UserDex.fromJson(json);
      expect(restored.includeTrades, isFalse);
      expect(restored.includeGifts, isTrue);
      expect(restored.includeGlitch, isTrue);
    });

    test('fromMap backward compatibility: missing include_glitch, trades, gifts default to false', () {
      final legacyMap = {
        'id': 'legacy_v11',
        'title': 'Legacy V11 Dex',
        'region': 'hoenn',
        'include_genders': 0,
        'include_regional': 0,
        'include_mega': 0,
        'include_gmax': 0,
        'include_other': 0,
        'is_shiny_dex': 0,
      };

      final restored = UserDex.fromMap(legacyMap);
      expect(restored.includeTrades, isFalse);
      expect(restored.includeGifts, isFalse);
      expect(restored.includeGlitch, isFalse);
    });
  });
}
