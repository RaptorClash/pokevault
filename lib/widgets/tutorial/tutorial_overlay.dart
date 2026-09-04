import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/tutorial_step.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';
import '../../constants/app_vectors.dart';
import 'tutorial_painters.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialFeature feature;
  final VoidCallback onFinish;
  final int initialIndex;
  final Function(int)? onStepChanged;

  static Offset? lastTapPosition;
  static bool _isShowing = false;

  const TutorialOverlay({
    super.key,
    required this.feature,
    required this.onFinish,
    this.initialIndex = 0,
    this.onStepChanged,
  });

  static void show(
    BuildContext context,
    TutorialFeature feature,
    VoidCallback onFinish, {
    int initialIndex = 0,
    Function(int)? onStepChanged,
  }) {
    if (_isShowing) return;
    _isShowing = true;

    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: TutorialOverlay(
            feature: feature,
            onFinish: onFinish,
            initialIndex: initialIndex,
            onStepChanged: onStepChanged,
          ),
        );
      },
    ).then((_) {
      _isShowing = false;
      onFinish();
    });
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late int _currentIndex;
  Rect? _targetRect;
  late AnimationController _pulseController;
  late AnimationController _lightningController;
  Offset? _oldRotomPos;
  Offset? _newRotomPos;
  bool _isAdvancing = false;
  int _wrongSwipeCount = 0;
  DateTime? _lastWrongSwipeTime;
  bool _isEasterEggActive = false;
  bool _easterEggTriggered = false;
  String? _overrideText;
  Offset? _easterEggPos;
  int _wrongTapCount = 0;
  DateTime? _lastWrongTapTime;
  DateTime? _pointerDownTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (_currentIndex >= widget.feature.steps.length) {
      _currentIndex = 0;
    }

    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _lightningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final step = widget.feature.steps[_currentIndex];
      if (step.preCalculateDelayMilliseconds > 0) {
        await Future.delayed(
          Duration(milliseconds: step.preCalculateDelayMilliseconds),
        );
      }
      await _scrollToTarget(step.targetKey);
      if (mounted) _calculateTargetRect();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _lightningController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _calculateTargetRect();
    });
  }

  ScrollableState? _findScrollable(BuildContext? targetContext) {
    if (targetContext == null) return null;
    ScrollableState? scrollable;
    void visitor(Element element) {
      if (scrollable != null) return;
      if (element.widget is Scrollable) {
        scrollable = (element as StatefulElement).state as ScrollableState;
      } else {
        element.visitChildren(visitor);
      }
    }

    targetContext.visitChildElements(visitor);
    return scrollable ?? Scrollable.maybeOf(targetContext);
  }

  Future<void> _scrollToTarget(GlobalKey? key) async {
    if (key == null) return;
    try {
      final step = widget.feature.steps[_currentIndex];
      final targetContext = key.currentContext;
      final activeScrollable = _findScrollable(targetContext);
      if (activeScrollable == null) return;

      await Scrollable.ensureVisible(
        targetContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: step.scrollAlignment,
      ).catchError((e) {
        NotificationHelper.showError(
          "${Translator.get('tutorial_error_scroll')} $e",
        );
      });
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('tutorial_error_scroll')} $e",
      );
    }
  }

  void _calculateTargetRect() {
    if (!mounted) return;
    try {
      final step = widget.feature.steps[_currentIndex];
      if (step.targetKey == null) {
        _updatePositions(null);
        return;
      }
      final currentContext = step.targetKey!.currentContext;
      if (currentContext == null) {
        _updatePositions(null);
        return;
      }

      final renderBox = currentContext.findRenderObject() as RenderBox?;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (renderBox != null && overlay != null && renderBox.attached) {
        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

        double left = offset.dx - 4;
        double right = offset.dx + size.width + 4;
        double top = offset.dy - 4;
        double bottom = offset.dy + size.height + 4;

        if (right < left) right = left;
        if (bottom < top) bottom = top;

        final newRect = Rect.fromLTRB(left, top, right, bottom);
        _updatePositions(newRect);
      } else {
        _updatePositions(null);
      }
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('tutorial_error_rect')} $e",
      );
    }
  }

  void _updatePositions(Rect? newRect) {
    if (_isEasterEggActive) return;
    if (_targetRect == newRect) return;

    void updateState() {
      if (!mounted) return;
      setState(() {
        _targetRect = newRect;
      });

      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      Offset calculatedNewPos;

      if (newRect == null) {
        calculatedNewPos = Offset(screenWidth / 2, screenHeight / 2);
      } else {
        double spaceTop = newRect.top;
        double spaceBottom = screenHeight - newRect.bottom;

        if (spaceTop >= 260) {
          calculatedNewPos = Offset(screenWidth / 2, newRect.top - 150);
        } else if (spaceBottom >= 260) {
          calculatedNewPos = Offset(screenWidth / 2, newRect.bottom + 150);
        } else {
          calculatedNewPos = Offset(screenWidth / 2, screenHeight - 150);
        }
      }

      if (_newRotomPos != null && _newRotomPos != calculatedNewPos) {
        _oldRotomPos = _newRotomPos;
        _lightningController.forward(from: 0.0);
      }
      _newRotomPos = calculatedNewPos;
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => updateState());
    } else {
      updateState();
    }
  }

  void _handleWrongSwipe() {
    if (_isAdvancing || _isEasterEggActive) return;
    final now = DateTime.now();
    if (_lastWrongSwipeTime != null &&
        now.difference(_lastWrongSwipeTime!).inMilliseconds < 600) {
      return;
    }
    _lastWrongSwipeTime = now;
    _wrongSwipeCount++;

    if (_wrongSwipeCount >= 3) {
      _triggerRotomAutoSwipe();
    } else {
      setState(() {
        _overrideText =
            Translator.get('tutorial_wrong_swipe') != 'tutorial_wrong_swipe'
            ? Translator.get('tutorial_wrong_swipe')
            : 'Halt, falsche Richtung! Wir wollen zurück zum Nationaldex (nach rechts wischen)!';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_isEasterEggActive) {
          setState(() => _overrideText = null);
        }
      });
    }
  }

  void _triggerRotomAutoSwipe() async {
    if (_isAdvancing) return;

    setState(() {
      _isEasterEggActive = true;
      _easterEggTriggered = true;
      _overrideText =
          Translator.get('tutorial_rotom_angry') != 'tutorial_rotom_angry'
          ? Translator.get('tutorial_rotom_angry')
          : 'Na gut, wenn du nicht willst... dann mach ich das eben selbst! ZZZZZZT!';
    });

    final step = widget.feature.steps[_currentIndex];
    final renderBox =
        step.targetKey?.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      double safeY = (offset.dy - 150).clamp(
        50.0,
        MediaQuery.of(context).size.height - 350.0,
      );
      setState(() {
        _easterEggPos = Offset(MediaQuery.of(context).size.width / 4, safeY);
      });
    }

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    ScrollableState? scrollable = _findScrollable(
      step.targetKey?.currentContext,
    );

    setState(() => _isAdvancing = true);

    if (scrollable != null) {
      setState(() {
        _easterEggPos = Offset(
          MediaQuery.of(context).size.width + 100,
          _easterEggPos?.dy ?? 0,
        );
      });

      try {
        await scrollable.position.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        NotificationHelper.showError("Fehler beim Autoscroll: $e");
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (!mounted) return;

    _isAdvancing = false;
    _nextStep();

    setState(() {
      _isEasterEggActive = false;
      _easterEggPos = null;
      _wrongSwipeCount = 0;
    });

    _calculateTargetRect();
  }

  void _handleWrongTap() {
    if (_isAdvancing || _isEasterEggActive) return;

    final now = DateTime.now();
    if (_lastWrongTapTime != null &&
        now.difference(_lastWrongTapTime!).inMilliseconds < 600) {
      return;
    }
    _lastWrongTapTime = now;
    _wrongTapCount++;

    if (_wrongTapCount >= 3) {
      _triggerRotomAutoTap();
    } else {
      setState(() {
        _overrideText =
            Translator.get('tutorial_wrong_tap') != 'tutorial_wrong_tap'
            ? Translator.get('tutorial_wrong_tap')
            : 'Klick direkt auf den markierten Bereich!';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_isEasterEggActive) {
          setState(() => _overrideText = null);
        }
      });
    }
  }

  void _handleShortTapError() {
    if (_isAdvancing || _isEasterEggActive) return;

    setState(() {
      _overrideText =
          Translator.get('tutorial_longpress_error') !=
              'tutorial_longpress_error'
          ? Translator.get('tutorial_longpress_error')
          : 'Das war ein normaler Klick! Halte das Pokémon LANGE gedrückt!';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isEasterEggActive) {
        setState(() => _overrideText = null);
      }
    });
  }

  void _triggerRotomAutoTap() async {
    if (_isAdvancing) return;

    setState(() {
      _isEasterEggActive = true;
      _easterEggTriggered = true;
      _overrideText =
          Translator.get('tutorial_rotom_angry') != 'tutorial_rotom_angry'
          ? Translator.get('tutorial_rotom_angry')
          : 'Na gut, wenn du nicht willst... dann mach ich das eben selbst! ZZZZZZT!';
    });

    if (_targetRect != null) {
      setState(() {
        _easterEggPos = Offset(
          MediaQuery.of(context).size.width / 4,
          (_targetRect!.top - 150).clamp(
            50.0,
            MediaQuery.of(context).size.height - 300.0,
          ),
        );
      });
    }

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final step = widget.feature.steps[_currentIndex];
    final isLast = _currentIndex == widget.feature.steps.length - 1;

    setState(() => _isAdvancing = true);

    if (isLast) {
      _skipTutorial();
      if (step.onTargetTap != null) step.onTargetTap!();
    } else {
      if (step.onTargetTap != null) step.onTargetTap!();
      _isAdvancing = false;
      _nextStep();
    }

    if (mounted) {
      setState(() {
        _isEasterEggActive = false;
        _easterEggPos = null;
        _wrongTapCount = 0;
      });
    }
  }

  void _handleScroll(double dx, double dy) {
    if (_isAdvancing || _isEasterEggActive) return;
    try {
      final step = widget.feature.steps[_currentIndex];
      if (step.disableScroll) return;

      final activeScrollable = _findScrollable(step.targetKey?.currentContext);
      if (activeScrollable == null) return;

      bool isHorizontal =
          activeScrollable.axisDirection == AxisDirection.right ||
          activeScrollable.axisDirection == AxisDirection.left;
      double delta = isHorizontal ? dx : dy;
      if (isHorizontal && delta == 0 && dy != 0) {
        delta = dy;
      }

      if (step.id == 'swipe_back_national' && isHorizontal && delta > 2) {
        _handleWrongSwipe();
        return;
      }

      activeScrollable.position.jumpTo(
        (activeScrollable.position.pixels + delta).clamp(
          activeScrollable.position.minScrollExtent,
          activeScrollable.position.maxScrollExtent,
        ),
      );

      _calculateTargetRect();

      if (step.checkScroll != null) {
        bool met = step.checkScroll!(activeScrollable.position.pixels);
        bool maxR =
            activeScrollable.position.pixels >=
            activeScrollable.position.maxScrollExtent - 2;
        bool minR =
            activeScrollable.position.pixels <=
            activeScrollable.position.minScrollExtent + 2;

        if (!met && step.checkScroll!(10000) && maxR) met = true;
        if (!met && step.checkScroll!(0) && minR) met = true;

        if (met) {
          _nextStep();
        }
      }
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('tutorial_error_scroll')} $e",
      );
    }
  }

  void _nextStep() {
    if (_isAdvancing) return;
    try {
      if (_currentIndex < widget.feature.steps.length - 1) {
        setState(() {
          _isAdvancing = true;
          _currentIndex++;
          _overrideText = null;
          _easterEggTriggered = false;
          _wrongTapCount = 0;
        });
        widget.onStepChanged?.call(_currentIndex);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _calculateTargetRect();
        });

        final step = widget.feature.steps[_currentIndex];
        Future.delayed(
          Duration(milliseconds: step.preCalculateDelayMilliseconds),
          () async {
            if (!mounted) return;
            await _scrollToTarget(step.targetKey);
            if (!mounted) return;
            _calculateTargetRect();
            setState(() => _isAdvancing = false);
          },
        );
      } else {
        _skipTutorial();
      }
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('tutorial_error_next')} $e",
      );
      setState(() => _isAdvancing = false);
    }
  }

  void _skipTutorial() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildRotomIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _pulseController.value),
          child: child,
        );
      },
      child: SvgPicture.string(AppVectors.rotomDex, width: 90, height: 90),
    );
  }

  Widget _buildBubbleContent(
    TutorialStep step,
    bool showBubbleTop,
    bool isIntro,
    bool isLast,
  ) {
    bool showNextBtn =
        (!step.requireTargetTap && !step.hideNextButton) ||
        _easterEggTriggered ||
        _targetRect == null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: (showBubbleTop && !isIntro) || _isEasterEggActive
              ? const Radius.circular(20)
              : const Radius.circular(0),
          topLeft: (showBubbleTop && !isIntro) && !_isEasterEggActive
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
            _overrideText ?? Translator.get(step.textKey),
            style: TextStyle(
              fontSize: 14,
              fontWeight: _overrideText != null
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: _overrideText != null ? Colors.redAccent : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: _isEasterEggActive ? null : _skipTutorial,
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
                    onPressed: _isEasterEggActive ? null : _nextStep,
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
    final step = widget.feature.steps[_currentIndex];
    final isLast = _currentIndex == widget.feature.steps.length - 1;
    final screenHeight = MediaQuery.of(context).size.height;

    bool isIntro = _targetRect == null;
    bool showBubbleTop = false;
    bool isHugeTarget = false;

    if (_targetRect != null) {
      double spaceTop = _targetRect!.top;
      double spaceBottom = screenHeight - _targetRect!.bottom;

      if (spaceTop >= 260) {
        showBubbleTop = true;
      } else if (spaceBottom >= 260) {
        showBubbleTop = false;
      } else {
        isHugeTarget = true;
        showBubbleTop = true;
      }
    }

    double? calcTop;
    double? calcBottom;

    if (_easterEggPos != null) {
      calcTop = _easterEggPos!.dy;
    } else if (isIntro) {
      calcTop = (screenHeight / 2) - 100;
    } else if (isHugeTarget) {
      calcBottom = 40.0;
    } else if (showBubbleTop) {
      calcBottom = screenHeight - _targetRect!.top + 30;
    } else {
      calcTop = _targetRect!.bottom + 30;
    }

    return Material(
      type: MaterialType.transparency,
      child: Listener(
        onPointerDown: (event) {
          _pointerDownTime = DateTime.now();
        },
        onPointerUp: (event) {
          TutorialOverlay.lastTapPosition = event.position;
          if (_isAdvancing) return;

          if (step.requireTargetTap &&
              _targetRect != null &&
              !_isEasterEggActive) {
            if (_targetRect!.contains(event.localPosition)) {
              if (step.requireLongPress) {
                bool isLong = false;
                if (_pointerDownTime != null) {
                  final duration = DateTime.now().difference(_pointerDownTime!);
                  if (duration.inMilliseconds >= 400) {
                    isLong = true;
                  }
                }
                if (!isLong) {
                  _handleShortTapError();
                  return;
                }
              }
              _wrongTapCount = 0;
              setState(() => _isAdvancing = true);
              if (isLast) {
                _skipTutorial();
                if (step.onTargetTap != null) step.onTargetTap!();
              } else {
                if (step.onTargetTap != null) step.onTargetTap!();
                _isAdvancing = false;
                _nextStep();
              }
            } else {
              _handleWrongTap();
            }
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onPanUpdate: (details) {
            _handleScroll(-details.delta.dx, -details.delta.dy);
          },
          child: Stack(
            children: [
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: HolePainter(
                  rect: _isEasterEggActive ? null : _targetRect,
                ),
              ),
              if (_targetRect != null &&
                  step.showHighlight &&
                  !_isEasterEggActive)
                Positioned.fromRect(
                  rect: _targetRect!,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withValues(
                                alpha: 0.5 + (_pulseController.value * 0.5),
                              ),
                              width: 4,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (_oldRotomPos != null && _newRotomPos != null)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _lightningController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: MediaQuery.of(context).size,
                        painter: LightningPainter(
                          start: _oldRotomPos!,
                          end: _newRotomPos!,
                          progress: _lightningController.value,
                        ),
                      );
                    },
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutBack,
                top: calcTop,
                bottom: calcBottom,
                left: _easterEggPos != null ? _easterEggPos!.dx : 20,
                width: MediaQuery.of(context).size.width - 40,
                child: _isEasterEggActive
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBubbleContent(
                            step,
                            showBubbleTop,
                            isIntro,
                            isLast,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildRotomIcon(),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: showBubbleTop && !isIntro
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          _buildRotomIcon(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBubbleContent(
                              step,
                              showBubbleTop,
                              isIntro,
                              isLast,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
