import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/tutorial_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorialProvider TDD - Reset All Tutorials & v1.6 Announcement', () {
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tutorialProvider = TutorialProvider(prefs);
    });

    test('resetAllTutorials sets v1_6_update_announced to true', () async {
      await prefs.setBool('home_screen', true);
      await prefs.setBool('v1_6_update_announced', true);
      await prefs.setInt('completed_tutorial_version', 2);

      await tutorialProvider.resetAllTutorials();

      // v1_6_update_announced must be set to true so the update popup does not appear after reset
      expect(prefs.getBool('v1_6_update_announced'), isTrue);
      expect(tutorialProvider.isV16UpdateAnnounced, isTrue);
    });

    test('after resetAllTutorials, seeing home_screen does NOT trigger shouldShowV16UpdatePrompt', () async {
      await tutorialProvider.resetAllTutorials();
      expect(tutorialProvider.isV16UpdateAnnounced, isTrue);

      // Now user starts fresh from home screen
      await tutorialProvider.markFeatureAsSeen('home_screen');

      // Update prompt must stay false!
      expect(tutorialProvider.shouldShowV16UpdatePrompt, isFalse);
    });

    test('fresh new user seeing home_screen does NOT trigger shouldShowV16UpdatePrompt', () async {
      final freshPrefs = await SharedPreferences.getInstance();
      await freshPrefs.clear();
      final freshTut = TutorialProvider(freshPrefs);

      expect(freshTut.shouldShowV16UpdatePrompt, isFalse);

      // Fresh user sees home screen during normal onboarding
      await freshTut.markFeatureAsSeen('home_screen');

      // Must NEVER show v1.6 update prompt to a brand new user!
      expect(freshTut.shouldShowV16UpdatePrompt, isFalse);
    });
  });
}
