import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/screens/dex/dex_screen.dart';
import 'package:pokevault/screens/dex/dex_list_view.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/screens/dex/dex_sort_settings_screen.dart';
import 'package:pokevault/screens/dex/route_tracker_screen.dart';
import 'package:pokevault/screens/ignored_list/ignored_list_screen.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

class MockTutorialProvider extends Mock implements TutorialProvider {}

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;

  @override
  Future<String?> getLibraryPath() async => tempDir.path;

  @override
  Future<String?> getDownloadsPath() async => tempDir.path;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockTutorialProvider mockTutorialProvider;

  final testPokemon = [
    Pokemon(
      id: 1,
      nameDe: 'Bisasam',
      nameEn: 'Bulbasaur',
      hasGenderDifferences: false,
      genderRate: 1,
      captureRate: 45,
      evolutionChainId: 1,
      eggGroups: ['Monster', 'Grass'],
      weight: 6.9,
      speed: 45,
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
    Pokemon(
      id: 7,
      nameDe: 'Schiggy',
      nameEn: 'Squirtle',
      hasGenderDifferences: false,
      genderRate: 1,
      captureRate: 45,
      evolutionChainId: 3,
      eggGroups: ['Monster', 'Water 1'],
      weight: 9.0,
      speed: 43,
      forms: [],
    ),
  ];

  late UserDex testDex;

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(UserDex(
      id: 'dummy',
      title: 'dummy',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
    ));

    tempDir = Directory.systemTemp.createTempSync('pokevault_dex_screen_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    await DatabaseService.instance.appDatabase;
    await DatabaseService.instance.userDatabase;
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    Translator.currentLanguage = 'de';
    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockTutorialProvider = MockTutorialProvider();

    testDex = UserDex(
      id: 'dex_test_kanto',
      title: 'Kanto Test Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['1_normal'],
      shinyIds: [],
      ignoredIds: [],
      viewMode: 'list',
    );

    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
    when(() => mockTutorialProvider.getFeatureStep(any())).thenReturn(0);

    when(() => mockDexProvider.userDexes).thenReturn([testDex]);
    when(() => mockDexProvider.allPokemon).thenReturn(testPokemon);
    when(() => mockDexProvider.ballUrls).thenReturn({});
    when(() => mockDexProvider.allRibbons).thenReturn([]);
    when(() => mockDexProvider.folders).thenReturn([]);
    when(() => mockDexProvider.structure).thenReturn({'root': [testDex.id]});
    when(() => mockDexProvider.allAvailableDexes).thenReturn({'kanto': [1, 4, 7]});
    when(() => mockDexProvider.saveUserDexAndSync(any())).thenAnswer((_) async {});
  });

  Widget buildDexScreen({UserDex? dex}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
        ChangeNotifierProvider<TutorialProvider>.value(
          value: mockTutorialProvider,
        ),
      ],
      child: MaterialApp(
        home: DexScreen(
          initialDex: dex ?? testDex,
          pokemonList: testPokemon,
        ),
      ),
    );
  }

  Future<void> pumpAndLoad(WidgetTester tester, {UserDex? dex}) async {
    await tester.pumpWidget(buildDexScreen(dex: dex));
    for (int i = 0; i < 15; i++) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
      if (find.byType(DexScreen).evaluate().isNotEmpty &&
          find.byType(DexListView).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('DexScreen laedt und zeigt DexListView mit initialen Pokemon an', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    expect(find.byType(DexScreen), findsOneWidget);
    expect(find.byType(DexListView), findsOneWidget);
    expect(find.text('Kanto Test Dex'), findsOneWidget);
    expect(find.text('Bisasam'), findsOneWidget);
    expect(find.text('Glumanda'), findsOneWidget);
    expect(find.text('Schiggy'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Wechsel zwischen DexListView und DexBoxView ueber Sortiermenue', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);
    expect(find.byType(DexListView), findsOneWidget);

    // Open popup menu
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Select Box-Ansicht
    await tester.tap(find.text(Translator.get('view_box')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DexBoxView), findsOneWidget);
    expect(find.byType(DexListView), findsNothing);

    // Switch back to List-Ansicht
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(Translator.get('view_list')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DexListView), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Suchleiste filtert Pokemon nach Name und clear-Button leert Text', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    // Search for 'Glumanda'
    await tester.enterText(find.byType(TextField), 'Glumanda');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(Card, 'Glumanda'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Bisasam'), findsNothing);
    expect(find.widgetWithText(Card, 'Schiggy'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(Card, 'Bisasam'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Glumanda'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Schiggy'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Filter-Dropdown filtert nach gefangen und fehlend', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    // Initially Bisasam is caught (id 1_normal)
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Select filter_caught
    await tester.tap(find.text(Translator.get('filter_caught')).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.widgetWithText(Card, 'Bisasam'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Glumanda'), findsNothing);
    expect(find.widgetWithText(Card, 'Schiggy'), findsNothing);

    // Select filter_missing
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(Translator.get('filter_missing')).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.widgetWithText(Card, 'Bisasam'), findsNothing);
    expect(find.widgetWithText(Card, 'Glumanda'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Schiggy'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Aktivieren des Edit-Modus ueber Checklist-Icon und Abbrechen', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    // Tap on checklist icon to enter edit mode
    await tester.tap(find.byIcon(Icons.checklist));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Edit mode should switch to BoxView and show back button in AppBar
    expect(find.byType(DexBoxView), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    // Tap back button to open discard dialog
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);

    // Discard changes
    await tester.tap(find.text('Verwerfen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BackButtonIcon), findsNothing);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Navigation zu RouteTrackerScreen ueber Location-Icon', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    await tester.tap(find.byIcon(Icons.location_on));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(RouteTrackerScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Navigation zu DexSortSettingsScreen ueber PopupMenu', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(Translator.get('advanced_sort_title')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DexSortSettingsScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Navigation zu IgnoredListScreen ueber PopupMenu', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(Translator.get('ignored_list_title')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(IgnoredListScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Tippen auf AppBar-Titel oeffnet DexProgressDialog', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    // Mini progress bar and caught counter with percentage are visible in AppBar
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.textContaining('1 / 3'), findsWidgets);

    // Tap on the title area
    await tester.tap(find.textContaining('Kanto Test Dex'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dex-Fortschritt & Statistiken dialog is shown
    expect(find.text(Translator.get('dex_progress_title')), findsOneWidget);
    expect(find.textContaining('33.3%'), findsWidgets);

    // Close dialog
    await tester.tap(find.text(Translator.get('dex_progress_close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(Translator.get('dex_progress_title')), findsNothing);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Statistik-Icon in AppBar oeffnet Dialog und filtert ueber "Nur Fehlende anzeigen"', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    // Tap on bar_chart icon in AppBar actions
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(Translator.get('dex_progress_title')), findsOneWidget);

    // Tap on "Nur Fehlende anzeigen"
    await tester.tap(find.text(Translator.get('dex_progress_show_missing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog is closed and Dex is filtered: only Glumanda and Schiggy shown, Bisasam hidden
    expect(find.text(Translator.get('dex_progress_title')), findsNothing);
    expect(find.widgetWithText(Card, 'Bisasam'), findsNothing);
    expect(find.widgetWithText(Card, 'Glumanda'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Schiggy'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('AppBar-Titel hat Tooltip und "Alle anzeigen" im Dialog setzt Filter zurueck', (
    WidgetTester tester,
  ) async {
    await pumpAndLoad(tester);

    // Verify tooltip on title
    expect(find.byTooltip(Translator.get('dex_progress_tooltip')), findsWidgets);

    // First filter to missing
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(Translator.get('dex_progress_show_missing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(Card, 'Bisasam'), findsNothing);

    // Open dialog again and tap "Alle anzeigen"
    await tester.tap(find.byTooltip(Translator.get('dex_progress_tooltip')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(Translator.get('dex_progress_show_all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // All Pokemon visible again
    expect(find.widgetWithText(Card, 'Bisasam'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Glumanda'), findsOneWidget);
    expect(find.widgetWithText(Card, 'Schiggy'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('DexScreen auf 320px schmalem Bildschirm rendert ohne Overflow in AppBar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320.0, 600.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpAndLoad(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('1 / 3'), findsWidgets);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('DexScreen triggers dex_appbar_tools tutorial after ignored_pokemon is seen', (
    WidgetTester tester,
  ) async {
    when(() => mockTutorialProvider.hasSeenFeature('dex_screen')).thenReturn(true);
    when(() => mockTutorialProvider.hasSeenFeature('pokemon_details')).thenReturn(true);
    when(() => mockTutorialProvider.hasSeenFeature('ignored_pokemon')).thenReturn(true);
    when(() => mockTutorialProvider.hasSeenFeature('dex_appbar_tools')).thenReturn(false);

    await pumpAndLoad(tester);

    expect(find.byType(TutorialOverlay), findsOneWidget);
    final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
    expect(overlay.feature.id, equals('dex_appbar_tools'));
    expect(overlay.feature.steps.length, equals(6));

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('DexScreen triggers dex_appbar_tools tutorial when ignored_pokemon was not seen but ignoredIds is empty', (
    WidgetTester tester,
  ) async {
    when(() => mockTutorialProvider.hasSeenFeature('dex_screen')).thenReturn(true);
    when(() => mockTutorialProvider.hasSeenFeature('pokemon_details')).thenReturn(true);
    when(() => mockTutorialProvider.hasSeenFeature('ignored_pokemon')).thenReturn(false);
    when(() => mockTutorialProvider.hasSeenFeature('dex_appbar_tools')).thenReturn(false);

    await pumpAndLoad(tester);

    expect(find.byType(TutorialOverlay), findsOneWidget);
    final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
    expect(overlay.feature.id, equals('dex_appbar_tools'));
    expect(overlay.feature.steps.length, equals(6));

    await tester.pump(const Duration(seconds: 15));
  });
}
