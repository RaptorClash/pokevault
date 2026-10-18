import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';

void main() {
  group('CustomBoxState Model Settings & Serialization', () {
    test('Default values match specification', () {
      final box = CustomBoxState(title: 'Box 1', pokemonIds: []);
      expect(box.columns, equals(6));
      expect(box.rows, equals(5));
      expect(box.capacity, equals(30));
      expect(box.autoFlow, isFalse);
      expect(box.autoShift, isTrue);
      expect(box.strictLimits, isTrue);
      expect(box.patternAutoCreate, isTrue);
      expect(box.autoDeleteEmpty, isTrue);
    });

    test('Custom grid dimensions calculate correct capacity', () {
      final box2x2 = CustomBoxState(title: 'Small', pokemonIds: [], columns: 2, rows: 2);
      expect(box2x2.capacity, equals(4));

      final box6x5 = CustomBoxState(title: 'Wide', pokemonIds: [], columns: 6, rows: 5);
      expect(box6x5.capacity, equals(30));
    });

    test('copyWith preserves properties and applies overrides', () {
      final original = CustomBoxState(
        title: 'Original',
        pokemonIds: ['P1', 'P2'],
        columns: 4,
        rows: 4,
        autoShift: false,
        strictLimits: false,
        patternAutoCreate: false,
        autoDeleteEmpty: false,
      );

      final copy = original.copyWith(
        title: 'Copy',
        autoShift: true,
      );

      expect(copy.title, equals('Copy'));
      expect(copy.pokemonIds, equals(['P1', 'P2']));
      expect(copy.columns, equals(4));
      expect(copy.rows, equals(4));
      expect(copy.autoShift, isTrue);
      expect(copy.strictLimits, isFalse);
      expect(copy.patternAutoCreate, isFalse);
      expect(copy.autoDeleteEmpty, isFalse);
    });

    test('toMap and fromMap serialize and deserialize all behavioral settings', () {
      final original = CustomBoxState(
        title: 'Settings Box',
        pokemonIds: ['Mon_1', 'Mon_2'],
        regionKey: 'kanto',
        columns: 4,
        rows: 5,
        autoFlow: false,
        autoShift: false,
        strictLimits: true,
        patternAutoCreate: false,
        autoDeleteEmpty: true,
      );

      final map = original.toMap();
      expect(map['title'], equals('Settings Box'));
      expect(map['autoShift'], isFalse);
      expect(map['strictLimits'], isTrue);
      expect(map['patternAutoCreate'], isFalse);
      expect(map['autoDeleteEmpty'], isTrue);

      final restored = CustomBoxState.fromMap(map);
      expect(restored.title, equals('Settings Box'));
      expect(restored.pokemonIds, equals(['Mon_1', 'Mon_2']));
      expect(restored.regionKey, equals('kanto'));
      expect(restored.columns, equals(4));
      expect(restored.rows, equals(5));
      expect(restored.autoShift, isFalse);
      expect(restored.strictLimits, isTrue);
      expect(restored.patternAutoCreate, isFalse);
      expect(restored.autoDeleteEmpty, isTrue);
    });

    test('fromMap applies defaults for legacy maps missing new boolean keys', () {
      final legacyMap = {
        'title': 'Legacy Box',
        'pokemonIds': ['Old_1'],
        'columns': 5,
        'rows': 6,
      };

      final restored = CustomBoxState.fromMap(legacyMap);
      expect(restored.autoShift, isTrue);
      expect(restored.strictLimits, isTrue);
      expect(restored.patternAutoCreate, isTrue);
      expect(restored.autoDeleteEmpty, isTrue);
    });
  });

  group('Pattern Classification & Parsing', () {
    test('Numbered suffix titles', () {
      final info1 = BoxSequenceManager.parsePattern('Kanto 1');
      expect(info1.type, equals(BoxPatternType.numbered));
      expect(info1.prefix, equals('Kanto'));
      expect(info1.index, equals(1));
      expect(info1.padWidth, equals(0));

      final info2 = BoxSequenceManager.parsePattern('Test 12');
      expect(info2.type, equals(BoxPatternType.numbered));
      expect(info2.prefix, equals('Test'));
      expect(info2.index, equals(12));

      final infoZeroPad = BoxSequenceManager.parsePattern('National 01');
      expect(infoZeroPad.type, equals(BoxPatternType.numbered));
      expect(infoZeroPad.prefix, equals('National'));
      expect(infoZeroPad.index, equals(1));
      expect(infoZeroPad.padWidth, equals(2));
    });

    test('Pure range titles', () {
      final info = BoxSequenceManager.parsePattern('1-30');
      expect(info.type, equals(BoxPatternType.pureRange));
      expect(info.rangeStart, equals(1));
      expect(info.rangeEnd, equals(30));
      expect(info.step, equals(30));
      expect(info.padWidth, equals(0));

      final infoZeroPad = BoxSequenceManager.parsePattern('001-030');
      expect(infoZeroPad.type, equals(BoxPatternType.pureRange));
      expect(infoZeroPad.rangeStart, equals(1));
      expect(infoZeroPad.rangeEnd, equals(30));
      expect(infoZeroPad.step, equals(30));
      expect(infoZeroPad.padWidth, equals(3));
    });

    test('Prefix range with parentheses', () {
      final infoWithIndex = BoxSequenceManager.parsePattern('Box 1 (1-30)');
      expect(infoWithIndex.type, equals(BoxPatternType.prefixRange));
      expect(infoWithIndex.prefix, equals('Box'));
      expect(infoWithIndex.index, equals(1));
      expect(infoWithIndex.rangeStart, equals(1));
      expect(infoWithIndex.rangeEnd, equals(30));
      expect(infoWithIndex.step, equals(30));
      expect(infoWithIndex.hasParens, isTrue);

      final infoNoIndex = BoxSequenceManager.parsePattern('Kanto (1-30)');
      expect(infoNoIndex.type, equals(BoxPatternType.prefixRange));
      expect(infoNoIndex.prefix, equals('Kanto'));
      expect(infoNoIndex.index, isNull);
      expect(infoNoIndex.rangeStart, equals(1));
      expect(infoNoIndex.rangeEnd, equals(30));
      expect(infoNoIndex.hasParens, isTrue);
    });

    test('Prefix range without parentheses', () {
      final info = BoxSequenceManager.parsePattern('Kanto 1-30');
      expect(info.type, equals(BoxPatternType.prefixRange));
      expect(info.prefix, equals('Kanto'));
      expect(info.rangeStart, equals(1));
      expect(info.rangeEnd, equals(30));
      expect(info.step, equals(30));
      expect(info.hasParens, isFalse);
    });

    test('Standalone / Unrelated titles', () {
      final t1 = BoxSequenceManager.parsePattern('Kanto Tausch');
      expect(t1.type, equals(BoxPatternType.standalone));

      final t2 = BoxSequenceManager.parsePattern('Unrelated Box');
      expect(t2.type, equals(BoxPatternType.standalone));

      final t3 = BoxSequenceManager.parsePattern('Shinies');
      expect(t3.type, equals(BoxPatternType.standalone));

      final t4 = BoxSequenceManager.parsePattern('');
      expect(t4.type, equals(BoxPatternType.standalone));

      final t5 = BoxSequenceManager.parsePattern('   ');
      expect(t5.type, equals(BoxPatternType.standalone));
    });

    test('Unicode hyphens (en-dash, em-dash) are supported in ranges', () {
      final enDash = BoxSequenceManager.parsePattern('1–30');
      expect(enDash.type, equals(BoxPatternType.pureRange));
      expect(enDash.rangeStart, equals(1));
      expect(enDash.rangeEnd, equals(30));

      final emDash = BoxSequenceManager.parsePattern('31—60');
      expect(emDash.type, equals(BoxPatternType.pureRange));
      expect(emDash.rangeStart, equals(31));
      expect(emDash.rangeEnd, equals(60));
    });
  });

  group('Sequence Linking (areLinked)', () {
    test('Standalone boxes never link to anything', () {
      final boxA = CustomBoxState(title: 'Unrelated Box', pokemonIds: []);
      final boxB = CustomBoxState(title: 'Test 1', pokemonIds: []);
      final boxC = CustomBoxState(title: 'Unrelated Box', pokemonIds: []);

      expect(BoxSequenceManager.areLinked(boxA, boxB), isFalse);
      expect(BoxSequenceManager.areLinked(boxB, boxA), isFalse);
      expect(BoxSequenceManager.areLinked(boxA, boxC), isFalse);
    });

    test('Numbered suffix boxes link when prefixes match case-insensitively', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: []);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: []);
      final bCase = CustomBoxState(title: 'test 3', pokemonIds: []);
      final bOther = CustomBoxState(title: 'Other 1', pokemonIds: []);

      expect(BoxSequenceManager.areLinked(b1, b2), isTrue);
      expect(BoxSequenceManager.areLinked(b1, bCase), isTrue);
      expect(BoxSequenceManager.areLinked(b1, bOther), isFalse);
    });

    test('Pure range boxes link when steps match', () {
      final r1 = CustomBoxState(title: '1-30', pokemonIds: []);
      final r2 = CustomBoxState(title: '31-60', pokemonIds: []);
      final rDiff = CustomBoxState(title: '31-50', pokemonIds: []);

      expect(BoxSequenceManager.areLinked(r1, r2), isTrue);
      expect(BoxSequenceManager.areLinked(r1, rDiff), isFalse);
    });

    test('Prefix range boxes link when prefix and step match', () {
      final pr1 = CustomBoxState(title: 'Box 1 (1-30)', pokemonIds: []);
      final pr2 = CustomBoxState(title: 'Box 2 (31-60)', pokemonIds: []);
      final prNoParen = CustomBoxState(title: 'Box 1-30', pokemonIds: []);

      expect(BoxSequenceManager.areLinked(pr1, pr2), isTrue);
      expect(BoxSequenceManager.areLinked(pr1, prNoParen), isFalse);
    });

    test('Different pattern types never link', () {
      final numBox = CustomBoxState(title: 'Box 1', pokemonIds: []);
      final rangeBox = CustomBoxState(title: '1-30', pokemonIds: []);
      final prefRange = CustomBoxState(title: 'Box 1 (1-30)', pokemonIds: []);

      expect(BoxSequenceManager.areLinked(numBox, rangeBox), isFalse);
      expect(BoxSequenceManager.areLinked(numBox, prefRange), isFalse);
      expect(BoxSequenceManager.areLinked(rangeBox, prefRange), isFalse);
    });
  });

  group('Linked Sequence Resolution (getLinkedSequence)', () {
    test('Standalone box returns single item list', () {
      final standalone = CustomBoxState(title: 'Solo Box', pokemonIds: []);
      final other = CustomBoxState(title: 'Other Box', pokemonIds: []);

      final seq = BoxSequenceManager.getLinkedSequence([standalone, other], standalone);
      expect(seq, equals([standalone]));
    });

    test('Numbered sequence is sorted ascending by index', () {
      final b3 = CustomBoxState(title: 'Test 3', pokemonIds: []);
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: []);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: []);
      final unrelated = CustomBoxState(title: 'Unrelated Box', pokemonIds: []);

      final seq = BoxSequenceManager.getLinkedSequence([b3, unrelated, b1, b2], b1);
      expect(seq, equals([b1, b2, b3]));
    });

    test('Pure range sequence is sorted ascending by range start', () {
      final r2 = CustomBoxState(title: '31-60', pokemonIds: []);
      final r1 = CustomBoxState(title: '1-30', pokemonIds: []);
      final r3 = CustomBoxState(title: '61-90', pokemonIds: []);

      final seq = BoxSequenceManager.getLinkedSequence([r3, r1, r2], r2);
      expect(seq, equals([r1, r2, r3]));
    });
  });

  group('Next Box Title Generation (generateNextBoxTitle)', () {
    test('Empty list returns Box 1', () {
      expect(BoxSequenceManager.generateNextBoxTitle([]), equals('Box 1'));
    });

    test('Numbered sequence generates next index', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: []);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([b1, b2]), equals('Test 3'));

      // With gap
      final bGap = CustomBoxState(title: 'Test 5', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([b1, bGap]), equals('Test 6'));
    });

    test('Zero-padded numbered sequence preserves padding', () {
      final b1 = CustomBoxState(title: 'National 01', pokemonIds: []);
      final b2 = CustomBoxState(title: 'National 02', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([b1, b2]), equals('National 03'));
    });

    test('Pure range sequence generates next range', () {
      final r1 = CustomBoxState(title: '1-30', pokemonIds: []);
      final r2 = CustomBoxState(title: '31-60', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([r1, r2]), equals('61-90'));
    });

    test('Prefix range with parens and index generates next title', () {
      final pr1 = CustomBoxState(title: 'Box 1 (1-30)', pokemonIds: []);
      final pr2 = CustomBoxState(title: 'Box 2 (31-60)', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([pr1, pr2]), equals('Box 3 (61-90)'));
    });

    test('Prefix range with parens without index generates next title', () {
      final pr1 = CustomBoxState(title: 'Kanto (1-30)', pokemonIds: []);
      final pr2 = CustomBoxState(title: 'Kanto (31-60)', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([pr1, pr2]), equals('Kanto (61-90)'));
    });

    test('Prefix range without parens generates next title', () {
      final pr1 = CustomBoxState(title: 'Kanto 1-30', pokemonIds: []);
      final pr2 = CustomBoxState(title: 'Kanto 31-60', pokemonIds: []);
      expect(BoxSequenceManager.generateNextBoxTitle([pr1, pr2]), equals('Kanto 61-90'));
    });
  });

  group('insertWithShiftAndOverflow Unit Tests', () {
    test('Under capacity insertion does not trigger overflow', () {
      final box = CustomBoxState(title: 'Test 1', pokemonIds: ['P1', 'P2'], columns: 5, rows: 6);
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

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 1,
        pokemonId: 'NEW',
      );

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].pokemonIds, equals(['P1', 'NEW', 'P2']));
    });

    test('strictLimits = false appends beyond capacity without overflow', () {
      final full4 = ['A', 'B', 'C', 'D'];
      final box = CustomBoxState(
        title: 'Test 1',
        pokemonIds: full4,
        columns: 2,
        rows: 2,
        strictLimits: false,
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
        customBoxes: [box],
      );

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'EXTRA',
      );

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].pokemonIds.length, equals(5));
      expect(dex.customBoxes[0].pokemonIds.first, equals('EXTRA'));
    });

    test('patternAutoCreate = false retains overflow in last box instead of creating new box', () {
      final full4 = ['A', 'B', 'C', 'D'];
      final box = CustomBoxState(
        title: 'Test 1',
        pokemonIds: full4,
        columns: 2,
        rows: 2,
        patternAutoCreate: false,
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
        customBoxes: [box],
      );

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'NEW',
      );

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes[0].pokemonIds, contains('D'));
    });
  });

  group('movePokemon Unit Tests', () {
    test('Intra-box move to same slot is a strict no-op', () {
      final box = CustomBoxState(title: 'Box 1', pokemonIds: ['A', 'B', 'C']);
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

      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'B',
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      );

      expect(dex.customBoxes[0].pokemonIds, equals(['A', 'B', 'C']));
    });

    test('Intra-box move with autoShift = false performs swap', () {
      final box = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['A', 'B', 'C'],
        autoShift: false,
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
        customBoxes: [box],
      );

      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 0,
        targetSlotIndex: 2,
      );

      // Swapped A and C
      expect(dex.customBoxes[0].pokemonIds, equals(['C', 'B', 'A']));
    });
  });

  group('removeWithShiftBack & cleanupEmptyBoxes Unit Tests', () {
    test('Disabled autoShift sets slot to empty string without pulling from next box', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: ['A', 'B'], autoShift: false);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: ['C', 'D'], autoShift: false);
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

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      expect(dex.customBoxes[0].pokemonIds, equals(['', 'B']));
      expect(dex.customBoxes[1].pokemonIds, equals(['C', 'D']));
    });

    test('cleanupEmptyBoxes preserves single remaining box in dex', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: []);
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
        customBoxes: [b1],
      );

      BoxSequenceManager.cleanupEmptyBoxes(dex: dex, affectedBox: b1);
      expect(dex.customBoxes.length, equals(1));
    });

    test('cleanupEmptyBoxes preserves boxes when autoDeleteEmpty is false', () {
      final b1 = CustomBoxState(title: 'Test 1', pokemonIds: ['A'], autoDeleteEmpty: false);
      final b2 = CustomBoxState(title: 'Test 2', pokemonIds: [], autoDeleteEmpty: false);
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

      BoxSequenceManager.cleanupEmptyBoxes(dex: dex, affectedBox: b1);
      expect(dex.customBoxes.length, equals(2));
    });
  });
}
