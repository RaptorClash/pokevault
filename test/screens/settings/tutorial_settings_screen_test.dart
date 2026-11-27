import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
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
import 'package:pokevault/screens/home/create_dex_bottom_sheet.dart';
import 'package:pokevault/screens/shiny_hunt/multi_hunt_dashboard_screen.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunts_hub_screen.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';
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

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('TutorialSettingsScreen Widget Tests', () {
    late SharedPreferences prefs;
    late TutorialProvider tutorialProvider;
    late MockDexProviderForTest mockDexProvider;
    late FakeShinyHuntProvider fakeShinyHuntProvider;
    late FakeSettingsProvider fakeSettingsProvider;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.de);
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

    testWidgets('Renders header with v1.7 tour button (no v1.6) and all 12 platform-visible chapters', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check header buttons: v1.7 present, v1.6 tour button & NEU (v1.6) badges removed
      expect(find.text(t.tutorial_v17_tour_btn), findsOneWidget);
      expect(find.text(t.tutorial_v16_tour_btn), findsNothing);
      expect(find.textContaining('zurücksetzen'), findsWidgets);
      expect(find.text('12 Kapitel'), findsOneWidget);

      // Check that chapters appear (e.g., Home, Boxen, Shiny Hunt, Backup, Multi-Hunt & Auto-Counter)
      expect(find.textContaining('Sammlung'), findsWidgets);
      expect(find.textContaining('Box'), findsWidgets);
      expect(find.textContaining('Shiny Hunt'), findsWidgets);
      expect(find.textContaining('Backup'), findsWidgets);
      expect(find.text('12. Multi-Hunt & Auto-Counter'), findsOneWidget);

      // Verify "NEU" badge only for v1.7 chapters, no "NEU (v1.6)"
      expect(find.text('NEU'), findsWidgets);
      expect(find.text('NEU (v1.6)'), findsNothing);
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

      final backupCard = find.ancestor(
        of: find.text('10. Cloud-Sync & Backups'),
        matching: find.byType(Card),
      );
      final backupReplay = find.descendant(
        of: backupCard,
        matching: find.text('Wiederholen'),
      );
      await tester.ensureVisible(backupReplay);
      await tester.tap(backupReplay);
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

      LocaleSettings.setLocaleSync(AppLocale.en);
      await tester.pumpWidget(createTestWidget(key: const Key('screen_en')));
      await tester.pumpAndSettle();

      // Check English translation
      expect(find.textContaining('Tutorials & Guides'), findsWidgets);
      expect(find.textContaining('Reset all tutorials'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Switch language to German at runtime
      LocaleSettings.setLocaleSync(AppLocale.de);
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

      // Advance through chapter 5 (6 steps)
      for (int i = 0; i < 5; i++) {
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

      final backupCard = find.ancestor(
        of: find.text('10. Cloud-Sync & Backups'),
        matching: find.byType(Card),
      );
      final backupReplay = find.descendant(
        of: backupCard,
        matching: find.text('Wiederholen'),
      );
      await tester.ensureVisible(backupReplay);
      await tester.tap(backupReplay);
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

    testWidgets('Shows only platform-appropriate scanner chapter in TutorialSettingsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(TrackerPlatformHelper.resetDebugOverrides);

      // Mobile view
      TrackerPlatformHelper.debugIsMobileOverride = () => true;
      TrackerPlatformHelper.debugIsDesktopOverride = () => false;
      await tester.pumpWidget(createTestWidget(key: const Key('tut_mob')));
      await tester.pumpAndSettle();
      expect(find.text('11. Kamera- & Foto-Scanner'), findsOneWidget);
      expect(find.text('11. Overlay-, Fenster- & Kamera-Scanner'), findsNothing);

      // Desktop view
      TrackerPlatformHelper.debugIsMobileOverride = () => false;
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      await tester.pumpWidget(createTestWidget(key: const Key('tut_desk')));
      await tester.pumpAndSettle();
      expect(find.text('11. Overlay-, Fenster- & Kamera-Scanner'), findsOneWidget);
      expect(find.text('11. Kamera- & Foto-Scanner'), findsNothing);
      expect(find.text('12. Multi-Hunt & Auto-Counter'), findsOneWidget);
    });

    testWidgets('Chapter 12 Demo Mode displays Multi-Hunt & Auto-Counter visual and navigates to dashboard', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final ch12Card = find.ancestor(
        of: find.text('12. Multi-Hunt & Auto-Counter'),
        matching: find.byType(Card),
      );
      final replayBtn = find.descendant(
        of: ch12Card,
        matching: find.text('Wiederholen'),
      );
      await tester.ensureVisible(replayBtn);
      await tester.tap(replayBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDemoDialog), findsOneWidget);
      expect(find.textContaining('Multi-Hunt'), findsWidgets);

      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(t.tutorial_try_now));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MultiHuntDashboardScreen), findsOneWidget);
    });

    testWidgets('Live-Tour button on every chapter resets seen flags and starts live TutorialOverlay', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Mark all shiny & auto-counter tutorials as already completed
      await tutorialProvider.markChapterSeen('module_shiny_hunt');
      await tutorialProvider.markChapterSeen('module_shiny_auto_counter');
      await tutorialProvider.markChapterSeen('module_create_dex');
      expect(tutorialProvider.isChapterCompleted('module_shiny_auto_counter'), isTrue);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Live-Tour on Chapter 12 (Multi-Hunt & Auto-Counter)
      final liveBtn12 = find.byKey(const Key('tutorial_live_tour_module_shiny_auto_counter'));
      expect(liveBtn12, findsOneWidget);
      await tester.ensureVisible(liveBtn12);
      await tester.tap(liveBtn12);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MultiHuntDashboardScreen), findsOneWidget);
      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(tutorialProvider.hasSeenFeature('multi_hunt_dashboard'), isFalse);
    });

    testWidgets('Live-Tour button on Chapter 2 (Create Dex) opens CreateDexBottomSheet and triggers live tour', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tutorialProvider.markChapterSeen('module_create_dex');
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final liveBtn2 = find.byKey(const Key('tutorial_live_tour_module_create_dex'));
      expect(liveBtn2, findsOneWidget);
      await tester.ensureVisible(liveBtn2);
      await tester.tap(liveBtn2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(CreateDexBottomSheet), findsOneWidget);
      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(tutorialProvider.hasSeenFeature('create_dex_sheet'), isFalse);
    });
  });
}
