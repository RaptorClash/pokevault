import 'package:flutter/material.dart';
import '../../../../models/dex_view_models.dart';
import '../../../../models/user_dex.dart';
import '../../../../providers/dex_provider.dart';
import '../../../../utils/dex_logic_helper.dart';
import '../../../../i18n/strings.g.dart';

/// Renders the header row above a Pokédex box, including navigation chevrons,
/// box title badge with QuickNav trigger, search match counters, and check/uncheck all toggle.
class DexBoxHeader extends StatelessWidget {
  final BoxData box;
  final int boxIndex;
  final int totalBoxes;
  final UserDex liveDex;
  final DexProvider provider;
  final PageController pageController;
  final bool separateForms;
  final bool isSearchActive;
  final List<int> matchIndices;
  final bool isDragging;
  final void Function(bool isNext) onTriggerPageTurn;
  final VoidCallback onQuickNavPressed;

  const DexBoxHeader({
    super.key,
    required this.box,
    required this.boxIndex,
    required this.totalBoxes,
    required this.liveDex,
    required this.provider,
    required this.pageController,
    required this.separateForms,
    required this.isSearchActive,
    required this.matchIndices,
    required this.isDragging,
    required this.onTriggerPageTurn,
    required this.onQuickNavPressed,
  });

  @override
  Widget build(BuildContext context) {
    int prevMatch = -1;
    int nextMatch = -1;
    int currentIndexInMatches = -1;

    if (isSearchActive && matchIndices.isNotEmpty) {
      currentIndexInMatches = matchIndices.indexOf(boxIndex);
      for (int i = matchIndices.length - 1; i >= 0; i--) {
        if (matchIndices[i] < boxIndex) {
          prevMatch = matchIndices[i];
          break;
        }
      }
      for (int i = 0; i < matchIndices.length; i++) {
        if (matchIndices[i] > boxIndex) {
          nextMatch = matchIndices[i];
          break;
        }
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSearchActive && matchIndices.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.keyboard_double_arrow_left),
                color: Theme.of(context).colorScheme.primary,
                onPressed: prevMatch != -1
                    ? () {
                        pageController.animateToPage(
                          prevMatch,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),

            isDragging
                ? DragTarget<String>(
                    onWillAcceptWithDetails: (details) {
                      if (boxIndex > 0) {
                        onTriggerPageTurn(false);
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
                if (separateForms && totalBoxes > 1) {
                  onQuickNavPressed();
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
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                        totalBoxes > 1 &&
                        !(isSearchActive && matchIndices.isNotEmpty))
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
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 14,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentIndexInMatches != -1
                                    ? '${currentIndexInMatches + 1} / ${matchIndices.length}'
                                    : '- / ${matchIndices.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    tooltip: allCaught ? t.box_uncheck_all : t.box_check_all,
                    onPressed: () {
                      bool newState = !allCaught;
                      for (var entry in validEntries) {
                        bool isCaught = DexLogicHelper.isPokemonCaught(
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

            isDragging
                ? DragTarget<String>(
                    onWillAcceptWithDetails: (details) {
                      if (boxIndex < totalBoxes - 1) {
                        onTriggerPageTurn(true);
                      }
                      return false;
                    },
                    builder: (context, candidateData, rejectedData) {
                      return IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: boxIndex < totalBoxes - 1
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
                    onPressed: boxIndex < totalBoxes - 1
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
                onPressed: nextMatch != -1
                    ? () {
                        pageController.animateToPage(
                          nextMatch,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
