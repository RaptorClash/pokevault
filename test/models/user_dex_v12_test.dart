import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';

void main() {
  group('UserDex Model V12 Tests (Trades & Gifts)', () {
    test('Default values for includeTrades and includeGifts are false', () {
      final dex = UserDex(
        id: 'test_default',
        title: 'Default Test Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      expect(dex.includeTrades, isFalse);
      expect(dex.includeGifts, isFalse);
    });

    test('toMap and fromMap serialize and deserialize include_trades and include_gifts', () {
      final dex = UserDex(
        id: 'test_custom',
        title: 'Custom Test Dex',
        region: 'johto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: false,
        includeGifts: true,
        isShinyDex: false,
      );

      final map = dex.toMap();
      expect(map['include_trades'], 0);
      expect(map['include_gifts'], 1);

      final restored = UserDex.fromMap(map);
      expect(restored.includeTrades, isFalse);
      expect(restored.includeGifts, isTrue);
    });

    test('fromMap provides backward compatibility for legacy maps without trades/gifts columns', () {
      final legacyMap = {
        'id': 'legacy_dex',
        'title': 'Legacy Dex',
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
    });

    test('toJson and fromJson serialize and deserialize includeTrades and includeGifts', () {
      final dex = UserDex(
        id: 'json_dex',
        title: 'JSON Dex',
        region: 'sinnoh',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: true,
        includeGifts: false,
        isShinyDex: false,
      );

      final json = dex.toJson();
      expect(json['includeTrades'], isTrue);
      expect(json['includeGifts'], isFalse);

      final restored = UserDex.fromJson(json);
      expect(restored.includeTrades, isTrue);
      expect(restored.includeGifts, isFalse);
    });

    test('fromJson provides backward compatibility when keys are missing', () {
      final legacyJson = {
        'id': 'legacy_json',
        'title': 'Legacy JSON',
        'region': 'unova',
        'includeGenders': false,
        'includeRegional': false,
        'includeMega': false,
        'includeGMax': false,
        'includeOther': false,
        'isShinyDex': false,
      };

      final restored = UserDex.fromJson(legacyJson);
      expect(restored.includeTrades, isFalse);
      expect(restored.includeGifts, isFalse);
    });
  });
}
