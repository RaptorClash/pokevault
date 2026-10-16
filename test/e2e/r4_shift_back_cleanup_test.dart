import 'package:flutter_test/flutter_test.dart';
import 'helpers/e2e_test_helper.dart';
import 'helpers/e2e_box_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    E2EBoxActions.resetHandlers();
  });

  group('R4 Auto-Shift Back & Empty Box Cleanup E2E Tests - Tier 1: Feature Coverage', () {
    test('T1.1: Removing Pokémon from "Test 1" shifts first item of "Test 2" backward into "Test 1"', () {
      final ids30 = List.generate(30, (i) => 'T1_${i + 1}');
      final idsTest2 = ['T2_First', 'T2_Second'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Shift Back Test',
        customBoxes: [box1, box2],
      );

      // Remove item at index 5 of Test 1
      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 5,
      );

      // Test 1 must remain full (30 items), with T2_First pulled into its last slot
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[0].pokemonIds.last, equals('T2_First'),
          reason: 'Removing from Test 1 must pull T2_First from Test 2 into last slot of Test 1');

      // Test 2 must now have only T2_Second
      expect(dex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['T2_Second']));
    });

    test('T1.2: Empty box is automatically deleted when last item shifts back into previous box', () {
      final ids30 = List.generate(30, (i) => 'T1_${i + 1}');
      final idsTest2 = ['T2_OnlyOne'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Cleanup Test',
        customBoxes: [box1, box2],
      );

      // Remove from Test 1 -> T2_OnlyOne shifts to Test 1 -> Test 2 becomes empty
      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Requirement: Test 2 must be automatically deleted from customBoxes!
      expect(dex.customBoxes.length, equals(1),
          reason: 'Test 2 became empty and must be automatically deleted');
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds.last, equals('T2_OnlyOne'));
    });

    test('T1.3: Multi-box backward shift cascade across sequence (Test 3 -> Test 2 -> Test 1)', () {
      final ids30A = List.generate(30, (i) => 'T1_${i + 1}');
      final ids30B = List.generate(30, (i) => 'T2_${i + 1}');
      final idsTest3 = ['T3_Head', 'T3_Tail'];

      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30A, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ids30B, columns: 5, rows: 6);
      final box3 = createTestCustomBox(title: 'Test 3', pokemonIds: idsTest3, columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Cascade Shift',
        customBoxes: [box1, box2, box3],
      );

      // Remove item at index 0 from Test 1
      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Test 1 gets T2_1
      expect(dex.customBoxes[0].pokemonIds.last, equals('T2_1'));
      // Test 2 gets T3_Head
      expect(dex.customBoxes[1].pokemonIds.last, equals('T3_Head'));
      // Test 3 only has T3_Tail remaining
      expect(dex.customBoxes[2].pokemonIds.where((id) => id.isNotEmpty).toList(), equals(['T3_Tail']));
    });

    test('T1.4: Cascade empty box cleanup deletes tail box when multiple boxes shift', () {
      final ids30A = List.generate(30, (i) => 'T1_${i + 1}');
      final ids30B = List.generate(30, (i) => 'T2_${i + 1}');
      final idsTest3 = ['T3_Single'];

      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30A, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ids30B, columns: 5, rows: 6);
      final box3 = createTestCustomBox(title: 'Test 3', pokemonIds: idsTest3, columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Cascade Cleanup',
        customBoxes: [box1, box2, box3],
      );

      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Test 3 emptied -> Test 3 deleted
      expect(dex.customBoxes.length, equals(2),
          reason: 'Test 3 was emptied by the cascade and must be auto-deleted');
      expect(dex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);
    });

    test('T1.5: Standalone box removal closes internal gap without affecting external boxes', () {
      final box = createTestCustomBox(
        title: 'Standalone Box',
        pokemonIds: ['Alpha', 'Beta', 'Gamma', 'Delta'],
      );
      final other = createTestCustomBox(
        title: 'Other Box',
        pokemonIds: ['O1', 'O2'],
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Standalone',
        customBoxes: [box, other],
      );

      // Remove Beta (index 1)
      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 1,
      );

      // Internal gap closed: [Alpha, Gamma, Delta]
      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['Alpha', 'Gamma', 'Delta']));
      // Other Box completely untouched
      expect(dex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['O1', 'O2']));
    });
  });

  group('R4 Auto-Shift Back & Empty Box Cleanup E2E Tests - Tier 2: Boundary & Corner Cases', () {
    test('T2.1: Removing item at index 0 (first slot) shifts all slots and pulls next box head', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ['NEXT_HEAD'], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Head Removal', customBoxes: [box1, box2]);

      E2EBoxActions.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(dex.customBoxes[0].pokemonIds[0], equals('M_2'));
      expect(dex.customBoxes[0].pokemonIds.last, equals('NEXT_HEAD'));
    });

    test('T2.2: Removing item at index 29 (last slot) directly pulls first item of next box into index 29', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ['PULL_DIRECT'], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Tail Removal', customBoxes: [box1, box2]);

      E2EBoxActions.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 29);

      expect(dex.customBoxes[0].pokemonIds[29], equals('PULL_DIRECT'));
    });

    test('T2.3: Deleting last remaining Pokémon in sole Box 1 empties Box 1 without deleting root box', () {
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ['LAST_POKE'], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Root Box Empty', customBoxes: [box1]);

      E2EBoxActions.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Root box should never be deleted, even when empty
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty), isEmpty);
    });

    test('T2.4: "Unrelated Box" items are never shifted into "Test 1" on removal', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final unrelated = createTestCustomBox(
        title: 'Unrelated Box',
        pokemonIds: ['SECRET_1', 'SECRET_2'],
        columns: 5,
        rows: 6,
      );
      final dex = createTestUserDex(id: 'dex1', title: 'Isolation', customBoxes: [box1, unrelated]);

      E2EBoxActions.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(dex.customBoxes[0].pokemonIds, isNot(contains('SECRET_1')));
      expect(dex.customBoxes[0].pokemonIds, isNot(contains('SECRET_2')));
      expect(dex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['SECRET_1', 'SECRET_2']));
    });

    test('T2.5: Batch removal of multiple items shifts back multiple items across sequence', () {
      final ids30 = List.generate(30, (i) => 'T1_${i + 1}');
      final idsTest2 = ['T2_A', 'T2_B', 'T2_C'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Batch', customBoxes: [box1, box2]);

      // Batch remove 2 items from Test 1: indices 0 and 1
      E2EBoxActions.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: ['0_0', '0_1'],
      );

      // Both T2_A and T2_B should be shifted into Test 1
      expect(dex.customBoxes[0].pokemonIds, contains('T2_A'));
      expect(dex.customBoxes[0].pokemonIds, contains('T2_B'));
      expect(dex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty).toList(), equals(['T2_C']));
    });

    test('T2.6: Gap closing in "Kanto 1" never shifts items from "Kanto Tausch"', () {
      final ids30 = List.generate(30, (i) => 'Kanto_${i + 1}');
      final kanto1 = createTestCustomBox(title: 'Kanto 1', pokemonIds: ids30, columns: 5, rows: 6);
      final kantoTausch = createTestCustomBox(
        title: 'Kanto Tausch',
        pokemonIds: ['Tausch_Alpha', 'Tausch_Beta'],
        columns: 5,
        rows: 6,
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto Removal Isolation',
        customBoxes: [kanto1, kantoTausch],
      );

      // Remove from Kanto 1
      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Kanto Tausch items must never be pulled into Kanto 1
      expect(dex.customBoxes[0].pokemonIds, isNot(contains('Tausch_Alpha')));
      expect(dex.customBoxes[0].pokemonIds, isNot(contains('Tausch_Beta')));
      expect(dex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['Tausch_Alpha', 'Tausch_Beta']),
          reason: 'Kanto Tausch must remain untouched when Kanto 1 removes items');
    });
  });

  group('R4 Auto-Shift Back & Empty Box Cleanup E2E Tests - Tier 3: Cross-Feature Combinations', () {
    test('T3.1: Round-trip invariant: Full Test 1 -> Insert index 0 (overflows to Test 2) -> Remove index 0 (shifts back, Test 2 deleted)', () {
      final initial30 = List.generate(30, (i) => 'ORIG_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: initial30, columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Roundtrip', customBoxes: [box1]);

      // 1. Insert new item at index 0 -> Test 2 auto-created with ORIG_30
      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'TEMP_ITEM',
      );
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[1].title, equals('Test 2'));

      // 2. Remove TEMP_ITEM at index 0 -> ORIG_30 shifts back to Test 1, Test 2 deleted
      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Invariant: Custom boxes count is back to 1, and box contents match initial state
      expect(dex.customBoxes.length, equals(1),
          reason: 'Roundtrip removal must restore single box state');
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds.sublist(0, 30), equals(initial30),
          reason: 'Roundtrip must restore original 30 Pokémon in exact initial order');
    });

    test('T3.2: Disabling autoDeleteEmpty setting preserves empty linked box when emptied', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: ids30,
        columns: 5,
        rows: 6,
        autoDeleteEmpty: false,
      );
      final box2 = createTestCustomBox(
        title: 'Test 2',
        pokemonIds: ['T2_Solitary'],
        columns: 5,
        rows: 6,
        autoDeleteEmpty: false,
      );
      final dex = createTestUserDex(id: 'dex1', title: 'No Cleanup', customBoxes: [box1, box2]);

      E2EBoxActions.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // With autoDeleteEmpty = false, Test 2 must NOT be deleted even when emptied
      expect(dex.customBoxes.length, equals(2),
          reason: 'Empty box must be preserved when autoDeleteEmpty is false');
    });
  });

  group('R4 Auto-Shift Back & Empty Box Cleanup E2E Tests - Tier 4: Real-World Acceptance Scenarios', () {
    test('T4.1 Acceptance Scenario 2: Remove Pokémon from "Test 1" -> Pokémon from "Test 2" shifts back to "Test 1", and "Test 2" is deleted when empty', () {
      // Setup full box named "Test 1" (30 items)
      final idsTest1 = List.generate(30, (i) => 'Mon_${i + 1}');
      final test1 = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: idsTest1,
        columns: 5,
        rows: 6,
      );

      // Setup "Test 2" with exactly 1 item
      final test2 = createTestCustomBox(
        title: 'Test 2',
        pokemonIds: ['Overflow_Pikachu'],
        columns: 5,
        rows: 6,
      );

      final dex = createTestUserDex(
        id: 'acceptance_r4_2',
        title: 'Acceptance Scenario 2',
        customBoxes: [test1, test2],
      );

      // User removes a Pokémon from "Test 1" (e.g. index 5, Mon_6)
      E2EBoxActions.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 5,
      );

      // Verification Steps:
      // 1. "Test 1" gap is filled and "Overflow_Pikachu" from "Test 2" shifts into "Test 1"
      final box1After = dex.customBoxes.firstWhere((b) => b.title == 'Test 1');
      expect(box1After.pokemonIds, contains('Overflow_Pikachu'),
          reason: 'Overflow_Pikachu from Test 2 must shift back into Test 1');
      expect(box1After.pokemonIds.length, equals(30),
          reason: 'Test 1 must maintain full capacity of 30 items');

      // 2. "Test 2" is deleted because it became empty
      expect(dex.customBoxes.any((b) => b.title == 'Test 2'), isFalse,
          reason: 'Test 2 must be deleted from customBoxes after becoming empty');
      expect(dex.customBoxes.length, equals(1),
          reason: 'Only Test 1 should remain in userDex');
    });
  });
}
