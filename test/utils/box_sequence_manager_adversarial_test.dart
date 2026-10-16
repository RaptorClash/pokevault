import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';

void main() {
  group('Challenger M2-1: Adversarial Pattern Classification & Metadata', () {
    test('1.1 Diverse Numbered Formats and Zero-padding', () {
      final p1 = BoxSequenceManager.parsePattern('Kanto 01');
      expect(p1.type, equals(BoxPatternType.numbered));
      expect(p1.prefix, equals('Kanto'));
      expect(p1.index, equals(1));
      expect(p1.padWidth, equals(2));

      final p2 = BoxSequenceManager.parsePattern('Box 007');
      expect(p2.type, equals(BoxPatternType.numbered));
      expect(p2.prefix, equals('Box'));
      expect(p2.index, equals(7));
      expect(p2.padWidth, equals(3));

      final p3 = BoxSequenceManager.parsePattern('Test 0001');
      expect(p3.type, equals(BoxPatternType.numbered));
      expect(p3.prefix, equals('Test'));
      expect(p3.index, equals(1));
      expect(p3.padWidth, equals(4));

      final pZero = BoxSequenceManager.parsePattern('Box 0');
      expect(pZero.type, equals(BoxPatternType.numbered));
      expect(pZero.index, equals(0));
      expect(pZero.padWidth, equals(0));

      final pLarge = BoxSequenceManager.parsePattern('Box 999999');
      expect(pLarge.type, equals(BoxPatternType.numbered));
      expect(pLarge.index, equals(999999));

      final pSpaces = BoxSequenceManager.parsePattern('  Kanto   42  ');
      expect(pSpaces.type, equals(BoxPatternType.numbered));
      expect(pSpaces.prefix, equals('Kanto'));
      expect(pSpaces.index, equals(42));
    });

    test('1.2 Diverse Pure Range Formats, Zero-padding & Unicode Dashes', () {
      final pStd = BoxSequenceManager.parsePattern('1-30');
      expect(pStd.type, equals(BoxPatternType.pureRange));
      expect(pStd.rangeStart, equals(1));
      expect(pStd.rangeEnd, equals(30));
      expect(pStd.step, equals(30));
      expect(pStd.padWidth, equals(0));

      final pPad = BoxSequenceManager.parsePattern('001-030');
      expect(pPad.type, equals(BoxPatternType.pureRange));
      expect(pPad.rangeStart, equals(1));
      expect(pPad.rangeEnd, equals(30));
      expect(pPad.step, equals(30));
      expect(pPad.padWidth, equals(3));

      final pEnDash = BoxSequenceManager.parsePattern('1–30');
      expect(pEnDash.type, equals(BoxPatternType.pureRange));
      expect(pEnDash.rangeStart, equals(1));
      expect(pEnDash.rangeEnd, equals(30));

      final pEmDash = BoxSequenceManager.parsePattern('31—60');
      expect(pEmDash.type, equals(BoxPatternType.pureRange));
      expect(pEmDash.rangeStart, equals(31));
      expect(pEmDash.rangeEnd, equals(60));

      final pSpaces = BoxSequenceManager.parsePattern('  001  -  030  ');
      expect(pSpaces.type, equals(BoxPatternType.pureRange));
      expect(pSpaces.rangeStart, equals(1));
      expect(pSpaces.rangeEnd, equals(30));
      expect(pSpaces.padWidth, equals(3));

      final pSingle = BoxSequenceManager.parsePattern('151-151');
      expect(pSingle.type, equals(BoxPatternType.pureRange));
      expect(pSingle.rangeStart, equals(151));
      expect(pSingle.rangeEnd, equals(151));
      expect(pSingle.step, equals(1));

      // Inverted range should not match pure range (start > end)
      final pInverted = BoxSequenceManager.parsePattern('30-1');
      expect(pInverted.type, isNot(equals(BoxPatternType.pureRange)));
    });

    test('1.3 Prefix Range Formats (With & Without Parens, With & Without Index)', () {
      final pParenWithIdx = BoxSequenceManager.parsePattern('Box 1 (1-30)');
      expect(pParenWithIdx.type, equals(BoxPatternType.prefixRange));
      expect(pParenWithIdx.prefix, equals('Box'));
      expect(pParenWithIdx.index, equals(1));
      expect(pParenWithIdx.rangeStart, equals(1));
      expect(pParenWithIdx.rangeEnd, equals(30));
      expect(pParenWithIdx.hasParens, isTrue);

      final pParenNoIdx = BoxSequenceManager.parsePattern('Kanto (1-30)');
      expect(pParenNoIdx.type, equals(BoxPatternType.prefixRange));
      expect(pParenNoIdx.prefix, equals('Kanto'));
      expect(pParenNoIdx.index, isNull);
      expect(pParenNoIdx.rangeStart, equals(1));
      expect(pParenNoIdx.rangeEnd, equals(30));
      expect(pParenNoIdx.hasParens, isTrue);

      final pNoParen = BoxSequenceManager.parsePattern('Kanto 1-30');
      expect(pNoParen.type, equals(BoxPatternType.prefixRange));
      expect(pNoParen.prefix, equals('Kanto'));
      expect(pNoParen.rangeStart, equals(1));
      expect(pNoParen.rangeEnd, equals(30));
      expect(pNoParen.hasParens, isFalse);

      final pParenPad = BoxSequenceManager.parsePattern('Box 1 (001-030)');
      expect(pParenPad.type, equals(BoxPatternType.prefixRange));
      expect(pParenPad.padWidth, equals(3));

      final pParenEnDash = BoxSequenceManager.parsePattern('Box 1 (1–30)');
      expect(pParenEnDash.type, equals(BoxPatternType.prefixRange));
      expect(pParenEnDash.rangeStart, equals(1));
      expect(pParenEnDash.rangeEnd, equals(30));
    });

    test('1.4 Strict Standalone Classification for Edge Cases', () {
      final standaloneTitles = [
        'Kanto Tausch',
        'Kanto',
        'Kanto 1 Extra',
        'Box 1A',
        'Box 1-B',
        'Living Dex',
        'Unrelated Box',
        'Shinies',
        'Trade 1.0',
        '',
        '   ',
        'Box',
        '1',
        'Box1',
      ];

      for (final title in standaloneTitles) {
        final info = BoxSequenceManager.parsePattern(title);
        expect(
          info.type,
          equals(BoxPatternType.standalone),
          reason: 'Expected "$title" to be classified as standalone',
        );
      }
    });
  });

  group('Challenger M2-1: Adversarial Sequence Linking (areLinked)', () {
    test('2.1 Standalone boxes are strictly isolated from all boxes', () {
      final standalone = [
        CustomBoxState(title: 'Kanto Tausch', pokemonIds: []),
        CustomBoxState(title: 'Kanto', pokemonIds: []),
        CustomBoxState(title: 'Kanto 1 Extra', pokemonIds: []),
        CustomBoxState(title: 'Box 1A', pokemonIds: []),
        CustomBoxState(title: 'Living Dex', pokemonIds: []),
        CustomBoxState(title: 'Unrelated Box', pokemonIds: []),
        CustomBoxState(title: '', pokemonIds: []),
      ];

      final numberedBox = CustomBoxState(title: 'Kanto 1', pokemonIds: []);
      final rangeBox = CustomBoxState(title: '1-30', pokemonIds: []);

      for (final s in standalone) {
        expect(BoxSequenceManager.areLinked(s, numberedBox), isFalse);
        expect(BoxSequenceManager.areLinked(numberedBox, s), isFalse);
        expect(BoxSequenceManager.areLinked(s, rangeBox), isFalse);
        expect(BoxSequenceManager.areLinked(rangeBox, s), isFalse);

        // Standalone box NEVER links even to another box with the exact same title
        final sDuplicate = CustomBoxState(title: s.title, pokemonIds: []);
        expect(BoxSequenceManager.areLinked(s, sDuplicate), isFalse);
      }
    });

    test('2.2 Incompatible pattern types and mismatched attributes never link', () {
      final num = CustomBoxState(title: 'Box 1', pokemonIds: []);
      final pure = CustomBoxState(title: '1-30', pokemonIds: []);
      final prefParen = CustomBoxState(title: 'Box 1 (1-30)', pokemonIds: []);
      final prefNoParen = CustomBoxState(title: 'Box 1-30', pokemonIds: []);

      expect(BoxSequenceManager.areLinked(num, pure), isFalse);
      expect(BoxSequenceManager.areLinked(num, prefParen), isFalse);
      expect(BoxSequenceManager.areLinked(pure, prefParen), isFalse);
      expect(BoxSequenceManager.areLinked(prefParen, prefNoParen), isFalse);

      // Mismatched step in pure range
      final pure30 = CustomBoxState(title: '1-30', pokemonIds: []);
      final pure20 = CustomBoxState(title: '31-50', pokemonIds: []);
      expect(BoxSequenceManager.areLinked(pure30, pure20), isFalse);

      // Mismatched prefix in numbered boxes
      final kanto1 = CustomBoxState(title: 'Kanto 1', pokemonIds: []);
      final johto1 = CustomBoxState(title: 'Johto 1', pokemonIds: []);
      expect(BoxSequenceManager.areLinked(kanto1, johto1), isFalse);
    });

    test('2.3 Case-insensitive numbered matching and dash variation linking', () {
      final b1 = CustomBoxState(title: 'BOX 1', pokemonIds: []);
      final b2 = CustomBoxState(title: 'box 2', pokemonIds: []);
      final b3 = CustomBoxState(title: 'Box 3', pokemonIds: []);
      expect(BoxSequenceManager.areLinked(b1, b2), isTrue);
      expect(BoxSequenceManager.areLinked(b2, b3), isTrue);

      // Pure range across dash styles
      final rHyphen = CustomBoxState(title: '1-30', pokemonIds: []);
      final rEnDash = CustomBoxState(title: '31–60', pokemonIds: []);
      final rEmDash = CustomBoxState(title: '61—90', pokemonIds: []);
      expect(BoxSequenceManager.areLinked(rHyphen, rEnDash), isTrue);
      expect(BoxSequenceManager.areLinked(rEnDash, rEmDash), isTrue);
    });
  });

  group('Challenger M2-1: Adversarial Sequence Sorting & Gap Resolution', () {
    test('3.1 Numbered sequence sorting with gaps and interspersed boxes', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: []);
      final b5 = CustomBoxState(title: 'Test 5', pokemonIds: []);
      final b10 = CustomBoxState(title: 'Test 10', pokemonIds: []);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: []);
      final unrelated = CustomBoxState(title: 'Unrelated Box', pokemonIds: []);
      final johto = CustomBoxState(title: 'Johto 1', pokemonIds: []);

      final allBoxes = [unrelated, b5, johto, b10, b1, b2];

      final seq = BoxSequenceManager.getLinkedSequence(allBoxes, b5);
      expect(seq, equals([b1, b2, b5, b10]));
    });

    test('3.2 Range sorting with gaps and out-of-order lists', () {
      final r1 = CustomBoxState(title: '1-30', pokemonIds: []);
      final r3 = CustomBoxState(title: '61-90', pokemonIds: []);
      final r4 = CustomBoxState(title: '91-120', pokemonIds: []);

      final seq = BoxSequenceManager.getLinkedSequence([r4, r1, r3], r3);
      expect(seq, equals([r1, r3, r4]));
    });

    test('3.3 Duplicate indices in sequence retain stable order', () {
      final b1A = CustomBoxState(title: 'Test 1', pokemonIds: ['A']);
      final b1B = CustomBoxState(title: 'Test 1', pokemonIds: ['B']);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: ['C']);

      final allBoxes = [b1A, b2, b1B];
      final seq = BoxSequenceManager.getLinkedSequence(allBoxes, b1A);
      expect(seq, equals([b1A, b1B, b2]));
    });
  });

  group('Challenger M2-1: Adversarial Next-Title Generation', () {
    test('4.1 Numbered title generation handles gaps and preserves zero-padding', () {
      final b1 = CustomBoxState(title: 'National 01', pokemonIds: []);
      final b5 = CustomBoxState(title: 'National 05', pokemonIds: []);
      // With gap, next should be max (5) + 1 = 6 with padding 2 -> "National 06"
      expect(BoxSequenceManager.generateNextBoxTitle([b1, b5]), equals('National 06'));

      final b9 = CustomBoxState(title: 'National 09', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([b9]), equals('National 10'));

      final b99 = CustomBoxState(title: 'National 99', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([b99]), equals('National 100'));
    });

    test('4.2 Pure range title generation with zero padding and custom steps', () {
      final r1 = CustomBoxState(title: '001-030', pokemonIds: []);
      final r2 = CustomBoxState(title: '031-060', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([r1, r2]), equals('061-090'));

      // Crossing 100 boundary with 3-digit padding
      final r3 = CustomBoxState(title: '061-090', pokemonIds: []);
      final r4 = CustomBoxState(title: '091-120', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([r3, r4]), equals('121-150'));

      // Custom step of 15
      final rSmall1 = CustomBoxState(title: '1-15', pokemonIds: []);
      final rSmall2 = CustomBoxState(title: '16-30', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([rSmall1, rSmall2]), equals('31-45'));
    });

    test('4.3 Prefix range title generation with parens and padding', () {
      final pr1 = CustomBoxState(title: 'Box 1 (001-030)', pokemonIds: []);
      final pr2 = CustomBoxState(title: 'Box 2 (031-060)', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([pr1, pr2]), equals('Box 3 (061-090)'));

      final prNoIdx = CustomBoxState(title: 'Kanto (001-030)', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([prNoIdx]), equals('Kanto (031-060)'));

      final prNoParen = CustomBoxState(title: 'Kanto 001-030', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([prNoParen]), equals('Kanto 031-060'));
    });
  });

  group('Challenger M2-1: Deep Cascade & Multi-Box Isolation Verification', () {
    test('5.1 Deep 3-box cascade overflow spills into auto-created 4th box', () {
      // 3 boxes of capacity 3, all completely full
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: ['A1', 'A2', 'A3'], columns: 1, rows: 3);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: ['B1', 'B2', 'B3'], columns: 1, rows: 3);
      final b3 = CustomBoxState(title: 'Test 3', pokemonIds: ['C1', 'C2', 'C3'], columns: 1, rows: 3);
      final unrelated = CustomBoxState(title: 'Unrelated Box', pokemonIds: ['U1', 'U2'], columns: 1, rows: 3);

      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [b1, unrelated, b2, b3],
      );

      // Insert NEW at slot 0 of Test 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW',
      );

      // Verify Test 1
      expect(b1.pokemonIds, equals(['NEW', 'A1', 'A2']));
      // Verify Test 2 received A3
      expect(b2.pokemonIds, equals(['A3', 'B1', 'B2']));
      // Verify Test 3 received B3
      expect(b3.pokemonIds, equals(['B3', 'C1', 'C2']));
      // Verify Unrelated Box is strictly untouched
      expect(unrelated.pokemonIds, equals(['U1', 'U2']));

      // Verify Test 4 was auto-created and holds displaced C3
      expect(dex.customBoxes.length, equals(5));
      final b4 = dex.customBoxes.last;
      expect(b4.title, equals('Test 4'));
      expect(b4.pokemonIds, equals(['C3']));
      expect(b4.columns, equals(1));
      expect(b4.rows, equals(3));
      expect(b4.capacity, equals(3));

      // Verify relative order in customBoxes: Test 4 must be inserted directly after Test 3
      final b3Index = dex.customBoxes.indexOf(b3);
      final b4Index = dex.customBoxes.indexOf(b4);
      expect(b4Index, equals(b3Index + 1));
    });

    test('5.2 Deep reverse-shift across 4 boxes deletes tail box and preserves root', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: ['NEW', 'A1', 'A2'], columns: 1, rows: 3);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: ['A3', 'B1', 'B2'], columns: 1, rows: 3);
      final b3 = CustomBoxState(title: 'Test 3', pokemonIds: ['B3', 'C1', 'C2'], columns: 1, rows: 3);
      final b4 = CustomBoxState(title: 'Test 4', pokemonIds: ['C3'], columns: 1, rows: 3);
      final unrelated = CustomBoxState(title: 'Unrelated Box', pokemonIds: ['U1', 'U2'], columns: 1, rows: 3);

      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [b1, unrelated, b2, b3, b4],
      );

      // Remove NEW from Test 1 at slot 0
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Test 1 should pull A3 from Test 2
      expect(b1.pokemonIds, equals(['A1', 'A2', 'A3']));
      // Test 2 should pull B3 from Test 3
      expect(b2.pokemonIds, equals(['B1', 'B2', 'B3']));
      // Test 3 should pull C3 from Test 4
      expect(b3.pokemonIds, equals(['C1', 'C2', 'C3']));
      // Test 4 should be empty and auto-deleted
      expect(dex.customBoxes.contains(b4), isFalse);
      expect(dex.customBoxes.length, equals(4));
      // Unrelated Box must remain strictly intact
      expect(unrelated.pokemonIds, equals(['U1', 'U2']));
    });

    test('5.3 Standalone box overflow does not spill or auto-create', () {
      final standalone = CustomBoxState(
        title: 'Kanto Tausch',
        pokemonIds: ['T1', 'T2'],
        columns: 1,
        rows: 2,
        patternAutoCreate: true,
      );

      final other = CustomBoxState(
        title: 'Unrelated Box',
        pokemonIds: ['U1'],
        columns: 1,
        rows: 2,
      );

      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [standalone, other],
      );

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'T0',
      );

      // Standalone pattern should NOT auto-create "Kanto Tausch 2"
      expect(dex.customBoxes.length, equals(2));
      // Item retained in standalone box to prevent loss
      expect(standalone.pokemonIds, contains('T0'));
      // Other box is untouched
      expect(other.pokemonIds, equals(['U1']));
    });

    test('5.4 Root box invariant: Completely emptied root box is NEVER deleted', () {
      final root = CustomBoxState(
        title: 'Test 1',
        pokemonIds: ['Solo'],
        columns: 1,
        rows: 2,
        autoDeleteEmpty: true,
      );

      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [root],
      );

      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes.first.title, equals('Test 1'));
      expect(dex.customBoxes.first.pokemonIds, isEmpty);
    });
  });

  group('Challenger M2-1: Extreme Boundaries, Stress Cascades & Robustness', () {
    test('6.1 Negative, out-of-bounds, and empty parameters fail gracefully without exceptions', () {
      final box = CustomBoxState(title: 'Test 1', pokemonIds: ['P1', 'P2']);
      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [box],
      );

      // Empty dex calls
      final emptyDex = UserDex(
        id: '2',
        title: 'Empty',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [],
      );

      expect(() => BoxSequenceManager.insertWithShiftAndOverflow(
        dex: emptyDex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'X',
      ), returnsNormally);

      expect(() => BoxSequenceManager.removeWithShiftBack(
        dex: emptyDex,
        boxIndex: 0,
        slotIndex: 0,
      ), returnsNormally);

      expect(() => BoxSequenceManager.movePokemon(
        dex: emptyDex,
        sourceId: 'X',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      ), returnsNormally);

      // Negative indices
      expect(() => BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: -1,
        slotIndex: 0,
        pokemonId: 'X',
      ), returnsNormally);

      expect(() => BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: -1,
        slotIndex: 0,
      ), returnsNormally);

      expect(() => BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: -1,
      ), returnsNormally);

      // Slot index beyond list length in remove
      expect(() => BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 999,
      ), returnsNormally);

      // Empty pokemonId in insertion
      expect(() => BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: '',
      ), returnsNormally);
      expect(dex.customBoxes[0].pokemonIds.length, equals(2));

      // Move with nonexistent sourceId
      expect(() => BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'NONEXISTENT',
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      ), returnsNormally);
      expect(dex.customBoxes[0].pokemonIds, equals(['P1', 'P2']));
    });

    test('6.2 10-box deep cascading overflow and 10-box deep reverse-shift roundtrip', () {
      // Create 10 full boxes of capacity 2
      final boxes = List.generate(
        10,
        (i) => CustomBoxState(
          title: 'Chain ${i + 1}',
          pokemonIds: ['M${i * 2 + 1}', 'M${i * 2 + 2}'],
          columns: 1,
          rows: 2,
        ),
      );

      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: List.from(boxes),
      );

      // Insert SUPER at slot 0 of Chain 1
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'SUPER',
      );

      // Total boxes should now be 11 (Chain 11 created)
      expect(dex.customBoxes.length, equals(11));
      expect(dex.customBoxes[0].pokemonIds, equals(['SUPER', 'M1']));
      expect(dex.customBoxes[1].pokemonIds, equals(['M2', 'M3']));
      expect(dex.customBoxes[2].pokemonIds, equals(['M4', 'M5']));
      expect(dex.customBoxes[9].pokemonIds, equals(['M18', 'M19']));
      expect(dex.customBoxes[10].title, equals('Chain 11'));
      expect(dex.customBoxes[10].pokemonIds, equals(['M20']));

      // Now reverse shift by removing SUPER from Chain 1 at slot 0
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Chain 11 should have been emptied and auto-deleted
      expect(dex.customBoxes.length, equals(10));
      for (int i = 0; i < 10; i++) {
        expect(dex.customBoxes[i].title, equals('Chain ${i + 1}'));
        expect(dex.customBoxes[i].pokemonIds, equals(['M${i * 2 + 1}', 'M${i * 2 + 2}']));
      }
    });

    test('6.3 Batch removal handles malformed keys and completely emptying dex safely', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: ['A', 'B'], columns: 1, rows: 2);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: ['C', 'D'], columns: 1, rows: 2);
      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [b1, b2],
      );

      // Malformed keys mixed with valid keys
      final malformedKeys = [
        'invalid_key',
        '',
        '-1_0',
        '0_-1',
        '99_0',
        '0_99',
        '0_0', // Valid: Test 1, slot 0 ('A')
        '0_0', // Duplicate valid
      ];

      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: malformedKeys,
      );

      // 'A' was removed from Test 1, 'B' shifted left, 'C' pulled from Test 2
      expect(b1.pokemonIds, equals(['B', 'C']));
      expect(b2.pokemonIds, equals(['D']));

      // Now batch remove all remaining items ('B', 'C', 'D')
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: ['0_0', '0_1', '1_0'],
      );

      // Test 2 emptied and deleted. Root box Test 1 emptied but preserved!
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].title, equals('Test 1'));
      expect(dex.customBoxes[0].pokemonIds, isEmpty);
    });

    test('6.4 Cross-box drag & drop between standalone and numbered boxes preserves boundaries', () {
      final standalone = CustomBoxState(title: 'Living Dex', pokemonIds: ['Mew']);
      final numbered = CustomBoxState(title: 'Test 1', pokemonIds: ['Pikachu']);
      final dex = UserDex(
        id: '1',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [standalone, numbered],
      );

      // Move Mew from Living Dex to Test 1 at slot 0
      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'Mew',
        targetBoxIndex: 1,
        targetSlotIndex: 0,
      );

      expect(standalone.pokemonIds, isEmpty);
      expect(numbered.pokemonIds, equals(['Mew', 'Pikachu']));
    });
  });
}
