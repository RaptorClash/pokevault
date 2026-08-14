import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pokemon.dart';
import '../../utils/shiny_logic_helper.dart';
import '../../l10n/app_translations.dart';
import '../../data/encounters_data.dart';
import '../breeding_calculator_widget.dart';
import '../../utils/notification_helper.dart';

class ShinyGuideWidget extends StatefulWidget {
  final Pokemon pokemon;
  final String dexId;

  const ShinyGuideWidget({
    super.key,
    required this.pokemon,
    required this.dexId,
  });

  @override
  State<ShinyGuideWidget> createState() => _ShinyGuideWidgetState();
}

class _ShinyGuideWidgetState extends State<ShinyGuideWidget> {
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = ShinyLogicHelper.getDefaultLevel(widget.pokemon.id);
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

  int _getMaxIdForGen(int gen) {
    switch (gen) {
      case 1:
        return 151;
      case 2:
        return 251;
      case 3:
        return 386;
      case 4:
        return 493;
      case 5:
        return 649;
      case 6:
        return 721;
      case 7:
        return 809;
      case 8:
        return 905;
      case 9:
        return 1025;
      default:
        return 1025;
    }
  }

  bool _shouldShowGen(int gen) {
    if (gen == 2 && widget.pokemon.id >= 252 && widget.pokemon.id <= 257) {
      return true;
    }
    if (widget.pokemon.id > _getMaxIdForGen(gen)) return false;

    if (gen == 1) {
      if (widget.pokemon.id <= 151) return true;
      return false;
    }

    bool hasEncounters =
        encountersDatabase[widget.pokemon.id]?.containsKey('gen_$gen') ?? false;
    bool isBreedable = ShinyLogicHelper.isBreedable(widget.pokemon.id);
    bool isStatic = ShinyLogicHelper.isStaticEncounter(
      widget.pokemon.id,
      'gen_$gen',
    );

    return hasEncounters || isBreedable || isStatic;
  }

  Widget _buildGenContent(BuildContext context, int gen) {
    List<Widget> content = [];
    String genKey = 'gen_$gen';

    bool isStatic = ShinyLogicHelper.isStaticEncounter(
      widget.pokemon.id,
      genKey,
    );

    if (isStatic) {
      String combo = ShinyLogicHelper.getSoftResetCombo(genKey);
      content.add(
        Text(
          '${Translator.get('soft_reset')}: $combo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      content.add(const SizedBox(height: 16));
    }

    if (gen == 1) {
      content.add(_buildGen1Specific(context));
    } else if (gen == 2) {
      content.add(_buildGen2Specific(context));
    } else {
      if (!isStatic) {
        content.add(Text(Translator.get('shiny_hunt_methods_soon')));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildGen1Specific(BuildContext context) {
    try {
      final isHuntable = ShinyLogicHelper.isHuntableInGen1(widget.pokemon.id);

      final statusWidget = Text(
        isHuntable
            ? Translator.get('shiny_huntable_yes')
            : Translator.get('shiny_huntable_no'),
        style: TextStyle(
          color: isHuntable ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );

      bool canGetInGen2 =
          ShinyLogicHelper.isBreedable(widget.pokemon.id) ||
          (encountersDatabase[widget.pokemon.id]?.containsKey('gen_2') ??
              false) ||
          ShinyLogicHelper.isStaticEncounter(widget.pokemon.id, 'gen_2');

      final tipWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canGetInGen2)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
          if (widget.pokemon.id == 151) ...[
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
      if (isHuntable && widget.pokemon.id != 151) {
        final baseStats = ShinyLogicHelper.gen1BaseStats[widget.pokemon.id];
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

    if (widget.pokemon.id >= 243 && widget.pokemon.id <= 245) {
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
            ).colorScheme.tertiaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
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
                  widget.pokemon.id == 245
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

    if (widget.pokemon.id >= 252 && widget.pokemon.id <= 257) {
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
            ).colorScheme.tertiaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
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

    if (widget.pokemon.id <= 251 &&
        ShinyLogicHelper.isBaby(widget.pokemon.id)) {
      content.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
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

    if (widget.pokemon.id <= 251 &&
        (ShinyLogicHelper.isBreedable(widget.pokemon.id) ||
            ShinyLogicHelper.isBaby(widget.pokemon.id))) {
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
          initialTargetId: widget.pokemon.id,
          dexId: widget.dexId,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
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
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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

    for (int gen = 1; gen <= 2; gen++) {
      if (_shouldShowGen(gen)) {
        Widget content = _buildGenContent(context, gen);
        genTiles.add(
          ExpansionTile(
            title: Text(
              Translator.get('shiny_guide_gen$gen') != 'shiny_guide_gen$gen'
                  ? Translator.get('shiny_guide_gen$gen')
                  : 'Generation $gen',
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
