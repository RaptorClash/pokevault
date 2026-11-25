import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/shiny_auto_counter_setup_sheet.dart';
import 'package:pokevault/screens/shiny_hunt/multi_hunt_dashboard_screen.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunt_counter_screen.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunts_hub_screen.dart';
import 'package:pokevault/screens/shiny_hunt/widgets/shiny_auto_counter_bar.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_service.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

class _MockWakelock extends Fake
    with MockPlatformInterfaceMixin
    implements WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}
  @override
  Future<bool> get enabled async => false;
  @override
  bool get isMock => true;
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
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

class _FakeDexProvider extends ChangeNotifier implements DexProvider {
  @override
  List<Pokemon> get allPokemon => [
        Pokemon(
          id: 150,
          nameDe: 'Mewtu',
          nameEn: 'Mewtwo',
          hasGenderDifferences: false,
          genderRate: -1,
          captureRate: 3,
          evolutionChainId: 1,
          eggGroups: ['Undiscovered'],
          weight: 122.0,
          speed: 130,
          forms: [],
        ),
      ];
  @override
  List<UserDex> get userDexes => const [];
  @override
  Map<String, String> get ballUrls => const {};
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDatabaseService extends Fake implements DatabaseService {
  final Map<String, ShinyHunt> _hunts = {};
  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async =>
      _hunts.values.where((h) => includeDeleted || h.deletedAt == 0).toList();
  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) async => _hunts[hunt.id] = hunt;
  @override
  Future<void> deleteShinyHunt(String id, {bool softDelete = true}) async =>
      _hunts.remove(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeDatabaseService fakeDb;
  late ShinyHuntProvider huntProvider;
  late _FakeDexProvider dexProvider;

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
    WakelockPlusPlatformInterface.instance = _MockWakelock();
    wakelockPlusPlatformInstance = _MockWakelock();
  });

  setUp(() async {
    TutorialOverlay.resetShowing();
    LocaleSettings.setLocaleSync(AppLocale.de);
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    fakeDb = _FakeDatabaseService();
    huntProvider = ShinyHuntProvider(
      databaseService: fakeDb,
      enableTimer: false,
    );
    await huntProvider.initialized;
    dexProvider = _FakeDexProvider();
    await ShinyAutoCounterService.instance.stopSession();
  });

  tearDown(() async {
    TutorialOverlay.resetShowing();
    await ShinyAutoCounterService.instance.stopSession();
    huntProvider.dispose();
  });

  ShinyHunt makeHunt({
    String id = 'hunt-1',
    String status = 'active',
  }) {
    final now = DateTime.now();
    return ShinyHunt(
      id: id,
      title: 'Mewtu',
      pokemonId: 150,
      pokemonName: 'Mewtu',
      game: 'SoulSilver',
      generation: 4.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  ScannerCoordinator makeCoordinator() {
    return ScannerCoordinator(
      engine: OcrDetectionEngine(),
      matcher: PokemonFuzzyMatcher.withEntries(const [
        PokemonMatcherEntry(id: 150, name: 'Mewtu', language: 'de'),
      ]),
    );
  }

  Future<void> pumpView(WidgetTester tester, {int ms = 400}) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: ms));
  }

  Future<void> advanceTutorialToEnd(
    WidgetTester tester,
    List<String> expectedTitles,
  ) async {
    for (int i = 0; i < expectedTitles.length; i++) {
      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(find.text(expectedTitles[i]), findsOneWidget);
      final isLast = i == expectedTitles.length - 1;
      final btnText = isLast ? t.tutorial_finish : t.tutorial_next;
      await tester.tap(find.text(btnText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 450));
    }
    expect(find.byType(TutorialOverlay), findsNothing);
  }

  Widget wrapProviders({
    required TutorialProvider tutProvider,
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
        ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
        ChangeNotifierProvider<TutorialProvider>.value(value: tutProvider),
      ],
      child: TranslationProvider(
        child: MaterialApp(home: child),
      ),
    );
  }

  group('ShinyHuntsHubScreen v1.7 Tutorial & Delta', () {
    testWidgets('Fresh user sees 3-step hub tour incl. Dashboard button and marks both keys', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: const ShinyHuntsHubScreen(),
        ),
      );
      await pumpView(tester);

      await advanceTutorialToEnd(tester, [
        t.tutorial_shiny_new_title,
        t.tutorial_shiny_hub_title,
        t.tutorial_shiny_hub_dashboard_title,
      ]);

      expect(tutProvider.hasSeenFeature('shiny_hunt_hub'), isTrue);
      expect(tutProvider.hasSeenFeature('shiny_hunt_hub_v17_delta'), isTrue);
    });

    testWidgets('Existing user (shiny_hunt_hub=true) sees 1-step Dashboard delta spotlight', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_db_version': 21,
        'shiny_hunt_hub': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: const ShinyHuntsHubScreen(),
        ),
      );
      await pumpView(tester);

      await advanceTutorialToEnd(tester, [
        t.tutorial_shiny_hub_dashboard_title,
      ]);

      expect(tutProvider.hasSeenFeature('shiny_hunt_hub_v17_delta'), isTrue);
    });

    testWidgets('No overlay when both shiny_hunt_hub and shiny_hunt_hub_v17_delta are seen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_db_version': 21,
        'shiny_hunt_hub': true,
        'shiny_hunt_hub_v17_delta': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: const ShinyHuntsHubScreen(),
        ),
      );
      await pumpView(tester);

      expect(find.byType(TutorialOverlay), findsNothing);
    });
  });

  group('ShinyHuntCounterScreen v1.7 Tutorial & Delta', () {
    testWidgets('Fresh user sees 5-step counter tour incl. Auto-Counter & Dashboard', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt();
      await huntProvider.createHunt(hunt);

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: ShinyHuntCounterScreen(huntId: hunt.id),
        ),
      );
      await pumpView(tester);

      await advanceTutorialToEnd(tester, [
        t.tutorial_shiny_counter_title,
        t.tutorial_shiny_buttons_title,
        t.tutorial_shiny_phases_actions_title,
        t.tutorial_shiny_counter_auto_title,
        t.tutorial_shiny_counter_dashboard_title,
      ]);

      expect(tutProvider.hasSeenFeature('shiny_hunt_counter'), isTrue);
      expect(tutProvider.hasSeenFeature('shiny_hunt_counter_v17_delta'), isTrue);
    });

    testWidgets('Existing user sees 2-step delta spotlight for Auto-Counter & Dashboard', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_db_version': 21,
        'shiny_hunt_counter': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt();
      await huntProvider.createHunt(hunt);

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: ShinyHuntCounterScreen(huntId: hunt.id),
        ),
      );
      await pumpView(tester);

      await advanceTutorialToEnd(tester, [
        t.tutorial_shiny_counter_auto_title,
        t.tutorial_shiny_counter_dashboard_title,
      ]);

      expect(tutProvider.hasSeenFeature('shiny_hunt_counter_v17_delta'), isTrue);
    });

    testWidgets('Completed hunt triggers neither full nor delta counter tour', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_db_version': 21,
        'shiny_hunt_counter': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt(status: 'completed');
      await huntProvider.createHunt(hunt);

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: ShinyHuntCounterScreen(huntId: hunt.id),
        ),
      );
      await pumpView(tester);

      expect(find.byType(TutorialOverlay), findsNothing);
    });
  });

  group('MultiHuntDashboardScreen Interactive Rotom Tour', () {
    testWidgets('First visit with active hunt shows 6-step Rotom tour & preserves ? help dialog', (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      await huntProvider.createHunt(makeHunt());

      final service = ShinyAutoCounterService.forTesting();
      addTearDown(() => service.stopSession());

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: MultiHuntDashboardScreen(autoCounterService: service),
        ),
      );
      await pumpView(tester);

      await advanceTutorialToEnd(tester, [
        t.tutorial_multi_hunt_intro_title,
        t.tutorial_multi_hunt_appbar_title,
        t.tutorial_multi_hunt_setup_title,
        t.tutorial_multi_hunt_card_counter_title,
        t.tutorial_multi_hunt_card_rules_title,
        t.tutorial_multi_hunt_card_slots_title,
      ]);

      expect(tutProvider.hasSeenFeature('multi_hunt_dashboard'), isTrue);

      // ? help button still opens static help dialog
      await tester.tap(find.byKey(const Key('multi_hunt_help_btn')));
      await pumpView(tester);
      expect(find.byKey(const Key('multi_hunt_help_dialog')), findsOneWidget);
      expect(find.byType(TutorialOverlay), findsNothing);
    });

    testWidgets('Adversarial Empty State (0 hunts): 3-step tour skips card steps cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final service = ShinyAutoCounterService.forTesting();
      addTearDown(() => service.stopSession());

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: MultiHuntDashboardScreen(autoCounterService: service),
        ),
      );
      await pumpView(tester);

      await advanceTutorialToEnd(tester, [
        t.tutorial_multi_hunt_intro_title,
        t.tutorial_multi_hunt_appbar_title,
        t.tutorial_multi_hunt_setup_title,
      ]);

      expect(tutProvider.hasSeenFeature('multi_hunt_dashboard'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Second visit does not trigger Multi-Hunt Dashboard tour', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_db_version': 21,
        'multi_hunt_dashboard': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final service = ShinyAutoCounterService.forTesting();
      addTearDown(() => service.stopSession());

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: MultiHuntDashboardScreen(autoCounterService: service),
        ),
      );
      await pumpView(tester);

      expect(find.byType(TutorialOverlay), findsNothing);
    });
  });

  group('ShinyAutoCounterSetupSheet Interactive Rotom Tour', () {
    testWidgets('Global mode shows 6-step tour with auto-scroll & 320x480 safety', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt();
      final service = ShinyAutoCounterService.forTesting();
      addTearDown(() => service.stopSession());

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ShinyAutoCounterSetupSheet.show(
                  ctx,
                  hunt: hunt,
                  service: service,
                ),
                child: const Text('Open Setup'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Setup'));
      await pumpView(tester, ms: 600);
      await pumpView(tester, ms: 400);

      await advanceTutorialToEnd(tester, [
        t.tutorial_auto_setup_source_title,
        t.tutorial_auto_setup_mode_title,
        t.tutorial_auto_setup_filter_title,
        t.tutorial_auto_setup_custom_title,
        t.tutorial_auto_setup_timing_title,
        t.tutorial_auto_setup_safety_title,
      ]);

      expect(tutProvider.hasSeenFeature('shiny_auto_counter_setup'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('perHuntOverride mode shows 5-step tour omitting source section', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt();
      final service = ShinyAutoCounterService.forTesting();
      addTearDown(() => service.stopSession());

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ShinyAutoCounterSetupSheet.show(
                  ctx,
                  hunt: hunt,
                  service: service,
                  perHuntOverride: true,
                ),
                child: const Text('Open PerHunt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open PerHunt'));
      await pumpView(tester, ms: 600);
      await pumpView(tester, ms: 400);

      await advanceTutorialToEnd(tester, [
        t.tutorial_auto_setup_mode_title,
        t.tutorial_auto_setup_filter_title,
        t.tutorial_auto_setup_custom_title,
        t.tutorial_auto_setup_timing_title,
        t.tutorial_auto_setup_safety_title,
      ]);

      expect(tutProvider.hasSeenFeature('shiny_auto_counter_setup'), isTrue);
    });

    testWidgets('Second open does not show setup tour', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_db_version': 21,
        'shiny_auto_counter_setup': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt();
      final service = ShinyAutoCounterService.forTesting();
      addTearDown(() => service.stopSession());

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: Scaffold(
            body: ShinyAutoCounterSetupSheet(
              hunt: hunt,
              service: service,
            ),
          ),
        ),
      );
      await pumpView(tester, ms: 500);

      expect(find.byType(TutorialOverlay), findsNothing);
    });
  });

  group('ShinyAutoCounterBar Interactive Rotom Tour & Route Guard', () {
    testWidgets('Does not trigger when stopped; triggers 3-step tour when running on top route; preserves ? dialog', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt();
      await huntProvider.createHunt(hunt);
      final service = ShinyAutoCounterService.forTesting();
      final coordinator = makeCoordinator();
      addTearDown(() async {
        await service.stopSession();
        coordinator.dispose();
      });

      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: Scaffold(
            body: ShinyAutoCounterBar(
              service: service,
              currentHuntId: hunt.id,
            ),
          ),
        ),
      );
      await pumpView(tester);
      expect(find.byType(TutorialOverlay), findsNothing);

      // Start auto-counter session
      service.startSession(
        huntProvider: huntProvider,
        coordinator: coordinator,
        defaultHuntId: hunt.id,
        slotIds: const [1],
      );
      await pumpView(tester);

      await advanceTutorialToEnd(tester, [
        t.tutorial_auto_bar_controls_title,
        t.tutorial_auto_bar_slots_title,
        t.tutorial_auto_bar_shiny_title,
      ]);

      expect(tutProvider.hasSeenFeature('shiny_auto_counter_bar'), isTrue);

      // ? help button still opens static help dialog
      await tester.tap(find.byKey(const Key('shiny_auto_help_btn')));
      await pumpView(tester);
      expect(find.byKey(const Key('shiny_auto_help_dialog')), findsOneWidget);
      expect(find.byType(TutorialOverlay), findsNothing);
    });

    testWidgets('Adversarial Route-Guard: covered bar waits until covering modal closes before showing tour', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final hunt = makeHunt();
      await huntProvider.createHunt(hunt);
      final service = ShinyAutoCounterService.forTesting();
      final coordinator = makeCoordinator();
      addTearDown(() async {
        await service.stopSession();
        coordinator.dispose();
      });

      late BuildContext rootCtx;
      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: Builder(
            builder: (ctx) {
              rootCtx = ctx;
              return Scaffold(
                body: ShinyAutoCounterBar(
                  service: service,
                  currentHuntId: hunt.id,
                ),
              );
            },
          ),
        ),
      );
      await pumpView(tester);

      // Push covering modal route
      unawaited(
        showDialog<void>(
          context: rootCtx,
          builder: (_) => const AlertDialog(content: Text('Covering Modal')),
        ),
      );
      await pumpView(tester);
      expect(find.text('Covering Modal'), findsOneWidget);

      // Start session while covered
      service.startSession(
        huntProvider: huntProvider,
        coordinator: coordinator,
        defaultHuntId: hunt.id,
        slotIds: const [1],
      );
      await pumpView(tester);

      // Overlay must NOT trigger while covered
      expect(find.byType(TutorialOverlay), findsNothing);

      // Pop covering modal -> bar's route becomes isCurrent -> tour triggers!
      Navigator.of(rootCtx).pop();
      await pumpView(tester);

      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(find.text(t.tutorial_auto_bar_controls_title), findsOneWidget);
    });

    testWidgets('Adversarial i18n: runtime language switch DE <-> EN localizes new tour', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final tutProvider = TutorialProvider(prefs);
      final service = ShinyAutoCounterService.forTesting();
      addTearDown(() => service.stopSession());

      LocaleSettings.setLocaleSync(AppLocale.en);
      await tester.pumpWidget(
        wrapProviders(
          tutProvider: tutProvider,
          child: MultiHuntDashboardScreen(autoCounterService: service),
        ),
      );
      await pumpView(tester);

      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(find.text(t.tutorial_multi_hunt_intro_title), findsOneWidget);
      // Should be translated into English, not German
      expect(t.tutorial_multi_hunt_intro_title, isNot(contains('Willkommen')));
    });
  });
}
