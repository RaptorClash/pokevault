import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../models/dex_view_models.dart';
import '../../../../models/pokemon.dart';

const Map<String, Color> _searchTileTypeColors = {
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
  'dark': Color(0xFF705746),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

/// Modular tile widget for single Pokémon card in [PokemonSearchSelectionScreen].
class PokemonSearchTile extends StatelessWidget {
  final Pokemon pokemon;
  final DexDisplayEntry entry;
  final bool isShiny;
  final List<String>? types;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PokemonSearchTile({
    super.key,
    required this.pokemon,
    required this.entry,
    this.isShiny = false,
    this.types,
    this.imageUrl,
    required this.onTap,
    this.onLongPress,
  });

  static String getDisplayImageUrl(DexDisplayEntry entry, bool wantShiny) {
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
      if (url.contains('/shiny/female/')) {
        return url.replaceFirst('/shiny/female/', '/female/');
      } else if (url.contains('/shiny/')) {
        return url.replaceFirst('/shiny/', '/');
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEn = LocaleSettings.currentLocale == AppLocale.en;
    final name = isEn ? pokemon.nameEn : pokemon.nameDe;
    final effectiveTypes = types ??
        (pokemon.forms.isNotEmpty && pokemon.forms.first.types.isNotEmpty
            ? pokemon.forms.first.types
            : <String>[]);
    final idStr = '#${pokemon.id.toString().padLeft(3, '0')}';
    final effectiveImageUrl = imageUrl ?? getDisplayImageUrl(entry, isShiny);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Number, Shiny star & Suffix
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        idStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (isShiny) ...[
                        const SizedBox(width: 2),
                        const Icon(Icons.star, size: 11, color: Colors.amber),
                      ],
                    ],
                  ),
                  if (entry.displaySuffix.isNotEmpty)
                    Flexible(
                      child: Text(
                        entry.displaySuffix.trim(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),

              // Image
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CachedNetworkImage(
                    imageUrl: effectiveImageUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: 150,
                    placeholder: (context, url) => Center(
                      child: Icon(
                        Icons.catching_pokemon,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                        size: 28,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.catching_pokemon,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Type Badges
              if (effectiveTypes.isNotEmpty)
                Wrap(
                  spacing: 3,
                  runSpacing: 2,
                  alignment: WrapAlignment.center,
                  children: effectiveTypes.map((type) {
                    final color = _searchTileTypeColors[type.toLowerCase()] ?? Colors.grey;
                    final typeName = (t['type_$type'] ?? type);
                    final label = (typeName != 'type_$type' && typeName.isNotEmpty)
                        ? typeName
                        : type;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
