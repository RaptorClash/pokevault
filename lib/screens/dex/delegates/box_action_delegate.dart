import 'package:flutter/foundation.dart';

/// Contract for handling user interactions and drag-and-drop operations within the Pokédex box view.
abstract class BoxActionDelegate {
  /// Whether this delegate supports swap actions. If false, drops on cards fall back to move/insert.
  bool get hasSwapTarget => true;

  /// Whether this delegate has a specific handler for moving multiple Pokémon.
  bool get hasMoveMultiplePokemonHandler => true;
  /// Invoked when a box slot selection is toggled in edit mode or move mode.
  void onSelectionChanged(int boxIndex, int itemIndex);

  /// Invoked when an insert operation is triggered at the specified box and index.
  void onInsertPokemon(int boxIndex, int insertIndex);

  /// Invoked when a Pokémon is moved to a target slot.
  void onMovePokemon(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  );

  /// Invoked when a Pokémon is swapped with a target slot.
  void onSwapPokemon(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  );

  /// Invoked when a Pokémon is moved with full knowledge of its source box and slot.
  void onMovePokemonWithSource(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  );

  /// Invoked when a Pokémon is swapped with full knowledge of its source box and slot.
  void onSwapPokemonWithSource(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  );

  /// Invoked when a batch of multiple selected Pokémon are moved to a target slot.
  void onMoveMultiplePokemon(
    List<String> sourceUniqueIds,
    int targetBoxIndex,
    int targetIndex,
  );

  /// Invoked when returning from the Pokémon info details screen.
  void onInfoScreenReturned();
}

/// A flexible, reusable implementation of [BoxActionDelegate] that routes calls
/// to optional closures or gracefully no-ops when no handler is provided.
class DefaultBoxActionDelegate implements BoxActionDelegate {
  final void Function(int boxIndex, int itemIndex)? onSelectionChangedHandler;
  final void Function(int boxIndex, int insertIndex)? onInsertPokemonHandler;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  )? onMovePokemonHandler;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  )? onSwapPokemonHandler;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  )? onMovePokemonWithSourceHandler;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  )? onSwapPokemonWithSourceHandler;
  final void Function(
    List<String> sourceUniqueIds,
    int targetBoxIndex,
    int targetIndex,
  )? onMoveMultiplePokemonHandler;
  final VoidCallback? onInfoScreenReturnedHandler;

  @override
  bool get hasSwapTarget =>
      onSwapPokemonHandler != null || onSwapPokemonWithSourceHandler != null;

  @override
  bool get hasMoveMultiplePokemonHandler => onMoveMultiplePokemonHandler != null;

  const DefaultBoxActionDelegate({
    this.onSelectionChangedHandler,
    this.onInsertPokemonHandler,
    this.onMovePokemonHandler,
    this.onSwapPokemonHandler,
    this.onMovePokemonWithSourceHandler,
    this.onSwapPokemonWithSourceHandler,
    this.onMoveMultiplePokemonHandler,
    this.onInfoScreenReturnedHandler,
  });

  @override
  void onSelectionChanged(int boxIndex, int itemIndex) {
    onSelectionChangedHandler?.call(boxIndex, itemIndex);
  }

  @override
  void onInsertPokemon(int boxIndex, int insertIndex) {
    onInsertPokemonHandler?.call(boxIndex, insertIndex);
  }

  @override
  void onMovePokemon(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  ) {
    if (onMovePokemonHandler != null) {
      onMovePokemonHandler!(sourceUniqueId, targetBoxIndex, targetIndex);
    } else {
      onMovePokemonWithSource(
        sourceUniqueId,
        targetBoxIndex,
        targetIndex,
        null,
        null,
      );
    }
  }

  @override
  void onSwapPokemon(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  ) {
    if (onSwapPokemonHandler != null) {
      onSwapPokemonHandler!(sourceUniqueId, targetBoxIndex, targetIndex);
    } else {
      onSwapPokemonWithSource(
        sourceUniqueId,
        targetBoxIndex,
        targetIndex,
        null,
        null,
      );
    }
  }

  @override
  void onMovePokemonWithSource(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  ) {
    if (onMovePokemonWithSourceHandler != null) {
      onMovePokemonWithSourceHandler!(
        sourceUniqueId,
        targetBoxIndex,
        targetIndex,
        sourceBoxIndex,
        sourceSlotIndex,
      );
    } else if (onMovePokemonHandler != null) {
      onMovePokemonHandler!(sourceUniqueId, targetBoxIndex, targetIndex);
    }
  }

  @override
  void onSwapPokemonWithSource(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  ) {
    if (onSwapPokemonWithSourceHandler != null) {
      onSwapPokemonWithSourceHandler!(
        sourceUniqueId,
        targetBoxIndex,
        targetIndex,
        sourceBoxIndex,
        sourceSlotIndex,
      );
    } else if (onSwapPokemonHandler != null) {
      onSwapPokemonHandler!(sourceUniqueId, targetBoxIndex, targetIndex);
    }
  }

  @override
  void onMoveMultiplePokemon(
    List<String> sourceUniqueIds,
    int targetBoxIndex,
    int targetIndex,
  ) {
    onMoveMultiplePokemonHandler?.call(
      sourceUniqueIds,
      targetBoxIndex,
      targetIndex,
    );
  }

  @override
  void onInfoScreenReturned() {
    onInfoScreenReturnedHandler?.call();
  }
}
