import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/tutorial_step.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:pokevault/widgets/tutorial/tutorial_ui_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TutorialOverlay enforces max width of 580px for bubble on widescreen (1920x1080)', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tutorialProvider = TutorialProvider(prefs);

    final feature = TutorialFeature(
      id: 'widescreen_test',
      nameKey: 'test',
      steps: [
        TutorialStep(
          targetKey: null,
          titleKey: 'Widescreen Title',
          textKey: 'Widescreen content description that is short',
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<TutorialProvider>.value(
        value: tutorialProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    TutorialOverlay.show(context, feature, () {});
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TutorialBubble), findsOneWidget);

    // The bubble size on screen must not exceed 580px wide
    final bubbleFinder = find.byType(TutorialBubble);
    final bubbleSize = tester.getSize(bubbleFinder);
    expect(bubbleSize.width, lessThanOrEqualTo(580.0));
  });
}
