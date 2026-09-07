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
  final Animation<double> pulseAnimation;
  final VoidCallback onSkip;
  final VoidCallback onNext;

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
    required this.pulseAnimation,
    required this.onSkip,
    required this.onNext,
  });

  Widget _buildRotomIcon() {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * pulseAnimation.value),
          child: child,
        );
      },
      child: SvgPicture.string(AppVectors.rotomDex, width: 90, height: 90),
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    bool showNextBtn =
        (!step.requireTargetTap && !step.hideNextButton) ||
        easterEggTriggered ||
        targetRect == null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: (showBubbleTop && !isIntro) || isEasterEggActive
              ? const Radius.circular(20)
              : const Radius.circular(0),
          topLeft: (showBubbleTop && !isIntro) && !isEasterEggActive
              ? const Radius.circular(0)
              : const Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Translator.get(step.titleKey),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overrideText ?? Translator.get(step.textKey),
            style: TextStyle(
              fontSize: 14,
              fontWeight: overrideText != null
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: overrideText != null ? Colors.redAccent : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: isEasterEggActive ? null : onSkip,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Translator.get('tutorial_skip'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              if (showNextBtn)
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: isEasterEggActive ? null : onNext,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Translator.get(
                          isLast ? 'tutorial_finish' : 'tutorial_next',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isEasterEggActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBubbleContent(context),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: _buildRotomIcon()),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: showBubbleTop && !isIntro
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          _buildRotomIcon(),
          const SizedBox(width: 16),
          Expanded(child: _buildBubbleContent(context)),
        ],
      );
    }
  }
}
