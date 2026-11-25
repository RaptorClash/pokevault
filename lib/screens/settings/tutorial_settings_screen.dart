import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../models/dex_view_models.dart';
import '../../models/pokemon.dart';
import '../../models/tutorial_step.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/tutorial/chapter_demo_dialog.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../services/scanner_core/scanner_launcher_helper.dart';
import '../../utils/notification_helper.dart';
import '../dex/dex_screen.dart';
import '../dex/route_tracker_screen.dart';
import '../home/create_dex_bottom_sheet.dart';
import '../pokemon_info/pokemon_info_screen.dart';
import '../shiny_hunt/multi_hunt_dashboard_screen.dart';
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

    final Color accentColor =
        chapter.isNewInV17 ? Colors.cyan : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: chapter.isNewInV17
              ? accentColor.withValues(alpha: 0.35)
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
                          if (chapter.isNewInV17) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                t.tutorial_new_badge,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
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
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  '${chapter.stepCount} Schritte',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
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
                    FilledButton.tonalIcon(
                      key: Key('tutorial_live_tour_${chapter.id}'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _startChapterLiveTour(context, chapter),
                      icon: const Icon(Icons.rocket_launch_outlined, size: 15),
                      label: Text(
                        t.tutorial_start_live_tour,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChapterLiveTour(
    BuildContext context,
    TutorialChapter chapter,
  ) async {
    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      tutProvider = null;
    }

    await tutProvider?.prepareChapterForLiveReplay(chapter.id);
    TutorialOverlay.resetShowing();
    if (!context.mounted) return;

    DexProvider? dexProvider;
    try {
      dexProvider = Provider.of<DexProvider>(context, listen: false);
    } catch (_) {
      dexProvider = null;
    }

    switch (chapter.id) {
      case 'module_home':
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 'module_create_dex':
        if (dexProvider != null) {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => CreateDexBottomSheet(
              provider: dexProvider!,
              currentFolderId: 'root',
            ),
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        break;
      case 'module_dex_screen':
      case 'module_box_management':
      case 'module_stats_share':
        _openDexOrHome(context);
        break;
      case 'module_pokemon_info':
        if (dexProvider != null && dexProvider.allPokemon.isNotEmpty) {
          final poke = dexProvider.allPokemon.first;
          final entry = DexDisplayEntry(
            pokemon: poke,
            uniqueId: poke.id.toString(),
            displaySuffix: '',
            imageUrl:
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${poke.id}.png',
          );
          final dexId = dexProvider.userDexes.isNotEmpty
              ? dexProvider.userDexes.first.id
              : 'national_overall';
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PokemonInfoScreen(
                entries: [entry],
                initialIndex: 0,
                dexId: dexId,
              ),
            ),
          );
        } else {
          _openDexOrHome(context);
        }
        break;
      case 'module_route_tracker':
        if (dexProvider != null &&
            dexProvider.userDexes.isNotEmpty &&
            dexProvider.allPokemon.isNotEmpty) {
          final poke = dexProvider.allPokemon.first;
          final entry = DexDisplayEntry(
            pokemon: poke,
            uniqueId: poke.id.toString(),
            displaySuffix: '',
            imageUrl:
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${poke.id}.png',
          );
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RouteTrackerScreen(
                liveDex: dexProvider!.userDexes.first,
                displayEntries: [entry],
              ),
            ),
          );
        } else {
          _openDexOrHome(context);
        }
        break;
      case 'module_shiny_hunt':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShinyHuntsHubScreen()),
        );
        break;
      case 'module_controls':
        try {
          tutProvider?.markFeatureAsSeen('controls_guide');
        } catch (_) {}
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ControlsGuideScreen()),
        );
        break;
      case 'module_backup_sync':
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        break;
      case 'module_scanner_mobile':
      case 'module_scanner_desktop':
        ScannerLauncherHelper.openPlatformTracker(
          context,
          allPokemon: dexProvider?.allPokemon ?? const [],
        );
        break;
      case 'module_shiny_auto_counter':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MultiHuntDashboardScreen()),
        );
        break;
    }
  }

  VoidCallback? _getTryInScreenAction(BuildContext context, String chapterId) {
    switch (chapterId) {
      case 'module_shiny_hunt':
        return () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShinyHuntsHubScreen()),
            );
      case 'module_shiny_auto_counter':
        return () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MultiHuntDashboardScreen()),
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
      case 'module_home':
      case 'module_create_dex':
      case 'module_home_screen':
      case 'module_first_steps':
        return () => Navigator.of(context).popUntil((route) => route.isFirst);
      case 'module_scanner_mobile':
      case 'module_scanner_desktop':
        return () {
          try {
            final dexProvider = Provider.of<DexProvider>(context, listen: false);
            ScannerLauncherHelper.openPlatformTracker(
              context,
              allPokemon: dexProvider.allPokemon,
            );
          } catch (_) {}
        };
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
                        key: const Key('tutorial_v17_tour_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await tutProvider.startV17DeltaTour();
                          if (context.mounted) {
                            NotificationHelper.showSuccess(
                              t.tutorial_tour_started,
                            );
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            t.tutorial_v17_tour_btn,
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
                  '${TutorialChapters.visibleForPlatform().length} Kapitel',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Render platform-relevant chapters
          for (final chapter in TutorialChapters.visibleForPlatform())
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
