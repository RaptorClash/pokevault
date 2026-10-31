import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/dex/delegates/box_action_delegate.dart';

void main() {
  group('BoxActionDelegate & DefaultBoxActionDelegate TDD', () {
    test('DefaultBoxActionDelegate safely no-ops with const constructor and null handlers', () {
      const delegate = DefaultBoxActionDelegate();

      expect(() => delegate.onSelectionChanged(0, 5), returnsNormally);
      expect(() => delegate.onInsertPokemon(1, 10), returnsNormally);
      expect(() => delegate.onMovePokemon('25', 0, 1), returnsNormally);
      expect(() => delegate.onSwapPokemon('25', 1, 2), returnsNormally);
      expect(() => delegate.onMovePokemonWithSource('25', 1, 2, 0, 4), returnsNormally);
      expect(() => delegate.onSwapPokemonWithSource('25', 1, 2, 0, 4), returnsNormally);
      expect(() => delegate.onMoveMultiplePokemon(['25', '26'], 2, 3), returnsNormally);
      expect(() => delegate.onInfoScreenReturned(), returnsNormally);
    });

    test('DefaultBoxActionDelegate dispatches all actions to provided handlers', () {
      int? selBox, selItem;
      int? insBox, insIndex;
      String? moveSource;
      int? moveTargetBox, moveTargetIndex;
      String? swapSource;
      int? swapTargetBox, swapTargetIndex;
      String? moveWithSourceId;
      int? moveWithSourceTargetBox, moveWithSourceTargetIndex, moveWithSourceBox, moveWithSourceSlot;
      String? swapWithSourceId;
      int? swapWithSourceTargetBox, swapWithSourceTargetIndex, swapWithSourceBox, swapWithSourceSlot;
      List<String>? multiIds;
      int? multiTargetBox, multiTargetIndex;
      bool infoReturned = false;

      final delegate = DefaultBoxActionDelegate(
        onSelectionChangedHandler: (box, item) {
          selBox = box;
          selItem = item;
        },
        onInsertPokemonHandler: (box, insert) {
          insBox = box;
          insIndex = insert;
        },
        onMovePokemonHandler: (src, targetBox, targetIdx) {
          moveSource = src;
          moveTargetBox = targetBox;
          moveTargetIndex = targetIdx;
        },
        onSwapPokemonHandler: (src, targetBox, targetIdx) {
          swapSource = src;
          swapTargetBox = targetBox;
          swapTargetIndex = targetIdx;
        },
        onMovePokemonWithSourceHandler: (src, targetBox, targetIdx, srcBox, srcSlot) {
          moveWithSourceId = src;
          moveWithSourceTargetBox = targetBox;
          moveWithSourceTargetIndex = targetIdx;
          moveWithSourceBox = srcBox;
          moveWithSourceSlot = srcSlot;
        },
        onSwapPokemonWithSourceHandler: (src, targetBox, targetIdx, srcBox, srcSlot) {
          swapWithSourceId = src;
          swapWithSourceTargetBox = targetBox;
          swapWithSourceTargetIndex = targetIdx;
          swapWithSourceBox = srcBox;
          swapWithSourceSlot = srcSlot;
        },
        onMoveMultiplePokemonHandler: (ids, targetBox, targetIdx) {
          multiIds = ids;
          multiTargetBox = targetBox;
          multiTargetIndex = targetIdx;
        },
        onInfoScreenReturnedHandler: () {
          infoReturned = true;
        },
      );

      delegate.onSelectionChanged(2, 7);
      expect(selBox, equals(2));
      expect(selItem, equals(7));

      delegate.onInsertPokemon(3, 14);
      expect(insBox, equals(3));
      expect(insIndex, equals(14));

      delegate.onMovePokemon('p_1', 4, 15);
      expect(moveSource, equals('p_1'));
      expect(moveTargetBox, equals(4));
      expect(moveTargetIndex, equals(15));

      delegate.onSwapPokemon('p_2', 5, 16);
      expect(swapSource, equals('p_2'));
      expect(swapTargetBox, equals(5));
      expect(swapTargetIndex, equals(16));

      delegate.onMovePokemonWithSource('p_3', 6, 17, 1, 9);
      expect(moveWithSourceId, equals('p_3'));
      expect(moveWithSourceTargetBox, equals(6));
      expect(moveWithSourceTargetIndex, equals(17));
      expect(moveWithSourceBox, equals(1));
      expect(moveWithSourceSlot, equals(9));

      delegate.onSwapPokemonWithSource('p_4', 7, 18, 2, 8);
      expect(swapWithSourceId, equals('p_4'));
      expect(swapWithSourceTargetBox, equals(7));
      expect(swapWithSourceTargetIndex, equals(18));
      expect(swapWithSourceBox, equals(2));
      expect(swapWithSourceSlot, equals(8));

      delegate.onMoveMultiplePokemon(['p_5', 'p_6'], 8, 19);
      expect(multiIds, equals(['p_5', 'p_6']));
      expect(multiTargetBox, equals(8));
      expect(multiTargetIndex, equals(19));

      delegate.onInfoScreenReturned();
      expect(infoReturned, isTrue);
    });

    test('onMovePokemon fallback dispatches to onMovePokemonWithSource if only onMovePokemon is given', () {
      String? movedSrc;
      int? movedTargetBox, movedTargetIndex;

      final delegate = DefaultBoxActionDelegate(
        onMovePokemonHandler: (src, targetBox, targetIdx) {
          movedSrc = src;
          movedTargetBox = targetBox;
          movedTargetIndex = targetIdx;
        },
      );

      // When onMovePokemonWithSource is called on delegate, it falls back to onMovePokemonHandler
      delegate.onMovePokemonWithSource('test_id', 3, 12, null, null);
      expect(movedSrc, equals('test_id'));
      expect(movedTargetBox, equals(3));
      expect(movedTargetIndex, equals(12));
    });

    test('onSwapPokemon fallback dispatches to onSwapPokemonWithSource if only onSwapPokemon is given', () {
      String? swappedSrc;
      int? swappedTargetBox, swappedTargetIndex;

      final delegate = DefaultBoxActionDelegate(
        onSwapPokemonHandler: (src, targetBox, targetIdx) {
          swappedSrc = src;
          swappedTargetBox = targetBox;
          swappedTargetIndex = targetIdx;
        },
      );

      // When onSwapPokemonWithSource is called on delegate, it falls back to onSwapPokemonHandler
      delegate.onSwapPokemonWithSource('test_id_swap', 4, 13, null, null);
      expect(swappedSrc, equals('test_id_swap'));
      expect(swappedTargetBox, equals(4));
      expect(swappedTargetIndex, equals(13));
    });
  });
}
