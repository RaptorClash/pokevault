import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../constants/app_vectors.dart';
import '../../../../models/dex_view_models.dart';
import '../../../../models/user_dex.dart';
import '../../../../providers/dex_provider.dart';
import '../../../../services/shiny_lock_service.dart';
import '../../../../utils/box_sequence_manager.dart';
import '../../../../utils/dex_logic_helper.dart';
import '../../../../utils/notification_helper.dart';
import '../../../../widgets/painters/dashed_rrect_painter.dart';
import '../../../../i18n/strings.g.dart';
import '../../../pokemon_info/pokemon_info_screen.dart';
import '../../dex_box_view.dart';
import '../overflow_stack.dart';
import '../multi_drag_pile_feedback.dart';

/// Renders an individual slot within a Pokédex box, supporting display of empty slots,
/// placeholders, caught Pokémon cards, selection highlights, and drag-and-drop interactions.
class DexBoxSlotItem extends StatelessWidget {
  final DexDisplayEntry entry;
  final int index;
  final int boxIndex;
  final BoxData box;
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

  const DexBoxSlotItem({
    super.key,
    required this.entry,
    required this.index,
    required this.boxIndex,
    required this.box,
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

  void _openInfoScreen(BuildContext context) {
    int initialIndex = boxOrderedEntries.indexOf(entry);
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PokemonInfoScreen(
          entries: boxOrderedEntries,
          initialIndex: initialIndex != -1 ? initialIndex : 0,
          dexId: liveDex.id,
          boxes: boxes,
          isBoxView: true,
          onPageChanged: (newIndex) {
            final currentEntry = boxOrderedEntries[newIndex];
            int targetBoxIndex = boxes.indexWhere(
              (b) => b.entries.contains(currentEntry),
            );
            if (targetBoxIndex != -1 && pageController.hasClients) {
              if (pageController.page?.round() != targetBoxIndex) {
                pageController.jumpToPage(targetBoxIndex);
              }
            }
          },
        ),
      ),
    ).then((_) {
      actionDelegate.onInfoScreenReturned();
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
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
            onHoverChanged(null, null, false);
            if (DexBoxView.isMultiDragData(details.data)) {
              final sourceIds = DexBoxView.parseMultiDragData(details.data);
              if (actionDelegate.hasMoveMultiplePokemonHandler) {
                actionDelegate.onMoveMultiplePokemon(sourceIds, boxIndex, index);
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
            final slotData = BoxSlotDragData.tryParse(details.data);
            final cleanId = slotData?.uniqueId ?? details.data;
            actionDelegate.onMovePokemonWithSource(
              cleanId,
              boxIndex,
              index,
              slotData?.boxIndex,
              slotData?.slotIndex,
            );
          },
          builder: (context, candidateData, rejectedData) {
            final bool isTargeted = candidateData.isNotEmpty;
            return InkWell(
              onTap: () {
                actionDelegate.onInsertPokemon(boxIndex, index);
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
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.3),
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
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isTargeted ? Icons.arrow_downward : Icons.add,
                      color: isTargeted
                          ? Theme.of(context).colorScheme.primary
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
      final isShinyLocked = ShinyLockService.isShinyLocked(
        entry,
        dexRegion: liveDex.region,
      );

      final bool isMatched =
          isSearchActive &&
          (highlightedIds.contains(entry.uniqueId) ||
              (entry.uniqueId.contains('__') &&
                  highlightedIds.contains(
                    DexLogicHelper.getBaseId(entry.uniqueId),
                  )));
      final bool isDimmed = isSearchActive && !isMatched;

      Widget card = Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyI ||
                (event.logicalKey == LogicalKeyboardKey.enter &&
                    HardwareKeyboard.instance.isControlPressed)) {
              _openInfoScreen(context);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            key: (tutorialTargetId != null && entry.uniqueId == tutorialTargetId)
                ? firstItemKey
                : (tutorialTargetId == null && boxIndex == 0 && index == 0)
                    ? firstItemKey
                    : null,
            onTap: isEditMode
                ? () => actionDelegate.onSelectionChanged(boxIndex, index)
                : (entry.isPlaceholder
                    ? () => actionDelegate.onInsertPokemon(boxIndex, index)
                    : () {
                        if (liveDex.isShinyDex && isShinyLocked) {
                          NotificationHelper.showError(
                            ShinyLockService.getShinyLockReason(
                              entry,
                              dexRegion: liveDex.region,
                              lang: LocaleSettings.currentLocale.languageCode,
                            ),
                          );
                          return;
                        }
                        provider.togglePokemon(
                          liveDex.id,
                          entry.uniqueId,
                        );
                      }),
            onSecondaryTap:
                (isEditMode || entry.isPlaceholder)
                    ? null
                    : () => _openInfoScreen(context),
            onLongPress:
                (isEditMode || entry.isPlaceholder)
                    ? null
                    : () => _openInfoScreen(context),
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.crop_free,
                                    size: 22,
                                    color: isMatched
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.placeholder,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isMatched
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.45),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isEditMode &&
                              selectedForEdit.contains('${boxIndex}_$index'))
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
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
                                  : Theme.of(context)
                                      .dividerColor
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
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, error, stackTrace) =>
                                      CachedNetworkImage(
                                    imageUrl:
                                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${liveDex.isShinyDex ? 'shiny/' : ''}${entry.pokemon.id}.png',
                                    memCacheWidth: 200,
                                    fit: BoxFit.contain,
                                    errorWidget: (c, e, s) => const Icon(
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
                                        colorFilter: const ColorFilter.matrix(
                                          <double>[
                                            0.2126, 0.7152, 0.0722, 0, 0,
                                            0.2126, 0.7152, 0.0722, 0, 0,
                                            0.2126, 0.7152, 0.0722, 0, 0,
                                            0,      0,      0,      1, 0,
                                          ],
                                        ),
                                        child: imageWidget,
                                      ),
                              );
                            },
                          ),
                          if (isShinyLocked)
                            Positioned(
                              top: 2,
                              left: 2,
                              child: Tooltip(
                                message: ShinyLockService.getShinyLockReason(
                                  entry,
                                  dexRegion: liveDex.region,
                                  lang: LocaleSettings.currentLocale.languageCode,
                                ),
                                child: Container(
                                  key: Key(
                                    'box_shiny_lock_badge_${entry.uniqueId}',
                                  ),
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
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
                              selectedForEdit.contains('${boxIndex}_$index'))
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
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
                ((effectiveWidth - 16 - (box.crossAxisCount - 1) * spacing) /
                        box.crossAxisCount)
                    .clamp(48.0, 160.0);

            final bool isThisSelected =
                selectedForEdit.contains('${boxIndex}_$index');
            final bool isMultiDrag =
                isThisSelected && selectedForEdit.length > 1;
            final List<String> multiIds =
                isMultiDrag ? getSelectedPokemonIds() : const <String>[];
            final String dragData = isMultiDrag
                ? DexBoxView.createMultiDragData(multiIds)
                : BoxSlotDragData.serialize(
                    boxIndex,
                    index,
                    entry.uniqueId,
                  );
            final bool isGhosted =
                isDragging && draggedMultiIds.contains(entry.uniqueId);

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

            return OverflowStack(
              overflowLeft: 32,
              clipBehavior: Clip.none,
              children: [
                LongPressDraggable<String>(
                  data: dragData,
                  dragAnchorStrategy: (draggable, context, position) {
                    return Offset(cardFeedbackSize / 2, cardFeedbackSize / 2);
                  },
                  onDragStarted: () {
                    onDragStateChanged(true, isMultiDrag ? multiIds : []);
                  },
                  onDragEnd: (details) {
                    onStopEdgeScroll();
                    onDragStateChanged(false, []);
                    onHoverChanged(null, null, false);
                  },
                  onDraggableCanceled: (velocity, offset) {
                    onStopEdgeScroll();
                    onDragStateChanged(false, []);
                    onHoverChanged(null, null, false);
                  },
                  onDragCompleted: () {
                    onStopEdgeScroll();
                    onDragStateChanged(false, []);
                    onHoverChanged(null, null, false);
                  },
                  feedback: isMultiDrag
                      ? MultiDragPileFeedback(
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
                      if (DexBoxView.isMultiDragData(details.data)) {
                        final sourceIds =
                            DexBoxView.parseMultiDragData(details.data);
                        if (!sourceIds.contains(entry.uniqueId)) {
                          HapticFeedback.selectionClick();
                          return true;
                        }
                        return false;
                      }
                      if (!DexBoxView.isSameSlotDragData(
                        details.data,
                        boxIndex,
                        index,
                        entry.uniqueId,
                      )) {
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
                        if (hoveredSlotIndex != index ||
                            hoveredBoxIndex != boxIndex ||
                            hoveredIsEdge != isEdge) {
                          onHoverChanged(index, boxIndex, isEdge);
                        }
                      }
                    },
                    onLeave: (data) {
                      if (hoveredSlotIndex == index &&
                          hoveredBoxIndex == boxIndex) {
                        onHoverChanged(null, null, false);
                      }
                    },
                    onAcceptWithDetails: (details) {
                      if (DexBoxView.isMultiDragData(details.data)) {
                        HapticFeedback.lightImpact();
                        final sourceIds =
                            DexBoxView.parseMultiDragData(details.data);
                        onHoverChanged(null, null, false);
                        if (actionDelegate.hasMoveMultiplePokemonHandler) {
                          actionDelegate.onMoveMultiplePokemon(
                            sourceIds,
                            boxIndex,
                            index,
                          );
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
                      if (!DexBoxView.isSameSlotDragData(
                        details.data,
                        boxIndex,
                        index,
                        entry.uniqueId,
                      )) {
                        HapticFeedback.lightImpact();
                        final ro = itemContext.findRenderObject();
                        bool isEdge = hoveredIsEdge;
                        if (ro is RenderBox && ro.hasSize) {
                          final pointerGlobal = details.offset +
                              Offset(cardFeedbackSize / 2, cardFeedbackSize / 2);
                          final local = ro.globalToLocal(pointerGlobal);
                          isEdge = local.dx <= (ro.size.width * 0.25);
                        }
                        onHoverChanged(null, null, false);
                        final slotData = BoxSlotDragData.tryParse(details.data);
                        final cleanId = slotData?.uniqueId ?? details.data;

                        final bool hasSwap = actionDelegate.hasSwapTarget;
                        if (hasSwap && !isEdge) {
                          actionDelegate.onSwapPokemonWithSource(
                            cleanId,
                            boxIndex,
                            index,
                            slotData?.boxIndex,
                            slotData?.slotIndex,
                          );
                        } else {
                          actionDelegate.onMovePokemonWithSource(
                            cleanId,
                            boxIndex,
                            index,
                            slotData?.boxIndex,
                            slotData?.slotIndex,
                          );
                        }
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      final bool isMulti = candidateData.any(
                        (d) => DexBoxView.isMultiDragData(d),
                      );
                      final bool isTargeted = isMulti ||
                          (candidateData.isNotEmpty &&
                              !DexBoxView.isSameSlotDragData(
                                candidateData.first,
                                boxIndex,
                                index,
                                entry.uniqueId,
                              ));
                      final bool isHoveredSlot = isTargeted &&
                          hoveredSlotIndex == index &&
                          hoveredBoxIndex == boxIndex;

                      final bool hasSwapTarget = actionDelegate.hasSwapTarget;
                      final bool isSwapTarget =
                          !isMulti && hasSwapTarget && isHoveredSlot && !hoveredIsEdge;
                      final bool isInsertTarget = isTargeted &&
                          (isMulti
                              ? isHoveredSlot
                              : (!hasSwapTarget ? true : (isHoveredSlot && hoveredIsEdge)));

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
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 2.5,
                                    ),
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
                                    color: Colors.amber.shade800
                                        .withValues(alpha: 0.9),
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
                                        t.box_action_swap,
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

                // Static circular '+' insert button
                if (!isDragging && index % box.crossAxisCount != 0)
                  Positioned(
                    left: -19,
                    top: 0,
                    bottom: 0,
                    width: 28,
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => actionDelegate.onInsertPokemon(
                          boxIndex,
                          index,
                        ),
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
              ],
            );
          },
        );
      }

      return cardWithInteractions;
    } catch (e) {
      debugPrint('Fehler beim Rendern in DexBoxSlotItem: $e');
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
  }
}
