import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_dex.dart';
import '../../models/dex_view_models.dart';
import '../../utils/dex_logic_helper.dart';
import '../../providers/dex_provider.dart';
import '../../l10n/app_translations.dart';
import '../pokemon_info/pokemon_info_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_vectors.dart';
import '../../utils/box_sequence_manager.dart';

class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  const DashedRRectPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dash = 4.5,
    this.gap = 3.5,
    this.radius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dash > metric.length)
            ? metric.length - distance
            : dash;
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dash != oldDelegate.dash ||
      gap != oldDelegate.gap ||
      radius != oldDelegate.radius;
}

class DexBoxView extends StatefulWidget {
  final List<BoxData> boxes;
  final UserDex liveDex;
  final DexProvider provider;
  final PageController pageController;
  final bool separateForms;
  final Set<String> highlightedIds;
  final bool isSearchActive;
  final GlobalKey? firstItemKey;
  final String? tutorialTargetId;
  final bool isEditMode;
  final Set<String> selectedForEdit;
  final void Function(int boxIndex, int itemIndex)? onSelectionChanged;
  final void Function(int boxIndex, int insertIndex)? onInsertPokemon;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  )?
  onMovePokemon;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  )?
  onSwapPokemon;
  final void Function(
    List<String> sourceUniqueIds,
    int targetBoxIndex,
    int targetIndex,
  )?
  onMoveMultiplePokemon;

  const DexBoxView({
    super.key,
    required this.boxes,
    required this.liveDex,
    required this.provider,
    required this.pageController,
    required this.separateForms,
    required this.highlightedIds,
    required this.isSearchActive,
    this.firstItemKey,
    this.tutorialTargetId,
    this.isEditMode = false,
    this.selectedForEdit = const {},
    this.onSelectionChanged,
    this.onInsertPokemon,
    this.onMovePokemon,
    this.onSwapPokemon,
    this.onMoveMultiplePokemon,
  });

  @override
  State<DexBoxView> createState() => _DexBoxViewState();
}

class _DexBoxViewState extends State<DexBoxView> {
  bool _isDragging = false;
  List<String> _draggedMultiIds = [];
  Timer? _edgeScrollTimer;
  DateTime? _lastEdgeFlipTime;
  int? _hoveredSlotIndex;
  int? _hoveredBoxIndex;
  bool _hoveredIsEdge = false;

  static const String multiDragPrefix = 'MULTI_POKEMON:';

  static bool isMultiDragData(String? data) =>
      data != null && data.startsWith(multiDragPrefix);

  static List<String> parseMultiDragData(String data) {
    if (!isMultiDragData(data)) return [data];
    return data.substring(multiDragPrefix.length).split('|||');
  }

  static String createMultiDragData(List<String> ids) {
    return '$multiDragPrefix${ids.join('|||')}';
  }

  List<String> getSelectedPokemonIds() {
    final sortedKeys = selectedForEdit.toList()
      ..sort((a, b) {
        final pA = a.split('_').map(int.parse).toList();
        final pB = b.split('_').map(int.parse).toList();
        if (pA[0] != pB[0]) return pA[0].compareTo(pB[0]);
        return pA[1].compareTo(pB[1]);
      });

    final ids = <String>[];
    for (final key in sortedKeys) {
      final parts = key.split('_').map(int.parse).toList();
      if (parts.length != 2) continue;
      final bIdx = parts[0];
      final sIdx = parts[1];
      String? id;
      if (bIdx < liveDex.customBoxes.length &&
          sIdx < liveDex.customBoxes[bIdx].pokemonIds.length) {
        final customId = liveDex.customBoxes[bIdx].pokemonIds[sIdx];
        if (customId.isNotEmpty) {
          id = customId;
        }
      } else if (bIdx < boxes.length && sIdx < boxes[bIdx].entries.length) {
        final entryId = boxes[bIdx].entries[sIdx].uniqueId;
        if (entryId.isNotEmpty) {
          id = entryId;
        }
      }
      if (id != null && id.isNotEmpty && !ids.contains(id)) {
        ids.add(id);
      }
    }
    return ids;
  }

  List<BoxData> get boxes => widget.boxes;
  UserDex get liveDex => widget.liveDex;
  DexProvider get provider => widget.provider;
  PageController get pageController => widget.pageController;
  bool get separateForms => widget.separateForms;
  Set<String> get highlightedIds => widget.highlightedIds;
  bool get isSearchActive => widget.isSearchActive;
  GlobalKey? get firstItemKey => widget.firstItemKey;
  String? get tutorialTargetId => widget.tutorialTargetId;
  bool get isEditMode => widget.isEditMode;
  Set<String> get selectedForEdit => widget.selectedForEdit;
  void Function(int boxIndex, int itemIndex)? get onSelectionChanged =>
      widget.onSelectionChanged;
  void Function(int boxIndex, int insertIndex)? get onInsertPokemon =>
      widget.onInsertPokemon;
  void Function(String sourceUniqueId, int targetBoxIndex, int targetIndex)?
  get onMovePokemon => widget.onMovePokemon;
  void Function(String sourceUniqueId, int targetBoxIndex, int targetIndex)?
  get onSwapPokemon => widget.onSwapPokemon;
  void Function(List<String> sourceUniqueIds, int targetBoxIndex, int targetIndex)?
  get onMoveMultiplePokemon => widget.onMoveMultiplePokemon;

  @override
  void dispose() {
    _edgeScrollTimer?.cancel();
    super.dispose();
  }

  void _triggerPageTurn({required bool isNext}) {
    final now = DateTime.now();
    if (_lastEdgeFlipTime != null &&
        now.difference(_lastEdgeFlipTime!) <
            const Duration(milliseconds: 400)) {
      return;
    }
    _lastEdgeFlipTime = now;
    if (!pageController.hasClients) return;
    final curPage = pageController.page?.round() ?? 0;
    if (isNext && curPage < boxes.length - 1) {
      HapticFeedback.selectionClick();
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (!isNext && curPage > 0) {
      HapticFeedback.selectionClick();
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startEdgeScroll({required bool isNext}) {
    _edgeScrollTimer?.cancel();
    _triggerPageTurn(isNext: isNext);
    _edgeScrollTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) {
        _triggerPageTurn(isNext: isNext);
      },
    );
  }

  void _stopEdgeScroll() {
    _edgeScrollTimer?.cancel();
    _edgeScrollTimer = null;
  }

  void _showQuickNavDialog(BuildContext context) {
    final Map<String, int> regionFirstIndices = {};
    for (int i = 0; i < boxes.length; i++) {
      if (!regionFirstIndices.containsKey(boxes[i].regionKey)) {
        regionFirstIndices[boxes[i].regionKey] = i;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(Translator.get('jump_to_region')),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: regionFirstIndices.entries.map((entry) {
                  String regionKey = entry.key;
                  int boxIndex = entry.value;
                  String regionName = Translator.get('region_name_$regionKey');
                  if (regionName == 'region_name_$regionKey') {
                    regionName =
                        regionKey[0].toUpperCase() + regionKey.substring(1);
                  }

                  return ActionChip(
                    label: Text(
                      regionName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(
                      ctx,
                    ).colorScheme.surfaceContainerHighest,
                    onPressed: () {
                      Navigator.pop(ctx);
                      pageController.jumpToPage(boxIndex);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return Center(child: Text(Translator.get('empty_box')));

    double screenWidth = MediaQuery.of(context).size.width;
    double boxMaxWidth = screenWidth > 1200
        ? 1100
        : (screenWidth > 800 ? 800 : double.infinity);

    final List<DexDisplayEntry> boxOrderedEntries = boxes
        .expand((b) => b.entries)
        .toList();

    final List<int> matchIndices = [];
    if (isSearchActive && highlightedIds.isNotEmpty) {
      for (int i = 0; i < boxes.length; i++) {
        if (boxes[i].entries.any(
          (e) =>
              highlightedIds.contains(e.uniqueId) ||
              (e.uniqueId.contains('__') &&
                  highlightedIds.contains(
                    DexLogicHelper.getBaseId(e.uniqueId),
                  )),
        )) {
          matchIndices.add(i);
        }
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: boxMaxWidth),
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: boxes.length,
              itemBuilder: (context, boxIndex) {
                final box = boxes[boxIndex];

                int prevMatch = -1;
                int nextMatch = -1;
                int currentIndexInMatches = -1;
                bool canJump = false;

                if (isSearchActive && matchIndices.isNotEmpty) {
                  currentIndexInMatches = matchIndices.indexOf(boxIndex);

                  int? tempPrev;
                  int? tempNext;
                  for (int i in matchIndices) {
                    if (i < boxIndex) tempPrev = i;
                    if (i > boxIndex && tempNext == null) tempNext = i;
                  }

                  prevMatch = tempPrev ?? matchIndices.last;
                  nextMatch = tempNext ?? matchIndices.first;

                  if (matchIndices.length > 1 || !matchIndices.contains(boxIndex)) {
                    canJump = true;
                  }
                }

                return CustomScrollView(
                  key: PageStorageKey('box_scroll_${box.title}_$boxIndex'),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSearchActive && matchIndices.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.keyboard_double_arrow_left),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: canJump
                                    ? () {
                                        pageController.animateToPage(
                                          prevMatch,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                              ),

                            _isDragging
                                ? DragTarget<String>(
                                    onWillAcceptWithDetails: (details) {
                                      if (boxIndex > 0) {
                                        _triggerPageTurn(isNext: false);
                                      }
                                      return false;
                                    },
                                    builder: (context, candidateData, rejectedData) {
                                      return IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: boxIndex > 0
                                            ? () {
                                                pageController.previousPage(
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                );
                                              }
                                            : null,
                                      );
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: boxIndex > 0
                                        ? () {
                                            pageController.previousPage(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        : null,
                                  ),

                        InkWell(
                          onTap: () {
                            if (separateForms && boxes.length > 1) {
                              _showQuickNavDialog(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  box.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (separateForms &&
                                    boxes.length > 1 &&
                                    !(isSearchActive &&
                                        matchIndices.isNotEmpty))
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                    ),
                                  ),
                                if (isSearchActive && matchIndices.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            size: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            currentIndexInMatches != -1
                                                ? '${currentIndexInMatches + 1} / ${matchIndices.length}'
                                                : '- / ${matchIndices.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Builder(
                            builder: (context) {
                              final validEntries = box.entries
                                  .where((e) => e.uniqueId.isNotEmpty && !e.isPlaceholder)
                                  .toList();
                              bool allCaught =
                                  validEntries.isNotEmpty &&
                                  validEntries.every(
                                    (e) => DexLogicHelper.isPokemonCaught(
                                      liveDex,
                                      e.uniqueId,
                                    ),
                                  );
                              return IconButton(
                                icon: Icon(
                                  allCaught
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                tooltip: Translator.get(
                                  allCaught
                                      ? 'box_uncheck_all'
                                      : 'box_check_all',
                                ),
                                onPressed: () {
                                  bool newState = !allCaught;
                                  for (var entry in validEntries) {
                                    bool isCaught =
                                        DexLogicHelper.isPokemonCaught(
                                          liveDex,
                                          entry.uniqueId,
                                        );
                                    if (isCaught != newState) {
                                      provider.togglePokemon(
                                        liveDex.id,
                                        entry.uniqueId,
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),

                        _isDragging
                            ? DragTarget<String>(
                                onWillAcceptWithDetails: (details) {
                                  if (boxIndex < boxes.length - 1) {
                                    _triggerPageTurn(isNext: true);
                                  }
                                  return false;
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: boxIndex < boxes.length - 1
                                        ? () {
                                            pageController.nextPage(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        : null,
                                  );
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: boxIndex < boxes.length - 1
                                    ? () {
                                        pageController.nextPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                              ),

                        if (isSearchActive && matchIndices.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.keyboard_double_arrow_right),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: canJump
                                ? () {
                                    pageController.animateToPage(
                                      nextMatch,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: box.crossAxisCount,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: isEditMode ? 10 : 4,
                      mainAxisSpacing: isEditMode ? 10 : 4,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      try {
                        final entry = box.entries[index];
                        if (entry.uniqueId.isEmpty) {
                          if (!isEditMode) return const SizedBox.shrink();

                          return DragTarget<String>(
                            onWillAcceptWithDetails: (details) {
                              if (details.data.isNotEmpty) {
                                HapticFeedback.selectionClick();
                                return true;
                              }
                              return false;
                            },
                            onAcceptWithDetails: (details) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _hoveredSlotIndex = null;
                                _hoveredBoxIndex = null;
                                _hoveredIsEdge = false;
                              });
                              if (isMultiDragData(details.data)) {
                                final sourceIds = parseMultiDragData(details.data);
                                if (onMoveMultiplePokemon != null) {
                                  onMoveMultiplePokemon!(sourceIds, boxIndex, index);
                                } else if (liveDex.customBoxes.isNotEmpty) {
                                  BoxSequenceManager.moveMultiplePokemon(
                                    dex: liveDex,
                                    sourceIds: sourceIds,
                                    targetBoxIndex: boxIndex,
                                    targetSlotIndex: index,
                                  );
                                }
                                return;
                              }
                              onMovePokemon?.call(
                                details.data,
                                boxIndex,
                                index,
                              );
                            },
                            builder: (context, candidateData, rejectedData) {
                              final bool isTargeted = candidateData.isNotEmpty;
                              return InkWell(
                                onTap: () {
                                  onInsertPokemon?.call(boxIndex, index);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isTargeted
                                        ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.35)
                                        : Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: isTargeted
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context).dividerColor
                                                .withValues(alpha: 0.3),
                                      width: isTargeted ? 2.0 : 1.0,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isTargeted
                                        ? [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: AnimatedScale(
                                      scale: isTargeted ? 1.25 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Icon(
                                        isTargeted
                                            ? Icons.arrow_downward
                                            : Icons.add,
                                        color: isTargeted
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.5),
                                        size: isTargeted ? 26 : 24,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        final isCaught = DexLogicHelper.isPokemonCaught(
                          liveDex,
                          entry.uniqueId,
                        );
                        final isShiny = DexLogicHelper.isPokemonShiny(
                          liveDex,
                          entry.uniqueId,
                        );
                        final isAlpha = DexLogicHelper.isPokemonAlpha(
                          liveDex,
                          entry.uniqueId,
                        );

                        final bool isMatched =
                            isSearchActive &&
                            (highlightedIds.contains(entry.uniqueId) ||
                                (entry.uniqueId.contains('__') &&
                                    highlightedIds.contains(
                                      DexLogicHelper.getBaseId(entry.uniqueId),
                                    )));
                        final bool isDimmed = isSearchActive && !isMatched;

                        void openInfoScreen() {
                          int initialIndex = boxOrderedEntries.indexOf(entry);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => PokemonInfoScreen(
                                entries: boxOrderedEntries,
                                initialIndex: initialIndex != -1
                                    ? initialIndex
                                    : 0,
                                dexId: liveDex.id,
                                boxes: boxes,
                                isBoxView: true,
                                onPageChanged: (newIndex) {
                                  final currentEntry =
                                      boxOrderedEntries[newIndex];
                                  int targetBoxIndex = boxes.indexWhere(
                                    (b) => b.entries.contains(currentEntry),
                                  );
                                  if (targetBoxIndex != -1 &&
                                      pageController.hasClients) {
                                    if (pageController.page?.round() !=
                                        targetBoxIndex) {
                                      pageController.jumpToPage(targetBoxIndex);
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        }

                        Widget card = Focus(
                          canRequestFocus: false,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.keyI ||
                                  (event.logicalKey ==
                                          LogicalKeyboardKey.enter &&
                                      HardwareKeyboard
                                          .instance
                                          .isControlPressed)) {
                                openInfoScreen();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: InkWell(
                            key:
                                (entry.uniqueId == tutorialTargetId &&
                                    boxIndex == 0 &&
                                    index == 0)
                                ? firstItemKey
                                : null,
                            onTap: isEditMode
                                ? () =>
                                      onSelectionChanged?.call(boxIndex, index)
                                : (entry.isPlaceholder
                                    ? () =>
                                          onInsertPokemon?.call(boxIndex, index)
                                    : () => provider.togglePokemon(
                                        liveDex.id,
                                        entry.uniqueId,
                                      )),
                            onSecondaryTap:
                                (isEditMode || entry.isPlaceholder)
                                    ? null
                                    : openInfoScreen,
                            onLongPress:
                                (isEditMode || entry.isPlaceholder)
                                    ? null
                                    : openInfoScreen,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isDimmed ? 0.2 : 1.0,
                              child: entry.isPlaceholder
                                  ? CustomPaint(
                                      painter: DashedRRectPainter(
                                        color: isMatched
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context)
                                                .dividerColor
                                                .withValues(alpha: 0.5),
                                        strokeWidth: isMatched ? 2.0 : 1.2,
                                        dash: 4.5,
                                        gap: 3.5,
                                        radius: 8.0,
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isMatched
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer
                                                      .withValues(alpha: 0.25)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.crop_free,
                                                    size: 22,
                                                    color: isMatched
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(alpha: 0.4),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    Translator.get(
                                                      'placeholder',
                                                      fallback: 'Platzhalter',
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: isMatched
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (isEditMode &&
                                              selectedForEdit.contains(
                                                '${boxIndex}_$index',
                                              ))
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent.withValues(
                                                  alpha: 0.3,
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                  8,
                                                ),
                                                border: Border.all(
                                                  color: Colors.red,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.remove_circle,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: isCaught
                                            ? Colors.green.withValues(alpha: 0.15)
                                            : Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isMatched
                                              ? Theme.of(context).colorScheme.primary
                                              : (isCaught
                                                    ? Colors.green
                                                    : Theme.of(context).dividerColor
                                                          .withValues(alpha: 0.3)),
                                          width: (isMatched || isCaught) ? 2 : 1,
                                        ),
                                        boxShadow: isMatched
                                            ? [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Stack(
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final imageWidget = Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: CachedNetworkImage(
                                                  imageUrl: entry.imageUrl,
                                                  memCacheWidth: 200,
                                                  fit: BoxFit.contain,
                                                  fadeInDuration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  placeholder: (context, url) =>
                                                      const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => CachedNetworkImage(
                                                        imageUrl:
                                                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${liveDex.isShinyDex ? 'shiny/' : ''}${entry.pokemon.id}.png',
                                                        memCacheWidth: 200,
                                                        fit: BoxFit.contain,
                                                        errorWidget: (c, e, s) =>
                                                            const Icon(
                                                              Icons.catching_pokemon,
                                                              size: 24,
                                                            ),
                                                      ),
                                                ),
                                              );

                                              return Center(
                                                child: isCaught
                                                    ? imageWidget
                                                    : ColorFiltered(
                                                        colorFilter:
                                                            const ColorFilter.matrix(
                                                              <double>[
                                                                0.2126,
                                                                0.7152,
                                                                0.0722,
                                                                0,
                                                                0,
                                                                0.2126,
                                                                0.7152,
                                                                0.0722,
                                                                0,
                                                                0,
                                                                0.2126,
                                                                0.7152,
                                                                0.0722,
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                1,
                                                                0,
                                                              ],
                                                            ),
                                                        child: imageWidget,
                                                      ),
                                              );
                                            },
                                          ),
                                          if (isCaught || isShiny || isAlpha)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Column(
                                          children: [
                                            if (isCaught)
                                              const Icon(
                                                Icons.catching_pokemon,
                                                color: Colors.green,
                                                size: 14,
                                              ),
                                            if (isShiny)
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 14,
                                              ),
                                            if (isAlpha)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 4.0,
                                                ),
                                                child: SvgPicture.string(
                                                  AppVectors.alphaSymbol,
                                                  width: 16,
                                                  height: 16,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    if (isEditMode &&
                                        selectedForEdit.contains(
                                          '${boxIndex}_$index',
                                        ))
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.remove_circle,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        Widget cardWithInteractions = card;

                        if (isEditMode) {
                          cardWithInteractions = Builder(
                            builder: (itemContext) {
                              final effectiveWidth = screenWidth > 1200
                                  ? 1100.0
                                  : (screenWidth > 800 ? 800.0 : screenWidth);
                              final spacing = isEditMode ? 10.0 : 4.0;
                              final cardFeedbackSize =
                                  ((effectiveWidth -
                                              16 -
                                              (box.crossAxisCount - 1) * spacing) /
                                          box.crossAxisCount)
                                       .clamp(48.0, 160.0);

                              final bool isThisSelected =
                                  selectedForEdit.contains('${boxIndex}_$index');
                              final bool isMultiDrag =
                                  isThisSelected && selectedForEdit.length > 1;
                              final List<String> multiIds = isMultiDrag
                                  ? getSelectedPokemonIds()
                                  : const <String>[];
                              final String dragData = isMultiDrag
                                  ? createMultiDragData(multiIds)
                                  : entry.uniqueId;
                              final bool isGhosted = _isDragging &&
                                  _draggedMultiIds.contains(entry.uniqueId);

                              final ghostWidget = Opacity(
                                opacity: 0.25,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: card,
                                ),
                              );

                              final displayCard = isGhosted ? ghostWidget : card;

                              return _OverflowStack(
                                overflowLeft: 32,
                                clipBehavior: Clip.none,
                                children: [
                                    LongPressDraggable<String>(
                                      data: dragData,
                                      dragAnchorStrategy: (draggable, context, position) {
                                        return Offset(cardFeedbackSize / 2, cardFeedbackSize / 2);
                                      },
                                      onDragStarted: () {
                                        setState(() {
                                          _isDragging = true;
                                          _draggedMultiIds = isMultiDrag ? multiIds : [];
                                        });
                                      },
                                      onDragEnd: (details) {
                                        _stopEdgeScroll();
                                        setState(() {
                                          _isDragging = false;
                                          _draggedMultiIds = [];
                                          _hoveredSlotIndex = null;
                                          _hoveredBoxIndex = null;
                                          _hoveredIsEdge = false;
                                        });
                                      },
                                      onDraggableCanceled: (velocity, offset) {
                                        _stopEdgeScroll();
                                        setState(() {
                                          _isDragging = false;
                                          _draggedMultiIds = [];
                                          _hoveredSlotIndex = null;
                                          _hoveredBoxIndex = null;
                                          _hoveredIsEdge = false;
                                        });
                                      },
                                      onDragCompleted: () {
                                        _stopEdgeScroll();
                                        setState(() {
                                          _isDragging = false;
                                          _draggedMultiIds = [];
                                          _hoveredSlotIndex = null;
                                          _hoveredBoxIndex = null;
                                          _hoveredIsEdge = false;
                                        });
                                      },
                                      feedback: isMultiDrag
                                          ? _MultiDragPileFeedback(
                                              topCard: card,
                                              count: multiIds.length,
                                              size: cardFeedbackSize,
                                            )
                                          : Opacity(
                                              opacity: 0.88,
                                              child: Material(
                                                elevation: 8,
                                                shadowColor: Colors.black45,
                                                borderRadius: BorderRadius.circular(8),
                                                color: Colors.transparent,
                                                child: SizedBox(
                                                  width: cardFeedbackSize,
                                                  height: cardFeedbackSize,
                                                  child: Transform.scale(
                                                    scale: 1.05,
                                                    child: card,
                                                  ),
                                                ),
                                              ),
                                            ),
                                      childWhenDragging: ghostWidget,
                                      child: DragTarget<String>(
                                        onWillAcceptWithDetails: (details) {
                                          if (isMultiDragData(details.data)) {
                                            final sourceIds = parseMultiDragData(details.data);
                                            if (!sourceIds.contains(entry.uniqueId)) {
                                              HapticFeedback.selectionClick();
                                              return true;
                                            }
                                            return false;
                                          }
                                          if (details.data != entry.uniqueId) {
                                            HapticFeedback.selectionClick();
                                            return true;
                                          }
                                          return false;
                                        },
                                        onMove: (details) {
                                          final ro = itemContext.findRenderObject();
                                          if (ro is RenderBox && ro.hasSize) {
                                            final pointerGlobal = details.offset +
                                                Offset(cardFeedbackSize / 2, cardFeedbackSize / 2);
                                            final local = ro.globalToLocal(pointerGlobal);
                                            final isEdge = local.dx <= (ro.size.width * 0.25);
                                            if (_hoveredSlotIndex != index ||
                                                _hoveredBoxIndex != boxIndex ||
                                                _hoveredIsEdge != isEdge) {
                                              setState(() {
                                                _hoveredSlotIndex = index;
                                                _hoveredBoxIndex = boxIndex;
                                                _hoveredIsEdge = isEdge;
                                              });
                                            }
                                          }
                                        },
                                        onLeave: (data) {
                                          if (_hoveredSlotIndex == index && _hoveredBoxIndex == boxIndex) {
                                            setState(() {
                                              _hoveredSlotIndex = null;
                                              _hoveredBoxIndex = null;
                                              _hoveredIsEdge = false;
                                            });
                                          }
                                        },
                                        onAcceptWithDetails: (details) {
                                          if (isMultiDragData(details.data)) {
                                            HapticFeedback.lightImpact();
                                            final sourceIds = parseMultiDragData(details.data);
                                            setState(() {
                                              _hoveredSlotIndex = null;
                                              _hoveredBoxIndex = null;
                                              _hoveredIsEdge = false;
                                            });
                                            if (onMoveMultiplePokemon != null) {
                                              onMoveMultiplePokemon!(sourceIds, boxIndex, index);
                                            } else if (liveDex.customBoxes.isNotEmpty) {
                                              BoxSequenceManager.moveMultiplePokemon(
                                                dex: liveDex,
                                                sourceIds: sourceIds,
                                                targetBoxIndex: boxIndex,
                                                targetSlotIndex: index,
                                              );
                                            }
                                            return;
                                          }
                                          if (details.data != entry.uniqueId) {
                                            HapticFeedback.lightImpact();
                                            final ro = itemContext.findRenderObject();
                                            bool isEdge = _hoveredIsEdge;
                                            if (ro is RenderBox && ro.hasSize) {
                                              final pointerGlobal = details.offset +
                                                  Offset(cardFeedbackSize / 2, cardFeedbackSize / 2);
                                              final local = ro.globalToLocal(pointerGlobal);
                                              isEdge = local.dx <= (ro.size.width * 0.25);
                                            }
                                            setState(() {
                                              _hoveredSlotIndex = null;
                                              _hoveredBoxIndex = null;
                                              _hoveredIsEdge = false;
                                            });
                                            if (onSwapPokemon != null && !isEdge) {
                                              onSwapPokemon!(details.data, boxIndex, index);
                                            } else {
                                              onMovePokemon?.call(details.data, boxIndex, index);
                                            }
                                          }
                                        },
                                        builder: (context, candidateData, rejectedData) {
                                          final bool isMulti =
                                              candidateData.any((d) => isMultiDragData(d));
                                          final bool isTargeted = isMulti ||
                                              (candidateData.isNotEmpty &&
                                                  !candidateData.contains(entry.uniqueId));
                                          final bool isHoveredSlot =
                                              isTargeted && _hoveredSlotIndex == index && _hoveredBoxIndex == boxIndex;

                                          final bool isSwapTarget =
                                              !isMulti && onSwapPokemon != null && isHoveredSlot && !_hoveredIsEdge;
                                          final bool isInsertTarget = isTargeted &&
                                              (isMulti
                                                  ? isHoveredSlot
                                                  : (onSwapPokemon == null ? true : (isHoveredSlot && _hoveredIsEdge)));

                                          final hoveredCard = AnimatedSlide(
                                            offset: isInsertTarget
                                                ? const Offset(0.06, 0.0)
                                                : Offset.zero,
                                            duration: const Duration(milliseconds: 150),
                                            curve: Curves.easeOutCubic,
                                            child: AnimatedScale(
                                              scale: isSwapTarget ? 1.05 : 1.0,
                                              duration: const Duration(milliseconds: 150),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 150),
                                                decoration: isSwapTarget
                                                    ? BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.amber, width: 2.5),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.amber.withValues(alpha: 0.5),
                                                            blurRadius: 10,
                                                            spreadRadius: 2,
                                                          ),
                                                        ],
                                                      )
                                                    : (isInsertTarget
                                                        ? BoxDecoration(
                                                            borderRadius: BorderRadius.circular(8),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .primary
                                                                    .withValues(alpha: 0.4),
                                                                blurRadius: 6,
                                                                spreadRadius: 1,
                                                              ),
                                                            ],
                                                          )
                                                        : null),
                                                child: displayCard,
                                              ),
                                            ),
                                          );

                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              hoveredCard,

                                              // Swap overlay badge
                                              if (isSwapTarget)
                                                Positioned.fill(
                                                  child: Center(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber.shade800.withValues(alpha: 0.9),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color: Colors.black38,
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.swap_horiz,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            Translator.get(
                                                              'box_action_swap',
                                                              fallback: 'Tauschen',
                                                            ),
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              // Insertion drop indicator line between slots
                                              if (isInsertTarget) ...[
                                                Positioned(
                                                  left: -3,
                                                  top: -2,
                                                  bottom: -2,
                                                  child: Container(
                                                    width: 4,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      borderRadius: BorderRadius.circular(2),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withValues(alpha: 0.8),
                                                          blurRadius: 6,
                                                          spreadRadius: 1,
                                                        ),
                                                        BoxShadow(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withValues(alpha: 0.4),
                                                          blurRadius: 12,
                                                          spreadRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: -5,
                                                  top: -3,
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withValues(alpha: 0.6),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: -5,
                                                  bottom: -3,
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withValues(alpha: 0.6),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ),

                                    // Static circular '+' insert button with >= 44x44 touch target
                                    if (!_isDragging && index % box.crossAxisCount != 0)
                                      Positioned(
                                        left: -27,
                                        top: 0,
                                        bottom: 0,
                                        width: 44,
                                        child: Center(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => onInsertPokemon?.call(
                                              boxIndex,
                                              index,
                                            ),
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              color: Colors.transparent,
                                              alignment: Alignment.center,
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.surface,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.3),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                            },
                          );
                        }

                        return cardWithInteractions;
                      } catch (e) {
                        debugPrint('Fehler beim Rendern in DexBoxView: $e');
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        );
                      }
                    },
                    childCount: box.entries.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    addSemanticIndexes: false,
                  ),
                  ),
                ),
                if (!isEditMode && box.entries.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        Translator.currentLanguage == 'de'
                            ? 'Diese Box ist leer.\nKlicke oben rechts auf das Bearbeiten-Icon (Checkliste), um Pokémon hinzuzufügen!'
                            : 'This box is empty.\nClick the edit icon (checklist) in the top right to add Pokémon!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (isEditMode && _isDragging) ...[
          Positioned(
            left: 0,
            top: 60,
            bottom: 20,
            width: 48,
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) {
                _startEdgeScroll(isNext: false);
                return false;
              },
              onLeave: (data) => _stopEdgeScroll(),
              builder: (context, candidateData, rejectedData) {
                final isHovered =
                    candidateData.isNotEmpty || rejectedData.isNotEmpty;
                return Container(
                  color: isHovered
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: isHovered
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Icon(
                            Icons.chevron_left,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          Positioned(
            right: 0,
            top: 60,
            bottom: 20,
            width: 48,
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) {
                _startEdgeScroll(isNext: true);
                return false;
              },
              onLeave: (data) => _stopEdgeScroll(),
              builder: (context, candidateData, rejectedData) {
                final isHovered =
                    candidateData.isNotEmpty || rejectedData.isNotEmpty;
                return Container(
                  color: isHovered
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  alignment: Alignment.centerRight,
                  child: isHovered
                      ? Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.chevron_right,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ],
    ),
  ),
);
  }
}

class _OverflowStack extends Stack {
  final double overflowLeft;

  const _OverflowStack({
    this.overflowLeft = 0.0,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _RenderOverflowStack(
      overflowLeft: overflowLeft,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderOverflowStack renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.overflowLeft = overflowLeft;
  }
}

class _RenderOverflowStack extends RenderStack {
  double overflowLeft;

  _RenderOverflowStack({
    required this.overflowLeft,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final hitRect = Rect.fromLTRB(-overflowLeft, 0, size.width, size.height);
    if (hitRect.contains(position)) {
      if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
}

class _MultiDragPileFeedback extends StatefulWidget {
  final Widget topCard;
  final int count;
  final double size;

  const _MultiDragPileFeedback({
    required this.topCard,
    required this.count,
    required this.size,
  });

  @override
  State<_MultiDragPileFeedback> createState() => _MultiDragPileFeedbackState();
}

class _MultiDragPileFeedbackState extends State<_MultiDragPileFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pileAnimation;
  late Animation<double> _badgeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _pileAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _badgeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShadowCard(
    BuildContext context, {
    required double angle,
    required Offset offset,
    required double opacity,
  }) {
    final theme = Theme.of(context);
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(2, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.catching_pokemon,
              size: widget.size * 0.35,
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTripleOrMore = widget.count >= 3;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _pileAnimation.value;

        final bottomOffset = Offset(
          (18.0 - 10.0 * t).clamp(4.0, 18.0),
          (18.0 - 10.0 * t).clamp(4.0, 18.0),
        );
        final middleOffset = Offset(
          (10.0 - 6.0 * t).clamp(2.0, 10.0),
          (10.0 - 6.0 * t).clamp(2.0, 10.0),
        );

        return Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: widget.size + 24,
            height: widget.size + 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (isTripleOrMore)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: _buildShadowCard(
                      context,
                      angle: 0.08 * t,
                      offset: bottomOffset,
                      opacity: 0.75,
                    ),
                  ),

                Positioned(
                  left: 0,
                  top: 0,
                  child: _buildShadowCard(
                    context,
                    angle: -0.05 * t,
                    offset: middleOffset,
                    opacity: 0.85,
                  ),
                ),

                Positioned(
                  left: 0,
                  top: 0,
                  child: Opacity(
                    opacity: 0.92,
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                      child: SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: Transform.scale(
                          scale: 1.04,
                          child: widget.topCard,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: -6,
                  right: 18,
                  child: Transform.scale(
                    scale: _badgeScaleAnimation.value,
                    child: Container(
                      key: const Key('multi_drag_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.count}',
                          key: const Key('multi_drag_count_text'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

