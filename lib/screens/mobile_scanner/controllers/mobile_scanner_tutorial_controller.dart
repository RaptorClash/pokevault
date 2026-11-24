import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../models/tutorial_step.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';

/// Orchestrates the 5-step interactive Rotom tutorial for the mobile camera scanner.
class MobileScannerTutorialController {
  final GlobalKey viewportKey;
  final GlobalKey modesKey;
  final GlobalKey photoKey;
  final GlobalKey pipKey;
  final GlobalKey bottomPanelKey;
  bool _hasTriggered = false;

  MobileScannerTutorialController({
    required this.viewportKey,
    required this.modesKey,
    required this.photoKey,
    required this.pipKey,
    required this.bottomPanelKey,
  });

  void maybeShowIfNeeded(
    BuildContext context, {
    required MobileScannerViewMode Function() getViewMode,
  }) {
    if (!context.mounted || _hasTriggered) return;
    _hasTriggered = true;

    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      return;
    }

    if (tutProvider.hasSeenFeature('mobile_scanner_tour')) return;
    startTutorial(context, getViewMode: getViewMode);
  }

  void startTutorial(
    BuildContext context, {
    required MobileScannerViewMode Function() getViewMode,
    bool force = false,
  }) {
    if (!context.mounted) return;
    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      tutProvider = null;
    }

    if (force) {
      TutorialOverlay.resetShowing();
    }

    TutorialOverlay.show(
      context,
      TutorialFeature(
        id: 'mobile_scanner_tour',
        nameKey: 'tutorial_chapter_scanner_mobile_title',
        steps: [
          TutorialStep(
            targetKey: viewportKey,
            titleKey: 'tutorial_scanner_mob_camera_title',
            textKey: 'tutorial_scanner_mob_camera_text',
            rotomMood: RotomMood.happy,
          ),
          TutorialStep(
            targetKey: modesKey,
            titleKey: 'tutorial_scanner_mob_modes_title',
            textKey: 'tutorial_scanner_mob_modes_text',
            rotomMood: RotomMood.explaining,
          ),
          TutorialStep(
            targetKey: photoKey,
            titleKey: 'tutorial_scanner_mob_photo_title',
            textKey: 'tutorial_scanner_mob_photo_text',
            rotomMood: RotomMood.explaining,
          ),
          TutorialStep(
            targetKey: pipKey,
            titleKey: 'tutorial_scanner_mob_pip_title',
            textKey: 'tutorial_scanner_mob_pip_text',
            rotomMood: RotomMood.thinking,
          ),
          TutorialStep(
            targetKey: getViewMode() == MobileScannerViewMode.fullscreen
                ? bottomPanelKey
                : null,
            titleKey: 'tutorial_scanner_mob_dex_title',
            textKey: 'tutorial_scanner_mob_dex_text',
            rotomMood: RotomMood.happy,
          ),
        ],
      ),
      () {
        tutProvider?.markFeatureAsSeen('mobile_scanner_tour');
        tutProvider?.endScannerDeltaTour();
        if (tutProvider != null &&
            tutProvider.completedTutorialVersion <
                TutorialProvider.currentTutorialVersion) {
          unawaited(tutProvider.completeScannerTutorial());
        }
      },
    );
  }
}
