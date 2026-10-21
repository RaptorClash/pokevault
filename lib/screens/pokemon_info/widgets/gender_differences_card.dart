import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/dex_view_models.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/database_service.dart';
import '../../../widgets/universal_poke_image.dart';
import '../../../i18n/strings.g.dart';

/// Card displayed within the Pokémon Info Screen for species exhibiting
/// visual gender differences between male and female forms.
class GenderDifferencesCard extends StatefulWidget {
  final DexDisplayEntry entry;
  final bool wantShiny;

  const GenderDifferencesCard({
    super.key,
    required this.entry,
    this.wantShiny = false,
  });

  @override
  State<GenderDifferencesCard> createState() => _GenderDifferencesCardState();
}

class _GenderDifferencesCardState extends State<GenderDifferencesCard> {
  Future<Map<String, String>?>? _diffFuture;

  @override
  void initState() {
    super.initState();
    _loadDifferences();
  }

  @override
  void didUpdateWidget(covariant GenderDifferencesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.pokemon.id != widget.entry.pokemon.id) {
      _loadDifferences();
    }
  }

  void _loadDifferences() {
    if (widget.entry.pokemon.hasGenderDifferences) {
      _diffFuture = DatabaseService.instance.getGenderDifference(widget.entry.pokemon.id);
    } else {
      _diffFuture = null;
    }
  }

  String _resolveMaleImageUrl() {
    final shinyPath = widget.wantShiny ? 'shiny/' : '';
    final hasMaleForm = widget.entry.pokemon.forms.any((f) => f.name == 'male');
    if (hasMaleForm) {
      return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyPath${widget.entry.pokemon.id}-male.png';
    }
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyPath${widget.entry.pokemon.id}.png';
  }

  String _resolveFemaleImageUrl() {
    final shinyFemalePath = widget.wantShiny ? 'shiny/female/' : 'female/';
    final hasFemaleForm = widget.entry.pokemon.forms.any((f) => f.name == 'female');
    if (hasFemaleForm) {
      final shinyPath = widget.wantShiny ? 'shiny/' : '';
      return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyPath${widget.entry.pokemon.id}-female.png';
    }
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyFemalePath${widget.entry.pokemon.id}.png';
  }

  String _resolveMaleFallbackUrl() {
    final shinyPath = widget.wantShiny ? 'shiny/' : '';
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$shinyPath${widget.entry.pokemon.id}.png';
  }

  String _resolveFemaleFallbackUrl() {
    final shinyFemalePath = widget.wantShiny ? 'shiny/female/' : 'female/';
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$shinyFemalePath${widget.entry.pokemon.id}.png';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.entry.pokemon.hasGenderDifferences || _diffFuture == null) {
      return const SizedBox.shrink();
    }

    final currentLang = context.watch<SettingsProvider>().currentLanguage;
    final isDe = currentLang.toLowerCase().startsWith('de');
    final trans = isDe ? AppLocale.de.translations : AppLocale.en.translations;

    return FutureBuilder<Map<String, String>?>(
      future: _diffFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final diffData = snapshot.data!;
        final textDe = diffData['de'] ?? '';
        final textEn = diffData['en'] ?? '';
        final descText = isDe
            ? (textDe.isNotEmpty ? textDe : textEn)
            : (textEn.isNotEmpty ? textEn : textDe);

        if (descText.isEmpty) {
          return const SizedBox.shrink();
        }

        final maleImg = _resolveMaleImageUrl();
        final femaleImg = _resolveFemaleImageUrl();
        final maleFallback = _resolveMaleFallbackUrl();
        final femaleFallback = _resolveFemaleFallbackUrl();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wc,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              trans.gender_differences_title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              trans.gender_differences_subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Side-by-side Sprites: Male vs Female
                    Row(
                      children: [
                        // Male side
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blueAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    trans.gender_male,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                UniversalPokeImage(
                                  imageUrl: maleImg,
                                  fallbackUrl: maleFallback,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.contain,
                                  errorIconSize: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Female side
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.pinkAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.pinkAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    trans.gender_female,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.pinkAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                UniversalPokeImage(
                                  imageUrl: femaleImg,
                                  fallbackUrl: femaleFallback,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.contain,
                                  errorIconSize: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              descText,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
