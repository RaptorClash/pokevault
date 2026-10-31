import 'package:flutter/material.dart';
import '../../../../models/dex_view_models.dart';
import '../../../../models/user_dex.dart';
import '../../../../providers/dex_provider.dart';
import '../../delegates/box_action_delegate.dart';
import 'dex_box_slot_item.dart';

/// Renders the responsive grid of Pokémon slots for a single Pokédex box,
/// managing keyboard navigation and mapping entries to [DexBoxSlotItem].
class DexBoxGrid extends StatelessWidget {
  final BoxData box;
  final int boxIndex;
  final List<BoxData> boxes;
  final List<DexDisplayEntry> boxOrderedEntries;
  final UserDex liveDex;
  final DexProvider provider;
  final PageController pageController;
  final bool isEditMode;
  final Set<String> selectedForEdit;
  final Set<String> highlightedIds;
  final bool isSearchActive;
  final BoxActionDelegate actionDelegate;
  final GlobalKey? firstItemKey;
  final String? tutorialTargetId;
  final bool isDragging;
  final List<String> draggedMultiIds;
  final int? hoveredSlotIndex;
  final int? hoveredBoxIndex;
  final bool hoveredIsEdge;
  final void Function(int? slotIndex, int? boxIndex, bool isEdge) onHoverChanged;
  final void Function(bool isDragging, List<String> multiIds) onDragStateChanged;
  final VoidCallback onStopEdgeScroll;
  final List<String> Function() getSelectedPokemonIds;
  final double screenWidth;

  const DexBoxGrid({
    super.key,
    required this.box,
    required this.boxIndex,
    required this.boxes,
    required this.boxOrderedEntries,
    required this.liveDex,
    required this.provider,
    required this.pageController,
    required this.isEditMode,
    required this.selectedForEdit,
    required this.highlightedIds,
    required this.isSearchActive,
    required this.actionDelegate,
    this.firstItemKey,
    this.tutorialTargetId,
    required this.isDragging,
    required this.draggedMultiIds,
    required this.hoveredSlotIndex,
    required this.hoveredBoxIndex,
    required this.hoveredIsEdge,
    required this.onHoverChanged,
    required this.onDragStateChanged,
    required this.onStopEdgeScroll,
    required this.getSelectedPokemonIds,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: box.crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: isEditMode ? 10 : 4,
          mainAxisSpacing: isEditMode ? 10 : 4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = box.entries[index];
            return DexBoxSlotItem(
              entry: entry,
              index: index,
              boxIndex: boxIndex,
              box: box,
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
              isDragging: isDragging,
              draggedMultiIds: draggedMultiIds,
              hoveredSlotIndex: hoveredSlotIndex,
              hoveredBoxIndex: hoveredBoxIndex,
              hoveredIsEdge: hoveredIsEdge,
              onHoverChanged: onHoverChanged,
              onDragStateChanged: onDragStateChanged,
              onStopEdgeScroll: onStopEdgeScroll,
              getSelectedPokemonIds: getSelectedPokemonIds,
              screenWidth: screenWidth,
            );
          },
          childCount: box.entries.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
        ),
      ),
    );
  }
}
