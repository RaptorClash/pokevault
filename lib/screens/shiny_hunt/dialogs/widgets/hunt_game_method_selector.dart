import 'package:flutter/material.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../utils/shiny_hunt_odds_helper.dart';

/// Game, method and shiny charm selector section for [CreateEditHuntDialog].
class HuntGameMethodSelector extends StatelessWidget {
  final String selectedGame;
  final List<String> availableGames;
  final Map<String, String>? gameLabels;
  final bool showGameSelector;
  final double generation;
  final String? selectedMethod;
  final List<ShinyMethodPreset> availablePresets;
  final bool hasShinyCharm;
  final String? specialNote;
  final Key? sectionKey;

  final ValueChanged<String?> onGameChanged;
  final VoidCallback? onToggleGameSelector;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<bool> onShinyCharmChanged;

  const HuntGameMethodSelector({
    super.key,
    required this.selectedGame,
    required this.availableGames,
    this.gameLabels,
    this.showGameSelector = true,
    this.generation = 9.0,
    required this.selectedMethod,
    required this.availablePresets,
    required this.hasShinyCharm,
    this.specialNote,
    this.sectionKey,
    required this.onGameChanged,
    this.onToggleGameSelector,
    required this.onMethodChanged,
    required this.onShinyCharmChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGame = availableGames.contains(selectedGame)
        ? selectedGame
        : (availableGames.isNotEmpty ? availableGames.first : null);

    final effectiveMethod = availablePresets.any((p) => p.name == selectedMethod)
        ? selectedMethod
        : (availablePresets.isNotEmpty ? availablePresets.first.name : null);

    return KeyedSubtree(
      key: sectionKey ?? const Key('_gameMethodSectionKey'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2. Spiel / Edition & Smart Skip
          if (!showGameSelector && onToggleGameSelector != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_esports, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Spiel: $selectedGame (Gen ${generation.toString().replaceAll('.0', '')})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: onToggleGameSelector,
                    child: const Text('Ändern'),
                  ),
                ],
              ),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: ValueKey('game-$selectedGame-$generation-${availableGames.length}'),
              initialValue: effectiveGame,
              decoration: InputDecoration(
                labelText: t.shiny_hunt_game,
                border: const OutlineInputBorder(),
              ),
              items: availableGames.map((gameName) {
                return DropdownMenuItem<String>(
                  value: gameName,
                  child: Text(
                    gameLabels?[gameName] ?? gameName,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onGameChanged,
            ),
          ],
          const SizedBox(height: 12),

          // 3. Methode Dropdown
          DropdownButtonFormField<String>(
            isExpanded: true,
            key: ValueKey('method-$selectedMethod-${availablePresets.length}'),
            initialValue: effectiveMethod,
            decoration: InputDecoration(
              labelText: t.shiny_hunt_method,
              border: const OutlineInputBorder(),
            ),
            items: availablePresets.map((preset) {
              return DropdownMenuItem<String>(
                value: preset.name,
                child: Text(
                  preset.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: 12),

          // Schillerpin Schalter (ab Gen 5 bzw. BDSP)
          if (generation >= 5.0 || ShinyHuntOddsHelper.isBDSP(selectedGame)) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.shiny_hunt_has_charm),
              secondary: const Icon(Icons.flare, color: Colors.amber),
              value: hasShinyCharm,
              onChanged: onShinyCharmChanged,
            ),
          ],

          // Hinweistext (z. B. BDSP Bug)
          if (specialNote != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      specialNote!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
