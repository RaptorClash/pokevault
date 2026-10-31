import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_info_widgets.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guide_widget.dart';
import 'package:pokevault/screens/dex/dex_list_view.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/i18n/strings.g.dart';

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

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static const List<int> _kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ];

  @override
  int get statusCode => HttpStatus.ok;

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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;

  late Pokemon pikachu;
  late Pokemon eevee;

  late DexDisplayEntry cosplayPikachuEntry;
  late DexDisplayEntry starterPikachuEntry;
  late DexDisplayEntry starterEeveeEntry;
  late DexDisplayEntry normalPikachuEntry;

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = Directory.systemTemp.createTempSync('cosplay_starter_ui_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    SharedPreferences.setMockInitialValues({'app_db_version': 28});
    await DatabaseService.instance.appDatabase;
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    try {
      final appDb = await DatabaseService.instance.appDatabase;
      await appDb.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() {
    LocaleSettings.setLocale(AppLocale.de);
    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();
    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');

    final normalPikaForm = PokemonForm(
      name: 'normal',
      formType: 'normal',
      minGen: 1,
      imageId: 25,
      types: ['electric'],
      exclusiveRegions: [],
    );
    final cosplayForm = PokemonForm(
      name: 'cosplay',
      formType: 'other',
      minGen: 6,
      imageId: 10080,
      types: ['electric'],
      exclusiveRegions: [],
    );
    final starterPikaForm = PokemonForm(
      name: 'starter',
      formType: 'other',
      minGen: 7,
      imageId: 10158,
      types: ['electric'],
      exclusiveRegions: [],
    );

    pikachu = Pokemon(
      id: 25,
      nameDe: 'Pikachu',
      nameEn: 'Pikachu',
      hasGenderDifferences: true,
      genderRate: 4,
      captureRate: 190,
      evolutionChainId: 10,
      eggGroups: ['field', 'fairy'],
      weight: 6.0,
      speed: 90,
      forms: [normalPikaForm, cosplayForm, starterPikaForm],
    );

    final normalEeveeForm = PokemonForm(
      name: 'normal',
      formType: 'normal',
      minGen: 1,
      imageId: 133,
      types: ['normal'],
      exclusiveRegions: [],
    );
    final starterEeveeForm = PokemonForm(
      name: 'starter',
      formType: 'other',
      minGen: 7,
      imageId: 10159,
      types: ['normal'],
      exclusiveRegions: [],
    );

    eevee = Pokemon(
      id: 133,
      nameDe: 'Evoli',
      nameEn: 'Eevee',
      hasGenderDifferences: true,
      genderRate: 1,
      captureRate: 45,
      evolutionChainId: 67,
      eggGroups: ['field'],
      weight: 6.5,
      speed: 55,
      forms: [normalEeveeForm, starterEeveeForm],
    );

    cosplayPikachuEntry = DexDisplayEntry(
      pokemon: pikachu,
      uniqueId: '25_cosplay',
      displaySuffix: ' (Cosplay)',
      imageUrl: 'https://example.com/25_cosplay.png',
      form: cosplayForm,
    );

    starterPikachuEntry = DexDisplayEntry(
      pokemon: pikachu,
      uniqueId: '25_starter',
      displaySuffix: ' (Starter)',
      imageUrl: 'https://example.com/25_starter.png',
      form: starterPikaForm,
    );

    starterEeveeEntry = DexDisplayEntry(
      pokemon: eevee,
      uniqueId: '133_starter',
      displaySuffix: ' (Starter)',
      imageUrl: 'https://example.com/133_starter.png',
      form: starterEeveeForm,
    );

    normalPikachuEntry = DexDisplayEntry(
      pokemon: pikachu,
      uniqueId: '25_normal',
      displaySuffix: '',
      imageUrl: 'https://example.com/25_normal.png',
      form: normalPikaForm,
    );
  });

  Widget buildTestApp(Widget child, {bool scrollable = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ),
    );
  }

  Future<void> waitForLoaded(WidgetTester tester) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        return;
      }
    }
  }

  group('PokemonStatusTogglesWidget UI for Cosplay & Starter Pokémon', () {
    testWidgets('Cosplay Pikachu has disabled shiny toggle and no alpha toggle', (tester) async {
      final dex = UserDex(
        id: 'dex_test',
        title: 'Test Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: false,
      );
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      await tester.pumpWidget(
        buildTestApp(
          PokemonStatusTogglesWidget(
            entry: cosplayPikachuEntry,
            dexId: dex.id,
            isCaught: false,
            isShiny: false,
            isAlpha: false,
            provider: mockDexProvider,
            caughtStatusKey: caughtKey,
            shinyStatusKey: shinyKey,
            alphaToggleKey: alphaKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.onChanged, isNull, reason: 'Shiny toggle must be disabled for Cosplay Pikachu');

      // Subtitle should show shiny lock explanation mentioning Cosplay
      expect(find.textContaining('Cosplay'), findsOneWidget);

      // Alpha toggle should NOT exist (SizedBox.shrink)
      final alphaCardFinder = find.descendant(
        of: find.byKey(alphaKey),
        matching: find.byType(Card),
      );
      expect(alphaCardFinder, findsNothing);
    });

    testWidgets('Starter Pikachu has disabled shiny toggle and no alpha toggle', (tester) async {
      final dex = UserDex(
        id: 'dex_test',
        title: 'Test Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: false,
      );
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      await tester.pumpWidget(
        buildTestApp(
          PokemonStatusTogglesWidget(
            entry: starterPikachuEntry,
            dexId: dex.id,
            isCaught: false,
            isShiny: false,
            isAlpha: false,
            provider: mockDexProvider,
            caughtStatusKey: caughtKey,
            shinyStatusKey: shinyKey,
            alphaToggleKey: alphaKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.onChanged, isNull, reason: 'Shiny toggle must be disabled for Starter Pikachu');

      expect(find.textContaining('Starter'), findsOneWidget);

      final alphaCardFinder = find.descendant(
        of: find.byKey(alphaKey),
        matching: find.byType(Card),
      );
      expect(alphaCardFinder, findsNothing);
    });

    testWidgets('Starter Eevee has disabled shiny toggle and no alpha toggle', (tester) async {
      final dex = UserDex(
        id: 'dex_test',
        title: 'Test Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: false,
      );
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      await tester.pumpWidget(
        buildTestApp(
          PokemonStatusTogglesWidget(
            entry: starterEeveeEntry,
            dexId: dex.id,
            isCaught: false,
            isShiny: false,
            isAlpha: false,
            provider: mockDexProvider,
            caughtStatusKey: caughtKey,
            shinyStatusKey: shinyKey,
            alphaToggleKey: alphaKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.onChanged, isNull, reason: 'Shiny toggle must be disabled for Starter Eevee');

      expect(find.textContaining('Starter'), findsOneWidget);

      final alphaCardFinder = find.descendant(
        of: find.byKey(alphaKey),
        matching: find.byType(Card),
      );
      expect(alphaCardFinder, findsNothing);
    });

    testWidgets('Normal Pikachu has enabled shiny toggle and alpha toggle', (tester) async {
      final dex = UserDex(
        id: 'dex_test',
        title: 'Test Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      await tester.pumpWidget(
        buildTestApp(
          PokemonStatusTogglesWidget(
            entry: normalPikachuEntry,
            dexId: dex.id,
            isCaught: false,
            isShiny: false,
            isAlpha: false,
            provider: mockDexProvider,
            caughtStatusKey: caughtKey,
            shinyStatusKey: shinyKey,
            alphaToggleKey: alphaKey,
          ),
          scrollable: true,
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.onChanged, isNotNull, reason: 'Shiny toggle must be enabled for regular Pikachu');

      expect(find.byKey(alphaKey), findsOneWidget, reason: 'Alpha toggle must be shown for regular Pikachu');
    });
  });

  group('ShinyGuideWidget UI for Cosplay & Starter Pokémon', () {
    testWidgets('ShinyGuideWidget renders shiny lock warning for Cosplay Pikachu', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          ShinyGuideWidget(
            entry: cosplayPikachuEntry,
            dexId: 'dex_test',
          ),
          scrollable: true,
        ),
      );
      await waitForLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Expand main shiny guide tile
      await tester.tap(find.text(t.shiny_guide_title));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(t.shiny_lock_banner), findsOneWidget);
      expect(find.textContaining('Cosplay'), findsOneWidget);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('ShinyGuideWidget renders shiny lock warning for Starter Pikachu and Starter Eevee', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          ShinyGuideWidget(
            entry: starterPikachuEntry,
            dexId: 'dex_test',
          ),
          scrollable: true,
        ),
      );
      await waitForLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(t.shiny_guide_title));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(t.shiny_lock_banner), findsOneWidget);
      expect(find.textContaining('Starter'), findsOneWidget);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(seconds: 15));

      await tester.pumpWidget(
        buildTestApp(
          ShinyGuideWidget(
            entry: starterEeveeEntry,
            dexId: 'dex_test',
          ),
          scrollable: true,
        ),
      );
      await waitForLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(t.shiny_guide_title));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(t.shiny_lock_banner), findsOneWidget);
      expect(find.textContaining('Starter'), findsOneWidget);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(seconds: 15));
    });
  });

  group('DexListView & DexBoxView Shiny Lock Badges for Cosplay & Starter Pokémon', () {
    testWidgets('DexListView shows red lock badge and blocks toggle in Shiny Dex for Cosplay Pikachu', (tester) async {
      final shinyDex = UserDex(
        id: 'shiny_dex_1',
        title: 'Shiny Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexListView(
            displayList: [cosplayPikachuEntry],
            liveDex: shinyDex,
            provider: mockDexProvider,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Red lock badge must be present
      final badgeFinder = find.byKey(Key('shiny_lock_badge_${cosplayPikachuEntry.uniqueId}'));
      expect(badgeFinder, findsOneWidget);

      // Tapping the item should NOT call togglePokemon in Shiny Dex
      await tester.tap(find.text('Pikachu (Cosplay)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')));
    });

    testWidgets('DexBoxView shows red lock badge and blocks toggle in Shiny Dex for Starter Pikachu & Eevee', (tester) async {
      final shinyDex = UserDex(
        id: 'shiny_dex_2',
        title: 'Shiny Box Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_starter', '133_starter'],
          ),
        ],
      );

      final boxData = BoxData(
        'Box 1',
        'national_overall',
        [starterPikachuEntry, starterEeveeEntry],
        6,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexBoxView(
            boxes: [boxData],
            liveDex: shinyDex,
            provider: mockDexProvider,
            pageController: PageController(),
            separateForms: false,
            highlightedIds: const {},
            isSearchActive: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final pikaBadge = find.byKey(Key('box_shiny_lock_badge_${starterPikachuEntry.uniqueId}'));
      final eeveeBadge = find.byKey(Key('box_shiny_lock_badge_${starterEeveeEntry.uniqueId}'));

      expect(pikaBadge, findsOneWidget);
      expect(eeveeBadge, findsOneWidget);

      // Tapping pika card in Shiny Dex should not call togglePokemon
      await tester.tap(pikaBadge);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')));
    });
  });
}
