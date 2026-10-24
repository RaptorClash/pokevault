import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/widgets/tutorial/rotom_update_welcome_dialog.dart';

void main() {
  group('RotomUpdateWelcomeDialog Widget Tests', () {
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tutorialProvider = TutorialProvider(prefs);
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider<TutorialProvider>.value(
        value: tutorialProvider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const RotomUpdateWelcomeDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('RotomUpdateWelcomeDialog displays v1.6 features and badges', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('v1.6'), findsWidgets);
      expect(find.textContaining('Shiny Hunt'), findsWidgets);
      expect(find.textContaining('Box'), findsWidgets);
      expect(find.textContaining('Statistik'), findsWidgets);
      expect(find.text('Neuheiten-Tour starten'), findsOneWidget);
      expect(find.text('Später ansehen'), findsOneWidget);
    });

    testWidgets('Tapping Neuheiten-Tour starten starts delta tour and pops dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final tourBtn = find.text('Neuheiten-Tour starten');
      await tester.ensureVisible(tourBtn);
      await tester.tap(tourBtn);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(RotomUpdateWelcomeDialog), findsNothing);
      expect(tutorialProvider.isDeltaTourActive, isTrue);
      expect(tutorialProvider.isV16UpdateAnnounced, isTrue);
    });

    testWidgets('Tapping Später ansehen dismisses dialog and marks announced', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Später ansehen'));
      await tester.pumpAndSettle();

      expect(find.byType(RotomUpdateWelcomeDialog), findsNothing);
      expect(tutorialProvider.isDeltaTourActive, isFalse);
      expect(tutorialProvider.isV16UpdateAnnounced, isTrue);
    });
  });
}
