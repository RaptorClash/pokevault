import 'package:flutter/material.dart';

enum RotomMood { happy, explaining, thinking, alert }

enum ContentAlign { top, bottom, left, right }

class TutorialStep {
  final String? id;
  final GlobalKey? targetKey;
  final String titleKey;
  final String textKey;
  final bool requireTargetTap;
  final VoidCallback? onTargetTap;
  final int preCalculateDelayMilliseconds;
  final int tapDelayMilliseconds;
  final bool hideNextButton;
  final bool Function(double)? checkScroll;
  final bool disableScroll;
  final bool showHighlight;
  final double scrollAlignment;
  final bool requireLongPress;

  TutorialStep({
    this.id,
    this.targetKey,
    required this.titleKey,
    required this.textKey,
    this.requireTargetTap = false,
    this.onTargetTap,
    this.preCalculateDelayMilliseconds = 0,
    this.tapDelayMilliseconds = 0,
    this.hideNextButton = false,
    this.checkScroll,
    this.disableScroll = false,
    this.showHighlight = true,
    this.scrollAlignment = 0.5,
    this.requireLongPress = false,
  });
}

class TutorialFeature {
  final String id;
  final String nameKey;
  final List<TutorialStep> steps;

  TutorialFeature({
    required this.id,
    required this.nameKey,
    required this.steps,
  });
}
