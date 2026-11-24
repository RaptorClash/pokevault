import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/shiny_hunt.dart';
import '../../../providers/shiny_hunt_provider.dart';
import '../../../services/shiny_auto_counter/shiny_auto_counter_service.dart';
import '../../../services/shiny_auto_counter/shiny_slot_state_machine.dart';
import '../../../widgets/universal_poke_image.dart';
import 'dialogs/record_phase_dialog.dart';
import 'dialogs/shiny_auto_counter_setup_sheet.dart';
import 'dialogs/shiny_catch_dialog.dart';
import 'shiny_hunt_counter_screen.dart';
import 'widgets/shiny_auto_counter_bar.dart';

/// Responsive multi-hunt dashboard showing multiple active/paused shiny hunts
/// side-by-side with full manual controls and visual auto-counter slot badges.
class MultiHuntDashboardScreen extends StatelessWidget {
  final ShinyAutoCounterService? autoCounterService;

  const MultiHuntDashboardScreen({
    super.key,
    this.autoCounterService,
  });

  ShinyAutoCounterService get _service =>
      autoCounterService ?? ShinyAutoCounterService.instance;

  @override
  Widget build(BuildContext context) {
    final huntProvider = Provider.of<ShinyHuntProvider>(context);
    final hunts = [
      ...huntProvider.activeHunts,
      ...huntProvider.pausedHunts,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.multi_hunt_dashboard_title),
        actions: [
          if (hunts.isNotEmpty)
            IconButton(
              key: const Key('multi_hunt_setup_btn'),
              icon: const Icon(Icons.center_focus_strong),
              tooltip: t.shiny_auto_btn_tooltip,
              onPressed: () => ShinyAutoCounterSetupSheet.show(
                context,
                hunt: hunts.first,
                service: _service,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: hunts.isEmpty
            ? Center(
                key: const Key('multi_hunt_empty_state'),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        size: 52,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.multi_hunt_empty_title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.multi_hunt_empty_desc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  ShinyAutoCounterBar(
                    service: _service,
                    compact: true,
                    onOpenSetup: () => ShinyAutoCounterSetupSheet.show(
                      context,
                      hunt: hunts.first,
                      service: _service,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols = w >= 1100 ? 3 : (w >= 650 ? 2 : 1);
                        const spacing = 12.0;
                        final cardWidth =
                            (w - 24 - (cols - 1) * spacing) / cols;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: hunts.map((hunt) {
                              return SizedBox(
                                width: cardWidth,
                                child: _MultiHuntCard(
                                  hunt: hunt,
                                  huntProvider: huntProvider,
                                  service: _service,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MultiHuntCard extends StatelessWidget {
  final ShinyHunt hunt;
  final ShinyHuntProvider huntProvider;
  final ShinyAutoCounterService service;

  const _MultiHuntCard({
    required this.hunt,
    required this.huntProvider,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('multi_hunt_card_${hunt.id}'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hunt.isPaused
              ? Colors.amber.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Sprite + Name + Slot assignment
            Row(
              children: [
                UniversalPokeImage(
                  imageUrl:
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/${hunt.effectiveSpriteId}.png',
                  fallbackUrl:
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${hunt.effectiveSpriteId}.png',
                  width: 44,
                  height: 44,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hunt.title.isNotEmpty ? hunt.title : hunt.pokemonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${hunt.game} · ${hunt.method} · 1:${hunt.baseOdds.round()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: t.multi_hunt_open_counter,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ShinyHuntCounterScreen(huntId: hunt.id),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Assigned scan slot badges + quick assign menu
            ValueListenableBuilder<List<ShinySlotSnapshot>>(
              valueListenable: service.slotStatesNotifier,
              builder: (context, slots, _) {
                if (slots.isEmpty) return const SizedBox.shrink();
                final assigned = slots
                    .where((s) => s.assignedHuntId == hunt.id)
                    .toList();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...assigned.map((s) {
                        final color = Color(s.colorHex);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color),
                          ),
                          child: Text(
                            '#${s.slotId}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                      PopupMenuButton<int>(
                        key: Key('multi_hunt_slot_assign_${hunt.id}'),
                        tooltip: t.multi_hunt_slot_assign_label,
                        onSelected: (slotId) {
                          final already =
                              service.settings.slotToHuntOverrides[slotId] ==
                                  hunt.id;
                          service.assignSlotToHunt(
                            slotId,
                            already ? null : hunt.id,
                          );
                        },
                        itemBuilder: (_) => slots.map((s) {
                          final isHere = s.assignedHuntId == hunt.id;
                          return PopupMenuItem<int>(
                            value: s.slotId,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHere
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 16,
                                  color: Color(s.colorHex),
                                ),
                                const SizedBox(width: 8),
                                Text('Slot #${s.slotId}'),
                              ],
                            ),
                          );
                        }).toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '+ ${t.multi_hunt_slot_assign_label}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Counter Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    hunt.currentEncounters.toString(),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Phase ${hunt.phase} · ${hunt.isPaused ? t.shiny_hunt_paused : t.shiny_hunt_status_active}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: hunt.isPaused ? Colors.amber : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Manual Controls (-1, +1, Pause)
            Row(
              children: [
                OutlinedButton(
                  key: Key('multi_hunt_dec_${hunt.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () => huntProvider.decrement(hunt.id),
                  child: Text('-${hunt.incrementStep}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: Key('multi_hunt_inc_${hunt.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                    onPressed: () => huntProvider.increment(hunt.id),
                    child: Text(
                      '+${hunt.incrementStep}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  key: Key('multi_hunt_pause_${hunt.id}'),
                  tooltip: hunt.isPaused
                      ? t.shiny_hunt_resume
                      : t.shiny_hunt_pause,
                  icon: Icon(
                    hunt.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  onPressed: () {
                    if (hunt.isPaused) {
                      huntProvider.resumeHunt(hunt.id);
                    } else {
                      huntProvider.pauseHunt(hunt.id);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Phase & Catch quick actions
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: Text(
                    t.shiny_hunt_record_phase_btn,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => RecordPhaseDialog(hunt: hunt),
                    );
                  },
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.amber.shade700,
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    t.shiny_hunt_caught_btn,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ShinyCatchDialog(hunt: hunt),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
