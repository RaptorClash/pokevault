import 'package:flutter/material.dart';
import '../../../../models/pokemon.dart';
import '../../../../services/database_service.dart';
import '../../../../l10n/app_translations.dart';
import '../../../../utils/notification_helper.dart';

class Gen1ShinyGuide extends StatefulWidget {
  final Pokemon pokemon;
  final List<String> shinyCategories;
  final int initialLevel;
  final Future<void> Function(String) onLaunchUrl;

  const Gen1ShinyGuide({
    super.key,
    required this.pokemon,
    required this.shinyCategories,
    required this.initialLevel,
    required this.onLaunchUrl,
  });

  @override
  State<Gen1ShinyGuide> createState() => _Gen1ShinyGuideState();
}

class _Gen1ShinyGuideState extends State<Gen1ShinyGuide> {
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
    try {
      final isHuntable = widget.shinyCategories.contains('gen1_huntable');
      final statusWidget = Text(
        isHuntable
            ? (Translator.get(
                'shiny_gen1_huntable_yes',
                fallback: 'Shiny Huntable: Ja (DV-basiert, Chance 1:8192)',
              ))
            : (Translator.get(
                'shiny_huntable_no',
                fallback: 'Shiny Huntable: Nein',
              )),
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
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                onPressed: () => widget.onLaunchUrl('https://www.youtube.com/watch?v=jJro6Hx4IfQ'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_filled),
                label: Text(Translator.get('tutorial_mew_video_en')),
                onPressed: () => widget.onLaunchUrl('https://www.youtube.com/watch?v=rvhuJsS4EhE'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.article),
                label: Text(Translator.get('tutorial_mew_text_en')),
                onPressed: () => widget.onLaunchUrl('https://extratricky.com/md/mew.md'),
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
                  widget.onLaunchUrl(url);
                },
              ),
            ),
          ],
        ],
      );

      Widget calculatorWidget = const SizedBox.shrink();
      if (isHuntable && widget.pokemon.id != 151) {
        calculatorWidget = FutureBuilder<List<int>?>(
          future: DatabaseService.instance.getGen1BaseStats(widget.pokemon.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }
            final baseStats = snapshot.data!;
            return Column(
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
                              items: List.generate(100, (i) => i + 1).map((int value) {
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
                        _buildStatTable(baseStats, _selectedLevel, 0, [2, 6, 10, 14]),
                        const SizedBox(height: 24),
                        Text(
                          Translator.get('table_hp_8'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _buildStatTable(baseStats, _selectedLevel, 8, [3, 7, 11, 15]),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
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
}