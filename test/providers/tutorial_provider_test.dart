import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/widgets/tutorial/tutorial_painters.dart';
import 'package:pokevault/providers/tutorial_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('TutorialProvider Tests', () {
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tutorialProvider = TutorialProvider(prefs);
    });

    test('hasSeenFeature liefert false fuer ungesehene Features', () {
      expect(tutorialProvider.hasSeenFeature('feature_1'), isFalse);
    });

    test('markFeatureAsSeen speichert Feature als gesehen', () async {
      bool notified = false;
      tutorialProvider.addListener(() => notified = true);

      await tutorialProvider.markFeatureAsSeen('feature_1');

      expect(tutorialProvider.hasSeenFeature('feature_1'), isTrue);
      expect(prefs.getBool('feature_1'), isTrue);
      expect(notified, isTrue);
    });

    test('resetTutorial entfernt ein einzelnes Tutorial', () async {
      await tutorialProvider.markFeatureAsSeen('feature_1');
      expect(tutorialProvider.hasSeenFeature('feature_1'), isTrue);

      bool notified = false;
      tutorialProvider.addListener(() => notified = true);

      await tutorialProvider.resetTutorial('feature_1');
      expect(tutorialProvider.hasSeenFeature('feature_1'), isFalse);
      expect(notified, isTrue);
    });

    test('getFeatureStep und updateFatureStep verwalten Schritte', () async {
      expect(tutorialProvider.getFeatureStep('feature_steps'), equals(0));

      bool notified = false;
      tutorialProvider.addListener(() => notified = true);

      await tutorialProvider.updateFatureStep('feature_steps', 2);
      expect(tutorialProvider.getFeatureStep('feature_steps'), equals(2));
      expect(prefs.getInt('feature_steps'), equals(2));
      expect(notified, isTrue);
    });

    test('skipAllTutorials ueberspringt alle Tutorials', () async {
      expect(tutorialProvider.hasSeenFeature('any_feature'), isFalse);

      bool notified = false;
      tutorialProvider.addListener(() => notified = true);

      await tutorialProvider.skipAllTutorials();

      expect(tutorialProvider.hasSeenFeature('any_feature'), isTrue);
      expect(prefs.getBool('skip_all_tutorials'), isTrue);
      expect(notified, isTrue);
    });

    test('resetAllTutorials loescht nur Tutorial-Keys und behaelt System-Keys', () async {
      await prefs.setString('themeMode', 'dark');
      await prefs.setString('language', 'de');
      await prefs.setString('google_client_id', 'id_123');
      await prefs.setBool('migrated_to_sqlite_v2', true);
      await prefs.setBool('tutorial_home', true);
      await prefs.setBool('tutorial_dex', true);

      bool notified = false;
      tutorialProvider.addListener(() => notified = true);

      await tutorialProvider.resetAllTutorials();

      // Tutorial keys should be removed
      expect(prefs.getBool('tutorial_home'), isNull);
      expect(prefs.getBool('tutorial_dex'), isNull);

      // System keys should be preserved
      expect(prefs.getString('themeMode'), equals('dark'));
      expect(prefs.getString('language'), equals('de'));
      expect(prefs.getString('google_client_id'), equals('id_123'));
      expect(prefs.getBool('migrated_to_sqlite_v2'), isTrue);
      expect(notified, isTrue);
    });
  });
}
