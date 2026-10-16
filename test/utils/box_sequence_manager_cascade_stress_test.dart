import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';

UserDex createTestDex(List<CustomBoxState> boxes) {
  return UserDex(
    id: 'challenger_m6_dex',
    title: 'Challenger M6 Dex',
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
  group('Challenger M6: Multi-Box Cascade Overflows (5+ Boxes)', () {
    test('1.1 Deep 5-box cascade overflow upon single insertion at slot 0', () {
      // 5 boxes ("Kanto 1" to "Kanto 5"), capacity 30 each (total 150 items)
      final boxes = List.generate(5, (bIdx) {
        final bNum = bIdx + 1;
        return CustomBoxState(
          title: 'Kanto $bNum',
          pokemonIds: List.generate(30, (i) => 'K${bNum}_P${i + 1}'),
          columns: 5,
          rows: 6,
        );
      });
      final dex = createTestDex(boxes);

      expect(dex.customBoxes.length, equals(5));

      // Single insertion at slot 0 of Kanto 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW_INSERTION',
      );

      // Verify cascade triggered all the way to Kanto 6
      expect(dex.customBoxes.length, equals(6));
      expect(dex.customBoxes[5].title, equals('Kanto 6'));
      expect(dex.customBoxes[5].pokemonIds, equals(['K5_P30']));

      // Verify Kanto 1 received NEW_INSERTION and shifted K1_P30 out
      expect(dex.customBoxes[0].pokemonIds.first, equals('NEW_INSERTION'));
      expect(dex.customBoxes[0].pokemonIds[1], equals('K1_P1'));
      expect(dex.customBoxes[0].pokemonIds.last, equals('K1_P29'));
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));

      // Verify Kanto 2 received K1_P30 at slot 0 and displaced K2_P30
      expect(dex.customBoxes[1].pokemonIds.first, equals('K1_P30'));
      expect(dex.customBoxes[1].pokemonIds.last, equals('K2_P29'));
      expect(dex.customBoxes[1].pokemonIds.length, equals(30));

      // Verify Kanto 3 received K2_P30 at slot 0 and displaced K3_P30
      expect(dex.customBoxes[2].pokemonIds.first, equals('K2_P30'));
      expect(dex.customBoxes[2].pokemonIds.last, equals('K3_P29'));
      expect(dex.customBoxes[2].pokemonIds.length, equals(30));

      // Verify Kanto 4 received K3_P30 at slot 0 and displaced K4_P30
      expect(dex.customBoxes[3].pokemonIds.first, equals('K3_P30'));
      expect(dex.customBoxes[3].pokemonIds.last, equals('K4_P29'));
      expect(dex.customBoxes[3].pokemonIds.length, equals(30));

      // Verify Kanto 5 received K4_P30 at slot 0 and displaced K5_P30
      expect(dex.customBoxes[4].pokemonIds.first, equals('K4_P30'));
      expect(dex.customBoxes[4].pokemonIds.last, equals('K5_P29'));
      expect(dex.customBoxes[4].pokemonIds.length, equals(30));
    });

    test('1.2 Deep 8-box cascade overflow across heterogeneous grid dimensions', () {
      // 8 full boxes with varied column/row dimensions
      final dims = [
        [2, 2], // 4
        [3, 2], // 6
        [5, 2], // 10
        [1, 5], // 5
        [2, 3], // 6
        [4, 2], // 8
        [3, 3], // 9
        [2, 2], // 4
      ];

      final boxes = List.generate(dims.length, (i) {
        final bNum = i + 1;
        final cap = dims[i][0] * dims[i][1];
        return CustomBoxState(
          title: 'Chain $bNum',
          pokemonIds: List.generate(cap, (p) => 'C${bNum}_$p'),
          columns: dims[i][0],
          rows: dims[i][1],
        );
      });
      final dex = createTestDex(boxes);

      // Insert at slot 0 of Chain 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'CHALLENGER_SEED',
      );

      // Verify Chain 9 created
      expect(dex.customBoxes.length, equals(9));
      final newBox = dex.customBoxes[8];
      expect(newBox.title, equals('Chain 9'));
      // Last item of Chain 8 was C8_3 (index 3 out of 4)
      expect(newBox.pokemonIds, equals(['C8_3']));
      // New box inherits dimensions of previous tail box (2x2)
      expect(newBox.columns, equals(2));
      expect(newBox.rows, equals(2));
      expect(newBox.capacity, equals(4));

      // Chain 1 has seed
      expect(dex.customBoxes[0].pokemonIds.first, equals('CHALLENGER_SEED'));
      expect(dex.customBoxes[0].pokemonIds.length, equals(4));

      // Verify intermediate displacements
      expect(dex.customBoxes[1].pokemonIds.first, equals('C1_3'));
      expect(dex.customBoxes[2].pokemonIds.first, equals('C2_5'));
      expect(dex.customBoxes[3].pokemonIds.first, equals('C3_9'));
      expect(dex.customBoxes[4].pokemonIds.first, equals('C4_4'));
      expect(dex.customBoxes[5].pokemonIds.first, equals('C5_5'));
      expect(dex.customBoxes[6].pokemonIds.first, equals('C6_7'));
      expect(dex.customBoxes[7].pokemonIds.first, equals('C7_8'));
    });

    test('1.3 Mid-chain cascade absorption: non-full intermediate box terminates cascade', () {
      // 6 boxes of capacity 4
      // Box 3 is non-full (2 items out of 4)
      final b1 = CustomBoxState(title: 'Seq 1', pokemonIds: ['1A', '1B', '1C', '1D'], columns: 2, rows: 2);
      final b2 = CustomBoxState(title: 'Seq 2', pokemonIds: ['2A', '2B', '2C', '2D'], columns: 2, rows: 2);
      final b3 = CustomBoxState(title: 'Seq 3', pokemonIds: ['3A', '3B'], columns: 2, rows: 2); // 2 empty slots
      final b4 = CustomBoxState(title: 'Seq 4', pokemonIds: ['4A', '4B', '4C', '4D'], columns: 2, rows: 2);
      final b5 = CustomBoxState(title: 'Seq 5', pokemonIds: ['5A', '5B', '5C', '5D'], columns: 2, rows: 2);
      final b6 = CustomBoxState(title: 'Seq 6', pokemonIds: ['6A', '6B', '6C', '6D'], columns: 2, rows: 2);

      final dex = createTestDex([b1, b2, b3, b4, b5, b6]);

      // Insert into Seq 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'ABSORB_TEST',
      );

      // Cascade must terminate at Seq 3 without reaching Seq 4, 5, 6
      expect(dex.customBoxes.length, equals(6));
      expect(b1.pokemonIds, equals(['ABSORB_TEST', '1A', '1B', '1C']));
      expect(b2.pokemonIds, equals(['1D', '2A', '2B', '2C']));
      // Seq 3 absorbs 2D at slot 0 and shifts existing
      expect(b3.pokemonIds, equals(['2D', '3A', '3B']));
      expect(b3.pokemonIds.length, equals(3)); // still under capacity 4

      // Seq 4, 5, 6 must be 100% untouched
      expect(b4.pokemonIds, equals(['4A', '4B', '4C', '4D']));
      expect(b5.pokemonIds, equals(['5A', '5B', '5C', '5D']));
      expect(b6.pokemonIds, equals(['6A', '6B', '6C', '6D']));
    });

    test('1.4 Cascade through interleaved foreign sequences & standalone boxes preserves order', () {
      final k1 = CustomBoxState(title: 'Kanto 1', pokemonIds: ['K1_A', 'K1_B'], columns: 1, rows: 2);
      final foreign1 = CustomBoxState(title: 'Unrelated Box', pokemonIds: ['U1'], columns: 1, rows: 2);
      final j1 = CustomBoxState(title: 'Johto 1', pokemonIds: ['J1_A', 'J1_B'], columns: 1, rows: 2);
      final k2 = CustomBoxState(title: 'Kanto 2', pokemonIds: ['K2_A', 'K2_B'], columns: 1, rows: 2);
      final foreign2 = CustomBoxState(title: 'Kanto Tausch', pokemonIds: ['T1', 'T2'], columns: 1, rows: 2);
      final k3 = CustomBoxState(title: 'Kanto 3', pokemonIds: ['K3_A', 'K3_B'], columns: 1, rows: 2);
      final k4 = CustomBoxState(title: 'Kanto 4', pokemonIds: ['K4_A', 'K4_B'], columns: 1, rows: 2);
      final k5 = CustomBoxState(title: 'Kanto 5', pokemonIds: ['K5_A', 'K5_B'], columns: 1, rows: 2);
      final foreign3 = CustomBoxState(title: 'Living Dex', pokemonIds: ['L1'], columns: 1, rows: 2);

      final dex = createTestDex([k1, foreign1, j1, k2, foreign2, k3, k4, k5, foreign3]);

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'KANTO_BURST',
      );

      // Kanto 6 must be auto-created
      expect(dex.customBoxes.length, equals(10));
      final k6 = dex.customBoxes.firstWhere((b) => b.title == 'Kanto 6');
      expect(k6.pokemonIds, equals(['K5_B']));

      // Kanto 6 must be inserted immediately after Kanto 5, before foreign3
      final k5Idx = dex.customBoxes.indexOf(k5);
      final k6Idx = dex.customBoxes.indexOf(k6);
      expect(k6Idx, equals(k5Idx + 1));

      // Foreign boxes and Johto 1 are completely unaffected
      expect(foreign1.pokemonIds, equals(['U1']));
      expect(foreign2.pokemonIds, equals(['T1', 'T2']));
      expect(foreign3.pokemonIds, equals(['L1']));
      expect(j1.pokemonIds, equals(['J1_A', 'J1_B']));
    });

    test('1.5 Rapid multi-insertion progressive cascade across 20 insertions', () {
      // Start with 3 boxes of capacity 2 (total 6 items)
      final boxes = List.generate(3, (i) {
        final bNum = i + 1;
        return CustomBoxState(
          title: 'Burst $bNum',
          pokemonIds: ['B${bNum}_1', 'B${bNum}_2'],
          columns: 1,
          rows: 2,
        );
      });
      final dex = createTestDex(boxes);

      // Consecutively insert 10 items at slot 0 of Burst 1
      for (int i = 1; i <= 10; i++) {
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
          pokemonId: 'ITEM_$i',
        );
      }

      // Total items = 6 + 10 = 16. With capacity 2 per box, requires 8 boxes!
      expect(dex.customBoxes.length, equals(8));
      for (int i = 0; i < 8; i++) {
        expect(dex.customBoxes[i].title, equals('Burst ${i + 1}'));
        expect(dex.customBoxes[i].pokemonIds.length, equals(2));
      }

      // First box should contain the last two inserted items in order (ITEM_10, ITEM_9)
      expect(dex.customBoxes[0].pokemonIds, equals(['ITEM_10', 'ITEM_9']));
      // Last box should contain the original earliest items displaced all the way to the end
      expect(dex.customBoxes[7].pokemonIds, equals(['B3_1', 'B3_2']));
    });
  });

  group('Challenger M6: Complex Sequence Patterns & Title Syntheses', () {
    test('2.1 Single-number padding transitions ("Box 01", "Box 09" -> "Box 10")', () {
      final p01 = BoxSequenceManager.parsePattern('Box 01');
      expect(p01.type, equals(BoxPatternType.numbered));
      expect(p01.index, equals(1));
      expect(p01.padWidth, equals(2));

      final p09 = BoxSequenceManager.parsePattern('Box 09');
      expect(p09.index, equals(9));
      expect(p09.padWidth, equals(2));

      // Next box after "Box 01", "Box 09" must be "Box 10" (retaining 2-digit width)
      final b01 = CustomBoxState(title: 'Box 01', pokemonIds: ['P1', 'P2'], columns: 1, rows: 2);
      final b09 = CustomBoxState(title: 'Box 09', pokemonIds: ['P3', 'P4'], columns: 1, rows: 2);
      expect(BoxSequenceManager.generateNextBoxTitle([b01, b09]), equals('Box 10'));

      // 3-digit padding "Box 099" -> "Box 100"
      final b099 = CustomBoxState(title: 'Box 099', pokemonIds: ['P1', 'P2'], columns: 1, rows: 2);
      expect(BoxSequenceManager.generateNextBoxTitle([b099]), equals('Box 100'));

      // Overflow test with auto-creation
      final dex = createTestDex([b01, b09]);
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 1,
        slotIndex: 0,
        pokemonId: 'OVERFLOW_MON',
      );

      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes[2].title, equals('Box 10'));
      expect(dex.customBoxes[2].pokemonIds, equals(['P4']));
    });

    test('2.2 Large number transitions ("Box 999" -> "Box 1000") and no padding corruption', () {
      final p999 = BoxSequenceManager.parsePattern('Box 999');
      expect(p999.type, equals(BoxPatternType.numbered));
      expect(p999.index, equals(999));
      expect(p999.padWidth, equals(0));

      final b999 = CustomBoxState(title: 'Box 999', pokemonIds: ['M1', 'M2'], columns: 1, rows: 2);
      expect(BoxSequenceManager.generateNextBoxTitle([b999]), equals('Box 1000'));

      final dex = createTestDex([b999]);
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'OVER_999',
      );

      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[1].title, equals('Box 1000'));
      expect(dex.customBoxes[1].pokemonIds, equals(['M2']));

      // 4-digit zero-padded "Box 0999" -> "Box 1000"
      final b0999 = CustomBoxState(title: 'Box 0999', pokemonIds: ['A']);
      expect(BoxSequenceManager.generateNextBoxTitle([b0999]), equals('Box 1000'));
    });

    test('2.3 Pure range boundary crossing and Unicode dash compatibility', () {
      // 901-1000 crossing 1000 with step 100
      final rLarge = CustomBoxState(title: '901-1000', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([rLarge]), equals('1001-1100'));

      // Zero-padded 001-050 -> 051-100
      final rPad = CustomBoxState(title: '001-050', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([rPad]), equals('051-100'));

      // Single-slot step "1-1" -> "2-2"
      final rSingle = CustomBoxState(title: '1-1', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([rSingle]), equals('2-2'));

      // Linking across dash styles
      final rHyphen = CustomBoxState(title: '1-30', pokemonIds: []);
      final rEnDash = CustomBoxState(title: '31–60', pokemonIds: []);
      final rEmDash = CustomBoxState(title: '61—90', pokemonIds: []);
      expect(BoxSequenceManager.areLinked(rHyphen, rEnDash), isTrue);
      expect(BoxSequenceManager.areLinked(rEnDash, rEmDash), isTrue);
      expect(BoxSequenceManager.generateNextBoxTitle([rHyphen, rEnDash, rEmDash]), equals('91-120'));
    });

    test('2.4 Prefix range variations (with/without parens, with/without index)', () {
      // With parens and index: "Box 1 (1-30)"
      final prIdx = CustomBoxState(title: 'Box 1 (1-30)', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([prIdx]), equals('Box 2 (31-60)'));

      // With parens and NO index: "Johto (1-30)"
      final prNoIdx = CustomBoxState(title: 'Johto (1-30)', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([prNoIdx]), equals('Johto (31-60)'));

      // Without parens: "Kanto 1-30"
      final prNoParen = CustomBoxState(title: 'Kanto 1-30', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([prNoParen]), equals('Kanto 31-60'));

      // Padding preservation in prefix range: "Johto (001-030)" -> "Johto (031-060)"
      final prPad = CustomBoxState(title: 'Johto (001-030)', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([prPad]), equals('Johto (031-060)'));
    });

    test('2.5 Alphanumeric standalone isolation and non-creation resilience', () {
      final standaloneTitles = [
        'Box 1A',
        'Box A1-Extra',
        'Living Dex 2026-X',
        'Kanto Tausch',
        'Trade 2.0',
        'Box',
        '12345',
        'Special-100',
        'Box 1-B',
      ];

      for (final title in standaloneTitles) {
        final info = BoxSequenceManager.parsePattern(title);
        expect(info.type, equals(BoxPatternType.standalone), reason: '$title must be standalone');

        final b1 = CustomBoxState(title: title, pokemonIds: ['S1', 'S2'], columns: 1, rows: 2);
        final b2 = CustomBoxState(title: title, pokemonIds: ['S3'], columns: 1, rows: 2);

        // Standalone boxes never link, even with identical titles
        expect(BoxSequenceManager.areLinked(b1, b2), isFalse);

        // Full standalone box retains item without creating second box
        final dex = createTestDex([b1]);
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
          pokemonId: 'NO_AUTOCREATE',
        );

        expect(dex.customBoxes.length, equals(1), reason: '$title must never auto-create');
        expect(dex.customBoxes[0].pokemonIds.length, equals(3));
        expect(dex.customBoxes[0].pokemonIds, contains('NO_AUTOCREATE'));
      }
    });
  });

  group('Challenger M6: Boundary Conditions & Behavioral Toggles', () {
    test('3.1 Slot 0 insertion with patternAutoCreate: false vs true', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: ['A1', 'A2'], columns: 1, rows: 2);
      final b2 = CustomBoxState(
        title: 'Test 2',
        pokemonIds: ['B1', 'B2'],
        columns: 1,
        rows: 2,
        patternAutoCreate: false, // Auto-create disabled on tail box!
      );

      final dex = createTestDex([b1, b2]);

      // Insert at slot 0 of Test 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'HEAD_INSERT',
      );

      // Cascade pushes A2 to Test 2, Test 2 pushes B2 to overflow
      // But because patternAutoCreate is false on Test 2, B2 is retained in Test 2, no Test 3 created!
      expect(dex.customBoxes.length, equals(2));
      expect(b1.pokemonIds, equals(['HEAD_INSERT', 'A1']));
      expect(b2.pokemonIds, equals(['A2', 'B1', 'B2'])); // length 3, retained to prevent loss

      // Now enable patternAutoCreate on Test 2 and insert again
      b2.patternAutoCreate = true;
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'HEAD_INSERT_2',
      );

      // Now Test 3 is created!
      expect(dex.customBoxes.length, equals(3));
      expect(dex.customBoxes[2].title, equals('Test 3'));
    });

    test('3.2 Insertion with strictLimits: false ignores capacity without cascading', () {
      // Box with autoShift: true, strictLimits: false
      final bSoftShift = CustomBoxState(
        title: 'Soft 1',
        pokemonIds: ['S1', 'S2'],
        columns: 1,
        rows: 2,
        strictLimits: false,
        autoShift: true,
      );

      // Linked box Soft 2
      final bSoft2 = CustomBoxState(
        title: 'Soft 2',
        pokemonIds: ['T1'],
        columns: 1,
        rows: 2,
      );

      final dex = createTestDex([bSoftShift, bSoft2]);

      // Insert into slot 0 of Soft 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'SOFT_MON',
      );

      // Soft 1 expands to 3 items, never spilling into Soft 2
      expect(dex.customBoxes.length, equals(2));
      expect(bSoftShift.pokemonIds, equals(['SOFT_MON', 'S1', 'S2']));
      expect(bSoft2.pokemonIds, equals(['T1']));

      // Box with autoShift: false, strictLimits: false
      final bSoftNoShift = CustomBoxState(
        title: 'Soft 3',
        pokemonIds: ['N1', 'N2'],
        columns: 1,
        rows: 2,
        strictLimits: false,
        autoShift: false,
      );

      final dex2 = createTestDex([bSoftNoShift]);
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex2,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'OVERWRITE_MON',
      );

      // Overwrites slot 0 without shifting or cascading
      expect(bSoftNoShift.pokemonIds, equals(['OVERWRITE_MON', 'N2']));
    });

    test('3.3 Insertion at slot exceeding capacity immediately triggers overflow', () {
      final b1 = CustomBoxState(title: 'Jump 1', pokemonIds: ['J1', 'J2'], columns: 1, rows: 2);
      final b2 = CustomBoxState(title: 'Jump 2', pokemonIds: ['K1'], columns: 1, rows: 2);

      final dex = createTestDex([b1, b2]);

      // Insert at slotIndex 10 (capacity is 2)
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 10,
        pokemonId: 'FAR_OUT',
      );

      // FAR_OUT immediately overflows into Jump 2 at slot 0
      expect(b1.pokemonIds, equals(['J1', 'J2']));
      expect(b2.pokemonIds, equals(['FAR_OUT', 'K1']));
      expect(dex.customBoxes.length, equals(2));
    });

    test('3.4 Multi-box empty cleanup simultaneously prunes all empty tail boxes', () {
      final b1 = CustomBoxState(title: 'Clean 1', pokemonIds: ['ROOT_ITEM'], columns: 1, rows: 2);
      final b2 = CustomBoxState(title: 'Clean 2', pokemonIds: [], columns: 1, rows: 2);
      final b3 = CustomBoxState(title: 'Clean 3', pokemonIds: [], columns: 1, rows: 2);
      final b4 = CustomBoxState(title: 'Clean 4', pokemonIds: [], columns: 1, rows: 2);
      final b5 = CustomBoxState(title: 'Clean 5', pokemonIds: [], columns: 1, rows: 2);

      final dex = createTestDex([b1, b2, b3, b4, b5]);

      BoxSequenceManager.cleanupEmptyBoxes(dex: dex, affectedBox: b1);

      // All 4 empty tail boxes deleted; root Clean 1 preserved
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Clean 1'));
      expect(dex.customBoxes[0].pokemonIds, equals(['ROOT_ITEM']));
    });

    test('3.5 Partial autoDeleteEmpty protection in multi-box cleanup', () {
      final b1 = CustomBoxState(title: 'Guard 1', pokemonIds: ['MON'], columns: 1, rows: 2);
      final b2 = CustomBoxState(title: 'Guard 2', pokemonIds: [], columns: 1, rows: 2, autoDeleteEmpty: true);
      final b3 = CustomBoxState(title: 'Guard 3', pokemonIds: [], columns: 1, rows: 2, autoDeleteEmpty: false); // Protected!
      final b4 = CustomBoxState(title: 'Guard 4', pokemonIds: [], columns: 1, rows: 2, autoDeleteEmpty: true);

      final dex = createTestDex([b1, b2, b3, b4]);

      BoxSequenceManager.cleanupEmptyBoxes(dex: dex, affectedBox: b1);

      // Guard 2 and Guard 4 deleted; Guard 1 (root) and Guard 3 (protected) retained
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes.map((b) => b.title).toList(), equals(['Guard 1', 'Guard 3']));
    });

    test('3.6 Completely emptied root box invariant: dex never reduced to zero boxes', () {
      final rootOnly = CustomBoxState(title: 'Sole 1', pokemonIds: [], columns: 1, rows: 2);
      final dex = createTestDex([rootOnly]);

      BoxSequenceManager.cleanupEmptyBoxes(dex: dex, affectedBox: rootOnly);
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Sole 1'));

      // Even if multiple boxes are empty and all have autoDeleteEmpty: true
      final e1 = CustomBoxState(title: 'Empty 1', pokemonIds: []);
      final e2 = CustomBoxState(title: 'Empty 2', pokemonIds: []);
      final dex2 = createTestDex([e1, e2]);

      BoxSequenceManager.cleanupEmptyBoxes(dex: dex2, affectedBox: e1);
      expect(dex2.customBoxes.length, equals(1));
      expect(dex2.customBoxes[0].title, equals('Empty 1'));
    });

    test('3.7 Degenerate parameter immunity without throwing exceptions', () {
      final box = CustomBoxState(title: 'Safe 1', pokemonIds: ['P1', 'P2']);
      final dex = createTestDex([box]);

      // Out of bounds boxIndex
      expect(() => BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: -5,
        slotIndex: 0,
        pokemonId: 'A',
      ), returnsNormally);

      expect(() => BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 99,
        slotIndex: 0,
        pokemonId: 'A',
      ), returnsNormally);

      // Empty pokemonId
      expect(() => BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: '',
      ), returnsNormally);
      expect(box.pokemonIds.length, equals(2));

      // Negative slotIndex in remove
      expect(() => BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: -1,
      ), returnsNormally);

      // Out of bounds slotIndex in remove
      expect(() => BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 999,
      ), returnsNormally);

      // Empty dex calls
      final emptyDex = createTestDex([]);
      expect(() => BoxSequenceManager.insertWithShiftAndOverflow(
        dex: emptyDex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'A',
      ), returnsNormally);

      expect(() => BoxSequenceManager.removeWithShiftBack(
        dex: emptyDex,
        boxIndex: 0,
        slotIndex: 0,
      ), returnsNormally);

      expect(() => BoxSequenceManager.cleanupEmptyBoxes(
        dex: emptyDex,
        affectedBox: box,
      ), returnsNormally);

      expect(() => BoxSequenceManager.movePokemon(
        dex: emptyDex,
        sourceId: 'NONE',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      ), returnsNormally);
    });
  });

  group('Challenger M6: Idempotency & Invariant Stability Under Sequential Stress', () {
    test('4.1 Rapid 50-cycle insert and remove roundtrip at slot 0 preserves exact state', () {
      final box = CustomBoxState(
        title: 'Cycle 1',
        pokemonIds: ['ROOT_A', 'ROOT_B', 'ROOT_C'],
        columns: 1,
        rows: 3,
      );
      final dex = createTestDex([box]);

      for (int i = 0; i < 50; i++) {
        // Insert item at slot 0 -> overflows ROOT_C into auto-created Cycle 2
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
          pokemonId: 'TEMP_$i',
        );

        expect(dex.customBoxes.length, equals(2));
        expect(dex.customBoxes[1].title, equals('Cycle 2'));
        expect(dex.customBoxes[1].pokemonIds, equals(['ROOT_C']));

        // Immediately remove at slot 0 -> pulls ROOT_C back from Cycle 2, deletes Cycle 2
        BoxSequenceManager.removeWithShiftBack(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
        );

        expect(dex.customBoxes.length, equals(1));
        expect(dex.customBoxes[0].title, equals('Cycle 1'));
        expect(dex.customBoxes[0].pokemonIds, equals(['ROOT_A', 'ROOT_B', 'ROOT_C']));
      }
    });

    test('4.2 10-item bulk overflow across 5 boxes followed by complete drain to empty root', () {
      final b1 = CustomBoxState(title: 'Drain 1', pokemonIds: [], columns: 1, rows: 2);
      final dex = createTestDex([b1]);

      // Insert 10 items at slot 0
      for (int i = 1; i <= 10; i++) {
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
          pokemonId: 'D_$i',
        );
      }

      // 10 items in capacity 2 = 5 boxes
      expect(dex.customBoxes.length, equals(5));
      for (int i = 0; i < 5; i++) {
        expect(dex.customBoxes[i].title, equals('Drain ${i + 1}'));
        expect(dex.customBoxes[i].pokemonIds.length, equals(2));
      }

      // Consecutively remove at slot 0 of Drain 1 ten times
      for (int i = 1; i <= 10; i++) {
        BoxSequenceManager.removeWithShiftBack(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
        );
      }

      // Drain 5, 4, 3, 2 should have been cleaned up; Drain 1 preserved empty
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Drain 1'));
      expect(dex.customBoxes[0].pokemonIds, isEmpty);
    });

    test('4.3 Independent dual-sequence concurrent stress maintains strict isolation', () {
      final a1 = CustomBoxState(title: 'Alpha 1', pokemonIds: ['A1', 'A2'], columns: 1, rows: 2);
      final a2 = CustomBoxState(title: 'Alpha 2', pokemonIds: ['A3', 'A4'], columns: 1, rows: 2);
      final b1 = CustomBoxState(title: 'Beta 1', pokemonIds: ['B1', 'B2'], columns: 1, rows: 2);
      final b2 = CustomBoxState(title: 'Beta 2', pokemonIds: ['B3', 'B4'], columns: 1, rows: 2);

      final dex = createTestDex([a1, b1, a2, b2]);

      // Alternating operations on Alpha and Beta
      for (int i = 1; i <= 5; i++) {
        // Insert into Alpha
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: dex.customBoxes.indexOf(a1),
          slotIndex: 0,
          pokemonId: 'ALPHA_$i',
        );

        // Insert into Beta
        BoxSequenceManager.insertWithShiftAndOverflow(
          dex: dex,
          boxIndex: dex.customBoxes.indexOf(b1),
          slotIndex: 0,
          pokemonId: 'BETA_$i',
        );
      }

      // Both sequences should have grown independently
      final alphaBoxes = dex.customBoxes.where((b) => b.title.startsWith('Alpha')).toList();
      final betaBoxes = dex.customBoxes.where((b) => b.title.startsWith('Beta')).toList();

      expect(alphaBoxes.length, greaterThanOrEqualTo(4));
      expect(betaBoxes.length, greaterThanOrEqualTo(4));

      // Ensure no Alpha box has Beta items and vice versa
      for (final ab in alphaBoxes) {
        for (final id in ab.pokemonIds) {
          expect(id.startsWith('B'), isFalse, reason: 'Alpha box must not contain Beta item: $id');
        }
      }

      for (final bb in betaBoxes) {
        for (final id in bb.pokemonIds) {
          expect(id.startsWith('A'), isFalse, reason: 'Beta box must not contain Alpha item: $id');
        }
      }
    });
  });

  group('Challenger M6: Cross-Box Movement & Drag-Drop Invariants', () {
    test('5.1 Cross-box move from full box into another full box cascades destination sequence', () {
      final src = CustomBoxState(title: 'Source 1', pokemonIds: ['S1', 'S2'], columns: 1, rows: 2);
      final dst1 = CustomBoxState(title: 'Dest 1', pokemonIds: ['D1', 'D2'], columns: 1, rows: 2);
      final dst2 = CustomBoxState(title: 'Dest 2', pokemonIds: ['D3'], columns: 1, rows: 2);

      final dex = createTestDex([src, dst1, dst2]);

      // Move S1 from Source 1 into Dest 1 slot 0
      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'S1',
        targetBoxIndex: 1,
        targetSlotIndex: 0,
      );

      // Source 1 lost S1
      expect(src.pokemonIds, equals(['S2']));

      // Dest 1 received S1 at slot 0, D2 overflowed to Dest 2
      expect(dst1.pokemonIds, equals(['S1', 'D1']));
      expect(dst2.pokemonIds, equals(['D2', 'D3']));
    });

    test('5.2 Intra-box move to same slot index is strict no-op', () {
      final box = CustomBoxState(title: 'Same 1', pokemonIds: ['P1', 'P2', 'P3'], columns: 1, rows: 3);
      final dex = createTestDex([box]);

      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'P2',
        targetBoxIndex: 0,
        targetSlotIndex: 1, // P2 is at index 1
      );

      expect(box.pokemonIds, equals(['P1', 'P2', 'P3']));
    });

    test('5.3 Intra-box move to empty slot preserves positions of other occupied slots', () {
      final box = CustomBoxState(title: 'EmptySlot 1', pokemonIds: ['A', '', 'B', ''], columns: 2, rows: 2);
      final dex = createTestDex([box]);

      // Move 'A' (index 0) to empty slot 1
      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      );

      // 'A' moved to slot 1, slot 0 cleared, 'B' at slot 2 untouched
      expect(box.pokemonIds, equals(['', 'A', 'B', '']));
    });
  });
}
