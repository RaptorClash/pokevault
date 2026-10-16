import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';

UserDex _createDex(List<CustomBoxState> boxes) {
  return UserDex(
    id: 'it3_stress_dex',
    title: 'Iteration 3 Challenger Dex',
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
  group('Challenger M4-1 Iteration 3 - Task 1: Multi-Box Cascade & Auto-Deletion Stress', () {
    test('1.1: Classic 3-box cascade ("Test 1", "Test 2", "Test 3") with sizes 30, 30, 1 from slot 0', () {
      final t1 = List.generate(30, (i) => 'T1_${i + 1}');
      final t2 = List.generate(30, (i) => 'T2_${i + 1}');
      final t3 = ['T3_TAIL'];

      final box1 = _createBox(title: 'Test 1', items: t1);
      final box2 = _createBox(title: 'Test 2', items: t2);
      final box3 = _createBox(title: 'Test 3', items: t3);
      final dex = _createDex([box1, box2, box3]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Verify Test 1:
      // T1_1 removed, T1_2..T1_30 shifted left to indices 0..28, slot 29 gets T2_1
      expect(box1.pokemonIds.length, equals(30));
      expect(box1.pokemonIds[0], equals('T1_2'));
      expect(box1.pokemonIds[28], equals('T1_30'));
      expect(box1.pokemonIds[29], equals('T2_1'));

      // Verify Test 2:
      // T2_1 pulled into Test 1, T2_2..T2_30 shifted left to indices 0..28, slot 29 gets T3_TAIL
      expect(box2.pokemonIds.length, equals(30));
      expect(box2.pokemonIds[0], equals('T2_2'));
      expect(box2.pokemonIds[28], equals('T2_30'));
      expect(box2.pokemonIds[29], equals('T3_TAIL'));

      // Verify Test 3:
      // Emptied and auto-deleted
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[1].title, equals('Test 2'));
    });

    test('1.2: Middle-slot deletion in 3-box cascade ("Test 1" slot 14 in a 30-item box)', () {
      final t1 = List.generate(30, (i) => 'T1_${i + 1}');
      final t2 = List.generate(30, (i) => 'T2_${i + 1}');
      final t3 = ['T3_TAIL'];

      final box1 = _createBox(title: 'Test 1', items: t1);
      final box2 = _createBox(title: 'Test 2', items: t2);
      final box3 = _createBox(title: 'Test 3', items: t3);
      final dex = _createDex([box1, box2, box3]);

      // Remove item at slot 14 ('T1_15')
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 14);

      // Verify Test 1:
      // 0..13 undisturbed ('T1_1'..'T1_14')
      for (int i = 0; i < 14; i++) {
        expect(box1.pokemonIds[i], equals('T1_${i + 1}'));
      }
      // 14..28 shifted left ('T1_16'..'T1_30')
      expect(box1.pokemonIds[14], equals('T1_16'));
      expect(box1.pokemonIds[28], equals('T1_30'));
      // 29 received T2_1
      expect(box1.pokemonIds[29], equals('T2_1'));

      // Verify Test 2:
      expect(box2.pokemonIds.length, equals(30));
      expect(box2.pokemonIds[0], equals('T2_2'));
      expect(box2.pokemonIds[29], equals('T3_TAIL'));

      // Verify Test 3 deleted
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);
    });

    test('1.3: End-slot deletion in 3-box cascade ("Test 1" slot 29 in a 30-item box)', () {
      final t1 = List.generate(30, (i) => 'T1_${i + 1}');
      final t2 = List.generate(30, (i) => 'T2_${i + 1}');
      final t3 = ['T3_TAIL'];

      final box1 = _createBox(title: 'Test 1', items: t1);
      final box2 = _createBox(title: 'Test 2', items: t2);
      final box3 = _createBox(title: 'Test 3', items: t3);
      final dex = _createDex([box1, box2, box3]);

      // Remove slot 29 ('T1_30')
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 29);

      // Verify Test 1:
      // 0..28 undisturbed
      for (int i = 0; i < 29; i++) {
        expect(box1.pokemonIds[i], equals('T1_${i + 1}'));
      }
      // Slot 29 received T2_1
      expect(box1.pokemonIds[29], equals('T2_1'));

      // Verify Test 2:
      expect(box2.pokemonIds[0], equals('T2_2'));
      expect(box2.pokemonIds[29], equals('T3_TAIL'));

      // Verify Test 3 deleted
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);
    });

    test('1.4: Cascading double deletion: 3 boxes collapse progressively down to root Test 1', () {
      final box1 = _createBox(title: 'Test 1', items: ['A', 'B'], columns: 1, rows: 2);
      final box2 = _createBox(title: 'Test 2', items: ['C'], columns: 1, rows: 2);
      final box3 = _createBox(title: 'Test 3', items: ['D'], columns: 1, rows: 2);
      final dex = _createDex([box1, box2, box3]);

      // Remove 'A' (slot 0) from Test 1
      // Test 1: 'A' removed -> pulls 'C' from Test 2. Test 1 has ['B', 'C'].
      // Test 2: 'C' removed -> pulls 'D' from Test 3. Test 2 has ['D'].
      // Test 3: emptied -> deleted!
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(dex.customBoxes.length, equals(2));
      expect(box1.pokemonIds, equals(['B', 'C']));
      expect(box2.pokemonIds, equals(['D']));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);

      // Remove 'B' (slot 0) from Test 1
      // Test 1: 'B' removed -> pulls 'D' from Test 2. Test 1 has ['C', 'D'].
      // Test 2: emptied -> deleted!
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, equals(['C', 'D']));

      // Empty root box Test 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Root box must NEVER be deleted even when completely empty
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, isEmpty);
    });

    test('1.5: Deep 10-box cascade chain ("Test 1" .. "Test 10", 5 items each, Test 10 has 1 item)', () {
      final boxes = List.generate(10, (i) {
        final count = (i == 9) ? 1 : 5;
        final items = List.generate(count, (j) => 'B${i + 1}_$j');
        return _createBox(title: 'Test ${i + 1}', items: items, columns: 1, rows: 5);
      });
      final dex = _createDex(boxes);

      // Total items: 9 * 5 + 1 = 46 items.
      // Remove slot 0 from Test 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Verify ripple across all 10 boxes:
      for (int i = 0; i < 9; i++) {
        expect(boxes[i].pokemonIds.length, equals(5));
        // Last slot of box i should be first item of box i+1
        expect(boxes[i].pokemonIds.last, equals('B${i + 2}_0'));
      }

      // Box 10 had only B10_0, which was pulled into Box 9 -> Box 10 emptied and deleted!
      expect(dex.customBoxes.length, equals(9));
      expect(dex.customBoxes.any((b) => b.title == 'Test 10'), isFalse);
    });

    test('1.6: Heterogeneous capacities across linked sequence (Test 1 cap 10, Test 2 cap 20, Test 3 cap 5)', () {
      final b1 = _createBox(title: 'Test 1', items: List.generate(10, (i) => 'T1_$i'), columns: 2, rows: 5);
      final b2 = _createBox(title: 'Test 2', items: List.generate(20, (i) => 'T2_$i'), columns: 4, rows: 5);
      final b3 = _createBox(title: 'Test 3', items: ['T3_SINGLE'], columns: 1, rows: 5);
      final dex = _createDex([b1, b2, b3]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(b1.pokemonIds.length, equals(10));
      expect(b1.pokemonIds.last, equals('T2_0'));
      expect(b2.pokemonIds.length, equals(20));
      expect(b2.pokemonIds.last, equals('T3_SINGLE'));
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);
    });

    test('1.7: Disabled autoDeleteEmpty flag preserves emptied linked box', () {
      final b1 = _createBox(title: 'Test 1', items: ['A', 'B'], columns: 1, rows: 2);
      final b2 = _createBox(title: 'Test 2', items: ['C'], columns: 1, rows: 2, autoDeleteEmpty: false);
      final dex = _createDex([b1, b2]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // 'A' removed -> 'C' pulled into Test 1. Test 2 is empty but autoDeleteEmpty is false!
      expect(dex.customBoxes.length, equals(2));
      expect(b1.pokemonIds, equals(['B', 'C']));
      expect(b2.pokemonIds, isEmpty);
      expect(dex.customBoxes[1].title, equals('Test 2'));
    });
  });

  group('Challenger M4-1 Iteration 3 - Task 2: Rapid & Simultaneous Batch Removals', () {
    test('2.1: Simultaneous deletion of targets in all 3 sequence boxes ("0_0", "1_10", "2_0")', () {
      final t1 = List.generate(20, (i) => 'A_$i');
      final t2 = List.generate(20, (i) => 'B_$i');
      final t3 = ['C_0'];

      final box1 = _createBox(title: 'Test 1', items: t1, columns: 4, rows: 5);
      final box2 = _createBox(title: 'Test 2', items: t2, columns: 4, rows: 5);
      final box3 = _createBox(title: 'Test 3', items: t3, columns: 4, rows: 5);
      final dex = _createDex([box1, box2, box3]);

      // Batch remove A_0 ('0_0'), B_10 ('1_10'), C_0 ('2_0')
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: ['0_0', '1_10', '2_0'],
      );

      // C_0 was removed, Test 3 deleted!
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);

      // Total items remaining: 20 + 20 + 1 - 3 = 38 items.
      final totalRemaining = box1.pokemonIds.length + box2.pokemonIds.length;
      expect(totalRemaining, equals(38));

      // A_0, B_10, and C_0 must not exist in any box
      final allRemaining = [...box1.pokemonIds, ...box2.pokemonIds];
      expect(allRemaining.contains('A_0'), isFalse);
      expect(allRemaining.contains('B_10'), isFalse);
      expect(allRemaining.contains('C_0'), isFalse);
    });

    test('2.2: Batch removal of ALL items in Test 2 and Test 3 in a single call', () {
      final b1 = _createBox(title: 'Test 1', items: ['A1', 'A2'], columns: 1, rows: 2);
      final b2 = _createBox(title: 'Test 2', items: ['B1', 'B2'], columns: 1, rows: 2);
      final b3 = _createBox(title: 'Test 3', items: ['C1'], columns: 1, rows: 2);
      final dex = _createDex([b1, b2, b3]);

      // Remove B1, B2, C1
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: ['1_0', '1_1', '2_0'],
      );

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, equals(['A1', 'A2']));
    });

    test('2.3: Batch removal with out-of-order, duplicated, and invalid keys', () {
      final b1 = _createBox(title: 'Test 1', items: ['A', 'B', 'C'], columns: 1, rows: 3);
      final b2 = _createBox(title: 'Test 2', items: ['D', 'E'], columns: 1, rows: 3);
      final dex = _createDex([b1, b2]);

      final keys = [
        '1_1', // E
        '0_0', // A
        '1_1', // duplicate
        '99_99', // out of bounds box
        '-1_0', // negative box
        'invalid', // unparseable
        '0_99', // out of bounds slot
        '0_2', // C
      ];

      BoxSequenceManager.batchRemoveWithShiftBack(dex: dex, selectedKeys: keys);

      // E, A, C removed. Remaining: B, D.
      // D is pulled into Test 1. Test 2 becomes empty and is deleted!
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, equals(['B', 'D']));
    });

    test('2.4: Randomized property-based fuzz testing (50 iterations)', () {
      final rng = Random(12345);

      for (int iter = 0; iter < 50; iter++) {
        final boxCount = rng.nextInt(4) + 3; // 3 to 6 boxes
        final boxCap = rng.nextInt(6) + 4; // 4 to 9 capacity
        final totalItems = (boxCount - 1) * boxCap + (rng.nextInt(boxCap) + 1);

        final allItems = List.generate(totalItems, (i) => 'ITEM_${iter}_$i');

        final boxes = <CustomBoxState>[];
        int itemCursor = 0;
        for (int b = 0; b < boxCount; b++) {
          final countInBox = min(boxCap, totalItems - itemCursor);
          final items = allItems.sublist(itemCursor, itemCursor + countInBox);
          itemCursor += countInBox;
          boxes.add(_createBox(
            title: 'Test ${b + 1}',
            items: items,
            columns: 1,
            rows: boxCap,
          ));
        }

        final dex = _createDex(boxes);

        // Pick random number of items to delete (between 1 and totalItems - 1)
        final deleteCount = rng.nextInt(totalItems - 1) + 1;
        final selectedKeys = <String>{};
        final deletedItems = <String>{};

        while (selectedKeys.length < deleteCount) {
          final b = rng.nextInt(boxes.length);
          if (boxes[b].pokemonIds.isEmpty) continue;
          final s = rng.nextInt(boxes[b].pokemonIds.length);
          final key = '${b}_$s';
          if (!selectedKeys.contains(key)) {
            selectedKeys.add(key);
            deletedItems.add(boxes[b].pokemonIds[s]);
          }
        }

        final expectedRemainingItems = allItems.where((id) => !deletedItems.contains(id)).toList();

        // Execute batch removal
        BoxSequenceManager.batchRemoveWithShiftBack(
          dex: dex,
          selectedKeys: selectedKeys.toList(),
        );

        // Verify Oracle Invariants:
        final actualRemainingItems = <String>[];
        for (final box in dex.customBoxes) {
          actualRemainingItems.addAll(box.pokemonIds.where((id) => id.isNotEmpty));
        }

        // Invariant 1: Total items count
        expect(actualRemainingItems.length, equals(expectedRemainingItems.length),
            reason: 'Iter $iter: total remaining items count mismatch');

        // Invariant 2: Relative order and content preservation
        expect(actualRemainingItems, equals(expectedRemainingItems),
            reason: 'Iter $iter: item order or content corrupted');

        // Invariant 3: Root box preservation
        expect(dex.customBoxes.isNotEmpty, isTrue,
            reason: 'Iter $iter: dex must never have 0 boxes');
        expect(dex.customBoxes.first.title, equals('Test 1'),
            reason: 'Iter $iter: root box Test 1 must always be preserved');

        // Invariant 4: No empty boxes retained (except potentially root box if all deleted)
        for (int i = 1; i < dex.customBoxes.length; i++) {
          final box = dex.customBoxes[i];
          final hasItems = box.pokemonIds.any((id) => id.isNotEmpty);
          expect(hasItems, isTrue,
              reason: 'Iter $iter: box ${box.title} at index $i is empty but was not deleted');
        }
      }
    });
  });

  group('Challenger M4-1 Iteration 3 - Task 3: Non-Sequence Boxes Strict Isolation', () {
    test('3.1: Interleaved sequence and non-sequence boxes preserve 100% isolation', () {
      final t1 = _createBox(title: 'Test 1', items: ['T1_1', 'T1_2'], columns: 1, rows: 2);
      final kantoTausch = _createBox(title: 'Kanto Tausch', items: ['KT_1', 'KT_2'], columns: 1, rows: 2);
      final t2 = _createBox(title: 'Test 2', items: ['T2_1', 'T2_2'], columns: 1, rows: 2);
      final unrelated = _createBox(title: 'Unrelated Box', items: ['U_1', 'U_2'], columns: 1, rows: 2);
      final t3 = _createBox(title: 'Test 3', items: ['T3_ONLY'], columns: 1, rows: 2);

      // Order in dex: [Test 1, Kanto Tausch, Test 2, Unrelated Box, Test 3]
      final dex = _createDex([t1, kantoTausch, t2, unrelated, t3]);

      // Remove from Test 1 (box index 0, slot 0)
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Cascade must pull strictly Test 2 -> Test 1, Test 3 -> Test 2, and delete Test 3
      expect(t1.pokemonIds, equals(['T1_2', 'T2_1']));
      expect(t2.pokemonIds, equals(['T2_2', 'T3_ONLY']));
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);

      // Kanto Tausch must be completely untouched
      expect(kantoTausch.pokemonIds, equals(['KT_1', 'KT_2']));

      // Unrelated Box must be completely untouched
      expect(unrelated.pokemonIds, equals(['U_1', 'U_2']));

      // Remaining boxes order
      expect(dex.customBoxes.map((b) => b.title).toList(),
          equals(['Test 1', 'Kanto Tausch', 'Test 2', 'Unrelated Box']));
    });

    test('3.2: Removal inside "Kanto Tausch" closes internal gap and never pulls from sequence boxes or deletes box', () {
      final kantoTausch = _createBox(title: 'Kanto Tausch', items: ['KT_1', 'KT_2', 'KT_3'], columns: 1, rows: 3);
      final kanto1 = _createBox(title: 'Kanto 1', items: ['K1_1', 'K1_2'], columns: 1, rows: 2);
      final kanto2 = _createBox(title: 'Kanto 2', items: ['K2_1'], columns: 1, rows: 2);
      final dex = _createDex([kantoTausch, kanto1, kanto2]);

      // Remove KT_2 (slot 1) from Kanto Tausch
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 1);

      // Internal gap closed
      expect(kantoTausch.pokemonIds, equals(['KT_1', 'KT_3']));
      // Kanto 1 and Kanto 2 completely untouched
      expect(kanto1.pokemonIds, equals(['K1_1', 'K1_2']));
      expect(kanto2.pokemonIds, equals(['K2_1']));

      // Completely empty Kanto Tausch
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Standalone box emptied: must NEVER be deleted!
      expect(kantoTausch.pokemonIds, isEmpty);
      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes[0].title, equals('Kanto Tausch'));
      expect(dex.customBoxes[1].title, equals('Kanto 1'));
      expect(dex.customBoxes[2].title, equals('Kanto 2'));
    });

    test('3.3: Removal inside "Unrelated Box" closes gap and never deletes box when empty', () {
      final unrelated = _createBox(title: 'Unrelated Box', items: ['U_1'], columns: 1, rows: 2);
      final test1 = _createBox(title: 'Test 1', items: ['T_1', 'T_2'], columns: 1, rows: 2);
      final dex = _createDex([unrelated, test1]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(unrelated.pokemonIds, isEmpty);
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[0].title, equals('Unrelated Box'));
      expect(test1.pokemonIds, equals(['T_1', 'T_2']));
    });

    test('3.4: Simultaneous batch removal targeting sequence boxes AND standalone boxes', () {
      final t1 = _createBox(title: 'Test 1', items: ['T1_1', 'T1_2'], columns: 1, rows: 2);
      final kantoTausch = _createBox(title: 'Kanto Tausch', items: ['KT_1', 'KT_2'], columns: 1, rows: 2);
      final t2 = _createBox(title: 'Test 2', items: ['T2_1'], columns: 1, rows: 2);
      final unrelated = _createBox(title: 'Unrelated Box', items: ['U_1', 'U_2'], columns: 1, rows: 2);
      final dex = _createDex([t1, kantoTausch, t2, unrelated]);

      // Remove T1_1 ('0_0'), KT_1 ('1_0'), T2_1 ('2_0'), U_2 ('3_1')
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: ['0_0', '1_0', '2_0', '3_1'],
      );

      // T2_1 removed -> Test 2 emptied and deleted!
      expect(dex.customBoxes.any((b) => b.title == 'Test 2'), isFalse);

      // T1_1 removed -> no subsequent sequence items left in Test 2 -> Test 1: ['T1_2']
      expect(t1.pokemonIds, equals(['T1_2']));

      // Kanto Tausch: KT_1 removed -> ['KT_2']
      expect(kantoTausch.pokemonIds, equals(['KT_2']));

      // Unrelated Box: U_2 removed -> ['U_1']
      expect(unrelated.pokemonIds, equals(['U_1']));

      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes.map((b) => b.title).toList(),
          equals(['Test 1', 'Kanto Tausch', 'Unrelated Box']));
    });

    test('3.5: Multiple distinct sequences alongside standalone boxes never cross-pollinate', () {
      final kanto1 = _createBox(title: 'Kanto 1', items: ['K1_1', 'K1_2'], columns: 1, rows: 2);
      final kanto2 = _createBox(title: 'Kanto 2', items: ['K2_1'], columns: 1, rows: 2);
      final kantoTausch = _createBox(title: 'Kanto Tausch', items: ['KT_1'], columns: 1, rows: 2);
      final johto1 = _createBox(title: 'Johto 1', items: ['J1_1', 'J1_2'], columns: 1, rows: 2);
      final johto2 = _createBox(title: 'Johto 2', items: ['J2_1'], columns: 1, rows: 2);
      final range1 = _createBox(title: '1-10', items: ['R1_1', 'R1_2'], columns: 1, rows: 2);
      final range2 = _createBox(title: '11-20', items: ['R2_1'], columns: 1, rows: 2);
      final unrelated = _createBox(title: 'Unrelated Box', items: ['U_1'], columns: 1, rows: 2);

      final dex = _createDex([
        kanto1,
        kanto2,
        kantoTausch,
        johto1,
        johto2,
        range1,
        range2,
        unrelated,
      ]);

      // Remove from Kanto 1 -> pulls from Kanto 2, deletes Kanto 2
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(kanto1.pokemonIds, equals(['K1_2', 'K2_1']));
      expect(dex.customBoxes.any((b) => b.title == 'Kanto 2'), isFalse);

      // Verify all other sequences and standalone boxes untouched:
      expect(kantoTausch.pokemonIds, equals(['KT_1']));
      expect(johto1.pokemonIds, equals(['J1_1', 'J1_2']));
      expect(johto2.pokemonIds, equals(['J2_1']));
      expect(range1.pokemonIds, equals(['R1_1', 'R1_2']));
      expect(range2.pokemonIds, equals(['R2_1']));
      expect(unrelated.pokemonIds, equals(['U_1']));

      // Remove from Johto 1 -> pulls from Johto 2, deletes Johto 2
      final johto1Idx = dex.customBoxes.indexOf(johto1);
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: johto1Idx, slotIndex: 0);

      expect(johto1.pokemonIds, equals(['J1_2', 'J2_1']));
      expect(dex.customBoxes.any((b) => b.title == 'Johto 2'), isFalse);
      expect(range1.pokemonIds, equals(['R1_1', 'R1_2']));
      expect(range2.pokemonIds, equals(['R2_1']));
    });
  });
}
