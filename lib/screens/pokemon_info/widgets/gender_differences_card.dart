import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/dex_view_models.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/database_service.dart';
import '../../../widgets/universal_poke_image.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/dex_logic_helper.dart';

/// Card displayed within the Pokémon Info Screen for species exhibiting
/// visual gender differences between male and female forms.
class GenderDifferencesCard extends StatefulWidget {
  final DexDisplayEntry entry;
  final bool wantShiny;
  final void Function(String targetGender)? onNavigateToGender;

  const GenderDifferencesCard({
    super.key,
    required this.entry,
    this.wantShiny = false,
    this.onNavigateToGender,
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
    final hasFemaleForm = widget.entry.pokemon.forms.any((f) => f.name == 'female');
    if (hasFemaleForm) {
      final shinyPath = widget.wantShiny ? 'shiny/' : '';
      return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$shinyPath${widget.entry.pokemon.id}-female.png';
    }
    final shinyFemalePath = widget.wantShiny ? 'shiny/female/' : 'female/';
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$shinyFemalePath${widget.entry.pokemon.id}.png';
  }

  bool get _isCurrentFemale {
    final baseId = DexLogicHelper.getBaseId(widget.entry.uniqueId).toLowerCase();
    if (baseId.endsWith('_f') || baseId.endsWith('_female')) return true;
    final formName = widget.entry.resolvedForm?.name.toLowerCase();
    if (formName == 'female') return true;
    return false;
  }

  bool get _isCurrentMale => !_isCurrentFemale;

  void _handleGenderTap(String targetGender) {
    final isTargetFemale = targetGender.toLowerCase() == 'female' || targetGender.toLowerCase() == 'f';
    if ((isTargetFemale && _isCurrentFemale) || (!isTargetFemale && _isCurrentMale)) {
      return;
    }
    HapticFeedback.lightImpact();
    if (widget.onNavigateToGender != null) {
      widget.onNavigateToGender!(targetGender);
    }
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
                          child: Tooltip(
                            triggerMode: TooltipTriggerMode.manual,
                            message: _isCurrentMale
                                ? (isDe ? 'Aktuell ausgewählt' : 'Currently selected')
                                : (isDe ? 'Zu Männlich wechseln' : 'Switch to Male'),
                            child: Material(
                              color: _isCurrentMale
                                  ? Colors.blue.withValues(alpha: 0.16)
                                  : Colors.blue.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                key: const Key('gender_diff_male_action'),
                                onTap: () => _handleGenderTap('male'),
                                onSecondaryTap: () => _handleGenderTap('male'),
                                onLongPress: () => _handleGenderTap('male'),
                                borderRadius: BorderRadius.circular(12),
                                mouseCursor: _isCurrentMale
                                    ? SystemMouseCursors.basic
                                    : SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isCurrentMale
                                          ? Colors.blueAccent
                                          : Colors.blueAccent.withValues(alpha: 0.3),
                                      width: _isCurrentMale ? 2.0 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _isCurrentMale
                                              ? Colors.blueAccent.withValues(alpha: 0.3)
                                              : Colors.blueAccent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_isCurrentMale) ...[
                                              const Icon(
                                                Icons.check_circle,
                                                size: 13,
                                                color: Colors.blueAccent,
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Text(
                                              trans.gender_male,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ],
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
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _isCurrentMale
                                              ? (isDe ? 'Aktiv' : 'Active')
                                              : (isDe ? 'Wechseln' : 'Switch'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: _isCurrentMale ? FontWeight.bold : FontWeight.normal,
                                            color: _isCurrentMale
                                                ? Colors.blueAccent
                                                : Theme.of(context).hintColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Female side
                        Expanded(
                          child: Tooltip(
                            triggerMode: TooltipTriggerMode.manual,
                            message: _isCurrentFemale
                                ? (isDe ? 'Aktuell ausgewählt' : 'Currently selected')
                                : (isDe ? 'Zu Weiblich wechseln' : 'Switch to Female'),
                            child: Material(
                              color: _isCurrentFemale
                                  ? Colors.pink.withValues(alpha: 0.16)
                                  : Colors.pink.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                key: const Key('gender_diff_female_action'),
                                onTap: () => _handleGenderTap('female'),
                                onSecondaryTap: () => _handleGenderTap('female'),
                                onLongPress: () => _handleGenderTap('female'),
                                borderRadius: BorderRadius.circular(12),
                                mouseCursor: _isCurrentFemale
                                    ? SystemMouseCursors.basic
                                    : SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isCurrentFemale
                                          ? Colors.pinkAccent
                                          : Colors.pinkAccent.withValues(alpha: 0.3),
                                      width: _isCurrentFemale ? 2.0 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _isCurrentFemale
                                                ? Colors.pinkAccent.withValues(alpha: 0.3)
                                                : Colors.pinkAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_isCurrentFemale) ...[
                                                const Icon(
                                                  Icons.check_circle,
                                                  size: 13,
                                                  color: Colors.pinkAccent,
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Text(
                                                trans.gender_female,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.pinkAccent,
                                                ),
                                              ),
                                            ],
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
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _isCurrentFemale
                                              ? (isDe ? 'Aktiv' : 'Active')
                                              : (isDe ? 'Wechseln' : 'Switch'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: _isCurrentFemale ? FontWeight.bold : FontWeight.normal,
                                            color: _isCurrentFemale
                                                ? Colors.pinkAccent
                                                : Theme.of(context).hintColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
