import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/tutorial_step.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialFeature feature;
  final VoidCallback onFinish;
  final int initialIndex; // NEU: Start-Index
  final Function(int)? onStepChanged; // NEU: Callback bei Schritt-Wechsel

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
            initialIndex: initialIndex, // Übergeben
            onStepChanged: onStepChanged, // Übergeben
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (_currentIndex >= widget.initialIndex) {
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

      bool isHorizontal =
          activeScrollable.axisDirection == AxisDirection.right ||
          activeScrollable.axisDirection == AxisDirection.left;
      if (isHorizontal) return;

      await Scrollable.ensureVisible(
        targetContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: step.scrollAlignment,
      ).catchError((_) {});
    } catch (e) {}
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
        bool showBubbleTop = newRect.top > screenHeight / 2;
        calculatedNewPos = Offset(
          screenWidth / 2,
          showBubbleTop ? newRect.top - 150 : newRect.bottom + 150,
        );
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

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    ScrollableState? scrollable = _findScrollable(
      step.targetKey?.currentContext,
    );

    if (scrollable != null) {
      setState(() {
        _easterEggPos = Offset(
          -MediaQuery.of(context).size.width,
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

    setState(() {
      _isEasterEggActive = false;
      _easterEggPos = null;
      _wrongSwipeCount = 0;
    });
    _calculateTargetRect();
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

  final String rotomSvg = '''
    <svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="-0.45 -0.15 187.2 192.65">
      <g>
        <path fill="#65a9dc" d="M163.05 120.5 L185.0 145.55 Q186.75 147.5 186.5 148.15 186.2 148.8 183.65 147.8 175.15 144.35 139.0 127.75 101.1 110.3 92.85 106.8 91.8 106.35 91.9 105.8 92.0 105.3 93.05 104.8 L107.25 98.2 126.55 89.1 Q113.2 82.45 91.85 72.75 91.55 76.05 89.4 80.15 87.55 83.65 85.4 86.0 90.25 89.4 89.95 95.35 89.65 101.05 85.15 104.45 L86.95 115.8 Q88.05 123.85 88.25 127.55 88.35 129.45 87.9 129.7 87.35 130.0 85.8 128.35 80.75 123.0 71.8 111.05 65.45 112.25 61.05 108.1 56.9 104.2 57.6 99.25 53.45 99.8 47.55 98.25 41.5 96.7 37.75 93.95 36.25 98.05 27.4 117.95 32.15 119.7 61.75 128.35 63.6 128.85 62.05 130.5 L3.4 190.2 Q1.15 192.5 0.35 192.15 -0.45 191.8 0.45 189.2 3.9 178.8 11.55 160.9 19.65 142.0 27.25 127.05 L5.6 127.25 3.05 126.95 Q2.6 126.55 3.85 124.95 24.0 98.9 32.85 88.2 25.9 79.35 28.1 66.4 30.35 52.95 41.05 45.8 40.05 33.45 39.6 21.05 39.05 6.8 39.75 2.7 40.25 0.1 41.05 0.0 41.85 -0.15 43.6 2.1 51.3 12.15 64.65 39.9 75.35 39.1 83.45 45.75 92.0 52.7 92.6 64.1 103.25 67.3 122.5 73.55 L154.1 83.9 Q155.25 84.3 155.4 84.75 155.5 85.2 154.65 85.85 L141.15 95.35 163.05 120.5"/>
        <path fill="#bbe1e8" d="M90.85 64.2 Q90.9 65.0 91.75 65.3 104.75 68.95 152.7 85.2 L139.85 94.75 Q139.3 95.1 140.0 96.0 L158.45 117.3 182.8 145.75 Q170.85 140.6 138.0 125.6 L94.55 105.75 Q102.65 101.8 128.3 89.8 128.8 89.55 128.65 89.1 L128.0 88.4 Q102.6 75.9 91.65 71.0 90.65 70.6 90.5 71.75 89.95 75.25 88.2 79.05 86.45 82.85 84.0 85.8 83.45 86.4 84.4 87.15 88.4 90.0 88.0 95.25 87.6 100.1 84.05 103.3 83.55 103.75 83.65 104.7 L85.2 114.0 Q86.45 121.7 86.8 127.2 83.8 124.0 79.95 119.25 L72.7 110.1 Q72.35 109.65 71.4 109.65 65.05 110.2 61.55 106.3 58.55 102.9 59.3 99.0 L59.2 98.2 58.2 98.0 Q53.15 98.3 47.5 96.6 41.9 94.95 38.0 92.1 37.05 91.45 36.65 92.5 L32.3 103.05 25.8 117.8 Q25.4 118.75 26.4 119.15 L40.6 123.65 60.45 129.8 2.5 188.85 Q4.85 180.6 15.0 157.2 24.65 134.95 29.1 126.9 29.8 125.65 28.05 125.65 L5.25 125.85 Q14.2 114.0 34.35 88.95 34.8 88.3 34.15 87.45 27.55 78.55 30.4 65.35 33.15 52.5 42.25 46.85 42.75 46.5 42.6 45.35 L41.55 24.6 Q40.9 8.65 41.3 3.7 41.45 2.65 41.7 2.6 41.95 2.55 42.6 3.45 50.05 14.25 63.25 40.7 63.5 41.3 64.45 41.2 72.4 40.4 80.0 45.35 89.7 51.65 90.85 64.2"/>
        <path fill="#f19963" d="M85.25 59.7 Q87.95 66.7 85.4 74.6 82.8 82.8 75.55 88.5 77.8 88.55 79.6 90.2 81.35 91.85 81.85 94.2 82.95 100.05 75.95 103.15 68.75 106.3 65.3 101.75 62.1 97.5 65.1 92.65 56.45 95.5 48.0 92.6 38.35 89.25 35.6 79.8 32.9 70.3 37.15 60.8 40.85 52.45 47.4 48.5 45.95 39.95 45.0 27.4 44.05 14.5 44.95 14.35 45.9 14.2 52.15 26.45 57.85 37.7 61.4 46.05 70.35 45.2 77.1 49.65 82.85 53.5 85.25 59.7"/>
        <path fill="#ffffff" d="M23.0 118.95 L25.7 120.9 24.8 122.75 10.2 122.5 22.45 107.1 Q31.05 96.05 33.8 93.15 L23.0 118.95"/>
        <path fill="#ffffff" d="M26.65 140.25 L32.55 126.8 Q45.1 130.3 51.2 131.6 L27.5 156.35 20.9 152.3 Q23.3 147.85 26.65 140.25"/>
        <path fill="#ffffff" d="M23.95 160.05 L17.4 168.05 9.7 177.0 13.9 167.45 18.7 157.1 21.25 158.6 23.95 160.05"/>
        <path fill="#ffffff" d="M93.8 68.0 Q101.65 70.35 116.75 75.95 L137.25 83.6 Q132.2 85.9 130.1 87.05 122.35 82.75 93.05 69.25 L93.8 68.0"/>
        <path fill="#ffffff" d="M138.15 88.25 L140.75 91.1 134.3 95.5 151.7 115.4 Q145.1 120.3 141.8 122.4 L126.45 113.65 107.8 103.7 123.55 95.6 Q132.85 90.85 138.15 88.25"/>
        <path fill="#ffffff" d="M162.05 126.85 L169.5 136.1 Q167.15 134.7 158.85 130.6 150.45 126.45 146.45 124.1 L150.7 120.95 154.3 118.2 162.05 126.85"/>
        <path fill="#ffffff" d="M36.55 62.65 Q41.9 67.0 44.9 72.4 48.25 78.5 45.85 81.8 44.7 83.35 41.0 81.8 37.65 80.45 35.45 78.15 34.7 74.2 34.9 70.4 35.1 65.95 36.55 62.65"/>
        <path fill="#ffffff" d="M69.3 50.6 Q72.25 50.65 74.0 55.6 75.4 59.55 75.45 64.35 75.55 68.65 73.8 72.75 71.8 77.35 69.0 77.35 66.3 77.35 64.4 72.5 62.8 68.35 62.8 64.1 62.8 59.4 64.2 55.55 66.0 50.55 69.3 50.6"/>
        <path fill="#007bba" d="M35.5 66.25 Q38.9 68.9 41.75 73.05 45.0 77.75 43.65 79.45 43.15 80.15 40.3 78.1 37.15 75.85 34.8 72.5 34.7 70.2 35.5 66.25"/>
        <path fill="#007bba" d="M69.15 54.0 Q72.0 54.2 72.15 64.3 72.2 67.6 71.4 70.65 70.45 74.1 69.1 74.0 67.8 73.85 66.85 70.4 66.15 67.65 65.95 64.2 65.75 60.85 66.6 57.65 67.5 53.95 69.15 54.0"/>
        <path fill="#d18456" d="M85.8 73.15 Q83.65 82.5 75.55 88.5 81.25 90.05 81.9 94.45 82.6 99.25 75.75 103.25 70.55 106.3 66.4 102.75 62.15 99.1 64.9 92.8 55.8 94.9 49.0 92.85 40.7 90.3 37.05 81.75 42.35 86.5 50.25 87.45 57.95 88.35 65.6 85.45 73.55 82.4 78.75 76.15 84.5 69.25 85.5 60.0 87.4 66.05 85.8 73.15"/>
        <path fill="#f8ceb0" d="M49.55 58.05 Q48.7 59.5 47.3 60.05 L44.7 59.9 Q43.55 59.25 43.35 57.75 43.15 56.25 44.0 54.8 44.8 53.35 46.25 52.8 L48.85 52.95 Q50.0 53.65 50.2 55.15 50.4 56.65 49.55 58.05"/>
        <path fill="#0d131a" d="M84.8 57.05 Q88.25 63.9 86.8 72.2 85.1 82.15 76.55 88.35 80.8 89.0 82.3 93.05 83.3 95.75 81.5 99.0 79.6 102.45 75.65 104.05 71.95 105.55 68.3 104.5 64.8 103.45 63.6 100.85 62.9 99.4 63.1 97.3 63.3 95.25 64.15 93.55 54.25 95.65 46.9 92.85 39.55 90.1 36.15 83.0 32.05 74.25 35.1 64.1 38.15 53.8 46.75 48.5 45.4 40.05 44.5 30.0 43.55 19.45 43.85 15.25 43.95 13.55 44.5 13.3 45.1 13.0 46.05 14.35 48.7 18.1 54.4 29.35 59.85 40.1 61.9 45.4 68.3 44.6 74.25 47.2 81.35 50.25 84.8 57.05 M84.7 74.0 Q86.95 65.35 83.15 57.85 80.0 51.65 73.6 48.6 67.6 45.7 61.3 46.75 60.8 46.85 60.65 46.45 L54.1 32.45 Q50.1 24.2 45.75 16.15 L45.3 15.75 45.1 16.25 Q45.3 27.0 48.25 48.55 L48.25 48.6 47.95 49.15 Q39.75 54.05 36.8 64.2 33.95 74.05 37.8 82.2 41.1 89.2 47.8 91.7 54.55 94.3 64.5 92.2 L65.65 92.25 Q65.9 92.55 65.45 93.45 63.65 97.1 65.0 100.1 66.0 102.25 68.85 103.05 71.8 103.9 75.0 102.6 78.4 101.2 80.15 98.35 81.8 95.6 81.0 93.35 80.3 91.4 78.85 90.45 77.75 89.7 75.95 89.4 75.0 89.3 74.9 88.75 74.8 88.25 75.65 87.65 82.5 82.5 84.7 74.0"/>
        <path fill="#0d131a" d="M64.4 79.0 Q65.0 78.15 65.35 78.35 65.7 78.5 65.2 79.4 63.25 83.1 58.75 84.55 54.15 86.0 50.6 83.7 49.8 83.2 50.05 82.9 L51.1 82.95 Q54.4 84.45 58.3 83.3 62.15 82.15 64.4 79.0"/>
        <path fill="#0d131a" d="M64.1 54.15 Q66.25 50.15 69.15 50.15 72.05 50.15 74.15 54.15 76.25 58.25 76.25 64.0 76.25 69.8 74.15 73.9 72.05 77.9 69.15 77.9 66.25 77.9 64.1 73.9 61.95 69.8 61.95 64.0 61.95 58.25 64.1 54.15 M69.15 51.4 Q66.85 51.4 65.25 55.15 63.6 58.85 63.6 64.0 63.6 69.15 65.25 72.9 66.85 76.65 69.15 76.65 71.4 76.65 73.05 72.9 74.65 69.15 74.65 64.0 74.65 58.85 73.05 55.15 71.4 51.4 69.15 51.4"/>
        <path fill="#0d131a" d="M66.35 56.65 Q67.45 53.35 69.15 53.35 70.8 53.35 71.85 56.7 72.85 59.8 72.85 64.0 72.85 68.2 71.85 71.3 70.8 74.65 69.15 74.65 67.45 74.65 66.35 71.3 65.3 68.15 65.3 63.95 65.3 59.75 66.35 56.65 M70.6 57.05 Q69.85 54.6 69.15 54.6 68.4 54.6 67.7 57.05 66.8 59.9 66.8 64.0 66.8 68.15 67.7 71.0 68.4 73.4 69.15 73.4 69.85 73.4 70.6 71.0 71.45 68.1 71.45 64.0 71.45 59.9 70.6 57.05"/>
        <path fill="#0d131a" d="M62.95 64.85 L62.95 63.55 66.1 63.7 66.1 64.85 62.95 64.85"/>
        <path fill="#0d131a" d="M75.55 63.85 L75.25 65.0 72.15 64.85 72.15 63.7 75.55 63.85"/>
        <path fill="#0d131a" d="M36.0 79.25 L35.7 77.15 Q39.05 80.35 41.9 81.4 44.3 82.25 45.35 81.4 46.55 80.45 45.85 77.2 45.0 73.55 42.15 69.75 39.05 65.6 36.45 63.45 L37.05 62.35 Q39.7 64.15 43.3 68.8 46.45 72.95 47.15 77.1 47.85 80.95 46.15 82.35 44.8 83.5 42.25 82.85 39.3 82.1 36.0 79.25"/>
        <path fill="#0d131a" d="M34.5 73.45 L35.0 71.8 Q36.9 74.6 39.8 77.1 42.65 79.5 43.35 79.05 43.9 78.7 42.65 76.2 41.65 74.2 40.35 72.35 38.45 69.65 35.2 66.7 L35.65 65.5 38.45 68.0 41.5 71.45 Q43.05 73.75 43.95 76.05 45.1 79.05 44.05 79.95 42.95 80.9 39.9 78.7 37.0 76.65 34.5 73.45"/>
        <path fill="#0d131a" d="M41.3 72.1 L40.45 71.25 42.65 69.4 43.4 70.45 41.3 72.1"/>
        <path fill="#0d131a" d="M36.25 74.6 L37.0 75.65 35.35 77.15 34.85 76.1 36.25 74.6"/>
      </g>
    </svg>
  ''';

  Widget _buildRotomIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _pulseController.value),
          child: child,
        );
      },
      child: SvgPicture.string(rotomSvg, width: 90, height: 90),
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
              TextButton(
                onPressed: _isEasterEggActive ? null : _skipTutorial,
                child: Text(
                  Translator.get('tutorial_skip'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              if (showNextBtn)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _isEasterEggActive ? null : _nextStep,
                  child: Text(
                    Translator.get(
                      isLast ? 'tutorial_finish' : 'tutorial_next',
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

    bool showBubbleTop =
        _targetRect != null && _targetRect!.top > screenHeight / 2;
    bool isIntro = _targetRect == null;

    return Material(
      type: MaterialType.transparency,
      child: Listener(
        onPointerUp: (event) {
          TutorialOverlay.lastTapPosition = event.position;
          if (_isAdvancing) return;

          if (step.requireTargetTap &&
              _targetRect != null &&
              !_isEasterEggActive) {
            if (_targetRect!.contains(event.localPosition)) {
              setState(() => _isAdvancing = true);
              if (isLast) {
                _skipTutorial();
                if (step.onTargetTap != null) step.onTargetTap!();
              } else {
                if (step.onTargetTap != null) step.onTargetTap!();
                _isAdvancing = false;
                _nextStep();
              }
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
                              color: Colors.amber.withOpacity(
                                0.5 + (_pulseController.value * 0.5),
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
                top: _easterEggPos != null
                    ? _easterEggPos!.dy
                    : (isIntro
                          ? (screenHeight / 2) - 100
                          : (showBubbleTop ? null : _targetRect!.bottom + 30)),
                bottom: _easterEggPos != null || isIntro
                    ? null
                    : (showBubbleTop
                          ? screenHeight - _targetRect!.top + 30
                          : null),
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

class HolePainter extends CustomPainter {
  final Rect? rect;
  HolePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (rect != null) {
      final holePath = Path()
        ..addRRect(RRect.fromRectAndRadius(rect!, const Radius.circular(16)));
      final combinedPath = Path.combine(
        PathOperation.difference,
        screenPath,
        holePath,
      );
      canvas.drawPath(combinedPath, paint);
    } else {
      canvas.drawPath(screenPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) =>
      oldDelegate.rect != rect;
}

class LightningPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;

  LightningPainter({
    required this.start,
    required this.end,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0 || progress <= 0.0) return;
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity((1.0 - progress).clamp(0.0, 1.0))
      ..strokeWidth = 3 + (5 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    int steps = 6;
    for (int i = 1; i <= steps; i++) {
      double t = i / steps;
      double dx = lerpDouble(start.dx, end.dx, t)!;
      double dy = lerpDouble(start.dy, end.dy, t)!;

      if (i < steps) {
        dx += (i % 2 == 0 ? 30 : -30);
        dy += (i % 2 == 0 ? -30 : 30);
      }
      path.lineTo(dx, dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.start != start;
}
