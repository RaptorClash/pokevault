import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import '../e2e/helpers/e2e_test_helper.dart';

void main() {
  group('BoxSequenceManager - swapPokemon & swapPokemonByIndices', () {
    test('1:1 swap within the same box swaps exact positions without shifting other items', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['A', 'B', 'C', 'D', 'E'],
          ),
        ],
      );

      // Swap 'A' (slot 0) with slot 3 ('D')
      BoxSequenceManager.swapPokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 0,
        targetSlotIndex: 3,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['D', 'B', 'C', 'A', 'E']));
    });

    test('1:1 swap with empty slot exchanges pokemon and empty slot', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['A', 'B', '', 'D'],
          ),
        ],
      );

      // Swap 'B' (slot 1) with slot 2 ('')
      BoxSequenceManager.swapPokemon(
        dex: dex,
        sourceId: 'B',
        targetBoxIndex: 0,
        targetSlotIndex: 2,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['A', '', 'B', 'D']));
    });

    test('1:1 swap across different boxes exchanges items correctly', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['A1', 'A2', 'A3'],
          ),
          createTestCustomBox(
            title: 'Box 2',
            pokemonIds: ['B1', 'B2', 'B3'],
          ),
        ],
      );

      // Swap 'A1' (box 0, slot 0) with Box 2 slot 2 ('B3')
      BoxSequenceManager.swapPokemon(
        dex: dex,
        sourceId: 'A1',
        targetBoxIndex: 1,
        targetSlotIndex: 2,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['B3', 'A2', 'A3']));
      expect(dex.customBoxes[1].pokemonIds, equals(['B1', 'B2', 'A1']));
    });

    test('swap with same slot is a strict no-op', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['A', 'B', 'C'],
          ),
        ],
      );

      BoxSequenceManager.swapPokemon(
        dex: dex,
        sourceId: 'B',
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'B', 'C']));
    });

    test('swap with nonexistent sourceId is gracefully handled as no-op', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['A', 'B', 'C'],
          ),
        ],
      );

      BoxSequenceManager.swapPokemon(
        dex: dex,
        sourceId: 'NONEXISTENT',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'B', 'C']));
    });

    test('swap with invalid target box or negative target slot is no-op', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['A', 'B', 'C'],
          ),
        ],
      );

      BoxSequenceManager.swapPokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 99,
        targetSlotIndex: 0,
      );
      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'B', 'C']));

      BoxSequenceManager.swapPokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 0,
        targetSlotIndex: -1,
      );
      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'B', 'C']));
    });
  });

  group('BoxSequenceManager - moveMultiplePokemon', () {
    test('Intra-box forward move moves block contiguously', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['P1', 'P2', 'P3', 'P4', 'P5'],
          ),
        ],
      );

      // Move ['P1', 'P2'] to slot 4 (after P4)
      BoxSequenceManager.moveMultiplePokemon(
        dex: dex,
        sourceIds: ['P1', 'P2'],
        targetBoxIndex: 0,
        targetSlotIndex: 4,
      );

      // Remaining items were ['P3', 'P4', 'P5']. Target slot adjusted for removed count (2) => slot 2.
      // So block inserted at slot 2 => ['P3', 'P4', 'P1', 'P2', 'P5']
      expect(dex.customBoxes[0].pokemonIds, equals(['P3', 'P4', 'P1', 'P2', 'P5']));
    });

    test('Intra-box backward move moves block to beginning', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['P1', 'P2', 'P3', 'P4', 'P5'],
          ),
        ],
      );

      // Move ['P4', 'P5'] to slot 0
      BoxSequenceManager.moveMultiplePokemon(
        dex: dex,
        sourceIds: ['P4', 'P5'],
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['P4', 'P5', 'P1', 'P2', 'P3']));
    });

    test('Cross-box block move removes from source and inserts at slot in target', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Source Box',
            pokemonIds: ['A1', 'A2', 'A3', 'A4'],
          ),
          createTestCustomBox(
            title: 'Target Box',
            pokemonIds: ['B1', 'B2'],
          ),
        ],
      );

      // Move ['A2', 'A3'] to Target Box at slot 1
      BoxSequenceManager.moveMultiplePokemon(
        dex: dex,
        sourceIds: ['A2', 'A3'],
        targetBoxIndex: 1,
        targetSlotIndex: 1,
      );

      // Source box has A2, A3 removed and shifts back
      expect(dex.customBoxes[0].pokemonIds, equals(['A1', 'A4']));
      // Target box has ['B1', 'A2', 'A3', 'B2']
      expect(dex.customBoxes[1].pokemonIds, equals(['B1', 'A2', 'A3', 'B2']));
    });

    test('Cross-box block move with null targetSlotIndex appends to end', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Source Box',
            pokemonIds: ['A1', 'A2', 'A3'],
          ),
          createTestCustomBox(
            title: 'Target Box',
            pokemonIds: ['B1', 'B2'],
          ),
        ],
      );

      BoxSequenceManager.moveMultiplePokemon(
        dex: dex,
        sourceIds: ['A1', 'A2'],
        targetBoxIndex: 1,
        targetSlotIndex: null,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['A3']));
      expect(dex.customBoxes[1].pokemonIds, equals(['B1', 'B2', 'A1', 'A2']));
    });

    test('Cross-box block move triggers overflow and creates next sequence box when capacity is exceeded', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Source',
            pokemonIds: ['S1', 'S2', 'S3'],
            columns: 2,
            rows: 2, // cap 4
          ),
          createTestCustomBox(
            title: 'Kanto 1',
            pokemonIds: ['K1', 'K2', 'K3'],
            columns: 2,
            rows: 2, // cap 4
            strictLimits: true,
            patternAutoCreate: true,
          ),
        ],
      );

      // Move 3 items ['S1', 'S2', 'S3'] into 'Kanto 1' (index 1) at slot 0
      // Kanto 1 had 3 items. After adding 3, total 6 items. Capacity is 4.
      // Kanto 1 keeps 4, next 2 overflow to newly auto-created 'Kanto 2'!
      BoxSequenceManager.moveMultiplePokemon(
        dex: dex,
        sourceIds: ['S1', 'S2', 'S3'],
        targetBoxIndex: 1,
        targetSlotIndex: 0,
      );

      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes[0].title, equals('Source'));
      expect(dex.customBoxes[0].pokemonIds, isEmpty);

      expect(dex.customBoxes[1].title, equals('Kanto 1'));
      expect(dex.customBoxes[1].pokemonIds.length, equals(4));
      expect(dex.customBoxes[1].pokemonIds, equals(['S1', 'S2', 'S3', 'K1']));

      expect(dex.customBoxes[2].title, equals('Kanto 2'));
      expect(dex.customBoxes[2].pokemonIds, equals(['K2', 'K3']));
    });

    test('Moving empty list of IDs is a safe no-op', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['A', 'B'],
          ),
        ],
      );

      BoxSequenceManager.moveMultiplePokemon(
        dex: dex,
        sourceIds: [],
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'B']));
    });

    test('Cross-box move emptying an overflow box triggers cleanupEmptyBoxes', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Kanto 1',
            pokemonIds: ['K1', 'K2'],
            columns: 2,
            rows: 1, // cap 2
          ),
          createTestCustomBox(
            title: 'Kanto 2',
            pokemonIds: ['K3'],
            columns: 2,
            rows: 1,
            autoDeleteEmpty: true,
          ),
          createTestCustomBox(
            title: 'Other',
            pokemonIds: ['O1'],
          ),
        ],
      );

      // Move 'K3' from 'Kanto 2' into 'Other'
      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'K3',
        targetBoxIndex: 2,
        targetSlotIndex: 0,
      );

      // 'Kanto 2' became empty and should have been automatically cleaned up
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.map((b) => b.title), equals(['Kanto 1', 'Other']));
      expect(dex.customBoxes[1].pokemonIds, equals(['K3', 'O1']));
    });

    test('Cross-box move with autoShift = false in source box blanks slot without shifting', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Source Box',
            pokemonIds: ['A', 'B', 'C'],
            autoShift: false,
          ),
          createTestCustomBox(
            title: 'Target Box',
            pokemonIds: ['T1', 'T2'],
          ),
        ],
      );

      // Move 'B' from Source to Target
      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'B',
        targetBoxIndex: 1,
        targetSlotIndex: 0,
      );

      // Source box slot 1 is blanked, not shifted
      expect(dex.customBoxes[0].pokemonIds, equals(['A', '', 'C']));
      // Target box has 'B' inserted at 0
      expect(dex.customBoxes[1].pokemonIds, equals(['B', 'T1', 'T2']));
    });

    test('moveMultiplePokemon resolves base IDs when customBoxes has composite timestamp suffixes', () {
      final dex = createTestUserDex(
        customBoxes: [
          createTestCustomBox(
            title: 'Box 1',
            pokemonIds: ['1_normal__1728000000_0', '2_normal__1728000000_1', '3_normal__1728000000_2'],
          ),
          createTestCustomBox(
            title: 'Box 2',
            pokemonIds: ['4_normal__1728000000_3'],
          ),
        ],
      );

      // Caller passes base IDs '1_normal' and '2_normal'
      BoxSequenceManager.moveMultiplePokemon(
        dex: dex,
        sourceIds: ['1_normal', '2_normal'],
        targetBoxIndex: 1,
        targetSlotIndex: 0,
      );

      // Successfully resolved and moved to Box 2
      expect(dex.customBoxes[0].pokemonIds, equals(['3_normal__1728000000_2']));
      expect(dex.customBoxes[1].pokemonIds, equals(['1_normal__1728000000_0', '2_normal__1728000000_1', '4_normal__1728000000_3']));
    });
  });
}
