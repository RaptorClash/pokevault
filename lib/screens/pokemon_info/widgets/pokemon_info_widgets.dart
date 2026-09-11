import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/pokemon.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../utils/notification_helper.dart';
import '../../../widgets/universal_poke_image.dart';
import '../../../utils/dex_logic_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants/app_vectors.dart';

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
              child: UniversalPokeImage(
                imageUrl: currentImageUrl,
                fallbackUrl: fallbackUrl,
                errorIconSize: 60,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
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
                    ? (Translator.get('normal_form', fallback: 'Normale Form'))
                    : (Translator.get('shiny_form', fallback: 'Shiny Form')),
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
    final settingsProvider = context.watch<SettingsProvider>();

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
              entry.pokemon.getName(settingsProvider.currentLanguage),
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
                '${Translator.get('form', fallback: 'Form')}: ${entry.displaySuffix.replaceAll('(', '').replaceAll(')', '').trim()}',
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
  final bool isAlpha;
  final DexProvider provider;
  final GlobalKey caughtStatusKey;
  final GlobalKey shinyStatusKey;
  final GlobalKey alphaToggleKey;

  const PokemonStatusTogglesWidget({
    super.key,
    required this.dexId,
    required this.entry,
    required this.isCaught,
    required this.isShiny,
    required this.isAlpha,
    required this.provider,
    required this.caughtStatusKey,
    required this.shinyStatusKey,
    required this.alphaToggleKey,
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
                Translator.get('caught_status', fallback: 'Gefangen Status'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                Translator.get(
                  'mark_as_caught',
                  fallback: 'Als gefangen markieren',
                ),
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
          FutureBuilder<bool>(
            future: DexLogicHelper.isAlphaEligible(entry.pokemon.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == false) {
                return const SizedBox.shrink();
              }

              return Card(
                key: alphaToggleKey,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: SwitchListTile(
                  title: Text(
                    Translator.get('alpha_status', fallback: 'Alpha Status'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    Translator.get(
                      'alpha_status_sub',
                      fallback: 'Als Alpha markieren',
                    ),
                  ),
                  secondary: SvgPicture.string(
                    AppVectors.alphaSymbol,
                    width: 24,
                    height: 24,
                  ),
                  value: isAlpha,
                  activeThumbColor: Colors.red,
                  onChanged: (val) {
                    provider.toggleAlpha(dexId, entry.uniqueId);
                  },
                ),
              );
            },
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
          Translator.get('ignore_pokemon', fallback: 'Aus Dex entfernen'),
        ),
        onPressed: onIgnore,
      ),
    );
  }
}
