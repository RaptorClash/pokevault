import 'package:flutter/material.dart';

enum RotomMood { happy, explaining, thinking, alert }

enum ContentAlign { top, bottom, left, right }

class TutorialStep {
  final GlobalKey? targetKey;
  final String titleKey;
  final String textKey;
  final RotomMood mood;
  final ContentAlign alignment;

  final bool requireTargetTap;
  final VoidCallback? onTargetTap;

  TutorialStep({
    this.targetKey,
    required this.titleKey,
    required this.textKey,
    this.mood = RotomMood.explaining,
    this.alignment = ContentAlign.bottom,
    this.requireTargetTap = false,
    this.onTargetTap,
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
