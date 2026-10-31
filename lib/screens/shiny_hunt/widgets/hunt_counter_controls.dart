import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';

/// Control buttons and step-increment chips for [ShinyHuntCounterScreen].
class HuntCounterControls extends StatelessWidget {
  final int currentEncounters;
  final int incrementStep;
  final int? customStep;
  final Key? buttonsKey;
  final Key? phasesActionsKey;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onStepSelected;
  final VoidCallback onCustomStepPressed;
  final VoidCallback onRecordPhase;
  final VoidCallback onCaught;

  const HuntCounterControls({
    super.key,
    required this.currentEncounters,
    required this.incrementStep,
    this.customStep,
    this.buttonsKey,
    this.phasesActionsKey,
    required this.onIncrement,
    required this.onDecrement,
    required this.onStepSelected,
    required this.onCustomStepPressed,
    required this.onRecordPhase,
    required this.onCaught,
  });

  @override
  Widget build(BuildContext context) {
    final customStepVal = customStep ?? (![1, 5, 10].contains(incrementStep) ? incrementStep : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Schrittweiten-Leiste
        Padding(
          key: buttonsKey ?? const Key('_buttonsKey'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...[1, 5, 10].map((step) {
                  final isSel = incrementStep == step;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('+$step'),
                      selected: isSel,
                      onSelected: (_) => onStepSelected(step),
                    ),
                  );
                }),
                if (customStepVal != null && ![1, 5, 10].contains(customStepVal))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('+$customStepVal'),
                      selected: incrementStep == customStepVal,
                      onSelected: (_) => onStepSelected(customStepVal),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    avatar: const Icon(Icons.edit, size: 14),
                    label: Text(t.shiny_hunt_step_custom),
                    onPressed: onCustomStepPressed,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Button-Leiste: Minus (-), Phasen-Shiny, Fang, Plus (+)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Minus Button
              IconButton.filledTonal(
                iconSize: 28,
                onPressed: currentEncounters > 0 ? onDecrement : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8),

              // Phasen-Shiny & Shiny Gefangen
              Expanded(
                flex: 3,
                child: Container(
                  key: phasesActionsKey ?? const Key('_phasesActionsKey'),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: onRecordPhase,
                          icon: const Icon(Icons.history_toggle_off, size: 18),
                          label: Text(
                            t.shiny_hunt_record_phase_btn,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: onCaught,
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(
                            t.shiny_hunt_caught_btn,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Plus Button
              IconButton.filled(
                iconSize: 28,
                onPressed: onIncrement,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
