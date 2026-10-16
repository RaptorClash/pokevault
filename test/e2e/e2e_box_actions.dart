import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';

/// Function signature types matching the BoxSequenceManager contract in PROJECT.md
typedef MovePokemonHandler = void Function({
  required UserDex dex,
  required String sourceId,
  required int targetBoxIndex,
  required int targetSlotIndex,
});

typedef InsertPokemonHandler = void Function({
  required UserDex dex,
  required int boxIndex,
  required int slotIndex,
  required String pokemonId,
});

typedef RemovePokemonHandler = void Function({
  required UserDex dex,
  required int boxIndex,
  required int slotIndex,
});

typedef BatchRemoveHandler = void Function({
  required UserDex dex,
  required List<String> selectedKeys,
});

typedef CleanupEmptyBoxesHandler = void Function({
  required UserDex dex,
  required CustomBoxState affectedBox,
});

/// Opaque test action runner for Pokevault box operations.
/// In production, these operations are performed via DexScreen and BoxSequenceManager.
class E2EBoxActions {
  static MovePokemonHandler? defaultMoveHandler;
  static InsertPokemonHandler? defaultInsertHandler;
  static RemovePokemonHandler? defaultRemoveHandler;
  static BatchRemoveHandler? defaultBatchRemoveHandler;
  static CleanupEmptyBoxesHandler? defaultCleanupHandler;

  static MovePokemonHandler? _overrideMoveHandler;
  static InsertPokemonHandler? _overrideInsertHandler;
  static RemovePokemonHandler? _overrideRemoveHandler;
  static BatchRemoveHandler? _overrideBatchRemoveHandler;
  static CleanupEmptyBoxesHandler? _overrideCleanupHandler;

  static void setHandlers({
    MovePokemonHandler? moveHandler,
    InsertPokemonHandler? insertHandler,
    RemovePokemonHandler? removeHandler,
    BatchRemoveHandler? batchRemoveHandler,
    CleanupEmptyBoxesHandler? cleanupHandler,
  }) {
    _overrideMoveHandler = moveHandler;
    _overrideInsertHandler = insertHandler;
    _overrideRemoveHandler = removeHandler;
    _overrideBatchRemoveHandler = batchRemoveHandler;
    _overrideCleanupHandler = cleanupHandler;
  }

  static void setProductionHandlers({
    MovePokemonHandler? moveHandler,
    InsertPokemonHandler? insertHandler,
    RemovePokemonHandler? removeHandler,
    BatchRemoveHandler? batchRemoveHandler,
    CleanupEmptyBoxesHandler? cleanupHandler,
  }) {
    defaultMoveHandler = moveHandler;
    defaultInsertHandler = insertHandler;
    defaultRemoveHandler = removeHandler;
    defaultBatchRemoveHandler = batchRemoveHandler;
    defaultCleanupHandler = cleanupHandler;
  }

  static void resetHandlers() {
    _overrideMoveHandler = null;
    _overrideInsertHandler = null;
    _overrideRemoveHandler = null;
    _overrideBatchRemoveHandler = null;
    _overrideCleanupHandler = null;
  }

  /// Executes move/drag-and-drop Pokémon operation.
  static void movePokemon({
    required UserDex dex,
    required String sourceId,
    required int targetBoxIndex,
    required int targetSlotIndex,
  }) {
    final handler = _overrideMoveHandler ?? defaultMoveHandler;
    if (handler != null) {
      handler(
        dex: dex,
        sourceId: sourceId,
        targetBoxIndex: targetBoxIndex,
        targetSlotIndex: targetSlotIndex,
      );
      return;
    }

    BoxSequenceManager.movePokemon(
      dex: dex,
      sourceId: sourceId,
      targetBoxIndex: targetBoxIndex,
      targetSlotIndex: targetSlotIndex,
    );
  }

  /// Executes insertion with shift and overflow operation.
  static void insertWithShiftAndOverflow({
    required UserDex dex,
    required int boxIndex,
    required int slotIndex,
    required String pokemonId,
  }) {
    final handler = _overrideInsertHandler ?? defaultInsertHandler;
    if (handler != null) {
      handler(
        dex: dex,
        boxIndex: boxIndex,
        slotIndex: slotIndex,
        pokemonId: pokemonId,
      );
      return;
    }

    BoxSequenceManager.insertWithShiftAndOverflow(
      dex: dex,
      boxIndex: boxIndex,
      slotIndex: slotIndex,
      pokemonId: pokemonId,
    );
  }

  /// Executes remove with backward shift operation.
  static void removeWithShiftBack({
    required UserDex dex,
    required int boxIndex,
    required int slotIndex,
  }) {
    final handler = _overrideRemoveHandler ?? defaultRemoveHandler;
    if (handler != null) {
      handler(
        dex: dex,
        boxIndex: boxIndex,
        slotIndex: slotIndex,
      );
      return;
    }

    BoxSequenceManager.removeWithShiftBack(
      dex: dex,
      boxIndex: boxIndex,
      slotIndex: slotIndex,
    );
  }

  /// Executes batch removal with shift back.
  static void batchRemoveWithShiftBack({
    required UserDex dex,
    required List<String> selectedKeys,
  }) {
    final handler = _overrideBatchRemoveHandler ?? defaultBatchRemoveHandler;
    if (handler != null) {
      handler(
        dex: dex,
        selectedKeys: selectedKeys,
      );
      return;
    }

    BoxSequenceManager.batchRemoveWithShiftBack(
      dex: dex,
      selectedKeys: selectedKeys,
    );
  }

  /// Executes empty box cleanup.
  static void cleanupEmptyBoxes({
    required UserDex dex,
    required CustomBoxState affectedBox,
  }) {
    final handler = _overrideCleanupHandler ?? defaultCleanupHandler;
    if (handler != null) {
      handler(
        dex: dex,
        affectedBox: affectedBox,
      );
      return;
    }

    BoxSequenceManager.cleanupEmptyBoxes(
      dex: dex,
      affectedBox: affectedBox,
    );
  }
}
