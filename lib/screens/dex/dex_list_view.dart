import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/user_dex.dart';
import '../../models/dex_view_models.dart';
import '../../utils/dex_logic_helper.dart';
import '../../providers/dex_provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_translations.dart';
import '../../services/shiny_lock_service.dart';
import '../../utils/notification_helper.dart';
import '../pokemon_info/pokemon_info_screen.dart';
import 'package:flutter/services.dart';

class DexListView extends StatelessWidget {
  final List<DexDisplayEntry> displayList;
  final UserDex liveDex;
  final DexProvider provider;
  final GlobalKey? firstItemKey;
  final String? tutorialTargetId;
  final VoidCallback? onInfoScreenReturned;

  const DexListView({
    super.key,
    required this.displayList,
    required this.liveDex,
    required this.provider,
    this.firstItemKey,
    this.tutorialTargetId,
    this.onInfoScreenReturned,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguage = context.watch<SettingsProvider>().currentLanguage;

    if (displayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            Translator.currentLanguage == 'de'
              ? 'Dieser Dex ist leer.\nKlicke oben rechts auf das Bearbeiten-Icon (Checkliste), um Pokémon hinzuzufügen!'
              : 'This Dex is empty.\nClick the edit icon (checklist) in the top right to add Pokémon!',
            textAlign: TextAlign.center,
          ),
        ),
      );
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
          final isCaught = DexLogicHelper.isPokemonCaught(liveDex, entry.uniqueId);
          final isShiny = DexLogicHelper.isPokemonShiny(liveDex, entry.uniqueId);
          final isShinyLocked = ShinyLockService.isShinyLocked(entry, dexRegion: liveDex.region);
          void openInfoScreen() {
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
            ).then((_) {
              onInfoScreenReturned?.call();
            });
          }

          return Focus(
            canRequestFocus:
                false,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.keyI ||
                    (event.logicalKey == LogicalKeyboardKey.enter &&
                        HardwareKeyboard.instance.isControlPressed)) {
                  openInfoScreen();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: InkWell(
              key: (tutorialTargetId != null && entry.uniqueId == tutorialTargetId)
                  ? firstItemKey
                  : (tutorialTargetId == null && index == 0)
                      ? firstItemKey
                      : null,
              onTap: () {
                if (liveDex.isShinyDex && isShinyLocked) {
                  NotificationHelper.showError(
                    ShinyLockService.getShinyLockReason(
                      entry,
                      dexRegion: liveDex.region,
                      lang: currentLanguage,
                    ),
                  );
                  return;
                }
                provider.togglePokemon(liveDex.id, entry.uniqueId);
              },
              onSecondaryTap: openInfoScreen,
              onLongPress: openInfoScreen,
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
                          child: Builder(
                            builder: (context) {
                              final imageWidget = CachedNetworkImage(
                                imageUrl: entry.imageUrl,
                                memCacheWidth: 200,
                                fit: BoxFit.contain,
                                fadeInDuration: const Duration(milliseconds: 150),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                              );

                              if (isCaught) {
                                return imageWidget;
                              }

                              return ColorFiltered(
                                colorFilter: const ColorFilter.matrix(<double>[
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
                                child: imageWidget,
                              );
                            },
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
                    if (isShinyLocked)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Tooltip(
                          message: ShinyLockService.getShinyLockReason(
                            entry,
                            dexRegion: liveDex.region,
                            lang: currentLanguage,
                          ),
                          child: Container(
                            key: Key('shiny_lock_badge_${entry.uniqueId}'),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red, width: 1),
                            ),
                            child: const Icon(
                              Icons.lock,
                              size: 14,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
