import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/tutorial_step.dart';
import 'package:pokevault/widgets/tutorial/tutorial_ui_components.dart';

void main() {
  group('TutorialBubble Widget Tests', () {
    late AnimationController pulseController;

    setUpAll(() {
      // Setup test binding
    });

    testWidgets('TutorialBubble displays step counter and progress indicator', (
      WidgetTester tester,
    ) async {
      final step = TutorialStep(
        titleKey: 'Test Step Title',
        textKey: 'Test step description text',
        rotomMood: RotomMood.explaining,
      );

      bool skipped = false;
      bool nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  pulseController = AnimationController(
                    vsync: tester,
                    duration: const Duration(seconds: 1),
                  );
                  return TutorialBubble(
                    step: step,
                    showBubbleTop: false,
                    isIntro: true,
                    isLast: false,
                    isEasterEggActive: false,
                    easterEggTriggered: false,
                    stepIndex: 1, // Step 2
                    totalSteps: 5, // of 5
                    pulseAnimation: pulseController,
                    onSkip: () => skipped = true,
                    onNext: () => nextTapped = true,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Check step counter text
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('5'), findsWidgets);

      // Check skip button
      final skipBtn = find.byTooltip('Überspringen');
      final skipText = find.textContaining('Überspringen');
      expect(skipBtn.evaluate().isNotEmpty || skipText.evaluate().isNotEmpty, isTrue);
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn);
        expect(skipped, isTrue);
      }

      // Check next button
      final nextBtn = find.text('Weiter');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      expect(nextTapped, isTrue);
    });

    testWidgets('TutorialBubble renders cleanly without overflow on small 320x480 screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final step = TutorialStep(
        titleKey: 'Langer Tutorial Titel für Testzwecke',
        textKey: 'Dies ist ein ausführlicher Beschreibungstext, um sicherzustellen, dass auf kleinsten Displays keine RenderFlex Überläufe stattfinden.',
        rotomMood: RotomMood.happy,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pulseController = AnimationController(
                  vsync: tester,
                  duration: const Duration(seconds: 1),
                );
                return Center(
                  child: TutorialBubble(
                    step: step,
                    showBubbleTop: false,
                    isIntro: true,
                    isLast: true,
                    isEasterEggActive: false,
                    easterEggTriggered: false,
                    stepIndex: 0,
                    totalSteps: 1,
                    pulseAnimation: pulseController,
                    onSkip: () {},
                    onNext: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
