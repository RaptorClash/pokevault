import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/tutorial_step.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';

/// Manages the interactive Rotom tutorial tour keys and trigger flow
/// for [DesktopTrackerScreen].
class DesktopTrackerTutorialController {
  final GlobalKey sourceSectionKey = GlobalKey();
  final GlobalKey targetDexSectionKey = GlobalKey();
  final GlobalKey bordersToggleKey = GlobalKey();
  final GlobalKey zoneASectionKey = GlobalKey();
  final GlobalKey zoneBSectionKey = GlobalKey();
  final GlobalKey multiSectionKey = GlobalKey();
  final GlobalKey hudKey = GlobalKey();
  final GlobalKey eventFeedKey = GlobalKey();

  bool _hasTriggeredTutorial = false;

  /// Automatically starts the tour once if the user has not seen it yet.
  void showIfNeeded({
    required BuildContext context,
    required bool isMounted,
    required bool showOverlayControls,
  }) {
    if (!isMounted || _hasTriggeredTutorial) return;
    _hasTriggeredTutorial = true;

    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      return;
    }

    if (tutProvider.hasSeenFeature('desktop_scanner_tour')) return;
    start(
      context: context,
      isMounted: isMounted,
      showOverlayControls: showOverlayControls,
    );
  }

  /// Launches the step-by-step desktop scanner tour via [TutorialOverlay].
  void start({
    required BuildContext context,
    required bool isMounted,
    required bool showOverlayControls,
    bool force = false,
  }) {
    if (!isMounted) return;
    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      tutProvider = null;
    }

    if (force) {
      TutorialOverlay.resetShowing();
    }

    final steps = <TutorialStep>[
      TutorialStep(
        targetKey: sourceSectionKey,
        titleKey: 'tutorial_scanner_desk_source_title',
        textKey: 'tutorial_scanner_desk_source_text',
        rotomMood: RotomMood.happy,
      ),
      TutorialStep(
        targetKey: targetDexSectionKey,
        titleKey: 'tutorial_scanner_desk_dex_title',
        textKey: 'tutorial_scanner_desk_dex_text',
        rotomMood: RotomMood.explaining,
      ),
      if (showOverlayControls)
        TutorialStep(
          targetKey: bordersToggleKey,
          titleKey: 'tutorial_scanner_desk_borders_title',
          textKey: 'tutorial_scanner_desk_borders_text',
          rotomMood: RotomMood.explaining,
        ),
      TutorialStep(
        targetKey: zoneASectionKey,
        titleKey: 'tutorial_scanner_desk_zone_a_title',
        textKey: 'tutorial_scanner_desk_zone_a_text',
        rotomMood: RotomMood.explaining,
      ),
      TutorialStep(
        targetKey: zoneBSectionKey,
        titleKey: 'tutorial_scanner_desk_zone_b_title',
        textKey: 'tutorial_scanner_desk_zone_b_text',
        rotomMood: RotomMood.thinking,
      ),
      TutorialStep(
        targetKey: multiSectionKey,
        titleKey: 'tutorial_scanner_desk_multi_title',
        textKey: 'tutorial_scanner_desk_multi_text',
        rotomMood: RotomMood.explaining,
      ),
      if (showOverlayControls)
        TutorialStep(
          targetKey: hudKey,
          titleKey: 'tutorial_scanner_desk_hud_title',
          textKey: 'tutorial_scanner_desk_hud_text',
          rotomMood: RotomMood.explaining,
        ),
      TutorialStep(
        targetKey: eventFeedKey,
        titleKey: 'tutorial_scanner_desk_feed_title',
        textKey: 'tutorial_scanner_desk_feed_text',
        rotomMood: RotomMood.happy,
      ),
    ];

    TutorialOverlay.show(
      context,
      TutorialFeature(
        id: 'desktop_scanner_tour',
        nameKey: 'tutorial_chapter_scanner_desktop_title',
        steps: steps,
      ),
      () {
        tutProvider?.markFeatureAsSeen('desktop_scanner_tour');
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
