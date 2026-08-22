import 'package:flutter/material.dart';

enum RotomMood { happy, explaining, thinking, alert }

enum ContentAlign { top, bottom, left, right }

class TutorialStep {
  final GlobalKey? targetKey;
  final String titleKey;
  final String textKey;
  final bool requireTargetTap;
  final bool hideNextButton;
  final VoidCallback? onTargetTap;
  final bool Function(double)? checkScroll;
  final int tapDelayMilliseconds;
  final int preCalculateDelayMilliseconds; // NEU: Wartet auf UI-Animationen

  TutorialStep({
    this.targetKey,
    required this.titleKey,
    required this.textKey,
    this.requireTargetTap = false,
    this.hideNextButton = false,
    this.onTargetTap,
    this.checkScroll,
    this.tapDelayMilliseconds = 250,
    this.preCalculateDelayMilliseconds = 0,
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
