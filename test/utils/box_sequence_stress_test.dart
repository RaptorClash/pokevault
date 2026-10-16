import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';

UserDex createStressDex({required List<CustomBoxState> boxes}) {
  return UserDex(
    id: 'stress_dex',
    title: 'Stress Dex',
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

void main() {
  group('Empirical Stress Testing — Scenario 1: Deep Cascades (5+ & 10 Boxes)', () {
    test('1.1 Deep cascade: 5 full boxes (150 items) cascade across all 5 boxes and auto-create Box 6', () {
      final boxes = List.generate(5, (bIdx) {
        final boxNum = bIdx + 1;
        final items = List.generate(30, (i) => 'B${boxNum}_P${i + 1}');
        return CustomBoxState(
          title: 'Test $boxNum',
          pokemonIds: items,
          columns: 5,
          rows: 6,
        );
      });
      final dex = createStressDex(boxes: boxes);

      expect(dex.customBoxes.length, equals(5));

      // Insert at slot 0 of box 0 ("Test 1")
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW_TITAN',
      );

      // Verify box 6 was auto-created
      expect(dex.customBoxes.length, equals(6),
          reason: 'Inserting into 5 full boxes must cascade through all 5 and auto-create Box 6');
      expect(dex.customBoxes[5].title, equals('Test 6'));

      // Check slot 0 of Box 1 has NEW_TITAN
      expect(dex.customBoxes[0].pokemonIds.first, equals('NEW_TITAN'));
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[0].pokemonIds.last, equals('B1_P29'));

      // Check Box 2 received B1_P30 at slot 0
      expect(dex.customBoxes[1].pokemonIds.first, equals('B1_P30'));
      expect(dex.customBoxes[1].pokemonIds.length, equals(30));
      expect(dex.customBoxes[1].pokemonIds.last, equals('B2_P29'));

      // Check Box 3 received B2_P30 at slot 0
      expect(dex.customBoxes[2].pokemonIds.first, equals('B2_P30'));
      expect(dex.customBoxes[2].pokemonIds.length, equals(30));
      expect(dex.customBoxes[2].pokemonIds.last, equals('B3_P29'));

      // Check Box 4 received B3_P30 at slot 0
      expect(dex.customBoxes[3].pokemonIds.first, equals('B3_P30'));
      expect(dex.customBoxes[3].pokemonIds.length, equals(30));
      expect(dex.customBoxes[3].pokemonIds.last, equals('B4_P29'));

      // Check Box 5 received B4_P30 at slot 0
      expect(dex.customBoxes[4].pokemonIds.first, equals('B4_P30'));
      expect(dex.customBoxes[4].pokemonIds.length, equals(30));
      expect(dex.customBoxes[4].pokemonIds.last, equals('B5_P29'));

      // Check Box 6 has B5_P30
      expect(dex.customBoxes[5].pokemonIds.length, equals(1));
      expect(dex.customBoxes[5].pokemonIds.first, equals('B5_P30'));
    });

    test('1.2 Extreme cascade: 10 full boxes (300 items) cascade across all 10 boxes and auto-create Box 11', () {
      final boxes = List.generate(10, (bIdx) {
        final boxNum = bIdx + 1;
        final items = List.generate(30, (i) => 'M${boxNum}_I${i + 1}');
        return CustomBoxState(
          title: 'Kanto $boxNum',
          pokemonIds: items,
          columns: 5,
          rows: 6,
        );
      });
      final dex = createStressDex(boxes: boxes);

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'HYPER_START',
      );

      expect(dex.customBoxes.length, equals(11));
      expect(dex.customBoxes[10].title, equals('Kanto 11'));
      expect(dex.customBoxes[10].pokemonIds, equals(['M10_I30']));

      // Every intermediate box must have exactly 30 items
      for (int i = 0; i < 10; i++) {
        expect(dex.customBoxes[i].pokemonIds.length, equals(30));
      }
      expect(dex.customBoxes[0].pokemonIds.first, equals('HYPER_START'));
      for (int i = 1; i < 10; i++) {
        expect(dex.customBoxes[i].pokemonIds.first, equals('M${i}_I30'));
      }
    });

    test('1.3 Backward shift cascade across 6 full boxes propagates completely to delete Box 6', () {
      // 5 full boxes of 30, plus Box 6 with 1 item
      final boxes = List.generate(5, (bIdx) {
        final boxNum = bIdx + 1;
        return CustomBoxState(
          title: 'Test $boxNum',
          pokemonIds: List.generate(30, (i) => 'B${boxNum}_$i'),
          columns: 5,
          rows: 6,
        );
      });
      boxes.add(CustomBoxState(
        title: 'Test 6',
        pokemonIds: ['B6_LastOne'],
        columns: 5,
        rows: 6,
      ));
      final dex = createStressDex(boxes: boxes);

      // Remove item at slot 0 of Test 1
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Verify cascade: Test 6 emptied -> Test 6 deleted -> 5 boxes remaining
      expect(dex.customBoxes.length, equals(5));
      expect(dex.customBoxes.any((b) => b.title == 'Test 6'), isFalse);

      // Every remaining box has 30 items
      for (int i = 0; i < 5; i++) {
        expect(dex.customBoxes[i].pokemonIds.length, equals(30));
      }
      // Check tail of Box 5 is B6_LastOne
      expect(dex.customBoxes[4].pokemonIds.last, equals('B6_LastOne'));
    });

    test('1.4 Pure Range 5-box cascade: "1-30" through "121-150" auto-creates "151-180"', () {
      final boxes = [
        CustomBoxState(title: '1-30', pokemonIds: List.generate(30, (i) => 'P_${i + 1}')),
        CustomBoxState(title: '31-60', pokemonIds: List.generate(30, (i) => 'P_${i + 31}')),
        CustomBoxState(title: '61-90', pokemonIds: List.generate(30, (i) => 'P_${i + 61}')),
        CustomBoxState(title: '91-120', pokemonIds: List.generate(30, (i) => 'P_${i + 91}')),
        CustomBoxState(title: '121-150', pokemonIds: List.generate(30, (i) => 'P_${i + 121}')),
      ];
      final dex = createStressDex(boxes: boxes);

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'ZERO',
      );

      expect(dex.customBoxes.length, equals(6));
      expect(dex.customBoxes[5].title, equals('151-180'));
      expect(dex.customBoxes[5].pokemonIds, equals(['P_150']));

      // Shift back
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      expect(dex.customBoxes.length, equals(5));
      expect(dex.customBoxes[4].title, equals('121-150'));
      expect(dex.customBoxes[4].pokemonIds.last, equals('P_150'));
    });
  });

  group('Empirical Stress Testing — Scenario 2: Interleaving Isolation', () {
    test('2.1 Deep interleaved sequence: ["Kanto 1", "Unrelated Box", "Kanto 2"] strict isolation', () {
      final kanto1 = CustomBoxState(
        title: 'Kanto 1',
        pokemonIds: List.generate(30, (i) => 'K1_$i'),
      );
      final unrelated = CustomBoxState(
        title: 'Unrelated Box',
        pokemonIds: ['Secret_1', 'Secret_2', 'Secret_3'],
      );
      final kanto2 = CustomBoxState(
        title: 'Kanto 2',
        pokemonIds: ['K2_1'],
      );
      final dex = createStressDex(boxes: [kanto1, unrelated, kanto2]);

      // Overflow Kanto 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'K_NEW',
      );

      // Unrelated Box must remain exactly as was
      final uBox = dex.customBoxes.firstWhere((b) => b.title == 'Unrelated Box');
      expect(uBox.pokemonIds, equals(['Secret_1', 'Secret_2', 'Secret_3']));

      // Kanto 2 must have received the overflow item K1_29
      final k2Box = dex.customBoxes.firstWhere((b) => b.title == 'Kanto 2');
      expect(k2Box.pokemonIds, contains('K1_29'));

      // Shift back
      final k1Index = dex.customBoxes.indexOf(kanto1);
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: k1Index, slotIndex: 0);

      // Unrelated box still untouched
      expect(uBox.pokemonIds, equals(['Secret_1', 'Secret_2', 'Secret_3']));
    });

    test('2.2 Multi-unrelated interleaving with auto-creation insertion positioning', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: List.generate(30, (i) => 'T1_$i'));
      final uA = CustomBoxState(title: 'Alpha Solo', pokemonIds: ['UA_1', 'UA_2']);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: List.generate(30, (i) => 'T2_$i'));
      final uB = CustomBoxState(title: 'Beta Solo', pokemonIds: ['UB_1']);
      final b3 = CustomBoxState(title: 'Test 3', pokemonIds: List.generate(30, (i) => 'T3_$i'));
      final uC = CustomBoxState(title: 'Gamma Solo', pokemonIds: ['UC_1', 'UC_2', 'UC_3']);

      final dex = createStressDex(boxes: [b1, uA, b2, uB, b3, uC]);

      // Insert into Test 1 slot 0 -> cascades to auto-create Test 4
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'CASCADE_START',
      );

      // Verify Test 4 is placed directly after Test 3, before Gamma Solo!
      final titles = dex.customBoxes.map((b) => b.title).toList();
      expect(titles, equals(['Test 1', 'Alpha Solo', 'Test 2', 'Beta Solo', 'Test 3', 'Test 4', 'Gamma Solo']));

      // Verify all standalone boxes remain 100% untouched
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Alpha Solo').pokemonIds, equals(['UA_1', 'UA_2']));
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Beta Solo').pokemonIds, equals(['UB_1']));
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Gamma Solo').pokemonIds, equals(['UC_1', 'UC_2', 'UC_3']));

      // Backward shift removal
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Test 4 must be pruned
      final titlesAfter = dex.customBoxes.map((b) => b.title).toList();
      expect(titlesAfter, equals(['Test 1', 'Alpha Solo', 'Test 2', 'Beta Solo', 'Test 3', 'Gamma Solo']));

      // Standalone boxes still untouched
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Alpha Solo').pokemonIds, equals(['UA_1', 'UA_2']));
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Beta Solo').pokemonIds, equals(['UB_1']));
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Gamma Solo').pokemonIds, equals(['UC_1', 'UC_2', 'UC_3']));
    });
  });

  group('Empirical Stress Testing — Scenario 3: Rapid Oscillating Operations', () {
    test('3.1 50 successive insertions followed by 50 successive deletions preserves original state exactly', () {
      final originalItems = List.generate(30, (i) => 'ORIG_${i + 1}');
      final initialBox = CustomBoxState(
        title: 'Test 1',
        pokemonIds: List<String>.from(originalItems),
        columns: 5,
        rows: 6,
      );
      final dex = createStressDex(boxes: [initialBox]);

      // Phase 1: 50 successive insertions at slot 0
      for (int i = 0; i < 50; i++) {
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
          pokemonId: 'INJECT_$i',
        );
      }

      // Total items = 30 + 50 = 80 items
      // 80 items in 30-capacity boxes -> 2 full boxes (30 + 30) + 1 box of 20 = 3 boxes!
      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[1].title, equals('Test 2'));
      expect(dex.customBoxes[2].title, equals('Test 3'));
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[1].pokemonIds.length, equals(30));
      expect(dex.customBoxes[2].pokemonIds.length, equals(20));

      // Phase 2: 50 successive deletions at slot 0 of Box 1
      for (int i = 0; i < 50; i++) {
        BoxSequenceManager.removeWithShiftBack(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
        );
      }

      // Invariant check:
      // Must be back to exactly 1 box, titled 'Test 1', with original 30 items in original order!
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[0].pokemonIds, equals(originalItems),
          reason: '50 insert/delete cycle must restore original items in exact order');
    });

    test('3.2 50 rapid alternating insert/delete cycles maintain continuous invariant', () {
      final originalItems = List.generate(30, (i) => 'STABLE_$i');
      final box = CustomBoxState(
        title: 'Test 1',
        pokemonIds: List<String>.from(originalItems),
      );
      final dex = createStressDex(boxes: [box]);

      for (int cycle = 0; cycle < 50; cycle++) {
        // Insert at slot 5
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: 0,
          slotIndex: 5,
          pokemonId: 'TEMP_$cycle',
        );

        expect(dex.customBoxes.length, equals(2), reason: 'Cycle $cycle: overflow creates Test 2');
        expect(dex.customBoxes[0].pokemonIds[5], equals('TEMP_$cycle'));

        // Remove from slot 5
        BoxSequenceManager.removeWithShiftBack(
          dex: dex,
          boxIndex: 0,
          slotIndex: 5,
        );

        expect(dex.customBoxes.length, equals(1), reason: 'Cycle $cycle: shift back deletes Test 2');
        expect(dex.customBoxes[0].pokemonIds, equals(originalItems),
            reason: 'Cycle $cycle: items restored');
      }
    });

    test('3.3 Oscillating insertions at randomized slot indices with deterministic cleanup', () {
      final rng = Random(42);
      final originalItems = List.generate(30, (i) => 'ITEM_$i');
      final box = CustomBoxState(
        title: 'Kanto 1',
        pokemonIds: List<String>.from(originalItems),
      );
      final dex = createStressDex(boxes: [box]);

      final inserted = <MapEntry<int, String>>[];

      // 30 insertions at random slots
      for (int i = 0; i < 30; i++) {
        final slot = rng.nextInt(dex.customBoxes[0].pokemonIds.length);
        final id = 'RAND_$i';
        inserted.add(MapEntry(slot, id));
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: 0,
          slotIndex: slot,
          pokemonId: id,
        );
      }

      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[1].pokemonIds.length, equals(30));

      // Remove the 30 inserted items by finding their current slots
      for (int i = inserted.length - 1; i >= 0; i--) {
        final id = inserted[i].value;
        // Search across customBoxes
        int targetBox = -1;
        int targetSlot = -1;
        for (int b = 0; b < dex.customBoxes.length; b++) {
          final idx = dex.customBoxes[b].pokemonIds.indexOf(id);
          if (idx != -1) {
            targetBox = b;
            targetSlot = idx;
            break;
          }
        }
        expect(targetBox, isNot(-1), reason: 'Item $id must be in some box');
        BoxSequenceManager.removeWithShiftBack(
          dex: dex,
          boxIndex: targetBox,
          slotIndex: targetSlot,
        );
      }

      // Back to 1 box with original items
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].pokemonIds, equals(originalItems));
    });
  });

  group('Empirical Stress Testing — Scenario 4: Batch Deletion Stress', () {
    test('4.1 Multi-box batch deletion across 3 linked boxes with non-contiguous slots', () {
      // 3 boxes with 30 items each: 90 items total (P_1 to P_90)
      final allItems = List.generate(90, (i) => 'P_${i + 1}');
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: allItems.sublist(0, 30));
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: allItems.sublist(30, 60));
      final b3 = CustomBoxState(title: 'Test 3', pokemonIds: allItems.sublist(60, 90));

      final dex = createStressDex(boxes: [b1, b2, b3]);

      // Select 15 non-contiguous deletion targets across all 3 boxes:
      // Box 0: slots 0, 7, 15, 29 (items P_1, P_8, P_16, P_30)
      // Box 1: slots 3, 11, 20, 28 (items P_34, P_42, P_51, P_59)
      // Box 2: slots 0, 5, 12, 19, 25, 27, 29 (items P_61, P_66, P_73, P_80, P_86, P_88, P_90)
      final selectedKeys = [
        '0_0', '0_7', '0_15', '0_29',
        '1_3', '1_11', '1_20', '1_28',
        '2_0', '2_5', '2_12', '2_19', '2_25', '2_27', '2_29',
      ];

      final deletedItems = {
        'P_1', 'P_8', 'P_16', 'P_30',
        'P_34', 'P_42', 'P_51', 'P_59',
        'P_61', 'P_66', 'P_73', 'P_80', 'P_86', 'P_88', 'P_90',
      };
      final expectedRemaining = allItems.where((p) => !deletedItems.contains(p)).toList();
      expect(expectedRemaining.length, equals(75));

      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: selectedKeys,
      );

      // Remaining items in dex
      final remainingInDex = <String>[];
      for (final box in dex.customBoxes) {
        remainingInDex.addAll(box.pokemonIds.where((id) => id.isNotEmpty));
      }

      expect(remainingInDex.length, equals(75));
      expect(remainingInDex, equals(expectedRemaining),
          reason: 'Batch removal must preserve exact relative order of all non-deleted items');

      // Check packing: Box 1 and Box 2 must be full (30 items each), Box 3 has 15 items
      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[1].pokemonIds.length, equals(30));
      expect(dex.customBoxes[2].pokemonIds.length, equals(15));
    });

    test('4.2 Batch deletion emptying entire tail boxes auto-deletes empty boxes correctly', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: List.generate(30, (i) => 'T1_$i'));
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: List.generate(10, (i) => 'T2_$i'));
      final dex = createStressDex(boxes: [b1, b2]);

      // Select all 10 items of Test 2 plus 5 items of Test 1
      final selectedKeys = <String>[];
      for (int i = 0; i < 10; i++) {
        selectedKeys.add('1_$i');
      }
      for (int i = 0; i < 5; i++) {
        selectedKeys.add('0_$i');
      }

      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: selectedKeys,
      );

      // Test 2 must be completely pruned
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      // Test 1 had 30 items, 5 deleted -> 25 items remain
      expect(dex.customBoxes[0].pokemonIds.length, equals(25));
    });

    test('4.3 Batch deletion with invalid and duplicate keys is robust and idempotent', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: ['A', 'B', 'C']);
      final dex = createStressDex(boxes: [b1]);

      final selectedKeys = [
        '0_1', // 'B'
        '0_1', // duplicate
        '99_0', // invalid box index
        '-1_0', // negative box index
        '0_99', // invalid slot index
        'bad_format',
        '',
      ];

      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: selectedKeys,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'C']));
    });
  });

  group('Empirical Stress Testing — Scenario 5: Capacity & Geometry Boundary Conditions', () {
    test('5.1 Minimal 1x1 grid capacity cascades properly across 5 boxes', () {
      final boxes = List.generate(5, (i) {
        return CustomBoxState(
          title: 'Mini ${i + 1}',
          pokemonIds: ['M${i + 1}'],
          columns: 1,
          rows: 1,
        );
      });
      final dex = createStressDex(boxes: boxes);

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'M0',
      );

      expect(dex.customBoxes.length, equals(6));
      expect(dex.customBoxes[0].pokemonIds, equals(['M0']));
      expect(dex.customBoxes[1].pokemonIds, equals(['M1']));
      expect(dex.customBoxes[2].pokemonIds, equals(['M2']));
      expect(dex.customBoxes[3].pokemonIds, equals(['M3']));
      expect(dex.customBoxes[4].pokemonIds, equals(['M4']));
      expect(dex.customBoxes[5].pokemonIds, equals(['M5']));

      // Shift back
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      expect(dex.customBoxes.length, equals(5));
      expect(dex.customBoxes[0].pokemonIds, equals(['M1']));
      expect(dex.customBoxes[4].pokemonIds, equals(['M5']));
    });

    test('5.2 Insertion at out-of-bounds slotIndex (>= capacity) immediately triggers overflow', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: List.generate(30, (i) => 'P$i'), columns: 5, rows: 6);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: ['P_Next'], columns: 5, rows: 6);
      final dex = createStressDex(boxes: [b1, b2]);

      // Inserting at slotIndex 35 (beyond capacity 30)
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 35,
        pokemonId: 'OUT_OF_BOUNDS',
      );

      // OUT_OF_BOUNDS must immediately overflow into Test 2
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[0].pokemonIds, isNot(contains('OUT_OF_BOUNDS')));
      expect(dex.customBoxes[1].pokemonIds.first, equals('OUT_OF_BOUNDS'));
    });
  });

  group('Empirical Stress Testing — Scenario 6: Advanced Adversarial Cross-Sequence & Edge Dynamics', () {
    test('6.1 Interleaved dual sequences ["Kanto 1", "Johto 1", "Kanto 2", "Johto 2"] maintain perfect cross-isolation', () {
      final k1 = CustomBoxState(title: 'Kanto 1', pokemonIds: List.generate(30, (i) => 'K1_$i'));
      final j1 = CustomBoxState(title: 'Johto 1', pokemonIds: List.generate(30, (i) => 'J1_$i'));
      final k2 = CustomBoxState(title: 'Kanto 2', pokemonIds: List.generate(30, (i) => 'K2_$i'));
      final j2 = CustomBoxState(title: 'Johto 2', pokemonIds: List.generate(30, (i) => 'J2_$i'));

      final dex = createStressDex(boxes: [k1, j1, k2, j2]);

      // Step 1: Overflow Kanto 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0, // Kanto 1
        slotIndex: 0,
        pokemonId: 'KANTO_ALPHA',
      );

      // Kanto 3 auto-created and placed right after Kanto 2 (before Johto 2)
      final titles1 = dex.customBoxes.map((b) => b.title).toList();
      expect(titles1, equals(['Kanto 1', 'Johto 1', 'Kanto 2', 'Kanto 3', 'Johto 2']));
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Kanto 3').pokemonIds, equals(['K2_29']));

      // Johto boxes must be 100% untouched
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Johto 1').pokemonIds, equals(List.generate(30, (i) => 'J1_$i')));
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Johto 2').pokemonIds, equals(List.generate(30, (i) => 'J2_$i')));

      // Step 2: Overflow Johto 1
      final j1Index = dex.customBoxes.indexWhere((b) => b.title == 'Johto 1');
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: j1Index,
        slotIndex: 0,
        pokemonId: 'JOHTO_BETA',
      );

      // Johto 3 auto-created and placed right after Johto 2
      final titles2 = dex.customBoxes.map((b) => b.title).toList();
      expect(titles2, equals(['Kanto 1', 'Johto 1', 'Kanto 2', 'Kanto 3', 'Johto 2', 'Johto 3']));
      expect(dex.customBoxes.firstWhere((b) => b.title == 'Johto 3').pokemonIds, equals(['J2_29']));

      // Step 3: Shift-back removal on Kanto 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      final titles3 = dex.customBoxes.map((b) => b.title).toList();
      expect(titles3, equals(['Kanto 1', 'Johto 1', 'Kanto 2', 'Johto 2', 'Johto 3']));

      // Step 4: Shift-back removal on Johto 1
      final j1IndexFinal = dex.customBoxes.indexWhere((b) => b.title == 'Johto 1');
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: j1IndexFinal, slotIndex: 0);
      final titles4 = dex.customBoxes.map((b) => b.title).toList();
      expect(titles4, equals(['Kanto 1', 'Johto 1', 'Kanto 2', 'Johto 2']));
    });

    test('6.2 Non-sequential gapped sequence ["Test 1", "Test 5"] full cascade generates Test 6', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: List.generate(30, (i) => 'T1_$i'));
      final b5 = CustomBoxState(title: 'Test 5', pokemonIds: List.generate(30, (i) => 'T5_$i'));
      final dex = createStressDex(boxes: [b1, b5]);

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'GAP_TEST',
      );

      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes[2].title, equals('Test 6'));
      expect(dex.customBoxes[2].pokemonIds, equals(['T5_29']));
      expect(dex.customBoxes[1].pokemonIds.first, equals('T1_29'));

      // Backward shift removal
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.map((b) => b.title).toList(), equals(['Test 1', 'Test 5']));
    });

    test('6.3 Massive batch deletion emptying 4 out of 5 linked boxes cleans up all 4 empty boxes and retains Root', () {
      final boxes = List.generate(5, (b) {
        return CustomBoxState(
          title: 'Test ${b + 1}',
          pokemonIds: List.generate(30, (i) => 'B${b + 1}_P$i'),
        );
      });
      final dex = createStressDex(boxes: boxes);

      // We select all items of Boxes 2, 3, 4, 5, plus 20 items of Box 1 (total 140 deletions)
      final selectedKeys = <String>[];
      for (int b = 1; b < 5; b++) {
        for (int s = 0; s < 30; s++) {
          selectedKeys.add('${b}_$s');
        }
      }
      for (int s = 0; s < 20; s++) {
        selectedKeys.add('0_$s');
      }

      expect(selectedKeys.length, equals(140));

      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: selectedKeys,
      );

      // Only Root Box (Test 1) must remain with 10 items!
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds.length, equals(10));
      expect(dex.customBoxes[0].pokemonIds, equals(List.generate(10, (i) => 'B1_P${i + 20}')));
    });

    test('6.4 Empty slot padding absorption avoids unnecessary overflow', () {
      final b1 = CustomBoxState(
        title: 'Test 1',
        pokemonIds: ['A', '', 'B', ''],
        columns: 2,
        rows: 2,
      );
      final b2 = CustomBoxState(
        title: 'Test 2',
        pokemonIds: [],
        columns: 2,
        rows: 2,
      );
      final dex = createStressDex(boxes: [b1, b2]);

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 1,
        pokemonId: 'NEW_INSERT',
      );

      // Length was 4, inserted at 1, length became 5: ['A', 'NEW_INSERT', '', 'B', '']
      // Capacity is 4, displaced is '', which is empty!
      // Therefore, Test 2 should NOT receive any overflow, and length of Test 1 remains 4!
      expect(dex.customBoxes[0].pokemonIds.length, equals(4));
      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'NEW_INSERT', '', 'B']));
      expect(dex.customBoxes[1].pokemonIds, isEmpty);
    });
  });
}
