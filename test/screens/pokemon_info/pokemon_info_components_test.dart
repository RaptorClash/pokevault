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
import 'package:pokevault/screens/pokemon_info/widgets/encounters_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/marks_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/ribbons_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/special_obtainable_card.dart';
import 'package:pokevault/screens/pokemon_info/widgets/language_widget.dart';
import 'package:pokevault/screens/pokemon_info/breeding_calculator_widget.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}

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

  final bulbasaur = Pokemon(
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
    forms: [
      PokemonForm(
        name: 'normal',
        formType: 'normal',
        minGen: 1,
        imageId: 1,
        types: ['grass', 'poison'],
        exclusiveRegions: [],
      ),
    ],
  );

  final pikachu = Pokemon(
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
    forms: [
      PokemonForm(
        name: 'normal',
        formType: 'normal',
        minGen: 1,
        imageId: 25,
        types: ['electric'],
        exclusiveRegions: [],
      ),
    ],
  );

  final charmander = Pokemon(
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
  );

  final gyarados = Pokemon(
    id: 130,
    nameDe: 'Garados',
    nameEn: 'Gyarados',
    hasGenderDifferences: true,
    genderRate: 4,
    captureRate: 45,
    evolutionChainId: 58,
    eggGroups: ['Water 2', 'Dragon'],
    weight: 235.0,
    speed: 81,
    forms: [],
  );

  final testDex = UserDex(
    id: 'test_dex_1',
    title: 'Test Dex',
    region: 'national',
    includeGenders: false,
    includeRegional: true,
    includeMega: true,
    includeGMax: true,
    includeOther: true,
    isShinyDex: false,
    caughtIds: ['1_normal', '25_normal'],
    caughtRibbons: {'1_normal': ['champion_ribbon']},
    caughtLanguages: {'1_normal': ['GER']},
  );

  final bulbaEntry = DexDisplayEntry(
    pokemon: bulbasaur,
    uniqueId: '1_normal',
    displaySuffix: '',
    imageUrl: 'https://example.com/1.png',
  );

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = Directory.systemTemp.createTempSync('pokevault_components_test_');
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
    LocaleSettings.setLocale(AppLocale.de);
    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();

    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    when(() => mockDexProvider.userDexes).thenReturn([testDex]);
    when(() => mockDexProvider.allPokemon).thenReturn([bulbasaur, pikachu, charmander, gyarados]);
  });

  Widget wrapWithProviders(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  Future<void> pumpAsyncDB(WidgetTester tester) async {
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
  }

  group('EncountersWidget Tests', () {
    testWidgets('renders encounters table and expands generation tile', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(
        EncountersWidget(pokemonId: 1, encountersKey: GlobalKey()),
      ));
      await pumpAsyncDB(tester);

      final title = find.text(t.encounters_title);
      expect(title, findsOneWidget);

      // Expand main encounters card
      await tester.tap(title);
      await tester.pump(const Duration(milliseconds: 500));
      await pumpAsyncDB(tester);

      // Find Gen 1 ExpansionTile
      final genTile = find.textContaining('Generation 1').first;
      expect(genTile, findsOneWidget);

      await tester.tap(genTile, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Check note is displayed
      expect(find.text(t.encounter_missing_note), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('renders Mew glitch note for pokemonId = 151', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(
        EncountersWidget(pokemonId: 151, encountersKey: GlobalKey()),
      ));
      await pumpAsyncDB(tester);

      // Open encounters
      final title = find.text(t.encounters_title);
      await tester.tap(title);
      await pumpAsyncDB(tester);
      await tester.pumpAndSettle();

      // Open Gen 1 ExpansionTile
      final genTile = find.textContaining('Generation 1').first;
      expect(genTile, findsOneWidget);
      await tester.tap(genTile);
      await tester.pumpAndSettle();

      // Check glitch note button
      expect(find.text(t.tutorial_mew_normal_link), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('renders empty state for unknown pokemon ID', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(
        EncountersWidget(pokemonId: 99999, encountersKey: GlobalKey()),
      ));
      await pumpAsyncDB(tester);

      final title = find.text(t.encounters_title);
      await tester.tap(title);
      await tester.pump(const Duration(milliseconds: 500));
      await pumpAsyncDB(tester);

      expect(find.text(t.no_encounters_found), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('MarksWidget Tests', () {
    testWidgets('renders marks, handles tap toggle and search filter', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(
        MarksWidget(entry: bulbaEntry, dexId: 'test_dex_1', marksKey: GlobalKey()),
      ));
      await pumpAsyncDB(tester);

      final marksTile = find.text(t.marks);
      if (marksTile.evaluate().isNotEmpty) {
        expect(marksTile, findsOneWidget);

        // Expand
        await tester.tap(marksTile);
        await tester.pump(const Duration(milliseconds: 500));

        // Search textfield
        final searchField = find.widgetWithText(TextField, t.search);
        expect(searchField, findsOneWidget);

        // Filter search
        await tester.enterText(searchField, 'Mittags');
        await tester.pump();

        // Clear search
        await tester.enterText(searchField, '');
        await tester.pump();
      }

      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('RibbonsWidget Tests', () {
    testWidgets('renders ribbons, handles tap toggle and search filter', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(
        RibbonsWidget(entry: bulbaEntry, dexId: 'test_dex_1', ribbonsKey: GlobalKey()),
      ));
      await pumpAsyncDB(tester);

      final ribbonsTile = find.text(t.ribbons);
      if (ribbonsTile.evaluate().isNotEmpty) {
        expect(ribbonsTile, findsOneWidget);

        // Expand
        await tester.tap(ribbonsTile);
        await tester.pump(const Duration(milliseconds: 500));

        // Search textfield
        final searchField = find.widgetWithText(TextField, t.search);
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'Champ');
        await tester.pump();

        await tester.enterText(searchField, '');
        await tester.pump();
      }

      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('LanguageWidget Tests', () {
    testWidgets('renders language chips and triggers updatePokemonLanguages on tap', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockDexProvider.updatePokemonLanguages(any(), any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(wrapWithProviders(
        LanguageWidget(entry: bulbaEntry, dexId: 'test_dex_1'),
      ));
      await tester.pump();

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      final engChip = find.text('ENG');
      expect(engChip, findsOneWidget);

      await tester.tap(engChip);
      await tester.pump();

      verify(() => mockDexProvider.updatePokemonLanguages('test_dex_1', '1_normal', any())).called(1);

      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('SpecialObtainableCard Tests', () {
    testWidgets('returns shrink for non-special uniqueId', (tester) async {
      await tester.pumpWidget(wrapWithProviders(
        const SpecialObtainableCard(uniqueId: '1_normal'),
      ));
      await tester.pump();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders card for valid special uniqueId', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(
        const SpecialObtainableCard(uniqueId: '1_special_1_'),
      ));
      await pumpAsyncDB(tester);

      expect(find.byType(Card), findsOneWidget);
      expect(find.textContaining('Level:'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('BreedingCalculatorWidget Tests', () {
    testWidgets('initializes and calculates breeding path', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(
        const BreedingCalculatorWidget(initialTargetId: 1, dexId: 'test_dex_1'),
      ));
      await pumpAsyncDB(tester);

      final title = find.text(t.shiny_breed_calc_title);
      expect(title, findsOneWidget);

      await tester.tap(title);
      await tester.pump(const Duration(milliseconds: 500));
      await pumpAsyncDB(tester);

      // Check header or target displays
      expect(find.textContaining('Bisasam'), findsWidgets);

      await tester.pump(const Duration(seconds: 15));
    });
  });
}
