import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/tutorial_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorialProvider Tests', () {
    late TutorialProvider tutorialProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tutorialProvider = TutorialProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('Standardmäßig wurde kein Feature gesehen', () {
      expect(tutorialProvider.hasSeenFeature('home_screen'), isFalse);
      expect(tutorialProvider.getFeatureStep('home_screen'), equals(0));
    });

    test('markFeatureAsSeen speichert den Status korrekt', () async {
      await tutorialProvider.markFeatureAsSeen('home_screen');

      expect(tutorialProvider.hasSeenFeature('home_screen'), isTrue);
    });

    test(
      'resetTutorial und resetAllTutorials setzen den Status zurück',
      () async {
        await tutorialProvider.markFeatureAsSeen('home_screen');
        await tutorialProvider.markFeatureAsSeen('pokemon_details');

        expect(tutorialProvider.hasSeenFeature('home_screen'), isTrue);

        await tutorialProvider.resetTutorial('home_screen');
        expect(tutorialProvider.hasSeenFeature('home_screen'), isFalse);
        expect(tutorialProvider.hasSeenFeature('pokemon_details'), isTrue);

        await tutorialProvider.resetAllTutorials();
        expect(tutorialProvider.hasSeenFeature('pokemon_details'), isFalse);
      },
    );

    test('updateFatureStep speichert den aktuellen Schritt', () async {
      await tutorialProvider.updateFatureStep('create_dex_sheet', 3);

      expect(tutorialProvider.getFeatureStep('create_dex_sheet'), equals(3));
    });
  });
}
