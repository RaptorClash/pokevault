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
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/i18n/strings.g.dart';

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

  final testEntry = DexDisplayEntry(
    pokemon: pikachu,
    uniqueId: '25',
    displaySuffix: '',
    imageUrl: 'https://example.com/pika.png',
  );

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
    LocaleSettings.setLocale(AppLocale.de);
  });

  setUp(() async {
    LocaleSettings.setLocale(AppLocale.de);
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
    prefs = await SharedPreferences.getInstance();
    tutorialProvider = TutorialProvider(prefs);

    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();

    when(() => mockDexProvider.userDexes).thenReturn([UserDex.fallback('dex_1')]);
    when(() => mockDexProvider.allPokemon).thenReturn([pikachu]);
    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
  });

  Widget buildTestWidget() {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
        ],
        child: MaterialApp(
          home: PokemonInfoScreen(
            entries: [testEntry],
            initialIndex: 0,
            dexId: 'dex_1',
          ),
        ),
      ),
    );
  }

  testWidgets('PokemonInfoScreen tutorial includes v1.6 steps and marks gender_differences and special_obtainable as seen', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    expect(tutorialProvider.hasSeenFeature('pokemon_details'), isFalse);
    expect(tutorialProvider.hasSeenFeature('gender_differences'), isFalse);
    expect(tutorialProvider.hasSeenFeature('special_obtainable'), isFalse);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TutorialOverlay), findsOneWidget);

    final tutorialOverlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
    final stepTitles = tutorialOverlay.feature.steps.map((s) => s.titleKey).toList();
    expect(stepTitles, contains('tutorial_info_gender_title'));
    expect(stepTitles, contains('tutorial_info_obtainable_title'));
    expect(stepTitles, contains('tutorial_info_direct_hunt_title'));

    // Trigger onFinish
    tutorialOverlay.onFinish();

    // Verify all 3 keys are explicitly persisted as seen in SharedPreferences
    expect(prefs.getBool('pokemon_details'), isTrue);
    expect(prefs.getBool('gender_differences'), isTrue);
    expect(prefs.getBool('special_obtainable'), isTrue);
  });
}
