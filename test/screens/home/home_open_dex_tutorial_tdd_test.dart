import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/home/widgets/home_ui_components.dart';
import 'package:pokevault/screens/home/widgets/home_dialogs.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home Dex & Folder Creation Tutorial TDD', () {
    late MockDexProvider mockDexProvider;
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;

    setUp(() async {
      LocaleSettings.setLocale(AppLocale.de);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tutorialProvider = TutorialProvider(prefs);
      mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn([]);
      when(() => mockDexProvider.folders).thenReturn([]);
    });

    testWidgets('HomeBottomSheetMenu triggers folder creation tutorial when home_organize_part1 is seen but folder tutorial not seen', (tester) async {
      await tutorialProvider.markFeatureAsSeen('home_bottom_sheet');
      await tutorialProvider.markFeatureAsSeen('home_organize_part1');

      expect(tutorialProvider.hasSeenFeature('create_folder_step'), isFalse);

      await tester.pumpWidget(
        ChangeNotifierProvider<TutorialProvider>.value(
          value: tutorialProvider,
          child: MaterialApp(
            home: Scaffold(
              body: HomeBottomSheetMenu(
                provider: mockDexProvider,
                currentFolderId: 'root',
                onFolderCreate: () {},
                onDexCreate: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('create_folder_step'));
    });

    testWidgets('showCreateFolderDialog triggers create_folder_dialog tutorial when not seen', (tester) async {
      expect(tutorialProvider.hasSeenFeature('create_folder_dialog'), isFalse);

      await tester.pumpWidget(
        ChangeNotifierProvider<TutorialProvider>.value(
          value: tutorialProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => HomeDialogs.showCreateFolderDialog(
                    context,
                    mockDexProvider,
                    'root',
                  ),
                  child: const Text('Open Folder Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Folder Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('create_folder_dialog'));
    });
  });
}
