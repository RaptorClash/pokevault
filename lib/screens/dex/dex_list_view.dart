import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/user_dex.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_translations.dart';
import '../pokemon_info/pokemon_info_screen.dart';

class DexListView extends StatelessWidget {
  final List<DexDisplayEntry> displayList;
  final UserDex liveDex;
  final DexProvider provider;
  final GlobalKey? firstItemKey;
  final String? tutorialTargetId;

  const DexListView({
    super.key,
    required this.displayList,
    required this.liveDex,
    required this.provider,
    this.firstItemKey,
    this.tutorialTargetId,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.watch<SettingsProvider>().currentLanguage;

    if (displayList.isEmpty) {
      return Center(child: Text(Translator.get('empty_box')));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    int listColumns = screenWidth > 1200
        ? 8
        : (screenWidth > 900 ? 6 : (screenWidth > 600 ? 5 : 3));

    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: listColumns,
        childAspectRatio: 0.80,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        try {
          final entry = displayList[index];
          final isCaught = liveDex.caughtIds.contains(entry.uniqueId);
          final isShiny = liveDex.shinyIds.contains(entry.uniqueId);

          return GestureDetector(
            key: entry.uniqueId == tutorialTargetId ? firstItemKey : null,
            onTap: () => provider.togglePokemon(liveDex.id, entry.uniqueId),
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => PokemonInfoScreen(
                    entries: displayList,
                    initialIndex: index,
                    dexId: liveDex.id,
                    isBoxView: false,
                  ),
                ),
              );
            },
            child: Card(
              color: isCaught
                  ? Colors.green.withValues(alpha: 0.15)
                  : Theme.of(context).cardColor,
              elevation: isCaught ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isCaught ? Colors.green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${entry.pokemon.id.toString().padLeft(3, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
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
                          child: CachedNetworkImage(
                            imageUrl: entry.imageUrl,
                            memCacheWidth: 200,
                            fit: BoxFit.contain,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
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
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            entry.pokemon.getName(currentLanguage) +
                                entry.displaySuffix,
                            style: TextStyle(
                              fontWeight: isCaught
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isCaught || isShiny)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Column(
                        children: [
                          if (isCaught)
                            const Icon(
                              Icons.catching_pokemon,
                              color: Colors.green,
                              size: 20,
                            ),
                          if (isShiny)
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        } catch (e) {
          debugPrint('Fehler beim Rendern in DexListView: $e');
          return const Card(
            child: Center(child: Icon(Icons.error_outline, color: Colors.red)),
          );
        }
      },
    );
  }
}
