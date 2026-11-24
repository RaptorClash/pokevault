import 'package:material_ui/material_ui.dart';
import '../../../i18n/strings.g.dart';
import '../../../services/shiny_auto_counter/shiny_auto_counter_service.dart';
import '../../../services/shiny_auto_counter/shiny_slot_state_machine.dart';

/// Compact live status bar displayed inside Shiny Hunter screens while the
/// visual auto-counter is active.
class ShinyAutoCounterBar extends StatelessWidget {
  final ShinyAutoCounterService service;
  final VoidCallback? onOpenSetup;
  final bool compact;

  const ShinyAutoCounterBar({
    super.key = const Key('shiny_auto_bar'),
    required this.service,
    this.onOpenSetup,
    this.compact = false,
  });

  String _phaseLabel(ShinySlotPhase phase) {
    return switch (phase) {
      ShinySlotPhase.armed => t.shiny_auto_slot_armed,
      ShinySlotPhase.counted => t.shiny_auto_slot_counted,
      ShinySlotPhase.rearmPending => t.shiny_auto_slot_rearm,
      ShinySlotPhase.pausedByShiny => t.shiny_auto_slot_shiny,
      ShinySlotPhase.pausedManual => t.shiny_auto_slot_paused,
    };
  }

  String _formatReason(String reason) {
    if (reason == 'black_screen_reset') return t.shiny_auto_reason_black_reset;
    if (reason == 'white_screen_reset') return t.shiny_auto_reason_white_reset;
    if (reason == 'egg_oh_prompt') return t.shiny_auto_reason_egg_oh;
    if (reason.startsWith('shiny:')) {
      final name = reason.substring('shiny:'.length);
      return t.shiny_auto_reason_shiny.replaceAll('{name}', name);
    }
    if (reason.startsWith('ocr:')) {
      return 'OCR: ${reason.substring('ocr:'.length)}';
    }
    return reason;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showLogsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return SafeArea(
          child: SizedBox(
            key: const Key('shiny_auto_logs_sheet'),
            height: MediaQuery.sizeOf(sheetCtx).height * 0.6,
            child: ValueListenableBuilder<List<AutoCountLogEntry>>(
              valueListenable: service.recentLogsNotifier,
              builder: (context, logs, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.multi_hunt_logs_title.replaceAll(
                                '{count}',
                                logs.length.toString(),
                              ),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('shiny_auto_rearm_all_btn'),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              t.shiny_auto_rearm_all_btn,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: service.rearmAllSlots,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: logs.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  t.shiny_auto_logs_empty,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: logs.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final entry = logs[index];
                                final slotColor = Color(entry.colorHex);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: entry.undone
                                        ? theme.colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.25)
                                        : (entry.isShiny
                                            ? Colors.amber
                                                .withValues(alpha: 0.16)
                                            : theme.colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.5)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: entry.isShiny && !entry.undone
                                          ? Colors.amber
                                          : theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              slotColor.withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(color: slotColor),
                                        ),
                                        child: Text(
                                          '#${entry.slotId}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '+${entry.delta} · ${_formatReason(entry.reason)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                decoration: entry.undone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            Text(
                                              entry.undone
                                                  ? '${_formatTime(entry.timestamp)} · ${t.shiny_auto_logs_undone}'
                                                  : _formatTime(
                                                      entry.timestamp,
                                                    ),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!entry.undone && entry.delta > 0)
                                        TextButton(
                                          key: Key(
                                            'shiny_auto_log_undo_$index',
                                          ),
                                          onPressed: () =>
                                              service.undoEntry(entry.id),
                                          child: Text(t.shiny_auto_undo),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: service.isRunningNotifier,
      builder: (context, isRunning, _) {
        if (!isRunning) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blueGrey.shade900.withValues(alpha: 0.92)
                : Colors.indigo.shade50.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: Active status + Pause + Undo + Setup + Stop
              ValueListenableBuilder<bool>(
                valueListenable: service.isPausedNotifier,
                builder: (context, isPaused, _) {
                  return ValueListenableBuilder<List<AutoCountLogEntry>>(
                    valueListenable: service.recentLogsNotifier,
                    builder: (context, logs, _) {
                      final hasUndoable = logs.any((e) => !e.undone);
                      return Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPaused
                                  ? Colors.amber
                                  : Colors.greenAccent.shade400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isPaused
                                  ? t.shiny_auto_bar_paused
                                  : t.shiny_auto_bar_active,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('shiny_auto_logs_btn'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: t.shiny_auto_logs_tooltip,
                            icon: const Icon(
                              Icons.history_rounded,
                              size: 18,
                            ),
                            onPressed: () => _showLogsSheet(context),
                          ),
                          IconButton(
                            key: const Key('shiny_auto_undo_btn'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: t.shiny_auto_undo,
                            icon: Icon(
                              Icons.undo_rounded,
                              size: 18,
                              color: hasUndoable
                                  ? Colors.orangeAccent
                                  : Colors.grey,
                            ),
                            onPressed: hasUndoable
                                ? () => service.undoLastCount()
                                : null,
                          ),
                          IconButton(
                            key: const Key('shiny_auto_pause_btn'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: isPaused
                                ? t.shiny_hunt_resume
                                : t.shiny_hunt_pause,
                            icon: Icon(
                              isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              size: 18,
                            ),
                            onPressed: service.toggleGlobalPause,
                          ),
                          if (onOpenSetup != null)
                            IconButton(
                              key: const Key('shiny_auto_setup_btn'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: t.shiny_auto_setup_title,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              onPressed: onOpenSetup,
                            ),
                          IconButton(
                            key: const Key('shiny_auto_stop_btn'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: t.shiny_auto_stop_tooltip,
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => service.stopSession(),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              // Slot status chips
              ValueListenableBuilder<List<ShinySlotSnapshot>>(
                valueListenable: service.slotStatesNotifier,
                builder: (context, slots, _) {
                  if (slots.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: slots.map((slot) {
                        final color = Color(slot.colorHex);
                        final isShiny =
                            slot.phase == ShinySlotPhase.pausedByShiny;
                        final isPausedSlot =
                            slot.phase == ShinySlotPhase.pausedManual;
                        return Tooltip(
                          message: t.shiny_auto_slot_chip_tooltip,
                          child: InkWell(
                            key: Key('shiny_auto_slot_chip_${slot.slotId}'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => service.togglePauseSlot(slot.slotId),
                            onLongPress: () => service.rearmSlot(slot.slotId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isShiny
                                    ? Colors.amber.withValues(alpha: 0.25)
                                    : color.withValues(
                                        alpha: isPausedSlot ? 0.08 : 0.16,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isShiny ? Colors.amber : color,
                                  width: isShiny ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isShiny ? Colors.amber : color,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '#${slot.slotId} · ${_phaseLabel(slot.phase)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isShiny
                                          ? Colors.amber.shade700
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              // Prominent Shiny Alert Banner when a Shiny signal occurred
              ValueListenableBuilder<AutoCountLogEntry?>(
                valueListenable: service.latestShinyAlertNotifier,
                builder: (context, shinyAlert, _) {
                  if (shinyAlert == null) return const SizedBox.shrink();
                  return Container(
                    key: const Key('shiny_auto_shiny_banner'),
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                t.shiny_auto_shiny_alert_title.replaceAll(
                                  '{slot}',
                                  shinyAlert.slotId.toString(),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        FilledButton.tonal(
                          key: const Key('shiny_auto_resume_shiny_btn'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          onPressed: () => service
                              .resumeShinyPausedSlot(shinyAlert.slotId),
                          child: Text(
                            t.shiny_auto_shiny_alert_resume,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
