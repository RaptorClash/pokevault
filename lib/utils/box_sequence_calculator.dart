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

/// Internal batch target description for multi-item drag & drop operations.
class BatchTarget {
  final int boxIndex;
  final int slotIndex;
  final CustomBoxState box;
  final String pokemonId;

  BatchTarget(this.boxIndex, this.slotIndex, this.box, this.pokemonId);
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

/// Pure mathematical and parsing routines for box titles, patterns, and sequences.
class BoxSequenceCalculator {
  static final _pureRangeRegex = RegExp(r'^\s*(\d+)\s*[\-–—]\s*(\d+)\s*$');
  static final _prefixRangeParenRegex = RegExp(
    r'^(.*?)(?:\s+(\d+))?\s*\(\s*(\d+)\s*[\-–—]\s*(\d+)\s*\)\s*$',
  );
  static final _prefixRangeNoParenRegex = RegExp(
    r'^(.*?)\s+(\d+)\s*[\-–—]\s*(\d+)\s*$',
  );
  static final _numberedRegex = RegExp(r'^(.*?)\s+(\d+)\s*$');

  /// Parses a box title and classifies it into a [BoxPatternType] with extracted metadata.
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
            !listsEqual(box.pokemonIds, newIds)) {
          box.pokemonIds = newIds;
          changed = true;
        }
      }
    }
    return changed;
  }

  /// Compares two lists of strings for equality.
  static bool listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
