import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/pokemon_info/pokemon_info_screen.dart';
import 'package:pokevault/screens/pokemon_info/widgets/gender_differences_card.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockTutorialProvider extends Mock implements TutorialProvider {}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  String currentLanguage;

  FakeSettingsProvider({this.currentLanguage = 'de'});

  @override
  ThemeMode themeMode = ThemeMode.system;

  @override
  String get googleClientId => '';

  @override
  String get googleClientSecret => '';

  @override
  bool get autoSyncEnabled => false;

  @override
  void setLanguage(String lang) {
    currentLanguage = lang;
    notifyListeners();
  }

  @override
  Future<void> setGoogleClientId(String id) async {}

  @override
  Future<void> setGoogleClientSecret(String secret) async {}

  @override
  Future<void> setAutoSyncEnabled(bool enabled) async {}

  @override
  Future<void> toggleTheme() async {}
}

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getLibraryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getDownloadsPath() async => Directory.systemTemp.path;
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

Future<void> pumpAsyncDB(WidgetTester tester, [int expectedTiles = 1]) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    if (find.descendant(
          of: find.byType(GenderDifferencesCard),
          matching: find.byType(ExpansionTile),
        ).evaluate().length >= expectedTiles) {
      break;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Database? testDb;

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
    LocaleSettings.setLocale(AppLocale.de);
    final dbFile = File('assets/db/pokedex.sqlite');
    if (dbFile.existsSync()) {
      testDb = await openDatabase(dbFile.absolute.path, readOnly: true);
      DatabaseService.setAppDatabaseForTesting(testDb);
    }
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    DatabaseService.setAppDatabaseForTesting(null);
    await testDb?.close();
  });

  final bisaflor = Pokemon(
    id: 3,
    nameDe: 'Bisaflor',
    nameEn: 'Venusaur',
    hasGenderDifferences: true,
    genderRate: 1,
    captureRate: 45,
    evolutionChainId: 1,
    eggGroups: ['Monster', 'Grass'],
    weight: 100.0,
    speed: 80,
    forms: [
      PokemonForm(
        name: 'normal',
        formType: 'normal',
        imageId: 3,
        types: ['grass', 'poison'],
        exclusiveRegions: [],
        minGen: 1,
      ),
    ],
  );

  Widget createScreen({
    required List<DexDisplayEntry> entries,
    required MockDexProvider mockDexProvider,
    required MockTutorialProvider mockTutorialProvider,
    required FakeSettingsProvider fakeSettingsProvider,
    int initialIndex = 0,
    String dexId = 'test_dex',
  }) {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: fakeSettingsProvider),
          ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
        ],
        child: MaterialApp(
          home: PokemonInfoScreen(
            entries: entries,
            initialIndex: initialIndex,
            dexId: dexId,
          ),
        ),
      ),
    );
  }

  group('PokemonInfoScreen Gender Navigation Tests (TDD)', () {
    late MockDexProvider mockDexProvider;
    late MockTutorialProvider mockTutorialProvider;
    late FakeSettingsProvider fakeSettingsProvider;
    late UserDex userDex;

    setUp(() {
      mockDexProvider = MockDexProvider();
      mockTutorialProvider = MockTutorialProvider();
      fakeSettingsProvider = FakeSettingsProvider(currentLanguage: 'de');

      userDex = UserDex.fallback('test_dex');
      when(() => mockDexProvider.userDexes).thenReturn([userDex]);
      when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
    });

    testWidgets('Gender Dex: Wechselt per PageController flüssig von 3_m zu 3_f und zurück', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final maleEntry = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_m',
        displaySuffix: ' ♂',
        imageUrl: 'https://example.com/3.png',
        form: bisaflor.forms.first,
      );
      final femaleEntry = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_f',
        displaySuffix: ' ♀',
        imageUrl: 'https://example.com/3_f.png',
        form: bisaflor.forms.first,
      );

      await tester.pumpWidget(createScreen(
        entries: [maleEntry, femaleEntry],
        mockDexProvider: mockDexProvider,
        mockTutorialProvider: mockTutorialProvider,
        fakeSettingsProvider: fakeSettingsProvider,
        initialIndex: 0,
      ));
      await pumpAsyncDB(tester);

      // Verify initial page is 3_m (1 / 2)
      expect(find.text('1 / 2'), findsOneWidget);

      // Open GenderDifferencesCard on male page
      final malePage = find.byKey(const ValueKey('3_m'));
      final maleTileFinder = find.descendant(
        of: find.descendant(
          of: malePage,
          matching: find.byType(GenderDifferencesCard),
        ),
        matching: find.byType(ExpansionTile),
      );
      await tester.tap(maleTileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // Tap on female card
      final femaleActionFinder = find.descendant(
        of: malePage,
        matching: find.byKey(const Key('gender_diff_female_action')),
      );
      await tester.tap(femaleActionFinder);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Now the page should be at index 1 (3_f) -> shows 2 / 2
      expect(find.text('2 / 2'), findsOneWidget);
      await pumpAsyncDB(tester);

      // Open GenderDifferencesCard on female page
      final femalePage = find.byKey(const ValueKey('3_f'));
      final femaleTileFinder = find.descendant(
        of: find.descendant(
          of: femalePage,
          matching: find.byType(GenderDifferencesCard),
        ),
        matching: find.byType(ExpansionTile),
      );
      await tester.tap(femaleTileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // Tap on male card
      final maleActionFinder = find.descendant(
        of: femalePage,
        matching: find.byKey(const Key('gender_diff_male_action')),
      );
      await tester.tap(maleActionFinder);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should be back at index 0 (3_m) -> shows 1 / 2
      expect(find.text('1 / 2'), findsOneWidget);

      // Drain 10s sqflite timer
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Non-Gender Dex: Öffnet neuen Screen für 3_f wenn female nicht in entries ist', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final baseEntry = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_normal',
        displaySuffix: '',
        imageUrl: 'https://example.com/3.png',
        form: bisaflor.forms.first,
      );

      await tester.pumpWidget(createScreen(
        entries: [baseEntry],
        mockDexProvider: mockDexProvider,
        mockTutorialProvider: mockTutorialProvider,
        fakeSettingsProvider: fakeSettingsProvider,
        initialIndex: 0,
      ));
      await pumpAsyncDB(tester);

      // Open GenderDifferencesCard
      final expansionTileFinder = find.descendant(
        of: find.byType(GenderDifferencesCard),
        matching: find.byType(ExpansionTile),
      ).first;
      await tester.tap(expansionTileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // Tap on female card
      final femaleActionFinder = find.byKey(const Key('gender_diff_female_action'));
      await tester.tap(femaleActionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      // A new PokemonInfoScreen was pushed! It has female Venusaur (displaySuffix ' ♀' or uniqueId '3_f')
      expect(find.byType(PokemonInfoScreen), findsNWidgets(2));
      expect(find.textContaining('♀'), findsWidgets);

      // Pop back via top screen Navigator
      final nav = Navigator.of(tester.element(find.byType(PokemonInfoScreen).last));
      expect(nav.canPop(), isTrue);
      nav.pop();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(PokemonInfoScreen), findsOneWidget);

      // Drain 10s sqflite timer
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Non-Gender Dex: Klick auf Männlich auf dem gepushten female Screen poppt zurück statt unendlich zu stacken', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final baseEntry = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_normal',
        displaySuffix: '',
        imageUrl: 'https://example.com/3.png',
        form: bisaflor.forms.first,
      );

      await tester.pumpWidget(createScreen(
        entries: [baseEntry],
        mockDexProvider: mockDexProvider,
        mockTutorialProvider: mockTutorialProvider,
        fakeSettingsProvider: fakeSettingsProvider,
        initialIndex: 0,
      ));
      await pumpAsyncDB(tester);

      // Open GenderDifferencesCard on 3_normal
      final tileFinder = find.descendant(
        of: find.byType(GenderDifferencesCard),
        matching: find.byType(ExpansionTile),
      ).first;
      await tester.tap(tileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // Tap female card -> pushes female screen
      final femaleActionFinder = find.byKey(const Key('gender_diff_female_action'));
      await tester.tap(femaleActionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byType(PokemonInfoScreen), findsNWidgets(2));

      // Open GenderDifferencesCard on the pushed female screen
      await pumpAsyncDB(tester, 2);
      final femaleTileFinder = find.descendant(
        of: find.byType(GenderDifferencesCard),
        matching: find.byType(ExpansionTile),
      ).last;
      await tester.tap(femaleTileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // Tap male card on the pushed female screen
      final maleActionFinder = find.byKey(const Key('gender_diff_male_action')).last;
      await tester.tap(maleActionFinder);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // MUST NOT push a 3rd screen! It must pop back to 1 screen!
      expect(find.byType(PokemonInfoScreen), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Regional Forms: Klick auf weiblich bei Hisui-Form springt zur Hisui-weiblich Form und nicht zur Johto-Form', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sneasel = Pokemon(
        id: 215,
        nameDe: 'Sniebel',
        nameEn: 'Sneasel',
        hasGenderDifferences: true,
        genderRate: 1,
        captureRate: 60,
        evolutionChainId: 108,
        eggGroups: ['Field'],
        weight: 28.0,
        speed: 115,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            imageId: 215,
            types: ['dark', 'ice'],
            exclusiveRegions: [],
            minGen: 2,
          ),
          PokemonForm(
            name: 'hisui',
            formType: 'regional',
            imageId: 215,
            types: ['fighting', 'poison'],
            exclusiveRegions: ['hisui'],
            minGen: 8,
          ),
        ],
      );

      final johtoMale = DexDisplayEntry(
        pokemon: sneasel,
        uniqueId: '215_m',
        displaySuffix: ' ♂',
        imageUrl: 'https://example.com/215.png',
        form: sneasel.forms[0],
      );
      final johtoFemale = DexDisplayEntry(
        pokemon: sneasel,
        uniqueId: '215_f',
        displaySuffix: ' ♀',
        imageUrl: 'https://example.com/215_f.png',
        form: sneasel.forms[0],
      );
      final hisuiMale = DexDisplayEntry(
        pokemon: sneasel,
        uniqueId: '215_hisui_m',
        displaySuffix: ' (Hisui) ♂',
        imageUrl: 'https://example.com/215_hisui.png',
        form: sneasel.forms[1],
      );
      final hisuiFemale = DexDisplayEntry(
        pokemon: sneasel,
        uniqueId: '215_hisui_f',
        displaySuffix: ' (Hisui) ♀',
        imageUrl: 'https://example.com/215_hisui_f.png',
        form: sneasel.forms[1],
      );

      // Entries order: Johto M (0), Johto F (1), Hisui M (2), Hisui F (3)
      await tester.pumpWidget(createScreen(
        entries: [johtoMale, johtoFemale, hisuiMale, hisuiFemale],
        mockDexProvider: mockDexProvider,
        mockTutorialProvider: mockTutorialProvider,
        fakeSettingsProvider: fakeSettingsProvider,
        initialIndex: 2, // Start at Hisui Male
      ));
      await pumpAsyncDB(tester);

      expect(find.text('3 / 4'), findsOneWidget);

      // Open GenderDifferencesCard on Hisui Male
      final tileFinder = find.descendant(
        of: find.byType(GenderDifferencesCard),
        matching: find.byType(ExpansionTile),
      ).first;
      await tester.tap(tileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // Tap female card -> must jump to Hisui Female (index 3 -> 4 / 4), NOT Johto Female (index 1 -> 2 / 4)!
      final femaleActionFinder = find.byKey(const Key('gender_diff_female_action'));
      await tester.tap(femaleActionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('4 / 4'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Custom Box: Bei mehrfachen Einträgen desselben Pokemons wird der nächstgelegene Eintrag gewählt', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Box 1 has 3_m at 0, 3_f at 1.
      // Box 2 has filler items, then 3_m at 4, 3_f at 5.
      final fillerPokemon = Pokemon(
        id: 1,
        nameDe: 'Bisasam',
        nameEn: 'Bulbasaur',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['Monster'],
        weight: 6.9,
        speed: 45,
        forms: [],
      );
      final filler1 = DexDisplayEntry(
        pokemon: fillerPokemon,
        uniqueId: '1_normal__1',
        displaySuffix: '',
        imageUrl: 'https://example.com/1.png',
      );
      final filler2 = DexDisplayEntry(
        pokemon: fillerPokemon,
        uniqueId: '1_normal__2',
        displaySuffix: '',
        imageUrl: 'https://example.com/1.png',
      );

      final box1Male = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_m__box1',
        displaySuffix: ' ♂',
        imageUrl: 'https://example.com/3.png',
        form: bisaflor.forms.first,
      );
      final box1Female = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_f__box1',
        displaySuffix: ' ♀',
        imageUrl: 'https://example.com/3_f.png',
        form: bisaflor.forms.first,
      );
      final box2Male = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_m__box2',
        displaySuffix: ' ♂',
        imageUrl: 'https://example.com/3.png',
        form: bisaflor.forms.first,
      );
      final box2Female = DexDisplayEntry(
        pokemon: bisaflor,
        uniqueId: '3_f__box2',
        displaySuffix: ' ♀',
        imageUrl: 'https://example.com/3_f.png',
        form: bisaflor.forms.first,
      );

      final entries = [
        box1Male,   // 0
        box1Female, // 1
        filler1,    // 2
        filler2,    // 3
        box2Male,   // 4
        box2Female, // 5
      ];

      await tester.pumpWidget(createScreen(
        entries: entries,
        mockDexProvider: mockDexProvider,
        mockTutorialProvider: mockTutorialProvider,
        fakeSettingsProvider: fakeSettingsProvider,
        initialIndex: 4, // Start at box2Male (index 4)
      ));
      await pumpAsyncDB(tester);

      expect(find.text('5 / 6'), findsOneWidget);

      // Open GenderDifferencesCard on box2Male
      final tileFinder = find.descendant(
        of: find.byType(GenderDifferencesCard),
        matching: find.byType(ExpansionTile),
      ).first;
      await tester.tap(tileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // Tap female card -> must jump to box2Female (index 5 -> 6 / 6), NOT box1Female (index 1 -> 2 / 6)!
      final femaleActionFinder = find.byKey(const Key('gender_diff_female_action'));
      await tester.tap(femaleActionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('6 / 6'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });
  });
}
