import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/pokemon.dart';
import '../../../providers/dex_provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../utils/notification_helper.dart';
import '../shiny_guide_widget.dart';
import 'catch_rate_calculator.dart';
import 'breeding_info_widget.dart';
import 'pokemon_info_widgets.dart';
import 'encounters_widget.dart';
import './tera_type_widget.dart';
import './ribbons_widget.dart';
import './marks_widget.dart';
import './matching_balls_widget.dart';
import 'language_widget.dart';

class PokemonInfoPage extends StatelessWidget {
  final DexDisplayEntry entry;
  final String dexId;
  final bool? manualShinyToggle;
  final VoidCallback onShinyToggled;
  final VoidCallback onIgnore;

  final GlobalKey shinyToggleKey;
  final GlobalKey alphaToggleKey;
  final GlobalKey basicInfoKey;
  final GlobalKey caughtStatusKey;
  final GlobalKey shinyStatusKey;
  final GlobalKey breedingKey;
  final GlobalKey catchCalcKey;
  final GlobalKey matchingBallsKey;
  final GlobalKey languageKey;
  final GlobalKey teraKey;
  final GlobalKey ribbonsKey;
  final GlobalKey marksKey;
  final GlobalKey encountersKey;
  final GlobalKey shinyGuideKey;
  final GlobalKey ignoreBtnKey;

  const PokemonInfoPage({
    super.key,
    required this.entry,
    required this.dexId,
    required this.manualShinyToggle,
    required this.onShinyToggled,
    required this.onIgnore,
    required this.shinyToggleKey,
    required this.alphaToggleKey,
    required this.basicInfoKey,
    required this.caughtStatusKey,
    required this.shinyStatusKey,
    required this.breedingKey,
    required this.catchCalcKey,
    required this.matchingBallsKey,
    required this.teraKey,
    required this.ribbonsKey,
    required this.marksKey,
    required this.encountersKey,
    required this.shinyGuideKey,
    required this.ignoreBtnKey,
    required this.languageKey,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final provider = context.watch<DexProvider>();
      final liveDex = provider.userDexes.firstWhere((d) => d.id == dexId);
      final isCaught = liveDex.caughtIds.contains(entry.uniqueId);
      final isShiny = liveDex.shinyIds.contains(entry.uniqueId);
      final wantShiny = manualShinyToggle ?? liveDex.isShinyDex;
      final isAlpha = liveDex.alphaIds.contains(entry.uniqueId);

      String formName = 'normal';
      if (entry.uniqueId.contains('_')) {
        formName = entry.uniqueId.substring(entry.uniqueId.indexOf('_') + 1);
        if (formName == 'm' || formName == 'f') formName = 'normal';
      }

      PokemonForm? currentForm;
      try {
        currentForm = entry.pokemon.forms.firstWhere((f) => f.name == formName);
      } catch (_) {
        if (entry.pokemon.forms.isNotEmpty) {
          currentForm = entry.pokemon.forms.first;
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PokemonHeaderWidget(
              entry: entry,
              wantShiny: wantShiny,
              currentForm: currentForm,
              shinyToggleKey: shinyToggleKey,
              onShinyToggled: onShinyToggled,
            ),
            const SizedBox(height: 24),
            PokemonBasicInfoWidget(
              entry: entry,
              provider: provider,
              basicInfoKey: basicInfoKey,
              currentForm: currentForm,
            ),
            const SizedBox(height: 32),
            PokemonStatusTogglesWidget(
              dexId: dexId,
              entry: entry,
              isCaught: isCaught,
              isShiny: isShiny,
              isAlpha: isAlpha,
              provider: provider,
              caughtStatusKey: caughtStatusKey,
              shinyStatusKey: shinyStatusKey,
              alphaToggleKey: alphaToggleKey,
            ),

            const SizedBox(height: 32),

            Container(
              key: breedingKey,
              child: BreedingInfoWidget(pokemon: entry.pokemon),
            ),
            Card(
              key: catchCalcKey,
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.calculate_outlined,
                  color: Colors.purple,
                ),
                title: Text(
                  Translator.get(
                    'catch_calculator_title',
                    fallback: 'Ultimativer Fangratenrechner',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [CatchRateCalculator(pokemon: entry.pokemon)],
              ),
            ),
            MatchingBallsWidget(
              entry: entry,
              matchingBallsKey: matchingBallsKey,
            ),
            Container(
              key: languageKey,
              child: LanguageWidget(entry: entry, dexId: dexId),
            ),
            Container(
              key: teraKey,
              child: TeraTypeWidget(entry: entry, dexId: dexId),
            ),
            Container(
              key: ribbonsKey,
              child: RibbonsWidget(
                entry: entry,
                dexId: dexId,
                ribbonsKey: ribbonsKey,
              ),
            ),
            Container(
              key: marksKey,
              child: MarksWidget(
                entry: entry,
                dexId: dexId,
                marksKey: marksKey,
              ),
            ),
            EncountersWidget(
              pokemonId: entry.pokemon.id,
              encountersKey: encountersKey,
            ),
            Container(
              key: shinyGuideKey,
              child: ShinyGuideWidget(entry: entry, dexId: dexId),
            ),

            const SizedBox(height: 16),
            IgnorePokemonButton(ignoreBtnKey: ignoreBtnKey, onIgnore: onIgnore),
            const SizedBox(height: 32),
          ],
        ),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_page_load', fallback: 'Fehler beim Laden der Seite:')} $e",
        );
      });
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        ),
      );
    }
  }
}
