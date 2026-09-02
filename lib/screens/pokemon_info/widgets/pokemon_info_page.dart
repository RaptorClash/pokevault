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

class PokemonInfoPage extends StatelessWidget {
  final DexDisplayEntry entry;
  final String dexId;
  final bool? manualShinyToggle;
  final VoidCallback onShinyToggled;
  final VoidCallback onIgnore;

  final GlobalKey shinyToggleKey;
  final GlobalKey basicInfoKey;
  final GlobalKey caughtStatusKey;
  final GlobalKey shinyStatusKey;
  final GlobalKey breedingKey;
  final GlobalKey catchCalcKey;
  final GlobalKey matchingBallsKey;
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
    required this.basicInfoKey,
    required this.caughtStatusKey,
    required this.shinyStatusKey,
    required this.breedingKey,
    required this.catchCalcKey,
    required this.matchingBallsKey,
    required this.encountersKey,
    required this.shinyGuideKey,
    required this.ignoreBtnKey,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final provider = context.watch<DexProvider>();
      final liveDex = provider.userDexes.firstWhere((d) => d.id == dexId);
      final isCaught = liveDex.caughtIds.contains(entry.uniqueId);
      final isShiny = liveDex.shinyIds.contains(entry.uniqueId);
      final wantShiny = manualShinyToggle ?? liveDex.isShinyDex;

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
              provider: provider,
              caughtStatusKey: caughtStatusKey,
              shinyStatusKey: shinyStatusKey,
            ),
            const SizedBox(height: 16),
            Container(
              key: breedingKey,
              child: BreedingInfoWidget(pokemon: entry.pokemon),
            ),
            Card(
              key: catchCalcKey,
              margin: const EdgeInsets.symmetric(vertical: 8),
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
                  Translator.get('catch_calculator_title') !=
                          'catch_calculator_title'
                      ? Translator.get('catch_calculator_title')
                      : 'Ultimativer Fangratenrechner',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [CatchRateCalculator(pokemon: entry.pokemon)],
              ),
            ),
            const SizedBox(height: 16),
            MatchingBallsWidget(
              entry: entry,
              matchingBallsKey: matchingBallsKey,
            ),
            EncountersWidget(
              pokemonId: entry.pokemon.id,
              encountersKey: encountersKey,
            ),
            const SizedBox(height: 16),
            Container(
              key: shinyGuideKey,
              child: ShinyGuideWidget(entry: entry, dexId: dexId),
            ),
            const SizedBox(height: 32),
            IgnorePokemonButton(ignoreBtnKey: ignoreBtnKey, onIgnore: onIgnore),
            const SizedBox(height: 32),
          ],
        ),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_page_load') != 'error_page_load' ? Translator.get('error_page_load') : 'Fehler beim Laden der Seite:'} $e",
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
