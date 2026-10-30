import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../models/dex_view_models.dart';
import '../../../../services/database_service.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../l10n/app_translations.dart';

class Gen7ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;
  final Widget? extraAction;
  final DexDisplayEntry? entry;

  const Gen7ShinyGuide({
    super.key,
    required this.pokemon,
    required this.shinyCategories,
    required this.title,
    required this.onLaunchUrl,
    this.extraAction,
    this.entry,
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
        bool hasAlolaEncounter = false, isStaticOrGift = false, hasWildSpawn = false;

        if (encounters != null && encounters.containsKey('gen_7')) {
          final gen7 = encounters['gen_7']!;
          for (var version in gen7.keys) {
            if (version == 'sun' || version == 'moon' || version == 'ultra-sun' || version == 'ultra-moon') {
              hasAlolaEncounter = true;
              for (var loc in gen7[version]!) {
                final locLower = loc.toLowerCase();
                if (locLower.contains('stationary') || locLower.contains('gift') || locLower.contains('fossil') || locLower.contains('only one')) {
                  isStaticOrGift = true;
                }
                if (locLower.contains('grass') || locLower.contains('walk') || locLower.contains('gras') || locLower.contains('cave') || locLower.contains('surf')) {
                  hasWildSpawn = true;
                }
              }
            }
          }
        }

        final isPartnerCap = entry != null && ShinyLogicHelper.isPartnerCapPikachu(entry!);
        final isOtherCap = entry != null && !isPartnerCap && ShinyLogicHelper.isAnyCapPikachu(entry!);

        bool canBeInWarpRide = shinyCategories.contains('warp_ride');
        bool isBreedableThisGen = (id <= 807) &&
            (ShinyLogicHelper.isBreedable(pokemon) || ShinyLogicHelper.isBaby(id)) &&
            !shinyCategories.contains('legendary_mythical') &&
            !isPartnerCap &&
            !isOtherCap;
        bool isHuntable = hasAlolaEncounter || canBeInWarpRide || isBreedableThisGen || isPartnerCap;

        if (!isHuntable && !shinyCategories.contains('gen7_locks') && !isOtherCap) {
          return const SizedBox.shrink();
        }

        if ((shinyCategories.contains('legendary_mythical') && hasAlolaEncounter) || canBeInWarpRide) {
          isStaticOrGift = true;
        }

        if (isPartnerCap) {
          hasWildSpawn = false;
          canBeInWarpRide = false;
          isBreedableThisGen = false;
          isStaticOrGift = false;
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

        if (isOtherCap || shinyCategories.contains('gen7_locks')) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no', fallback: 'Shiny Huntable: Nein'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 8));
          if (isOtherCap) {
            content.add(buildInfoBox(
              Icons.lock,
              Translator.currentLanguage == 'de' ? 'Shiny-Lock' : 'Shiny Lock',
              Translator.currentLanguage == 'de'
                  ? 'Pikachu mit Kappe kann in dieser Generation nicht schillernd erhalten werden (außer Partner-Kappe in USUM).'
                  : 'Cap Pikachu cannot be obtained shiny in this generation (except Partner Cap in USUM).',
              Colors.red,
            ));
          } else {
            content.add(buildInfoBox(Icons.lock, 'shiny_gen7_locked_title', 'shiny_gen7_locked_desc', Colors.red));
          }
        } else {
          content.add(
            Text(
              Translator.get('shiny_gen7_huntable_yes', fallback: 'Shiny Huntable: Ja (Basis-Chance 1:4096)'),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 16));

          if (isPartnerCap) {
            content.add(buildInfoBox(
              Icons.stars,
              Translator.currentLanguage == 'de'
                  ? 'Pikachu-Tal (QR-Code Event) - Soft Reset'
                  : 'Pikachu Valley (QR Code Event) - Soft Reset',
              Translator.currentLanguage == 'de'
                  ? 'In Pokémon Ultra Sonne & Ultra Mond kann das Partner-Kappe Pikachu am Pikachu-Tal per QR-Code Event erhalten und per Soft Reset schillernd gejagt werden (Basis-Chance 1:4096).'
                  : 'In Pokémon Ultra Sun & Ultra Moon, Partner Cap Pikachu can be obtained at Pikachu Valley via QR Code event and soft reset for shiny (base odds 1:4096).',
              Colors.teal,
            ));
            content.add(buildInfoBox(
              Icons.visibility,
              Translator.currentLanguage == 'de'
                  ? 'Wichtiger optischer Hinweis'
                  : 'Important Visual Note',
              ShinyLogicHelper.getPartnerCapShinyNote(lang: Translator.currentLanguage),
              Colors.amber,
            ));
          }

          if (shinyCategories.contains('ultra_beast')) {
            content.add(buildInfoBox(Icons.warning_amber_rounded, 'shiny_gen7_ub_locked_title', 'shiny_gen7_ub_locked_desc', Colors.orange));
          }
          if (isBreedableThisGen) {
            content.add(buildInfoBox(Icons.egg_alt, 'shiny_gen6_masuda_title', 'shiny_gen6_masuda_desc', Colors.purple));
          }
          if (hasWildSpawn && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.group_add, 'shiny_gen7_sos_title', 'shiny_gen7_sos_desc', Colors.blue));
            content.add(buildLinkBtn(Icons.forum, 'shiny_gen7_sos_link_reddit', 'https://www.reddit.com/r/pokemontrades/comments/5ig3pj/sos_chaining_how_to_do_it_and_how_to_do_it/'));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen7_sos_link_yt_en', 'https://www.youtube.com/watch?v=JyQW4buHeGY'));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen7_sos_link_yt_de', 'https://www.youtube.com/watch?v=SJdagmvWASM'));
            content.add(const SizedBox(height: 8));
          }
          if (canBeInWarpRide) {
            content.add(buildInfoBox(Icons.rocket_launch, 'shiny_gen7_warp_title', 'shiny_gen7_warp_desc', Colors.indigo));
            content.add(buildLinkBtn(Icons.forum, 'shiny_gen7_warp_link_reddit', 'https://www.reddit.com/r/ShinyPokemon/comments/7myj5n/7_warp_ride_shiny_odds_grid/'));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen7_warp_link_yt_en', 'https://www.youtube.com/watch?v=63AHQizp8zg'));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen7_warp_link_yt_de', 'https://www.youtube.com/watch?v=USjxUroSmKA'));
            content.add(buildLinkBtn(Icons.language, 'shiny_gen7_warp_link_bisa', 'https://www.bisafans.de/spiele/editionen/ultra-sonne-ultra-mond/warp-loch-shinys.php'));
            content.add(const SizedBox(height: 8));
          }
          if (isStaticOrGift) {
            content.add(buildInfoBox(Icons.restart_alt, 'shiny_gen6_sr_title', 'shiny_gen6_sr_desc', Colors.teal));
          }
          if (hasWildSpawn && !shinyCategories.contains('legendary_mythical')) {
            content.add(buildInfoBox(Icons.holiday_village, 'shiny_gen7_pelago_title', 'shiny_gen7_pelago_desc', Colors.green));
          }
        }

        if (extraAction != null && !isOtherCap) {
          content.add(const SizedBox(height: 12));
          content.add(extraAction!);
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