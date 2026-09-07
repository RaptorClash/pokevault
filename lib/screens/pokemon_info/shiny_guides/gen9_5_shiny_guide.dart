import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../l10n/app_translations.dart';

class Gen9_5ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;

  const Gen9_5ShinyGuide({
    super.key,
    required this.pokemon,
    required this.shinyCategories,
    required this.title,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final id = pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: ShinyLogicHelper.fetchGen9Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        bool isPLZAAvailable = snapshot.data!['isPLZA'] == true;
        bool isLocked = shinyCategories.contains('plza_locks');
        
        if (!isPLZAAvailable) return const SizedBox.shrink();

        List<Widget> content = [];

        Widget buildInfoBox(IconData icon, String titleKey, String descKey, Color color) {
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
                        Translator.get(titleKey) != titleKey ? Translator.get(titleKey) : titleKey,
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Translator.get(descKey) != descKey ? Translator.get(descKey) : descKey,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
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
                  Translator.get(titleKey) != titleKey ? Translator.get(titleKey) : titleKey,
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
              Translator.get('shiny_huntable_no', fallback: 'Shiny Huntable: Nein'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 8));
          content.add(buildInfoBox(Icons.lock, 'shiny_gen95_locked_title', 'shiny_gen95_locked_desc', Colors.red));
        } else {
          content.add(
            Text(
              Translator.get('shiny_gen7_huntable_yes', fallback: 'Shiny Huntable: Ja (Basis-Chance 1:4096)'),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 16));
          content.add(buildInfoBox(Icons.campaign, 'shiny_gen95_plza_title', 'shiny_gen95_plza_desc', Colors.amber));
          content.add(buildInfoBox(Icons.refresh, 'shiny_gen95_donut_title', 'shiny_gen95_donut_desc', Colors.deepOrange));
          content.add(buildLinkBtn(Icons.forum, 'shiny_gen95_link_reddit', 'https://www.reddit.com/r/PokemonZA/comments/1of201i/best_shiny_hunting_locationsmethods/'));
          content.add(buildLinkBtn(Icons.language, 'shiny_gen95_link_ign', 'https://www.ign.com/wikis/pokemon-legends-z-a/How_to_Shiny_Hunt_(Shiny_Pokemon_Guide)'));
          content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen95_link_yt_de', 'https://www.youtube.com/watch?v=6Z6nbxlK3J8'));
        }

        return ExpansionTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
            ),
          ],
        );
      },
    );
  }
}