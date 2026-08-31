import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/data/dex_groups_data.dart';

void main() {
  group('DexGroupsData Tests', () {
    test('Alle Gruppen haben mindestens einen Sub-Dex und ein Name-Key', () {
      for (var group in DexGroupsData.groups) {
        expect(group.nameKey, isNotEmpty);
        expect(group.dexKeys, isNotEmpty);
        expect(group.displayPokemonIds.length, equals(4));
      }
    });

    test(
      'getAvailableFeatures liefert korrekte Features für spezielle Dexe',
      () {
        final nationalFeatures = DexGroupsData.getAvailableFeatures(
          'national_overall',
        );
        expect(nationalFeatures['mega'], isTrue);
        expect(nationalFeatures['regional'], isTrue);

        final kantoFeatures = DexGroupsData.getAvailableFeatures('kanto');
        expect(kantoFeatures, isA<Map<String, bool>>());
        expect(kantoFeatures.containsKey('mega'), isTrue);
      },
    );
  });
}
