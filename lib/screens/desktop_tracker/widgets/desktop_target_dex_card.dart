import 'package:flutter/material.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../utils/dex_logic_helper.dart';

/// Displays the selected target Pokédex progress card with a quick-switch button.
class DesktopTargetDexCard extends StatelessWidget {
  final Key? tutorialKey;
  final UserDex? activeDex;
  final DexProvider dexProvider;
  final bool isDark;
  final VoidCallback onChangeDex;

  const DesktopTargetDexCard({
    super.key,
    this.tutorialKey,
    required this.activeDex,
    required this.dexProvider,
    required this.isDark,
    required this.onChangeDex,
  });

  @override
  Widget build(BuildContext context) {
    final cleanedWords = activeDex != null && activeDex!.title.isNotEmpty
        ? activeDex!.title
            .split(RegExp(r'\s+'))
            .map((w) => w.replaceAll(RegExp(r'[^A-Za-z0-9ÄÖÜäöüß]'), ''))
            .where((w) => w.isNotEmpty)
            .toList()
        : const <String>[];
    final initials = cleanedWords.isNotEmpty
        ? cleanedWords.take(2).map((w) => w[0]).join().toUpperCase()
        : 'DX';
    final stats = activeDex != null
        ? DexLogicHelper.computeDexProgress(
            activeDex!,
            allPokemon: dexProvider.allPokemon,
          )
        : const TrackerDexProgress(
            caughtCount: 0,
            totalCount: 1025,
            percent: 0.0,
          );

    return Column(
      key: tutorialKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                t.scanner_target_dex_header,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Flexible(
              child: TextButton(
                key: const Key('btn_change_target_dex'),
                onPressed: onChangeDex,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
                child: Text(
                  t.scanner_change_dex_btn,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF5350),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('card_active_target_dex'),
            borderRadius: BorderRadius.circular(14),
            onTap: onChangeDex,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                activeDex?.title ?? t.scanner_no_dex_selected,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${(stats.percent * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stats.percent,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.black38
                                : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.greenAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.scanner_caught_of_total
                              .replaceAll('{caught}', '${stats.caughtCount}')
                              .replaceAll('{total}', '${stats.totalCount}'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
