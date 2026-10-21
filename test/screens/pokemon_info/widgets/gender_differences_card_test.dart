import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/gender_differences_card.dart';
import 'package:pokevault/widgets/universal_poke_image.dart';
import 'package:pokevault/i18n/strings.g.dart';

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
    if (find.byType(Card).evaluate().isNotEmpty) {
      break;
    }
  }
}

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

  Widget buildTestWidget({
    required Pokemon pokemon,
    bool wantShiny = false,
    String language = 'de',
  }) {
    LocaleSettings.setLocale(language == 'de' ? AppLocale.de : AppLocale.en);
    final entry = DexDisplayEntry(
      pokemon: pokemon,
      uniqueId: '${pokemon.id}',
      displaySuffix: '',
      imageUrl: 'https://example.com/${pokemon.id}.png',
    );

    final settingsProvider = FakeSettingsProvider(currentLanguage: language);

    return TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
            child: SingleChildScrollView(
              child: GenderDifferencesCard(
                entry: entry,
                wantShiny: wantShiny,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('GenderDifferencesCard Widget Tests (TDD)', () {
    testWidgets('Rendert SizedBox.shrink wenn hasGenderDifferences false ist', (tester) async {
      final noDiffPokemon = Pokemon(
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

      await tester.pumpWidget(buildTestWidget(pokemon: noDiffPokemon));
      await pumpAsyncDB(tester);

      expect(find.byType(Card), findsNothing);
      expect(find.text('Geschlechtsunterschiede'), findsNothing);
      expect(find.text('Gender Differences'), findsNothing);
    });

    testWidgets('Rendert einklappbare Karte (ExpansionTile) mit Männlich/Weiblich nach Aufklappen', (tester) async {
      LocaleSettings.setLocale(AppLocale.de);
      final diffPokemon = Pokemon(
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

      await tester.pumpWidget(buildTestWidget(pokemon: diffPokemon, language: 'de'));
      await pumpAsyncDB(tester);

      expect(find.byType(Card), findsWidgets);
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('Geschlechtsunterschiede'), findsOneWidget);

      // Vor dem Aufklappen sind die Sprites/Details eingeklappt
      expect(find.text('Männlich (♂)'), findsNothing);
      expect(find.text('Weiblich (♀)'), findsNothing);

      // Aufklappen durch Antippen der ExpansionTile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump(const Duration(milliseconds: 300));

      // Nach dem Aufklappen sichtbar
      expect(find.text('Männlich (♂)'), findsOneWidget);
      expect(find.text('Weiblich (♀)'), findsOneWidget);
      expect(find.textContaining('Samen'), findsOneWidget);

      // Zuklappen durch erneutes Antippen
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Männlich (♂)'), findsNothing);
      expect(find.text('Weiblich (♀)'), findsNothing);
    });

    testWidgets('Zeigt englischen Text wenn Sprache auf Englisch gesetzt und aufgeklappt ist', (tester) async {
      LocaleSettings.setLocale(AppLocale.en);
      final diffPokemon = Pokemon(
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

      await tester.pumpWidget(buildTestWidget(pokemon: diffPokemon, language: 'en'));
      await pumpAsyncDB(tester);

      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('Gender Differences'), findsOneWidget);

      // Aufklappen
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Male (♂)'), findsOneWidget);
      expect(find.text('Female (♀)'), findsOneWidget);
      expect(find.textContaining('flower'), findsOneWidget);
      LocaleSettings.setLocale(AppLocale.de);
    });

    testWidgets('Adversarial Boundary Test: Bildschirmgröße 320x480 ohne RenderFlex Overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final diffPokemon = Pokemon(
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
      );

      await tester.pumpWidget(buildTestWidget(pokemon: diffPokemon));
      await pumpAsyncDB(tester);

      expect(find.text('Geschlechtsunterschiede'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UniversalPokeImage für Männlich und Weiblich besitzen korrekte Fallback-URLs', (tester) async {
      final diffPokemon = Pokemon(
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
      );

      await tester.pumpWidget(buildTestWidget(pokemon: diffPokemon, wantShiny: true));
      await pumpAsyncDB(tester);

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump(const Duration(milliseconds: 300));

      final imageWidgets = tester.widgetList<UniversalPokeImage>(find.byType(UniversalPokeImage)).toList();
      expect(imageWidgets.length, 2);
      expect(imageWidgets[0].fallbackUrl, contains('sprites/pokemon/shiny/25.png'));
      expect(imageWidgets[1].fallbackUrl, contains('sprites/pokemon/shiny/female/25.png'));
    });
  });
}

