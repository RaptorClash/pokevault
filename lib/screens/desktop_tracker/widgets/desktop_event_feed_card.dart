import 'package:material_ui/material_ui.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/user_dex.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// Right-column live event feed displaying detected Pokémon catches,
/// encounters, evolutions, and quick edit / add-to-dex actions.
class DesktopEventFeedCard extends StatelessWidget {
  final GlobalKey tutorialKey;
  final List<ScannerEvent> events;
  final UserDex? activeDex;
  final bool isDark;
  final VoidCallback onClearEvents;
  final ValueChanged<int> onEditEvent;
  final Future<void> Function(
    int pokemonId, {
    required bool isShiny,
    required bool isAlpha,
  }) onMarkCaught;

  const DesktopEventFeedCard({
    super.key,
    required this.tutorialKey,
    required this.events,
    required this.activeDex,
    required this.isDark,
    required this.onClearEvents,
    required this.onEditEvent,
    required this.onMarkCaught,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyedSubtree(
              key: tutorialKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 18),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Live-Ereignisse',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${events.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (events.isNotEmpty)
                    TextButton.icon(
                      onPressed: onClearEvents,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label:
                          const Text('Leeren', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.catching_pokemon,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Warte auf In-Game Ereignisse...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Wähle dein Emulator-Fenster aus. Fänge und Begegnungen werden automatisch erkannt.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ev = events[index];
                        final isCaught = activeDex != null &&
                            ev.pokemonId != null &&
                            activeDex!.caughtIds
                                .contains(ev.pokemonId.toString());

                        return _buildEventTile(ev, index, isCaught);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(ScannerEvent ev, int index, bool isCaught) {
    final id = ev.pokemonId;
    final isShiny = ev.isShiny;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF343444) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B24) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: id != null && id > 0
                  ? Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${isShiny ? 'shiny/' : ''}$id.png',
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.pets, size: 20),
                    )
                  : const Icon(Icons.help_outline, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      ev.matchedName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (ev.instanceIndex != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Color(ev.instanceColorHex ?? 0xFFA855F7)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '#${ev.instanceIndex}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (isShiny) const Text('✨'),
                    _buildEventTypeBadge(ev.type),
                    if (ev.isSmartMatch)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'SMART ${(ev.confidence * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ev.rawText.replaceAll('\n', ' · '),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                key: Key('btn_edit_event_$index'),
                tooltip: 'Ereignis korrigieren',
                onPressed: () => onEditEvent(index),
                icon: const Icon(Icons.edit_outlined, size: 16),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              if (id != null)
                isCaught
                    ? const Text(
                        '✓ Im Dex',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => onMarkCaught(
                          id,
                          isShiny: isShiny,
                          isAlpha: ev.isAlpha,
                        ),
                        child: const Text(
                          '+ Eintragen',
                          style: TextStyle(
                            fontSize: 10,
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

  Widget _buildEventTypeBadge(ScannerEventType type) {
    Color bg;
    Color fg;
    String label;

    switch (type) {
      case ScannerEventType.caught:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green;
        label = 'FANG';
        break;
      case ScannerEventType.encounter:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        label = 'BEGEGNUNG';
        break;
      case ScannerEventType.evolved:
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        label = 'ENTWICKLUNG';
        break;
      case ScannerEventType.shinyDetected:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber;
        label = 'SHINY';
        break;
      case ScannerEventType.alphaDetected:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red;
        label = 'ALPHA';
        break;
      case ScannerEventType.eggHatched:
        bg = Colors.teal.withValues(alpha: 0.15);
        fg = Colors.teal;
        label = t.scanner_event_egg_hatched_badge;
        break;
      case ScannerEventType.softReset:
      case ScannerEventType.customReset:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange;
        label = 'RESET';
        break;
      case ScannerEventType.unknown:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = 'INFO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
