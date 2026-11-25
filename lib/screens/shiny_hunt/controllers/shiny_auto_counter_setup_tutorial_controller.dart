import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/tutorial_step.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';

/// Manages the interactive Rotom tutorial tour for [ShinyAutoCounterSetupSheet].
class ShinyAutoCounterSetupTutorialController {
  final GlobalKey sourceSectionKey = GlobalKey();
  final GlobalKey modeSectionKey = GlobalKey();
  final GlobalKey filterResetSectionKey = GlobalKey();
  final GlobalKey customPatternsSectionKey = GlobalKey();
  final GlobalKey timingSectionKey = GlobalKey();
  final GlobalKey safetyStartSectionKey = GlobalKey();

  bool _hasTriggered = false;

  /// Automatically starts the setup tour once when `shiny_auto_counter_setup` has not been seen.
  void showIfNeeded({
    required BuildContext context,
    required bool isMounted,
    required bool perHuntOverride,
  }) {
    if (!isMounted || _hasTriggered) return;
    _hasTriggered = true;

    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      return;
    }

    if (tutProvider.hasSeenFeature('shiny_auto_counter_setup')) return;

    start(
      context: context,
      isMounted: isMounted,
      perHuntOverride: perHuntOverride,
    );
  }

  /// Starts the 6-step (or 5-step for per-hunt override) setup tour via [TutorialOverlay].
  void start({
    required BuildContext context,
    required bool isMounted,
    required bool perHuntOverride,
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
      if (!perHuntOverride)
        TutorialStep(
          targetKey: sourceSectionKey,
          titleKey: 'tutorial_auto_setup_source_title',
          textKey: 'tutorial_auto_setup_source_text',
          rotomMood: RotomMood.happy,
          preCalculateDelayMilliseconds: 450,
          scrollAlignment: 0.25,
        ),
      TutorialStep(
        targetKey: modeSectionKey,
        titleKey: 'tutorial_auto_setup_mode_title',
        textKey: 'tutorial_auto_setup_mode_text',
        rotomMood: RotomMood.explaining,
        preCalculateDelayMilliseconds: perHuntOverride ? 450 : 0,
        scrollAlignment: 0.25,
      ),
      TutorialStep(
        targetKey: filterResetSectionKey,
        titleKey: 'tutorial_auto_setup_filter_title',
        textKey: 'tutorial_auto_setup_filter_text',
        rotomMood: RotomMood.explaining,
        scrollAlignment: 0.25,
      ),
      TutorialStep(
        targetKey: customPatternsSectionKey,
        titleKey: 'tutorial_auto_setup_custom_title',
        textKey: 'tutorial_auto_setup_custom_text',
        rotomMood: RotomMood.thinking,
        scrollAlignment: 0.25,
      ),
      TutorialStep(
        targetKey: timingSectionKey,
        titleKey: 'tutorial_auto_setup_timing_title',
        textKey: 'tutorial_auto_setup_timing_text',
        rotomMood: RotomMood.thinking,
        scrollAlignment: 0.25,
      ),
      TutorialStep(
        targetKey: safetyStartSectionKey,
        titleKey: 'tutorial_auto_setup_safety_title',
        textKey: 'tutorial_auto_setup_safety_text',
        rotomMood: RotomMood.happy,
        scrollAlignment: 0.25,
      ),
    ];

    TutorialOverlay.show(
      context,
      TutorialFeature(
        id: 'shiny_auto_counter_setup',
        nameKey: 'tutorial_chapter_shiny_auto_title',
        steps: steps,
      ),
      () => tutProvider?.markFeatureAsSeen('shiny_auto_counter_setup'),
    );
  }
}
