import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../l10n/app_translations.dart';
import '../breeding_calculator_widget.dart';

class Gen2ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final String dexId;
  final Future<void> Function(String) onLaunchUrl;

  const Gen2ShinyGuide({
    super.key,
    required this.pokemon,
    required this.dexId,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [];

    content.add(
      Text(
        Translator.get(
          'shiny_gen2_huntable_yes',
          fallback: 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
        ),
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    content.add(const SizedBox(height: 16));

    if (pokemon.id >= 243 && pokemon.id <= 245) {
      content.add(
        Text(
          Translator.get('shiny_roamer_gen2_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pokemon.id == 245
                      ? Translator.get('shiny_roamer_gen2_suicune_note')
                      : Translator.get('shiny_roamer_gen2_beasts_note'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      content.add(const SizedBox(height: 16));
    }

    if (pokemon.id >= 252 && pokemon.id <= 257) {
      content.add(
        Text(
          Translator.get('shiny_mail_writer_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.memory,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Translator.get('shiny_mail_writer_note'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      content.add(const SizedBox(height: 12));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.language),
            label: Text(Translator.get('tutorial_mail_writer_main')),
            onPressed: () => onLaunchUrl(
              'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.code),
            label: Text(Translator.get('tutorial_mail_writer_scripts')),
            onPressed: () => onLaunchUrl(
              'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes#Gen3Giver_scripts',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 24));
    }

    if (pokemon.id <= 251 && ShinyLogicHelper.isBaby(pokemon.id)) {
      content.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.egg,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Translator.get('shiny_odd_egg_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                Translator.get('shiny_odd_egg_desc'),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      );
      content.add(const SizedBox(height: 16));
    }

    if (pokemon.id <= 251 &&
        (ShinyLogicHelper.isBreedable(pokemon) ||
            ShinyLogicHelper.isBaby(pokemon.id))) {
      content.add(
        Text(
          Translator.get('shiny_ditto_guide'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.language),
            label: const Text('Text Tutorial (DE) - Bisafans'),
            onPressed: () => onLaunchUrl(
              'https://www.bisafans.de/spiele/editionen/gold-silber/shiny-ditto.php',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.language),
            label: const Text('Text Tutorial (EN) - Reddit'),
            onPressed: () => onLaunchUrl(
              'https://www.reddit.com/r/ShinyPokemon/comments/14s1ush/discussion_found_a_way_to_get_a_shiny_ditto_in/',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 24));
      content.add(
        BreedingCalculatorWidget(initialTargetId: pokemon.id, dexId: dexId),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }
}
