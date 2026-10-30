import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/pokemon_info/pokemon_info_screen.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}

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
  int get contentLength => 0;
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
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;
  late SharedPreferences prefs;
  late TutorialProvider tutorialProvider;

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
    forms: [],
  );

  final pikachuEntry = DexDisplayEntry(
    pokemon: pikachu,
    uniqueId: '25',
    displaySuffix: '',
    imageUrl: 'https://example.com/pikachu.png',
  );

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
    LocaleSettings.setLocale(AppLocale.de);
    registerFallbackValue(UserDex.fallback('fallback_dex'));
  });

  setUp(() async {
    Translator.currentLanguage = 'de';
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
    prefs = await SharedPreferences.getInstance();
    tutorialProvider = TutorialProvider(prefs);

    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();

    when(() => mockDexProvider.userDexes).thenReturn([UserDex.fallback('dex_1')]);
    when(() => mockDexProvider.allPokemon).thenReturn([pikachu]);
    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
  });

  test('Translations exist for tutorial_info_language_title and tutorial_info_language_text in German and English', () {
    // German
    Translator.currentLanguage = 'de';
    final deTitle = Translator.get('tutorial_info_language_title');
    final deText = Translator.get('tutorial_info_language_text');
    expect(deTitle, isNot(equals('tutorial_info_language_title')));
    expect(deTitle.isNotEmpty, isTrue);
    expect(deText, isNot(equals('tutorial_info_language_text')));
    expect(deText.isNotEmpty, isTrue);

    // English
    Translator.currentLanguage = 'en';
    final enTitle = Translator.get('tutorial_info_language_title');
    final enText = Translator.get('tutorial_info_language_text');
    expect(enTitle, isNot(equals('tutorial_info_language_title')));
    expect(enTitle.isNotEmpty, isTrue);
    expect(enText, isNot(equals('tutorial_info_language_text')));
    expect(enText.isNotEmpty, isTrue);
  });

  testWidgets('PokemonInfoScreen tutorial includes translated language step without raw keys', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: MaterialApp(
            home: PokemonInfoScreen(
              entries: [pikachuEntry],
              initialIndex: 0,
              dexId: 'dex_1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TutorialOverlay), findsOneWidget);
    final tutorialOverlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
    final steps = tutorialOverlay.feature.steps;

    final langStep = steps.firstWhere((s) => s.titleKey == 'tutorial_info_language_title');
    expect(langStep.textKey, equals('tutorial_info_language_text'));
  });
}
