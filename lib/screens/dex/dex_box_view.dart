import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_dex.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../l10n/app_translations.dart';
import '../pokemon_info/pokemon_info_screen.dart';

class DexBoxView extends StatelessWidget {
  final List<BoxData> boxes;
  final UserDex liveDex;
  final DexProvider provider;
  final PageController pageController;
  final bool separateForms;
  final Set<String> highlightedIds;
  final bool isSearchActive;
  final GlobalKey? firstItemKey;
  final String? tutorialTargetId;

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
  });

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

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: boxMaxWidth),
        child: PageView.builder(
          controller: pageController,
          itemCount: boxes.length,
          itemBuilder: (context, boxIndex) {
            final box = boxes[boxIndex];
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            if (pageController.hasClients &&
                                pageController.page! > 0) {
                              pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            if (separateForms && boxes.length > 1) {
                              _showQuickNavDialog(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.5),
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
                                if (separateForms && boxes.length > 1)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            if (pageController.hasClients &&
                                pageController.page! < boxes.length - 1) {
                              pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
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
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = box.entries[index];
                      final isCaught = liveDex.caughtIds.contains(
                        entry.uniqueId,
                      );
                      final isShiny = liveDex.shinyIds.contains(entry.uniqueId);

                      final bool isMatched =
                          isSearchActive &&
                          highlightedIds.contains(entry.uniqueId);
                      final bool isDimmed =
                          isSearchActive &&
                          !highlightedIds.contains(entry.uniqueId);

                      return GestureDetector(
                        key: entry.uniqueId == tutorialTargetId
                            ? firstItemKey
                            : null,
                        onTap: () =>
                            provider.togglePokemon(liveDex.id, entry.uniqueId),
                        onLongPress: () {
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
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isDimmed ? 0.2 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCaught
                                  ? Colors.green.withOpacity(0.15)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isMatched
                                    ? Theme.of(context).colorScheme.primary
                                    : (isCaught
                                          ? Colors.green
                                          : Theme.of(
                                              context,
                                            ).dividerColor.withOpacity(0.3)),
                                width: (isMatched || isCaught) ? 2 : 1,
                              ),
                              boxShadow: isMatched
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: ColorFiltered(
                                    colorFilter: isCaught
                                        ? const ColorFilter.mode(
                                            Colors.transparent,
                                            BlendMode.dst,
                                          )
                                        : const ColorFilter.matrix(<double>[
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
                                          ]),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: CachedNetworkImage(
                                        imageUrl: entry.imageUrl,
                                        memCacheWidth: 200,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: CircularProgressIndicator(
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
                                    ),
                                  ),
                                ),
                                if (isCaught || isShiny)
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
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: box.entries.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
