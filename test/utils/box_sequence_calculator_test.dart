import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_calculator.dart';

void main() {
  group('BoxSequenceCalculator Isolated Tests (TDD)', () {
    test('parsePattern correctly classifies pure range, prefix range, numbered, and standalone', () {
      final pure = BoxSequenceCalculator.parsePattern('1-30');
      expect(pure.type, equals(BoxPatternType.pureRange));
      expect(pure.rangeStart, equals(1));
      expect(pure.rangeEnd, equals(30));
      expect(pure.step, equals(30));

      final prefixParen = BoxSequenceCalculator.parsePattern('Kanto (1-30)');
      expect(prefixParen.type, equals(BoxPatternType.prefixRange));
      expect(prefixParen.prefix, equals('Kanto'));
      expect(prefixParen.hasParens, isTrue);

      final prefixNoParen = BoxSequenceCalculator.parsePattern('Kanto 1-30');
      expect(prefixNoParen.type, equals(BoxPatternType.prefixRange));
      expect(prefixNoParen.prefix, equals('Kanto'));
      expect(prefixNoParen.hasParens, isFalse);

      final numbered = BoxSequenceCalculator.parsePattern('Box 4');
      expect(numbered.type, equals(BoxPatternType.numbered));
      expect(numbered.prefix, equals('Box'));
      expect(numbered.index, equals(4));

      final standalone = BoxSequenceCalculator.parsePattern('My Shinies');
      expect(standalone.type, equals(BoxPatternType.standalone));
      expect(standalone.prefix, equals('My Shinies'));
    });

    test('areLinked determines whether two boxes belong to same sequence', () {
      final b1 = CustomBoxState(title: 'Box 1', pokemonIds: []);
      final b2 = CustomBoxState(title: 'Box 2', pokemonIds: []);
      final bDiff = CustomBoxState(title: 'Kanto 1', pokemonIds: []);
      final bStandalone = CustomBoxState(title: 'Shinies', pokemonIds: []);

      expect(BoxSequenceCalculator.areLinked(b1, b2), isTrue);
      expect(BoxSequenceCalculator.areLinked(b1, bDiff), isFalse);
      expect(BoxSequenceCalculator.areLinked(b1, bStandalone), isFalse);
    });

    test('getLinkedSequence returns sorted linked boxes', () {
      final b3 = CustomBoxState(title: 'Box 3', pokemonIds: []);
      final b1 = CustomBoxState(title: 'Box 1', pokemonIds: []);
      final b2 = CustomBoxState(title: 'Box 2', pokemonIds: []);
      final standalone = CustomBoxState(title: 'Shinies', pokemonIds: []);

      final linked = BoxSequenceCalculator.getLinkedSequence(
        [b3, standalone, b1, b2],
        b2,
      );

      expect(linked.length, equals(3));
      expect(linked[0].title, equals('Box 1'));
      expect(linked[1].title, equals('Box 2'));
      expect(linked[2].title, equals('Box 3'));
    });

    test('generateNextBoxTitle computes next title in sequence', () {
      final numBox = CustomBoxState(title: 'Box 2', pokemonIds: []);
      expect(BoxSequenceCalculator.generateNextBoxTitle([numBox]), equals('Box 3'));

      final rangeBox = CustomBoxState(title: '1-30', pokemonIds: []);
      expect(BoxSequenceCalculator.generateNextBoxTitle([rangeBox]), equals('31-60'));

      final prefRangeBox = CustomBoxState(title: 'Kanto (1-30)', pokemonIds: []);
      expect(BoxSequenceCalculator.generateNextBoxTitle([prefRangeBox]), equals('Kanto (31-60)'));
    });

    test('BoxSlotDragData serializes and deserializes drag payloads', () {
      const data = BoxSlotDragData(boxIndex: 2, slotIndex: 15, uniqueId: '25_f');
      expect(data.boxIndex, equals(2));
      expect(data.slotIndex, equals(15));
      expect(data.uniqueId, equals('25_f'));
      final serialized = BoxSlotDragData.serialize(2, 15, '25_f');
      expect(serialized, equals('SLOT:2:15:25_f'));

      final parsed = BoxSlotDragData.tryParse(serialized);
      expect(parsed, isNotNull);
      expect(parsed!.boxIndex, equals(2));
      expect(parsed.slotIndex, equals(15));
      expect(parsed.uniqueId, equals('25_f'));
    });
  });
}
