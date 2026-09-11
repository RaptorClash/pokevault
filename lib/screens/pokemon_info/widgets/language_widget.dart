import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../providers/dex_provider.dart';
import '../../../l10n/app_translations.dart';

class LanguageWidget extends StatelessWidget {
  final DexDisplayEntry entry;
  final String dexId;

  const LanguageWidget({super.key, required this.entry, required this.dexId});

  static const List<Map<String, String>> _languages = [
    {'id': 'JPN', 'label': 'JPN', 'tooltip': 'Japanisch'},
    {'id': 'ENG', 'label': 'ENG', 'tooltip': 'Englisch'},
    {'id': 'FRA', 'label': 'FRA', 'tooltip': 'Französisch'},
    {'id': 'ITA', 'label': 'ITA', 'tooltip': 'Italienisch'},
    {'id': 'GER', 'label': 'GER', 'tooltip': 'Deutsch'},
    {'id': 'SPA', 'label': 'SPA', 'tooltip': 'Spanisch'},
    {'id': 'ES-LA', 'label': 'ES-LA', 'tooltip': 'Spanisch (Lateinamerika)'},
    {'id': 'KOR', 'label': 'KOR', 'tooltip': 'Koreanisch'},
    {'id': 'CHS', 'label': 'CHS', 'tooltip': 'Chinesisch (Vereinfacht)'},
    {'id': 'CHT', 'label': 'CHT', 'tooltip': 'Chinesisch (Traditionell)'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final dex = provider.userDexes.firstWhere(
      (d) => d.id == dexId,
      orElse: () => provider.userDexes.first,
    );
    final uniqueId = entry.uniqueId;
    final caughtLangs = dex.caughtLanguages[uniqueId] ?? [];

    final int totalLangs = _languages.length;
    final int caughtCount = caughtLangs.length;
    final bool isComplete = caughtCount == totalLangs;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          Icons.language,
          color: isComplete ? Colors.green : Colors.blue,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                Translator.get('languages_title', fallback: 'Sprachen'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$caughtCount / $totalLangs',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _languages.map((lang) {
                  final isSelected = caughtLangs.contains(lang['id']);

                  return Tooltip(
                    message: lang['tooltip'],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        List<String> updatedLangs = List.from(caughtLangs);
                        if (!isSelected) {
                          updatedLangs.add(lang['id']!);
                        } else {
                          updatedLangs.remove(lang['id']!);
                        }
                        provider.updatePokemonLanguages(
                          dexId,
                          uniqueId,
                          updatedLangs,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.withValues(alpha: 0.15)
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              lang['label']!,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
