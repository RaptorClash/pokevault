import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/providers/theme_provider.dart';
import 'package:pokevault/screens/dex/dex_screen.dart';
import 'package:pokevault/screens/settings/controls_guide_screen.dart';
import 'package:pokevault/screens/settings/settings_screen.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}
class MockShinyHuntProvider extends Mock implements ShinyHuntProvider {}
class MockThemeProvider extends Mock implements ThemeProvider {}

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
  late MockShinyHuntProvider mockShinyHuntProvider;
  late MockThemeProvider mockThemeProvider;
  late SharedPreferences prefs;
  late TutorialProvider tutorialProvider;

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
    forms: [],
  );

  final gengar = Pokemon(
    id: 94,
    nameDe: 'Gengar',
    nameEn: 'Gengar',
    hasGenderDifferences: false,
    genderRate: 4,
    captureRate: 45,
    evolutionChainId: 40,
    eggGroups: ['Amorphous'],
    weight: 40.5,
    speed: 110,
    forms: [],
  );

  late Directory tempDir;

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('pokevault_dex_tutorial_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
    await DatabaseService.instance.appDatabase;
    await DatabaseService.instance.userDatabase;
    LocaleSettings.setLocale(AppLocale.de);
    registerFallbackValue(UserDex.fallback('fallback_dex'));
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    Translator.currentLanguage = 'de';
    PackageInfo.setMockInitialValues(
      appName: 'Pokevault',
      packageName: 'com.example.pokevault',
      version: '1.5.0',
      buildNumber: '6',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
    prefs = await SharedPreferences.getInstance();
    tutorialProvider = TutorialProvider(prefs);

    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockShinyHuntProvider = MockShinyHuntProvider();
    mockThemeProvider = MockThemeProvider();

    when(() => mockDexProvider.userDexes).thenReturn([UserDex.fallback('dex_1')]);
    when(() => mockDexProvider.allPokemon).thenReturn([bulbasaur, gengar]);
    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    when(() => mockSettingsProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockSettingsProvider.googleClientId).thenReturn('');
    when(() => mockSettingsProvider.googleClientSecret).thenReturn('');
    when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
    when(() => mockShinyHuntProvider.activeHunts).thenReturn([]);
    when(() => mockShinyHuntProvider.pausedHunts).thenReturn([]);
    when(() => mockShinyHuntProvider.completedHunts).thenReturn([]);
    when(() => mockShinyHuntProvider.isLoading).thenReturn(false);
    when(() => mockThemeProvider.darkBackgroundColor).thenReturn(const Color(0xFF121212));
    when(() => mockThemeProvider.lightBackgroundColor).thenReturn(const Color(0xFFF7F7F8));
    when(() => mockThemeProvider.darkPrimaryColor).thenReturn(const Color(0xFF9575CD));
    when(() => mockThemeProvider.lightPrimaryColor).thenReturn(const Color(0xFFE53935));
    when(() => mockThemeProvider.customColors).thenReturn([const Color(0xFF336699)]);
  });

  Future<void> pumpAndLoad(WidgetTester tester, {required UserDex dex}) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: MaterialApp(
            home: DexScreen(
              initialDex: dex,
              pokemonList: [bulbasaur, gengar],
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 15; i++) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
    }
  }

  group('Issue 1: Search & Target Pokémon in Dex', () {
    test('Translations refer to Gengar instead of Pikachu in search & ignore steps', () {
      // German
      Translator.currentLanguage = 'de';
      final deSearch = Translator.get('tutorial_dex_search_text');
      expect(deSearch, contains('Gengar'));
      expect(deSearch, isNot(contains('Pikachu')));

      final deIgnoreConfirm = Translator.get('tutorial_info_ignore_confirm_text');
      expect(deIgnoreConfirm, contains('Gengar'));
      expect(deIgnoreConfirm, isNot(contains('Pikachu')));

      final deMenuIgnored = Translator.get('tutorial_dex_menu_ignored_text');
      expect(deMenuIgnored, contains('Gengar'));
      expect(deMenuIgnored, isNot(contains('Pikachu')));

      final deRestore = Translator.get('tutorial_ignored_restore_text');
      expect(deRestore, contains('Gengar'));
      expect(deRestore, isNot(contains('Pikachu')));

      // English
      Translator.currentLanguage = 'en';
      final enSearch = Translator.get('tutorial_dex_search_text');
      expect(enSearch, contains('Gengar'));
      expect(enSearch, isNot(contains('Pikachu')));

      final enIgnoreConfirm = Translator.get('tutorial_info_ignore_confirm_text');
      expect(enIgnoreConfirm, contains('Gengar'));
      expect(enIgnoreConfirm, isNot(contains('Pikachu')));

      final enMenuIgnored = Translator.get('tutorial_dex_menu_ignored_text');
      expect(enMenuIgnored, contains('Gengar'));
      expect(enMenuIgnored, isNot(contains('Pikachu')));

      final enRestore = Translator.get('tutorial_ignored_restore_text');
      expect(enRestore, contains('Gengar'));
      expect(enRestore, isNot(contains('Pikachu')));
    });

    testWidgets('DexScreen search step types Gengar into search bar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testDex = UserDex.fallback('dex_1');
      when(() => mockDexProvider.userDexes).thenReturn([testDex]);
      when(() => mockDexProvider.allAvailableDexes).thenReturn({'kanto': [1, 94]});

      await pumpAndLoad(tester, dex: testDex);

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      final steps = overlay.feature.steps;
      final searchStep = steps.firstWhere((s) => s.titleKey == 'tutorial_dex_search_title');
      expect(searchStep.onTargetTap, isNotNull);

      // Trigger search step
      searchStep.onTargetTap!();
      await tester.pump();

      // Verify search input has 'Gengar'
      final searchFinder = find.byType(TextField);
      expect(searchFinder, findsOneWidget);
      final textField = tester.widget<TextField>(searchFinder);
      expect(textField.controller?.text, equals('Gengar'));
      await tester.pump(const Duration(seconds: 11));
    });
  });

  group('Issue 2: Ignore / Remove seamless update in DexScreen', () {
    testWidgets('Immediately shows ignored_pokemon step upon returning with ignored Pokémon', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-condition: user already completed dex_screen & pokemon_details, and ignored Gengar
      await tutorialProvider.markFeatureAsSeen('dex_screen');
      await tutorialProvider.markFeatureAsSeen('pokemon_details');
      expect(tutorialProvider.hasSeenFeature('ignored_pokemon'), isFalse);

      final testDex = UserDex.fallback('dex_1');
      testDex.ignoredIds = ['94'];
      when(() => mockDexProvider.userDexes).thenReturn([testDex]);
      when(() => mockDexProvider.allAvailableDexes).thenReturn({'kanto': [1, 94]});

      await pumpAndLoad(tester, dex: testDex);

      // TutorialOverlay should appear immediately for ignored_pokemon
      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('ignored_pokemon'));
      expect(overlay.feature.steps.first.titleKey, equals('tutorial_dex_menu_ignored_title'));
    });
  });

  group('Issue 3: Chapter completion keys satisfaction', () {
    test('dex_appbar_tools marks chapters 4, 5, 6, 8, 9, 10 required keys', () async {
      // Initially v1.6 chapters are incomplete
      expect(tutorialProvider.isChapterCompleted('module_box_management'), isFalse);
      expect(tutorialProvider.isChapterCompleted('module_shiny_hunt'), isFalse);
      expect(tutorialProvider.isChapterCompleted('module_stats_share'), isFalse);
      expect(tutorialProvider.isChapterCompleted('module_route_tracker'), isFalse);
      expect(tutorialProvider.isChapterCompleted('module_controls'), isFalse);
      expect(tutorialProvider.isChapterCompleted('module_backup_sync'), isFalse);

      // Mark the keys that dex_appbar_tools marks upon completion
      await tutorialProvider.markFeatureAsSeen('dex_appbar_tools');
      await tutorialProvider.markFeatureAsSeen('ignored_pokemon');
      await tutorialProvider.markFeatureAsSeen('dex_statistics');
      await tutorialProvider.markFeatureAsSeen('completion_card');
      await tutorialProvider.markFeatureAsSeen('box_management');
      await tutorialProvider.markFeatureAsSeen('box_drag_shift');
      await tutorialProvider.markFeatureAsSeen('route_tracker');
      await tutorialProvider.markFeatureAsSeen('shiny_hunt_hub');
      await tutorialProvider.markFeatureAsSeen('shiny_hunt_counter');
      await tutorialProvider.markFeatureAsSeen('controls_guide');
      await tutorialProvider.markFeatureAsSeen('cloud_sync');
      await tutorialProvider.markFeatureAsSeen('data_backup');
      await tutorialProvider.completeV16Tutorial();

      // Now all chapters must be completed!
      expect(tutorialProvider.isChapterCompleted('module_box_management'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_shiny_hunt'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_stats_share'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_route_tracker'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_controls'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_backup_sync'), isTrue);
      expect(tutorialProvider.completedTutorialVersion, equals(2));
    });

    testWidgets('ControlsGuideScreen marks controls_guide seen in initState', (tester) async {
      expect(tutorialProvider.hasSeenFeature('controls_guide'), isFalse);
      expect(tutorialProvider.isChapterCompleted('module_controls'), isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: const MaterialApp(
            home: ControlsGuideScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(tutorialProvider.hasSeenFeature('controls_guide'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_controls'), isTrue);
    });

    test('startV16DeltaTour resets dex_appbar_tools along with other v16 keys', () async {
      await tutorialProvider.markFeatureAsSeen('dex_appbar_tools');
      expect(tutorialProvider.hasSeenFeature('dex_appbar_tools'), isTrue);

      await tutorialProvider.startV16DeltaTour();
      expect(tutorialProvider.hasSeenFeature('dex_appbar_tools'), isFalse);
    });

    testWidgets('DexScreen dex_appbar_tools onFinish marks all required keys for chapters 4, 5, 6, 8', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tutorialProvider.markFeatureAsSeen('dex_screen');
      await tutorialProvider.markFeatureAsSeen('pokemon_details');
      await tutorialProvider.markFeatureAsSeen('ignored_pokemon');
      expect(tutorialProvider.hasSeenFeature('dex_appbar_tools'), isFalse);

      final testDex = UserDex.fallback('dex_1');
      when(() => mockDexProvider.userDexes).thenReturn([testDex]);
      when(() => mockDexProvider.allAvailableDexes).thenReturn({'kanto': [1, 94]});

      await pumpAndLoad(tester, dex: testDex);

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('dex_appbar_tools'));

      // Trigger onFinish
      overlay.onFinish();
      await tester.pump();

      expect(tutorialProvider.hasSeenFeature('dex_statistics'), isTrue);
      expect(tutorialProvider.hasSeenFeature('completion_card'), isTrue);
      expect(tutorialProvider.hasSeenFeature('box_management'), isTrue);
      expect(tutorialProvider.hasSeenFeature('box_drag_shift'), isTrue);
      expect(tutorialProvider.hasSeenFeature('route_tracker'), isTrue);
      expect(tutorialProvider.hasSeenFeature('shiny_hunt_hub'), isTrue);
      expect(tutorialProvider.hasSeenFeature('shiny_hunt_counter'), isTrue);
      expect(tutorialProvider.hasSeenFeature('controls_guide'), isTrue);
      expect(tutorialProvider.hasSeenFeature('cloud_sync'), isTrue);
      expect(tutorialProvider.hasSeenFeature('data_backup'), isTrue);

      expect(tutorialProvider.isChapterCompleted('module_box_management'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_shiny_hunt'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_stats_share'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_route_tracker'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_controls'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_backup_sync'), isTrue);
      expect(tutorialProvider.completedTutorialVersion, equals(2));
    });

    testWidgets('SettingsScreen tutorial onFinish marks cloud_sync and data_backup for Chapter 10', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      expect(tutorialProvider.hasSeenFeature('cloud_sync'), isFalse);
      expect(tutorialProvider.hasSeenFeature('data_backup'), isFalse);
      expect(tutorialProvider.isChapterCompleted('module_backup_sync'), isFalse);

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
              ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
              ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
              ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            ],
            child: const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TutorialOverlay), findsOneWidget);
      final overlay = tester.widget<TutorialOverlay>(find.byType(TutorialOverlay));
      expect(overlay.feature.id, equals('settings_screen'));

      overlay.onFinish();
      await tester.pump();

      expect(tutorialProvider.hasSeenFeature('cloud_sync'), isTrue);
      expect(tutorialProvider.hasSeenFeature('data_backup'), isTrue);
      expect(tutorialProvider.isChapterCompleted('module_backup_sync'), isTrue);
    });
  });
}
