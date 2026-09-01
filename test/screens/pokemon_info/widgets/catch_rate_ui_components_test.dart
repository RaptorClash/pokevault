import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/utils/catch_rate/models.dart';
import 'package:pokevault/utils/catch_rate/strategy_base.dart';
import 'package:pokevault/screens/pokemon_info/widgets/catch_rate_ui_components.dart';
import 'package:pokevault/l10n/app_translations.dart';

void main() {
  group('CatchRateResultCard Widget Tests', () {
    final strategy = CatchRateStrategyFactory.getStrategy(9.0);

    setUp(() {
      Translator.currentLanguage = 'de';
    });

    testWidgets('Rendert garantierten Fang in Grün', (
      WidgetTester tester,
    ) async {
      final guaranteedResult = CatchRateResult(
        catchChance: 100.0,
        critChance: 0.0,
        bonus: 1.0,
        baseRate: 255,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatchRateResultCard(
              result: guaranteedResult,
              strategy: strategy,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border!.top.color, equals(Colors.green));
    });

    testWidgets('Zeigt Glitch-Warnungen an, wenn vorhanden', (
      WidgetTester tester,
    ) async {
      final glitchResult = CatchRateResult(
        catchChance: 50.0,
        critChance: 5.0,
        bonus: 1.5,
        baseRate: 45,
        glitchText: 'Achtung: Gen 1 Superball Glitch!',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatchRateResultCard(result: glitchResult, strategy: strategy),
          ),
        ),
      );

      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(find.text('Achtung: Gen 1 Superball Glitch!'), findsOneWidget);
    });
  });
}
