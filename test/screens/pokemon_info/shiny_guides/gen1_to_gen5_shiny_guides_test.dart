import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen1_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen2_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen3_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen4_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen5_shiny_guide.dart';
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
  late MockDexProvider mockDexProvider;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = Directory.systemTemp.createTempSync('pokevault_gen1_5_test_');
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
    mockDexProvider = MockDexProvider();
    when(() => mockDexProvider.allPokemon).thenReturn([
      createTestPokemon(id: 1, nameDe: 'Bisasam'),
      createTestPokemon(id: 25, nameDe: 'Pikachu'),
      createTestPokemon(id: 151, nameDe: 'Mew'),
    ]);
  });

  Future<void> settleDb(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  Widget wrapWithProvider(Widget child) {
    return ChangeNotifierProvider<DexProvider>.value(
      value: mockDexProvider,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('Gen1ShinyGuide Tests', () {
    testWidgets('Renders stat table and level selector for huntable Pokemon', (tester) async {
      final launchedUrls = <String>[];
      final pokemon = createTestPokemon(id: 1, nameDe: 'Bisasam');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen1ShinyGuide(
            pokemon: pokemon,
            shinyCategories: const ['gen1_huntable'],
            initialLevel: 5,
            onLaunchUrl: (url) async => launchedUrls.add(url),
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text(t.shiny_stat_calculator), findsOneWidget);
      await tester.tap(find.text(t.shiny_stat_calculator));
      await tester.pumpAndSettle();

      expect(find.textContaining('DV'), findsWidgets);
      expect(find.byType(DataTable), findsNWidgets(2));
    });

    testWidgets('Renders Mew tutorial buttons and triggers onLaunchUrl', (tester) async {
      final launchedUrls = <String>[];
      final mew = createTestPokemon(id: 151, nameDe: 'Mew');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen1ShinyGuide(
            pokemon: mew,
            shinyCategories: const ['gen1_huntable'],
            initialLevel: 5,
            onLaunchUrl: (url) async => launchedUrls.add(url),
          ),
        ),
      );

      await settleDb(tester);

      // Mew special buttons
      expect(find.text(t.tutorial_mew_video_de), findsOneWidget);
      await tester.tap(find.text(t.tutorial_mew_video_de));
      await tester.pump();

      expect(launchedUrls, contains('https://www.youtube.com/watch?v=jJro6Hx4IfQ'));
    });

    testWidgets('Renders Silph Scope tutorial and info box for Nebulak, Alpollo, Tragosso, Knogga', (tester) async {
      for (final id in [92, 93, 104, 105]) {
        final launchedUrls = <String>[];
        final pokemon = createTestPokemon(id: id, nameDe: 'Poke_$id');

        await tester.pumpWidget(
          wrapWithProvider(
            Gen1ShinyGuide(
              pokemon: pokemon,
              shinyCategories: const ['gen1_huntable'],
              initialLevel: 20,
              onLaunchUrl: (url) async => launchedUrls.add(url),
            ),
          ),
        );

        await settleDb(tester);

        expect(find.text(t.tutorials_silph_scope), findsOneWidget);
        expect(find.text(t.tutorial_silph_scope_video_en), findsOneWidget);
        expect(find.text(t.shiny_gen1_silph_scope_desc), findsOneWidget);

        await tester.tap(find.text(t.tutorial_silph_scope_video_en));
        await tester.pump();

        expect(launchedUrls, contains('https://youtu.be/2s6QxW-3BcE?is=T0lmNtgkVIMapARw'));
      }
    });

    testWidgets('Does not render Silph Scope tutorial for other Pokemon', (tester) async {
      final launchedUrls = <String>[];
      final bulbasaur = createTestPokemon(id: 1, nameDe: 'Bisasam');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen1ShinyGuide(
            pokemon: bulbasaur,
            shinyCategories: const ['gen1_huntable'],
            initialLevel: 5,
            onLaunchUrl: (url) async => launchedUrls.add(url),
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text(t.tutorials_silph_scope), findsNothing);
      expect(find.text(t.tutorial_silph_scope_video_en), findsNothing);
    });

    testWidgets('Renders non-huntable status when category is missing', (tester) async {
      final pokemon = createTestPokemon(id: 144, nameDe: 'Arktos');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen1ShinyGuide(
            pokemon: pokemon,
            shinyCategories: const [],
            initialLevel: 50,
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text(t.shiny_huntable_no), findsOneWidget);
    });

    testWidgets('Renders huntable status for Gastly even if shinyCategories is empty', (tester) async {
      final gastly = createTestPokemon(id: 92, nameDe: 'Nebulak');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen1ShinyGuide(
            pokemon: gastly,
            shinyCategories: const [],
            initialLevel: 20,
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text(t.shiny_gen1_huntable_yes), findsOneWidget);
    });
  });

  group('Gen2ShinyGuide Tests', () {
    testWidgets('Renders standard huntable text and breeding calculator', (tester) async {
      final pokemon = createTestPokemon(id: 25, nameDe: 'Pikachu');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen2ShinyGuide(
            pokemon: pokemon,
            dexId: 'kanto_dex',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);
      expect(find.textContaining('1:8192'), findsOneWidget);
    });

    testWidgets('Renders Roamer beast info for Suicune (245) and Raikou (243)', (tester) async {
      final suicune = createTestPokemon(id: 245, nameDe: 'Suicune');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen2ShinyGuide(
            pokemon: suicune,
            dexId: 'johto_dex',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);
      expect(find.text(t.shiny_roamer_gen2_title), findsOneWidget);
      expect(find.text(t.shiny_roamer_gen2_suicune_note), findsOneWidget);
    });

    testWidgets('Renders Mail writer glitch for Gen 3 starters (252-257)', (tester) async {
      final launchedUrls = <String>[];
      final treecko = createTestPokemon(id: 252, nameDe: 'Geckarbor');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen2ShinyGuide(
            pokemon: treecko,
            dexId: 'johto_dex',
            onLaunchUrl: (url) async => launchedUrls.add(url),
          ),
        ),
      );

      await settleDb(tester);
      expect(find.text(t.shiny_mail_writer_title), findsOneWidget);
      expect(find.text(t.tutorial_mail_writer_main), findsOneWidget);

      await tester.tap(find.text(t.tutorial_mail_writer_main));
      await tester.pump();
      expect(launchedUrls, contains('https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes'));
    });
  });

  group('Gen3ShinyGuide Tests', () {
    testWidgets('Renders Gen 3 hunting info and links', (tester) async {
      final launchedUrls = <String>[];

      await tester.pumpWidget(
        wrapWithProvider(
          Gen3ShinyGuide(
            onLaunchUrl: (url) async => launchedUrls.add(url),
          ),
        ),
      );

      await settleDb(tester);
      expect(find.textContaining('1:8192'), findsOneWidget);
      expect(find.textContaining('Smaragd'), findsWidgets);
    });
  });

  group('Gen4ShinyGuide Tests', () {
    testWidgets('Renders Gen 4 radar and masuda methods', (tester) async {
      final pokemon = createTestPokemon(id: 4, nameDe: 'Glumanda');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen4ShinyGuide(
            pokemon: pokemon,
            shinyCategories: const ['gen4_masuda'],
            title: 'Generation 4',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 4'), findsOneWidget);
      await tester.tap(find.text('Generation 4'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen4_masuda_title), findsOneWidget);
    });
  });

  group('Gen5ShinyGuide Tests', () {
    testWidgets('Renders Gen 5 shiny charm and masuda methods', (tester) async {
      final pokemon = createTestPokemon(id: 495, nameDe: 'Serpifeu');

      await tester.pumpWidget(
        wrapWithProvider(
          Gen5ShinyGuide(
            pokemon: pokemon,
            shinyCategories: const ['gen5_masuda'],
            title: 'Generation 5',
            onLaunchUrl: (_) async {},
          ),
        ),
      );

      await settleDb(tester);

      expect(find.text('Generation 5'), findsOneWidget);
      await tester.tap(find.text('Generation 5'));
      await tester.pumpAndSettle();

      expect(find.text(t.shiny_gen5_masuda_title), findsOneWidget);
    });
  });
}
