import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/shiny_hunt.dart';
import '../../../utils/shiny_hunt_odds_helper.dart';

/// Cockpit card displaying real-time shiny probabilities, classification,
/// hunt duration timer, pace and pause/resume button for [ShinyHuntCounterScreen].
class HuntOddsCard extends StatelessWidget {
  final ShinyHunt hunt;
  final VoidCallback? onTogglePause;
  final double? pace;

  const HuntOddsCard({
    super.key,
    required this.hunt,
    this.onTogglePause,
    this.pace,
  });

  static String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static double calculatePacePerHour(int encounters, int totalSeconds) {
    if (totalSeconds < 10) return 0.0;
    return (encounters / totalSeconds) * 3600.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pProb = ShinyHuntOddsHelper.calculateEffectiveProbability(hunt);
    final qProb = ShinyHuntOddsHelper.calculateEffectiveComplementProbability(hunt);
    final ratio = ShinyHuntOddsHelper.calculateOddsRatio(
      hunt.currentPhaseRolls,
      hunt.baseOdds,
    );
    final classification = ShinyHuntOddsHelper.getClassification(
      hunt.currentPhaseRolls,
      hunt.baseOdds,
    );

    final effectivePace = pace ?? calculatePacePerHour(hunt.totalEncounters, hunt.totalTimeSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: classification.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: classification.color, width: 1.5),
            ),
            child: Text(
              classification.label,
              style: TextStyle(
                color: classification.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(pProb * 100.0).toStringAsFixed(1)}% ${t.shiny_hunt_chance_at_least_one}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(qProb * 100.0).toStringAsFixed(1)}% ${t.shiny_hunt_chance_none_yet} • ${ratio.toStringAsFixed(2)}x Odds',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Zeit & Pace
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hunt.isCompleted && onTogglePause != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: Icon(
                    hunt.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 18,
                  ),
                  label: Text(
                    hunt.isPaused
                        ? t.shiny_hunt_resume_hunt_btn
                        : t.shiny_hunt_pause_hunt_btn,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: onTogglePause,
                ),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTime(hunt.totalTimeSeconds),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${effectivePace.toStringAsFixed(0)} / h',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
