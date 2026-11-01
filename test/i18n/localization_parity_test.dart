import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Parity & Pre-Release Key Tests', () {
    late Map<String, dynamic> deJson;
    late Map<String, dynamic> enJson;

    setUpAll(() {
      final deFile = File('lib/i18n/strings_de.i18n.json');
      final enFile = File('lib/i18n/strings_en.i18n.json');

      expect(deFile.existsSync(), isTrue, reason: 'German translation file must exist');
      expect(enFile.existsSync(), isTrue, reason: 'English translation file must exist');

      deJson = jsonDecode(deFile.readAsStringSync()) as Map<String, dynamic>;
      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
    });

    Set<String> extractKeys(Map<String, dynamic> map, [String prefix = '']) {
      final keys = <String>{};
      map.forEach((key, value) {
        final fullKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map<String, dynamic>) {
          keys.addAll(extractKeys(value, fullKey));
        } else {
          keys.add(fullKey);
        }
      });
      return keys;
    }

    test('German and English translations have 100% key parity', () {
      final deKeys = extractKeys(deJson);
      final enKeys = extractKeys(enJson);

      final missingInEn = deKeys.difference(enKeys);
      final missingInDe = enKeys.difference(deKeys);

      expect(missingInEn, isEmpty, reason: 'Keys present in DE but missing in EN: $missingInEn');
      expect(missingInDe, isEmpty, reason: 'Keys present in EN but missing in DE: $missingInDe');
    });

    test('No translation string is empty or whitespace-only', () {
      void checkNonEmpty(Map<String, dynamic> map, String locale) {
        map.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            checkNonEmpty(value, locale);
          } else if (value is String) {
            expect(value.trim(), isNotEmpty, reason: 'Empty translation in $locale for key: $key');
          }
        });
      }

      checkNonEmpty(deJson, 'de');
      checkNonEmpty(enJson, 'en');
    });

    test('All v1.6.0 pre-release polish keys are present in both locales', () {
      final requiredKeys = [
        'sort_manual',
        'sort_most_caught',
        'sort_by_region',
        'export_tooltip',
        'move_tooltip',
        'delete_tooltip',
        'no_dexes_to_export',
        'menu_edit',
        'menu_move',
        'menu_delete',
        'reset_boxes_title',
        'reset_boxes_content',
        'reset_boxes_action',
        'reset_boxes_tooltip',
        'calc_gen_1',
        'calc_gen_2',
        'calc_gen_3_4',
        'calc_gen_5',
        'calc_gen_6_7',
        'calc_gen_7_5',
        'calc_gen_8',
        'calc_gen_8_5',
        'calc_gen_9',
        'calc_gen_9_5',
        'calc_mult_under_30',
        'calc_mult_30_plus',
        'calc_mult_150_plus',
        'calc_mult_300_plus',
        'calc_mult_450_plus',
        'calc_mult_600_plus',
        'no_older_versions',
        'select_pokemon_warning',
        'please_login_first',
        'hunt_game_label',
        'change_btn',
        'moved_successfully',
        'deleted_successfully',
        'items_deleted',
        'create_new_pokedex',
      ];

      final deKeys = extractKeys(deJson);
      final enKeys = extractKeys(enJson);

      for (final key in requiredKeys) {
        expect(deKeys.contains(key), isTrue, reason: 'Missing "$key" in strings_de.i18n.json');
        expect(enKeys.contains(key), isTrue, reason: 'Missing "$key" in strings_en.i18n.json');
      }
    });
  });
}
