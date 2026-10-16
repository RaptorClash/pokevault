import 'package:flutter/material.dart';

class MultiDragPileFeedback extends StatefulWidget {
  final Widget topCard;
  final int count;
  final double size;

  const MultiDragPileFeedback({
    super.key,
    required this.topCard,
    required this.count,
    required this.size,
  });

  @override
  State<MultiDragPileFeedback> createState() => _MultiDragPileFeedbackState();
}

class _MultiDragPileFeedbackState extends State<MultiDragPileFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pileAnimation;
  late Animation<double> _badgeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _pileAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _badgeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShadowCard(
    BuildContext context, {
    required double angle,
    required Offset offset,
    required double opacity,
  }) {
    final theme = Theme.of(context);
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(2, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.catching_pokemon,
              size: widget.size * 0.35,
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTripleOrMore = widget.count >= 3;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _pileAnimation.value;

        final bottomOffset = Offset(
          (18.0 - 10.0 * t).clamp(4.0, 18.0),
          (18.0 - 10.0 * t).clamp(4.0, 18.0),
        );
        final middleOffset = Offset(
          (10.0 - 6.0 * t).clamp(2.0, 10.0),
          (10.0 - 6.0 * t).clamp(2.0, 10.0),
        );

        return Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: widget.size + 24,
            height: widget.size + 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (isTripleOrMore)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: _buildShadowCard(
                      context,
                      angle: 0.08 * t,
                      offset: bottomOffset,
                      opacity: 0.75,
                    ),
                  ),

                Positioned(
                  left: 0,
                  top: 0,
                  child: _buildShadowCard(
                    context,
                    angle: -0.05 * t,
                    offset: middleOffset,
                    opacity: 0.85,
                  ),
                ),

                Positioned(
                  left: 0,
                  top: 0,
                  child: Opacity(
                    opacity: 0.92,
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                      child: SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: Transform.scale(
                          scale: 1.04,
                          child: widget.topCard,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: -6,
                  right: 18,
                  child: Transform.scale(
                    scale: _badgeScaleAnimation.value,
                    child: Container(
                      key: const Key('multi_drag_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.count}',
                          key: const Key('multi_drag_count_text'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
