import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guide_widget.dart';
import 'package:pokevault/l10n/app_translations.dart';
import '../../../e2e/helpers/e2e_test_helper.dart';

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

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = Directory.systemTemp.createTempSync('pokevault_shiny_widget_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
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

  late MockDexProvider mockDexProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    Translator.currentLanguage = 'de';
    mockDexProvider = MockDexProvider();
    when(() => mockDexProvider.allPokemon).thenReturn([
      createTestPokemon(id: 1, nameDe: 'Bisasam'),
      createTestPokemon(id: 25, nameDe: 'Pikachu'),
    ]);
  });

  Future<void> waitForLoaded(WidgetTester tester) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
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

  testWidgets('ShinyGuideWidget shows loading indicator then renders ExpansionTiles', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final entry = createTestEntry(
      pokemon: createTestPokemon(id: 1, nameDe: 'Bisasam'),
      uniqueId: '1',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<DexProvider>.value(
        value: mockDexProvider,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShinyGuideWidget(entry: entry, dexId: 'kanto_dex'),
            ),
          ),
        ),
      ),
    );

    // Initial pump shows CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await waitForLoaded(tester);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify main card and title are present
    expect(find.byType(Card), findsOneWidget);
    expect(find.text(Translator.get('shiny_guide_title')), findsOneWidget);

    // Expand the main shiny guide ExpansionTile
    await tester.tap(find.text(Translator.get('shiny_guide_title')));
    await tester.pump(const Duration(milliseconds: 300));

    // Gen 1 through 9.5 tiles should be visible for ID 1
    expect(find.text('Generation 1'), findsOneWidget);
    expect(find.text('Generation 2'), findsOneWidget);

    // Tap on Generation 1 tile to expand it
    await tester.ensureVisible(find.text('Generation 1'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Generation 1'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Gen 1 content rendered
    expect(find.textContaining('DV'), findsWidgets);

    // Let any pending background db queries settle
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('ShinyGuideWidget returns SizedBox.shrink for out of range Pokemon', (
    WidgetTester tester,
  ) async {
    final entry = createTestEntry(
      pokemon: createTestPokemon(id: 2000, nameDe: 'Unknown'),
      uniqueId: '2000',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<DexProvider>.value(
        value: mockDexProvider,
        child: MaterialApp(
          home: Scaffold(
            body: ShinyGuideWidget(entry: entry, dexId: 'test_dex'),
          ),
        ),
      ),
    );

    await waitForLoaded(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('ShinyGuideWidget expands Gen 2 and Gen 3 tiles', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final entry = createTestEntry(
      pokemon: createTestPokemon(id: 25, nameDe: 'Pikachu'),
      uniqueId: '25',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<DexProvider>.value(
        value: mockDexProvider,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShinyGuideWidget(entry: entry, dexId: 'kanto_dex'),
            ),
          ),
        ),
      ),
    );

    await waitForLoaded(tester);
    await tester.pump(const Duration(milliseconds: 300));

    // Open main guide
    await tester.tap(find.text(Translator.get('shiny_guide_title')));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Gen 2
    await tester.ensureVisible(find.text('Generation 2'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Generation 2'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('1:8192'), findsWidgets);

    // Tap Gen 3
    await tester.ensureVisible(find.text('Generation 3'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Generation 3'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump(const Duration(seconds: 15));
  });
}
