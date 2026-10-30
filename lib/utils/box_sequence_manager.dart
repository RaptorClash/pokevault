import '../models/user_dex.dart';
import 'dex_logic_helper.dart';

/// Pattern classification for box titles to detect sequential ordering.
enum BoxPatternType {
  /// Simple numbered boxes (e.g. "Box 1", "Box 2").
  numbered,

  /// Pure numeric range boxes without text prefix (e.g. "1-30", "31-60").
  pureRange,

  /// Range boxes with an alphanumeric prefix (e.g. "Kanto 1-30", "Gen 1 (1-30)").
  prefixRange,

  /// Standalone boxes that do not belong to any auto-shifting sequence (e.g. "Shinies", "Trade").
  standalone,
}

/// Extracted metadata from a parsed box title pattern.
class BoxPatternInfo {
  /// The detected pattern classification type.
  final BoxPatternType type;

  /// Normalized prefix or grouping key used to identify sequence siblings.
  final String groupKey;

  /// Numeric sequence index (e.g. 1 for "Box 1").
  final int? index;

  /// Starting range number (e.g. 1 for "1-30").
  final int? rangeStart;

  /// Ending range number (e.g. 30 for "1-30").
  final int? rangeEnd;

  /// Step size between consecutive range intervals (e.g. 30 for "1-30").
  final int? step;

  /// Raw textual prefix before numbers or parenthesized range.
  final String prefix;

  /// Zero-padding width if numbers are padded (e.g. 3 for "Box 001").
  final int padWidth;

  /// Whether the range bounds were enclosed in parentheses.
  final bool hasParens;

  /// Creates a [BoxPatternInfo] instance with extracted pattern fields.
  const BoxPatternInfo({
    required this.type,
    required this.groupKey,
    this.index,
    this.rangeStart,
    this.rangeEnd,
    this.step,
    required this.prefix,
    this.padWidth = 0,
    this.hasParens = false,
  });

  @override
  String toString() =>
      'BoxPatternInfo(type: $type, groupKey: "$groupKey", index: $index, '
      'range: $rangeStart-$rangeEnd, step: $step, prefix: "$prefix", pad: $padWidth)';
}

class _BatchTarget {
  final int boxIndex;
  final int slotIndex;
  final CustomBoxState box;
  final String pokemonId;

  _BatchTarget(this.boxIndex, this.slotIndex, this.box, this.pokemonId);
}

/// Encapsulates drag-and-drop payload data for a Pokémon box slot.
class BoxSlotDragData {
  /// Index of the source box in the dex box list.
  final int boxIndex;

  /// Index of the source slot inside the box.
  final int slotIndex;

  /// Unique identifier of the dragged Pokémon.
  final String uniqueId;

  /// Creates a [BoxSlotDragData] payload.
  const BoxSlotDragData({
    required this.boxIndex,
    required this.slotIndex,
    required this.uniqueId,
  });

  /// String prefix identifying a serialized slot drag payload.
  static const String prefix = 'SLOT:';

  /// Serializes box, slot, and Pokémon ID into a transferable string format.
  static String serialize(int boxIndex, int slotIndex, String uniqueId) =>
      '$prefix$boxIndex:$slotIndex:$uniqueId';

  /// Attempts to parse a serialized drag string back into a [BoxSlotDragData] instance.
  static BoxSlotDragData? tryParse(String? data) {
    if (data == null || !data.startsWith(prefix)) return null;
    final parts = data.substring(prefix.length).split(':');
    if (parts.length < 3) return null;
    final b = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (b == null || s == null) return null;
    final uId = parts.sublist(2).join(':');
    return BoxSlotDragData(boxIndex: b, slotIndex: s, uniqueId: uId);
  }
}

/// Manages intelligent box sequencing, cascading item overflow, auto-shifting, and range title generation.
class BoxSequenceManager {
  /// Packs entries sequentially in all special boxes (trades, gifts, forms, etc.)
  /// removing any middle gaps and consolidating trailing empty slots.
  /// Returns `true` if any custom box was reordered or modified.
  static bool packSpecialBoxes(UserDex dex) {
    bool changed = false;
    for (var box in dex.customBoxes) {
      final isSpecial = DexLogicHelper.isSpecialBoxTitle(box.title) ||
          box.pokemonIds.any((id) => id.contains('_special_'));
      if (isSpecial) {
        final nonBlankIds =
            box.pokemonIds.where((id) => id.isNotEmpty).toList();
        final capacity = box.capacity;
        final padCount = capacity - nonBlankIds.length;
        final newIds = [
          ...nonBlankIds,
          ...List.generate(padCount > 0 ? padCount : 0, (_) => ''),
        ];
        if (box.pokemonIds.length != newIds.length ||
            !_listsEqual(box.pokemonIds, newIds)) {
          box.pokemonIds = newIds;
          changed = true;
        }
      }
    }
    return changed;
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static final _pureRangeRegex = RegExp(r'^\s*(\d+)\s*[\-–—]\s*(\d+)\s*$');
  static final _prefixRangeParenRegex = RegExp(
    r'^(.*?)(?:\s+(\d+))?\s*\(\s*(\d+)\s*[\-–—]\s*(\d+)\s*\)\s*$',
  );
  static final _prefixRangeNoParenRegex = RegExp(
    r'^(.*?)\s+(\d+)\s*[\-–—]\s*(\d+)\s*$',
  );
  static final _numberedRegex = RegExp(r'^(.*?)\s+(\d+)\s*$');

  /// Parses a box title and classifies it into a BoxPatternType with extracted metadata.
  static BoxPatternInfo parsePattern(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return const BoxPatternInfo(
        type: BoxPatternType.standalone,
        groupKey: '',
        prefix: '',
      );
    }

    // 1. Pure Range (e.g. "1-30", "31-60")
    final pureMatch = _pureRangeRegex.firstMatch(trimmed);
    if (pureMatch != null) {
      final startStr = pureMatch.group(1)!;
      final endStr = pureMatch.group(2)!;
      final start = int.parse(startStr);
      final end = int.parse(endStr);
      if (start <= end) {
        final step = end - start + 1;
        return BoxPatternInfo(
          type: BoxPatternType.pureRange,
          groupKey: 'pure_range_$step',
          rangeStart: start,
          rangeEnd: end,
          step: step,
          prefix: '',
          padWidth: startStr.length > 1 && startStr.startsWith('0') ? startStr.length : 0,
        );
      }
    }

    // 2. Prefix Range with parentheses (e.g. "Box 1 (1-30)", "Kanto (1-30)")
    final prefParenMatch = _prefixRangeParenRegex.firstMatch(trimmed);
    if (prefParenMatch != null) {
      final rawPrefix = prefParenMatch.group(1)?.trim() ?? '';
      final rawIndex = prefParenMatch.group(2);
      final startStr = prefParenMatch.group(3)!;
      final endStr = prefParenMatch.group(4)!;
      final start = int.parse(startStr);
      final end = int.parse(endStr);
      if (start <= end) {
        final step = end - start + 1;
        final index = rawIndex != null ? int.tryParse(rawIndex) : null;
        final prefix = rawPrefix.isEmpty ? 'Box' : rawPrefix;
        return BoxPatternInfo(
          type: BoxPatternType.prefixRange,
          groupKey: prefix.toLowerCase(),
          prefix: prefix,
          index: index,
          rangeStart: start,
          rangeEnd: end,
          step: step,
          padWidth: startStr.length > 1 && startStr.startsWith('0') ? startStr.length : 0,
          hasParens: true,
        );
      }
    }

    // 3. Prefix Range without parentheses (e.g. "Kanto 1-30")
    final prefNoParenMatch = _prefixRangeNoParenRegex.firstMatch(trimmed);
    if (prefNoParenMatch != null) {
      final rawPrefix = prefNoParenMatch.group(1)?.trim() ?? '';
      final startStr = prefNoParenMatch.group(2)!;
      final endStr = prefNoParenMatch.group(3)!;
      final start = int.parse(startStr);
      final end = int.parse(endStr);
      if (rawPrefix.isNotEmpty && !RegExp(r'^\d+$').hasMatch(rawPrefix) && start <= end) {
        final step = end - start + 1;
        return BoxPatternInfo(
          type: BoxPatternType.prefixRange,
          groupKey: rawPrefix.toLowerCase(),
          prefix: rawPrefix,
          rangeStart: start,
          rangeEnd: end,
          step: step,
          padWidth: startStr.length > 1 && startStr.startsWith('0') ? startStr.length : 0,
          hasParens: false,
        );
      }
    }

    // 4. Numbered suffix (e.g. "Kanto 1", "Test 2", "Box 1")
    final numMatch = _numberedRegex.firstMatch(trimmed);
    if (numMatch != null) {
      final rawPrefix = numMatch.group(1)?.trim() ?? '';
      final rawIndex = numMatch.group(2)!;
      final index = int.parse(rawIndex);
      if (rawPrefix.isNotEmpty) {
        return BoxPatternInfo(
          type: BoxPatternType.numbered,
          groupKey: rawPrefix.toLowerCase(),
          prefix: rawPrefix,
          index: index,
          padWidth: rawIndex.startsWith('0') && rawIndex.length > 1 ? rawIndex.length : 0,
        );
      }
    }

    // 5. Standalone / Unrelated fallback
    return BoxPatternInfo(
      type: BoxPatternType.standalone,
      groupKey: trimmed.toLowerCase(),
      prefix: trimmed,
    );
  }

  /// Determines whether two boxes belong to the same logical sequence.
  static bool areLinked(CustomBoxState a, CustomBoxState b) {
    final infoA = parsePattern(a.title);
    final infoB = parsePattern(b.title);

    // Standalone boxes are strictly isolated and never link
    if (infoA.type == BoxPatternType.standalone || infoB.type == BoxPatternType.standalone) {
      return false;
    }

    // Pattern types must match exactly
    if (infoA.type != infoB.type) {
      return false;
    }

    switch (infoA.type) {
      case BoxPatternType.numbered:
        return infoA.groupKey == infoB.groupKey;
      case BoxPatternType.pureRange:
        return infoA.step == infoB.step;
      case BoxPatternType.prefixRange:
        return infoA.groupKey == infoB.groupKey &&
            infoA.step == infoB.step &&
            infoA.hasParens == infoB.hasParens;
      case BoxPatternType.standalone:
        return false;
    }
  }

  /// Returns all boxes linked with [targetBox], sorted in logical sequence order.
  static List<CustomBoxState> getLinkedSequence(
    List<CustomBoxState> allBoxes,
    CustomBoxState targetBox,
  ) {
    final targetInfo = parsePattern(targetBox.title);
    if (targetInfo.type == BoxPatternType.standalone) {
      return [targetBox];
    }

    final linked = allBoxes.where((b) {
      if (identical(b, targetBox) || b == targetBox) return true;
      return areLinked(targetBox, b);
    }).toList();

    if (!linked.any((b) => identical(b, targetBox) || b == targetBox)) {
      linked.add(targetBox);
    }

    linked.sort((b1, b2) {
      final info1 = parsePattern(b1.title);
      final info2 = parsePattern(b2.title);

      if (info1.type == BoxPatternType.numbered) {
        final idx1 = info1.index ?? 0;
        final idx2 = info2.index ?? 0;
        final cmp = idx1.compareTo(idx2);
        if (cmp != 0) return cmp;
      } else if (info1.type == BoxPatternType.pureRange) {
        final start1 = info1.rangeStart ?? 0;
        final start2 = info2.rangeStart ?? 0;
        final cmp = start1.compareTo(start2);
        if (cmp != 0) return cmp;
      } else if (info1.type == BoxPatternType.prefixRange) {
        if (info1.index != null && info2.index != null) {
          final cmp = info1.index!.compareTo(info2.index!);
          if (cmp != 0) return cmp;
        }
        final start1 = info1.rangeStart ?? 0;
        final start2 = info2.rangeStart ?? 0;
        final cmp = start1.compareTo(start2);
        if (cmp != 0) return cmp;
      }

      final pos1 = allBoxes.indexOf(b1);
      final pos2 = allBoxes.indexOf(b2);
      return pos1.compareTo(pos2);
    });

    return linked;
  }

  /// Generates the next box title in the sequence represented by [linkedBoxes].
  static String generateNextBoxTitle(List<CustomBoxState> linkedBoxes) {
    if (linkedBoxes.isEmpty) {
      return 'Box 1';
    }

    final lastBox = linkedBoxes.last;
    final lastInfo = parsePattern(lastBox.title);

    switch (lastInfo.type) {
      case BoxPatternType.numbered:
        int maxIndex = 0;
        int padWidth = 0;
        String prefix = lastInfo.prefix;
        for (var box in linkedBoxes) {
          final info = parsePattern(box.title);
          if (info.index != null && info.index! > maxIndex) {
            maxIndex = info.index!;
            padWidth = info.padWidth;
            prefix = info.prefix;
          }
        }
        final nextIndex = maxIndex + 1;
        final formattedIndex = padWidth > 0
            ? nextIndex.toString().padLeft(padWidth, '0')
            : nextIndex.toString();
        return '$prefix $formattedIndex';

      case BoxPatternType.pureRange:
        int maxEnd = 0;
        int step = lastInfo.step ?? (lastBox.columns * lastBox.rows);
        int padWidth = lastInfo.padWidth;
        for (var box in linkedBoxes) {
          final info = parsePattern(box.title);
          if (info.rangeEnd != null && info.rangeEnd! > maxEnd) {
            maxEnd = info.rangeEnd!;
            if (info.step != null) step = info.step!;
            padWidth = info.padWidth;
          }
        }
        final nextStart = maxEnd + 1;
        final nextEnd = nextStart + step - 1;
        final formattedStart = padWidth > 0
            ? nextStart.toString().padLeft(padWidth, '0')
            : nextStart.toString();
        final formattedEnd = padWidth > 0
            ? nextEnd.toString().padLeft(padWidth, '0')
            : nextEnd.toString();
        return '$formattedStart-$formattedEnd';

      case BoxPatternType.prefixRange:
        int maxEnd = 0;
        int maxIndex = 0;
        bool hasIndex = false;
        int step = lastInfo.step ?? (lastBox.columns * lastBox.rows);
        int padWidth = lastInfo.padWidth;
        String prefix = lastInfo.prefix;
        bool hasParens = lastInfo.hasParens;

        for (var box in linkedBoxes) {
          final info = parsePattern(box.title);
          if (info.rangeEnd != null && info.rangeEnd! > maxEnd) {
            maxEnd = info.rangeEnd!;
            if (info.step != null) step = info.step!;
            padWidth = info.padWidth;
            prefix = info.prefix;
            hasParens = info.hasParens;
          }
          if (info.index != null) {
            hasIndex = true;
            if (info.index! > maxIndex) {
              maxIndex = info.index!;
            }
          }
        }

        final nextStart = maxEnd + 1;
        final nextEnd = nextStart + step - 1;
        final formattedStart = padWidth > 0
            ? nextStart.toString().padLeft(padWidth, '0')
            : nextStart.toString();
        final formattedEnd = padWidth > 0
            ? nextEnd.toString().padLeft(padWidth, '0')
            : nextEnd.toString();

        final rangePart = hasParens
            ? '($formattedStart-$formattedEnd)'
            : '$formattedStart-$formattedEnd';

        if (hasIndex) {
          final nextIndex = maxIndex + 1;
          return '$prefix $nextIndex $rangePart';
        } else {
          return '$prefix $rangePart';
        }

      case BoxPatternType.standalone:
        return '${lastBox.title} 2';
    }
  }

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
