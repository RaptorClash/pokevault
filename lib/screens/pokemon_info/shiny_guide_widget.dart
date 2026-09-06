import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/dex_view_models.dart';
import '../../utils/shiny_logic_helper.dart';
import '../../l10n/app_translations.dart';
import 'breeding_calculator_widget.dart';
import '../../utils/notification_helper.dart';
import '../../services/database_service.dart';

class ShinyGuideWidget extends StatefulWidget {
  final DexDisplayEntry entry;
  final String dexId;

  const ShinyGuideWidget({super.key, required this.entry, required this.dexId});

  @override
  State<ShinyGuideWidget> createState() => _ShinyGuideWidgetState();
}

class _ShinyGuideWidgetState extends State<ShinyGuideWidget> {
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = ShinyLogicHelper.getDefaultLevel(widget.entry.pokemon.id);
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

  Future<Map<String, dynamic>> _fetchGen8Data(int id) async {
    final encounters = await DatabaseService.instance.getEncounters(id);
    final db = await DatabaseService.instance.appDatabase;

    final hisuiCheck = await db.query(
      'dex_orders',
      where: 'pokemon_id = ? AND dex_name = ?',
      whereArgs: [id, 'hisui_regional'],
      limit: 1,
    );

    final swshCheck = await db.query(
      'dex_orders',
      where: 'pokemon_id = ? AND dex_name IN (?, ?, ?)',
      whereArgs: [
        id,
        'galar_regional',
        'isle_of_armor_regional',
        'crown_tundra_regional',
      ],
      limit: 1,
    );

    return {
      'encounters': encounters,
      'isHisui': hisuiCheck.isNotEmpty,
      'isSwSh': swshCheck.isNotEmpty,
      'isBDSP': id <= 493,
    };
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
        widget.entry.pokemon.id <= 257)
      return true;
    if (gen == 1) return widget.entry.pokemon.id <= 151;
    if (gen == 2) return widget.entry.pokemon.id <= 251;
    if (gen == 3) return widget.entry.pokemon.id <= 386;
    if (gen == 4) return widget.entry.pokemon.id <= 493;
    if (gen == 5) return widget.entry.pokemon.id <= 649;
    if (gen == 6) return widget.entry.pokemon.id <= 721;
    if (gen == 7) return widget.entry.pokemon.id <= 807;
    if (gen == 7.5)
      return widget.entry.pokemon.id <= 151 ||
          widget.entry.pokemon.id == 808 ||
          widget.entry.pokemon.id == 809;
    if (gen == 8) return widget.entry.pokemon.id <= 905;
    if (gen == 8.5) return widget.entry.pokemon.id <= 905;
    if (gen == 9) return widget.entry.pokemon.id <= 1025;
    if (gen == 9.5)
      return widget.entry.pokemon.id <= 1025;
    return false;
  }

  Widget _buildGenContent(BuildContext context, double gen) {
    List<Widget> content = [];
    if (gen == 1.0)
      content.add(_buildGen1Specific(context));
    else if (gen == 2.0)
      content.add(_buildGen2Specific(context));
    else if (gen == 3.0)
      content.add(_buildGen3Specific(context));
    else if (gen == 4.0)
      content.add(_buildGen4Specific(context));
    else if (gen == 5.0)
      content.add(_buildGen5Specific(context));
    else if (gen == 6.0)
      content.add(_buildGen6Specific(context));
    else if (gen == 7.0)
      content.add(_buildGen7Specific(context));
    else if (gen == 7.5)
      content.add(_buildGen7_5Specific(context));
    else if (gen == 8.0)
      content.add(_buildGen8Specific(context));
    else if (gen == 8.5)
      content.add(_buildGen8_5Specific(context));
    else if (gen == 9.0)
      content.add(_buildGen9Specific(context));
    else if (gen == 9.5)
      content.add(_buildGen9_5Specific(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildGen1Specific(BuildContext context) {
    try {
      final isHuntable = ShinyLogicHelper.isHuntableInGen1(
        widget.entry.pokemon.id,
      );

      final statusWidget = Text(
        isHuntable
            ? (Translator.get('shiny_gen1_huntable_yes') !=
                      'shiny_gen1_huntable_yes'
                  ? Translator.get('shiny_gen1_huntable_yes')
                  : 'Shiny Huntable: Ja (DV-basiert, Chance 1:8192)')
            : (Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein'),
        style: TextStyle(
          color: isHuntable ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );

      final tipWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Translator.get('shiny_guide_gen1_desc'),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.entry.pokemon.id == 151) ...[
            const SizedBox(height: 8),
            Text(
              Translator.get('tutorials_mew'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_filled),
                label: Text(Translator.get('tutorial_mew_video_de')),
                onPressed: () =>
                    _launchURL('https://www.youtube.com/watch?v=jJro6Hx4IfQ'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_filled),
                label: Text(Translator.get('tutorial_mew_video_en')),
                onPressed: () =>
                    _launchURL('https://www.youtube.com/watch?v=rvhuJsS4EhE'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.article),
                label: Text(Translator.get('tutorial_mew_text_en')),
                onPressed: () =>
                    _launchURL('https://extratricky.com/md/mew.md'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.article),
                label: Text(Translator.get('tutorial_mew_normal_text')),
                onPressed: () {
                  final url = Translator.currentLanguage == 'de'
                      ? 'https://www.pokewiki.de/Mew-Glitch'
                      : 'https://bulbapedia.bulbagarden.net/wiki/Mew_glitch';
                  _launchURL(url);
                },
              ),
            ),
          ],
        ],
      );

      Widget calculatorWidget = const SizedBox.shrink();

      if (isHuntable && widget.entry.pokemon.id != 151) {
        final baseStats =
            ShinyLogicHelper.gen1BaseStats[widget.entry.pokemon.id];
        if (baseStats != null) {
          calculatorWidget = Column(
            children: [
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  Translator.get('shiny_stat_calculator'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${Translator.get('level')}: '),
                          const SizedBox(width: 16),
                          DropdownButton<int>(
                            value: _selectedLevel,
                            items: List.generate(100, (i) => i + 1).map((
                              int value,
                            ) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLevel = newValue;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${Translator.get('base_stats')}: ${baseStats[0]}/${baseStats[1]}/${baseStats[2]}/${baseStats[3]}/${baseStats[4]}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Translator.get('table_hp_0'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _buildStatTable(baseStats, _selectedLevel, 0, [
                        2,
                        6,
                        10,
                        14,
                      ]),
                      const SizedBox(height: 24),
                      Text(
                        Translator.get('table_hp_8'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _buildStatTable(baseStats, _selectedLevel, 8, [
                        3,
                        7,
                        11,
                        15,
                      ]),
                    ],
                  ),
                ],
              ),
            ],
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statusWidget,
          const SizedBox(height: 12),
          tipWidget,
          calculatorWidget,
        ],
      );
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error_shiny_guide')} $e');
      return Text('${Translator.get('error_shiny_guide')} $e');
    }
  }

  Widget _buildGen2Specific(BuildContext context) {
    List<Widget> content = [];

    content.add(
      Text(
        Translator.get('shiny_gen2_huntable_yes') != 'shiny_gen2_huntable_yes'
            ? Translator.get('shiny_gen2_huntable_yes')
            : 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    content.add(const SizedBox(height: 16));

    if (widget.entry.pokemon.id >= 243 && widget.entry.pokemon.id <= 245) {
      content.add(
        Text(
          Translator.get('shiny_roamer_gen2_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.entry.pokemon.id == 245
                      ? Translator.get('shiny_roamer_gen2_suicune_note')
                      : Translator.get('shiny_roamer_gen2_beasts_note'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      content.add(const SizedBox(height: 16));
    }

    if (widget.entry.pokemon.id >= 252 && widget.entry.pokemon.id <= 257) {
      content.add(
        Text(
          Translator.get('shiny_mail_writer_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.memory,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Translator.get('shiny_mail_writer_note'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      content.add(const SizedBox(height: 12));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.language),
            label: Text(Translator.get('tutorial_mail_writer_main')),
            onPressed: () => _launchURL(
              'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.code),
            label: Text(Translator.get('tutorial_mail_writer_scripts')),
            onPressed: () => _launchURL(
              'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes#Gen3Giver_scripts',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 24));
    }

    if (widget.entry.pokemon.id <= 251 &&
        ShinyLogicHelper.isBaby(widget.entry.pokemon.id)) {
      content.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.egg,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Translator.get('shiny_odd_egg_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                Translator.get('shiny_odd_egg_desc'),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      );
      content.add(const SizedBox(height: 16));
    }

    if (widget.entry.pokemon.id <= 251 &&
        (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
            ShinyLogicHelper.isBaby(widget.entry.pokemon.id))) {
      content.add(
        Text(
          Translator.get('shiny_ditto_guide'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.language),
            label: const Text('Text Tutorial (DE) - Bisafans'),
            onPressed: () => _launchURL(
              'https://www.bisafans.de/spiele/editionen/gold-silber/shiny-ditto.php',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 8));
      content.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.language),
            label: const Text('Text Tutorial (EN) - Reddit'),
            onPressed: () => _launchURL(
              'https://www.reddit.com/r/ShinyPokemon/comments/14s1ush/discussion_found_a_way_to_get_a_shiny_ditto_in/',
            ),
          ),
        ),
      );
      content.add(const SizedBox(height: 24));
      content.add(
        BreedingCalculatorWidget(
          initialTargetId: widget.entry.pokemon.id,
          dexId: widget.dexId,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildGen3Specific(BuildContext context) {
    List<Widget> content = [];

    content.add(
      Text(
        Translator.get('shiny_gen3_huntable_yes') != 'shiny_gen3_huntable_yes'
            ? Translator.get('shiny_gen3_huntable_yes')
            : 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    content.add(const SizedBox(height: 16));

    content.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Translator.get('shiny_gen3_rs_note') != 'shiny_gen3_rs_note'
                    ? Translator.get('shiny_gen3_rs_note')
                    : 'Rubin & Saphir: Der Seed ist zufällig...',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    content.add(const SizedBox(height: 8));

    content.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Translator.get('shiny_gen3_emerald_note') !=
                        'shiny_gen3_emerald_note'
                    ? Translator.get('shiny_gen3_emerald_note')
                    : 'Smaragd: RNG Fehler! Der Start-Seed ist bei jedem Reset immer 0...',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    content.add(const SizedBox(height: 8));

    content.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.tertiary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Translator.get('shiny_gen3_frbg_note') != 'shiny_gen3_frbg_note'
                    ? Translator.get('shiny_gen3_frbg_note')
                    : 'Feuerrot & Blattgrün: Kein RNG Bug...',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    content.add(const SizedBox(height: 24));

    content.add(
      Text(
        Translator.get('shiny_gen3_links_title') != 'shiny_gen3_links_title'
            ? Translator.get('shiny_gen3_links_title')
            : 'RNG Manipulation Guides & Ressourcen',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    content.add(const SizedBox(height: 12));

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
            onPressed: () => _launchURL(url),
          ),
        ),
      );
    }

    content.add(
      buildLinkBtn(
        Icons.person,
        'shiny_gen3_link_blisy_channel',
        'https://www.youtube.com/@imablisy',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.play_circle_filled,
        'shiny_gen3_link_blisy_playlist',
        'https://www.youtube.com/watch?v=5feON9zDy6g&list=PL4o9bTT3px_h08zUFb3oChEFku_jG6zyt',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.play_circle_filled,
        'shiny_gen3_link_blisy_rs_video',
        'https://www.youtube.com/watch?v=_8qxkkGeXok',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.article,
        'shiny_gen3_link_smogon',
        'https://www.smogon.com/ingame/rng/rs_nonbredrng',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.article,
        'shiny_gen3_link_retail_rng',
        'https://retailrng.com/emerald/',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.forum,
        'shiny_gen3_link_reddit_emerald',
        'https://www.reddit.com/r/pokemonrng/comments/idxt27/rng_manipulation_in_emerald/',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildGen4Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final encounters = snapshot.data;
        bool hasEncounterThisGen =
            encounters != null && encounters.containsKey('gen_4');
        bool hasRadarEncounter = false;
        bool isStaticOrGift = false;

        List<int> legendariesAndMythicals = [
          144,
          145,
          146,
          150,
          151,
          243,
          244,
          245,
          249,
          250,
          251,
          377,
          378,
          379,
          380,
          381,
          382,
          383,
          384,
          385,
          386,
          480,
          481,
          482,
          483,
          484,
          485,
          486,
          487,
          488,
          489,
          490,
          491,
          492,
          493,
        ];

        bool isBreedable =
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !legendariesAndMythicals.contains(id);

        bool isHuntable = isBreedable || hasEncounterThisGen;

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

        if (legendariesAndMythicals.contains(id) && hasEncounterThisGen) {
          isStaticOrGift = true;
        }

        List<Widget> content = [];

        if (!isHuntable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 8));
          content.add(
            Text(
              Translator.get('shiny_not_in_gen') != 'shiny_not_in_gen'
                  ? Translator.get('shiny_not_in_gen')
                  : 'Dieses Pokémon ist in dieser Generation nicht regulär fangbar oder züchtbar.',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen4_huntable_yes') !=
                    'shiny_gen4_huntable_yes'
                ? Translator.get('shiny_gen4_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
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

        if (isBreedable) {
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

        if (hasRadarEncounter && !legendariesAndMythicals.contains(id)) {
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
        if (hasGenderVariation && !legendariesAndMythicals.contains(id)) {
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

        bool isHGSSStarter = id == 152 || id == 155 || id == 158;
        if (isHGSSStarter) {
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
        if (gen4Roamers.contains(id)) {
          content.add(
            buildInfoBox(
              Icons.map,
              'shiny_gen4_roamer_title',
              'shiny_gen4_roamer_desc',
              Colors.deepOrange,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen5Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    List<int> gen5ShinyLocks = [494, 643, 644, 647, 648, 649];
    bool isShinyLocked = gen5ShinyLocks.contains(id);

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final encounters = snapshot.data;
        bool hasEncounterThisGen =
            encounters != null && encounters.containsKey('gen_5');
        bool isStaticOrGift = false;
        bool hasGrassEncounter = false;

        List<int> gen5Legendaries = [
          494,
          638,
          639,
          640,
          641,
          642,
          643,
          644,
          645,
          646,
          647,
          648,
          649,
        ];
        bool isBreedable =
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !gen5Legendaries.contains(id);

        bool isHuntable =
            (isBreedable || hasEncounterThisGen) && !isShinyLocked;

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

        if (gen5Legendaries.contains(id) && hasEncounterThisGen) {
          isStaticOrGift = true;
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

        if (!isHuntable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 8));

          if (isShinyLocked) {
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
                Translator.get('shiny_not_in_gen') != 'shiny_not_in_gen'
                    ? Translator.get('shiny_not_in_gen')
                    : 'Dieses Pokémon ist in dieser Generation nicht regulär fangbar oder züchtbar.',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen5_huntable_yes') !=
                    'shiny_gen5_huntable_yes'
                ? Translator.get('shiny_gen5_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:8192)',
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

        if (isBreedable) {
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

        if (hasGrassEncounter && !gen5Legendaries.contains(id)) {
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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen6Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    List<int> absoluteGen6Locks = [
      144,
      145,
      146,
      150,
      382,
      383,
      384,
      386,
      716,
      717,
      718,
      719,
      720,
      721,
    ];
    bool isAbsolutelyLocked = absoluteGen6Locks.contains(id);

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final encounters = snapshot.data;
        bool hasEncounterThisGen =
            encounters != null && encounters.containsKey('gen_6');
        bool hasXYGrassEncounter = false;
        bool hasORASGrassEncounter = false;
        bool hasFriendSafari = false;
        bool hasFishingEncounter = false;
        bool hasHordeEncounter = false;
        bool isStaticOrGift = false;

        List<int> legendariesAndMythicals = [
          144,
          145,
          146,
          150,
          151,
          243,
          244,
          245,
          249,
          250,
          251,
          377,
          378,
          379,
          380,
          381,
          382,
          383,
          384,
          385,
          386,
          480,
          481,
          482,
          483,
          484,
          485,
          486,
          487,
          488,
          489,
          490,
          491,
          492,
          493,
          494,
          638,
          639,
          640,
          641,
          642,
          643,
          644,
          645,
          646,
          647,
          648,
          649,
          716,
          717,
          718,
          719,
          720,
          721,
        ];

        bool isBreedable =
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !legendariesAndMythicals.contains(id);
        bool isHuntable =
            (isBreedable || hasEncounterThisGen) && !isAbsolutelyLocked;

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

        if (legendariesAndMythicals.contains(id) && hasEncounterThisGen) {
          isStaticOrGift = true;
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

        if (!isHuntable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 8));

          if (isAbsolutelyLocked) {
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
                Translator.get('shiny_not_in_gen') != 'shiny_not_in_gen'
                    ? Translator.get('shiny_not_in_gen')
                    : 'Dieses Pokémon ist in dieser Generation nicht regulär fangbar oder züchtbar.',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen6_huntable_yes') !=
                    'shiny_gen6_huntable_yes'
                ? Translator.get('shiny_gen6_huntable_yes')
                : 'Shiny Huntable: Ja (Neue Basis-Chance: 1:4096)',
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

        if (isBreedable) {
          content.add(
            buildInfoBox(
              Icons.egg_alt,
              'shiny_gen6_masuda_title',
              'shiny_gen6_masuda_desc',
              Colors.purple,
            ),
          );
        }

        if (hasFriendSafari && !legendariesAndMythicals.contains(id)) {
          content.add(
            buildInfoBox(
              Icons.people_alt,
              'shiny_gen6_friendsafari_title',
              'shiny_gen6_friendsafari_desc',
              Colors.pink,
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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (hasORASGrassEncounter && !legendariesAndMythicals.contains(id)) {
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

        if (hasXYGrassEncounter && !legendariesAndMythicals.contains(id)) {
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

        if (hasFishingEncounter && !legendariesAndMythicals.contains(id)) {
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

        if (hasHordeEncounter && !legendariesAndMythicals.contains(id)) {
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

        if (isStaticOrGift && id != 143 && !isAbsolutelyLocked) {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen7Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final encounters = snapshot.data;
        bool hasAlolaEncounter = false;
        bool isStaticOrGift = false;
        bool hasWildSpawn = false;

        if (encounters != null && encounters.containsKey('gen_7')) {
          final gen7 = encounters['gen_7']!;
          for (var version in gen7.keys) {
            if (version == 'sun' ||
                version == 'moon' ||
                version == 'ultra-sun' ||
                version == 'ultra-moon') {
              hasAlolaEncounter = true;
              for (var loc in gen7[version]!) {
                final locLower = loc.toLowerCase();
                if (locLower.contains('stationary') ||
                    locLower.contains('gift') ||
                    locLower.contains('fossil') ||
                    locLower.contains('only one')) {
                  isStaticOrGift = true;
                }
                if (locLower.contains('grass') ||
                    locLower.contains('walk') ||
                    locLower.contains('gras') ||
                    locLower.contains('cave') ||
                    locLower.contains('surf')) {
                  hasWildSpawn = true;
                }
              }
            }
          }
        }

        List<int> warpRidePokemon = [
          195,
          219,
          271,
          274,
          277,
          308,
          326,
          334,
          419,
          423,
          450,
          452,
          460,
          469,
          531,
          558,
          561,
          581,
          618,
          695,
          144,
          145,
          146,
          150,
          243,
          244,
          245,
          249,
          250,
          377,
          378,
          379,
          380,
          381,
          382,
          383,
          384,
          480,
          481,
          482,
          483,
          484,
          485,
          486,
          487,
          488,
          638,
          639,
          640,
          641,
          642,
          643,
          644,
          645,
          646,
          716,
          717,
        ];
        bool canBeInWarpRide = warpRidePokemon.contains(id);

        List<int> absoluteGen7Locks = [
          718,
          785,
          786,
          787,
          788,
          789,
          790,
          791,
          792,
          800,
          801,
          802,
          807,
        ];

        List<int> ultraBeasts = [
          793,
          794,
          795,
          796,
          797,
          798,
          799,
          803,
          804,
          805,
          806,
        ];

        List<int> legendariesAndMythicals = [
          144,
          145,
          146,
          150,
          151,
          243,
          244,
          245,
          249,
          250,
          251,
          377,
          378,
          379,
          380,
          381,
          382,
          383,
          384,
          385,
          386,
          480,
          481,
          482,
          483,
          484,
          485,
          486,
          487,
          488,
          489,
          490,
          491,
          492,
          493,
          494,
          638,
          639,
          640,
          641,
          642,
          643,
          644,
          645,
          646,
          647,
          648,
          649,
          716,
          717,
          718,
          719,
          720,
          721,
          772,
          773,
          785,
          786,
          787,
          788,
          789,
          790,
          791,
          792,
          793,
          794,
          795,
          796,
          797,
          798,
          799,
          800,
          801,
          802,
          803,
          804,
          805,
          806,
          807,
        ];

        bool isBreedable =
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !legendariesAndMythicals.contains(id);
        bool isHuntable =
            (isBreedable || hasAlolaEncounter || canBeInWarpRide) &&
            !absoluteGen7Locks.contains(id);

        if ((legendariesAndMythicals.contains(id) && hasAlolaEncounter) ||
            canBeInWarpRide) {
          isStaticOrGift = true;
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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (!isHuntable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          content.add(const SizedBox(height: 8));
          if (absoluteGen7Locks.contains(id)) {
            content.add(
              buildInfoBox(
                Icons.lock,
                'shiny_gen7_locked_title',
                'shiny_gen7_locked_desc',
                Colors.red,
              ),
            );
          } else {
            content.add(
              Text(
                Translator.get('shiny_not_in_gen') != 'shiny_not_in_gen'
                    ? Translator.get('shiny_not_in_gen')
                    : 'Dieses Pokémon ist in dieser Generation nicht regulär fangbar oder züchtbar.',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen7_huntable_yes') !=
                    'shiny_gen7_huntable_yes'
                ? Translator.get('shiny_gen7_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        content.add(const SizedBox(height: 16));

        if (ultraBeasts.contains(id)) {
          content.add(
            buildInfoBox(
              Icons.warning_amber_rounded,
              'shiny_gen7_ub_locked_title',
              'shiny_gen7_ub_locked_desc',
              Colors.orange,
            ),
          );
        }

        if (isBreedable) {
          content.add(
            buildInfoBox(
              Icons.egg_alt,
              'shiny_gen6_masuda_title',
              'shiny_gen6_masuda_desc',
              Colors.purple,
            ),
          );
        }

        if (hasWildSpawn && !legendariesAndMythicals.contains(id)) {
          content.add(
            buildInfoBox(
              Icons.group_add,
              'shiny_gen7_sos_title',
              'shiny_gen7_sos_desc',
              Colors.blue,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.forum,
              'shiny_gen7_sos_link_reddit',
              'https://www.reddit.com/r/pokemontrades/comments/5ig3pj/sos_chaining_how_to_do_it_and_how_to_do_it/',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen7_sos_link_yt_en',
              'https://www.youtube.com/watch?v=JyQW4buHeGY',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen7_sos_link_yt_de',
              'https://www.youtube.com/watch?v=SJdagmvWASM',
            ),
          );
          content.add(const SizedBox(height: 8));
        }

        if (canBeInWarpRide) {
          content.add(
            buildInfoBox(
              Icons.rocket_launch,
              'shiny_gen7_warp_title',
              'shiny_gen7_warp_desc',
              Colors.indigo,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.forum,
              'shiny_gen7_warp_link_reddit',
              'https://www.reddit.com/r/ShinyPokemon/comments/7myj5n/7_warp_ride_shiny_odds_grid/',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen7_warp_link_yt_en',
              'https://www.youtube.com/watch?v=63AHQizp8zg',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen7_warp_link_yt_de',
              'https://www.youtube.com/watch?v=USjxUroSmKA',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen7_warp_link_bisa',
              'https://www.bisafans.de/spiele/editionen/ultra-sonne-ultra-mond/warp-loch-shinys.php',
            ),
          );
          content.add(const SizedBox(height: 8));
        }

        if (isStaticOrGift) {
          content.add(
            buildInfoBox(
              Icons.restart_alt,
              'shiny_gen6_sr_title',
              'shiny_gen6_sr_desc',
              Colors.teal,
            ),
          );
        }

        if (hasWildSpawn && !legendariesAndMythicals.contains(id)) {
          content.add(
            buildInfoBox(
              Icons.holiday_village,
              'shiny_gen7_pelago_title',
              'shiny_gen7_pelago_desc',
              Colors.green,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen7_5Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, Map<String, List<String>>>?>(
      future: DatabaseService.instance.getEncounters(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final encounters = snapshot.data;
        bool hasLetsGoEncounter = false;
        bool isStaticOrGift = false;

        if (encounters != null && encounters.containsKey('gen_7')) {
          final gen7 = encounters['gen_7']!;
          for (var version in gen7.keys) {
            if (version == 'lets-go-pikachu' || version == 'lets-go-eevee') {
              hasLetsGoEncounter = true;
              for (var loc in gen7[version]!) {
                final locLower = loc.toLowerCase();
                if (locLower.contains('stationary') ||
                    locLower.contains('gift') ||
                    locLower.contains('fossil') ||
                    locLower.contains('only one')) {
                  isStaticOrGift = true;
                }
              }
            }
          }
        }

        List<int> alolanFormsBaseIds = [
          19,
          20,
          26,
          27,
          28,
          37,
          38,
          50,
          51,
          52,
          53,
          74,
          75,
          76,
          88,
          89,
          103,
          105,
        ];
        bool canTradeAlolan = alolanFormsBaseIds.contains(id);

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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (!hasLetsGoEncounter && !canTradeAlolan && id != 808 && id != 809) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen7_huntable_yes') !=
                    'shiny_gen7_huntable_yes'
                ? Translator.get('shiny_gen7_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        content.add(const SizedBox(height: 16));

        if (id == 25 || id == 133 || id == 151) {
          content.add(
            buildInfoBox(
              Icons.lock,
              'shiny_gen75_locked_title',
              'shiny_gen75_locked_desc',
              Colors.red,
            ),
          );
        }

        if (hasLetsGoEncounter && id != 151) {
          content.add(
            buildInfoBox(
              Icons.link,
              'shiny_gen75_combo_title',
              'shiny_gen75_combo_desc',
              Colors.orange,
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

        if (isStaticOrGift && id != 151) {
          content.add(
            buildInfoBox(
              Icons.restart_alt,
              'shiny_gen6_sr_title',
              'shiny_gen6_sr_desc',
              Colors.deepPurple,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen8Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGen8Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        bool isSwShAvailable = data['isSwSh'] == true;
        bool isBDSPAvailable = data['isBDSP'] == true;

        bool isBreedable =
            ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
            ShinyLogicHelper.isBaby(id);
        bool isHuntable = isSwShAvailable || isBDSPAvailable || isBreedable;

        List<int> absoluteGen8Locks = [
          772,
          773,
          789,
          790,
          803,
          804,
          888,
          889,
          890,
          891,
          892,
          893,
          896,
          897,
          898,
        ];
        bool isLocked = absoluteGen8Locks.contains(id);

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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (!isHuntable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        if (isLocked) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
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
              'shiny_gen8_locked_title',
              'shiny_gen8_locked_desc',
              Colors.red,
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen7_huntable_yes') !=
                    'shiny_gen7_huntable_yes'
                ? Translator.get('shiny_gen7_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        content.add(const SizedBox(height: 16));

        if (isSwShAvailable || isBreedable) {
          content.add(
            buildInfoBox(
              Icons.sports_esports,
              'shiny_gen8_swsh_title',
              'shiny_gen8_swsh_desc',
              Colors.blue,
            ),
          );
        }

        if (isBDSPAvailable) {
          content.add(
            buildInfoBox(
              Icons.diamond,
              'shiny_gen8_bdsp_title',
              'shiny_gen8_bdsp_desc',
              Colors.cyan,
            ),
          );
        }

        if (isBreedable) {
          content.add(
            buildInfoBox(
              Icons.egg_alt,
              'shiny_gen8_masuda_title',
              'shiny_gen8_masuda_desc',
              Colors.purple,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.language,
              'shiny_gen8_masuda_link',
              'https://bulbapedia.bulbagarden.net/wiki/Masuda_method',
            ),
          );
          content.add(const SizedBox(height: 8));
        }

        if (isBDSPAvailable && isBreedable) {
          content.add(
            buildInfoBox(
              Icons.radar,
              'shiny_gen8_radar_title',
              'shiny_gen8_radar_desc',
              Colors.indigo,
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen8_radar_link_yt_de',
              'https://www.youtube.com/watch?v=bCmGq6eYL90',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.forum,
              'shiny_gen8_radar_link_reddit',
              'https://www.reddit.com/r/PokeLeaks/comments/qsr6ze/bdsp_poke_radar_guide/?show=original',
            ),
          );
          content.add(
            buildLinkBtn(
              Icons.play_circle_filled,
              'shiny_gen8_radar_link_yt_en',
              'https://www.youtube.com/watch?v=wnaS_WhyNMs',
            ),
          );
          content.add(const SizedBox(height: 8));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen8_5Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGen8Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        bool isPLAAvailable = snapshot.data!['isHisui'] == true;

        List<int> plaLocks = [
          480,
          481,
          482,
          483,
          484,
          485,
          486,
          487,
          488,
          489,
          490,
          491,
          492,
          493,
          641,
          642,
          645,
          905,
        ];
        bool isLocked = plaLocks.contains(id);

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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (!isPLAAvailable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        if (isLocked) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
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
              'shiny_gen85_locked_title',
              'shiny_gen85_locked_desc',
              Colors.red,
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen7_huntable_yes') !=
                    'shiny_gen7_huntable_yes'
                ? Translator.get('shiny_gen7_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        content.add(const SizedBox(height: 16));

        content.add(
          buildInfoBox(
            Icons.catching_pokemon,
            'shiny_gen85_pla_title',
            'shiny_gen85_pla_desc',
            Colors.amber,
          ),
        );
        content.add(
          buildInfoBox(
            Icons.radar,
            'shiny_gen85_pla_outbreaks_title',
            'shiny_gen85_pla_outbreaks_desc',
            Colors.deepOrange,
          ),
        );

        content.add(
          buildLinkBtn(
            Icons.forum,
            'shiny_gen8_pla_link_reddit',
            'https://www.reddit.com/r/PokemonLegendsArceus/comments/1lqhvyh/the_right_method_to_shiny_hunting_since_111/?show=original',
          ),
        );
        content.add(
          buildLinkBtn(
            Icons.language,
            'shiny_gen8_pla_link_bisafans',
            'https://community.bisafans.de/forum/index.php?thread/340909-shiny-hunting-in-version-1-1-1/',
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen9Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGen9Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        bool isSVAvailable = data['isSV'] == true;

        List<int> svLocks = [
          144,
          145,
          146,
          243,
          244,
          245,
          249,
          250,
          380,
          381,
          382,
          383,
          384,
          638,
          639,
          640,
          643,
          644,
          646,
          648,
          791,
          792,
          800,
          891,
          896,
          897,
          901,
          1001,
          1002,
          1003,
          1004,
          1007,
          1008,
          1009,
          1010,
          1014,
          1015,
          1016,
          1017,
          1020,
          1021,
          1022,
          1023,
          1024,
          1025,
        ];

        List<int> legendariesAndMythicals = [
          144,
          145,
          146,
          150,
          151,
          243,
          244,
          245,
          249,
          250,
          251,
          377,
          378,
          379,
          380,
          381,
          382,
          383,
          384,
          385,
          386,
          480,
          481,
          482,
          483,
          484,
          485,
          486,
          487,
          488,
          489,
          490,
          491,
          492,
          493,
          494,
          638,
          639,
          640,
          641,
          642,
          643,
          644,
          645,
          646,
          647,
          648,
          649,
          716,
          717,
          718,
          719,
          720,
          721,
          772,
          773,
          785,
          786,
          787,
          788,
          789,
          790,
          791,
          792,
          793,
          794,
          795,
          796,
          797,
          798,
          799,
          800,
          801,
          802,
          803,
          804,
          805,
          806,
          807,
          888,
          889,
          890,
          891,
          892,
          893,
          894,
          895,
          896,
          897,
          898,
          905,
          1001,
          1002,
          1003,
          1004,
          1007,
          1008,
          1014,
          1015,
          1016,
          1017,
          1024,
        ];

        bool isBreedable =
            (ShinyLogicHelper.isBreedable(widget.entry.pokemon) ||
                ShinyLogicHelper.isBaby(id)) &&
            !legendariesAndMythicals.contains(id);
        bool isHuntable = isSVAvailable || isBreedable;
        bool isLocked = svLocks.contains(id);

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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (!isHuntable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        if (isLocked) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen7_huntable_yes') !=
                    'shiny_gen7_huntable_yes'
                ? Translator.get('shiny_gen7_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
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

          if (!legendariesAndMythicals.contains(id)) {
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

        if (isBreedable) {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  Widget _buildGen9_5Specific(BuildContext context) {
    final id = widget.entry.pokemon.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGen9Data(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        bool isPLZAAvailable = snapshot.data!['isPLZA'] == true;

        List<int> plzaLocks = [
          359,
          382,
          383,
          384,
          398,
          448,
          485,
          491,
          669,
          678,
          716,
          717,
          718,
          977,
        ];
        bool isLocked = plzaLocks.contains(id);

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
                onPressed: () => _launchURL(url),
              ),
            ),
          );
        }

        if (!isPLZAAvailable) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        if (isLocked) {
          content.add(
            Text(
              Translator.get('shiny_huntable_no') != 'shiny_huntable_no'
                  ? Translator.get('shiny_huntable_no')
                  : 'Shiny Huntable: Nein',
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          );
        }

        content.add(
          Text(
            Translator.get('shiny_gen7_huntable_yes') !=
                    'shiny_gen7_huntable_yes'
                ? Translator.get('shiny_gen7_huntable_yes')
                : 'Shiny Huntable: Ja (Basis-Chance 1:4096)',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      },
    );
  }

  int _calcStat(int base, int dv, int level, bool isHp) {
    int stat = (((base + dv) * 2) * level) ~/ 100;
    return isHp ? stat + level + 10 : stat + 5;
  }

  Widget _buildStatTable(
    List<int> baseStats,
    int level,
    int hpDv,
    List<int> atkDvs,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowMinHeight: 35,
          dataRowMaxHeight: 35,
          columns: [
            const DataColumn(label: Text('')),
            ...atkDvs.map(
              (dv) => DataColumn(
                label: Text(
                  'ATK DV $dv',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(
                  Text(
                    Translator.get('stat_hp'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...atkDvs.map(
                  (dv) => DataCell(
                    Text(_calcStat(baseStats[0], hpDv, level, true).toString()),
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(
                  Text(
                    Translator.get('stat_atk'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...atkDvs.map(
                  (dv) => DataCell(
                    Text(_calcStat(baseStats[1], dv, level, false).toString()),
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(
                  Text(
                    Translator.get('stat_def'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...atkDvs.map(
                  (dv) => DataCell(
                    Text(_calcStat(baseStats[2], 10, level, false).toString()),
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(
                  Text(
                    Translator.get('stat_spe'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...atkDvs.map(
                  (dv) => DataCell(
                    Text(_calcStat(baseStats[3], 10, level, false).toString()),
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(
                  Text(
                    Translator.get('stat_spc'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...atkDvs.map(
                  (dv) => DataCell(
                    Text(_calcStat(baseStats[4], 10, level, false).toString()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        Widget content = _buildGenContent(context, gen);

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

        genTiles.add(
          ExpansionTile(
            title: Text(
              Translator.get(titleKey) != titleKey
                  ? Translator.get(titleKey)
                  : fallbackTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(padding: const EdgeInsets.all(16.0), child: content),
            ],
          ),
        );
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
