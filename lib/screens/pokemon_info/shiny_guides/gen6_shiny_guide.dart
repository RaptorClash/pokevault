import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../services/database_service.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../l10n/app_translations.dart';

class Gen6ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;

  const Gen6ShinyGuide({
    super.key,
    required this.pokemon,
    required this.shinyCategories,
    required this.title,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final id = pokemon.id;
    bool isAbsolutelyLocked = shinyCategories.contains('gen6_locks');

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final encounters = snapshot.data;
        bool hasEncounterThisGen = encounters != null && encounters.containsKey('gen_6');
        bool hasXYGrassEncounter = false;
        bool hasORASGrassEncounter = false;
        bool hasFriendSafari = false;
        bool hasFishingEncounter = false;
        bool hasHordeEncounter = false;
        bool isStaticOrGift = false;

        bool isBreedableThisGen = (id <= 721) &&
            (ShinyLogicHelper.isBreedable(pokemon) || ShinyLogicHelper.isBaby(id)) &&
            !shinyCategories.contains('legendary_mythical');

        bool isHuntable = hasEncounterThisGen || isBreedableThisGen;

        if (!isHuntable && !isAbsolutelyLocked) return const SizedBox.shrink();

        if (hasEncounterThisGen) {
          final gen6 = encounters['gen_6']!;
          for (var version in gen6.keys) {
            for (var loc in gen6[version]!) {
              final locLower = loc.toLowerCase();
              bool isXY = version == 'x' || version == 'y';
              bool isORAS = version == 'omega-ruby' || version == 'alpha-sapphire';
              
              if (locLower.contains('grass') || locLower.contains('walk') || locLower.contains('gras')) {
                if (isXY) hasXYGrassEncounter = true;
                if (isORAS) hasORASGrassEncounter = true;
              }
              if (locLower.contains('friend') || locLower.contains('safari') || locLower.contains('kontakt')) {
                hasFriendSafari = true;
              }
              if (locLower.contains('fish') || locLower.contains('angel') || locLower.contains('surf') || locLower.contains('water') || locLower.contains('rod')) {
                hasFishingEncounter = true;
              }
              if (locLower.contains('horde') || locLower.contains('massen')) {
                hasHordeEncounter = true;
              }
              if (locLower.contains('stationary') || locLower.contains('gift') || locLower.contains('fossil') || locLower.contains('only one')) {
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

        if (isAbsolutelyLocked) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no', fallback: 'Shiny Huntable: Nein'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 8));
          content.add(buildInfoBox(Icons.lock, 'shiny_gen6_locked_title', 'shiny_gen6_locked_desc', Colors.red));
        } else {
          content.add(
            Text(
              Translator.get('shiny_gen6_huntable_yes', fallback: 'Shiny Huntable: Ja (Neue Basis-Chance: 1:4096)'),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 16));

          if (id == 143) {
            content.add(buildInfoBox(Icons.warning_amber_rounded, 'shiny_gen6_snorlax_warning_title', 'shiny_gen6_snorlax_warning_desc', Colors.orange));
          }
          if (isBreedableThisGen) {
            content.add(buildInfoBox(Icons.egg_alt, 'shiny_gen6_masuda_title', 'shiny_gen6_masuda_desc', Colors.purple));
          }
          if (hasFriendSafari && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.people_alt, 'shiny_gen6_friendsafari_title', 'shiny_gen6_friendsafari_desc', Colors.pink));
          }
          if (hasORASGrassEncounter && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.screen_search_desktop, 'shiny_gen6_dexnav_title', 'shiny_gen6_dexnav_desc', Colors.orange));
            content.add(buildLinkBtn(Icons.forum, 'shiny_gen6_dexnav_link_reddit', 'https://www.reddit.com/r/ShinyPokemon/comments/1i8rjzm/talk_oras_dexnav_survival_guide_how_to_chain_what/'));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen6_dexnav_link_yt', 'https://www.youtube.com/watch?v=acqLZJjAGGk'));
            content.add(buildLinkBtn(Icons.forum, 'shiny_gen6_dexnav_link_pokecomm', 'https://www.pokecommunity.com/threads/dexnav-shiny-chaining-and-perfect-iv-guide-updated-v-1.340264/'));
            content.add(const SizedBox(height: 8));
          }
          if (hasXYGrassEncounter && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.radar, 'shiny_gen6_radar_title', 'shiny_gen6_radar_desc', Colors.blue));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen6_radar_link_yt', 'https://www.youtube.com/watch?v=oP4hDHPA8Cg'));
            content.add(buildLinkBtn(Icons.insert_chart_outlined, 'shiny_gen6_radar_link_slides', 'https://docs.google.com/presentation/d/1lg-wfWoBa7etT4Yd4jFOP4Z979Qr9-q_w0t6liFeftc/pub?slide=id.g2094469701_4_440'));
            content.add(const SizedBox(height: 8));
          }
          if (hasFishingEncounter && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.water, 'shiny_gen6_fishing_title', 'shiny_gen6_fishing_desc', Colors.lightBlue));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen6_fishing_link_yt', 'https://www.youtube.com/watch?v=JgvW8fha7k4'));
            content.add(buildLinkBtn(Icons.forum, 'shiny_gen6_fishing_link_reddit', 'https://www.reddit.com/r/pokemon/comments/1p1iqx/vps_guide_to_chain_fishing_shinies/'));
            content.add(const SizedBox(height: 8));
          }
          if (hasHordeEncounter && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.group, 'shiny_gen6_horde_title', 'shiny_gen6_horde_desc', Colors.teal));
            content.add(const SizedBox(height: 8));
          }
          if (isStaticOrGift && id != 143) {
            content.add(buildInfoBox(Icons.restart_alt, 'shiny_gen6_sr_title', 'shiny_gen6_sr_desc', Colors.deepPurple));
          }
          if (hasORASGrassEncounter || hasXYGrassEncounter || hasFishingEncounter) {
            content.add(buildLinkBtn(Icons.language, 'shiny_gen6_chaining_link_wiki', 'https://www.pokewiki.de/Shiny-Chaining'));
          }
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