import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';

UserDex _createDex(List<CustomBoxState> boxes) {
  return UserDex(
    id: 'test_dex',
    title: 'Stress Test Dex',
    region: 'kanto',
    includeGenders: false,
    includeRegional: false,
    includeMega: false,
    includeGMax: false,
    includeOther: false,
    isShinyDex: false,
    customBoxes: boxes,
  );
}

CustomBoxState _createBox({
  required String title,
  required List<String> items,
  int columns = 5,
  int rows = 6,
  bool autoShift = true,
  bool strictLimits = true,
  bool patternAutoCreate = true,
  bool autoDeleteEmpty = true,
}) {
  return CustomBoxState(
    title: title,
    pokemonIds: List<String>.from(items),
    columns: columns,
    rows: rows,
    autoShift: autoShift,
    strictLimits: strictLimits,
    patternAutoCreate: patternAutoCreate,
    autoDeleteEmpty: autoDeleteEmpty,
  );
}

void main() {
  group('Challenger M4-1 Stress Suite 1: Multi-Box Shift Cascade & Auto-Deletion', () {
    test('1.1 3-Box Cascade (Test 1, Test 2, Test 3): remove from Test 1 pulls from Test 2, pulls from Test 3, auto-deletes Test 3', () {
      final t1Items = List.generate(30, (i) => 'T1_${i + 1}');
      final t2Items = List.generate(30, (i) => 'T2_${i + 1}');
      final t3Items = ['T3_Single'];

      final box1 = _createBox(title: 'Test 1', items: t1Items);
      final box2 = _createBox(title: 'Test 2', items: t2Items);
      final box3 = _createBox(title: 'Test 3', items: t3Items);

      final dex = _createDex([box1, box2, box3]);

      // Remove from Test 1 at slot 0
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Verify Test 1:
      // T1_1 was removed. T1_2 to T1_30 shifted left. T2_1 pulled into slot 29.
      expect(box1.pokemonIds.length, equals(30));
      expect(box1.pokemonIds[0], equals('T1_2'));
      expect(box1.pokemonIds[28], equals('T1_30'));
      expect(box1.pokemonIds[29], equals('T2_1'));

      // Verify Test 2:
      // T2_1 was pulled into Test 1. T2_2 to T2_30 shifted left. T3_Single pulled into slot 29.
      expect(box2.pokemonIds.length, equals(30));
      expect(box2.pokemonIds[0], equals('T2_2'));
      expect(box2.pokemonIds[28], equals('T2_30'));
      expect(box2.pokemonIds[29], equals('T3_Single'));

      // Verify Test 3:
      // T3_Single was pulled into Test 2. Test 3 became empty and must be auto-deleted.
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[1].title, equals('Test 2'));
    });

    test('1.2 Cascading collapse: repeated removals systematically pull and delete Test 3 and Test 2, preserving root Test 1', () {
      final box1 = _createBox(title: 'Test 1', items: ['A', 'B'], columns: 1, rows: 2);
      final box2 = _createBox(title: 'Test 2', items: ['C', 'D'], columns: 1, rows: 2);
      final box3 = _createBox(title: 'Test 3', items: ['E'], columns: 1, rows: 2);

      final dex = _createDex([box1, box2, box3]);

      // Removal 1: remove 'A' from Test 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      // 'A' removed -> Test 1: ['B', 'C']. Test 2: ['D', 'E']. Test 3 empty -> deleted.
      expect(dex.customBoxes.length, equals(2));
      expect(box1.pokemonIds, equals(['B', 'C']));
      expect(box2.pokemonIds, equals(['D', 'E']));

      // Removal 2: remove 'B' from Test 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      // 'B' removed -> Test 1: ['C', 'D']. Test 2: ['E'].
      expect(dex.customBoxes.length, equals(2));
      expect(box1.pokemonIds, equals(['C', 'D']));
      expect(box2.pokemonIds, equals(['E']));

      // Removal 3: remove 'C' from Test 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      // 'C' removed -> Test 1: ['D', 'E']. Test 2 empty -> deleted!
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, equals(['D', 'E']));

      // Removal 4 & 5: empty root box Test 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      expect(dex.customBoxes[0].pokemonIds, equals(['E']));
      expect(dex.customBoxes.length, equals(1));

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      // Root box emptied: must NEVER be deleted
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, isEmpty);
    });

    test('1.3 5-Box Deep Cascade: removing from Test 1 ripples across all 5 boxes and deletes trailing box', () {
      final boxes = List.generate(5, (i) {
        final count = (i == 4) ? 1 : 4;
        final items = List.generate(count, (j) => 'B${i + 1}_M${j + 1}');
        return _createBox(title: 'Chain ${i + 1}', items: items, columns: 2, rows: 2);
      });

      final dex = _createDex(boxes);

      // Remove from Chain 1 at index 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 1);

      // Chain 1 pulled B2_M1 into slot 3
      expect(boxes[0].pokemonIds, equals(['B1_M1', 'B1_M3', 'B1_M4', 'B2_M1']));
      // Chain 2 pulled B3_M1
      expect(boxes[1].pokemonIds, equals(['B2_M2', 'B2_M3', 'B2_M4', 'B3_M1']));
      // Chain 3 pulled B4_M1
      expect(boxes[2].pokemonIds, equals(['B3_M2', 'B3_M3', 'B3_M4', 'B4_M1']));
      // Chain 4 pulled B5_M1 (the only item in Chain 5)
      expect(boxes[3].pokemonIds, equals(['B4_M2', 'B4_M3', 'B4_M4', 'B5_M1']));
      // Chain 5 emptied -> auto-deleted
      expect(dex.customBoxes.length, equals(4));
      expect(dex.customBoxes.any((b) => b.title == 'Chain 5'), isFalse);
    });

    test('1.4 Pure Range 3-Box Cascade (1-10, 11-20, 21-30)', () {
      final b1 = _createBox(title: '1-10', items: List.generate(10, (i) => 'M_${i + 1}'), columns: 2, rows: 5);
      final b2 = _createBox(title: '11-20', items: List.generate(10, (i) => 'M_${i + 11}'), columns: 2, rows: 5);
      final b3 = _createBox(title: '21-30', items: ['M_21'], columns: 2, rows: 5);

      final dex = _createDex([b1, b2, b3]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(b1.pokemonIds.length, equals(10));
      expect(b1.pokemonIds.last, equals('M_11'));
      expect(b2.pokemonIds.length, equals(10));
      expect(b2.pokemonIds.last, equals('M_21'));
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == '21-30'), isFalse);
    });

    test('1.5 Prefix Range with Parens 3-Box Cascade (Box 1 (1-10), Box 2 (11-20), Box 3 (21-30))', () {
      final b1 = _createBox(title: 'Box 1 (1-10)', items: List.generate(10, (i) => 'P_${i + 1}'), columns: 2, rows: 5);
      final b2 = _createBox(title: 'Box 2 (11-20)', items: List.generate(10, (i) => 'P_${i + 11}'), columns: 2, rows: 5);
      final b3 = _createBox(title: 'Box 3 (21-30)', items: ['P_21'], columns: 2, rows: 5);

      final dex = _createDex([b1, b2, b3]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 5);

      expect(b1.pokemonIds.length, equals(10));
      expect(b1.pokemonIds.last, equals('P_11'));
      expect(b2.pokemonIds.length, equals(10));
      expect(b2.pokemonIds.last, equals('P_21'));
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == 'Box 3 (21-30)'), isFalse);
    });
  });

  group('Challenger M4-1 Stress Suite 2: Rapid & Simultaneous Batch Removals', () {
    test('2.1 Simultaneous batch removal across Test 1, Test 2, and Test 3', () {
      final b1 = _createBox(title: 'Test 1', items: ['A1', 'A2', 'A3'], columns: 1, rows: 3);
      final b2 = _createBox(title: 'Test 2', items: ['B1', 'B2', 'B3'], columns: 1, rows: 3);
      final b3 = _createBox(title: 'Test 3', items: ['C1'], columns: 1, rows: 3);

      final dex = _createDex([b1, b2, b3]);

      // Remove A1 (0_0), B2 (1_1), and C1 (2_0) simultaneously
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: ['0_0', '1_1', '2_0'],
      );

      // Trace:
      // Highest boxIndex first:
      // 1. Box 2, slot 0 (C1): removed. Box 3 emptied -> deleted!
      // 2. Box 1, slot 1 (B2): removed from Test 2. Test 2 was ['B1', 'B2', 'B3'].
      //    Now ['B1', 'B3']. No subsequent boxes to pull from.
      // 3. Box 0, slot 0 (A1): removed from Test 1. Test 1 pulls B1 from Test 2.
      //    Test 1 becomes ['A2', 'A3', 'B1'].
      //    Test 2 becomes ['B3'].
      expect(dex.customBoxes.length, equals(2));
      expect(b1.pokemonIds, equals(['A2', 'A3', 'B1']));
      expect(b2.pokemonIds, equals(['B3']));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);
    });

    test('2.2 Batch removal with reverse order, duplicates, and out-of-order keys', () {
      final b1 = _createBox(title: 'Test 1', items: ['1', '2', '3', '4'], columns: 2, rows: 2);
      final b2 = _createBox(title: 'Test 2', items: ['5', '6'], columns: 2, rows: 2);

      final dex = _createDex([b1, b2]);

      // Shuffle / duplicate keys
      final keys = ['1_1', '0_0', '1_1', '0_2', '1_0', '0_0'];

      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: keys,
      );

      // Removed from b2: 1_1 ('6'), 1_0 ('5') -> b2 completely emptied!
      // Removed from b1: 0_2 ('3'), 0_0 ('1').
      // Remaining in b1: '2' and '4'.
      // b2 was emptied and auto-deleted!
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, equals(['2', '4']));
    });

    test('2.3 Heavy Randomized Batch Removal Stress (4 boxes x 10 items, 25 removals)', () {
      final rng = Random(42);
      const totalBoxes = 4;
      const boxCap = 10;
      final allItems = List.generate(totalBoxes * boxCap, (i) => 'MON_${i + 1}');

      final boxes = List.generate(totalBoxes, (bIdx) {
        final start = bIdx * boxCap;
        return _createBox(
          title: 'Stress ${bIdx + 1}',
          items: allItems.sublist(start, start + boxCap),
          columns: 2,
          rows: 5,
        );
      });

      final dex = _createDex(boxes);

      // Randomly pick 25 distinct targets across the boxes
      final selectedKeys = <String>{};
      while (selectedKeys.length < 25) {
        final b = rng.nextInt(totalBoxes);
        final s = rng.nextInt(boxCap);
        selectedKeys.add('${b}_$s');
      }

      // Record which specific Pokémon IDs should be deleted
      final targetedIds = <String>{};
      for (final key in selectedKeys) {
        final parts = key.split('_');
        final b = int.parse(parts[0]);
        final s = int.parse(parts[1]);
        targetedIds.add(boxes[b].pokemonIds[s]);
      }

      final expectedRemainingIds = allItems.where((id) => !targetedIds.contains(id)).toList();
      expect(expectedRemainingIds.length, equals(15));

      // Execute batch removal
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: selectedKeys.toList(),
      );

      // Verify dex state:
      // Total remaining items must be exactly 15
      final actualRemainingIds = <String>[];
      for (final box in dex.customBoxes) {
        actualRemainingIds.addAll(box.pokemonIds.where((id) => id.isNotEmpty));
      }
      expect(actualRemainingIds.length, equals(15));
      expect(actualRemainingIds, equals(expectedRemainingIds),
          reason: 'All remaining Pokémon must maintain exact relative order without gaps');

      // 15 items in capacity-10 boxes must occupy exactly ceil(15/10) = 2 boxes
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[0].pokemonIds.length, equals(10));
      expect(dex.customBoxes[1].pokemonIds.length, equals(5));
      expect(dex.customBoxes.any((b) => b.title == 'Stress 3'), isFalse);
      expect(dex.customBoxes.any((b) => b.title == 'Stress 4'), isFalse);
    });

    test('2.4 Batch removal with empty slots ("") does not corrupt indices or pull empty strings', () {
      final b1 = _createBox(title: 'Test 1', items: ['A', '', 'B'], columns: 1, rows: 3);
      final b2 = _createBox(title: 'Test 2', items: ['', 'C', 'D'], columns: 1, rows: 3);

      final dex = _createDex([b1, b2]);

      // Remove slot 0 ('A') from Test 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // 'A' removed. b1 shifts left -> ['', 'B'].
      // Then cascade looks for first NON-EMPTY item in b2 -> finds 'C' at index 1!
      // 'C' is pulled into b1.
      // b2 now has ['', 'D'].
      expect(b1.pokemonIds, equals(['', 'B', 'C']));
      expect(b2.pokemonIds, equals(['', 'D']));
    });
  });

  group('Challenger M4-1 Stress Suite 3: Non-Sequence Boxes Strict Isolation', () {
    test('3.1 Interleaved sequence and non-sequence boxes preserve isolation during multi-box cascade', () {
      final t1 = _createBox(title: 'Test 1', items: ['T1_A', 'T1_B'], columns: 1, rows: 2);
      final kantoTausch = _createBox(title: 'Kanto Tausch', items: ['KT_1', 'KT_2'], columns: 1, rows: 2);
      final t2 = _createBox(title: 'Test 2', items: ['T2_A', 'T2_B'], columns: 1, rows: 2);
      final unrelated = _createBox(title: 'Unrelated Box', items: ['U_1', 'U_2'], columns: 1, rows: 2);
      final t3 = _createBox(title: 'Test 3', items: ['T3_Single'], columns: 1, rows: 2);

      // Order in dex: [Test 1, Kanto Tausch, Test 2, Unrelated Box, Test 3]
      final dex = _createDex([t1, kantoTausch, t2, unrelated, t3]);

      // Remove T1_A (index 0) from Test 1 (box index 0)
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Cascade must skip Kanto Tausch and Unrelated Box:
      // Test 1: ['T1_B', 'T2_A']
      expect(t1.pokemonIds, equals(['T1_B', 'T2_A']));

      // Test 2: ['T2_B', 'T3_Single']
      expect(t2.pokemonIds, equals(['T2_B', 'T3_Single']));

      // Test 3 emptied -> deleted!
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);

      // Kanto Tausch must be 100% untouched
      expect(kantoTausch.pokemonIds, equals(['KT_1', 'KT_2']));

      // Unrelated Box must be 100% untouched
      expect(unrelated.pokemonIds, equals(['U_1', 'U_2']));

      // Remaining boxes: [Test 1, Kanto Tausch, Test 2, Unrelated Box]
      expect(dex.customBoxes.length, equals(4));
      expect(dex.customBoxes.map((b) => b.title).toList(),
          equals(['Test 1', 'Kanto Tausch', 'Test 2', 'Unrelated Box']));
    });

    test('3.2 Removal from Standalone Box closes internal gap and never pulls from sequence boxes or deletes standalone box', () {
      final kantoTausch = _createBox(title: 'Kanto Tausch', items: ['KT_1', 'KT_2', 'KT_3'], columns: 1, rows: 3);
      final kanto1 = _createBox(title: 'Kanto 1', items: ['K1_1', 'K1_2'], columns: 1, rows: 2);

      final dex = _createDex([kantoTausch, kanto1]);

      // Remove KT_2 from Kanto Tausch
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 1);

      // Kanto Tausch gap closed
      expect(kantoTausch.pokemonIds, equals(['KT_1', 'KT_3']));
      // Kanto 1 completely untouched
      expect(kanto1.pokemonIds, equals(['K1_1', 'K1_2']));

      // Remove remaining items from Kanto Tausch until empty
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Standalone box emptied: must NEVER be auto-deleted!
      expect(kantoTausch.pokemonIds, isEmpty);
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[0].title, equals('Kanto Tausch'));
      expect(dex.customBoxes[1].title, equals('Kanto 1'));
    });

    test('3.3 Simultaneous batch removal across both sequence boxes and non-sequence boxes', () {
      final t1 = _createBox(title: 'Test 1', items: ['T1_1', 'T1_2'], columns: 1, rows: 2);
      final standalone = _createBox(title: 'Unrelated Box', items: ['U_1', 'U_2'], columns: 1, rows: 2);
      final t2 = _createBox(title: 'Test 2', items: ['T2_1'], columns: 1, rows: 2);

      final dex = _createDex([t1, standalone, t2]);

      // Batch remove T1_1 (0_0), U_1 (1_0), and T2_1 (2_0)
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: ['0_0', '1_0', '2_0'],
      );

      // 1. Box 2 (Test 2, slot 0): removed T2_1. Test 2 empty -> deleted!
      // 2. Box 1 (Unrelated Box, slot 0): removed U_1. Unrelated Box: ['U_2'].
      // 3. Box 0 (Test 1, slot 0): removed T1_1. No items left in Test 2. Test 1: ['T1_2'].
      expect(dex.customBoxes.length, equals(2));
      expect(t1.pokemonIds, equals(['T1_2']));
      expect(standalone.pokemonIds, equals(['U_2']));
      expect(dex.customBoxes.any((b) => b.title == 'Test 2'), isFalse);
    });
  });
}
