import '../models/user_dex.dart';
import 'box_sequence_calculator.dart';
import 'dex_logic_helper.dart';

export 'box_sequence_calculator.dart';

class _BatchTarget {
  final int boxIndex;
  final int slotIndex;
  final CustomBoxState box;
  final String pokemonId;

  _BatchTarget(this.boxIndex, this.slotIndex, this.box, this.pokemonId);
}

/// Manages intelligent box sequencing, cascading item overflow, auto-shifting, and range title generation.
class BoxSequenceManager {
  /// Packs entries sequentially in all special boxes (trades, gifts, forms, etc.)
  /// removing any middle gaps and consolidating trailing empty slots.
  /// Returns `true` if any custom box was reordered or modified.
  static bool packSpecialBoxes(UserDex dex) =>
      BoxSequenceCalculator.packSpecialBoxes(dex);

  /// Parses a box title and classifies it into a [BoxPatternType] with extracted metadata.
  static BoxPatternInfo parsePattern(String title) =>
      BoxSequenceCalculator.parsePattern(title);

  /// Determines whether two boxes belong to the same logical sequence.
  static bool areLinked(CustomBoxState a, CustomBoxState b) =>
      BoxSequenceCalculator.areLinked(a, b);

  /// Returns all boxes linked with [targetBox], sorted in logical sequence order.
  static List<CustomBoxState> getLinkedSequence(
    List<CustomBoxState> allBoxes,
    CustomBoxState targetBox,
  ) =>
      BoxSequenceCalculator.getLinkedSequence(allBoxes, targetBox);

  /// Generates the next box title in the sequence represented by [linkedBoxes].
  static String generateNextBoxTitle(List<CustomBoxState> linkedBoxes) =>
      BoxSequenceCalculator.generateNextBoxTitle(linkedBoxes);

  /// Inserts a Pokémon at [slotIndex] in [dex.customBoxes[boxIndex]],
  /// shifts subsequent items right, and cascades any overflow along
  /// the linked box sequence. Auto-creates a new box if the sequence
  /// is full and [patternAutoCreate] is true.
  static void insertWithShiftAndOverflow({
    required UserDex dex,
    required int boxIndex,
    required int slotIndex,
    required String pokemonId,
  }) {
    if (boxIndex < 0 || boxIndex >= dex.customBoxes.length) return;
    if (pokemonId.isEmpty) return;

    final startBox = dex.customBoxes[boxIndex];
    final linkedBoxes = getLinkedSequence(dex.customBoxes, startBox);
    int seqIdx = linkedBoxes.indexOf(startBox);
    if (seqIdx == -1) {
      seqIdx = 0;
    }

    CustomBoxState currentBox = startBox;
    int currentSlot = slotIndex;
    String itemToInsert = pokemonId;

    while (true) {
      final capacity = currentBox.capacity;
      String? overflowItem;

      if (!currentBox.strictLimits) {
        // Strict limits disabled: insert with shift or append, no overflow
        if (currentBox.autoShift) {
          if (currentSlot >= currentBox.pokemonIds.length) {
            while (currentBox.pokemonIds.length < currentSlot) {
              currentBox.pokemonIds.add("");
            }
            currentBox.pokemonIds.add(itemToInsert);
          } else {
            final hasDownstreamPlaceholder = currentBox.pokemonIds
                .skip(currentSlot)
                .any(DexLogicHelper.isPlaceholder);

            if (hasDownstreamPlaceholder) {
              int firstEmptyIdx = -1;
              for (int i = currentSlot; i < currentBox.pokemonIds.length; i++) {
                if (DexLogicHelper.isPlaceholder(currentBox.pokemonIds[i])) {
                  break;
                }
                if (currentBox.pokemonIds[i].isEmpty) {
                  firstEmptyIdx = i;
                  break;
                }
              }
              if (firstEmptyIdx != -1) {
                for (int i = firstEmptyIdx; i > currentSlot; i--) {
                  currentBox.pokemonIds[i] = currentBox.pokemonIds[i - 1];
                }
                currentBox.pokemonIds[currentSlot] = itemToInsert;
              } else {
                currentBox.pokemonIds.insert(currentSlot, itemToInsert);
              }
            } else {
              currentBox.pokemonIds.insert(currentSlot, itemToInsert);
            }
          }
        } else {
          while (currentBox.pokemonIds.length <= currentSlot) {
            currentBox.pokemonIds.add("");
          }
          currentBox.pokemonIds[currentSlot] = itemToInsert;
        }
        break;
      }

      // Strict limits enabled
      if (currentSlot >= capacity) {
        // Appending at or past capacity on a full box
        overflowItem = itemToInsert;
      } else {
        if (currentBox.autoShift) {
          if (currentSlot >= currentBox.pokemonIds.length) {
            while (currentBox.pokemonIds.length < currentSlot) {
              currentBox.pokemonIds.add("");
            }
            currentBox.pokemonIds.add(itemToInsert);
          } else {
            final hasDownstreamPlaceholder = currentBox.pokemonIds
                .skip(currentSlot)
                .any(DexLogicHelper.isPlaceholder);

            if (hasDownstreamPlaceholder) {
              int firstEmptyIdx = -1;
              for (int i = currentSlot; i < currentBox.pokemonIds.length; i++) {
                if (DexLogicHelper.isPlaceholder(currentBox.pokemonIds[i])) {
                  break;
                }
                if (currentBox.pokemonIds[i].isEmpty) {
                  firstEmptyIdx = i;
                  break;
                }
              }
              if (firstEmptyIdx != -1) {
                for (int i = firstEmptyIdx; i > currentSlot; i--) {
                  currentBox.pokemonIds[i] = currentBox.pokemonIds[i - 1];
                }
                currentBox.pokemonIds[currentSlot] = itemToInsert;
              } else {
                currentBox.pokemonIds.insert(currentSlot, itemToInsert);
              }
            } else {
              currentBox.pokemonIds.insert(currentSlot, itemToInsert);
            }
          }
        } else {
          while (currentBox.pokemonIds.length <= currentSlot) {
            currentBox.pokemonIds.add("");
          }
          currentBox.pokemonIds[currentSlot] = itemToInsert;
        }

        // Check if length exceeds capacity
        if (currentBox.pokemonIds.length > capacity) {
          final displaced = currentBox.pokemonIds.removeLast();
          if (displaced.isNotEmpty) {
            overflowItem = displaced;
          }
        }
      }

      // If nothing overflowed, cascade is finished
      if (overflowItem == null || overflowItem.isEmpty) {
        break;
      }

      // Cascade to next linked box in sequence
      seqIdx++;
      if (seqIdx < linkedBoxes.length) {
        currentBox = linkedBoxes[seqIdx];
        currentSlot = 0; // Overflowed item enters next box at index 0
        itemToInsert = overflowItem;
      } else {
        // Reached past the last linked box in sequence
        final pattern = parsePattern(currentBox.title);
        final canAutoCreate = currentBox.patternAutoCreate &&
            pattern.type != BoxPatternType.standalone;

        if (canAutoCreate) {
          final nextTitle = generateNextBoxTitle(linkedBoxes);
          final newBox = currentBox.copyWith(
            title: nextTitle,
            pokemonIds: [overflowItem],
          );

          final lastBoxInSequence = linkedBoxes.last;
          final insertIdx = dex.customBoxes.indexOf(lastBoxInSequence);
          if (insertIdx != -1) {
            dex.customBoxes.insert(insertIdx + 1, newBox);
          } else {
            dex.customBoxes.add(newBox);
          }
          linkedBoxes.add(newBox);
        } else {
          // Auto-creation disabled or standalone: retain item in last box to prevent loss
          currentBox.pokemonIds.add(overflowItem);
        }
        break;
      }
    }
  }

  /// Handles drag-and-drop movement of a Pokémon between boxes or within a box.
  static void movePokemon({
    required UserDex dex,
    required String sourceId,
    required int targetBoxIndex,
    required int targetSlotIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  }) {
    if (dex.customBoxes.isEmpty) return;
    if (targetBoxIndex < 0 || targetBoxIndex >= dex.customBoxes.length) return;

    int? sBox = sourceBoxIndex;
    int? sIndex = sourceSlotIndex;
    if (sBox == null ||
        sIndex == null ||
        sBox < 0 ||
        sBox >= dex.customBoxes.length ||
        sIndex < 0 ||
        sIndex >= dex.customBoxes[sBox].pokemonIds.length ||
        (dex.customBoxes[sBox].pokemonIds[sIndex] != sourceId &&
            DexLogicHelper.getBaseId(dex.customBoxes[sBox].pokemonIds[sIndex]) !=
                DexLogicHelper.getBaseId(sourceId))) {
      sBox = null;
      sIndex = null;
      for (int i = 0; i < dex.customBoxes.length; i++) {
        final box = dex.customBoxes[i];
        final idx = box.pokemonIds.indexOf(sourceId);
        if (idx != -1) {
          sBox = i;
          sIndex = idx;
          break;
        }
      }
      if (sBox == null || sIndex == null) {
        final baseId = DexLogicHelper.getBaseId(sourceId);
        for (int i = 0; i < dex.customBoxes.length; i++) {
          final box = dex.customBoxes[i];
          for (int j = 0; j < box.pokemonIds.length; j++) {
            if (box.pokemonIds[j].isNotEmpty &&
                DexLogicHelper.getBaseId(box.pokemonIds[j]) == baseId) {
              sBox = i;
              sIndex = j;
              sourceId = box.pokemonIds[j];
              break;
            }
          }
          if (sBox != null) break;
        }
      }
    } else {
      sourceId = dex.customBoxes[sBox].pokemonIds[sIndex];
    }
    if (sBox == null || sIndex == null) return;

    final sourceBox = dex.customBoxes[sBox];
    final targetBox = dex.customBoxes[targetBoxIndex];

    // Intra-box move
    if (sBox == targetBoxIndex) {
      if (sIndex == targetSlotIndex) return; // Dropping on same index is a strict no-op
      if (targetBox.autoShift) {
        // If target slot is an empty slot or placeholder, place into it without shifting other filled slots
        if (targetSlotIndex < sourceBox.pokemonIds.length &&
            (sourceBox.pokemonIds[targetSlotIndex].isEmpty ||
                DexLogicHelper.isPlaceholder(sourceBox.pokemonIds[targetSlotIndex]))) {
          sourceBox.pokemonIds[targetSlotIndex] = sourceId;
          sourceBox.pokemonIds[sIndex] = '';
        } else {
          sourceBox.pokemonIds.removeAt(sIndex);
          if (targetSlotIndex >= sourceBox.pokemonIds.length) {
            while (sourceBox.pokemonIds.length < targetSlotIndex) {
              sourceBox.pokemonIds.add("");
            }
            sourceBox.pokemonIds.add(sourceId);
          } else {
            sourceBox.pokemonIds.insert(targetSlotIndex, sourceId);
          }
        }
      } else {
        // Swap or place
        while (targetBox.pokemonIds.length <= targetSlotIndex) {
          targetBox.pokemonIds.add("");
        }
        final temp = targetBox.pokemonIds[targetSlotIndex];
        targetBox.pokemonIds[targetSlotIndex] = sourceId;
        sourceBox.pokemonIds[sIndex] = temp;
      }
      return;
    }

    // Cross-box move: remove from source box with placeholder protection (without cascading pull from other boxes), insert with overflow into target box
    if (sourceBox.autoShift) {
      final isSourcePlaceholder = DexLogicHelper.isPlaceholder(sourceId);
      if (isSourcePlaceholder) {
        sourceBox.pokemonIds.removeAt(sIndex);
      } else {
        int nextPlaceholderIdx = -1;
        for (int i = sIndex + 1; i < sourceBox.pokemonIds.length; i++) {
          if (DexLogicHelper.isPlaceholder(sourceBox.pokemonIds[i])) {
            nextPlaceholderIdx = i;
            break;
          }
        }
        if (nextPlaceholderIdx != -1) {
          for (int i = sIndex; i < nextPlaceholderIdx - 1; i++) {
            sourceBox.pokemonIds[i] = sourceBox.pokemonIds[i + 1];
          }
          sourceBox.pokemonIds[nextPlaceholderIdx - 1] = '';
        } else {
          sourceBox.pokemonIds.removeAt(sIndex);
        }
      }
    } else {
      sourceBox.pokemonIds[sIndex] = '';
    }
    final actualTargetBoxIdx = dex.customBoxes.indexOf(targetBox);
    if (actualTargetBoxIdx != -1) {
      insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: actualTargetBoxIdx,
        slotIndex: targetSlotIndex,
        pokemonId: sourceId,
      );
    }
    cleanupEmptyBoxes(dex: dex, affectedBox: sourceBox);
    cleanupEmptyBoxes(dex: dex, affectedBox: targetBox);
  }

  /// Swaps positions of two Pokémon (1:1 swap) within the same box or across boxes.
  static void swapPokemon({
    required UserDex dex,
    required String sourceId,
    required int targetBoxIndex,
    required int targetSlotIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  }) {
    if (dex.customBoxes.isEmpty) return;
    if (targetBoxIndex < 0 || targetBoxIndex >= dex.customBoxes.length) return;

    if (sourceBoxIndex != null && sourceSlotIndex != null) {
      swapPokemonByIndices(
        dex: dex,
        sourceBoxIndex: sourceBoxIndex,
        sourceSlotIndex: sourceSlotIndex,
        targetBoxIndex: targetBoxIndex,
        targetSlotIndex: targetSlotIndex,
      );
      return;
    }

    int? sBox;
    int? sIndex;
    for (int i = 0; i < dex.customBoxes.length; i++) {
      final box = dex.customBoxes[i];
      final idx = box.pokemonIds.indexOf(sourceId);
      if (idx != -1) {
        sBox = i;
        sIndex = idx;
        break;
      }
    }
    if (sBox == null || sIndex == null) {
      final baseId = DexLogicHelper.getBaseId(sourceId);
      for (int i = 0; i < dex.customBoxes.length; i++) {
        final box = dex.customBoxes[i];
        for (int j = 0; j < box.pokemonIds.length; j++) {
          if (box.pokemonIds[j].isNotEmpty &&
              DexLogicHelper.getBaseId(box.pokemonIds[j]) == baseId) {
            sBox = i;
            sIndex = j;
            break;
          }
        }
        if (sBox != null) break;
      }
    }
    if (sBox == null || sIndex == null) return;

    swapPokemonByIndices(
      dex: dex,
      sourceBoxIndex: sBox,
      sourceSlotIndex: sIndex,
      targetBoxIndex: targetBoxIndex,
      targetSlotIndex: targetSlotIndex,
    );
  }

  /// Swaps positions of two Pokémon by box and slot indices.
  static void swapPokemonByIndices({
    required UserDex dex,
    required int sourceBoxIndex,
    required int sourceSlotIndex,
    required int targetBoxIndex,
    required int targetSlotIndex,
  }) {
    if (dex.customBoxes.isEmpty) return;
    if (sourceBoxIndex < 0 || sourceBoxIndex >= dex.customBoxes.length) return;
    if (targetBoxIndex < 0 || targetBoxIndex >= dex.customBoxes.length) return;

    final sourceBox = dex.customBoxes[sourceBoxIndex];
    final targetBox = dex.customBoxes[targetBoxIndex];

    if (sourceSlotIndex < 0 || sourceSlotIndex >= sourceBox.pokemonIds.length) return;
    if (targetSlotIndex < 0) return;

    if (sourceBoxIndex == targetBoxIndex && sourceSlotIndex == targetSlotIndex) {
      return; // Strict no-op
    }

    while (targetBox.pokemonIds.length <= targetSlotIndex) {
      targetBox.pokemonIds.add("");
    }

    final temp = sourceBox.pokemonIds[sourceSlotIndex];
    sourceBox.pokemonIds[sourceSlotIndex] = targetBox.pokemonIds[targetSlotIndex];
    targetBox.pokemonIds[targetSlotIndex] = temp;
  }

  /// Moves multiple Pokémon as a block to [targetBoxIndex] at [targetSlotIndex] (or appends if null),
  /// with automatic cascading overflow across linked boxes.
  static void moveMultiplePokemon({
    required UserDex dex,
    required List<String> sourceIds,
    required int targetBoxIndex,
    int? targetSlotIndex,
  }) {
    if (dex.customBoxes.isEmpty) return;
    if (targetBoxIndex < 0 || targetBoxIndex >= dex.customBoxes.length) return;

    // Filter to distinct, non-empty IDs that exist in the dex
    final validSourceIds = <String>[];
    for (final id in sourceIds) {
      if (id.isEmpty) continue;
      String? matchedId;
      for (final box in dex.customBoxes) {
        if (box.pokemonIds.contains(id)) {
          matchedId = id;
          break;
        }
      }
      if (matchedId == null) {
        final baseId = DexLogicHelper.getBaseId(id);
        for (final box in dex.customBoxes) {
          for (final pid in box.pokemonIds) {
            if (pid.isNotEmpty &&
                DexLogicHelper.getBaseId(pid) == baseId &&
                !validSourceIds.contains(pid)) {
              matchedId = pid;
              break;
            }
          }
          if (matchedId != null) break;
        }
      }
      if (matchedId != null && !validSourceIds.contains(matchedId)) {
        validSourceIds.add(matchedId);
      }
    }
    if (validSourceIds.isEmpty) return;

    final targetBox = dex.customBoxes[targetBoxIndex];

    // If a target slot was specified, try to find an anchor item that is NOT being moved
    String? anchorId;
    int removedBeforeInTarget = 0;
    if (targetSlotIndex != null) {
      if (targetSlotIndex < targetBox.pokemonIds.length) {
        final currentAtSlot = targetBox.pokemonIds[targetSlotIndex];
        if (currentAtSlot.isNotEmpty && !validSourceIds.contains(currentAtSlot)) {
          anchorId = currentAtSlot;
        }
      }
      if (anchorId == null) {
        for (int i = 0; i < targetSlotIndex && i < targetBox.pokemonIds.length; i++) {
          if (validSourceIds.contains(targetBox.pokemonIds[i])) {
            removedBeforeInTarget++;
          }
        }
      }
    }

    // Remove source items from all boxes
    for (final box in dex.customBoxes) {
      if (box.autoShift) {
        box.pokemonIds.removeWhere((id) => validSourceIds.contains(id));
      } else {
        for (int i = 0; i < box.pokemonIds.length; i++) {
          if (validSourceIds.contains(box.pokemonIds[i])) {
            box.pokemonIds[i] = "";
          }
        }
      }
    }

    // Determine insertion starting slot in targetBox
    int startSlot;
    if (targetSlotIndex == null) {
      final emptyIdx = targetBox.pokemonIds.indexOf("");
      startSlot = emptyIdx != -1 ? emptyIdx : targetBox.pokemonIds.length;
    } else if (anchorId != null) {
      final idx = targetBox.pokemonIds.indexOf(anchorId);
      startSlot = idx != -1 ? idx : targetBox.pokemonIds.length;
    } else {
      startSlot = (targetSlotIndex - removedBeforeInTarget).clamp(0, targetBox.pokemonIds.length);
    }

    // Insert items as a block sequentially with overflow handling
    int currentSlot = startSlot;
    for (final id in validSourceIds) {
      insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: targetBoxIndex,
        slotIndex: currentSlot,
        pokemonId: id,
      );
      currentSlot++;
    }

    // Clean up any empty overflow boxes
    for (final b in dex.customBoxes.toList()) {
      cleanupEmptyBoxes(dex: dex, affectedBox: b);
    }
  }

  /// Removes a Pokémon from [boxIndex] at [slotIndex] with backward shift
  /// across logically linked boxes and automatic cleanup of empty overflow boxes.
  static void removeWithShiftBack({
    required UserDex dex,
    required int boxIndex,
    required int slotIndex,
  }) {
    if (dex.customBoxes.isEmpty) return;
    if (boxIndex < 0 || boxIndex >= dex.customBoxes.length) return;
    if (slotIndex < 0) return;

    final targetBox = dex.customBoxes[boxIndex];
    if (slotIndex >= targetBox.pokemonIds.length) return;

    // Check autoShift setting: if disabled, clear slot without shifting
    if (!targetBox.autoShift) {
      targetBox.pokemonIds[slotIndex] = '';
      cleanupEmptyBoxes(dex: dex, affectedBox: targetBox);
      return;
    }

    // Identify linked sequence of boxes in pattern order
    final linkedSequence = getLinkedSequence(dex.customBoxes, targetBox);
    final targetSeqIndex = linkedSequence.indexOf(targetBox);
    if (targetSeqIndex == -1) {
      targetBox.pokemonIds.removeAt(slotIndex);
      cleanupEmptyBoxes(dex: dex, affectedBox: targetBox);
      return;
    }

    // 1. Remove from targetBox at slotIndex with placeholder protection
    final bool removingPlaceholder =
        DexLogicHelper.isPlaceholder(targetBox.pokemonIds[slotIndex]);

    bool tailShifted = false;
    if (removingPlaceholder) {
      targetBox.pokemonIds.removeAt(slotIndex);
      tailShifted = true;
    } else {
      // Find the first placeholder after slotIndex
      int nextPlaceholderIdx = -1;
      for (int i = slotIndex + 1; i < targetBox.pokemonIds.length; i++) {
        if (DexLogicHelper.isPlaceholder(targetBox.pokemonIds[i])) {
          nextPlaceholderIdx = i;
          break;
        }
      }

      if (nextPlaceholderIdx != -1) {
        // Shift only items between slotIndex and nextPlaceholderIdx left
        for (int i = slotIndex; i < nextPlaceholderIdx - 1; i++) {
          targetBox.pokemonIds[i] = targetBox.pokemonIds[i + 1];
        }
        targetBox.pokemonIds[nextPlaceholderIdx - 1] = '';
        tailShifted = false;
      } else {
        // No placeholder after slotIndex: normal shift left for all subsequent items
        targetBox.pokemonIds.removeAt(slotIndex);
        tailShifted = true;
      }
    }

    // 2. Cascade item pulls from subsequent linked boxes if the tail shifted
    if (tailShifted) {
      for (int j = targetSeqIndex; j < linkedSequence.length - 1; j++) {
        final currentBox = linkedSequence[j];
        final nextBox = linkedSequence[j + 1];

        // Find first non-empty item in nextBox
        final nextItemIdx =
            nextBox.pokemonIds.indexWhere((id) => id.isNotEmpty);
        if (nextItemIdx != -1) {
          // Never pull a placeholder into the previous box
          if (DexLogicHelper.isPlaceholder(nextBox.pokemonIds[nextItemIdx])) {
            break;
          }
          // Do not pull across a placeholder in nextBox
          final hasPlaceholderAfter = nextBox.pokemonIds
              .skip(nextItemIdx + 1)
              .any(DexLogicHelper.isPlaceholder);
          if (hasPlaceholderAfter) {
            break;
          }

          final pulledItem = nextBox.pokemonIds.removeAt(nextItemIdx);
          currentBox.pokemonIds.add(pulledItem);
        } else {
          // No items in nextBox to pull, cascade ends
          break;
        }
      }
    }

    // 3. Clean up any subsequent boxes that became empty
    cleanupEmptyBoxes(dex: dex, affectedBox: targetBox);
  }

  /// Batch removes multiple Pokémon identified by [selectedKeys] ('boxIndex_slotIndex')
  /// with backward shift and empty box cleanup.
  static void batchRemoveWithShiftBack({
    required UserDex dex,
    required List<String> selectedKeys,
  }) {
    if (selectedKeys.isEmpty || dex.customBoxes.isEmpty) return;

    // Parse and deduplicate
    final targets = <_BatchTarget>[];
    for (final key in selectedKeys.toSet()) {
      final parts = key.split('_');
      if (parts.length == 2) {
        final bIdx = int.tryParse(parts[0]);
        final sIdx = int.tryParse(parts[1]);
        if (bIdx != null && sIdx != null) {
          if (bIdx >= 0 && bIdx < dex.customBoxes.length) {
            final box = dex.customBoxes[bIdx];
            if (sIdx >= 0 &&
                sIdx < box.pokemonIds.length &&
                box.pokemonIds[sIdx].isNotEmpty) {
              targets.add(_BatchTarget(bIdx, sIdx, box, box.pokemonIds[sIdx]));
            }
          }
        }
      }
    }

    if (targets.isEmpty) return;

    // Sort descending by boxIndex, then descending by slotIndex
    // This ensures higher indices are processed first and avoid index drift
    targets.sort((a, b) {
      if (a.boxIndex != b.boxIndex) {
        return b.boxIndex.compareTo(a.boxIndex);
      }
      return b.slotIndex.compareTo(a.slotIndex);
    });

    for (final target in targets) {
      final currentBoxIndex = dex.customBoxes.indexOf(target.box);
      if (currentBoxIndex != -1) {
        int currentSlotIndex = -1;
        if (target.slotIndex < target.box.pokemonIds.length &&
            target.box.pokemonIds[target.slotIndex] == target.pokemonId) {
          currentSlotIndex = target.slotIndex;
        } else {
          currentSlotIndex = target.box.pokemonIds.indexOf(target.pokemonId);
        }
        if (currentSlotIndex == -1 && target.slotIndex < target.box.pokemonIds.length) {
          currentSlotIndex = target.slotIndex;
        }
        if (currentSlotIndex != -1) {
          removeWithShiftBack(
            dex: dex,
            boxIndex: currentBoxIndex,
            slotIndex: currentSlotIndex,
          );
        }
      }
    }
  }

  /// Automatically deletes linked overflow boxes that became empty as a result of shifting,
  /// respecting [autoDeleteEmpty] and protecting the root/first box of the sequence.
  static void cleanupEmptyBoxes({
    required UserDex dex,
    required CustomBoxState affectedBox,
  }) {
    if (dex.customBoxes.length <= 1) return;

    final linkedSequence = getLinkedSequence(dex.customBoxes, affectedBox);
    if (linkedSequence.length <= 1) return;

    // The first box in the sequence is the root box (e.g. "Test 1") and must NEVER be deleted.
    final boxesToDelete = <CustomBoxState>[];
    for (int i = 1; i < linkedSequence.length; i++) {
      final box = linkedSequence[i];
      if (!box.autoDeleteEmpty) continue;

      final bool hasItems = box.pokemonIds.any((id) => id.isNotEmpty);
      if (!hasItems) {
        // Safety guard: ensure dex never has 0 boxes
        if (dex.customBoxes.length - boxesToDelete.length > 1) {
          boxesToDelete.add(box);
        }
      }
    }

    for (final box in boxesToDelete) {
      dex.customBoxes.remove(box);
    }
  }
}
