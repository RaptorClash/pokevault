import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/dex_view_models.dart';
import '../../utils/shiny_logic_helper.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';
import '../../services/database_service.dart';
import './shiny_guides/gen1_shiny_guide.dart';
import './shiny_guides/gen2_shiny_guide.dart';
import './shiny_guides/gen3_shiny_guide.dart';
import './shiny_guides/gen4_shiny_guide.dart';
import './shiny_guides/gen5_shiny_guide.dart';
import './shiny_guides/gen6_shiny_guide.dart';
import './shiny_guides/gen7_shiny_guide.dart';
import './shiny_guides/gen7_5_shiny_guide.dart';
import './shiny_guides/gen8_shiny_guide.dart';
import './shiny_guides/gen8_5_shiny_guide.dart';
import './shiny_guides/gen9_shiny_guide.dart';
import './shiny_guides/gen9_5_shiny_guide.dart';

class ShinyGuideWidget extends StatefulWidget {
  final DexDisplayEntry entry;
  final String dexId;

  const ShinyGuideWidget({super.key, required this.entry, required this.dexId});

  @override
  State<ShinyGuideWidget> createState() => _ShinyGuideWidgetState();
}

class _ShinyGuideWidgetState extends State<ShinyGuideWidget> {
  late int _selectedLevel;
  List<String> _shinyCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final id = widget.entry.pokemon.id;
      final level = await DatabaseService.instance.getDefaultLevel(id);
      final categories = await DatabaseService.instance.getShinyCategories(id);

      if (mounted) {
        setState(() {
          _selectedLevel = level;
          _shinyCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fehler beim Laden der Shiny-Daten: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationHelper.showError('Fehler beim Laden der Shiny-Daten: $e');
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          NotificationHelper.showError(
            '${Translator.get('error_launch_url')} $urlString',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          '${Translator.get('error_launch_url')} $e',
        );
      }
    }
  }

  Future<Map<String, dynamic>> _fetchGen9Data(int id) async {
    final encounters = await DatabaseService.instance.getEncounters(id);
    final db = await DatabaseService.instance.appDatabase;

    final svCheck = await db.query(
      'dex_orders',
      where: 'pokemon_id = ? AND dex_name IN (?, ?, ?)',
      whereArgs: [
        id,
        'paldea_regional',
        'kitakami_regional',
        'blueberry_regional',
      ],
      limit: 1,
    );

    final plzaCheck = await db.query(
      'dex_orders',
      where: 'pokemon_id = ? AND dex_name IN (?, ?)',
      whereArgs: [id, 'lumiose_regional', 'lumiose_dimensions_regional'],
      limit: 1,
    );

    return {
      'encounters': encounters,
      'isSV': svCheck.isNotEmpty,
      'isPLZA': plzaCheck.isNotEmpty,
    };
  }

  bool _shouldShowGen(double gen) {
    if (gen == 2 &&
        widget.entry.pokemon.id >= 252 &&
        widget.entry.pokemon.id <= 257) {
      return true;
    }
    if (gen == 1) return widget.entry.pokemon.id <= 151;
    if (gen == 2) return widget.entry.pokemon.id <= 251;
    if (gen == 3) return widget.entry.pokemon.id <= 386;
    if (gen == 4) return widget.entry.pokemon.id <= 493;
    if (gen == 5) return widget.entry.pokemon.id <= 649;
    if (gen == 6) return widget.entry.pokemon.id <= 721;
    if (gen == 7) return widget.entry.pokemon.id <= 807;
    if (gen == 7.5) {
      return widget.entry.pokemon.id <= 151 ||
          widget.entry.pokemon.id == 808 ||
          widget.entry.pokemon.id == 809;
    }
    if (gen == 8) return widget.entry.pokemon.id <= 905;
    if (gen == 8.5) return widget.entry.pokemon.id <= 905;
    if (gen == 9) return widget.entry.pokemon.id <= 1025;
    if (gen == 9.5) return widget.entry.pokemon.id <= 1025;
    return false;
  }

  Widget _buildGen4Specific(BuildContext context, String title) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox.shrink();

        final encounters = snapshot.data;
        bool hasEncounterThisGen =
            encounters != null && encounters.containsKey('gen_4');
        bool hasRadarEncounter = false;
        bool isStaticOrGift = false;

        bool isLegendaryOrMythical = _shinyCategories.contains(
          'legendary_mythical',
        );

        bool isBreedableThisGen =
            (id <= 493) &&
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !isLegendaryOrMythical;

        bool isHuntable = hasEncounterThisGen || isBreedableThisGen;

        if (!isHuntable) return const SizedBox.shrink();

        if (hasEncounterThisGen) {
          final gen4 = encounters['gen_4']!;
          for (var version in gen4.keys) {
            for (var loc in gen4[version]!) {
              final locLower = loc.toLowerCase();
              if (version == 'diamond' ||
                  version == 'pearl' ||
                  version == 'platinum') {
                if (locLower.contains('walk') ||
                    locLower.contains('grass') ||
                    locLower.contains('radar') ||
                    locLower.contains('gras'))
                  hasRadarEncounter = true;
              }
              if (locLower.contains('stationary') ||
                  locLower.contains('gift') ||
                  locLower.contains('fossil') ||
                  locLower.contains('only one'))
                isStaticOrGift = true;
            }
          }
        }

        if (_shinyCategories.contains('legendary_mythical') &&
            hasEncounterThisGen)
          isStaticOrGift = true;

        List<Widget> content = [];
        Widget buildInfoBox(
          IconData icon,
          String titleKey,
          String descKey,
          Color color,
        ) {
          /* ...wie bisher... */
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
          /* ...wie bisher... */
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
                onPressed: () => _launchURL(url),
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
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        content.add(const SizedBox(height: 16));

        if (isStaticOrGift) {
          content.add(
            buildInfoBox(
              Icons.restart_alt,
              'shiny_gen4_sr_title',
              'shiny_gen4_sr_desc',
              Colors.teal,
            ),
          );
        }
        if (isBreedableThisGen) {
          content.add(
            buildInfoBox(
              Icons.egg_alt,
              'shiny_gen4_masuda_title',
              'shiny_gen4_masuda_desc',
              Colors.purple,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen4_masuda_link',
              'https://bulbapedia.bulbagarden.net/wiki/Masuda_method',
            ),
          );
        }
        if (hasRadarEncounter &&
            !_shinyCategories.contains('legendary_mythical')) {
          content.add(
            buildInfoBox(
              Icons.radar,
              'shiny_gen4_radar_title',
              'shiny_gen4_radar_desc',
              Colors.blue,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.forum,
              'shiny_gen4_radar_link_en_reddit',
              'https://www.reddit.com/r/ShinyPokemon/comments/ezinx0/gen_4_poke_radar_guide_leave_suggestions/',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen4_radar_link_en_yt',
              'https://www.youtube.com/watch?v=nXVGWZOEHU8',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen4_radar_link_de_bisa',
              'https://www.bisafans.de/spiele/editionen/diamant-perl/shiny-pokemon-fangen.php',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen4_radar_link_de_yt',
              'https://www.youtube.com/watch?v=mXV1G0z7gZM',
            ),
          );
        }
        bool hasGenderVariation =
            widget.entry.pokemon.genderRate > 0 &&
            widget.entry.pokemon.genderRate < 8;
        if (hasGenderVariation &&
            !_shinyCategories.contains('legendary_mythical')) {
          content.add(
            buildInfoBox(
              Icons.favorite,
              'shiny_gen4_ccg_title',
              'shiny_gen4_ccg_desc',
              Colors.pink,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen4_ccg_link_dppt',
              'https://www.youtube.com/watch?v=os0AOt1VMi0&t=475s',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen4_ccg_link_hgss',
              'https://www.youtube.com/watch?v=aHfVnqkmmUw',
            ),
          );
        }
        if (id == 152 || id == 155 || id == 158) {
          content.add(
            buildInfoBox(
              Icons.star,
              'shiny_gen4_hgss_starter_title',
              'shiny_gen4_hgss_starter_desc',
              Colors.amber,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen4_hgss_starter_link',
              'https://pokemondb.net/pokebase/412511/how-do-you-shiny-hunt-the-starters-in-heartgold',
            ),
          );
        }
        List<int> gen4Roamers = [144, 145, 146, 243, 244, 380, 381, 481, 488];
        if (gen4Roamers.contains(id) && hasEncounterThisGen) {
          content.add(
            buildInfoBox(
              Icons.map,
              'shiny_gen4_roamer_title',
              'shiny_gen4_roamer_desc',
              Colors.deepOrange,
            ),
          );
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

  Widget _buildGen5Specific(BuildContext context, String title) {
    final id = widget.entry.pokemon.id;

    List<int> gen5ShinyLocks = [494, 643, 644, 647, 648, 649];
    bool isShinyLocked = gen5ShinyLocks.contains(id);

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox.shrink();

        final encounters = snapshot.data;
        bool hasEncounterThisGen =
            encounters != null && encounters.containsKey('gen_5');
        bool isStaticOrGift = false;
        bool hasGrassEncounter = false;

        bool isBreedableThisGen =
            (id <= 649) &&
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !_shinyCategories.contains('legendary_mythical');

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

        if (_shinyCategories.contains('legendary_mythical') &&
            hasEncounterThisGen) {
          isStaticOrGift = true;
        }

        List<Widget> content = [];
        Widget buildInfoBox(
          IconData icon,
          String titleKey,
          String descKey,
          Color color,
        ) {
          /* wie bisher */
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
          /* wie bisher */
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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (isShinyLocked) {
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
              'shiny_gen5_locked_title',
              'shiny_gen5_locked_desc',
              Colors.red,
            ),
          );
        } else {
          content.add(
            Text(
              Translator.get(
                'shiny_gen5_huntable_yes',
                fallback: 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
              ),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 16));
          content.add(
            buildInfoBox(
              Icons.star,
              'shiny_gen5_charm_title',
              'shiny_gen5_charm_desc',
              Colors.amber,
            ),
          );
          if (isBreedableThisGen) {
            content.add(
              buildInfoBox(
                Icons.egg_alt,
                'shiny_gen5_masuda_title',
                'shiny_gen5_masuda_desc',
                Colors.purple,
              ),
            );
          }

          if (isStaticOrGift) {
            content.add(
              buildInfoBox(
                Icons.restart_alt,
                'shiny_gen5_sr_title',
                'shiny_gen5_sr_desc',
                Colors.teal,
              ),
            );
          }
          if (hasGrassEncounter &&
              !_shinyCategories.contains('legendary_mythical')) {
            content.add(
              buildInfoBox(
                Icons.grass,
                'shiny_gen5_darkgrass_title',
                'shiny_gen5_darkgrass_desc',
                Colors.green,
              ),
            );
          }

          content.add(
            buildInfoBox(
              Icons.memory,
              'shiny_gen5_rng_title',
              'shiny_gen5_rng_desc',
              Colors.blue,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen5_rng_link_blisy',
              'https://www.youtube.com/watch?v=Yy1YNz0oBls&list=PL4o9bTT3px_jOygj-x_vlYkNLtRsRXAPn',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.article,
              'shiny_gen5_rng_link_retail',
              'https://retailrng.com/bw/beginner/introduction/',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.article,
              'shiny_gen5_rng_link_smogon',
              'https://www.smogon.com/ingame/rng/bw_rng_intro',
            ),
          );
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

  Widget _buildGen6Specific(BuildContext context, String title) {
    final id = widget.entry.pokemon.id;

    bool isAbsolutelyLocked = _shinyCategories.contains('gen6_locks');

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final encounters = snapshot.data;
        bool hasEncounterThisGen =
            encounters != null && encounters.containsKey('gen_6');
        bool hasXYGrassEncounter = false,
            hasORASGrassEncounter = false,
            hasFriendSafari = false,
            hasFishingEncounter = false,
            hasHordeEncounter = false,
            isStaticOrGift = false;

        bool isBreedableThisGen =
            (id <= 721) &&
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !_shinyCategories.contains('legendary_mythical');
        bool isHuntable = hasEncounterThisGen || isBreedableThisGen;

        if (!isHuntable && !isAbsolutelyLocked) return const SizedBox.shrink();

        if (hasEncounterThisGen) {
          final gen6 = encounters['gen_6']!;
          for (var version in gen6.keys) {
            for (var loc in gen6[version]!) {
              final locLower = loc.toLowerCase();
              bool isXY = version == 'x' || version == 'y';
              bool isORAS =
                  version == 'omega-ruby' || version == 'alpha-sapphire';

              if (locLower.contains('grass') ||
                  locLower.contains('walk') ||
                  locLower.contains('gras')) {
                if (isXY) hasXYGrassEncounter = true;
                if (isORAS) hasORASGrassEncounter = true;
              }
              if (locLower.contains('friend') ||
                  locLower.contains('safari') ||
                  locLower.contains('kontakt')) {
                hasFriendSafari = true;
              }
              if (locLower.contains('fish') ||
                  locLower.contains('angel') ||
                  locLower.contains('surf') ||
                  locLower.contains('water') ||
                  locLower.contains('rod')) {
                hasFishingEncounter = true;
              }
              if (locLower.contains('horde') || locLower.contains('massen')) {
                hasHordeEncounter = true;
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

        if (_shinyCategories.contains('legendary_mythical') &&
            hasEncounterThisGen) {
          isStaticOrGift = true;
        }

        List<Widget> content = [];
        Widget buildInfoBox(
          IconData icon,
          String titleKey,
          String descKey,
          Color color,
        ) {
          /* wie bisher */
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
          /* wie bisher */
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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (isAbsolutelyLocked) {
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
              'shiny_gen6_locked_title',
              'shiny_gen6_locked_desc',
              Colors.red,
            ),
          );
        } else {
          content.add(
            Text(
              Translator.get(
                'shiny_gen6_huntable_yes',
                fallback: 'Shiny Huntable: Ja (Neue Basis-Chance: 1:4096)',
              ),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 16));
          if (id == 143) {
            content.add(
              buildInfoBox(
                Icons.warning_amber_rounded,
                'shiny_gen6_snorlax_warning_title',
                'shiny_gen6_snorlax_warning_desc',
                Colors.orange,
              ),
            );
          }

          if (isBreedableThisGen) {
            content.add(
              buildInfoBox(
                Icons.egg_alt,
                'shiny_gen6_masuda_title',
                'shiny_gen6_masuda_desc',
                Colors.purple,
              ),
            );
          }

          if (hasFriendSafari &&
              !_shinyCategories.contains('legendary_mythical')) {
            content.add(
              buildInfoBox(
                Icons.people_alt,
                'shiny_gen6_friendsafari_title',
                'shiny_gen6_friendsafari_desc',
                Colors.pink,
              ),
            );
          }

          if (hasORASGrassEncounter &&
              !_shinyCategories.contains('legendary_mythical')) {
            content.add(
              buildInfoBox(
                Icons.screen_search_desktop,
                'shiny_gen6_dexnav_title',
                'shiny_gen6_dexnav_desc',
                Colors.orange,
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.forum,
                'shiny_gen6_dexnav_link_reddit',
                'https://www.reddit.com/r/ShinyPokemon/comments/1i8rjzm/talk_oras_dexnav_survival_guide_how_to_chain_what/',
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.play_circle_filled,
                'shiny_gen6_dexnav_link_yt',
                'https://www.youtube.com/watch?v=acqLZJjAGGk',
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.forum,
                'shiny_gen6_dexnav_link_pokecomm',
                'https://www.pokecommunity.com/threads/dexnav-shiny-chaining-and-perfect-iv-guide-updated-v-1.340264/',
              ),
            );
            content.add(const SizedBox(height: 8));
          }
          if (hasXYGrassEncounter &&
              !_shinyCategories.contains('legendary_mythical')) {
            content.add(
              buildInfoBox(
                Icons.radar,
                'shiny_gen6_radar_title',
                'shiny_gen6_radar_desc',
                Colors.blue,
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.play_circle_filled,
                'shiny_gen6_radar_link_yt',
                'https://www.youtube.com/watch?v=oP4hDHPA8Cg',
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.insert_chart_outlined,
                'shiny_gen6_radar_link_slides',
                'https://docs.google.com/presentation/d/1lg-wfWoBa7etT4Yd4jFOP4Z979Qr9-q_w0t6liFeftc/pub?slide=id.g2094469701_4_440',
              ),
            );
            content.add(const SizedBox(height: 8));
          }
          if (hasFishingEncounter &&
              !_shinyCategories.contains('legendary_mythical')) {
            content.add(
              buildInfoBox(
                Icons.water,
                'shiny_gen6_fishing_title',
                'shiny_gen6_fishing_desc',
                Colors.lightBlue,
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.play_circle_filled,
                'shiny_gen6_fishing_link_yt',
                'https://www.youtube.com/watch?v=JgvW8fha7k4',
              ),
            );
            content.add(
              buildLinkBtn(
                Icons.forum,
                'shiny_gen6_fishing_link_reddit',
                'https://www.reddit.com/r/pokemon/comments/1p1iqx/vps_guide_to_chain_fishing_shinies/',
              ),
            );
            content.add(const SizedBox(height: 8));
          }
          if (hasHordeEncounter &&
              !_shinyCategories.contains('legendary_mythical')) {
            content.add(
              buildInfoBox(
                Icons.group,
                'shiny_gen6_horde_title',
                'shiny_gen6_horde_desc',
                Colors.teal,
              ),
            );
            content.add(const SizedBox(height: 8));
          }
          if (isStaticOrGift && id != 143) {
            content.add(
              buildInfoBox(
                Icons.restart_alt,
                'shiny_gen6_sr_title',
                'shiny_gen6_sr_desc',
                Colors.deepPurple,
              ),
            );
          }
          if (hasORASGrassEncounter ||
              hasXYGrassEncounter ||
              hasFishingEncounter) {
            content.add(
              buildLinkBtn(
                Icons.language,
                'shiny_gen6_chaining_link_wiki',
                'https://www.pokewiki.de/Shiny-Chaining',
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

  Widget _buildGen9Specific(BuildContext context, String title) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGen9Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox.shrink();

        final data = snapshot.data!;
        bool isSVAvailable = data['isSV'] == true;

        bool isBreedableThisGen =
            isSVAvailable &&
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !_shinyCategories.contains('legendary_mythical');
        bool isHuntable = isSVAvailable || isBreedableThisGen;
        bool isLocked = _shinyCategories.contains('sv_locks');
        if (!isHuntable && !isLocked) return const SizedBox.shrink();

        List<Widget> content = [];
        Widget buildInfoBox(
          IconData icon,
          String titleKey,
          String descKey,
          Color color,
        ) {
          /* wie bisher */
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
          /* wie bisher */
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
                onPressed: () => _launchURL(url),
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
              'shiny_gen9_locked_title',
              'shiny_gen9_locked_desc',
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
          if (isSVAvailable) {
            content.add(
              buildInfoBox(
                Icons.map,
                'shiny_gen9_sv_title',
                'shiny_gen9_sv_desc',
                Colors.blue,
              ),
            );
            content.add(
              buildInfoBox(
                Icons.fastfood,
                'shiny_gen9_sandwich_title',
                'shiny_gen9_sandwich_desc',
                Colors.orange,
              ),
            );
            content.add(
              buildInfoBox(
                Icons.groups,
                'shiny_gen9_outbreak_title',
                'shiny_gen9_outbreak_desc',
                Colors.teal,
              ),
            );
            if (!_shinyCategories.contains('legendary_mythical')) {
              content.add(
                buildInfoBox(
                  Icons.filter_center_focus,
                  'shiny_gen9_isolation_title',
                  'shiny_gen9_isolation_desc',
                  Colors.cyan,
                ),
              );
            }
          }
          if (isBreedableThisGen) {
            content.add(
              buildInfoBox(
                Icons.egg_alt,
                'shiny_gen8_masuda_title',
                'shiny_gen8_masuda_desc',
                Colors.purple,
              ),
            );
          }

          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen9_link_bisa',
              'https://www.bisafans.de/spiele/editionen/karmesin-purpur/shiny-pokemon.php',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen9_link_sandwich',
              'https://www.polygon.com/pokemon-scarlet-violet-guide/23472506/sandwich-recipes-ingredients-list-meal-powers',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen9_link_outbreak',
              'https://www.youtube.com/watch?v=kYJzXvG22iY',
            ),
          );
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

  Widget _buildGen9_5Specific(BuildContext context, String title) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGen9Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox.shrink();

        bool isPLZAAvailable = snapshot.data!['isPLZA'] == true;

        bool isLocked = _shinyCategories.contains('plza_locks');
        if (!isPLZAAvailable) return const SizedBox.shrink();

        List<Widget> content = [];
        Widget buildInfoBox(
          IconData icon,
          String titleKey,
          String descKey,
          Color color,
        ) {
          /* wie bisher */
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
          /* wie bisher */
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
                onPressed: () => _launchURL(url),
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
              'shiny_gen95_locked_title',
              'shiny_gen95_locked_desc',
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
          content.add(
            buildInfoBox(
              Icons.campaign,
              'shiny_gen95_plza_title',
              'shiny_gen95_plza_desc',
              Colors.amber,
            ),
          );
          content.add(
            buildInfoBox(
              Icons.refresh,
              'shiny_gen95_donut_title',
              'shiny_gen95_donut_desc',
              Colors.deepOrange,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.forum,
              'shiny_gen95_link_reddit',
              'https://www.reddit.com/r/PokemonZA/comments/1of201i/best_shiny_hunting_locationsmethods/',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen95_link_ign',
              'https://www.ign.com/wikis/pokemon-legends-z-a/How_to_Shiny_Hunt_(Shiny_Pokemon_Guide)',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen95_link_yt_de',
              'https://www.youtube.com/watch?v=6Z6nbxlK3J8',
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    List<Widget> genTiles = [];

    List<double> generations = [
      1.0,
      2.0,
      3.0,
      4.0,
      5.0,
      6.0,
      7.0,
      7.5,
      8.0,
      8.5,
      9.0,
      9.5,
    ];

    for (double gen in generations) {
      if (_shouldShowGen(gen)) {
        String titleKey;
        String fallbackTitle;
        if (gen == 7.5) {
          titleKey = 'shiny_guide_gen7_5';
          fallbackTitle = 'Generation 7.5';
        } else if (gen == 8.5) {
          titleKey = 'shiny_guide_gen8_5';
          fallbackTitle = 'Generation 8.5';
        } else if (gen == 9.5) {
          titleKey = 'shiny_guide_gen9_5';
          fallbackTitle = 'Generation 9.5';
        } else {
          titleKey = 'shiny_guide_gen${gen.toInt()}';
          fallbackTitle = 'Generation ${gen.toInt()}';
        }

        String resolvedTitle = Translator.get(titleKey) != titleKey
            ? Translator.get(titleKey)
            : fallbackTitle;

        if (gen == 1.0) {
          genTiles.add(
            ExpansionTile(
              title: Text(
                resolvedTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Gen1ShinyGuide(
                    pokemon: widget.entry.pokemon,
                    shinyCategories: _shinyCategories,
                    initialLevel: _selectedLevel,
                    onLaunchUrl: _launchURL,
                  ),
                ),
              ],
            ),
          );
        } else if (gen == 2.0) {
          genTiles.add(
            ExpansionTile(
              title: Text(
                resolvedTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Gen2ShinyGuide(
                    pokemon: widget.entry.pokemon,
                    dexId: widget.dexId,
                    onLaunchUrl: _launchURL,
                  ),
                ),
              ],
            ),
          );
        } else if (gen == 3.0) {
          genTiles.add(
            ExpansionTile(
              title: Text(
                resolvedTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Gen3ShinyGuide(onLaunchUrl: _launchURL),
                ),
              ],
            ),
          );
        } else if (gen == 4.0) {
          genTiles.add(
            Gen4ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 5.0) {
          genTiles.add(
            Gen5ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 6.0) {
          genTiles.add(
            Gen6ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 7.0) {
          genTiles.add(
            Gen7ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 7.5) {
          genTiles.add(
            Gen7_5ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 8.0) {
          genTiles.add(
            Gen8ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 8.5) {
          genTiles.add(
            Gen8_5ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 9.0) {
          genTiles.add(
            Gen9ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 9.5) {
          genTiles.add(
            Gen9_5ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        }
      }
    }

    if (genTiles.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.amber),
        title: Text(
          Translator.get('shiny_guide_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          ...genTiles,
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Translator.get('shiny_guide_missing_note'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
