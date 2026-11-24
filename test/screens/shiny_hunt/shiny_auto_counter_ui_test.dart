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
import 'package:pokevault/screens/shiny_hunt/dialogs/shiny_auto_counter_setup_sheet.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunt_counter_screen.dart';
import 'package:pokevault/screens/shiny_hunt/widgets/shiny_auto_counter_bar.dart';
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

  ShinyHunt makeHunt() {
    final now = DateTime.now();
    return ShinyHunt(
      id: 'hunt-mewtwo',
      title: 'Mewtu',
      pokemonId: 150,
      pokemonName: 'Mewtu',
      game: 'SoulSilver',
      generation: 4.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
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

  group('ShinyAutoCounter UI Widget Tests', () {
    testWidgets('ShinyAutoCounterBar renders slot badges, handles shiny alert banner & undo without overflow on 320x480', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final hunt = makeHunt();
      await huntProvider.createHunt(hunt);
      final coordinator = makeCoordinator();
      final service = ShinyAutoCounterService.forTesting();
      service.startSession(
        huntProvider: huntProvider,
        coordinator: coordinator,
        defaultHuntId: hunt.id,
        slotIds: const [1, 2],
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          autoPauseSlotOnShiny: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShinyAutoCounterBar(service: service),
          ),
        ),
      );

      expect(find.byKey(const Key('shiny_auto_bar')), findsOneWidget);
      expect(find.byKey(const Key('shiny_auto_slot_chip_1')), findsOneWidget);
      expect(find.byKey(const Key('shiny_auto_slot_chip_2')), findsOneWidget);

      await coordinator.processFrameText('Wildes ✨ Mewtu erscheint!', instanceIndex: 2);
      await service.waitForIdle();
      await tester.pump();

      expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(1));
      expect(find.byKey(const Key('shiny_auto_shiny_banner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('shiny_auto_resume_shiny_btn')));
      await tester.pump();
      expect(find.byKey(const Key('shiny_auto_shiny_banner')), findsNothing);

      await tester.tap(find.byKey(const Key('shiny_auto_undo_btn')));
      await tester.pump();
      expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(0));
      expect(tester.takeException(), isNull);

      await service.stopSession();
      await coordinator.dispose();
    });

    testWidgets('ShinyAutoCounterSetupSheet allows changing mode, adding custom trigger/reset patterns, and toggling safety options', (tester) async {
      final hunt = makeHunt();
      await huntProvider.createHunt(hunt);
      final service = ShinyAutoCounterService.forTesting();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
            ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ShinyAutoCounterSetupSheet(
                hunt: hunt,
                service: service,
                showSourceLauncher: false,
              ),
            ),
          ),
        ),
      );

      // Select Egg Hatch preset
      await tester.tap(find.byKey(const Key('setup_mode_eggHatch')));
      await tester.pump();

      // Add custom trigger pattern
      await tester.ensureVisible(find.byKey(const Key('setup_custom_trigger_field')));
      await tester.enterText(find.byKey(const Key('setup_custom_trigger_field')), '{pokemon} erscheint');
      await tester.ensureVisible(find.byKey(const Key('setup_add_trigger_btn')));
      await tester.tap(find.byKey(const Key('setup_add_trigger_btn')));
      await tester.pump();
      expect(find.text('{pokemon} erscheint'), findsOneWidget);

      // Add custom reset pattern
      await tester.ensureVisible(find.byKey(const Key('setup_custom_reset_field')));
      await tester.enterText(find.byKey(const Key('setup_custom_reset_field')), 'Weiter');
      await tester.ensureVisible(find.byKey(const Key('setup_add_reset_btn')));
      await tester.tap(find.byKey(const Key('setup_add_reset_btn')));
      await tester.pump();
      expect(find.text('Weiter'), findsOneWidget);

      // Toggle sound on count
      await tester.ensureVisible(find.byKey(const Key('setup_toggle_sound_count')));
      await tester.tap(find.byKey(const Key('setup_toggle_sound_count')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ShinyHuntCounterScreen integrates auto-scanner button, live bar, and auto-increment updates', (tester) async {
      final hunt = makeHunt();
      await huntProvider.createHunt(hunt);
      final coordinator = makeCoordinator();
      final service = ShinyAutoCounterService.instance;
      service.startSession(
        huntProvider: huntProvider,
        coordinator: coordinator,
        defaultHuntId: hunt.id,
        slotIds: const [1],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
            ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
          ],
          child: MaterialApp(
            home: ShinyHuntCounterScreen(huntId: hunt.id),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('counter_auto_scanner_btn')), findsOneWidget);
      expect(find.byKey(const Key('shiny_auto_bar')), findsOneWidget);

      await coordinator.processFrameText('Ein wildes Mewtu erscheint!', instanceIndex: 1);
      await service.waitForIdle();
      await tester.pump();

      expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(1));
      expect(find.text('1'), findsWidgets);

      await coordinator.dispose();
    });
  });
}
