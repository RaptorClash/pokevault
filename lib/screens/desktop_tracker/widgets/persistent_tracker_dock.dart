import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/database_service.dart';
import '../../../services/desktop_tracker/desktop_tracker_service.dart';
import '../../../services/scanner_core/models/scanner_event.dart';
import '../../../utils/tracker_platform_helper.dart';

/// A persistent bottom dock bar that remains visible across PokéVault while
/// tracking is active in the background, allowing users to browse their dexes
/// without interrupting OCR tracking or encounter recording.
class PersistentTrackerDock extends StatelessWidget {
  final ScannerEvent? latestEvent;
  final UserDex? activeDex;
  final bool isScanningActive;
  final bool isHudVisible;
  final String? activeSourceTitle;
  final VoidCallback onOpenHud;
  final VoidCallback onOpenSetup;
  final VoidCallback onTogglePause;
  final VoidCallback? onMarkCaught;
  final VoidCallback? onClose;

  const PersistentTrackerDock({
    super.key,
    this.latestEvent,
    this.activeDex,
    required this.isScanningActive,
    this.isHudVisible = false,
    this.activeSourceTitle,
    required this.onOpenHud,
    required this.onOpenSetup,
    required this.onTogglePause,
    this.onMarkCaught,
    this.onClose,
  });

  bool _isPokemonCaught() {
    final event = latestEvent;
    final dex = activeDex;
    if (event == null || dex == null || event.pokemonId == null) return false;
    return dex.caughtIds.contains(event.pokemonId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCaught = _isPokemonCaught();
    final event = latestEvent;
    final isShiny = event?.isShiny ?? false;
    final statusColor =
        isScanningActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 540;
        final isVeryCompact = constraints.maxWidth < 380;

        return SafeArea(
          top: false,
          child: Container(
            margin: isVeryCompact
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(12, 0, 12, 10),
            padding: EdgeInsets.symmetric(
              horizontal: isVeryCompact ? 10 : 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1B26) : colors.surfaceContainerHigh,
              borderRadius: isVeryCompact
                  ? const BorderRadius.vertical(top: Radius.circular(14))
                  : BorderRadius.circular(16),
              border: Border.all(
                color: isShiny
                    ? const Color(0xFFFBC02D).withValues(alpha: 0.7)
                    : (isScanningActive
                        ? statusColor.withValues(alpha: 0.35)
                        : colors.outlineVariant),
                width: isShiny ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Status Pill (LIVE / PAUSIERT)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVeryCompact ? 6 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
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
                          color: statusColor,
                        ),
                      ),
                      if (!isVeryCompact) ...[
                        const SizedBox(width: 5),
                        Text(
                          isScanningActive ? 'LIVE' : 'PAUSIERT',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: isVeryCompact ? 8 : 12),

                // Encounter & Target Dex Info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              event != null
                                  ? '${isShiny ? '✨ ' : ''}${event.matchedName}${event.pokemonId != null && !isVeryCompact ? ' (#${event.pokemonId})' : ''}'
                                  : (isScanningActive
                                      ? 'Live-Tracker aktiv'
                                      : 'Tracker pausiert'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: (event != null && isShiny)
                                    ? const Color(0xFFFDD835)
                                    : colors.onSurface,
                                fontSize: isVeryCompact ? 11.5 : 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (event != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: (isCaught
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B))
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isCaught
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                isVeryCompact
                                    ? (isCaught ? '✔' : '!')
                                    : (isCaught ? '✔ Gefangen' : 'Fehlt im Ziel-Dex'),
                                style: TextStyle(
                                  color: isCaught
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFFBBF24),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        [
                          if (activeDex != null)
                            'Ziel-Dex: ${activeDex!.title} (${activeDex!.caughtIds.length} gefangen)',
                          if (!isCompact &&
                              activeSourceTitle != null &&
                              activeSourceTitle!.trim().isNotEmpty)
                            activeSourceTitle!.trim(),
                        ].join(' · '),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: isVeryCompact ? 9.5 : 11,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: isVeryCompact ? 4 : 10),

                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (event != null &&
                        !isCaught &&
                        event.pokemonId != null &&
                        onMarkCaught != null &&
                        !isVeryCompact) ...[
                      FilledButton.tonalIcon(
                        key: const Key('btn_dock_mark_caught'),
                        onPressed: onMarkCaught,
                        icon: const Icon(Icons.catching_pokemon, size: 14),
                        label: const Text(
                          '+ Eintragen',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.18),
                          foregroundColor: const Color(0xFF34D399),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    IconButton.filledTonal(
                      key: const Key('btn_dock_toggle_pause'),
                      onPressed: onTogglePause,
                      tooltip: isScanningActive ? 'Pausieren' : 'Fortsetzen',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isScanningActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                        color: isScanningActive
                            ? colors.onSurface
                            : const Color(0xFF34D399),
                      ),
                    ),
                    if (isCompact) ...[
                      const SizedBox(width: 2),
                      IconButton.filledTonal(
                        key: const Key('btn_dock_open_hud'),
                        onPressed: onOpenHud,
                        tooltip: isHudVisible ? 'HUD ausblenden' : 'HUD öffnen',
                        visualDensity: VisualDensity.compact,
                        style: isHudVisible
                            ? IconButton.styleFrom(
                                backgroundColor: const Color(0xFF06B6D4).withValues(alpha: 0.22),
                                foregroundColor: const Color(0xFF22D3EE),
                              )
                            : null,
                        icon: const Icon(Icons.picture_in_picture_alt, size: 17),
                      ),
                      const SizedBox(width: 2),
                      IconButton.filled(
                        key: const Key('btn_dock_open_setup'),
                        onPressed: onOpenSetup,
                        tooltip: 'Scanner-Setup öffnen',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                        ),
                        icon: const Icon(Icons.tune, size: 17),
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      if (isHudVisible)
                        FilledButton.tonalIcon(
                          key: const Key('btn_dock_open_hud'),
                          onPressed: onOpenHud,
                          icon: const Icon(Icons.picture_in_picture_alt, size: 14),
                          label: const Text(
                            'HUD aktiv',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                            foregroundColor: const Color(0xFF22D3EE),
                            side: BorderSide(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          key: const Key('btn_dock_open_hud'),
                          onPressed: onOpenHud,
                          icon: const Icon(Icons.picture_in_picture_alt, size: 14),
                          label: const Text(
                            'HUD',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.onSurface,
                            side: BorderSide(color: colors.outlineVariant),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        key: const Key('btn_dock_open_setup'),
                        onPressed: onOpenSetup,
                        icon: const Icon(Icons.tune, size: 14),
                        label: const Text(
                          'Setup',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                    if (onClose != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        key: const Key('btn_dock_close'),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        tooltip: 'Tracker beenden',
                        visualDensity: VisualDensity.compact,
                        onPressed: onClose,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shared reactive host that binds [PersistentTrackerDock] to
/// [DesktopTrackerService.instance] for top-level desktop navigation screens.
class PersistentTrackerDockHost extends StatelessWidget {
  final VoidCallback onOpenSetup;
  final UserDex? fallbackDex;

  const PersistentTrackerDockHost({
    super.key,
    required this.onOpenSetup,
    this.fallbackDex,
  });

  Future<void> _handleMarkCaught(
    BuildContext context,
    UserDex activeDex,
    ScannerEvent event,
  ) async {
    final service = DesktopTrackerService.instance;
    if (service.hasMarkCaughtHandler) {
      await service.markLatestEventCaught();
      return;
    }
    final pid = event.pokemonId;
    if (pid == null) return;
    final idStr = pid.toString();
    if (!activeDex.caughtIds.contains(idStr)) {
      activeDex.caughtIds.add(idStr);
    }
    if (event.isShiny && !activeDex.shinyIds.contains(idStr)) {
      activeDex.shinyIds.add(idStr);
    }
    if (event.isAlpha && !activeDex.alphaIds.contains(idStr)) {
      activeDex.alphaIds.add(idStr);
    }
    try {
      await DatabaseService.instance.savePokemonStatus(
        activeDex.id,
        idStr,
        isCaught: true,
        isShiny: event.isShiny ? true : null,
        isAlpha: event.isAlpha ? true : null,
      );
    } catch (_) {}
    if (!context.mounted) return;
    await Provider.of<DexProvider>(context, listen: false)
        .saveUserDexAndSync(activeDex);
  }

  @override
  Widget build(BuildContext context) {
    final service = DesktopTrackerService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        service.isTrackingNotifier,
        service.latestEventNotifier,
        service.isPausedNotifier,
        service.showFloatingHudNotifier,
      ]),
      builder: (context, _) {
        if (!TrackerPlatformHelper.isDesktop || !service.isTrackingActive) {
          return const SizedBox.shrink();
        }
        final dexProvider = Provider.of<DexProvider>(context);
        final activeDexId = service.activeDexId;
        final activeDex = dexProvider.userDexes
                .where((d) => d.id == activeDexId)
                .firstOrNull ??
            fallbackDex;
        final latestEvent = service.latestEvent;

        return PersistentTrackerDock(
          latestEvent: latestEvent,
          activeDex: activeDex,
          isScanningActive: !service.isPaused,
          isHudVisible: service.showFloatingHud,
          activeSourceTitle: service.activeWindow?.title,
          onMarkCaught: (latestEvent?.pokemonId != null && activeDex != null)
              ? () => _handleMarkCaught(context, activeDex, latestEvent!)
              : null,
          onOpenHud: () => service.toggleFloatingHud(),
          onOpenSetup: onOpenSetup,
          onTogglePause: () => service.togglePause(),
          onClose: () => service.stopTracking(),
        );
      },
    );
  }
}
