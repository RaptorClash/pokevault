import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

void main() {
  group('Box Dimensions Defaults (6 width x 5 height for 30 capacity)', () {
    test('CustomBoxState default constructor has 6 columns and 5 rows (30 capacity)', () {
      final box = CustomBoxState(title: 'Box 1', pokemonIds: []);
      expect(box.columns, equals(6));
      expect(box.rows, equals(5));
      expect(box.capacity, equals(30));
    });

    test('CustomBoxState.fromMap defaults to 6 columns and 5 rows when keys are missing', () {
      final box = CustomBoxState.fromMap({
        'title': 'Legacy Map Box',
        'pokemonIds': <String>[],
      });
      expect(box.columns, equals(6));
      expect(box.rows, equals(5));
      expect(box.capacity, equals(30));
    });

    test('DexLogicHelper.generateBoxes creates 6 crossAxisCount for standard 30-capacity dexes', () {
      final dex = createTestUserDex(
        id: 'hoenn_dex',
        title: 'Hoenn Dex',
        region: 'hoenn',
      );

      final entries = List.generate(
        30,
        (i) => createTestEntry(
          pokemon: createTestPokemon(id: i + 1, nameDe: 'Mon $i', nameEn: 'Mon $i'),
          uniqueId: '${i + 1}_normal',
        ),
      );

      final boxes = DexLogicHelper.generateBoxes(entries, false, dex);
      expect(boxes, isNotEmpty);
      expect(boxes.first.crossAxisCount, equals(6));
      expect(boxes.first.entries.length, equals(30));
    });

    test('DexLogicHelper.generateBoxes preserves 4 crossAxisCount for Kanto & Johto (20 capacity)', () {
      final kantoDex = createTestUserDex(
        id: 'kanto_dex',
        title: 'Kanto Dex',
        region: 'kanto_regional',
      );

      final entries = List.generate(
        20,
        (i) => createTestEntry(
          pokemon: createTestPokemon(id: i + 1, nameDe: 'Mon $i', nameEn: 'Mon $i'),
          uniqueId: '${i + 1}_normal',
        ),
      );

      final kantoBoxes = DexLogicHelper.generateBoxes(entries, false, kantoDex);
      expect(kantoBoxes, isNotEmpty);
      expect(kantoBoxes.first.crossAxisCount, equals(4));
      expect(kantoBoxes.first.entries.length, equals(20));

      final johtoDex = createTestUserDex(
        id: 'johto_dex',
        title: 'Johto Dex',
        region: 'johto_regional',
      );
      final johtoBoxes = DexLogicHelper.generateBoxes(entries, false, johtoDex);
      expect(johtoBoxes, isNotEmpty);
      expect(johtoBoxes.first.crossAxisCount, equals(4));
      expect(johtoBoxes.first.entries.length, equals(20));
    });

    test('DexLogicHelper.initializeCustomBoxesFromEntries creates 6x5 boxes for 30 capacity', () {
      final dex = createTestUserDex(
        id: 'custom_dex',
        title: 'Custom Dex',
        region: 'custom_empty',
      );

      final entries = List.generate(
        10,
        (i) => createTestEntry(
          pokemon: createTestPokemon(id: i + 1, nameDe: 'Mon $i', nameEn: 'Mon $i'),
          uniqueId: '${i + 1}_normal',
        ),
      );

      final customBoxes = DexLogicHelper.initializeCustomBoxesFromEntries(dex, entries, boxCapacity: 30);
      expect(customBoxes, isNotEmpty);
      expect(customBoxes.first.columns, equals(6));
      expect(customBoxes.first.rows, equals(5));
      expect(customBoxes.first.capacity, equals(30));
    });

    test('DexLogicHelper.initializeCustomBoxesFromEntries preserves 4x5 boxes when boxCapacity is 20', () {
      final dex = createTestUserDex(
        id: 'kanto_custom',
        title: 'Kanto Custom',
        region: 'kanto_regional',
      );

      final entries = List.generate(
        10,
        (i) => createTestEntry(
          pokemon: createTestPokemon(id: i + 1, nameDe: 'Mon $i', nameEn: 'Mon $i'),
          uniqueId: '${i + 1}_normal',
        ),
      );

      final customBoxes = DexLogicHelper.initializeCustomBoxesFromEntries(dex, entries, boxCapacity: 20);
      expect(customBoxes, isNotEmpty);
      expect(customBoxes.first.columns, equals(4));
      expect(customBoxes.first.rows, equals(5));
      expect(customBoxes.first.capacity, equals(20));
    });

    test('migrateCustomBoxesDefaultDimensions updates legacy 5x6 custom boxes to 6x5', () {
      final dex = createTestUserDex(
        id: 'legacy_dex',
        title: 'Legacy Dex',
        region: 'hoenn',
      );
      dex.customBoxes = [
        CustomBoxState(title: 'Legacy 1', pokemonIds: ['1_normal'], columns: 5, rows: 6),
        CustomBoxState(title: 'Custom 4x4', pokemonIds: ['2_normal'], columns: 4, rows: 4),
      ];

      final didMigrate = DexLogicHelper.migrateCustomBoxesDefaultDimensions(dex);
      expect(didMigrate, isTrue);
      expect(dex.customBoxes[0].columns, equals(6));
      expect(dex.customBoxes[0].rows, equals(5));
      expect(dex.customBoxes[0].capacity, equals(30));
      // Non-5x6 box is preserved as-is
      expect(dex.customBoxes[1].columns, equals(4));
      expect(dex.customBoxes[1].rows, equals(4));
    });

    test('DexLogicHelper.initializeCustomBoxesFromEntries calculates rows dynamically from BoxData', () {
      final dex = createTestUserDex(
        id: 'box_data_dex',
        title: 'Box Data Dex',
        region: 'hoenn',
      );

      final entries12 = List.generate(
        12,
        (i) => createTestEntry(
          pokemon: createTestPokemon(id: i + 1, nameDe: 'Mon $i', nameEn: 'Mon $i'),
          uniqueId: '${i + 1}_normal',
        ),
      );

      final boxData12 = BoxData('Custom 3x4', 'hoenn', entries12, 3);
      final customBoxes = DexLogicHelper.initializeCustomBoxesFromEntries(
        dex,
        entries12,
        boxes: [boxData12],
      );

      expect(customBoxes, isNotEmpty);
      expect(customBoxes.first.columns, equals(3));
      expect(customBoxes.first.rows, equals(4));
      expect(customBoxes.first.capacity, equals(12));
    });
  });
}
