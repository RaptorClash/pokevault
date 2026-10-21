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
import 'package:pokevault/screens/pokemon_info/widgets/gender_differences_card.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_info_page.dart';
import 'package:pokevault/screens/pokemon_info/widgets/breeding_info_widget.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}

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

Future<void> pumpAsyncDB(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    if (find.descendant(
          of: find.byType(GenderDifferencesCard),
          matching: find.byType(ExpansionTile),
        ).evaluate().isNotEmpty) {
      break;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': 27});
    LocaleSettings.setLocale(AppLocale.de);
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  Widget createTestWidget({
    required Pokemon pokemon,
    required MockDexProvider mockDexProvider,
    required FakeSettingsProvider fakeSettingsProvider,
  }) {
    final entry = DexDisplayEntry(
      pokemon: pokemon,
      uniqueId: '${pokemon.id}',
      displaySuffix: '',
      imageUrl: 'https://example.com/${pokemon.id}.png',
    );

    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: fakeSettingsProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
          body: PokemonInfoPage(
            entry: entry,
            dexId: 'test_dex',
            manualShinyToggle: false,
            onShinyToggled: () {},
            onIgnore: () {},
            shinyToggleKey: GlobalKey(),
            alphaToggleKey: GlobalKey(),
            basicInfoKey: GlobalKey(),
            caughtStatusKey: GlobalKey(),
            shinyStatusKey: GlobalKey(),
            breedingKey: GlobalKey(),
            catchCalcKey: GlobalKey(),
            matchingBallsKey: GlobalKey(),
            teraKey: GlobalKey(),
            ribbonsKey: GlobalKey(),
            marksKey: GlobalKey(),
            encountersKey: GlobalKey(),
            shinyGuideKey: GlobalKey(),
            ignoreBtnKey: GlobalKey(),
            languageKey: GlobalKey(),
          ),
        ),
      ),
    ),
  );
}

  group('PokemonInfoPage Integration Tests with GenderDifferencesCard', () {
    late MockDexProvider mockDexProvider;
    late FakeSettingsProvider fakeSettingsProvider;

    setUp(() {
      mockDexProvider = MockDexProvider();
      fakeSettingsProvider = FakeSettingsProvider(currentLanguage: 'de');

      final userDex = UserDex.fallback('test_dex');

      when(() => mockDexProvider.userDexes).thenReturn([userDex]);
    });

    testWidgets('Rendert GenderDifferencesCard wenn Pokemon hasGenderDifferences true ist', (tester) async {
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
        forms: [],
      );

      await tester.pumpWidget(createTestWidget(
        pokemon: bisaflor,
        mockDexProvider: mockDexProvider,
        fakeSettingsProvider: fakeSettingsProvider,
      ));

      expect(find.byType(GenderDifferencesCard), findsOneWidget);
    });

    testWidgets('Rendert KEINE GenderDifferencesCard wenn Pokemon hasGenderDifferences false ist', (tester) async {
      final glumanda = Pokemon(
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

      await tester.pumpWidget(createTestWidget(
        pokemon: glumanda,
        mockDexProvider: mockDexProvider,
        fakeSettingsProvider: fakeSettingsProvider,
      ));

      expect(find.byType(GenderDifferencesCard), findsNothing);
    });

    testWidgets('GenderDifferencesCard wird ohne redundanten SizedBox-Abstand direkt nach BreedingInfo platziert', (tester) async {
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
        forms: [],
      );

      await tester.pumpWidget(createTestWidget(
        pokemon: bisaflor,
        mockDexProvider: mockDexProvider,
        fakeSettingsProvider: fakeSettingsProvider,
      ));

      expect(find.byType(GenderDifferencesCard), findsOneWidget);

      final pageColumn = tester.widget<Column>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Column),
        ).first,
      );

      final children = pageColumn.children;
      final breedingIndex = children.indexWhere(
        (w) => w is Container && w.child is BreedingInfoWidget,
      );
      final genderCardIndex = children.indexWhere(
        (w) => w is GenderDifferencesCard,
      );

      expect(breedingIndex, isNot(equals(-1)));
      expect(genderCardIndex, isNot(equals(-1)));
      // Beweist, dass keine extra SizedBox dazwischenliegt:
      expect(genderCardIndex, equals(breedingIndex + 1));
    });
  });
}
