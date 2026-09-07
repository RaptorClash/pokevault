import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../l10n/app_translations.dart';

class Gen9ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;

  const Gen9ShinyGuide({
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
        
        final data = snapshot.data!;
        bool isSVAvailable = data['isSV'] == true;
        
        bool isBreedableThisGen = isSVAvailable &&
            (ShinyLogicHelper.isBreedable(pokemon) || ShinyLogicHelper.isBaby(id)) &&
            !shinyCategories.contains('legendary_mythical');
            
        bool isHuntable = isSVAvailable || isBreedableThisGen;
        bool isLocked = shinyCategories.contains('sv_locks');
        
        if (!isHuntable && !isLocked) return const SizedBox.shrink();

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
          content.add(buildInfoBox(Icons.lock, 'shiny_gen9_locked_title', 'shiny_gen9_locked_desc', Colors.red));
        } else {
          content.add(
            Text(
              Translator.get('shiny_gen7_huntable_yes', fallback: 'Shiny Huntable: Ja (Basis-Chance 1:4096)'),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 16));

          if (isSVAvailable) {
            content.add(buildInfoBox(Icons.map, 'shiny_gen9_sv_title', 'shiny_gen9_sv_desc', Colors.blue));
            content.add(buildInfoBox(Icons.fastfood, 'shiny_gen9_sandwich_title', 'shiny_gen9_sandwich_desc', Colors.orange));
            content.add(buildInfoBox(Icons.groups, 'shiny_gen9_outbreak_title', 'shiny_gen9_outbreak_desc', Colors.teal));
            
            if (!shinyCategories.contains('legendary_mythical')) {
              content.add(buildInfoBox(Icons.filter_center_focus, 'shiny_gen9_isolation_title', 'shiny_gen9_isolation_desc', Colors.cyan));
            }
          }
          if (isBreedableThisGen) {
            content.add(buildInfoBox(Icons.egg_alt, 'shiny_gen8_masuda_title', 'shiny_gen8_masuda_desc', Colors.purple));
          }

          content.add(buildLinkBtn(Icons.language, 'shiny_gen9_link_bisa', 'https://www.bisafans.de/spiele/editionen/karmesin-purpur/shiny-pokemon.php'));
          content.add(buildLinkBtn(Icons.language, 'shiny_gen9_link_sandwich', 'https://www.polygon.com/pokemon-scarlet-violet-guide/23472506/sandwich-recipes-ingredients-list-meal-powers'));
          content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen9_link_outbreak', 'https://www.youtube.com/watch?v=kYJzXvG22iY'));
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