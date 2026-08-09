import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pokemon.dart';
import '../utils/shiny_logic_helper.dart';
import '../l10n/app_translations.dart';

class ShinyGuideWidget extends StatefulWidget {
  final Pokemon pokemon;

  const ShinyGuideWidget({super.key, required this.pokemon});

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
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Translator.get('error_launch_url')} $urlString'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Zeige das Widget nur für Gen 1 Pokémon an
    if (widget.pokemon.id > 151) return const SizedBox.shrink();

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
          ExpansionTile(
            title: Text(
              Translator.get('shiny_guide_gen1'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildGen1Content(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGen1Content(BuildContext context) {
    try {
      final isHuntable = ShinyLogicHelper.isHuntableInGen1(widget.pokemon.id);
      final encounters = ShinyLogicHelper.getGen1Encounters(widget.pokemon.id);

      // 1. Huntable Status Text
      final statusWidget = Text(
        isHuntable
            ? Translator.get('shiny_huntable_yes')
            : Translator.get('shiny_huntable_no'),
        style: TextStyle(
          color: isHuntable ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );

      // 2. Tipp anzeigen (wird immer angezeigt)
      final tipWidget = Container(
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
      );

      // 3. Encounters anzeigen (Nur wenn es Encounters gibt - also bei huntbaren Pokémon inkl. Mew)
      Widget encountersWidget = const SizedBox.shrink();
      if (encounters.isNotEmpty) {
        encountersWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.get('notable_encounters'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...encounters.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- ${Translator.get(e.typeKey)}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        Translator.currentLanguage == 'de'
                            ? e.detailsDe
                            : e.detailsEn,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mew Tutorials
            if (widget.pokemon.id == 151) ...[
              const SizedBox(height: 16),
              const Divider(),
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
            ],
          ],
        );
      }

      // 4. Stat Rechner (Nur wenn huntbar UND NICHT Mew)
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
          encountersWidget,
          calculatorWidget,
        ],
      );
    } catch (e) {
      return Text('${Translator.get('error_shiny_guide')} $e');
    }
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
}
