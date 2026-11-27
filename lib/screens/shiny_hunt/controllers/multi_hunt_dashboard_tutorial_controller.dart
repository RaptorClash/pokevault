import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/tutorial_step.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';

/// Manages the interactive 6-step Rotom tutorial tour for [MultiHuntDashboardScreen].
class MultiHuntDashboardTutorialController {
  final GlobalKey addHuntBtnKey = GlobalKey();
  final GlobalKey pausedToggleBtnKey = GlobalKey();
  final GlobalKey autoSetupBtnKey = GlobalKey();
  final GlobalKey helpBtnKey = GlobalKey();

  final GlobalKey firstCardCounterKey = GlobalKey();
  final GlobalKey firstCardRulesKey = GlobalKey();
  final GlobalKey firstCardSlotsKey = GlobalKey();

  bool _hasTriggered = false;

  /// Automatically starts the dashboard tour once when `multi_hunt_dashboard` has not been seen.
  void showIfNeeded({
    required BuildContext context,
    required bool isMounted,
    required bool hasActiveHunts,
    required bool hasPausedHunts,
    required bool hasVisibleCard,
  }) {
    if (!isMounted || _hasTriggered) return;
    _hasTriggered = true;

    TutorialProvider? tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      return;
    }

    if (tutProvider.hasSeenFeature('multi_hunt_dashboard')) return;

    start(
      context: context,
      isMounted: isMounted,
      hasActiveHunts: hasActiveHunts,
      hasPausedHunts: hasPausedHunts,
      hasVisibleCard: hasVisibleCard,
    );
  }

  /// Starts the 6-step Rotom spotlight tour via [TutorialOverlay].
  void start({
    required BuildContext context,
    required bool isMounted,
    required bool hasActiveHunts,
    required bool hasPausedHunts,
    required bool hasVisibleCard,
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
        targetKey: null,
        titleKey: 'tutorial_multi_hunt_intro_title',
        textKey: 'tutorial_multi_hunt_intro_text',
        rotomMood: RotomMood.happy,
      ),
      TutorialStep(
        targetKey: hasPausedHunts ? pausedToggleBtnKey : addHuntBtnKey,
        titleKey: 'tutorial_multi_hunt_appbar_title',
        textKey: 'tutorial_multi_hunt_appbar_text',
        rotomMood: RotomMood.explaining,
      ),
      TutorialStep(
        targetKey: hasActiveHunts ? autoSetupBtnKey : helpBtnKey,
        titleKey: 'tutorial_multi_hunt_setup_title',
        textKey: 'tutorial_multi_hunt_setup_text',
        rotomMood: RotomMood.explaining,
      ),
      if (hasVisibleCard) ...[
        TutorialStep(
          targetKey: firstCardCounterKey,
          titleKey: 'tutorial_multi_hunt_card_counter_title',
          textKey: 'tutorial_multi_hunt_card_counter_text',
          rotomMood: RotomMood.explaining,
          scrollAlignment: 0.3,
        ),
        TutorialStep(
          targetKey: firstCardRulesKey,
          titleKey: 'tutorial_multi_hunt_card_rules_title',
          textKey: 'tutorial_multi_hunt_card_rules_text',
          rotomMood: RotomMood.thinking,
          scrollAlignment: 0.3,
        ),
        TutorialStep(
          targetKey: firstCardSlotsKey,
          titleKey: 'tutorial_multi_hunt_card_slots_title',
          textKey: 'tutorial_multi_hunt_card_slots_text',
          rotomMood: RotomMood.happy,
          scrollAlignment: 0.3,
        ),
      ],
    ];

    TutorialOverlay.show(
      context,
      TutorialFeature(
        id: 'multi_hunt_dashboard',
        nameKey: 'tutorial_chapter_shiny_auto_title',
        steps: steps,
      ),
      () => tutProvider?.markFeatureAsSeen('multi_hunt_dashboard'),
    );
  }
}
