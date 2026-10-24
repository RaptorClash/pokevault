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

    test('shouldShowV16UpdatePrompt returns false for fresh users', () {
      expect(tutorialProvider.shouldShowV16UpdatePrompt, isFalse);
    });

    test('shouldShowV16UpdatePrompt returns true for existing users with completed base tutorial', () async {
      final existingPrefs = await SharedPreferences.getInstance();
      await existingPrefs.clear();
      await existingPrefs.setBool('home_screen', true);
      final existingTut = TutorialProvider(existingPrefs);
      expect(existingTut.shouldShowV16UpdatePrompt, isTrue);
    });

    test('shouldShowV16UpdatePrompt returns false if skipped or already announced', () async {
      final existingPrefs = await SharedPreferences.getInstance();
      await existingPrefs.clear();
      await existingPrefs.setBool('home_screen', true);
      final existingTut = TutorialProvider(existingPrefs);
      expect(existingTut.shouldShowV16UpdatePrompt, isTrue);

      await existingTut.dismissV16UpdatePrompt();
      expect(existingTut.shouldShowV16UpdatePrompt, isFalse);
    });

    test('dismissV16UpdatePrompt marks prompt as seen and notifies', () async {
      bool notified = false;
      tutorialProvider.addListener(() => notified = true);

      await tutorialProvider.dismissV16UpdatePrompt();
      expect(tutorialProvider.isV16UpdateAnnounced, isTrue);
      expect(notified, isTrue);
    });

    test('completeV16Tutorial updates completedTutorialVersion to 2', () async {
      await tutorialProvider.completeV16Tutorial();
      expect(tutorialProvider.completedTutorialVersion, equals(2));
      expect(tutorialProvider.isV16UpdateAnnounced, isTrue);
      expect(tutorialProvider.shouldShowV16UpdatePrompt, isFalse);
    });

    test('isChapterCompleted and resetChapter manage chapter feature keys', () async {
      // module_box_management has keys: box_management, box_drag_shift
      expect(tutorialProvider.isChapterCompleted('module_box_management'), isFalse);

      await tutorialProvider.markFeatureAsSeen('box_management');
      expect(tutorialProvider.isChapterCompleted('module_box_management'), isFalse);

      await tutorialProvider.markFeatureAsSeen('box_drag_shift');
      expect(tutorialProvider.isChapterCompleted('module_box_management'), isTrue);

      bool notified = false;
      tutorialProvider.addListener(() => notified = true);
      await tutorialProvider.resetChapter('module_box_management');

      expect(tutorialProvider.isChapterCompleted('module_box_management'), isFalse);
      expect(tutorialProvider.hasSeenFeature('box_management'), isFalse);
      expect(tutorialProvider.hasSeenFeature('box_drag_shift'), isFalse);
      expect(notified, isTrue);
    });

    test('markChapterSeen marks all feature keys of a chapter', () async {
      await tutorialProvider.markChapterSeen('module_box_management');
      expect(tutorialProvider.hasSeenFeature('box_management'), isTrue);
      expect(tutorialProvider.hasSeenFeature('box_drag_shift'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_box_management'), isTrue);
    });

    test('startV16DeltaTour marks announcement and activates delta tour', () async {
      await tutorialProvider.markChapterSeen('module_box_management');
      await tutorialProvider.markChapterSeen('module_shiny_hunt');

      await tutorialProvider.startV16DeltaTour();

      expect(tutorialProvider.isV16UpdateAnnounced, isTrue);
      expect(tutorialProvider.isDeltaTourActive, isTrue);
      // Reset new feature keys for guided experience
      expect(tutorialProvider.hasSeenFeature('box_management'), isFalse);
      expect(tutorialProvider.hasSeenFeature('shiny_hunt_hub'), isFalse);
    });

    test('endDeltaTour deactivates the delta tour mode', () async {
      await tutorialProvider.startV16DeltaTour();
      expect(tutorialProvider.isDeltaTourActive, isTrue);

      tutorialProvider.endDeltaTour();
      expect(tutorialProvider.isDeltaTourActive, isFalse);
    });
  });
}

