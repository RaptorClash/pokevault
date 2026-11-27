import 'package:material_ui/material_ui.dart';
import '../../../i18n/strings.g.dart';
import '../../../services/scanner_core/media/visual_shiny_detector.dart';
import '../../../services/shiny_auto_counter/shiny_auto_counter_service.dart';
import '../../../services/shiny_auto_counter/shiny_slot_state_machine.dart';
import '../controllers/shiny_auto_counter_bar_tutorial_controller.dart';

/// Compact live status bar displayed inside Shiny Hunter screens while the
/// visual auto-counter is active.
class ShinyAutoCounterBar extends StatefulWidget {
  final ShinyAutoCounterService service;
  final VoidCallback? onOpenSetup;
  final void Function(String huntId, int slotId)? onMarkShinyCaught;
  final bool compact;
  final String? currentHuntId;
  final String? Function(String huntId)? resolveHuntName;

  const ShinyAutoCounterBar({
    super.key = const Key('shiny_auto_bar'),
    required this.service,
    this.onOpenSetup,
    this.onMarkShinyCaught,
    this.compact = false,
    this.currentHuntId,
    this.resolveHuntName,
  });

  @override
  State<ShinyAutoCounterBar> createState() => _ShinyAutoCounterBarState();
}

class _ShinyAutoCounterBarState extends State<ShinyAutoCounterBar> {
  final ShinyAutoCounterBarTutorialController _tutorialController =
      ShinyAutoCounterBarTutorialController();

  @override
  void initState() {
    super.initState();
    widget.service.isRunningNotifier.addListener(_onRunningChanged);
    _scheduleTutorialCheck();
  }

  @override
  void didUpdateWidget(covariant ShinyAutoCounterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.isRunningNotifier.removeListener(_onRunningChanged);
      widget.service.isRunningNotifier.addListener(_onRunningChanged);
      _scheduleTutorialCheck();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe synchronously to ModalRoute so popping covering modals/sheets
    // reliably triggers didChangeDependencies() for the tutorial check.
    ModalRoute.of(context);
    _scheduleTutorialCheck();
  }

  @override
  void dispose() {
    widget.service.isRunningNotifier.removeListener(_onRunningChanged);
    super.dispose();
  }

  void _onRunningChanged() {
    if (widget.service.isRunningNotifier.value) {
      _scheduleTutorialCheck();
    }
  }

  void _scheduleTutorialCheck() {
    if (!widget.service.isRunningNotifier.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final svc = widget.service;
      final hasSlotsArea =
          svc.slotStatesNotifier.value.isNotEmpty || svc.defaultHuntId != null;
      _tutorialController.maybeShowIfNeeded(
        context: context,
        isMounted: mounted,
        isRunning: svc.isRunningNotifier.value,
        hasSlotsArea: hasSlotsArea,
      );
    });
  }

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
    if (reason.startsWith('sparkleDelay:')) {
      final details = reason.substring('sparkleDelay:'.length);
      return t.shiny_auto_reason_sparkle_delay.replaceAll('{details}', details);
    }
    if (reason.startsWith('colorDeviation:')) {
      final details = reason.substring('colorDeviation:'.length);
      return t.shiny_auto_reason_color_dev.replaceAll('{details}', details);
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

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('shiny_auto_help_dialog'),
        title: Text(t.shiny_auto_help_title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.shiny_auto_help_phases_desc,
                style: const TextStyle(fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 12),
              Text(
                t.shiny_auto_help_gestures_desc,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Theme.of(ctx).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              valueListenable: widget.service.recentLogsNotifier,
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
                            onPressed: widget.service.rearmAllSlots,
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
                                              widget.service.undoEntry(entry.id),
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
    final service = widget.service;
    final compact = widget.compact;
    final currentHuntId = widget.currentHuntId;
    final resolveHuntName = widget.resolveHuntName;
    final onOpenSetup = widget.onOpenSetup;

    return ValueListenableBuilder<bool>(
      valueListenable: service.isRunningNotifier,
      builder: (context, isRunning, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: service.hasPendingSessionNotifier,
          builder: (context, hasPending, _) {
            if (!isRunning) {
              if (!hasPending) return const SizedBox.shrink();
              return Container(
                key: const Key('shiny_auto_pending_banner'),
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.18 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.shiny_auto_pending_banner,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('shiny_auto_pending_cancel_btn'),
                      onPressed: service.cancelPendingSession,
                      child: Text(
                        t.shiny_auto_pending_cancel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            return KeyedSubtree(
              key: _tutorialController.barRootKey,
              child: Container(
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
                    // Top row: Active status + Help + Logs + Undo + Pause + Setup + Stop
                    KeyedSubtree(
                      key: _tutorialController.controlsRowKey,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: service.isPausedNotifier,
                        builder: (context, isPaused, _) {
                          final compactBtnStyle = IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(28, 28),
                            fixedSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                          );
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
                                key: const Key('shiny_auto_help_btn'),
                                style: compactBtnStyle,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: t.shiny_auto_help_tooltip,
                                icon: const Icon(
                                  Icons.help_outline_rounded,
                                  size: 17,
                                ),
                                onPressed: () => _showHelpDialog(context),
                              ),
                              ValueListenableBuilder<List<ShinySlotSnapshot>>(
                                valueListenable: service.slotStatesNotifier,
                                builder: (context, slots, _) {
                                  final needsRearm = slots.any(
                                    (s) =>
                                        s.phase == ShinySlotPhase.counted ||
                                        s.phase == ShinySlotPhase.rearmPending,
                                  );
                                  if (!needsRearm) {
                                    return const SizedBox.shrink();
                                  }
                                  return IconButton(
                                    key: const Key('shiny_auto_bar_rearm_all_btn'),
                                    style: compactBtnStyle,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    tooltip: t.shiny_auto_rearm_all_tooltip,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 17,
                                      color: Colors.lightBlueAccent,
                                    ),
                                    onPressed: service.rearmAllSlots,
                                  );
                                },
                              ),
                              IconButton(
                                key: const Key('shiny_auto_logs_btn'),
                                style: compactBtnStyle,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: t.shiny_auto_logs_tooltip,
                                icon: const Icon(
                                  Icons.history_rounded,
                                  size: 17,
                                ),
                                onPressed: () => _showLogsSheet(context),
                              ),
                              ValueListenableBuilder<List<AutoCountLogEntry>>(
                                valueListenable: service.recentLogsNotifier,
                                builder: (context, logs, _) {
                                  final hasUndoable =
                                      logs.any((e) => !e.undone && e.delta > 0);
                                  return IconButton(
                                    key: const Key('shiny_auto_undo_btn'),
                                    style: compactBtnStyle,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    tooltip: t.shiny_auto_undo,
                                    icon: Icon(
                                      Icons.undo_rounded,
                                      size: 17,
                                      color: hasUndoable
                                          ? Colors.orangeAccent
                                          : Colors.grey,
                                    ),
                                    onPressed: hasUndoable
                                        ? () => service.undoLastCount()
                                        : null,
                                  );
                                },
                              ),
                              IconButton(
                                key: const Key('shiny_auto_pause_btn'),
                                style: compactBtnStyle,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: isPaused
                                    ? t.shiny_hunt_resume
                                    : t.shiny_hunt_pause,
                                icon: Icon(
                                  isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  size: 17,
                                ),
                                onPressed: service.toggleGlobalPause,
                              ),
                              if (onOpenSetup != null)
                                IconButton(
                                  key: const Key('shiny_auto_setup_btn'),
                                  style: compactBtnStyle,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  tooltip: t.shiny_auto_setup_title,
                                  icon:
                                      const Icon(Icons.tune_rounded, size: 17),
                                  onPressed: onOpenSetup,
                                ),
                              IconButton(
                                key: const Key('shiny_auto_stop_btn'),
                                style: compactBtnStyle,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: t.shiny_auto_stop_tooltip,
                                icon: const Icon(
                                  Icons.stop_circle_outlined,
                                  size: 17,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => service.stopSession(),
                              ),
                            ],
                          );
                        },
                      ),
                  ),

                  // Target hunt indicator + quick switch + slot status chips
                  KeyedSubtree(
                    key: _tutorialController.slotsAreaKey,
                    child: ValueListenableBuilder<List<ShinySlotSnapshot>>(
                      valueListenable: service.slotStatesNotifier,
                      builder: (context, slots, _) {
                        final activeHuntId = service.defaultHuntId;
                        final targetHuntName = activeHuntId != null
                            ? resolveHuntName?.call(activeHuntId)
                            : null;
                        final isDifferentHunt = currentHuntId != null &&
                            activeHuntId != null &&
                            currentHuntId != activeHuntId;
                        if (slots.isEmpty &&
                            targetHuntName == null &&
                            !isDifferentHunt) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (targetHuntName != null || isDifferentHunt)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (targetHuntName != null)
                                    Text(
                                      t.shiny_auto_counting_for.replaceAll(
                                        '{name}',
                                        targetHuntName,
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDifferentHunt
                                            ? Colors.amber.shade600
                                            : theme.colorScheme.onSurfaceVariant,
                                        fontWeight: isDifferentHunt
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  if (isDifferentHunt)
                                    ActionChip(
                                      key: const Key(
                                        'shiny_auto_switch_hunt_btn',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      labelStyle: const TextStyle(fontSize: 11),
                                      label: Text(t.shiny_auto_switch_hunt_btn),
                                      onPressed: () => service
                                          .setDefaultHuntId(currentHuntId),
                                    ),
                                ],
                              ),
                            ),
                          if (slots.isNotEmpty)
                            Padding(
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
                                  final isCounted =
                                      slot.phase == ShinySlotPhase.counted;
                                  return Tooltip(
                                    message: t.shiny_auto_slot_chip_tooltip,
                                    child: InkWell(
                                      key: Key(
                                        'shiny_auto_slot_chip_${slot.slotId}',
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () =>
                                          service.togglePauseSlot(slot.slotId),
                                      onLongPress: () =>
                                          service.rearmSlot(slot.slotId),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isShiny
                                              ? Colors.amber
                                                  .withValues(alpha: 0.25)
                                              : color.withValues(
                                                  alpha:
                                                      isPausedSlot ? 0.08 : 0.16,
                                                ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isShiny
                                                ? Colors.amber
                                                : color,
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
                                                color: isShiny
                                                    ? Colors.amber
                                                    : color,
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
                                            if (isCounted) ...[
                                              const SizedBox(width: 4),
                                              InkWell(
                                                key: Key(
                                                  'shiny_auto_slot_rearm_${slot.slotId}',
                                                ),
                                                onTap: () => service
                                                    .rearmSlot(slot.slotId),
                                                child: Tooltip(
                                                  message: t
                                                      .shiny_auto_rearm_single_tooltip
                                                      .replaceAll(
                                                    '{slot}',
                                                    slot.slotId.toString(),
                                                  ),
                                                  child: const Icon(
                                                    Icons.refresh_rounded,
                                                    size: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                    ),
                  ),

                  // Prominent Shiny Alert Banners for ALL Shiny-paused slots
                  ValueListenableBuilder<List<AutoCountLogEntry>>(
                    valueListenable: service.activeShinyAlertsNotifier,
                    builder: (context, alerts, _) {
                      if (alerts.isEmpty) return const SizedBox.shrink();
                      final list = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < alerts.length; i++) ...[
                            _buildShinyAlertCard(
                              context,
                              theme: theme,
                              service: service,
                              alert: alerts[i],
                              isPrimary: i == 0,
                            ),
                          ],
                        ],
                      );
                      if (alerts.length <= 1) return list;
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 170),
                        child: SingleChildScrollView(child: list),
                      );
                    },
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  Widget _buildShinyAlertCard(
    BuildContext context, {
    required ThemeData theme,
    required ShinyAutoCounterService service,
    required AutoCountLogEntry alert,
    required bool isPrimary,
  }) {
    final rawName = alert.pokemonName?.trim();
    final fallbackName = widget.resolveHuntName?.call(alert.huntId)?.trim();
    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (fallbackName != null && fallbackName.isNotEmpty ? fallbackName : '');
    final baseTitle = t.shiny_auto_shiny_alert_title
        .replaceAll('{slot}', alert.slotId.toString());
    final titleText =
        displayName.isNotEmpty ? '$baseTitle · $displayName' : baseTitle;
    final sourceLabel = _sourceLabel(alert.detectionSource);

    return Container(
      key: isPrimary
          ? const Key('shiny_auto_shiny_banner')
          : Key('shiny_auto_shiny_banner_${alert.slotId}'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
              Text(
                titleText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Container(
                key: Key('shiny_auto_shiny_source_${alert.slotId}'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.65),
                  ),
                ),
                child: Text(
                  sourceLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: theme.brightness == Brightness.dark
                        ? Colors.amber.shade200
                        : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              if (widget.onMarkShinyCaught != null && alert.huntId.isNotEmpty)
                FilledButton.tonalIcon(
                  key: Key('shiny_auto_catch_shiny_btn_${alert.slotId}'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                  onPressed: () =>
                      widget.onMarkShinyCaught!(alert.huntId, alert.slotId),
                  icon: const Icon(Icons.catching_pokemon, size: 14),
                  label: Text(
                    t.shiny_auto_shiny_mark_caught,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              FilledButton.tonal(
                key: isPrimary
                    ? const Key('shiny_auto_resume_shiny_btn')
                    : Key('shiny_auto_resume_shiny_btn_${alert.slotId}'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                ),
                onPressed: () => service.resumeShinyPausedSlot(alert.slotId),
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
        ],
      ),
    );
  }

  String _sourceLabel(ShinyDetectionSource? source) {
    return switch (source) {
      ShinyDetectionSource.sparkleDelay => t.shiny_auto_source_sparkle_delay,
      ShinyDetectionSource.colorDeviation => t.shiny_auto_source_color_dev,
      ShinyDetectionSource.ocrText || null => t.shiny_auto_source_ocr,
    };
  }
}
