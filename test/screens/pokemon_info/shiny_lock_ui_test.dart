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
import 'package:pokevault/services/database_service.dart';
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;

  late Pokemon poliwhirl;
  late DexDisplayEntry tradePoliwhirlEntry;
  late Pokemon pikachu;
  late DexDisplayEntry regularPikachuEntry;
  late DexDisplayEntry nZoruaEntry;
  late DexDisplayEntry unownNEntry;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = Directory.systemTemp.createTempSync('pokevault_shiny_lock_ui_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    SharedPreferences.setMockInitialValues({'app_db_version': 28});
    await DatabaseService.instance.appDatabase;
  });

  tearDownAll(() async {
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

    poliwhirl = Pokemon(
      id: 61,
      nameDe: 'Quaputzi',
      nameEn: 'Poliwhirl',
      hasGenderDifferences: false,
      genderRate: 4,
      captureRate: 120,
      evolutionChainId: 26,
      eggGroups: ['water1'],
      weight: 20.0,
      speed: 90,
      forms: [
        PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 1,
          imageId: 61,
          types: ['water'],
          exclusiveRegions: [],
        ),
      ],
    );

    tradePoliwhirlEntry = DexDisplayEntry(
      pokemon: poliwhirl,
      uniqueId: '61_special_128_trade_alola_normal',
      displaySuffix: ' (Tausch - Pokémon Sun and Moon)',
      imageUrl: 'https://img/61.png',
      form: poliwhirl.forms.first,
    );

    pikachu = Pokemon(
      id: 25,
      nameDe: 'Pikachu',
      nameEn: 'Pikachu',
      hasGenderDifferences: true,
      genderRate: 4,
      captureRate: 190,
      evolutionChainId: 10,
      eggGroups: [],
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

    regularPikachuEntry = DexDisplayEntry(
      pokemon: pikachu,
      uniqueId: '25_normal',
      displaySuffix: '',
      imageUrl: 'https://img/25.png',
      form: pikachu.forms.first,
    );

    final zorua = Pokemon(
      id: 570,
      nameDe: 'Zorua',
      nameEn: 'Zorua',
      hasGenderDifferences: false,
      genderRate: 1,
      captureRate: 75,
      evolutionChainId: 292,
      eggGroups: ['field'],
      weight: 12.5,
      speed: 65,
      forms: [
        PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 5,
          imageId: 570,
          types: ['dark'],
          exclusiveRegions: [],
        ),
      ],
    );

    nZoruaEntry = DexDisplayEntry(
      pokemon: zorua,
      uniqueId: '570_special_336_n_unova_normal',
      displaySuffix: " (N's Pokémon)",
      imageUrl: 'https://img/570.png',
      form: zorua.forms.first,
    );

    final unown = Pokemon(
      id: 201,
      nameDe: 'Icognito',
      nameEn: 'Unown',
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: 225,
      evolutionChainId: 99,
      eggGroups: ['no-eggs'],
      weight: 5.0,
      speed: 48,
      forms: [
        PokemonForm(
          name: 'n',
          formType: 'unown',
          minGen: 2,
          imageId: 201,
          types: ['psychic'],
          exclusiveRegions: [],
        ),
      ],
    );

    unownNEntry = DexDisplayEntry(
      pokemon: unown,
      uniqueId: '201_n',
      displaySuffix: ' (N)',
      imageUrl: 'https://img/201.png',
      form: unown.forms.first,
    );

    final testDex = UserDex(
      id: 'test_dex_1',
      title: 'Alola Dex',
      region: 'alola_regional',
      includeGenders: false,
      includeRegional: true,
      includeMega: false,
      includeGMax: false,
      includeOther: true,
      isShinyDex: false,
    );

    when(() => mockDexProvider.userDexes).thenReturn([testDex]);
    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
  });

  Widget buildWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
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
    throw Exception('Timed out waiting for ShinyGuideWidget to load');
  }

  group('ShinyLock UI Tests (TDD)', () {
    testWidgets('PokemonStatusTogglesWidget locks shiny toggle and displays lock badge for shiny locked trade Poliwhirl', (tester) async {
      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      await tester.pumpWidget(
        buildWidget(
          PokemonStatusTogglesWidget(
            dexId: 'test_dex_1',
            entry: tradePoliwhirlEntry,
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

      // Check for lock icon and Shiny-Lock badge
      expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
      expect(find.text(t.shiny_lock_badge), findsOneWidget);

      // Verify that the shiny switch tile is disabled (onChanged is null)
      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.onChanged, isNull);
      expect(switchWidget.value, isFalse);

      // Verify explanation reason in subtitle
      expect(find.textContaining('In-Game Tausch'), findsOneWidget);
    });

    testWidgets('PokemonStatusTogglesWidget allows toggling shiny switch for regular Pikachu', (tester) async {
      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      when(() => mockDexProvider.toggleShiny('test_dex_1', '25_normal', targetState: any(named: 'targetState')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildWidget(
          PokemonStatusTogglesWidget(
            dexId: 'test_dex_1',
            entry: regularPikachuEntry,
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

      expect(find.text(t.shiny_lock_badge), findsNothing);

      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.onChanged, isNotNull);

      // Tap the switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.toggleShiny('test_dex_1', '25_normal', targetState: true)).called(1);
    });

    testWidgets('ShinyGuideWidget displays Shiny-Lock warning banner and hides Gen 1-6 for Gen 7 in-game trade Poliwhirl', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildWidget(
          ShinyGuideWidget(
            entry: tradePoliwhirlEntry,
            dexId: 'test_dex_1',
          ),
        ),
      );
      await waitForLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Expand main shiny guide tile
      await tester.tap(find.text(t.shiny_guide_title));
      await tester.pump(const Duration(milliseconds: 300));

      // Check that Shiny-Lock banner is displayed
      expect(find.text(t.shiny_lock_banner), findsOneWidget);
      expect(find.textContaining('In-Game Tausch'), findsOneWidget);

      // Check that Gen 1, 2, 3, 4, 5, 6 are NOT shown (originGen is 7)
      expect(find.text(t.shiny_guide_gen1), findsNothing);
      expect(find.text(t.shiny_guide_gen2), findsNothing);
      expect(find.text(t.shiny_guide_gen3), findsNothing);
      expect(find.text(t.shiny_guide_gen4), findsNothing);
      expect(find.text(t.shiny_guide_gen5), findsNothing);
      expect(find.text(t.shiny_guide_gen6), findsNothing);

      // Check that Gen 7 is shown
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.text(t.shiny_guide_gen7), findsOneWidget);

      // Let any pending background db queries settle
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets("PokemonStatusTogglesWidget locks shiny toggle and displays lock badge for N's Pokémon Zorua", (tester) async {
      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      await tester.pumpWidget(
        buildWidget(
          PokemonStatusTogglesWidget(
            dexId: 'test_dex_1',
            entry: nZoruaEntry,
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

      // Check for lock icon and Shiny-Lock badge
      expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
      expect(find.text(t.shiny_lock_badge), findsOneWidget);

      // Verify that the shiny switch tile is disabled (onChanged is null)
      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.onChanged, isNull);
      expect(switchWidget.value, isFalse);

      // Verify explanation reason in subtitle mentions N's Pokémon and Schwarz 2 / Weiß 2
      expect(find.textContaining("N's Pokémon"), findsOneWidget);
    });

    testWidgets("ShinyGuideWidget displays Shiny-Lock warning banner and hides Gen 1-4 for N's Pokémon Zorua", (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildWidget(
          ShinyGuideWidget(
            entry: nZoruaEntry,
            dexId: 'test_dex_1',
          ),
        ),
      );
      await waitForLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Expand main shiny guide tile
      await tester.tap(find.text(t.shiny_guide_title));
      await tester.pump(const Duration(milliseconds: 300));

      // Check that Shiny-Lock banner is displayed
      expect(find.text(t.shiny_lock_banner), findsOneWidget);
      expect(find.textContaining("N's Pokémon"), findsOneWidget);

      // Check that Gen 1, 2, 3, 4 are NOT shown (originGen is 5 for Unova)
      expect(find.text(t.shiny_guide_gen1), findsNothing);
      expect(find.text(t.shiny_guide_gen2), findsNothing);
      expect(find.text(t.shiny_guide_gen3), findsNothing);
      expect(find.text(t.shiny_guide_gen4), findsNothing);

      // Check that Gen 6, 7, 8, 9 are also NOT shown (N's Pokémon exists ONLY in Gen 5 B2W2)
      expect(find.text(t.shiny_guide_gen6), findsNothing);
      expect(find.text(t.shiny_guide_gen7), findsNothing);
      expect(find.text(t.shiny_guide_gen8), findsNothing);
      expect(find.text(t.shiny_guide_gen9), findsNothing);

      // Check that Gen 5 is shown
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.text(t.shiny_guide_gen5), findsOneWidget);

      // Let any pending background db queries settle
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('PokemonStatusTogglesWidget allows toggling shiny switch for Unown Form N without shiny lock', (tester) async {
      final caughtKey = GlobalKey();
      final shinyKey = GlobalKey();
      final alphaKey = GlobalKey();

      when(() => mockDexProvider.toggleShiny('test_dex_1', '201_n', targetState: any(named: 'targetState')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildWidget(
          PokemonStatusTogglesWidget(
            dexId: 'test_dex_1',
            entry: unownNEntry,
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

      expect(find.text(t.shiny_lock_badge), findsNothing);

      final switchFinder = find.descendant(
        of: find.byKey(shinyKey),
        matching: find.byType(SwitchListTile),
      );
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.onChanged, isNotNull);

      // Tap the switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.toggleShiny('test_dex_1', '201_n', targetState: true)).called(1);
    });
  });
}
