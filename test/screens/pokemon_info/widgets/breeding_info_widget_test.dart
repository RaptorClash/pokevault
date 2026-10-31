import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/breeding_info_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_avatar.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = '${Directory.current.path}/assets/db/pokedex.sqlite';
    db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(readOnly: true),
    );
    DatabaseService.setAppDatabaseForTesting(db);
  });

  tearDownAll(() async {
    DatabaseService.setAppDatabaseForTesting(null);
    await db.close();
  });

  group('BreedingInfoWidget UI Tests', () {
    test('DatabaseService lädt Evolutionskette mit Details aus SQLite', () async {
      final res = await DatabaseService.instance.getEvolutionChain(1);
      expect(res, isNotNull);
      expect(res!['species_id'], 1);
      expect(res['details'], isEmpty);
      final evolvesTo = res['evolves_to'] as List;
      expect(evolvesTo, isNotEmpty);
      expect(evolvesTo.first['details'], isNotEmpty);
      expect(evolvesTo.first['details'].first['trigger'], 'level-up');
      expect(evolvesTo.first['details'].first['min_level'], 16);
    });

    late MockDexProvider mockProvider;
    late MockSettingsProvider mockSettingsProvider;

    final testPokemonList = [
      Pokemon(
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
      ),
      Pokemon(
        id: 2,
        nameDe: 'Bisaknosp',
        nameEn: 'Ivysaur',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['Monster', 'Grass'],
        weight: 13.0,
        speed: 60,
        forms: [],
      ),
      Pokemon(
        id: 3,
        nameDe: 'Bisaflor',
        nameEn: 'Venusaur',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['Monster', 'Grass'],
        weight: 100.0,
        speed: 80,
        forms: [],
      ),
      Pokemon(
        id: 172,
        nameDe: 'Pichu',
        nameEn: 'Pichu',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 190,
        evolutionChainId: 10,
        eggGroups: ['No Eggs'],
        weight: 2.0,
        speed: 60,
        forms: [],
      ),
      Pokemon(
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
      ),
      Pokemon(
        id: 26,
        nameDe: 'Raichu',
        nameEn: 'Raichu',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 75,
        evolutionChainId: 10,
        eggGroups: ['Field', 'Fairy'],
        weight: 30.0,
        speed: 110,
        forms: [],
      ),
      Pokemon(
        id: 60,
        nameDe: 'Quapsel',
        nameEn: 'Poliwag',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 255,
        evolutionChainId: 26,
        eggGroups: ['Water 1'],
        weight: 12.4,
        speed: 90,
        forms: [],
      ),
      Pokemon(
        id: 61,
        nameDe: 'Quaputzi',
        nameEn: 'Poliwhirl',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 120,
        evolutionChainId: 26,
        eggGroups: ['Water 1'],
        weight: 20.0,
        speed: 90,
        forms: [],
      ),
      Pokemon(
        id: 62,
        nameDe: 'Quappo',
        nameEn: 'Poliwrath',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 45,
        evolutionChainId: 26,
        eggGroups: ['Water 1'],
        weight: 54.0,
        speed: 70,
        forms: [],
      ),
      Pokemon(
        id: 186,
        nameDe: 'Quaxo',
        nameEn: 'Politoed',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 45,
        evolutionChainId: 26,
        eggGroups: ['Water 1'],
        weight: 33.9,
        speed: 70,
        forms: [],
      ),
      Pokemon(
        id: 236,
        nameDe: 'Rabauz',
        nameEn: 'Tyrogue',
        hasGenderDifferences: false,
        genderRate: 0,
        captureRate: 75,
        evolutionChainId: 47,
        eggGroups: ['No Eggs'],
        weight: 21.0,
        speed: 35,
        forms: [],
      ),
      Pokemon(
        id: 106,
        nameDe: 'Kicklee',
        nameEn: 'Hitmonlee',
        hasGenderDifferences: false,
        genderRate: 0,
        captureRate: 45,
        evolutionChainId: 47,
        eggGroups: ['Human-Like'],
        weight: 49.8,
        speed: 87,
        forms: [],
      ),
      Pokemon(
        id: 107,
        nameDe: 'Nockchan',
        nameEn: 'Hitmonchan',
        hasGenderDifferences: false,
        genderRate: 0,
        captureRate: 45,
        evolutionChainId: 47,
        eggGroups: ['Human-Like'],
        weight: 50.2,
        speed: 76,
        forms: [],
      ),
      Pokemon(
        id: 237,
        nameDe: 'Kapoera',
        nameEn: 'Hitmontop',
        hasGenderDifferences: false,
        genderRate: 0,
        captureRate: 45,
        evolutionChainId: 47,
        eggGroups: ['Human-Like'],
        weight: 48.0,
        speed: 70,
        forms: [],
      ),
      Pokemon(
        id: 216,
        nameDe: 'Teddiursa',
        nameEn: 'Teddiursa',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 120,
        evolutionChainId: 110,
        eggGroups: ['Field'],
        weight: 8.8,
        speed: 40,
        forms: [],
      ),
      Pokemon(
        id: 217,
        nameDe: 'Ursaring',
        nameEn: 'Ursaring',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 60,
        evolutionChainId: 110,
        eggGroups: ['Field'],
        weight: 125.8,
        speed: 55,
        forms: [],
      ),
      Pokemon(
        id: 901,
        nameDe: 'Ursaluna',
        nameEn: 'Ursaluna',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 75,
        evolutionChainId: 110,
        eggGroups: ['Field'],
        weight: 290.0,
        speed: 50,
        forms: [],
      ),
      Pokemon(
        id: 349,
        nameDe: 'Barschwa',
        nameEn: 'Feebas',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 255,
        evolutionChainId: 178,
        eggGroups: ['Water 1', 'Dragon'],
        weight: 7.4,
        speed: 80,
        forms: [],
      ),
      Pokemon(
        id: 350,
        nameDe: 'Milotic',
        nameEn: 'Milotic',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 60,
        evolutionChainId: 178,
        eggGroups: ['Water 1', 'Dragon'],
        weight: 162.0,
        speed: 81,
        forms: [],
      ),
      Pokemon(
        id: 924,
        nameDe: 'Zwieps',
        nameEn: 'Tandemaus',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 150,
        evolutionChainId: 485,
        eggGroups: ['Field', 'Fairy'],
        weight: 1.8,
        speed: 75,
        forms: [],
      ),
      Pokemon(
        id: 925,
        nameDe: 'Famieps',
        nameEn: 'Maushold',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 75,
        evolutionChainId: 485,
        eggGroups: ['Field', 'Fairy'],
        weight: 2.8,
        speed: 111,
        forms: [],
      ),
      Pokemon(
        id: 81,
        nameDe: 'Magnetilo',
        nameEn: 'Magnemite',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 190,
        evolutionChainId: 34,
        eggGroups: ['Mineral'],
        weight: 6.0,
        speed: 45,
        forms: [],
      ),
      Pokemon(
        id: 82,
        nameDe: 'Magneton',
        nameEn: 'Magneton',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 60,
        evolutionChainId: 34,
        eggGroups: ['Mineral'],
        weight: 60.0,
        speed: 70,
        forms: [],
      ),
      Pokemon(
        id: 462,
        nameDe: 'Magnezone',
        nameEn: 'Magnezone',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 30,
        evolutionChainId: 34,
        eggGroups: ['Mineral'],
        weight: 180.0,
        speed: 60,
        forms: [],
      ),
      Pokemon(
        id: 133,
        nameDe: 'Evoli',
        nameEn: 'Eevee',
        hasGenderDifferences: true,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 67,
        eggGroups: ['Field'],
        weight: 6.5,
        speed: 55,
        forms: [],
      ),
      Pokemon(
        id: 470,
        nameDe: 'Folipurba',
        nameEn: 'Leafeon',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: 67,
        eggGroups: ['Field'],
        weight: 25.5,
        speed: 95,
        forms: [],
      ),
      Pokemon(
        id: 56,
        nameDe: 'Menki',
        nameEn: 'Mankey',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 190,
        evolutionChainId: 24,
        eggGroups: ['Field'],
        weight: 28.0,
        speed: 70,
        forms: [],
      ),
      Pokemon(
        id: 57,
        nameDe: 'Rasaff',
        nameEn: 'Primeape',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 75,
        evolutionChainId: 24,
        eggGroups: ['Field'],
        weight: 32.0,
        speed: 95,
        forms: [],
      ),
      Pokemon(
        id: 979,
        nameDe: 'Epitaff',
        nameEn: 'Annihilape',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 45,
        evolutionChainId: 24,
        eggGroups: ['Field'],
        weight: 56.0,
        speed: 90,
        forms: [],
      ),
      Pokemon(
        id: 588,
        nameDe: 'Laukaps',
        nameEn: 'Karrablast',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 200,
        evolutionChainId: 299,
        eggGroups: ['Bug'],
        weight: 5.9,
        speed: 60,
        forms: [],
      ),
      Pokemon(
        id: 589,
        nameDe: 'Cavalanzas',
        nameEn: 'Escavalier',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 75,
        evolutionChainId: 299,
        eggGroups: ['Bug'],
        weight: 33.0,
        speed: 20,
        forms: [],
      ),
      Pokemon(
        id: 37,
        nameDe: 'Vulpix',
        nameEn: 'Vulpix',
        hasGenderDifferences: false,
        genderRate: 6,
        captureRate: 190,
        evolutionChainId: 15,
        eggGroups: ['Field'],
        weight: 9.9,
        speed: 65,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 37,
            types: ['fire'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'alola',
            formType: 'regional',
            minGen: 7,
            imageId: 10103,
            types: ['ice'],
            exclusiveRegions: ['alola'],
          ),
        ],
      ),
      Pokemon(
        id: 38,
        nameDe: 'Vulnona',
        nameEn: 'Ninetales',
        hasGenderDifferences: false,
        genderRate: 6,
        captureRate: 75,
        evolutionChainId: 15,
        eggGroups: ['Field'],
        weight: 19.9,
        speed: 100,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 38,
            types: ['fire'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'alola',
            formType: 'regional',
            minGen: 7,
            imageId: 10104,
            types: ['ice', 'fairy'],
            exclusiveRegions: ['alola'],
          ),
        ],
      ),
      Pokemon(
        id: 52,
        nameDe: 'Mauzi',
        nameEn: 'Meowth',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 255,
        evolutionChainId: 22,
        eggGroups: ['Field'],
        weight: 4.2,
        speed: 90,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 52,
            types: ['normal'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'alola',
            formType: 'regional',
            minGen: 7,
            imageId: 10091,
            types: ['dark'],
            exclusiveRegions: ['alola'],
          ),
          PokemonForm(
            name: 'galar',
            formType: 'regional',
            minGen: 8,
            imageId: 10161,
            types: ['steel'],
            exclusiveRegions: ['galar'],
          ),
        ],
      ),
      Pokemon(
        id: 53,
        nameDe: 'Snobilikat',
        nameEn: 'Persian',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 90,
        evolutionChainId: 22,
        eggGroups: ['Field'],
        weight: 32.0,
        speed: 115,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 53,
            types: ['normal'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'alola',
            formType: 'regional',
            minGen: 7,
            imageId: 10092,
            types: ['dark'],
            exclusiveRegions: ['alola'],
          ),
        ],
      ),
      Pokemon(
        id: 863,
        nameDe: 'Mauzinger',
        nameEn: 'Perrserker',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 90,
        evolutionChainId: 22,
        eggGroups: ['Field'],
        weight: 28.0,
        speed: 50,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 8,
            imageId: 863,
            types: ['steel'],
            exclusiveRegions: [],
          ),
        ],
      ),
    ];

    setUp(() {
      LocaleSettings.setLocale(AppLocale.de);
      mockProvider = MockDexProvider();
      mockSettingsProvider = MockSettingsProvider();
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockProvider.allPokemon).thenReturn(testPokemonList);
    });

    Widget buildWidget(Pokemon pokemon, {PokemonForm? currentForm}) {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<DexProvider>.value(value: mockProvider),
              ChangeNotifierProvider<SettingsProvider>.value(
                value: mockSettingsProvider,
              ),
            ],
            child: SingleChildScrollView(
              child: BreedingInfoWidget(pokemon: pokemon, currentForm: currentForm),
            ),
          ),
        ),
      );
    }

    testWidgets('Rendert Geschlechtslos korrekt (genderRate = -1)', (
      WidgetTester tester,
    ) async {
      final p = Pokemon(
        id: 1,
        nameDe: 'Test',
        nameEn: 'Test',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 45,
        evolutionChainId: -1,
        eggGroups: ['Monster'],
        weight: 1.0,
        speed: 1,
        forms: [],
      );
      await tester.pumpWidget(buildWidget(p));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.byIcon(Icons.transgender), findsOneWidget);
      expect(
        find.textContaining('Geschlechtslos', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Rendert 50/50 Geschlechter korrekt (genderRate = 4)', (
      WidgetTester tester,
    ) async {
      final p = Pokemon(
        id: 1,
        nameDe: 'Test',
        nameEn: 'Test',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 45,
        evolutionChainId: -1,
        eggGroups: ['Monster'],
        weight: 1.0,
        speed: 1,
        forms: [],
      );
      await tester.pumpWidget(buildWidget(p));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.byIcon(Icons.wc), findsOneWidget);
      expect(find.textContaining('50%', findRichText: true), findsWidgets);
    });

    testWidgets('Bisasam zeigt Basisform / Ei und Stufen zeigen Level 16 und Level 32', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(testPokemonList[0])); // Bisasam, chainId: 1

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Bisasam ist die Basis
      expect(find.text('Basisform / Ei'), findsOneWidget);
      // Bisaknosp entwickelt sich ab Level 16
      expect(find.text('Level 16'), findsOneWidget);
      // Bisaflor entwickelt sich ab Level 32
      expect(find.text('Level 32'), findsOneWidget);
    });

    testWidgets('Pichu-Kette zeigt Baby-Pokémon, Hohe Zuneigung und Donnerstein', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(testPokemonList[3])); // Pichu, chainId: 10

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Pichu ist Baby
      expect(find.text('Baby-Pokémon'), findsOneWidget);
      // Pikachu entwickelt sich durch Zuneigung
      expect(find.text('Hohe Zuneigung'), findsOneWidget);
      // Raichu entwickelt sich mit Donnerstein
      expect(find.text('Donnerstein'), findsOneWidget);
    });

    testWidgets('Quaputzi-Kette zeigt Level 25, Wasserstein und Tausch (trägt King-Stein)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(testPokemonList[6])); // Quapsel, chainId: 26

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Quapsel Basis
      expect(find.text('Basisform / Ei'), findsOneWidget);
      // Quaputzi Level 25
      expect(find.text('Level 25'), findsOneWidget);
      // Quappo Wasserstein
      expect(find.text('Wasserstein'), findsOneWidget);
      // Quaxo Tausch mit King-Stein
      expect(find.text('Tausch (trägt King-Stein)'), findsOneWidget);
    });

    testWidgets('Rabauz zeigt statuswertabhängige Entwicklungen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(testPokemonList[10])); // Rabauz, chainId: 47

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Baby-Pokémon'), findsOneWidget);
      expect(find.text('Level 20 (Angriff > Vert.)'), findsOneWidget);
      expect(find.text('Level 20 (Angriff < Vert.)'), findsOneWidget);
      expect(find.text('Level 20 (Angriff = Vert.)'), findsOneWidget);
    });

    testWidgets('Englische Lokalisierung wird korrekt dargestellt', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocale(AppLocale.en);
      when(() => mockSettingsProvider.currentLanguage).thenReturn('en');

      await tester.pumpWidget(buildWidget(testPokemonList[6])); // Poliwag chain

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Base Form / Egg'), findsOneWidget);
      expect(find.text('Level 25'), findsOneWidget);
      expect(find.text('Water Stone'), findsOneWidget);
      expect(find.text("Trade (holding King's Rock)"), findsOneWidget);
    });

    testWidgets('Englische Lokalisierung für Ursaluna Vollmond', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocale(AppLocale.en);
      when(() => mockSettingsProvider.currentLanguage).thenReturn('en');

      final teddiursa = testPokemonList.firstWhere((p) => p.id == 216);
      await tester.pumpWidget(buildWidget(teddiursa));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Peat Block (during a full moon)'), findsOneWidget);
    });

    testWidgets('Ursaluna zeigt Torfblock (bei Vollmond) in DE und Vollmond in EN', (
      WidgetTester tester,
    ) async {
      final teddiursa = testPokemonList.firstWhere((p) => p.id == 216);
      await tester.pumpWidget(buildWidget(teddiursa));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Level 30'), findsOneWidget);
      expect(find.text('Torfblock (bei Vollmond)'), findsOneWidget);
    });

    testWidgets('Milotic zeigt Schönheit 170+ und Schönschuppe', (
      WidgetTester tester,
    ) async {
      final barschwa = testPokemonList.firstWhere((p) => p.id == 349);
      await tester.pumpWidget(buildWidget(barschwa));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(
        find.text('Levelaufstieg (Schönheit 170+) / Tausch (trägt Schönschuppe)'),
        findsOneWidget,
      );
    });

    testWidgets('Zwieps zeigt Level 25 (Besondere Bedingung)', (
      WidgetTester tester,
    ) async {
      final zwieps = testPokemonList.firstWhere((p) => p.id == 924);
      await tester.pumpWidget(buildWidget(zwieps));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Level 25 (Besondere Bedingung)'), findsOneWidget);
    });

    testWidgets('Magnezone konsolidiert Magnetfeld-Orte', (
      WidgetTester tester,
    ) async {
      final magnetilo = testPokemonList.firstWhere((p) => p.id == 81);
      await tester.pumpWidget(buildWidget(magnetilo));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Level 30'), findsOneWidget);
      expect(
        find.text('Levelaufstieg (besonderes Magnetfeld) / Donnerstein'),
        findsOneWidget,
      );
    });

    testWidgets('Folipurba konsolidiert Moos-/Eisfelsen', (
      WidgetTester tester,
    ) async {
      final evoli = testPokemonList.firstWhere((p) => p.id == 133);
      await tester.pumpWidget(buildWidget(evoli));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(
        find.text('Levelaufstieg (in der Nähe eines Moos-/Eisfelsens) / Blattstein'),
        findsOneWidget,
      );
    });

    testWidgets('Epitaff zeigt Attackeneinsatz ohne doppelte Klammern', (
      WidgetTester tester,
    ) async {
      final menki = testPokemonList.firstWhere((p) => p.id == 56);
      await tester.pumpWidget(buildWidget(menki));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Level 28'), findsOneWidget);
      expect(
        find.text('Attacke einsetzen (Zornesfaust, 20× eingesetzt)'),
        findsOneWidget,
      );
    });

    testWidgets('Laukaps zeigt Tausch gegen Schnuthelm übersetzt', (
      WidgetTester tester,
    ) async {
      final laukaps = testPokemonList.firstWhere((p) => p.id == 588);
      await tester.pumpWidget(buildWidget(laukaps));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Tausch (gegen Schnuthelm)'), findsOneWidget);
    });

    testWidgets('Alola-Vulnona zeigt nur Eisstein und Alola-Icons', (
      WidgetTester tester,
    ) async {
      final vulnona = testPokemonList.firstWhere((p) => p.id == 38);
      final alolaForm = vulnona.forms.firstWhere((f) => f.name == 'alola');
      await tester.pumpWidget(buildWidget(vulnona, currentForm: alolaForm));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Soll nur Eisstein zeigen, nicht Feuerstein
      expect(find.text('Eisstein'), findsOneWidget);
      expect(find.text('Feuerstein'), findsNothing);

      // Avatare sollen die Alola-ImageIds 10103 und 10104 nutzen
      final avatars = tester.widgetList<PokemonAvatar>(find.byType(PokemonAvatar)).toList();
      expect(avatars.any((a) => a.id == 37 && a.imageId == 10103), isTrue);
      expect(avatars.any((a) => a.id == 38 && a.imageId == 10104), isTrue);
    });

    testWidgets('Normales Vulnona zeigt nur Feuerstein und Standard-Icons', (
      WidgetTester tester,
    ) async {
      final vulnona = testPokemonList.firstWhere((p) => p.id == 38);
      final normalForm = vulnona.forms.firstWhere((f) => f.name == 'normal');
      await tester.pumpWidget(buildWidget(vulnona, currentForm: normalForm));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Soll nur Feuerstein zeigen, nicht Eisstein
      expect(find.text('Feuerstein'), findsOneWidget);
      expect(find.text('Eisstein'), findsNothing);

      // Avatare sollen normale IDs nutzen (keine Alola ImageIds 10103 / 10104)
      final avatars = tester.widgetList<PokemonAvatar>(find.byType(PokemonAvatar)).toList();
      expect(avatars.any((a) => a.id == 37 && (a.imageId == null || a.imageId == 37)), isTrue);
      expect(avatars.any((a) => a.id == 38 && (a.imageId == null || a.imageId == 38)), isTrue);
      expect(avatars.any((a) => a.imageId == 10103 || a.imageId == 10104), isFalse);
    });

    testWidgets('Alola-Vulpix als Basis zeigt Eisstein und Alola-Icons', (
      WidgetTester tester,
    ) async {
      final vulpix = testPokemonList.firstWhere((p) => p.id == 37);
      final alolaForm = vulpix.forms.firstWhere((f) => f.name == 'alola');
      await tester.pumpWidget(buildWidget(vulpix, currentForm: alolaForm));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('Eisstein'), findsOneWidget);
      expect(find.text('Feuerstein'), findsNothing);

      final avatars = tester.widgetList<PokemonAvatar>(find.byType(PokemonAvatar)).toList();
      expect(avatars.any((a) => a.id == 37 && a.imageId == 10103), isTrue);
      expect(avatars.any((a) => a.id == 38 && a.imageId == 10104), isTrue);
    });

    testWidgets('Galar-Mauzi zeigt nur Mauzinger und schließt Snobilikat aus', (
      WidgetTester tester,
    ) async {
      final mauzi = testPokemonList.firstWhere((p) => p.id == 52);
      final galarForm = mauzi.forms.firstWhere((f) => f.name == 'galar');
      await tester.pumpWidget(buildWidget(mauzi, currentForm: galarForm));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Soll Mauzinger zeigen, aber nicht Snobilikat
      expect(find.text('#863 Mauzinger'), findsOneWidget);
      expect(find.textContaining('Snobilikat'), findsNothing);

      // Galar-Mauzi nutzt imageId 10161
      final avatars = tester.widgetList<PokemonAvatar>(find.byType(PokemonAvatar)).toList();
      expect(avatars.any((a) => a.id == 52 && a.imageId == 10161), isTrue);
    });

    testWidgets('Normales Mauzi zeigt nur Snobilikat und schließt Mauzinger aus', (
      WidgetTester tester,
    ) async {
      final mauzi = testPokemonList.firstWhere((p) => p.id == 52);
      final normalForm = mauzi.forms.firstWhere((f) => f.name == 'normal');
      await tester.pumpWidget(buildWidget(mauzi, currentForm: normalForm));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Soll Snobilikat zeigen, aber nicht Mauzinger
      expect(find.text('#53 Snobilikat'), findsOneWidget);
      expect(find.textContaining('Mauzinger'), findsNothing);
    });

    testWidgets('Mauzinger als betrachtetes Pokémon zeigt Galar-Mauzi in der Kette', (
      WidgetTester tester,
    ) async {
      final mauzinger = testPokemonList.firstWhere((p) => p.id == 863);
      final normalForm = mauzinger.forms.firstWhere((f) => f.name == 'normal');
      await tester.pumpWidget(buildWidget(mauzinger, currentForm: normalForm));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      // Soll Mauzinger und Galar-Mauzi enthalten, aber nicht Snobilikat
      expect(find.text('#863 Mauzinger'), findsOneWidget);
      expect(find.textContaining('Snobilikat'), findsNothing);

      // Galar-Mauzi Vorfahre nutzt imageId 10161
      final avatars = tester.widgetList<PokemonAvatar>(find.byType(PokemonAvatar)).toList();
      expect(avatars.any((a) => a.id == 52 && a.imageId == 10161), isTrue);
    });
  });
}
