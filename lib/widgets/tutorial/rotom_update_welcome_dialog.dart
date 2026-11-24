import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../i18n/strings.g.dart';
import '../../constants/app_vectors.dart';
import '../../utils/tracker_platform_helper.dart';

enum RotomUpdateType { v16, scanner }

class RotomUpdateWelcomeDialog extends StatelessWidget {
  final VoidCallback? onStartTour;
  final RotomUpdateType updateType;

  const RotomUpdateWelcomeDialog({
    super.key,
    this.onStartTour,
    this.updateType = RotomUpdateType.v16,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onStartTour,
    RotomUpdateType updateType = RotomUpdateType.v16,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RotomUpdateWelcomeDialog(
        onStartTour: onStartTour,
        updateType: updateType,
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    final isScanner = updateType == RotomUpdateType.scanner;
    final isMobile = TrackerPlatformHelper.isMobile;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Rotom & Version Badge
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: SvgPicture.string(AppVectors.rotomDex),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.4,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isScanner
                                ? t.tutorial_scanner_update_badge
                                : t.tutorial_v16_badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isScanner
                              ? (isMobile
                                  ? t.tutorial_scanner_update_mob_title
                                  : t.tutorial_scanner_update_desk_title)
                              : t.tutorial_v16_welcome_title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                isScanner
                    ? (isMobile
                        ? t.tutorial_scanner_update_mob_desc
                        : t.tutorial_scanner_update_desk_desc)
                    : t.tutorial_v16_welcome_desc,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 14),

              if (isScanner && isMobile) ...[
                _buildFeatureCard(
                  context,
                  icon: Icons.photo_camera_outlined,
                  iconColor: Colors.cyanAccent,
                  title: t.tutorial_scanner_mob_f1_title,
                  desc: t.tutorial_scanner_mob_f1_desc,
                ),
                const SizedBox(height: 8),
                _buildFeatureCard(
                  context,
                  icon: Icons.crop_free,
                  iconColor: Colors.greenAccent,
                  title: t.tutorial_scanner_mob_f2_title,
                  desc: t.tutorial_scanner_mob_f2_desc,
                ),
                const SizedBox(height: 8),
                _buildFeatureCard(
                  context,
                  icon: Icons.picture_in_picture_alt,
                  iconColor: Colors.amber,
                  title: t.tutorial_scanner_mob_f3_title,
                  desc: t.tutorial_scanner_mob_f3_desc,
                ),
              ] else if (isScanner) ...[
                _buildFeatureCard(
                  context,
                  icon: Icons.track_changes,
                  iconColor: Colors.redAccent,
                  title: t.tutorial_scanner_desk_f1_title,
                  desc: t.tutorial_scanner_desk_f1_desc,
                ),
                const SizedBox(height: 8),
                _buildFeatureCard(
                  context,
                  icon: Icons.crop_free,
                  iconColor: Colors.tealAccent,
                  title: t.tutorial_scanner_desk_f2_title,
                  desc: t.tutorial_scanner_desk_f2_desc,
                ),
                const SizedBox(height: 8),
                _buildFeatureCard(
                  context,
                  icon: Icons.picture_in_picture_alt,
                  iconColor: Colors.amber,
                  title: t.tutorial_scanner_desk_f3_title,
                  desc: t.tutorial_scanner_desk_f3_desc,
                ),
              ] else ...[
                // Feature cards grid (v1.6)
                _buildFeatureCard(
                  context,
                  icon: Icons.auto_awesome,
                  iconColor: Colors.amber,
                  title: t.tutorial_v16_f1_title,
                  desc: t.tutorial_v16_f1_desc,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  context,
                  icon: Icons.inventory_2_outlined,
                  iconColor: Colors.blueAccent,
                  title: t.tutorial_v16_f2_title,
                  desc: t.tutorial_v16_f2_desc,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  context,
                  icon: Icons.bar_chart,
                  iconColor: Colors.teal,
                  title: t.tutorial_v16_f3_title,
                  desc: t.tutorial_v16_f3_desc,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  context,
                  icon: Icons.search,
                  iconColor: Colors.purpleAccent,
                  title: t.tutorial_v16_f4_title,
                  desc: t.tutorial_v16_f4_desc,
                ),
              ],

              const SizedBox(height: 18),

              // Buttons
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () async {
                      if (isScanner) {
                        await tutProvider.dismissScannerUpdatePrompt();
                      } else {
                        await tutProvider.dismissV16UpdatePrompt();
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      t.tutorial_v16_skip,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (isScanner) {
                        await tutProvider.startScannerDeltaTour();
                      } else {
                        await tutProvider.startV16DeltaTour();
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        onStartTour?.call();
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(
                      t.tutorial_v16_start_tour,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
