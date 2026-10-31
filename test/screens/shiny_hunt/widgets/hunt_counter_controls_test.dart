import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/screens/shiny_hunt/widgets/hunt_counter_controls.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.de);
  });

  Widget buildTestWidget({
    int currentEncounters = 10,
    int incrementStep = 1,
    int? customStep,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
    ValueChanged<int>? onStepSelected,
    VoidCallback? onCustomStepPressed,
    VoidCallback? onRecordPhase,
    VoidCallback? onCaught,
    double screenWidth = 400,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 600)),
        child: Scaffold(
          body: HuntCounterControls(
            currentEncounters: currentEncounters,
            incrementStep: incrementStep,
            customStep: customStep,
            onIncrement: onIncrement ?? () {},
            onDecrement: onDecrement ?? () {},
            onStepSelected: onStepSelected ?? (_) {},
            onCustomStepPressed: onCustomStepPressed ?? () {},
            onRecordPhase: onRecordPhase ?? () {},
            onCaught: onCaught ?? () {},
          ),
        ),
      ),
    );
  }

  group('HuntCounterControls TDD Tests', () {
    testWidgets('Renders step chips, +/- buttons, phase button and caught button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('+1'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.history_toggle_off), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('Step selection dispatches callback', (tester) async {
      int? selectedStep;

      await tester.pumpWidget(buildTestWidget(
        incrementStep: 1,
        onStepSelected: (s) => selectedStep = s,
      ));

      await tester.tap(find.text('+5'));
      await tester.pump();

      expect(selectedStep, 5);
    });

    testWidgets('Minus button is disabled when currentEncounters is 0', (tester) async {
      bool decremented = false;

      await tester.pumpWidget(buildTestWidget(
        currentEncounters: 0,
        onDecrement: () => decremented = true,
      ));

      await tester.tap(find.byIcon(Icons.remove));
      expect(decremented, isFalse);
    });

    testWidgets('Buttons dispatch increment, decrement, phase and caught actions', (tester) async {
      bool incClicked = false;
      bool decClicked = false;
      bool phaseClicked = false;
      bool caughtClicked = false;

      await tester.pumpWidget(buildTestWidget(
        currentEncounters: 5,
        onIncrement: () => incClicked = true,
        onDecrement: () => decClicked = true,
        onRecordPhase: () => phaseClicked = true,
        onCaught: () => caughtClicked = true,
      ));

      await tester.tap(find.byIcon(Icons.add));
      expect(incClicked, isTrue);

      await tester.tap(find.byIcon(Icons.remove));
      expect(decClicked, isTrue);

      await tester.tap(find.byIcon(Icons.history_toggle_off));
      expect(phaseClicked, isTrue);

      await tester.tap(find.byIcon(Icons.auto_awesome));
      expect(caughtClicked, isTrue);
    });

    testWidgets('Adversarial Viewport: Renders on 320px narrow screen without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(screenWidth: 320));

      expect(tester.takeException(), isNull);
    });
  });
}
