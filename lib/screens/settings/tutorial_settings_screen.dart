import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pokemon.dart';
import '../../models/tutorial_step.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/tutorial/chapter_demo_dialog.dart';
import '../../utils/notification_helper.dart';
import '../dex/dex_screen.dart';
import '../shiny_hunt/shiny_hunts_hub_screen.dart';
import 'controls_guide_screen.dart';

class TutorialSettingsScreen extends StatelessWidget {
  const TutorialSettingsScreen({super.key});

  void _showResetAllConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.tutorial_replay_all),
        content: Text(
          t.tutorial_reset_confirm_msg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
              await tutProvider.resetAllTutorials();
              NotificationHelper.showSuccess(
                t.tutorial_reset_success,
              );
            },
            child: Text(t.reset),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(
    BuildContext context,
    TutorialChapter chapter,
    bool isCompleted,
  ) {
    final theme = Theme.of(context);

    Color accentColor;
    if (chapter.isNewInV16) {
      accentColor = Colors.amber;
    } else {
      accentColor = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: chapter.isNewInV16
              ? Colors.amber.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(chapter.icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (t[chapter.titleKey] ?? chapter.titleKey),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          if (chapter.isNewInV16) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'NEU (v1.6)',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (t[chapter.descKey] ?? chapter.descKey),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${chapter.stepCount} Schritte',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    ChapterDemoDialog.show(
                      context,
                      chapter,
                      onTryInScreen: _getTryInScreenAction(context, chapter.id),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: Text(
                    t.tutorial_replay,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _getTryInScreenAction(BuildContext context, String chapterId) {
    switch (chapterId) {
      case 'module_shiny_hunt':
        return () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShinyHuntsHubScreen()),
            );
      case 'module_controls':
        return () {
          try {
            Provider.of<TutorialProvider>(context, listen: false)
                .markFeatureAsSeen('controls_guide');
          } catch (_) {}
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ControlsGuideScreen()),
          );
        };
      case 'module_backup_sync':
        return () {
          try {
            final tut = Provider.of<TutorialProvider>(context, listen: false);
            tut.markFeatureAsSeen('cloud_sync');
            tut.markFeatureAsSeen('data_backup');
          } catch (_) {}
          Navigator.of(context).pop();
        };
      case 'module_route_tracker':
      case 'module_dex_screen':
      case 'module_box_management':
      case 'module_stats_share':
      case 'module_pokemon_info':
        return () => _openDexOrHome(context);
      case 'module_home_screen':
      case 'module_first_steps':
        return () => Navigator.of(context).popUntil((route) => route.isFirst);
      default:
        return null;
    }
  }

  void _openDexOrHome(BuildContext context) {
    DexProvider? dexProvider;
    try {
      dexProvider = Provider.of<DexProvider>(context, listen: false);
    } catch (_) {
      dexProvider = null;
    }

    if (dexProvider != null && dexProvider.userDexes.isNotEmpty) {
      final dex = dexProvider.userDexes.first;
      List<int> selectedOrder = dexProvider.allAvailableDexes[dex.region] ?? [];
      if (dex.region == 'custom_empty' || selectedOrder.isEmpty) {
        selectedOrder = dexProvider.allAvailableDexes['national_overall'] ?? [];
      }
      final pokemonMap = {for (var p in dexProvider.allPokemon) p.id: p};
      final selectedDatabase = selectedOrder
          .map(
            (id) =>
                pokemonMap[id] ??
                Pokemon(
                  id: id,
                  nameDe: 'Unbekannt',
                  nameEn: 'Unknown',
                  hasGenderDifferences: false,
                  genderRate: -1,
                  captureRate: 255,
                  evolutionChainId: -1,
                  eggGroups: const [],
                  weight: 0.0,
                  speed: 0,
                  forms: const [],
                ),
          )
          .toList();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DexScreen(
            initialDex: dex,
            pokemonList: selectedDatabase,
          ),
        ),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tutProvider = context.watch<TutorialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.tutorial_menu_title),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Hero header banner
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.school, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.tutorial_center_title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.tutorial_center_subtitle,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await tutProvider.startV16DeltaTour();
                          if (context.mounted) {
                            NotificationHelper.showSuccess(
                              t.tutorial_tour_started,
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            t.tutorial_v16_tour_btn,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showResetAllConfirmDialog(context),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            t.tutorial_replay_all,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chapters Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.tutorial_chapters_header,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${TutorialChapters.all.length} Kapitel',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Render all 9 chapters
          for (final chapter in TutorialChapters.all)
            _buildChapterCard(
              context,
              chapter,
              tutProvider.isChapterCompleted(chapter.id),
            ),
        ],
      ),
    );
  }
}
