import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/tutorial_step.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';

/// Manages the 3-step interactive Rotom tutorial tour for [ShinyAutoCounterBar]
/// when it first becomes visible on an active top route.
class ShinyAutoCounterBarTutorialController {
  final GlobalKey barRootKey = GlobalKey();
  final GlobalKey controlsRowKey = GlobalKey();
  final GlobalKey slotsAreaKey = GlobalKey();

  bool _hasTriggered = false;

  /// Triggers the bar tour if [isRunning] is true, the bar's route is currently
  /// the active top route, and `shiny_auto_counter_bar` has not yet been seen.
  void maybeShowIfNeeded({
    required BuildContext context,
    required bool isMounted,
    required bool isRunning,
    required bool hasSlotsArea,
  }) {
    if (!isMounted || !isRunning || _hasTriggered) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      return;
    }

    if (tutProvider.hasSeenFeature('shiny_auto_counter_bar')) return;
    if (TutorialOverlay.isShowing) return;

    _hasTriggered = true;
    start(
      context: context,
      isMounted: isMounted,
      hasSlotsArea: hasSlotsArea,
    );
  }

  /// Starts the 3-step Rotom spotlight tour for the live auto-counter bar.
  void start({
    required BuildContext context,
    required bool isMounted,
    required bool hasSlotsArea,
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
        targetKey: controlsRowKey,
        titleKey: 'tutorial_auto_bar_controls_title',
        textKey: 'tutorial_auto_bar_controls_text',
        rotomMood: RotomMood.happy,
      ),
      TutorialStep(
        targetKey: hasSlotsArea ? slotsAreaKey : barRootKey,
        titleKey: 'tutorial_auto_bar_slots_title',
        textKey: 'tutorial_auto_bar_slots_text',
        rotomMood: RotomMood.explaining,
      ),
      TutorialStep(
        targetKey: barRootKey,
        titleKey: 'tutorial_auto_bar_shiny_title',
        textKey: 'tutorial_auto_bar_shiny_text',
        rotomMood: RotomMood.alert,
      ),
    ];

    TutorialOverlay.show(
      context,
      TutorialFeature(
        id: 'shiny_auto_counter_bar',
        nameKey: 'tutorial_chapter_shiny_auto_title',
        steps: steps,
      ),
      () => tutProvider?.markFeatureAsSeen('shiny_auto_counter_bar'),
    );
  }
}
