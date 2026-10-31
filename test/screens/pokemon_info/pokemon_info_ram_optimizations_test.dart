import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/screens/pokemon_info/widgets/encounters_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/matching_balls_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/ribbons_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/marks_widget.dart';
import 'package:pokevault/screens/pokemon_info/utils/pokemon_info_keys.dart';
import 'package:pokevault/widgets/universal_poke_image.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../../e2e/helpers/e2e_test_helper.dart';
import 'dart:io';

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

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('pokevault_ram_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
    SharedPreferences.setMockInitialValues({'app_db_version': 21});

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    await DatabaseService.instance.appDatabase;
  });

  tearDownAll(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() {
    LocaleSettings.setLocale(AppLocale.de);
  });

  final testPokemon = createTestPokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur');
  final testEntry = createTestEntry(pokemon: testPokemon, uniqueId: '1');

  group('Pokemon Info RAM Optimization & Lazy Loading Tests', () {
    testWidgets('EncountersWidget does not show encounter list when collapsed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EncountersWidget(
              pokemonId: 1,
              encountersKey: GlobalKey(),
            ),
          ),
        ),
      );

      // Verify title is rendered
      expect(find.byType(EncountersWidget), findsOneWidget);

      // Verify inner expansion content is NOT rendered while collapsed
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('MatchingBallsWidget does not load ball details when collapsed', (tester) async {
      final mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.ballUrls).thenReturn({});

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: Scaffold(
              body: MatchingBallsWidget(
                entry: testEntry,
                matchingBallsKey: GlobalKey(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MatchingBallsWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    test('PokemonInfoKeys.prune releases keys outside of activeIds window', () {
      final keys = PokemonInfoKeys();

      // Allocate keys for IDs 1..10
      for (int i = 1; i <= 10; i++) {
        keys.get(keys.shinyToggle, '$i');
        keys.get(keys.basicInfo, '$i');
        keys.get(keys.breeding, '$i');
      }

      expect(keys.shinyToggle.length, equals(10));
      expect(keys.basicInfo.length, equals(10));

      // Prune to only keep IDs 4, 5, 6
      keys.prune({'4', '5', '6'});

      expect(keys.shinyToggle.length, equals(3));
      expect(keys.basicInfo.length, equals(3));
      expect(keys.shinyToggle.containsKey('1'), isFalse);
      expect(keys.shinyToggle.containsKey('5'), isTrue);
      expect(keys.shinyToggle.containsKey('10'), isFalse);
    });

    testWidgets('UniversalPokeImage configures memCache bounds for main and fallback image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversalPokeImage(
              imageUrl: 'https://example.com/invalid.png',
              fallbackUrl: 'https://example.com/fallback.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.memCacheWidth, isNotNull);
      expect(cachedImage.memCacheHeight, isNotNull);
    });

    testWidgets('RibbonsWidget uses static placeholder in grid items to eliminate 80 ticking animations', (tester) async {
      final mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn([UserDex.fallback('test_dex')]);

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RibbonsWidget(
                  entry: testEntry,
                  dexId: 'test_dex',
                  ribbonsKey: GlobalKey(),
                ),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(ExpansionTile), findsOneWidget);

      // Expand ribbons card
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Ensure no animated CircularProgressIndicators are spawned in the ribbon items
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'Ribbon items must use a static placeholder to prevent 80 animated tickers from lagging the expand animation');
    });

    testWidgets('MarksWidget uses static placeholder in grid items to eliminate animated tickers', (tester) async {
      final mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn([UserDex.fallback('test_dex')]);

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MarksWidget(
                  entry: testEntry,
                  dexId: 'test_dex',
                  marksKey: GlobalKey(),
                ),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(ExpansionTile), findsOneWidget);

      // Expand marks card
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Ensure no animated CircularProgressIndicators are spawned in the mark items
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'Mark items must use a static placeholder to prevent animated tickers from lagging the expand animation');
    });
  });
}
