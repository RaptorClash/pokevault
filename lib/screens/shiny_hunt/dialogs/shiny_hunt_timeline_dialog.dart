import 'package:flutter/material.dart';
import '../../../models/shiny_hunt.dart';
import '../../../i18n/strings.g.dart';

/// Modal dialog displaying the chronological timeline and pause history of a [ShinyHunt].
///
/// Shows:
/// * Hunt start timestamp ([ShinyHunt.createdAt])
/// * Chronological list of all pause intervals with start, resume, and duration ([ShinyHunt.pauseHistory])
/// * Hunt completion timestamp ([ShinyHunt.completedAt]) or active status
/// * Net encounter hunt time ([ShinyHunt.totalTimeSeconds]) vs. total pause duration.
class ShinyHuntTimelineDialog extends StatelessWidget {
  final ShinyHunt hunt;

  const ShinyHuntTimelineDialog({super.key, required this.hunt});

  /// Displays the [ShinyHuntTimelineDialog] for [hunt].
  static Future<void> show(BuildContext context, ShinyHunt hunt) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ShinyHuntTimelineDialog(hunt: hunt),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year, $hour:$minute Uhr';
  }

  static String _formatDuration(Duration d) {
    if (d.inMinutes < 1) {
      return t.shiny_hunt_duration_under_minute;
    }
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) {
      if (minutes > 0) {
        return '$hours Std. $minutes Min.';
      }
      return '$hours Std.';
    }
    return '$minutes Min.';
  }

  static String _formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Duration _calculateTotalPauseDuration() {
    Duration sum = Duration.zero;
    final now = DateTime.now();
    for (final interval in hunt.pauseHistory) {
      final end = interval.resumedAt ?? (hunt.isCompleted ? (hunt.completedAt ?? now) : now);
      final diff = end.difference(interval.pausedAt);
      if (!diff.isNegative) {
        sum += diff;
      }
    }
    return sum;
  }

  /// Formats the chronological range of a pause interval ("von wann bis wann").
  /// Shows date on resume timestamp if interval spans across different calendar days.
  static String formatPauseIntervalRange(ShinyPauseInterval interval) {
    if (interval.resumedAt == null) {
      return 'Seit ${_formatDateTime(interval.pausedAt)} (${t.shiny_hunt_pause_ongoing})';
    }
    final p = interval.pausedAt;
    final r = interval.resumedAt!;
    final pDateStr = '${p.day.toString().padLeft(2, '0')}.${p.month.toString().padLeft(2, '0')}.';
    final pTimeStr = '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
    final rTimeStr = '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')} Uhr';

    final isSameDay = p.year == r.year && p.month == r.month && p.day == r.day;
    if (isSameDay) {
      return '$pDateStr $pTimeStr - $rTimeStr';
    } else {
      final rDateStr = '${r.day.toString().padLeft(2, '0')}.${r.month.toString().padLeft(2, '0')}.';
      return '$pDateStr $pTimeStr - $rDateStr $rTimeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalPauseDuration = _calculateTotalPauseDuration();
    final totalPauseStr = _formatDuration(totalPauseDuration);
    final netHuntTimeStr = _formatSeconds(hunt.totalTimeSeconds);

    final end = hunt.completedAt ?? DateTime.now();
    final grossDiff = end.difference(hunt.createdAt);
    final grossDuration = grossDiff.isNegative ? Duration.zero : grossDiff;
    final grossDurationStr = _formatDuration(grossDuration);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time_rounded, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.shiny_hunt_timeline_title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  hunt.title.isNotEmpty ? hunt.title : hunt.pokemonName,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: t.shiny_hunt_net_time,
                      value: netHuntTimeStr,
                      valueColor: Colors.green,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: t.shiny_hunt_pause_total,
                      value: totalPauseStr,
                      valueColor: Colors.amber,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: t.shiny_hunt_gross_duration,
                      value: grossDurationStr,
                      valueColor: Colors.blue,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                t.shiny_hunt_timeline_events,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),

              // 1. Start Event
              _buildTimelineTile(
                icon: Icons.play_arrow_rounded,
                iconColor: Colors.green,
                title: t.shiny_hunt_started_at,
                subtitle: _formatDateTime(hunt.createdAt),
                trailingBadge: 'Start',
                isDark: isDark,
              ),

              // 2. Pause Intervals
              if (hunt.pauseHistory.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        t.shiny_hunt_no_pauses,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (int i = 0; i < hunt.pauseHistory.length; i++)
                  _buildPauseTile(hunt.pauseHistory[i], i + 1, isDark),
              ],

              // 3. Completion / Active Event
              if (hunt.isCompleted && hunt.completedAt != null) ...[
                _buildTimelineTile(
                  icon: Icons.flag_rounded,
                  iconColor: Colors.purple,
                  title: t.shiny_hunt_completed_at,
                  subtitle: _formatDateTime(hunt.completedAt!),
                  trailingBadge: t.shiny_hunt_completed_status,
                  isDark: isDark,
                ),
              ] else if (hunt.isPaused) ...[
                _buildTimelineTile(
                  icon: Icons.pause_circle_filled,
                  iconColor: Colors.amber,
                  title: t.shiny_hunt_status_currently_paused,
                  subtitle: hunt.pauseHistory.isNotEmpty
                      ? 'Seit ${_formatDateTime(hunt.pauseHistory.last.pausedAt)}'
                      : 'Pausiert',
                  trailingBadge: t.shiny_hunt_paused,
                  isDark: isDark,
                ),
              ] else ...[
                _buildTimelineTile(
                  icon: Icons.hourglass_top_rounded,
                  iconColor: Colors.blue,
                  title: t.shiny_hunt_status_active,
                  subtitle: t.shiny_hunt_active_desc,
                  trailingBadge: t.active,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailingBadge,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: iconColor.withValues(alpha: 0.15),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trailingBadge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseTile(ShinyPauseInterval interval, int index, bool isDark) {
    final bool isOngoing = interval.resumedAt == null;
    final pauseDuration = isOngoing
        ? DateTime.now().difference(interval.pausedAt)
        : (interval.duration ?? Duration.zero);
    final durationStr = _formatDuration(pauseDuration);

    final String timeRangeStr = formatPauseIntervalRange(interval);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.amber.shade50.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOngoing
              ? Colors.amber.shade400
              : (isDark ? Colors.grey.shade800 : Colors.amber.shade200),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.amber.withValues(alpha: 0.15),
            child: Icon(
              isOngoing ? Icons.pause_circle_outline : Icons.pause,
              size: 16,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.shiny_hunt_pause_label} $index',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  timeRangeStr,
                  style: TextStyle(fontSize: 11, color: isOngoing ? Colors.amber.shade700 : Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              durationStr,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
