import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen6_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen7_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen7_5_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen8_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen8_5_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen9_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen9_5_shiny_guide.dart';
import 'package:pokevault/i18n/strings.g.dart';
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

    tempDir = Directory.systemTemp.createTempSync('pokevault_gen6_9_test_');
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

  setUp(() {
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    LocaleSettings.setLocale(AppLocale.de);
  });

  Future<void> settleDb(WidgetTester tester) async {
    for (int i = 0; i < 40; i++) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();
      if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
  }

  Widget wrapWithScaffold(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Gen6ShinyGuide Tests', () {
    testWidgets('Renders Gen 6 hunt methods when expanded', (tester) async {
      final pokemon = createTestPokemon(id: 650, nameDe: 'Igamaro');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen6ShinyGuide(
            pokemon: pokemon,
            shinyCategories: const ['gen6_masuda'],
            title: 'Generation 6',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 6'), findsOneWidget);
      await tester.tap(find.text('Generation 6'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen6_masuda_title), findsOneWidget);
    });

    testWidgets('Renders shiny locked state for Gen 6 locked Pokemon', (tester) async {
      final xerneas = createTestPokemon(id: 716, nameDe: 'Xerneas');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen6ShinyGuide(
            pokemon: xerneas,
            shinyCategories: const ['gen6_locks'],
            title: 'Generation 6',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      await tester.tap(find.text('Generation 6'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_huntable_no), findsOneWidget);
    });
  });

  group('Gen7ShinyGuide Tests', () {
    testWidgets('Renders Gen 7 methods when expanded', (tester) async {
      final pikachu = createTestPokemon(id: 25, nameDe: 'Pikachu');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen7ShinyGuide(
            pokemon: pikachu,
            shinyCategories: const ['gen7_masuda'],
            title: 'Generation 7',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 7'), findsOneWidget);
      await tester.tap(find.text('Generation 7'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen6_masuda_title), findsOneWidget);
    });
  });

  group('Gen75ShinyGuide Tests', () {
    testWidgets('Renders Let\'s Go methods (Catch Combo, Lures)', (tester) async {
      final pikachu = createTestPokemon(id: 25, nameDe: 'Pikachu');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen75ShinyGuide(
            pokemon: pikachu,
            shinyCategories: const ['gen7_5_combo'],
            title: 'Generation 7.5',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 7.5'), findsOneWidget);
      await tester.tap(find.text('Generation 7.5'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen75_combo_title), findsOneWidget);
    });
  });

  group('Gen8ShinyGuide & Gen85ShinyGuide Tests', () {
    testWidgets('Renders Gen 8 Dynamax & Masuda methods', (tester) async {
      final pikachu = createTestPokemon(id: 25, nameDe: 'Pikachu');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen8ShinyGuide(
            pokemon: pikachu,
            shinyCategories: const ['gen8_masuda'],
            title: 'Generation 8',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 8'), findsOneWidget);
      await tester.tap(find.text('Generation 8'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen8_masuda_title), findsOneWidget);
    });

    testWidgets('Renders Gen 8.5 Legends Arceus methods', (tester) async {
      final pikachu = createTestPokemon(id: 25, nameDe: 'Pikachu');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen85ShinyGuide(
            pokemon: pikachu,
            shinyCategories: const ['gen8_5_outbreak'],
            title: 'Generation 8.5',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 8.5'), findsOneWidget);
      await tester.tap(find.text('Generation 8.5'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen85_pla_title), findsOneWidget);
    });
  });

  group('Gen9ShinyGuide & Gen95ShinyGuide Tests', () {
    testWidgets('Renders Gen 9 Sandwiches & Outbreaks', (tester) async {
      final pikachu = createTestPokemon(id: 25, nameDe: 'Pikachu');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen9ShinyGuide(
            pokemon: pikachu,
            shinyCategories: const ['gen9_sandwiches'],
            title: 'Generation 9',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 9'), findsOneWidget);
      await tester.tap(find.text('Generation 9'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen9_sandwich_title), findsOneWidget);
    });

    testWidgets('Renders Gen 9.5 Legends Z-A methods or handles unreleased dex', (tester) async {
      final pikachu = createTestPokemon(id: 25, nameDe: 'Pikachu');

      await tester.pumpWidget(
        wrapWithScaffold(
          Gen95ShinyGuide(
            pokemon: pikachu,
            shinyCategories: const ['gen9_5_za'],
            title: 'Generation 9.5',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);
      final tileFinder = find.text('Generation 9.5');
      if (tileFinder.evaluate().isNotEmpty) {
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();
        expect(find.text(t.shiny_gen95_donut_title), findsOneWidget);
      } else {
        expect(find.byType(SizedBox), findsWidgets);
      }
    });
  });
}
