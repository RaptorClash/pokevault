import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/widgets/tutorial/tutorial_painters.dart';

void main() {
  group('TutorialPainters Tests', () {
    testWidgets('HolePainter rendert ohne Exception (mit und ohne Loch)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 800),
              painter: HolePainter(rect: null),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is HolePainter,
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 800),
              painter: HolePainter(
                rect: const Rect.fromLTWH(100, 100, 200, 200),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is HolePainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('LightningPainter rendert ohne Exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 800),
              painter: LightningPainter(
                start: const Offset(0, 0),
                end: const Offset(100, 100),
                progress: 0.5,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is LightningPainter,
        ),
        findsOneWidget,
      );
    });
  });
}
