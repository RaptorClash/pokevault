import 'package:material_ui/material_ui.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/user_dex.dart';
import '../../../services/desktop_tracker/evolution_chain_helper.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// Horizontal brush selector bar shown when drawing custom scan/focus/multi-instance rectangles.
class MobileDrawBrushBar extends StatelessWidget {
  final CameraBrushTarget activeBrushTarget;
  final List<int> multiSlotIds;
  final bool isEditingRegions;
  final ValueChanged<CameraBrushTarget> onSelectBrushTarget;
  final VoidCallback onAddMultiSlot;
  final ValueChanged<bool> onEditingChanged;

  const MobileDrawBrushBar({
    super.key,
    required this.activeBrushTarget,
    required this.multiSlotIds,
    required this.isEditingRegions,
    required this.onSelectBrushTarget,
    required this.onAddMultiSlot,
    required this.onEditingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('mobile_draw_brush_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Zone A', style: TextStyle(fontSize: 10)),
              selected: activeBrushTarget == CameraBrushTarget.zoneA(),
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onSelectBrushTarget(CameraBrushTarget.zoneA()),
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Zone B (Fokus)', style: TextStyle(fontSize: 10)),
              selected: activeBrushTarget == CameraBrushTarget.zoneB(),
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onSelectBrushTarget(CameraBrushTarget.zoneB()),
            ),
            for (final slotId in multiSlotIds) ...[
              const SizedBox(width: 4),
              ChoiceChip(
                label: Text('#$slotId Scan', style: const TextStyle(fontSize: 10)),
                selected:
                    activeBrushTarget == CameraBrushTarget.multiScan(slotId),
                visualDensity: VisualDensity.compact,
                onSelected: (_) =>
                    onSelectBrushTarget(CameraBrushTarget.multiScan(slotId)),
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: Text('#$slotId Fokus', style: const TextStyle(fontSize: 10)),
                selected:
                    activeBrushTarget == CameraBrushTarget.multiFocus(slotId),
                visualDensity: VisualDensity.compact,
                onSelected: (_) =>
                    onSelectBrushTarget(CameraBrushTarget.multiFocus(slotId)),
              ),
            ],
            const SizedBox(width: 4),
            ActionChip(
              avatar: const Icon(Icons.add, size: 14),
              label: Text(
                t.scanner_mob_instance_btn,
                style: const TextStyle(fontSize: 10),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: onAddMultiSlot,
            ),
            const SizedBox(width: 6),
            FilterChip(
              label: Text(
                isEditingRegions
                    ? t.scanner_mob_editing
                    : t.scanner_mob_locked,
                style: const TextStyle(fontSize: 10),
              ),
              selected: isEditingRegions,
              visualDensity: VisualDensity.compact,
              onSelected: onEditingChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating compact status pill displayed at the bottom of the fullscreen camera feed.
class MobileCompactFocusPill extends StatelessWidget {
  final ScannerEvent event;
  final bool isCaught;
  final EvolutionCheckStatus? evolutionStatus;
  final VoidCallback? onMarkCaught;

  const MobileCompactFocusPill({
    super.key,
    required this.event,
    required this.isCaught,
    required this.evolutionStatus,
    this.onMarkCaught,
  });

  @override
  Widget build(BuildContext context) {
    final pid = event.pokemonId;
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${event.isShiny ? '✨ ' : ''}${event.isAlpha ? '🔥 ' : ''}${event.matchedName}${pid != null ? ' (#$pid)' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (evolutionStatus != null && evolutionStatus!.hasEvolutions)
                    Text(
                      evolutionStatus!.summaryLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (pid != null && onMarkCaught != null)
              TextButton(
                onPressed: onMarkCaught,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor:
                      isCaught ? Colors.greenAccent : Colors.cyanAccent,
                ),
                child: Text(
                  isCaught
                      ? t.scanner_caught_badge_short
                      : t.scanner_dock_add_caught,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible fullscreen bottom bar / expanded tabbed drawer for focus, zones, and feed.
class MobileFullscreenBottomPanel extends StatelessWidget {
  final GlobalKey tutorialKey;
  final bool isExpanded;
  final int eventCount;
  final UserDex? activeDex;
  final double maxHeight;
  final ValueChanged<bool> onExpandedChanged;
  final Widget Function(Widget headerAction) buildTabbedPanel;

  const MobileFullscreenBottomPanel({
    super.key,
    required this.tutorialKey,
    required this.isExpanded,
    required this.eventCount,
    required this.activeDex,
    required this.maxHeight,
    required this.onExpandedChanged,
    required this.buildTabbedPanel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (!isExpanded) {
      return KeyedSubtree(
        key: tutorialKey,
        child: InkWell(
          onTap: () => onExpandedChanged(true),
          child: Container(
            key: const Key('mobile_collapsed_bottom_bar'),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_up, color: colors.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.scanner_mob_drawer_header
                        .replaceAll('{count}', '$eventCount'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurface, fontSize: 12),
                  ),
                ),
                Text(
                  activeDex?.title ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: tutorialKey,
      child: SizedBox(
        height: maxHeight,
        child: buildTabbedPanel(
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () => onExpandedChanged(false),
          ),
        ),
      ),
    );
  }
}
