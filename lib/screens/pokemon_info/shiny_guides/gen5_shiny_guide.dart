import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../services/database_service.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../l10n/app_translations.dart';

class Gen5ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;

  const Gen5ShinyGuide({
    super.key,
    required this.pokemon,
    required this.shinyCategories,
    required this.title,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final id = pokemon.id;
    List<int> gen5ShinyLocks = [494, 643, 644, 647, 648, 649];
    bool isShinyLocked = gen5ShinyLocks.contains(id);

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final encounters = snapshot.data;
        bool hasEncounterThisGen = encounters != null && encounters.containsKey('gen_5');
        bool isStaticOrGift = false;
        bool hasGrassEncounter = false;
        bool isBreedableThisGen = (id <= 649) &&
            (ShinyLogicHelper.isBreedable(pokemon) || ShinyLogicHelper.isBaby(id)) &&
            !shinyCategories.contains('legendary_mythical');
        bool isHuntable = hasEncounterThisGen || isBreedableThisGen;

        if (!isHuntable && !isShinyLocked) return const SizedBox.shrink();

        if (hasEncounterThisGen) {
          final gen5 = encounters['gen_5']!;
          for (var version in gen5.keys) {
            for (var loc in gen5[version]!) {
              final locLower = loc.toLowerCase();
              if (locLower.contains('stationary') ||
                  locLower.contains('gift') ||
                  locLower.contains('fossil') ||
                  locLower.contains('only one')) {
                isStaticOrGift = true;
              }
              if (locLower.contains('grass') ||
                  locLower.contains('walk') ||
                  locLower.contains('gras')) {
                hasGrassEncounter = true;
              }
            }
          }
        }
        if (shinyCategories.contains('legendary_mythical') && hasEncounterThisGen) {
          isStaticOrGift = true;
        }

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

        if (isShinyLocked) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no', fallback: 'Shiny Huntable: Nein'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 8));
          content.add(buildInfoBox(Icons.lock, 'shiny_gen5_locked_title', 'shiny_gen5_locked_desc', Colors.red));
        } else {
          content.add(
            Text(
              Translator.get('shiny_gen5_huntable_yes', fallback: 'Shiny Huntable: Ja (Basis-Chance 1:8192)'),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 16));
          content.add(buildInfoBox(Icons.star, 'shiny_gen5_charm_title', 'shiny_gen5_charm_desc', Colors.amber));

          if (isBreedableThisGen) {
            content.add(buildInfoBox(Icons.egg_alt, 'shiny_gen5_masuda_title', 'shiny_gen5_masuda_desc', Colors.purple));
          }
          if (isStaticOrGift) {
            content.add(buildInfoBox(Icons.restart_alt, 'shiny_gen5_sr_title', 'shiny_gen5_sr_desc', Colors.teal));
          }
          if (hasGrassEncounter && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.grass, 'shiny_gen5_darkgrass_title', 'shiny_gen5_darkgrass_desc', Colors.green));
          }

          content.add(buildInfoBox(Icons.memory, 'shiny_gen5_rng_title', 'shiny_gen5_rng_desc', Colors.blue));
          content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen5_rng_link_blisy', 'https://www.youtube.com/watch?v=Yy1YNz0oBls&list=PL4o9bTT3px_jOygj-x_vlYkNLtRsRXAPn'));
          content.add(buildLinkBtn(Icons.article, 'shiny_gen5_rng_link_retail', 'https://retailrng.com/bw/beginner/introduction/'));
          content.add(buildLinkBtn(Icons.article, 'shiny_gen5_rng_link_smogon', 'https://www.smogon.com/ingame/rng/bw_rng_intro'));
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