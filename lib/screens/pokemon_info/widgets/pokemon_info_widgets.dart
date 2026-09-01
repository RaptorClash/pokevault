import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../models/dex_view_models.dart';
import '../../../models/pokemon.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/database_service.dart';
import '../../../l10n/app_translations.dart';
import '../../../utils/notification_helper.dart';

const Map<String, Color> pokemonTypeColors = {
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705848),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

class PokemonHeaderWidget extends StatelessWidget {
  final DexDisplayEntry entry;
  final bool wantShiny;
  final VoidCallback onShinyToggled;
  final GlobalKey shinyToggleKey;
  final PokemonForm? currentForm;

  const PokemonHeaderWidget({
    super.key,
    required this.entry,
    required this.wantShiny,
    required this.onShinyToggled,
    required this.shinyToggleKey,
    required this.currentForm,
  });

  String _getImageUrl(DexDisplayEntry entry, bool wantShiny) {
    String url = entry.imageUrl;
    bool isCurrentlyShiny = url.contains('/shiny/');

    if (wantShiny && !isCurrentlyShiny) {
      if (url.contains('official-artwork/')) {
        return url.replaceFirst('official-artwork/', 'official-artwork/shiny/');
      } else if (url.contains('home/female/')) {
        return url.replaceFirst('home/female/', 'home/shiny/female/');
      } else if (url.contains('home/')) {
        return url.replaceFirst('home/', 'home/shiny/');
      }
    } else if (!wantShiny && isCurrentlyShiny) {
      return url.replaceFirst('/shiny/', '/');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    try {
      final Color typeColor1 =
          currentForm != null && currentForm!.types.isNotEmpty
          ? pokemonTypeColors[currentForm!.types.first] ?? Colors.grey
          : Colors.grey;

      final Color typeColor2 =
          currentForm != null && currentForm!.types.length > 1
          ? pokemonTypeColors[currentForm!.types[1]] ?? typeColor1
          : typeColor1;

      String currentImageUrl = _getImageUrl(entry, wantShiny);
      String fallbackUrl =
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${wantShiny ? 'shiny/' : ''}${entry.pokemon.id}.png';

      return Container(
        height: 240,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              typeColor1.withValues(alpha: 0.5),
              typeColor2.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: kIsWeb
                  ? Image.network(
                      currentImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.network(
                            fallbackUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.catching_pokemon,
                              size: 60,
                              color: Colors.white54,
                            ),
                          ),
                    )
                  : CachedNetworkImage(
                      imageUrl: currentImageUrl,
                      fit: BoxFit.contain,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => CachedNetworkImage(
                        imageUrl: fallbackUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (c, e, s) => const Icon(
                          Icons.catching_pokemon,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                    ),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: FloatingActionButton.small(
                key: shinyToggleKey,
                heroTag: 'shiny_toggle_${entry.uniqueId}',
                backgroundColor: wantShiny
                    ? Colors.amber
                    : Theme.of(context).colorScheme.surface,
                tooltip: wantShiny
                    ? (Translator.get('normal_form') != 'normal_form'
                          ? Translator.get('normal_form')
                          : 'Normale Form')
                    : (Translator.get('shiny_form') != 'shiny_form'
                          ? Translator.get('shiny_form')
                          : 'Shiny Form'),
                onPressed: onShinyToggled,
                child: Icon(
                  wantShiny ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                  color: wantShiny ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_header_load')} $e",
        );
      });
      return const SizedBox(height: 240, child: Icon(Icons.error));
    }
  }
}

class PokemonBasicInfoWidget extends StatelessWidget {
  final DexDisplayEntry entry;
  final DexProvider provider;
  final GlobalKey basicInfoKey;
  final PokemonForm? currentForm;

  const PokemonBasicInfoWidget({
    super.key,
    required this.entry,
    required this.provider,
    required this.basicInfoKey,
    required this.currentForm,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Container(
        key: basicInfoKey,
        child: Column(
          children: [
            Text(
              '#${entry.pokemon.id.toString().padLeft(3, '0')}',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              entry.pokemon.getName(provider.currentLanguage),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (currentForm != null && currentForm!.types.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: currentForm!.types.map((type) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pokemonTypeColors[type] ?? Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Text(
                      Translator.get('type_$type').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (entry.displaySuffix.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${Translator.get('form') != 'form' ? Translator.get('form') : 'Form'}: ${entry.displaySuffix.replaceAll('(', '').replaceAll(')', '').trim()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_basic_info')} $e",
        );
      });
      return const SizedBox.shrink();
    }
  }
}

class PokemonStatusTogglesWidget extends StatelessWidget {
  final String dexId;
  final DexDisplayEntry entry;
  final bool isCaught;
  final bool isShiny;
  final DexProvider provider;
  final GlobalKey caughtStatusKey;
  final GlobalKey shinyStatusKey;

  const PokemonStatusTogglesWidget({
    super.key,
    required this.dexId,
    required this.entry,
    required this.isCaught,
    required this.isShiny,
    required this.provider,
    required this.caughtStatusKey,
    required this.shinyStatusKey,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        children: [
          Card(
            key: caughtStatusKey,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: SwitchListTile(
              title: Text(
                Translator.get('caught_status') != 'caught_status'
                    ? Translator.get('caught_status')
                    : 'Gefangen Status',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                Translator.get('mark_as_caught') != 'mark_as_caught'
                    ? Translator.get('mark_as_caught')
                    : 'Als gefangen markieren',
              ),
              secondary: Icon(
                Icons.catching_pokemon,
                color: isCaught ? Colors.green : Colors.grey,
              ),
              value: isCaught,
              activeThumbColor: Colors.green,
              onChanged: (val) {
                provider.togglePokemon(dexId, entry.uniqueId);
              },
            ),
          ),
          Card(
            key: shinyStatusKey,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: SwitchListTile(
              title: const Text(
                'Shiny Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Als schillernd markieren'),
              secondary: Icon(
                Icons.star,
                color: isShiny ? Colors.amber : Colors.grey,
              ),
              value: isShiny,
              activeThumbColor: Colors.amber,
              onChanged: (val) {
                provider.toggleShiny(dexId, entry.uniqueId);
              },
            ),
          ),
        ],
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_status_toggles')} $e",
        );
      });
      return const SizedBox.shrink();
    }
  }
}

class MatchingBallsWidget extends StatelessWidget {
  final DexDisplayEntry entry;
  final GlobalKey matchingBallsKey;

  const MatchingBallsWidget({
    super.key,
    required this.entry,
    required this.matchingBallsKey,
  });

  Widget _buildBallCard(
    BuildContext context,
    IconData icon,
    String title,
    List<String> ballKeys,
    Color iconColor,
    Map<String, String> ballUrls,
  ) {
    bool isAny = ballKeys.isEmpty || ballKeys.contains('any_ball');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isAny
              ? Text(
                  Translator.get('any_ball'),
                  style: const TextStyle(fontSize: 15),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ballKeys.map((key) {
                    final imgUrl = ballUrls[key];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                          ).dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (imgUrl != null)
                            kIsWeb
                                ? Image.network(
                                    imgUrl,
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.catching_pokemon,
                                      size: 24,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imgUrl,
                                    width: 24,
                                    height: 24,
                                    errorWidget: (_, _, _) => const Icon(
                                      Icons.catching_pokemon,
                                      size: 24,
                                    ),
                                  ),
                          if (imgUrl != null) const SizedBox(width: 8),
                          Text(
                            Translator.get('ball_$key'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();

    return Card(
      key: matchingBallsKey,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.catching_pokemon, color: Colors.redAccent),
        title: Text(
          Translator.get('matching_balls') != 'matching_balls'
              ? Translator.get('matching_balls')
              : 'Matching Balls',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: DatabaseService.instance.getMatchingBalls(entry.uniqueId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final matchingBalls = snapshot.data;
              final List<String> normalBalls = List<String>.from(
                matchingBalls?['normal'] ?? [],
              );
              final List<String> shinyBalls = List<String>.from(
                matchingBalls?['shiny'] ?? [],
              );

              return Column(
                children: [
                  _buildBallCard(
                    context,
                    Icons.catching_pokemon,
                    Translator.get('matching_ball_normal') !=
                            'matching_ball_normal'
                        ? Translator.get('matching_ball_normal')
                        : 'Matching Ball (Normal)',
                    normalBalls,
                    Theme.of(context).colorScheme.primary,
                    provider.ballUrls,
                  ),
                  _buildBallCard(
                    context,
                    Icons.star,
                    Translator.get('matching_ball_shiny') !=
                            'matching_ball_shiny'
                        ? Translator.get('matching_ball_shiny')
                        : 'Matching Ball (Shiny)',
                    shinyBalls,
                    Colors.amber,
                    provider.ballUrls,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class IgnorePokemonButton extends StatelessWidget {
  final GlobalKey ignoreBtnKey;
  final VoidCallback onIgnore;

  const IgnorePokemonButton({
    super.key,
    required this.ignoreBtnKey,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ignoreBtnKey,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.delete_outline),
        label: Text(
          Translator.get('ignore_pokemon') != 'ignore_pokemon'
              ? Translator.get('ignore_pokemon')
              : 'Aus Dex entfernen',
        ),
        onPressed: onIgnore,
      ),
    );
  }
}
