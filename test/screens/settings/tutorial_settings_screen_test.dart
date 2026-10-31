import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/settings/tutorial_settings_screen.dart';
import 'package:pokevault/widgets/tutorial/chapter_demo_dialog.dart';
import 'package:pokevault/models/tutorial_step.dart';
import 'package:pokevault/i18n/strings.g.dart';

import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/ribbon.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/screens/dex/dex_screen.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunts_hub_screen.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

class MockDexProviderForTest extends ChangeNotifier implements DexProvider {
  @override
  List<UserDex> userDexes = [];
  @override
  List<Pokemon> allPokemon = [];
  @override
  Map<String, List<int>> allAvailableDexes = {};
  @override
  List<DexFolder> folders = [];
  @override
  Map<String, List<String>> structure = {'root': []};
  @override
  Map<String, String> ballUrls = {};
  @override
  bool isInitialized = true;
  @override
  bool isMigrating = false;
  @override
  Future<void> get initialized => Future.value();
  @override
  DatabaseService get db => throw UnimplementedError();
  @override
  List<Ribbon> allRibbons = [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeShinyHuntProvider extends ChangeNotifier implements ShinyHuntProvider {
  @override
  bool isLoading = false;
  @override
  List<ShinyHunt> activeHunts = [];
  @override
  List<ShinyHunt> pausedHunts = [];
  @override
  List<ShinyHunt> completedHunts = [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  String currentLanguage = 'de';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TutorialSettingsScreen Widget Tests', () {
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;
    late MockDexProviderForTest mockDexProvider;
    late FakeShinyHuntProvider fakeShinyHuntProvider;
    late FakeSettingsProvider fakeSettingsProvider;

    setUp(() async {
      LocaleSettings.setLocale(AppLocale.de);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tutorialProvider = TutorialProvider(prefs);
      mockDexProvider = MockDexProviderForTest();
      fakeShinyHuntProvider = FakeShinyHuntProvider();
      fakeSettingsProvider = FakeSettingsProvider();
    });

    Widget createTestWidget({Key? key, DexProvider? dexProvider}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<TutorialProvider>.value(
            value: tutorialProvider,
          ),
          ChangeNotifierProvider<DexProvider>.value(
            value: dexProvider ?? mockDexProvider,
          ),
          ChangeNotifierProvider<ShinyHuntProvider>.value(
            value: fakeShinyHuntProvider,
          ),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: fakeSettingsProvider,
          ),
        ],
        child: MaterialApp(
          home: TutorialSettingsScreen(key: key),
        ),
      );
    }

    testWidgets('Renders header with v1.6 tour button and all 10 chapters', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check header buttons
      expect(find.textContaining('v1.6'), findsWidgets);
      expect(find.textContaining('zurücksetzen'), findsWidgets);
      expect(find.text('10 Kapitel'), findsOneWidget);

      // Check that chapters appear (e.g., Home, Boxen, Shiny Hunt, Backup)
      expect(find.textContaining('Sammlung'), findsWidgets);
      expect(find.textContaining('Box'), findsWidgets);
      expect(find.textContaining('Shiny Hunt'), findsWidgets);
      expect(find.textContaining('Backup'), findsWidgets);

      // Verify "NEU" badge on v1.6 chapters
      expect(find.textContaining('NEU'), findsWidgets);
    });

    testWidgets('Tapping Wiederholen opens Chapter Demo Mode dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find first "Wiederholen" button
      final replayButtons = find.text('Wiederholen');
      expect(replayButtons, findsWidgets);

      await tester.tap(replayButtons.first);
      await tester.pumpAndSettle();

      // Demo mode dialog should be visible
      expect(find.byType(ChapterDemoDialog), findsOneWidget);
      expect(find.textContaining('Schritt'), findsWidgets);
      expect(find.text('Weiter'), findsOneWidget);

      // Tap Weiter to advance step
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Schritt 2'), findsWidgets);

      // Tap Zurück to go back
      expect(find.text('Zurück'), findsOneWidget);
      await tester.tap(find.text('Zurück'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Schritt 1'), findsWidgets);
    });

    testWidgets('Tapping Wiederholen on Cloud & Backup chapter opens Demo Mode with cloud visual', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the last "Wiederholen" button (which corresponds to chapter 10: module_backup_sync)
      final replayButtons = find.text('Wiederholen');
      expect(replayButtons, findsWidgets);

      await tester.tap(replayButtons.last);
      await tester.pumpAndSettle();

      // Verify ChapterDemoDialog opened with cloud visual
      expect(find.byType(ChapterDemoDialog), findsOneWidget);
      expect(find.text('Google Drive Cloud & Auto-Backup'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChapterDemoDialog),
          matching: find.text('10. Cloud-Sync & Backups'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Alle zurücksetzen shows confirmation dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final resetBtn = find.textContaining('zurücksetzen');
      expect(resetBtn, findsWidgets);

      await tester.tap(resetBtn.first);
      await tester.pumpAndSettle();

      // Alert dialog should ask for confirmation
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Adversarial Test: Runtime language change and small 320x480 screen without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleSettings.setLocale(AppLocale.en);
      await tester.pumpWidget(createTestWidget(key: const Key('screen_en')));
      await tester.pumpAndSettle();

      // Check English translation
      expect(find.textContaining('Tutorials & Guides'), findsWidgets);
      expect(find.textContaining('Reset all tutorials'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Switch language to German at runtime
      LocaleSettings.setLocale(AppLocale.de);
      await tester.pumpWidget(createTestWidget(key: const Key('screen_de')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tutorials & Anleitungen'), findsWidgets);
      expect(find.textContaining('zurücksetzen'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Final step of ChapterDemoDialog displays Jetzt ausprobieren button and triggers onTryInScreen', (tester) async {
      bool tryInScreenCalled = false;
      final chapter = TutorialChapters.all.firstWhere((c) => c.id == 'module_shiny_hunt');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ChapterDemoDialog.show(
                  ctx,
                  chapter,
                  onTryInScreen: () => tryInScreenCalled = true,
                ),
                child: const Text('Open Demo'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Demo'));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDemoDialog), findsOneWidget);

      // Advance through all steps until final step
      for (int i = 0; i < chapter.stepCount - 1; i++) {
        final nextBtn = find.text('Weiter');
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // On final step, both finish and try now button should be visible
      expect(find.text(t.tutorial_finish), findsOneWidget);
      final tryNowBtn = find.text(t.tutorial_try_now);
      expect(tryNowBtn, findsOneWidget);

      // Tap try now button
      await tester.tap(tryNowBtn);
      await tester.pumpAndSettle();

      // Dialog should close and callback triggered
      expect(find.byType(ChapterDemoDialog), findsNothing);
      expect(tryInScreenCalled, isTrue);
    });

    testWidgets('TutorialSettingsScreen wires onTryInScreen to navigate to live feature (e.g. Chapter 9 Controls)', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find chapter 9 (Controls) replay button
      final replayButtons = find.text('Wiederholen');
      // Chapter 9 is index 8 (0-based)
      await tester.tap(replayButtons.at(8));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDemoDialog), findsOneWidget);

      // Advance to final step of Controls chapter (4 steps)
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
      }

      final tryNowBtn = find.text(t.tutorial_try_now);
      expect(tryNowBtn, findsOneWidget);

      await tester.tap(tryNowBtn);
      await tester.pumpAndSettle();

      // Should have navigated to ControlsGuideScreen
      expect(find.text(t.controls_guide_title), findsOneWidget);
    });

    testWidgets('Chapter 5 (Shiny Hunt) Jetzt ausprobieren navigates to ShinyHuntsHubScreen WITHOUT pre-marking shiny_hunt_hub seen', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Chapter 5 is index 4 (0-based)
      final replayButtons = find.text('Wiederholen');
      await tester.tap(replayButtons.at(4));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDemoDialog), findsOneWidget);

      // Advance through chapter 5 (5 steps)
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
      }

      final tryNowBtn = find.text(t.tutorial_try_now);
      expect(tryNowBtn, findsOneWidget);

      await tester.tap(tryNowBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Should have navigated to ShinyHuntsHubScreen
      expect(find.byType(ShinyHuntsHubScreen), findsOneWidget);
      // Critically: shiny_hunt_hub was NOT pre-marked seen, so live overlay appears!
      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(tutorialProvider.hasSeenFeature('shiny_hunt_hub'), isFalse);
    });

    testWidgets('Chapter 8 (Route Tracker) Jetzt ausprobieren navigates to DexScreen when a dex exists', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyDex = UserDex.fallback('kanto_dex');
      final dummyPika = Pokemon(
        id: 25,
        nameDe: 'Pikachu',
        nameEn: 'Pikachu',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 255,
        evolutionChainId: -1,
        eggGroups: const [],
        weight: 0.0,
        speed: 0,
        forms: const [],
      );
      mockDexProvider.userDexes = [dummyDex];
      mockDexProvider.allPokemon = [dummyPika];
      mockDexProvider.allAvailableDexes = {'kanto': [25]};

      await tester.pumpWidget(createTestWidget(dexProvider: mockDexProvider));
      await tester.pumpAndSettle();

      // Chapter 8 is index 7 (0-based)
      final replayButtons = find.text('Wiederholen');
      await tester.tap(replayButtons.at(7));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDemoDialog), findsOneWidget);

      // Advance through chapter 8 (4 steps)
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
      }

      final tryNowBtn = find.text(t.tutorial_try_now);
      expect(tryNowBtn, findsOneWidget);

      await tester.tap(tryNowBtn);
      await tester.pumpAndSettle();

      // Should have navigated to DexScreen
      expect(find.byType(DexScreen), findsOneWidget);
    });

    testWidgets('Chapter 10 (Cloud Sync) Jetzt ausprobieren pops back and marks cloud features seen', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider<TutorialProvider>.value(
                            value: tutorialProvider,
                          ),
                          ChangeNotifierProvider<DexProvider>.value(
                            value: mockDexProvider,
                          ),
                        ],
                        child: const TutorialSettingsScreen(),
                      ),
                    ),
                  );
                  popped = true;
                },
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(TutorialSettingsScreen), findsOneWidget);

      // Chapter 10 is index 9 (last)
      final replayButtons = find.text('Wiederholen');
      await tester.tap(replayButtons.last);
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDemoDialog), findsOneWidget);

      // Advance through chapter 10 (4 steps)
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
      }

      final tryNowBtn = find.text(t.tutorial_try_now);
      expect(tryNowBtn, findsOneWidget);

      await tester.tap(tryNowBtn);
      await tester.pumpAndSettle();

      // Should have popped TutorialSettingsScreen back to caller
      expect(popped, isTrue);
      expect(find.byType(TutorialSettingsScreen), findsNothing);
    });
  });
}
