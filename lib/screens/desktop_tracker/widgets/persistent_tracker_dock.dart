import 'package:flutter/material.dart';
import '../../../models/user_dex.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// A persistent bottom dock bar that remains visible across PokéVault while
/// tracking is active in the background, allowing users to browse their dexes
/// without interrupting OCR tracking or encounter recording.
class PersistentTrackerDock extends StatelessWidget {
  final ScannerEvent? latestEvent;
  final UserDex? activeDex;
  final bool isScanningActive;
  final VoidCallback onOpenHud;
  final VoidCallback onOpenSetup;
  final VoidCallback onTogglePause;
  final VoidCallback? onClose;

  const PersistentTrackerDock({
    super.key,
    this.latestEvent,
    this.activeDex,
    required this.isScanningActive,
    required this.onOpenHud,
    required this.onOpenSetup,
    required this.onTogglePause,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCaught = _isPokemonCaught();
    final event = latestEvent;
    final isShiny = event?.isShiny ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161622) : Colors.grey.shade100,
            border: Border(
              top: BorderSide(
                color: isShiny
                    ? const Color(0xFFFBC02D).withValues(alpha: 0.6)
                    : (isDark ? const Color(0xFF2C2C3E) : Colors.grey.shade300),
                width: isShiny ? 1.5 : 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16, vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Live Status Indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isScanningActive ? Colors.greenAccent : Colors.amberAccent,
                  ),
                ),
                SizedBox(width: isCompact ? 6 : 10),

                // Encounter & Dex info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCompact) ...[
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                event != null
                                    ? '${isShiny ? '✨ ' : ''}${event.matchedName}'
                                    : (isScanningActive ? 'Live-Tracker aktiv' : 'Pausiert'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: (event != null && isShiny)
                                      ? const Color(0xFFFDD835)
                                      : (isDark ? Colors.white : Colors.black87),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (event != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                isCaught ? '✔' : '⚠️',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          event != null
                              ? (isCaught ? 'Gefangen' : 'Fehlt im Ziel-Dex')
                              : (activeDex != null ? 'Ziel: ${activeDex!.title}' : 'Kein Dex'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: event != null
                                ? (isCaught ? Colors.greenAccent : Colors.amberAccent)
                                : (isDark ? Colors.white54 : Colors.black45),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Text(
                              isScanningActive ? 'Live-Tracker aktiv' : 'Pausiert',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (event != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${isShiny ? '✨ ' : ''}${event.matchedName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isShiny
                                        ? const Color(0xFFFDD835)
                                        : (isDark ? Colors.white70 : Colors.black87),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isCaught
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCaught
                                        ? Colors.green.withValues(alpha: 0.4)
                                        : Colors.amber.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isCaught ? '✔ Gefangen' : '⚠️ Fehlt im Ziel-Dex',
                                  style: TextStyle(
                                    color: isCaught ? Colors.greenAccent : Colors.amberAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (activeDex != null)
                          Text(
                            'Ziel-Dex: ${activeDex!.title} (${activeDex!.caughtIds.length} gefangen)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: isCompact ? 4 : 10),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pause Toggle
                    IconButton(
                      key: const Key('btn_dock_toggle_pause'),
                      icon: Icon(
                        isScanningActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        size: 20,
                        color: isScanningActive ? Colors.white70 : Colors.greenAccent,
                      ),
                      tooltip: isScanningActive ? 'Pausieren' : 'Fortsetzen',
                      visualDensity: VisualDensity.compact,
                      onPressed: onTogglePause,
                    ),
                    if (isCompact) ...[
                      IconButton(
                        key: const Key('btn_dock_open_hud'),
                        onPressed: onOpenHud,
                        icon: const Icon(Icons.picture_in_picture_alt, size: 18),
                        tooltip: 'HUD',
                        visualDensity: VisualDensity.compact,
                        color: const Color(0xFFEF5350),
                      ),
                      IconButton(
                        key: const Key('btn_dock_open_setup'),
                        onPressed: onOpenSetup,
                        icon: const Icon(Icons.settings, size: 18),
                        tooltip: 'Setup',
                        visualDensity: VisualDensity.compact,
                        color: const Color(0xFFEF5350),
                      ),
                    ] else ...[
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        key: const Key('btn_dock_open_hud'),
                        onPressed: onOpenHud,
                        icon: const Icon(Icons.picture_in_picture_alt, size: 14),
                        label: const Text('HUD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF5350),
                          side: const BorderSide(color: Color(0xFFEF5350)),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        key: const Key('btn_dock_open_setup'),
                        onPressed: onOpenSetup,
                        icon: const Icon(Icons.settings, size: 14),
                        label: const Text('Setup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF5350),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],

                    if (onClose != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        key: const Key('btn_dock_close'),
                        icon: const Icon(Icons.close, size: 18),
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
