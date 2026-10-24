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
import 'package:pokevault/screens/shiny_hunt/dialogs/create_edit_hunt_dialog.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/shiny_hunt_timeline_dialog.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunt_counter_screen.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunts_hub_screen.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
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
        Pokemon(
          id: 25,
          nameDe: 'Pikachu',
          nameEn: 'Pikachu',
          hasGenderDifferences: true,
          genderRate: 4,
          captureRate: 190,
          evolutionChainId: 10,
          eggGroups: ['Field', 'Fairy'],
          weight: 6.0,
          speed: 90,
          forms: [],
        ),
      ];

  @override
  List<UserDex> get userDexes => [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  Future<ShinyHunt> createHunt({
    required String id,
    required String pokemonName,
    int pokemonId = 6,
    int? pokemonFormId,
    String status = 'active',
    int encounters = 0,
    int step = 1,
    String? ballUsed,
    String? huntingType,
    DateTime? completedAt,
    DateTime? createdAt,
    List<ShinyPauseInterval> pauseHistory = const [],
    String? notes,
  }) async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: id,
      title: pokemonName,
      pokemonId: pokemonId,
      pokemonFormId: pokemonFormId,
      pokemonName: pokemonName,
      game: 'Karmesin / Purpur',
      generation: 9.0,
      method: 'Standard Wild',
      baseOdds: 4096.0,
      spawnsPerEncounter: 1,
      incrementStep: step,
      currentEncounters: encounters,
      status: status,
      ballUsed: ballUsed,
      huntingType: huntingType,
      completedAt: completedAt,
      pauseHistory: pauseHistory,
      notes: notes,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
    await huntProvider.createHunt(hunt);
    return hunt;
  }

  Widget buildHubWidget({int initialTabIndex = 0, TutorialProvider? tutorialProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
        ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
        if (tutorialProvider != null)
          ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
      ],
      child: MaterialApp(
        home: ShinyHuntsHubScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Renders ShinyHuntsHubScreen with empty active tab', (tester) async {
    await tester.pumpWidget(buildHubWidget());
    await pumpView(tester);

    expect(find.text(Translator.get('shiny_hunt_hub_title')), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_empty_active')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Displays active hunt card and increments encounters via quick +1 button', (tester) async {
    final hunt = await createHunt(id: 'active-1', pokemonName: 'Glurak', encounters: 5);
    await tester.pumpWidget(buildHubWidget());
    await pumpView(tester);

    expect(find.text('Glurak'), findsOneWidget);
    expect(find.textContaining('5 Encounters'), findsOneWidget);

    // Tap quick +1 button
    final addIcon = find.descendant(
      of: find.byType(Card),
      matching: find.byIcon(Icons.add),
    );
    expect(addIcon, findsOneWidget);
    await tester.tap(addIcon);
    await pumpView(tester);

    expect(find.textContaining('6 Encounters'), findsOneWidget);
    expect(huntProvider.getHuntById(hunt.id)!.currentEncounters, equals(6));
  });

  testWidgets('Quick pause button in active tab moves hunt to paused', (tester) async {
    final hunt = await createHunt(id: 'active-pause-test', pokemonName: 'Glurak', encounters: 10);
    await tester.pumpWidget(buildHubWidget());
    await pumpView(tester);

    final pauseIcon = find.descendant(
      of: find.byType(Card),
      matching: find.byIcon(Icons.pause),
    );
    expect(pauseIcon, findsOneWidget);

    await tester.tap(pauseIcon);
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id)!.isPaused, isTrue);
    // Active tab is now empty
    expect(find.text(Translator.get('shiny_hunt_empty_active')), findsOneWidget);
  });

  testWidgets('Paused tab displays paused hunt with resume button which reactivates it', (tester) async {
    final hunt = await createHunt(
      id: 'paused-1',
      pokemonName: 'Pikachu',
      pokemonId: 25,
      status: 'paused',
      encounters: 42,
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 1));
    await pumpView(tester);

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.textContaining('42 Encounters'), findsOneWidget);

    final resumeBtn = find.byIcon(Icons.play_arrow);
    expect(resumeBtn, findsOneWidget);

    await tester.tap(resumeBtn);
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id)!.isActive, isTrue);
    expect(find.text(Translator.get('shiny_hunt_empty_paused')), findsOneWidget);
  });

  testWidgets('Completed tab displays completed hunt with ball and classification badge', (tester) async {
    await createHunt(
      id: 'comp-1',
      pokemonName: 'Glurak',
      pokemonId: 6,
      status: 'completed',
      encounters: 800,
      ballUsed: 'ultra-ball',
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 2));
    await pumpView(tester);

    expect(find.text('Glurak'), findsOneWidget);
    expect(find.textContaining('800 Encounters'), findsOneWidget);
    expect(find.textContaining('Hyperball'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('Completed tab card displays catch date, hunting type, ball, notes, and reopen button', (tester) async {
    final compDate = DateTime(2026, 4, 15);
    await createHunt(
      id: 'comp-detail-1',
      pokemonName: 'Glurak',
      pokemonId: 6,
      status: 'completed',
      encounters: 1200,
      ballUsed: 'ultra-ball',
      huntingType: 'breeding',
      completedAt: compDate,
      notes: 'Ei-Zucht nach 1200 Eiern',
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 2));
    await pumpView(tester);

    expect(find.textContaining('15.04.2026'), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_type_breeding')), findsOneWidget);
    expect(find.textContaining('Hyperball'), findsOneWidget);
    expect(find.textContaining('Ei-Zucht nach 1200 Eiern'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  testWidgets('Tapping completed hunt card navigates to ShinyHuntCounterScreen', (tester) async {
    await createHunt(
      id: 'comp-tap-1',
      pokemonName: 'Glurak',
      pokemonId: 6,
      status: 'completed',
      encounters: 500,
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 2));
    await pumpView(tester);

    await tester.tap(find.text('Glurak'));
    await pumpView(tester);

    expect(find.byType(ShinyHuntCounterScreen), findsOneWidget);
  });

  testWidgets('Reopen button in completed tab restores hunt to active status and shows SnackBar', (tester) async {
    final hunt = await createHunt(
      id: 'comp-reopen-1',
      pokemonName: 'Glurak',
      pokemonId: 6,
      status: 'completed',
      encounters: 300,
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 2));
    await pumpView(tester);

    final reopenBtn = find.byIcon(Icons.refresh_rounded);
    expect(reopenBtn, findsOneWidget);

    await tester.tap(reopenBtn);
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id)!.isActive, isTrue);
    expect(find.text(Translator.get('shiny_hunt_reopened_toast')), findsOneWidget);
  });

  testWidgets('Delete hunt confirmation dialog removes hunt when confirmed', (tester) async {
    final hunt = await createHunt(
      id: 'delete-test',
      pokemonName: 'Pikachu',
      pokemonId: 25,
      status: 'paused',
      encounters: 10,
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 1));
    await pumpView(tester);

    final deleteBtn = find.byIcon(Icons.delete_outline);
    expect(deleteBtn, findsOneWidget);

    await tester.tap(deleteBtn);
    await pumpView(tester);

    expect(find.text(Translator.get('shiny_hunt_delete_confirm_title')), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.text(Translator.get('delete', fallback: 'Löschen')));
    await pumpView(tester);

    expect(huntProvider.getHuntById(hunt.id), isNull);
    expect(find.text(Translator.get('shiny_hunt_empty_paused')), findsOneWidget);
  });

  testWidgets('FAB opens CreateEditHuntDialog', (tester) async {
    await tester.pumpWidget(buildHubWidget());
    await pumpView(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await pumpView(tester);

    expect(find.byType(CreateEditHuntDialog), findsOneWidget);
  });

  testWidgets('Tapping hunt card navigates to ShinyHuntCounterScreen', (tester) async {
    await createHunt(id: 'nav-test', pokemonName: 'Glurak', encounters: 3);
    await tester.pumpWidget(buildHubWidget());
    await pumpView(tester);

    await tester.tap(find.byType(Card));
    await pumpView(tester);

    expect(find.byType(ShinyHuntCounterScreen), findsOneWidget);
  });

  testWidgets('Active hunt card displays start date and pause badge opening ShinyHuntTimelineDialog', (tester) async {
    final start = DateTime(2026, 10, 20, 10, 0);
    final p1Start = DateTime(2026, 10, 21, 12, 0);
    final p1End = DateTime(2026, 10, 21, 13, 0);
    await createHunt(
      id: 'active-timeline-test',
      pokemonName: 'Glurak',
      createdAt: start,
      pauseHistory: [
        ShinyPauseInterval(pausedAt: p1Start, resumedAt: p1End),
      ],
      encounters: 50,
    );
    await tester.pumpWidget(buildHubWidget());
    await pumpView(tester);

    expect(find.textContaining('20.10.2026'), findsOneWidget);
    expect(find.textContaining('1 Pause'), findsOneWidget);

    await tester.tap(find.textContaining('1 Pause'));
    await pumpView(tester);

    expect(find.byType(ShinyHuntTimelineDialog), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_timeline_title', fallback: 'Hunt-Zeiten & Pausen')), findsOneWidget);
  });

  testWidgets('Paused tab displays pause timestamp and history button opening ShinyHuntTimelineDialog', (tester) async {
    final start = DateTime(2026, 10, 20, 10, 0);
    final pauseStart = DateTime(2026, 10, 22, 14, 30);
    await createHunt(
      id: 'paused-timeline-test',
      pokemonName: 'Pikachu',
      pokemonId: 25,
      status: 'paused',
      createdAt: start,
      pauseHistory: [
        ShinyPauseInterval(pausedAt: pauseStart),
      ],
      encounters: 120,
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 1));
    await pumpView(tester);

    expect(find.textContaining('Pausiert seit 22.10.2026'), findsOneWidget);

    final historyBtn = find.byIcon(Icons.history_rounded);
    expect(historyBtn, findsOneWidget);
    await tester.tap(historyBtn);
    await pumpView(tester);

    expect(find.byType(ShinyHuntTimelineDialog), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_timeline_title', fallback: 'Hunt-Zeiten & Pausen')), findsOneWidget);
  });

  testWidgets('Completed tab displays timeline button opening ShinyHuntTimelineDialog', (tester) async {
    final start = DateTime(2026, 10, 18, 9, 0);
    final p1Start = DateTime(2026, 10, 19, 10, 0);
    final p1End = DateTime(2026, 10, 19, 12, 0);
    final completed = DateTime(2026, 10, 24, 15, 30);
    await createHunt(
      id: 'completed-timeline-test',
      pokemonName: 'Glurak',
      status: 'completed',
      createdAt: start,
      completedAt: completed,
      pauseHistory: [
        ShinyPauseInterval(pausedAt: p1Start, resumedAt: p1End),
      ],
      encounters: 500,
      ballUsed: 'master_ball',
    );
    await tester.pumpWidget(buildHubWidget(initialTabIndex: 2));
    await pumpView(tester);

    final historyBtn = find.byIcon(Icons.history_rounded);
    expect(historyBtn, findsOneWidget);
    await tester.tap(historyBtn);
    await pumpView(tester);

    expect(find.byType(ShinyHuntTimelineDialog), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_timeline_title', fallback: 'Hunt-Zeiten & Pausen')), findsOneWidget);
  });

  testWidgets('Triggers live TutorialOverlay for shiny_hunt_hub when not seen and marks as seen on completion', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shiny_hunt_hub');
    final tutProvider = TutorialProvider(prefs);
    expect(tutProvider.hasSeenFeature('shiny_hunt_hub'), isFalse);

    await tester.pumpWidget(buildHubWidget(tutorialProvider: tutProvider));
    await pumpView(tester);

    expect(find.byType(TutorialOverlay), findsOneWidget);
    expect(find.text(Translator.get('tutorial_shiny_new_title')), findsOneWidget);

    // Skip / advance tutorial to complete
    final skipBtn = find.text(Translator.get('tutorial_skip', fallback: 'Überspringen'));
    expect(skipBtn, findsOneWidget);
    await tester.tap(skipBtn);
    await pumpView(tester);

    expect(tutProvider.hasSeenFeature('shiny_hunt_hub'), isTrue);
  });

  testWidgets('Does not trigger live TutorialOverlay when shiny_hunt_hub has already been seen', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shiny_hunt_hub', true);
    final tutProvider = TutorialProvider(prefs);
    expect(tutProvider.hasSeenFeature('shiny_hunt_hub'), isTrue);

    await tester.pumpWidget(buildHubWidget(tutorialProvider: tutProvider));
    await pumpView(tester);

    expect(find.byType(TutorialOverlay), findsNothing);
  });
}
