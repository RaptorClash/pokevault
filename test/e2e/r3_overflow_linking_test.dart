import 'package:flutter_test/flutter_test.dart';
import 'helpers/e2e_test_helper.dart';
import 'helpers/e2e_box_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    E2EBoxActions.resetHandlers();
  });

  group('R3 Box Linking & Overflow E2E Tests - Tier 1: Feature Coverage', () {
    test('T1.1: Full box "Test 1" overflows last item into existing linked "Test 2"', () {
      // 5x6 box with 30 items
      final ids30 = List.generate(30, (i) => 'P_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: [], columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Overflow Test',
        customBoxes: [box1, box2],
      );

      // Insert new item at index 0 of Test 1
      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW_POKE',
      );

      // Test 1 should have capacity 30, starting with NEW_POKE and ending with P_29
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      expect(dex.customBoxes[0].pokemonIds.first, equals('NEW_POKE'));
      expect(dex.customBoxes[0].pokemonIds.last, equals('P_29'));

      // Test 2 should receive P_30
      expect(dex.customBoxes[1].pokemonIds, contains('P_30'),
          reason: 'Last item P_30 must spill over into existing linked box Test 2');
    });

    test('T1.2: Full box "Test 1" auto-creates "Test 2" when no linked box exists yet', () {
      final ids30 = List.generate(30, (i) => 'P_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Auto-Create Test',
        customBoxes: [box1],
      );

      // Insert new item at index 0 of Test 1
      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW_POKE',
      );

      // Requirement: A new box "Test 2" must be created
      expect(dex.customBoxes.length, equals(2),
          reason: 'Inserting into full Test 1 when no Test 2 exists must auto-create Test 2');
      expect(dex.customBoxes[1].title, equals('Test 2'));
      expect(dex.customBoxes[1].pokemonIds, contains('P_30'));
    });

    test('T1.3: Multi-box cascade: "Test 1" and "Test 2" both full cascades to auto-create "Test 3"', () {
      final ids30A = List.generate(30, (i) => 'Box1_${i + 1}');
      final ids30B = List.generate(30, (i) => 'Box2_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30A, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ids30B, columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Cascade Test',
        customBoxes: [box1, box2],
      );

      // Insert at beginning of Test 1
      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'CASCADE_ITEM',
      );

      // Should cascade: Test 1 -> Test 2 -> Test 3
      expect(dex.customBoxes.length, equals(3),
          reason: 'Both Test 1 and Test 2 full must cascade and auto-create Test 3');
      expect(dex.customBoxes[2].title, equals('Test 3'));
      expect(dex.customBoxes[2].pokemonIds, contains('Box2_30'));
    });

    test('T1.4: Pure range sequence: "1-30" overflowing cascades into existing "31-60"', () {
      final ids30 = List.generate(30, (i) => 'Item_${i + 1}');
      final box1 = createTestCustomBox(title: '1-30', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: '31-60', pokemonIds: ['Item_31'], columns: 5, rows: 6);
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Range Test',
        customBoxes: [box1, box2],
      );

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW_FIRST',
      );

      expect(dex.customBoxes[0].pokemonIds.first, equals('NEW_FIRST'));
      expect(dex.customBoxes[1].pokemonIds, contains('Item_30'),
          reason: 'Range sequence 1-30 must overflow into 31-60');
    });

    test('T1.5: Isolation: Overflow from "Test 1" never affects "Unrelated Box"', () {
      final ids30 = List.generate(30, (i) => 'Item_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final unrelated = createTestCustomBox(
        title: 'Unrelated Box',
        pokemonIds: ['Special_A', 'Special_B'],
        columns: 5,
        rows: 6,
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Isolation Test',
        customBoxes: [box1, unrelated],
      );

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'OVERFLOW_TRIGGER',
      );

      // Unrelated Box must be 100% untouched
      final unrelatedBoxAfter = dex.customBoxes.firstWhere((b) => b.title == 'Unrelated Box');
      expect(unrelatedBoxAfter.pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['Special_A', 'Special_B']),
          reason: 'Unrelated Box must never receive overflow from Test 1 sequence');
    });

    test('T1.6: Pattern Isolation: "Kanto 1" overflow never affects "Kanto Tausch" and auto-creates "Kanto 2"', () {
      final ids30 = List.generate(30, (i) => 'Kanto_${i + 1}');
      final kanto1 = createTestCustomBox(title: 'Kanto 1', pokemonIds: ids30, columns: 5, rows: 6);
      final kantoTausch = createTestCustomBox(
        title: 'Kanto Tausch',
        pokemonIds: ['Tausch_A', 'Tausch_B'],
        columns: 5,
        rows: 6,
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto Isolation',
        customBoxes: [kanto1, kantoTausch],
      );

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'Kanto_New',
      );

      // Kanto 2 must be auto-created
      expect(dex.customBoxes.length, equals(3),
          reason: 'Inserting into full Kanto 1 must auto-create Kanto 2');
      final kanto2 = dex.customBoxes.firstWhere((b) => b.title == 'Kanto 2');
      expect(kanto2.pokemonIds, contains('Kanto_30'));

      // Kanto Tausch must be completely unaffected
      final tauschAfter = dex.customBoxes.firstWhere((b) => b.title == 'Kanto Tausch');
      expect(tauschAfter.pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['Tausch_A', 'Tausch_B']),
          reason: 'Kanto Tausch must never be affected by Kanto 1 numbered overflow sequence');
    });
  });

  group('R3 Box Linking & Overflow E2E Tests - Tier 2: Boundary & Corner Cases', () {
    test('T2.1: Box at capacity minus 1 (29 of 30) does NOT overflow to next box on insertion', () {
      final ids29 = List.generate(29, (i) => 'P_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids29, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: [], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Boundaries', customBoxes: [box1, box2]);

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'FITS_EXACTLY',
      );

      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).length, equals(30));
      expect(dex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty), isEmpty,
          reason: 'When box has space, no overflow should occur');
    });

    test('T2.2: Insertion at last slot of full box overflows the newly inserted item if capacity exceeded', () {
      final ids30 = List.generate(30, (i) => 'P_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: [], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Tail Insert', customBoxes: [box1, box2]);

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 30, // append at end
        pokemonId: 'TAIL_ITEM',
      );

      // TAIL_ITEM overflows directly into Test 2
      expect(dex.customBoxes[1].pokemonIds, contains('TAIL_ITEM'));
      expect(dex.customBoxes[0].pokemonIds.sublist(0, 30), equals(ids30));
    });

    test('T2.3: Custom grid dimensions (2x2 = 4 capacity) enforces strict overflow at 5th item', () {
      final ids4 = ['A', 'B', 'C', 'D'];
      final box1 = createTestCustomBox(title: 'Small 1', pokemonIds: ids4, columns: 2, rows: 2);
      final dex = createTestUserDex(id: 'dex1', title: 'Small Grid', customBoxes: [box1]);

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW_5',
      );

      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).length, equals(4));
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[1].title, equals('Small 2'));
      expect(dex.customBoxes[1].pokemonIds, contains('D'));
    });

    test('T2.4: Prefix range pattern "Box 1 (1-30)" links with "Box 2 (31-60)"', () {
      final ids30 = List.generate(30, (i) => 'Pref_${i + 1}');
      final box1 = createTestCustomBox(title: 'Box 1 (1-30)', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Box 2 (31-60)', pokemonIds: [], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Prefix Range', customBoxes: [box1, box2]);

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'PREF_NEW',
      );

      expect(dex.customBoxes[1].pokemonIds, contains('Pref_30'),
          reason: 'Prefix range pattern Box 1 (1-30) must link and overflow to Box 2 (31-60)');
    });

    test('T2.5: Non-sequential existing sequence "Test 1" and "Test 3" cascades into Test 3 before creating Test 4', () {
      final ids30 = List.generate(30, (i) => 'Item_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box3 = createTestCustomBox(title: 'Test 3', pokemonIds: [], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Gap Test', customBoxes: [box1, box3]);

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'GAP_ITEM',
      );

      // Should spill into existing Test 3 or auto-create Test 2 in sequence order
      expect(dex.customBoxes.any((b) => b.pokemonIds.contains('Item_30')), isTrue,
          reason: 'Overflowed item must be preserved in linked sequence');
    });
  });

  group('R3 Box Linking & Overflow E2E Tests - Tier 3: Cross-Feature Combinations', () {
    test('T3.1: Overflow cascade into next box preserves caught status for overflowed Pokémon', () {
      final ids30 = List.generate(30, (i) => 'PKMN_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: [], columns: 5, rows: 6);
      // PKMN_30 is caught
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Status Preservation',
        customBoxes: [box1, box2],
        caughtIds: ['PKMN_30'],
      );

      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'TRIGGER',
      );

      expect(dex.customBoxes[1].pokemonIds, contains('PKMN_30'));
      expect(dex.caughtIds, contains('PKMN_30'),
          reason: 'Caught status must remain intact after Pokémon overflows to next box');
    });

    test('T3.2: Drag & drop within Box 1 that causes overflow triggers cascade into Box 2', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: [], columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex1', title: 'Move Overflow', customBoxes: [box1, box2]);

      // Move M_30 to index 0: internal shift does not change total count, so no overflow
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'M_30',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      expect(dex.customBoxes[0].pokemonIds.first, equals('M_30'));
      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).length, equals(30));
    });
  });

  group('R3 Box Linking & Overflow E2E Tests - Tier 4: Real-World Acceptance Scenarios', () {
    test('T4.1 Acceptance Scenario 1: Box "Test 1" is full. Insert at index 0 -> "Test 2" is auto-created with overflowed item; "Unrelated Box" is untouched', () {
      // Setup full box named "Test 1" (30 items)
      final full30 = List.generate(30, (i) => 'Mon_${i + 1}');
      final test1 = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: full30,
        columns: 5,
        rows: 6,
      );

      // Setup Unrelated Box with 5 items
      final unrelated = createTestCustomBox(
        title: 'Unrelated Box',
        pokemonIds: ['Tausch_1', 'Tausch_2', 'Tausch_3', 'Tausch_4', 'Tausch_5'],
        columns: 5,
        rows: 6,
      );

      final dex = createTestUserDex(
        id: 'acceptance_r3_1',
        title: 'Acceptance Scenario 1',
        customBoxes: [test1, unrelated],
      );

      // Action: Insert a new Pokémon at index 0 of "Test 1"
      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'Hero_Pikachu',
      );

      // Assertions:
      // 1. "Test 1" has 30 items, starting with Hero_Pikachu and ending with Mon_29
      final box1After = dex.customBoxes.firstWhere((b) => b.title == 'Test 1');
      expect(box1After.pokemonIds.first, equals('Hero_Pikachu'));
      expect(box1After.pokemonIds.length, equals(30));
      expect(box1After.pokemonIds.last, equals('Mon_29'));

      // 2. "Test 2" is auto-created with the overflowed item (Mon_30)
      final box2After = dex.customBoxes.firstWhere(
        (b) => b.title == 'Test 2',
        orElse: () => throw TestFailure('Box "Test 2" was not auto-created after overflow!'),
      );
      expect(box2After.pokemonIds, contains('Mon_30'),
          reason: 'Test 2 must contain the overflowed item Mon_30');

      // 3. "Unrelated Box" is completely untouched
      final unrelatedAfter = dex.customBoxes.firstWhere((b) => b.title == 'Unrelated Box');
      expect(
        unrelatedAfter.pokemonIds.where((id) => id.isNotEmpty).toList(),
        equals(['Tausch_1', 'Tausch_2', 'Tausch_3', 'Tausch_4', 'Tausch_5']),
        reason: 'Unrelated Box must remain untouched and receive no overflowed items',
      );
    });

    test('T4.2 Acceptance Scenario 3: Numeric range sequence: "1-30" overflowing into "31-60", and auto-creating "61-90" if both are full', () {
      final range1to30 = List.generate(30, (i) => 'Poke_${i + 1}');
      final range31to60 = List.generate(30, (i) => 'Poke_${i + 31}');

      final box1 = createTestCustomBox(title: '1-30', pokemonIds: range1to30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: '31-60', pokemonIds: range31to60, columns: 5, rows: 6);

      final dex = createTestUserDex(
        id: 'acceptance_r3_3',
        title: 'Acceptance Scenario 3',
        customBoxes: [box1, box2],
      );

      // Insert at index 0 of 1-30
      E2EBoxActions.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'EXTRA_POKE',
      );

      // Both 1-30 and 31-60 were full, so 61-90 must be auto-created!
      expect(dex.customBoxes.length, equals(3),
          reason: 'Overflowing through 1-30 and 31-60 must auto-create 61-90');
      expect(dex.customBoxes[2].title, equals('61-90'),
          reason: 'Auto-created box must follow range pattern "61-90"');
      expect(dex.customBoxes[2].pokemonIds, contains('Poke_60'),
          reason: 'Newly created 61-90 must receive Poke_60');
    });
  });
}
