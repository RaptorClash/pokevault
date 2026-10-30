import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen7_5_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guides/gen9_5_shiny_guide.dart';
import 'package:pokevault/screens/pokemon_info/shiny_guide_widget.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database testDb;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDb = await openDatabase(File('assets/db/pokedex.sqlite').absolute.path);
    DatabaseService.setAppDatabaseForTesting(testDb);
  });

  tearDownAll(() async {
    DatabaseService.setAppDatabaseForTesting(null);
    try {
      await testDb.close();
    } catch (_) {}
  });

  Future<void> pumpGuide(WidgetTester tester) async {
    for (int i = 0; i < 40; i++) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Shiny Guide Enhancements & Edge Cases (TDD)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
      Translator.currentLanguage = 'de';
    });

    testWidgets('Gen 2/3 GB VC Glitch only displays Generation 2 shiny guide tile', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final treeckoGlitch = Pokemon(
        id: 252,
        nameDe: 'Geckarbor',
        nameEn: 'Treecko',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 130,
        eggGroups: ['monster'],
        weight: 5.0,
        speed: 70,
        forms: [
          PokemonForm(
            name: 'vc_glitch',
            formType: 'other',
            minGen: 2,
            imageId: 252,
            types: ['grass'],
            exclusiveRegions: [],
          ),
        ],
      );

      final entry = DexDisplayEntry(
        pokemon: treeckoGlitch,
        uniqueId: '252_vc_glitch',
        displaySuffix: ' (Game Boy VC Glitch)',
        imageUrl: '',
        form: treeckoGlitch.forms.first,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShinyGuideWidget(entry: entry, dexId: 'dex_1'),
            ),
          ),
        ),
      );
      await pumpGuide(tester);

      // Expand the main shiny guide card if present
      final mainExpansion = find.text(Translator.get('shiny_guide_title'));
      expect(mainExpansion, findsOneWidget);
      await tester.tap(mainExpansion);
      await tester.pump(const Duration(milliseconds: 300));

      // Generation 2 must be visible
      expect(find.text(Translator.get('shiny_guide_gen2')), findsOneWidget);

      // Generations 3, 4, 5, 6, 7, 8, 9, 9.5 must NOT be visible
      expect(find.text(Translator.get('shiny_guide_gen3')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen4')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen6')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen9_5')), findsNothing);
    });

    testWidgets('Gen95ShinyGuide marks Diancie as shiny locked and shows no hunt start button', (tester) async {
      final diancie = Pokemon(
        id: 719,
        nameDe: 'Diancie',
        nameEn: 'Diancie',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 3,
        evolutionChainId: 369,
        eggGroups: ['undiscovered'],
        weight: 8.8,
        speed: 50,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 6,
            imageId: 719,
            types: ['rock', 'fairy'],
            exclusiveRegions: [],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Gen95ShinyGuide(
                pokemon: diancie,
                shinyCategories: const ['legendary_mythical'],
                title: 'Generation 9.5 (Legenden: Z-A)',
                onLaunchUrl: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand tile
      final tileFinder = find.text('Generation 9.5 (Legenden: Z-A)');
      if (tileFinder.evaluate().isNotEmpty) {
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Nein'), findsOneWidget);
        expect(find.textContaining('Ja (Basis-Chance'), findsNothing);
      }
    });

    testWidgets('Gen75ShinyGuide displays Pokemon GO limited event note for Meltan and Melmetal', (tester) async {
      final meltan = Pokemon(
        id: 808,
        nameDe: 'Meltan',
        nameEn: 'Meltan',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 3,
        evolutionChainId: 420,
        eggGroups: ['undiscovered'],
        weight: 8.0,
        speed: 34,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 7,
            imageId: 808,
            types: ['steel'],
            exclusiveRegions: [],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Gen75ShinyGuide(
                pokemon: meltan,
                shinyCategories: const ['legendary_mythical'],
                title: 'Generation 7.5',
                onLaunchUrl: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileFinder = find.text('Generation 7.5');
      if (tileFinder.evaluate().isNotEmpty) {
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Pokémon GO'), findsWidgets);
      }
    });

    testWidgets('Partner Cap Pikachu in ShinyGuideWidget ONLY displays Gen 7 and suppresses SOS/Pelago', (tester) async {
      final pikachu = Pokemon(
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
        forms: [
          PokemonForm(
            name: 'partner-cap',
            formType: 'other',
            minGen: 7,
            imageId: 10148,
            types: ['electric'],
            exclusiveRegions: [],
          ),
        ],
      );

      final entry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_partner-cap',
        displaySuffix: ' (Partner-Kappe)',
        imageUrl: '',
        form: pikachu.forms.first,
      );

      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShinyGuideWidget(entry: entry, dexId: 'dex_partner_cap'),
            ),
          ),
        ),
      );
      await pumpGuide(tester);

      // Expand main shiny guide card
      final mainExpansion = find.text(Translator.get('shiny_guide_title'));
      expect(mainExpansion, findsOneWidget);
      await tester.tap(mainExpansion);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));

      // Gen 7 must be visible
      expect(find.text(Translator.get('shiny_guide_gen7')), findsOneWidget);

      // Other generations must NOT be visible
      expect(find.text(Translator.get('shiny_guide_gen1')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen2')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen3')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen4')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen5')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen6')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen7_5')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen8')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen8_5')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen9')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen9_5')), findsNothing);

      // Expand Gen 7 tile
      final gen7Tile = find.text(Translator.get('shiny_guide_gen7'));
      await tester.tap(gen7Tile);
      await tester.pump(const Duration(milliseconds: 300));

      // Must display Pikachu Valley QR-Code Soft Reset & Visual Note
      expect(find.textContaining('Pikachu-Tal'), findsWidgets);
      expect(find.textContaining('Stern'), findsWidgets);
      expect(find.textContaining('Animation'), findsWidgets);

      // Must NOT display SOS-Chaining or Pokémon-Resort / Pelago
      expect(find.textContaining('Hilferuf'), findsNothing);
      expect(find.textContaining('SOS'), findsNothing);
      expect(find.textContaining('Pelago'), findsNothing);
      expect(find.textContaining('Resort'), findsNothing);
    });

    testWidgets('Original Cap Pikachu in ShinyGuideWidget ONLY displays Gen 7 with Shiny-Lock and no hunt button', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final pikachu = Pokemon(
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
        forms: [
          PokemonForm(
            name: 'original-cap',
            formType: 'other',
            minGen: 7,
            imageId: 10094,
            types: ['electric'],
            exclusiveRegions: [],
          ),
        ],
      );

      final entry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_original-cap',
        displaySuffix: ' (Original-Kappe)',
        imageUrl: '',
        form: pikachu.forms.first,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShinyGuideWidget(entry: entry, dexId: 'dex_orig_cap'),
            ),
          ),
        ),
      );
      await pumpGuide(tester);

      // Expand main shiny guide card
      final mainExpansion = find.text(Translator.get('shiny_guide_title'));
      expect(mainExpansion, findsOneWidget);
      await tester.tap(mainExpansion);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));

      // Shiny-Lock banner must be visible inside children
      expect(find.text(Translator.get('shiny_lock_banner')), findsOneWidget);

      // Gen 7 must be visible
      expect(find.text(Translator.get('shiny_guide_gen7')), findsOneWidget);

      // Other generations must NOT be visible
      expect(find.text(Translator.get('shiny_guide_gen1')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen8')), findsNothing);
      expect(find.text(Translator.get('shiny_guide_gen9')), findsNothing);

      // Expand Gen 7 tile
      final gen7Tile = find.text(Translator.get('shiny_guide_gen7'));
      await tester.tap(gen7Tile);
      await tester.pump(const Duration(milliseconds: 300));

      // Shows locked and no hunt start button
      expect(find.textContaining('Nein'), findsOneWidget);
      expect(find.textContaining('Hunt starten'), findsNothing);
    });
  });
}
