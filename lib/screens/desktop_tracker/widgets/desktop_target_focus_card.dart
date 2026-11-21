import 'package:flutter/material.dart';

import '../../../models/user_dex.dart';
import '../../../services/desktop_tracker/evolution_chain_helper.dart';
import '../../../services/scanner_core/models/scanner_event.dart';
import '../../../utils/dex_logic_helper.dart';

/// Displays the currently focused single or multi-encounter Pokémon card with
/// dex status badge, evolution status summary, smart alternatives, and catch button.
class DesktopTargetFocusCard extends StatelessWidget {
  final ScannerEvent? latestEvent;
  final List<ScannerEvent> activeFocusEvents;
  final EvolutionCheckStatus? activeEvolutionStatus;
  final UserDex? activeDex;
  final bool isDark;
  final Future<void> Function(
    int pokemonId, {
    required bool isShiny,
    required bool isAlpha,
  }) onMarkCaught;
  final Future<void> Function({
    required int pokemonId,
    required String pokemonName,
  }) onSelectAlternative;

  const DesktopTargetFocusCard({
    super.key,
    required this.latestEvent,
    required this.activeFocusEvents,
    required this.activeEvolutionStatus,
    required this.activeDex,
    required this.isDark,
    required this.onMarkCaught,
    required this.onSelectAlternative,
  });

  @override
  Widget build(BuildContext context) {
    final focusEvents = activeFocusEvents.isNotEmpty
        ? activeFocusEvents
        : (latestEvent != null ? [latestEvent!] : const <ScannerEvent>[]);
    final isMultiEncounter = focusEvents.length > 1;
    final singleEvent = focusEvents.length == 1 ? focusEvents.first : latestEvent;
    final id = singleEvent?.pokemonId;
    final name = singleEvent?.matchedName ?? 'Warte auf Spiel...';
    final isCaught = activeDex != null &&
        id != null &&
        DexLogicHelper.isPokemonCaught(activeDex!, id.toString());
    final isShiny = singleEvent?.isShiny ?? false;

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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Aktueller Live-Fokus',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isMultiEncounter)
                  Container(
                    key: const Key('badge_multi_encounter'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MEHRFACHBEGEGNUNG (${focusEvents.length})',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  )
                else if (singleEvent != null)
                  Text(
                    singleEvent.type.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: singleEvent.type == ScannerEventType.caught
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isMultiEncounter)
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 290
                      ? (constraints.maxWidth - 8) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: focusEvents.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ev = entry.value;
                      final enemyId = ev.pokemonId;
                      final enemyCaught = activeDex != null &&
                          enemyId != null &&
                          DexLogicHelper.isPokemonCaught(
                            activeDex!,
                            enemyId.toString(),
                          );
                      return SizedBox(
                        width: cardWidth,
                        child: Container(
                          key: Key('focus_enemy_card_${enemyId ?? idx}'),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF242432)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: enemyCaught
                                  ? Colors.green.withValues(alpha: 0.35)
                                  : Colors.amber.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1B1B24)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: enemyId != null && enemyId > 0
                                          ? Image.network(
                                              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${ev.isShiny ? 'shiny/' : ''}$enemyId.png',
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                Icons.pets,
                                                size: 18,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.search,
                                              size: 18,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                ev.matchedName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (ev.encounterCount > 1) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.cyanAccent
                                                      .withValues(alpha: 0.16),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '×${ev.encounterCount}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.cyanAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (ev.isShiny) ...[
                                              const SizedBox(width: 3),
                                              const Text(
                                                '✨',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (enemyId != null)
                                          Text(
                                            '#${enemyId.toString().padLeft(3, '0')}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: enemyCaught
                                      ? Colors.green.withValues(alpha: 0.14)
                                      : Colors.amber.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  enemyCaught ? '✓ Im Dex' : '★ Fehlt!',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: enemyCaught
                                        ? Colors.green
                                        : Colors.amber,
                                  ),
                                ),
                              ),
                              if (enemyId != null) ...[
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    key: Key('btn_mark_focus_caught_$enemyId'),
                                    onPressed: () => onMarkCaught(
                                      enemyId,
                                      isShiny: ev.isShiny,
                                      isAlpha: ev.isAlpha,
                                    ),
                                    icon: const Icon(Icons.add, size: 13),
                                    label: const Text(
                                      'Eintragen',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF242432) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF343444)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1B24) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: id != null && id > 0
                            ? Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${isShiny ? 'shiny/' : ''}$id.png',
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.pets, size: 28),
                              )
                            : const Icon(
                                Icons.search,
                                size: 28,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isShiny) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  '✨',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                          if (id != null)
                            Text(
                              '#${id.toString().padLeft(3, '0')}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isCaught
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCaught
                                    ? Colors.green.withValues(alpha: 0.4)
                                    : Colors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isCaught
                                  ? '✓ Im Ziel-Dex gefangen'
                                  : '★ Fehlt im Ziel-Dex!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCaught ? Colors.green : Colors.amber,
                              ),
                            ),
                          ),
                          if (singleEvent != null &&
                              singleEvent.instanceIndex != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(
                                  singleEvent.instanceColorHex ?? 0xFFA855F7,
                                ).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Instanz #${singleEvent.instanceIndex}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (activeEvolutionStatus != null &&
                              activeEvolutionStatus!.hasEvolutions &&
                              activeEvolutionStatus!.pokemonId == id) ...[
                            const SizedBox(height: 4),
                            Container(
                              key: const Key('focus_evolution_status_badge'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (activeEvolutionStatus!
                                            .hasMissingEvolutions
                                        ? Colors.cyanAccent
                                        : Colors.greenAccent)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                activeEvolutionStatus!.summaryLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: activeEvolutionStatus!
                                          .hasMissingEvolutions
                                      ? Colors.cyanAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (singleEvent != null &&
                  singleEvent.alternatives.length > 1) ...[
                const Text(
                  'SMART-ALTERNATIVEN (ANTIPPEN ZUM WECHSELN)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: singleEvent.alternatives.map((alt) {
                    final isCurrent = alt.pokemonId == id;
                    return ActionChip(
                      avatar: Icon(
                        isCurrent ? Icons.check_circle : Icons.swap_horiz,
                        size: 13,
                      ),
                      label: Text(
                        '${alt.canonicalName} ${(alt.confidence * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: isCurrent
                          ? null
                          : () => onSelectAlternative(
                                pokemonId: alt.pokemonId,
                                pokemonName: alt.canonicalName,
                              ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (id != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('btn_mark_caught_in_dex'),
                    onPressed: () => onMarkCaught(
                      id,
                      isShiny: isShiny,
                      isAlpha: singleEvent?.isAlpha ?? false,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      'In "${activeDex?.title ?? "Dex"}" eintragen',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
