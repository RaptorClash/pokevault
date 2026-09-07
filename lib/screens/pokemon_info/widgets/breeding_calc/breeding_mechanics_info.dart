import 'package:flutter/material.dart';
import '../../../../l10n/app_translations.dart';

class BreedingMechanicsInfo extends StatelessWidget {
  const BreedingMechanicsInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.menu_book,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          Translator.get(
            'shiny_breed_mechanics_title',
            fallback: 'Wichtige Zucht-Mechaniken (Gen 2)',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get('shiny_breed_female_note'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get(
                          'shiny_breed_mechanics_dv_passing',
                          fallback:
                              'Warum dieser Geschlechter-Wechsel? In Gen 2 wird der Shiny-Status immer an das *andere* Geschlecht vererbt.',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get(
                          'shiny_breed_dv_conflict_text',
                          fallback:
                              'Achtung: Inzest-Sperre bei gleichen DVs beachten!',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
