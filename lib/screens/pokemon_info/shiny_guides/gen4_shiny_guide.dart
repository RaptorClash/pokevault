import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../services/database_service.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../l10n/app_translations.dart';

class Gen4ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;

  const Gen4ShinyGuide({
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
        bool hasEncounterThisGen = encounters != null && encounters.containsKey('gen_4');
        bool hasRadarEncounter = false;
        bool isStaticOrGift = false;
        bool isLegendaryOrMythical = shinyCategories.contains('legendary_mythical');
        bool isBreedableThisGen = (id <= 493) &&
            (ShinyLogicHelper.isBreedable(pokemon) || ShinyLogicHelper.isBaby(id)) &&
            !isLegendaryOrMythical;
        bool isHuntable = hasEncounterThisGen || isBreedableThisGen;

        if (!isHuntable) return const SizedBox.shrink();

        if (hasEncounterThisGen) {
          final gen4 = encounters['gen_4']!;
          for (var version in gen4.keys) {
            for (var loc in gen4[version]!) {
              final locLower = loc.toLowerCase();
              if (version == 'diamond' || version == 'pearl' || version == 'platinum') {
                if (locLower.contains('walk') ||
                    locLower.contains('grass') ||
                    locLower.contains('radar') ||
                    locLower.contains('gras')) {
                  hasRadarEncounter = true;
                }
              }
              if (locLower.contains('stationary') ||
                  locLower.contains('gift') ||
                  locLower.contains('fossil') ||
                  locLower.contains('only one')) {
                isStaticOrGift = true;
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
                        Translator.get(titleKey) != titleKey
                            ? Translator.get(titleKey)
                            : titleKey,
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Translator.get(descKey) != descKey
                      ? Translator.get(descKey)
                      : descKey,
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

        content.add(
          Text(
            Translator.get(
              'shiny_gen4_huntable_yes',
              fallback: 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
            ),
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        );
        content.add(const SizedBox(height: 16));

        if (isStaticOrGift) {
          content.add(buildInfoBox(Icons.restart_alt, 'shiny_gen4_sr_title', 'shiny_gen4_sr_desc', Colors.teal));
        }
        if (isBreedableThisGen) {
          content.add(buildInfoBox(Icons.egg_alt, 'shiny_gen4_masuda_title', 'shiny_gen4_masuda_desc', Colors.purple));
          content.add(buildLinkBtn(Icons.language, 'shiny_gen4_masuda_link', 'https://bulbapedia.bulbagarden.net/wiki/Masuda_method'));
        }
        if (hasRadarEncounter && !shinyCategories.contains('legendary_mythical')) {
          content.add(buildInfoBox(Icons.radar, 'shiny_gen4_radar_title', 'shiny_gen4_radar_desc', Colors.blue));
          content.add(buildLinkBtn(Icons.forum, 'shiny_gen4_radar_link_en_reddit', 'https://www.reddit.com/r/ShinyPokemon/comments/ezinx0/gen_4_poke_radar_guide_leave_suggestions/'));
          content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen4_radar_link_en_yt', 'https://www.youtube.com/watch?v=nXVGWZOEHU8'));
          content.add(buildLinkBtn(Icons.language, 'shiny_gen4_radar_link_de_bisa', 'https://www.bisafans.de/spiele/editionen/diamant-perl/shiny-pokemon-fangen.php'));
          content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen4_radar_link_de_yt', 'https://www.youtube.com/watch?v=mXV1G0z7gZM'));
        }

        bool hasGenderVariation = pokemon.genderRate > 0 && pokemon.genderRate < 8;
        if (hasGenderVariation && !shinyCategories.contains('legendary_mythical')) {
          content.add(buildInfoBox(Icons.favorite, 'shiny_gen4_ccg_title', 'shiny_gen4_ccg_desc', Colors.pink));
          content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen4_ccg_link_dppt', 'https://www.youtube.com/watch?v=os0AOt1VMi0&t=475s'));
          content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen4_ccg_link_hgss', 'https://www.youtube.com/watch?v=aHfVnqkmmUw'));
        }

        if (id == 152 || id == 155 || id == 158) {
          content.add(buildInfoBox(Icons.star, 'shiny_gen4_hgss_starter_title', 'shiny_gen4_hgss_starter_desc', Colors.amber));
          content.add(buildLinkBtn(Icons.language, 'shiny_gen4_hgss_starter_link', 'https://pokemondb.net/pokebase/412511/how-do-you-shiny-hunt-the-starters-in-heartgold'));
        }

        List<int> gen4Roamers = [144, 145, 146, 243, 244, 380, 381, 481, 488];
        if (gen4Roamers.contains(id) && hasEncounterThisGen) {
          content.add(buildInfoBox(Icons.map, 'shiny_gen4_roamer_title', 'shiny_gen4_roamer_desc', Colors.deepOrange));
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