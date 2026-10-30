import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/tutorial_step.dart';
import '../../../l10n/app_translations.dart';
import '../../../constants/app_vectors.dart';
import './tutorial_painters.dart';

class TutorialHighlight extends StatelessWidget {
  final Rect? targetRect;
  final bool isEasterEggActive;
  final bool showHighlight;
  final Animation<double> pulseAnimation;

  const TutorialHighlight({
    super.key,
    required this.targetRect,
    required this.isEasterEggActive,
    required this.showHighlight,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: HolePainter(rect: isEasterEggActive ? null : targetRect),
        ),
        if (targetRect != null && showHighlight && !isEasterEggActive)
          Positioned.fromRect(
            rect: targetRect!,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withValues(
                          alpha: 0.5 + (pulseAnimation.value * 0.5),
                        ),
                        width: 4,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class TutorialLightning extends StatelessWidget {
  final Offset? oldPos;
  final Offset? newPos;
  final Animation<double> lightningAnimation;

  const TutorialLightning({
    super.key,
    required this.oldPos,
    required this.newPos,
    required this.lightningAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (oldPos == null || newPos == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: lightningAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: LightningPainter(
              start: oldPos!,
              end: newPos!,
              progress: lightningAnimation.value,
            ),
          );
        },
      ),
    );
  }
}

class TutorialBubble extends StatelessWidget {
  final TutorialStep step;
  final bool showBubbleTop;
  final bool isIntro;
  final bool isLast;
  final bool isEasterEggActive;
  final bool easterEggTriggered;
  final String? overrideText;
  final Rect? targetRect;
  final int stepIndex;
  final int totalSteps;
  final Animation<double> pulseAnimation;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback? onPrev;

  const TutorialBubble({
    super.key,
    required this.step,
    required this.showBubbleTop,
    required this.isIntro,
    required this.isLast,
    required this.isEasterEggActive,
    required this.easterEggTriggered,
    this.overrideText,
    this.targetRect,
    this.stepIndex = 0,
    this.totalSteps = 1,
    required this.pulseAnimation,
    required this.onSkip,
    required this.onNext,
    this.onPrev,
  });

  Widget _buildRotomIcon({bool isSmall = false}) {
    IconData moodIcon;
    Color moodColor;

    switch (step.rotomMood) {
      case RotomMood.happy:
        moodIcon = Icons.sentiment_very_satisfied;
        moodColor = Colors.amber;
        break;
      case RotomMood.thinking:
        moodIcon = Icons.lightbulb_outline;
        moodColor = Colors.cyanAccent;
        break;
      case RotomMood.alert:
        moodIcon = Icons.bolt;
        moodColor = Colors.orangeAccent;
        break;
      case RotomMood.explaining:
        moodIcon = Icons.auto_awesome;
        moodColor = Colors.amber;
        break;
    }

    final size = isSmall ? 52.0 : 75.0;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -6 * pulseAnimation.value),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.string(AppVectors.rotomDex, width: size, height: size),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
                border: Border.all(color: moodColor, width: 1.5),
              ),
              child: Icon(moodIcon, size: isSmall ? 11 : 13, color: moodColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(BuildContext context, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final bool showNextBtn =
        (!step.requireTargetTap && !step.hideNextButton) ||
        easterEggTriggered ||
        targetRect == null;

    final double progress = totalSteps > 0
        ? ((stepIndex + 1) / totalSteps).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: (showBubbleTop && !isIntro) || isEasterEggActive
              ? const Radius.circular(20)
              : const Radius.circular(4),
          topLeft: (showBubbleTop && !isIntro) && !isEasterEggActive
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Rotom Assistant badge + Step counter + Skip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Rotom',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (totalSteps > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Schritt ${stepIndex + 1} von $totalSteps',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: Translator.get('tutorial_skip'),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: isEasterEggActive ? null : onSkip,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 2),
                            Text(
                              Translator.get('tutorial_skip'),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Progress bar
            if (totalSteps > 1) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Title
            Text(
              Translator.get(step.titleKey),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 5),

            // Description
            Text(
              overrideText ?? Translator.get(step.textKey),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: overrideText != null
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: overrideText != null
                    ? Colors.redAccent
                    : theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            // Bottom action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onPrev != null && stepIndex > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: isEasterEggActive ? null : onPrev,
                    icon: const Icon(Icons.arrow_back, size: 13),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Translator.get('previous', fallback: 'Zurück'),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (showNextBtn)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    onPressed: isEasterEggActive ? null : onNext,
                    icon: Icon(
                      isLast ? Icons.check : Icons.arrow_forward,
                      size: 13,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Translator.get(
                          isLast ? 'tutorial_finish' : 'tutorial_next',
                          fallback: isLast ? 'Fertig' : 'Weiter',
                        ),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    if (isEasterEggActive || isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBubbleContent(context, isCompact: isCompact),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildRotomIcon(isSmall: isCompact),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: showBubbleTop && !isIntro
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          _buildRotomIcon(),
          const SizedBox(width: 12),
          Expanded(child: _buildBubbleContent(context)),
        ],
      );
    }
  }
}
