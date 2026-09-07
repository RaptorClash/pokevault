import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../services/database_service.dart';
import '../../../../l10n/app_translations.dart';

class Gen7_5ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;

  const Gen7_5ShinyGuide({
    super.key,
    required this.pokemon,
    required this.shinyCategories,
    required this.title,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final id = pokemon.id;

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final encounters = snapshot.data;
        bool hasLetsGoEncounter = false;

        if (encounters != null && encounters.containsKey('gen_7')) {
          final gen7 = encounters['gen_7']!;
          for (var version in gen7.keys) {
            if (version == 'lets-go-pikachu' || version == 'lets-go-eevee') {
              hasLetsGoEncounter = true;
            }
          }
        }

        bool canTradeAlolan = shinyCategories.contains('alolan_base');
        bool isLocked =
            shinyCategories.contains('gen75_locks') ||
            id == 151;

        bool isLegendary = [144, 145, 146, 150].contains(id);
        bool isHuntable =
            hasLetsGoEncounter ||
            canTradeAlolan ||
            id == 25 ||
            id == 133 ||
            isLegendary;

        if (!isHuntable && !isLocked) {
          return const SizedBox.shrink();
        }

        List<Widget> content = [];

        Widget buildInfoBox(
          IconData icon,
          String titleKey,
          String descKey,
          Color color,
        ) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get(titleKey) != titleKey
                            ? Translator.get(titleKey)
                            : titleKey,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Translator.get(descKey) != descKey
                      ? Translator.get(descKey)
                      : descKey,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildLinkBtn(IconData icon, String titleKey, String url) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(icon),
                label: Text(
                  Translator.get(titleKey) != titleKey
                      ? Translator.get(titleKey)
                      : titleKey,
                  textAlign: TextAlign.center,
                ),
                onPressed: () => onLaunchUrl(url),
              ),
            ),
          );
        }

        if (isLocked) {
          content.add(
            Text(
              Translator.get(
                'shiny_huntable_no',
                fallback: 'Shiny Huntable: Nein',
              ),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 8));
          content.add(
            buildInfoBox(
              Icons.lock,
              'shiny_gen75_locked_title',
              'shiny_gen75_locked_desc',
              Colors.red,
            ),
          );
        } else {
          content.add(
            Text(
              Translator.get(
                'shiny_gen7_huntable_yes',
                fallback: 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
              ),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 16));

          if (id == 25 || id == 133) {
            content.add(
              buildInfoBox(
                Icons.warning_amber_rounded,
                'shiny_gen75_locked_title',
                'shiny_gen75_locked_desc',
                Colors.orange,
              ),
            );
          }

          if ((hasLetsGoEncounter || id == 25 || id == 133) && !isLegendary) {
            content.add(
              buildInfoBox(
                Icons.link,
                'shiny_gen75_combo_title',
                'shiny_gen75_combo_desc',
                Colors.blue,
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.forum,
                'shiny_gen75_combo_link_reddit',
                'https://www.reddit.com/r/PokemonLetsGo/comments/1fendma/pokemon_lets_go_guide_for_shiny_hunting_tracking/',
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.play_circle_filled,
                'shiny_gen75_combo_link_yt_de1',
                'https://www.youtube.com/watch?v=8UJ_91-wcQM',
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.play_circle_filled,
                'shiny_gen75_combo_link_yt_de2',
                'https://www.youtube.com/watch?v=mzAWo2-vXsM',
              ),
            );
            content.add(const SizedBox(height: 8));
          }

          if (canTradeAlolan) {
            content.add(
              buildInfoBox(
                Icons.swap_horiz,
                'shiny_gen75_alola_title',
                'shiny_gen75_alola_desc',
                Colors.teal,
              ),
            );
          }

          if (isLegendary) {
            content.add(
              buildInfoBox(
                Icons.restart_alt,
                'shiny_gen6_sr_title',
                'shiny_gen6_sr_desc',
                Colors.deepPurple,
              ),
            );
          }
        }

        return ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content,
              ),
            ),
          ],
        );
      },
    );
  }
}
