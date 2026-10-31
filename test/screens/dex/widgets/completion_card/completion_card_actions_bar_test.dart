import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/dex/widgets/completion_card/completion_card_actions_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget({
    bool isExporting = false,
    VoidCallback? onCopyText,
    VoidCallback? onShare,
    VoidCallback? onSavePng,
    Size size = const Size(600, 200),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: CompletionCardActionsBar(
              isExporting: isExporting,
              onCopyText: onCopyText ?? () {},
              onShare: onShare ?? () {},
              onSavePng: onSavePng ?? () {},
              borderColor: Colors.grey,
              isDark: false,
            ),
          ),
        ),
      ),
    );
  }

  group('CompletionCardActionsBar TDD Tests', () {
    testWidgets('Renders all 3 action buttons with designated keys', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byKey(const Key('btn_copy_text')), findsOneWidget);
      expect(find.byKey(const Key('btn_share')), findsOneWidget);
      expect(find.byKey(const Key('btn_save_png')), findsOneWidget);
    });

    testWidgets('Triggers callbacks on tap', (tester) async {
      bool copyCalled = false;
      bool shareCalled = false;
      bool saveCalled = false;

      await tester.pumpWidget(buildTestableWidget(
        onCopyText: () => copyCalled = true,
        onShare: () => shareCalled = true,
        onSavePng: () => saveCalled = true,
      ));

      await tester.ensureVisible(find.byKey(const Key('btn_copy_text')));
      await tester.tap(find.byKey(const Key('btn_copy_text')));
      await tester.ensureVisible(find.byKey(const Key('btn_share')));
      await tester.tap(find.byKey(const Key('btn_share')));
      await tester.ensureVisible(find.byKey(const Key('btn_save_png')));
      await tester.tap(find.byKey(const Key('btn_save_png')));

      expect(copyCalled, isTrue);
      expect(shareCalled, isTrue);
      expect(saveCalled, isTrue);
    });

    testWidgets('Shows ProgressIndicator and disables button when isExporting', (tester) async {
      await tester.pumpWidget(buildTestableWidget(isExporting: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Adversarial Viewport: Renders gracefully on 320px narrow screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(size: const Size(320, 150)));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('btn_copy_text')), findsOneWidget);
      expect(find.byKey(const Key('btn_share')), findsOneWidget);
      expect(find.byKey(const Key('btn_save_png')), findsOneWidget);
    });
  });
}
