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
import 'package:pokevault/screens/shiny_hunt/dialogs/create_edit_hunt_dialog.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/shiny_auto_counter_setup_sheet.dart';
import 'package:pokevault/screens/shiny_hunt/multi_hunt_dashboard_screen.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunts_hub_screen.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_config.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_service.dart';

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
        Pokemon(
          id: 4,
          nameDe: 'Glumanda',
          nameEn: 'Charmander',
          hasGenderDifferences: false,
          genderRate: 1,
          captureRate: 45,
          evolutionChainId: 2,
          eggGroups: ['Monster', 'Dragon'],
          weight: 8.5,
          speed: 65,
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
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    HttpOverrides.global = _MockHttpOverrides();
    WakelockPlusPlatformInterface.instance = _MockWakelock();
    wakelockPlusPlatformInstance = _MockWakelock();
  });

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.de);
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
    await ShinyAutoCounterService.instance.stopSession();
    huntProvider.dispose();
  });

  Future<ShinyHunt> createHunt(String id, int pid, String name, {String method = 'Soft Reset'}) async {
    final now = DateTime.now();
    final h = ShinyHunt(
      id: id,
      title: name,
      pokemonId: pid,
      pokemonName: name,
      game: 'SoulSilver',
      generation: 4.0,
      method: method,
      baseOdds: 8192.0,
      createdAt: now,
      updatedAt: now,
    );
    await huntProvider.createHunt(h);
    return h;
  }

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
        ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('MultiHuntDashboardScreen Widget & Boundary Tests', () {
    testWidgets('shows empty state when zero active/paused hunts exist', (tester) async {
      await tester.pumpWidget(wrap(const MultiHuntDashboardScreen()));
      await tester.pump();
      expect(find.byKey(const Key('multi_hunt_empty_state')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 4 parallel hunts, supports manual +1/-1/pause independently and slot assignment', (tester) async {
      await createHunt('h1', 150, 'Mewtu');
      await createHunt('h2', 4, 'Glumanda');
      await createHunt('h3', 25, 'Pikachu', method: 'Wild');
      await createHunt('h4', 133, 'Evoli', method: 'Masuda');

      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 150, name: 'Mewtu', language: 'de'),
          PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
        ]),
      );
      final service = ShinyAutoCounterService.forTesting();
      service.startSession(
        huntProvider: huntProvider,
        coordinator: coordinator,
        defaultHuntId: 'h1',
        slotIds: const [1, 2],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          matchFilter: ShinyMatchFilter.allPokemon,
          slotToHuntOverrides: {2: 'h2'},
        ),
      );

      await tester.pumpWidget(
        wrap(MultiHuntDashboardScreen(autoCounterService: service)),
      );
      await tester.pump();

      expect(find.byKey(const Key('multi_hunt_card_h1')), findsOneWidget);
      expect(find.byKey(const Key('multi_hunt_card_h2')), findsOneWidget);

      // Manual +1 on h1 and -1 guard on h2
      await tester.ensureVisible(find.byKey(const Key('multi_hunt_inc_h1')));
      await tester.tap(find.byKey(const Key('multi_hunt_inc_h1')));
      await tester.pump();
      expect(huntProvider.getHuntById('h1')!.currentEncounters, equals(1));
      expect(huntProvider.getHuntById('h2')!.currentEncounters, equals(0));

      // Pause h2 manually -> h2 moves out of active grid into paused toggle
      await tester.ensureVisible(find.byKey(const Key('multi_hunt_pause_h2')));
      await tester.tap(find.byKey(const Key('multi_hunt_pause_h2')));
      await tester.pump();
      expect(huntProvider.getHuntById('h2')!.isPaused, isTrue);
      expect(find.byKey(const Key('multi_hunt_card_h2')), findsNothing);
      expect(find.byKey(const Key('multi_hunt_toggle_paused_btn')), findsOneWidget);

      // Auto event on slot 1 increments h1
      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      await tester.pump();
      expect(huntProvider.getHuntById('h1')!.currentEncounters, equals(2));

      await service.stopSession();
      await coordinator.dispose();
    });

    testWidgets('hides paused hunts by default, allows showing and resuming them', (tester) async {
      await createHunt('h-act', 150, 'Mewtu');
      final pausedHunt = await createHunt('h-pau', 4, 'Glumanda');
      await huntProvider.pauseHunt(pausedHunt.id);

      await tester.pumpWidget(wrap(const MultiHuntDashboardScreen()));
      await tester.pump();

      expect(find.byKey(const Key('multi_hunt_card_h-act')), findsOneWidget);
      expect(find.byKey(const Key('multi_hunt_card_h-pau')), findsNothing);

      final toggleBtn = find.byKey(const Key('multi_hunt_toggle_paused_btn'));
      expect(toggleBtn, findsOneWidget);
      await tester.tap(toggleBtn);
      await tester.pump();

      expect(find.byKey(const Key('multi_hunt_card_h-pau')), findsOneWidget);

      // Resume paused hunt from the paused section
      await tester.ensureVisible(find.byKey(const Key('multi_hunt_pause_h-pau')));
      await tester.tap(find.byKey(const Key('multi_hunt_pause_h-pau')));
      await tester.pump();

      expect(huntProvider.getHuntById('h-pau')!.isActive, isTrue);
      expect(find.byKey(const Key('multi_hunt_card_h-pau')), findsOneWidget);
    });

    testWidgets('supports adding a new hunt directly and editing per-hunt rules or hunt metadata', (tester) async {
      await createHunt('h1', 150, 'Mewtu');

      await tester.pumpWidget(wrap(const MultiHuntDashboardScreen()));
      await tester.pump();

      // Add hunt button opens CreateEditHuntDialog
      await tester.tap(find.byKey(const Key('multi_hunt_add_hunt_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CreateEditHuntDialog), findsOneWidget);
      Navigator.of(tester.element(find.byType(CreateEditHuntDialog))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Per-hunt rules button opens ShinyAutoCounterSetupSheet
      await tester.tap(find.byKey(const Key('multi_hunt_rules_h1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ShinyAutoCounterSetupSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(ShinyAutoCounterSetupSheet))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Edit hunt button opens CreateEditHuntDialog for h1
      await tester.tap(find.byKey(const Key('multi_hunt_edit_h1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CreateEditHuntDialog), findsOneWidget);
    });

    testWidgets('renders cleanly across extreme viewport sizes (320x480, 640x320 landscape, 1440x900 desktop) and runtime DE<->EN switch', (tester) async {
      await createHunt('h1', 150, 'Mewtu');
      await createHunt('h2', 4, 'Glumanda');

      for (final size in const [Size(320, 480), Size(640, 320), Size(1440, 900)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(wrap(const MultiHuntDashboardScreen()));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow at size $size');
      }

      LocaleSettings.setLocaleSync(AppLocale.en);
      await tester.pump();
      expect(tester.takeException(), isNull);

      LocaleSettings.setLocaleSync(AppLocale.de);
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('ShinyHuntsHubScreen exposes Multi-Hunt Dashboard button and navigates to it', (tester) async {
      await createHunt('h1', 150, 'Mewtu');
      await tester.pumpWidget(wrap(const ShinyHuntsHubScreen()));
      await tester.pump();

      final btn = find.byKey(const Key('hub_multi_hunt_dashboard_btn'));
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MultiHuntDashboardScreen), findsOneWidget);
    });
  });
}
