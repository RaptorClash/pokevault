import 'package:flutter/material.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// Compact, floating Always-on-Top HUD widget designed to sit next to or over the emulator.
class CompactMiniHud extends StatelessWidget {
  final ScannerEvent? latestEvent;
  final VoidCallback? onExpand;
  final VoidCallback? onMarkCaught;
  final VoidCallback? onEvolve;

  const CompactMiniHud({
    super.key,
    this.latestEvent,
    this.onExpand,
    this.onMarkCaught,
    this.onEvolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = latestEvent?.matchedName ?? 'Warte auf Spiel...';
    final id = latestEvent?.pokemonId;
    final isShiny = latestEvent?.isShiny ?? false;
    final isCaught = latestEvent?.type == ScannerEventType.caught;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isShiny
                ? const Color(0xFFFFB300)
                : (isDark ? const Color(0xFF363645) : Colors.grey.shade300),
            width: isShiny ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PokéVault HUD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (onExpand != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_full, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Dashboard öffnen',
                    onPressed: onExpand,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Content row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141418) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A2A38) : Colors.grey.shade200,
                    ),
                  ),
                  child: Center(
                    child: id != null && id > 0
                        ? Image.network(
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${isShiny ? 'shiny/' : ''}$id.png',
                            errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 24),
                          )
                        : const Icon(Icons.visibility, size: 22, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (id != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '#${id.toString().padLeft(3, '0')}',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isCaught
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isCaught ? '✔ GEFANGEN' : 'FEHLT IM DEX',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isCaught ? Colors.green : Colors.amber.shade700,
                              ),
                            ),
                          ),
                          if (isShiny) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '✨ SHINY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 13),
                    label: const Text('Fang eintragen', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onMarkCaught,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.auto_fix_high, size: 13),
                    label: const Text('Entwickeln', style: TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onEvolve,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
