import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_dex.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../i18n/strings.g.dart';
import '../../utils/box_sequence_calculator.dart';
import '../../utils/dex_logic_helper.dart';
import 'delegates/box_action_delegate.dart';
import 'widgets/box_view/dex_box_header.dart';
import 'widgets/box_view/dex_box_grid.dart';
export 'delegates/box_action_delegate.dart';

/// Main container widget displaying Pokédex boxes in a scrollable [PageView].
/// Supports page turning, edge scrolling, quick navigation, and delegates
/// slot manipulation to a configured [BoxActionDelegate].
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
  final BoxActionDelegate actionDelegate;

  // Legacy callback parameters for backward-compatibility
  final void Function(int boxIndex, int itemIndex)? onSelectionChanged;
  final void Function(int boxIndex, int insertIndex)? onInsertPokemon;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  )? onMovePokemon;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
  )? onSwapPokemon;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  )? onMovePokemonWithSource;
  final void Function(
    String sourceUniqueId,
    int targetBoxIndex,
    int targetIndex,
    int? sourceBoxIndex,
    int? sourceSlotIndex,
  )? onSwapPokemonWithSource;
  final void Function(
    List<String> sourceUniqueIds,
    int targetBoxIndex,
    int targetIndex,
  )? onMoveMultiplePokemon;
  final VoidCallback? onInfoScreenReturned;

  DexBoxView({
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
    BoxActionDelegate? actionDelegate,
    this.onSelectionChanged,
    this.onInsertPokemon,
    this.onMovePokemon,
    this.onSwapPokemon,
    this.onMovePokemonWithSource,
    this.onSwapPokemonWithSource,
    this.onMoveMultiplePokemon,
    this.onInfoScreenReturned,
  }) : actionDelegate = actionDelegate ??
            DefaultBoxActionDelegate(
              onSelectionChangedHandler: onSelectionChanged,
              onInsertPokemonHandler: onInsertPokemon,
              onMovePokemonHandler: onMovePokemon,
              onSwapPokemonHandler: onSwapPokemon,
              onMovePokemonWithSourceHandler: onMovePokemonWithSource,
              onSwapPokemonWithSourceHandler: onSwapPokemonWithSource,
              onMoveMultiplePokemonHandler: onMoveMultiplePokemon,
              onInfoScreenReturnedHandler: onInfoScreenReturned,
            );

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

  static bool isSameSlotDragData(
    String? data,
    int targetBoxIndex,
    int targetSlotIndex,
    String targetUniqueId,
  ) {
    if (data == null) return false;
    final slot = BoxSlotDragData.tryParse(data);
    if (slot != null) {
      return slot.boxIndex == targetBoxIndex && slot.slotIndex == targetSlotIndex;
    }
    return data == targetUniqueId;
  }

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
  BoxActionDelegate get actionDelegate => widget.actionDelegate;

  @override
  void dispose() {
    _edgeScrollTimer?.cancel();
    super.dispose();
  }

  void _triggerPageTurn({required bool isNext}) {
    if (!pageController.hasClients) return;
    final now = DateTime.now();
    if (_lastEdgeFlipTime != null &&
        now.difference(_lastEdgeFlipTime!) < const Duration(milliseconds: 600)) {
      return;
    }
    _lastEdgeFlipTime = now;
    if (isNext) {
      if ((pageController.page?.round() ?? 0) < boxes.length - 1) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      if ((pageController.page?.round() ?? 0) > 0) {
        pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _startEdgeScroll({required bool isNext}) {
    if (_edgeScrollTimer != null && _edgeScrollTimer!.isActive) return;
    _triggerPageTurn(isNext: isNext);
    _edgeScrollTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (timer) {
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
          title: Text(t.jump_to_region),
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
                  String regionName = (t['region_name_$regionKey'] ?? regionKey);
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.close),
            ),
          ],
        );
      },
    );
  }

  List<String> _getSelectedPokemonIds() {
    final List<String> ids = [];
    for (final key in selectedForEdit) {
      final parts = key.split('_');
      if (parts.length == 2) {
        final bIdx = int.tryParse(parts[0]);
        final sIdx = int.tryParse(parts[1]);
        if (bIdx != null &&
            sIdx != null &&
            bIdx < boxes.length &&
            sIdx < boxes[bIdx].entries.length) {
          final entry = boxes[bIdx].entries[sIdx];
          if (entry.uniqueId.isNotEmpty) {
            ids.add(entry.uniqueId);
          }
        }
      }
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return Center(child: Text(t.empty_box));

    double screenWidth = MediaQuery.of(context).size.width;
    double boxMaxWidth = screenWidth > 1200
        ? 1100
        : (screenWidth > 800 ? 800 : double.infinity);

    final List<DexDisplayEntry> boxOrderedEntries =
        boxes.expand((b) => b.entries).toList();

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
                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    DexBoxHeader(
                      box: box,
                      boxIndex: boxIndex,
                      totalBoxes: boxes.length,
                      liveDex: liveDex,
                      provider: provider,
                      pageController: pageController,
                      separateForms: separateForms,
                      isSearchActive: isSearchActive,
                      matchIndices: matchIndices,
                      isDragging: _isDragging,
                      onTriggerPageTurn: (isNext) =>
                          _triggerPageTurn(isNext: isNext),
                      onQuickNavPressed: () => _showQuickNavDialog(context),
                    ),
                    DexBoxGrid(
                      box: box,
                      boxIndex: boxIndex,
                      boxes: boxes,
                      boxOrderedEntries: boxOrderedEntries,
                      liveDex: liveDex,
                      provider: provider,
                      pageController: pageController,
                      isEditMode: isEditMode,
                      selectedForEdit: selectedForEdit,
                      highlightedIds: highlightedIds,
                      isSearchActive: isSearchActive,
                      actionDelegate: actionDelegate,
                      firstItemKey: firstItemKey,
                      tutorialTargetId: tutorialTargetId,
                      isDragging: _isDragging,
                      draggedMultiIds: _draggedMultiIds,
                      hoveredSlotIndex: _hoveredSlotIndex,
                      hoveredBoxIndex: _hoveredBoxIndex,
                      hoveredIsEdge: _hoveredIsEdge,
                      onHoverChanged: (slot, bIndex, isEdge) {
                        setState(() {
                          _hoveredSlotIndex = slot;
                          _hoveredBoxIndex = bIndex;
                          _hoveredIsEdge = isEdge;
                        });
                      },
                      onDragStateChanged: (isDragging, multiIds) {
                        setState(() {
                          _isDragging = isDragging;
                          _draggedMultiIds = multiIds;
                        });
                      },
                      onStopEdgeScroll: _stopEdgeScroll,
                      getSelectedPokemonIds: _getSelectedPokemonIds,
                      screenWidth: screenWidth,
                    ),
                    if (!isEditMode && box.entries.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            LocaleSettings.currentLocale == AppLocale.de
                                ? 'Diese Box ist leer.\nKlicke oben rechts auf das Bearbeiten-Icon (Checkliste), um Pokémon hinzuzufügen!'
                                : 'This box is empty.\nClick the edit icon (checklist) in the top right to add Pokémon!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
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
                          ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.18)
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
                          ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.18)
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
