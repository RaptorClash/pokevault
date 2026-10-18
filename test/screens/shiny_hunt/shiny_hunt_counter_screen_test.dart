import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/record_phase_dialog.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/shiny_catch_dialog.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunt_counter_screen.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class MockWakelockPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements WakelockPlusPlatformInterface {
  bool _enabled = false;
  @override
  Future<void> toggle({required bool enable}) async {
    _enabled = enable;
  }
  @override
  Future<bool> get enabled async => _enabled;
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
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class FakeDexProvider extends ChangeNotifier implements DexProvider {
  @override
  List<Pokemon> get allPokemon => [
        Pokemon(
          id: 6,
          nameDe: 'Glurak',
          nameEn: 'Charizard',
          hasGenderDifferences: false,
          genderRate: 1,
          captureRate: 45,
          evolutionChainId: 2,
          eggGroups: ['Monster', 'Dragon'],
          weight: 90.5,
          speed: 100,
          forms: [],
        ),
      ];

  List<UserDex> mockUserDexes = [];

  @override
  List<UserDex> get userDexes => mockUserDexes;

  @override
  Map<String, String> get ballUrls => {'ultra-ball': 'https://img.test/ultra.png'};

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabaseService extends Fake implements DatabaseService {
  final Map<String, ShinyHunt> _hunts = {};

  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async =>
      _hunts.values.where((h) => includeDeleted || h.deletedAt == 0).toList();

  @override
  Future<ShinyHunt?> getShinyHunt(String id) async => _hunts[id];

  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) async {
    _hunts[hunt.id] = hunt;
  }

  @override
  Future<void> deleteShinyHunt(String id, {bool softDelete = true}) async {
    _hunts.remove(id);
  }

  @override
  Future<void> clearUserData() async {
    _hunts.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabaseService fakeDb;
  late ShinyHuntProvider huntProvider;
  late FakeDexProvider dexProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    HttpOverrides.global = _MockHttpOverrides();
    WakelockPlusPlatformInterface.instance = MockWakelockPlatform();
    wakelockPlusPlatformInstance = MockWakelockPlatform();
  });

  setUp(() async {
    Translator.currentLanguage = 'de';
    fakeDb = FakeDatabaseService();
    huntProvider = ShinyHuntProvider(
      databaseService: fakeDb,
      enableTimer: false,
    );
    await huntProvider.initialized;
    dexProvider = FakeDexProvider();
  });

  tearDown(() {
    huntProvider.dispose();
  });

  Future<ShinyHunt> createTestHunt({
    String id = 'hunt-test-1',
    String title = 'Glurak',
    int currentEncounters = 0,
    int incrementStep = 1,
    double baseOdds = 4096.0,
    int spawns = 1,
    int? pokemonFormId,
    String? huntingType,
    bool hasShinyCharm = false,
    String? targetDexId,
    String? notes,
    String status = 'active',
    String? ballUsed,
    DateTime? completedAt,
  }) async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: id,
      title: title,
      pokemonId: 6,
      pokemonFormId: pokemonFormId,
      pokemonName: 'Glurak',
      game: 'Karmesin / Purpur',
      generation: 9.0,
      method: 'Standard Wild',
      baseOdds: baseOdds,
      spawnsPerEncounter: spawns,
      incrementStep: incrementStep,
      currentEncounters: currentEncounters,
      huntingType: huntingType,
      hasShinyCharm: hasShinyCharm,
      targetDexId: targetDexId,
      notes: notes,
      status: status,
      ballUsed: ballUsed,
      completedAt: completedAt,
      createdAt: now,
      updatedAt: now,
    );
    await huntProvider.createHunt(hunt);
    return hunt;
  }

  Widget buildTestWidget(String huntId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
        ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
      ],
      child: MaterialApp(
        home: ShinyHuntCounterScreen(huntId: huntId),
      ),
    );
  }

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Renders initial counter screen with Pokemon info and zero encounters', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    expect(find.text('Glurak'), findsWidgets);
    expect(find.textContaining('Karmesin / Purpur'), findsOneWidget);
    expect(find.textContaining('1/4096'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_tap_to_count')), findsOneWidget);
  });

  testWidgets('Increments encounter count when tapping central tap zone', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Tap on the tap zone
    await tester.tap(find.text(Translator.get('shiny_hunt_tap_to_count')));
    await pumpView(tester);

    expect(find.text('1'), findsOneWidget);
    expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(1));

    // Tap plus button
    await tester.tap(find.byIcon(Icons.add));
    await pumpView(tester);

    expect(find.text('2'), findsOneWidget);
    expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(2));
  });

  testWidgets('Decrements encounter count via minus button, bounded at 0', (tester) async {
    final hunt = await createTestHunt(currentEncounters: 2);
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    expect(find.text('2'), findsOneWidget);

    // Tap minus
    await tester.tap(find.byIcon(Icons.remove));
    await pumpView(tester);
    expect(find.text('1'), findsOneWidget);

    // Tap minus again
    await tester.tap(find.byIcon(Icons.remove));
    await pumpView(tester);
    expect(find.text('0'), findsOneWidget);

    // Minus button is now disabled (onPressed is null)
    final minusBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove));
    expect(minusBtn.onPressed, isNull);
  });

  testWidgets('Switches step chips and increments by selected step (+5, +10)', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Select +5
    await tester.tap(find.text('+5'));
    await pumpView(tester);

    // Tap tap-to-count
    await tester.tap(find.text(Translator.get('shiny_hunt_tap_to_count')));
    await pumpView(tester);
    expect(find.text('5'), findsOneWidget);

    // Select +10
    await tester.tap(find.text('+10'));
    await pumpView(tester);

    await tester.tap(find.text(Translator.get('shiny_hunt_tap_to_count')));
    await pumpView(tester);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('Toggles Lock Mode (Tap-Only Mode)', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Secondary buttons exist initially
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_record_phase_btn')), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_caught_btn')), findsOneWidget);

    // Tap lock icon to enter lock mode
    await tester.tap(find.byIcon(Icons.lock_open_rounded));
    await pumpView(tester);

    // In lock mode, secondary buttons are hidden
    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text(Translator.get('shiny_hunt_record_phase_btn')), findsNothing);
    expect(find.text(Translator.get('shiny_hunt_caught_btn')), findsNothing);

    // Tapping still increments
    await tester.tap(find.text(Translator.get('shiny_hunt_tap_to_count')));
    await pumpView(tester);
    expect(find.text('1'), findsOneWidget);

    // Tap locked icon to unlock
    await tester.tap(find.byIcon(Icons.lock_rounded));
    await pumpView(tester);

    // Secondary buttons restored
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Toggles Shiny / Normal sprite preview badge', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    expect(find.text(Translator.get('shiny_hunt_sprite_toggle_shiny')), findsOneWidget);

    // Tap toggle badge
    await tester.tap(find.text(Translator.get('shiny_hunt_sprite_toggle_shiny')));
    await pumpView(tester);

    expect(find.text(Translator.get('shiny_hunt_sprite_toggle_normal')), findsOneWidget);
  });

  testWidgets('Manual count entry dialog updates encounters', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Tap large number
    await tester.tap(find.text('0'));
    await pumpView(tester);

    expect(find.text(Translator.get('shiny_hunt_manual_count_title')), findsOneWidget);

    // Enter 2000
    await tester.enterText(find.byType(TextField), '2000');
    await tester.tap(find.text(Translator.get('save', fallback: 'Speichern')));
    await pumpView(tester);

    expect(find.text('2000'), findsOneWidget);
    expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(2000));
  });

  testWidgets('Pause and resume button toggles hunt paused status', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Hunt is active, button shows pause icon
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id)!.isPaused, isTrue);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id)!.isPaused, isFalse);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('Record Phase Shiny button opens RecordPhaseDialog', (tester) async {
    final hunt = await createTestHunt(currentEncounters: 50);
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    await tester.tap(find.text(Translator.get('shiny_hunt_record_phase_btn')));
    await pumpView(tester);

    expect(find.byType(RecordPhaseDialog), findsOneWidget);
  });

  testWidgets('Shiny Caught button opens ShinyCatchDialog', (tester) async {
    final hunt = await createTestHunt(currentEncounters: 100);
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    await tester.tap(find.text(Translator.get('shiny_hunt_caught_btn')));
    await pumpView(tester);

    expect(find.byType(ShinyCatchDialog), findsOneWidget);
  });

  testWidgets('ShinyCatchDialog handles invalid or deleted targetDexId without throwing', (tester) async {
    dexProvider.mockUserDexes = [
      UserDex(
        id: 'active-dex-uuid',
        title: 'Paldea Shiny Dex',
        region: 'paldea',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
      ),
    ];

    final hunt = await createTestHunt(currentEncounters: 50);
    hunt.targetDexId = 'deleted-or-non-existent-uuid';

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
          ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ShinyCatchDialog(hunt: hunt),
          ),
        ),
      ),
    );
    await pumpView(tester);

    expect(find.byType(ShinyCatchDialog), findsOneWidget);
    expect(find.text('Paldea Shiny Dex'), findsOneWidget);
  });

  testWidgets('RecordPhaseDialog handles invalid or deleted targetDexId without throwing', (tester) async {
    dexProvider.mockUserDexes = [
      UserDex(
        id: 'active-dex-uuid',
        title: 'Kanto Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      ),
    ];

    final hunt = await createTestHunt(currentEncounters: 50);
    hunt.targetDexId = 'deleted-or-non-existent-uuid';

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
          ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RecordPhaseDialog(hunt: hunt),
          ),
        ),
      ),
    );
    await pumpView(tester);

    expect(find.byType(RecordPhaseDialog), findsOneWidget);
    // Tap Dex Sync checkbox
    await tester.tap(find.text(Translator.get('shiny_hunt_save_phase_to_dex')));
    await pumpView(tester);

    expect(find.text('Kanto Dex'), findsOneWidget);
  });

  testWidgets('Counter Screen dispose cleans up activeCounterHuntId', (tester) async {
    final hunt = await createTestHunt();
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    expect(huntProvider.activeCounterHuntId, equals(hunt.id));

    // Dispose counter screen by pumping a different screen
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
          ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Text('Outside')),
        ),
      ),
    );
    await pumpView(tester);

    expect(huntProvider.activeCounterHuntId, isNull);
  });

  testWidgets('Pace calculation correctly uses totalEncounters including past phases', (tester) async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'multi-phase-hunt',
      title: 'Multi-Phase Hunt',
      pokemonId: 6,
      pokemonName: 'Glurak',
      game: 'Karmesin / Purpur',
      generation: 9.0,
      method: 'Standard Wild',
      baseOdds: 4096.0,
      currentEncounters: 100,
      priorPhaseEncounters: 500, // Phase 1 was 500 encounters
      totalTimeSeconds: 3600, // 1 hour elapsed total
      createdAt: now,
      updatedAt: now,
    );
    await huntProvider.createHunt(hunt);

    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Pace should be 600 / h (600 encounters / 1h), NOT 100 / h
    expect(find.textContaining('600 / h'), findsOneWidget);
  });

  testWidgets('Finish button opens dialog, archive-only completes hunt and reopen restores it', (tester) async {
    final hunt = await createTestHunt(currentEncounters: 350);
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Tap finish button in AppBar
    await tester.tap(find.text(Translator.get('shiny_hunt_finish_btn')));
    await pumpView(tester);

    expect(find.text(Translator.get('shiny_hunt_finish_dialog_title')), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_finish_archive_only')), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_finish_as_caught')), findsOneWidget);

    // Tap "Ohne Fang archivieren"
    await tester.tap(find.text(Translator.get('shiny_hunt_finish_archive_only')));
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id)!.isCompleted, isTrue);
    expect(find.text(Translator.get('shiny_hunt_completed_banner')), findsWidgets);
    expect(find.text(Translator.get('shiny_hunt_reopen_btn')), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_back_to_hub')), findsOneWidget);

    // Dismiss SnackBar so bottom buttons are unblocked for tapping
    ScaffoldMessenger.of(tester.element(find.byType(ShinyHuntCounterScreen))).hideCurrentSnackBar();
    await pumpView(tester);

    // Tap "Hunt wieder aufnehmen"
    await tester.tap(find.text(Translator.get('shiny_hunt_reopen_btn')));
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id)!.isCompleted, isFalse);
    expect(find.text(Translator.get('shiny_hunt_tap_to_count')), findsOneWidget);
  });

  testWidgets('Renders phase history card when past phases exist', (tester) async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'phase-history-hunt',
      title: 'Giratina Phase Hunt',
      pokemonId: 487,
      pokemonName: 'Giratina',
      game: 'Platin',
      generation: 4.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      currentEncounters: 42,
      phase: 2,
      phaseHistory: [
        ShinyPhaseEntry(
          phaseNumber: 1,
          encounters: 850,
          caughtPokemonId: 418,
          caughtPokemonName: 'Bojelin',
          completedAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    await huntProvider.createHunt(hunt);

    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    expect(find.text(Translator.get('shiny_hunt_phase_history_card_title')), findsOneWidget);
    expect(find.textContaining('Bojelin'), findsOneWidget);
    expect(find.textContaining('850'), findsOneWidget);
  });

  testWidgets('Context chips render Game, Method, Hunting Type, Target Dex, Shiny Charm, Form, and Notes', (tester) async {
    dexProvider.mockUserDexes = [
      UserDex(
        id: 'dex-kanto',
        title: 'Kanto Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
      ),
    ];

    final hunt = await createTestHunt(
      id: 'chips-hunt-1',
      pokemonFormId: 10100,
      huntingType: 'breeding',
      hasShinyCharm: true,
      targetDexId: 'dex-kanto',
      notes: 'Mein Zuchtprojekt',
    );

    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Verify each context chip is displayed
    expect(find.text('Karmesin / Purpur'), findsOneWidget);
    expect(find.textContaining('Standard Wild'), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_type_breeding')), findsOneWidget);
    expect(find.text('Kanto Dex'), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_charm_badge')), findsOneWidget);
    expect(find.textContaining('#10100'), findsOneWidget);
    expect(find.text('Mein Zuchtprojekt'), findsOneWidget);

    // Tapping notes chip opens the dialog with full notes
    await tester.ensureVisible(find.text('Mein Zuchtprojekt'));
    await tester.tap(find.text('Mein Zuchtprojekt'));
    await pumpView(tester);

    expect(find.text(Translator.get('notes', fallback: 'Notizen')), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await pumpView(tester);
  });

  testWidgets('Custom step selector opens dialog, updates incrementStep, and increments by custom amount', (tester) async {
    final hunt = await createTestHunt(id: 'custom-step-hunt', currentEncounters: 10);
    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Initial step is 1
    expect(huntProvider.getHuntById(hunt.id)!.incrementStep, equals(1));

    // Tap Custom step chip
    final customChip = find.text(Translator.get('shiny_hunt_step_custom'));
    expect(customChip, findsOneWidget);
    await tester.tap(customChip);
    await pumpView(tester);

    // Dialog should be open
    expect(find.text(Translator.get('shiny_hunt_step_custom_title')), findsOneWidget);

    // Enter custom number (e.g. 25)
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text(Translator.get('save', fallback: 'Speichern')));
    await pumpView(tester);

    // Step size should be updated in provider
    expect(huntProvider.getHuntById(hunt.id)!.incrementStep, equals(25));
    // The +25 choice chip should now be visible and selected
    expect(find.text('+25'), findsOneWidget);

    // Tap central tap zone to count
    await tester.tap(find.text(Translator.get('shiny_hunt_tap_to_count')));
    await pumpView(tester);

    // Current encounters should increase from 10 to 35
    expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(35));
    expect(find.text('35'), findsOneWidget);
  });

  testWidgets('Completed hunt renders Catch Details card with catch date, ball, notes, and reopen button', (tester) async {
    final compDate = DateTime(2026, 3, 21);
    final hunt = await createTestHunt(
      id: 'completed-details-hunt',
      status: 'completed',
      currentEncounters: 1500,
      completedAt: compDate,
      ballUsed: 'ultra-ball',
      notes: 'Zufallsfund im Gras',
      huntingType: 'wild',
    );

    await tester.pumpWidget(buildTestWidget(hunt.id));
    await pumpView(tester);

    // Verify catch details card
    expect(find.text(Translator.get('shiny_hunt_catch_details_title')), findsOneWidget);
    expect(find.textContaining('21.03.2026'), findsOneWidget);
    expect(find.textContaining('Hyperball'), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_type_wild')), findsWidgets);
    expect(find.textContaining('Zufallsfund im Gras'), findsWidgets);

    // Tap reopen icon button on catch details card
    final reopenIconBtn = find.widgetWithIcon(IconButton, Icons.refresh_rounded);
    expect(reopenIconBtn, findsOneWidget);
    await tester.tap(reopenIconBtn);
    await pumpView(tester);

    // Hunt should now be active again
    expect(huntProvider.getHuntById(hunt.id)!.isActive, isTrue);
    expect(find.text(Translator.get('shiny_hunt_tap_to_count')), findsOneWidget);
  });
}
