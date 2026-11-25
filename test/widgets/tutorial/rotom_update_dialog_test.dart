import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';
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

    testWidgets('RotomUpdateWelcomeDialog scanner mode renders platform-specific Mobile vs Desktop highlights', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.de);
      TrackerPlatformHelper.debugIsMobileOverride = () => true;
      TrackerPlatformHelper.debugIsDesktopOverride = () => false;
      addTearDown(TrackerPlatformHelper.resetDebugOverrides);

      await tester.pumpWidget(
        ChangeNotifierProvider<TutorialProvider>.value(
          value: tutorialProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => RotomUpdateWelcomeDialog.show(
                    context,
                    updateType: RotomUpdateType.scanner,
                  ),
                  child: const Text('Show Scanner Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Scanner Dialog'));
      await tester.pumpAndSettle();

      // Mobile variant highlights Camera/PiP AND Multi-Hunt/Auto-Counter, not Windows HUD
      expect(find.textContaining('Kamera'), findsWidgets);
      expect(find.textContaining('PiP'), findsWidgets);
      expect(find.textContaining('Multi-Hunt'), findsWidgets);
      expect(find.textContaining('Floating HUD'), findsNothing);

      final startBtn = find.text('Neuheiten-Tour starten');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();
      expect(tutorialProvider.isScannerDeltaTourActive, isTrue);
    });

    testWidgets('RotomUpdateWelcomeDialog v1.7 Desktop mode includes Floating HUD and Multi-Hunt/Auto-Counter', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.de);
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      addTearDown(TrackerPlatformHelper.resetDebugOverrides);

      await tester.pumpWidget(
        ChangeNotifierProvider<TutorialProvider>.value(
          value: tutorialProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => RotomUpdateWelcomeDialog.show(
                    context,
                    updateType: RotomUpdateType.scanner,
                  ),
                  child: const Text('Show Desktop Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Desktop Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('UPDATE v1.7'), findsWidgets);
      expect(find.textContaining('Floating HUD'), findsWidgets);
      expect(find.textContaining('Multi-Hunt'), findsWidgets);
    });
  });
}
