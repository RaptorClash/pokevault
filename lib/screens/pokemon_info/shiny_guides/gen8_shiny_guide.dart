import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../utils/shiny_logic_helper.dart';
import '../../../../i18n/strings.g.dart';

class Gen8ShinyGuide extends StatelessWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final String title;
  final Future<void> Function(String) onLaunchUrl;
  final Widget? extraAction;

  const Gen8ShinyGuide({
    super.key,
    required this.pokemon,
    required this.shinyCategories,
    required this.title,
    required this.onLaunchUrl,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    final id = pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: ShinyLogicHelper.fetchGen8Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!;
        bool isSwShAvailable = data['isSwSh'] == true;
        bool isBDSPAvailable = data['isBDSP'] == true;

        bool isBreedableThisGen = (isSwShAvailable || isBDSPAvailable) &&
            (ShinyLogicHelper.isBreedable(pokemon) || ShinyLogicHelper.isBaby(id));
        bool isHuntable = isSwShAvailable || isBDSPAvailable || isBreedableThisGen;
        bool isLocked = shinyCategories.contains('gen8_locks');

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
                        (t[titleKey] ?? titleKey) != titleKey ? (t[titleKey] ?? titleKey) : titleKey,
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (t[descKey] ?? descKey) != descKey ? (t[descKey] ?? descKey) : descKey,
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
                  (t[titleKey] ?? titleKey) != titleKey ? (t[titleKey] ?? titleKey) : titleKey,
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
              t.shiny_huntable_no,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 8));
          content.add(buildInfoBox(Icons.lock, 'shiny_gen8_locked_title', 'shiny_gen8_locked_desc', Colors.red));
        } else {
          content.add(
            Text(
              t.shiny_gen7_huntable_yes,
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          );
          content.add(const SizedBox(height: 16));

          if (isSwShAvailable || isBreedableThisGen) {
            content.add(buildInfoBox(Icons.sports_esports, 'shiny_gen8_swsh_title', 'shiny_gen8_swsh_desc', Colors.blue));
          }
          if (isBDSPAvailable) {
            content.add(buildInfoBox(Icons.diamond, 'shiny_gen8_bdsp_title', 'shiny_gen8_bdsp_desc', Colors.cyan));
          }
          if (isBreedableThisGen) {
            content.add(buildInfoBox(Icons.egg_alt, 'shiny_gen8_masuda_title', 'shiny_gen8_masuda_desc', Colors.purple));
            content.add(buildLinkBtn(Icons.language, 'shiny_gen8_masuda_link', 'https://bulbapedia.bulbagarden.net/wiki/Masuda_method'));
            content.add(const SizedBox(height: 8));
          }
          if (isBDSPAvailable && isBreedableThisGen) {
            content.add(buildInfoBox(Icons.radar, 'shiny_gen8_radar_title', 'shiny_gen8_radar_desc', Colors.indigo));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen8_radar_link_yt_de', 'https://www.youtube.com/watch?v=bCmGq6eYL90'));
            content.add(buildLinkBtn(Icons.forum, 'shiny_gen8_radar_link_reddit', 'https://www.reddit.com/r/PokeLeaks/comments/qsr6ze/bdsp_poke_radar_guide/?show=original'));
            content.add(buildLinkBtn(Icons.play_circle_filled, 'shiny_gen8_radar_link_yt_en', 'https://www.youtube.com/watch?v=wnaS_WhyNMs'));
            content.add(const SizedBox(height: 8));
          }
        }

        if (extraAction != null) {
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