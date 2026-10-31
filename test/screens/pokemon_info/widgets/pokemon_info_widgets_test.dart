import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_info_widgets.dart';
import 'package:pokevault/screens/pokemon_info/widgets/matching_balls_widget.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('PokemonInfoWidgets Tests (Header & Matching Balls)', () {
    late MockDexProvider mockProvider;
    late MockSettingsProvider mockSettingsProvider;
    late Pokemon dummyPokemon;
    late DexDisplayEntry dummyEntry;

    setUp(() {
      mockProvider = MockDexProvider();
      mockSettingsProvider = MockSettingsProvider();

      dummyPokemon = Pokemon(
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
        forms: [],
      );

      dummyEntry = DexDisplayEntry(
        pokemon: dummyPokemon,
        uniqueId: '25_normal',
        displaySuffix: '',
        imageUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
      );

      when(() => mockProvider.allPokemon).thenReturn([dummyPokemon]);
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockProvider.ballUrls).thenReturn({'poke': 'https://url'});
      LocaleSettings.setLocale(AppLocale.de);
    });

    testWidgets(
      'PokemonHeaderWidget nutzt das korrekte Image-Widget (Web vs Native)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiProvider(
                providers: [
                  ChangeNotifierProvider<DexProvider>.value(
                    value: mockProvider,
                  ),
                  ChangeNotifierProvider<SettingsProvider>.value(
                    value: mockSettingsProvider,
                  ),
                ],
                child: PokemonHeaderWidget(
                  entry: dummyEntry,
                  wantShiny: false,
                  onShinyToggled: () {},
                  shinyToggleKey: GlobalKey(),
                  currentForm: null,
                ),
              ),
            ),
          ),
        );

        if (kIsWeb) {
          expect(find.byType(Image), findsWidgets);
        } else {
          expect(find.byType(CachedNetworkImage), findsWidgets);
        }
      },
    );

    testWidgets('MatchingBallsWidget rendert UI fehlerfrei', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<DexProvider>.value(value: mockProvider),
                ChangeNotifierProvider<SettingsProvider>.value(
                  value: mockSettingsProvider,
                ),
              ],
              child: MatchingBallsWidget(
                entry: dummyEntry,
                matchingBallsKey: GlobalKey(),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Matching Balls'), findsOneWidget);
    });

    testWidgets(
      'Regionalform Alola-Vulnona mit Instance-ID (38_alola__1728..._0) zeigt EIS und FEE Typen und Eis/Fee Gradient',
      (WidgetTester tester) async {
        final alolaForm = PokemonForm(
          name: 'alola',
          formType: 'regional',
          minGen: 7,
          imageId: 10104,
          types: ['ice', 'fairy'],
          exclusiveRegions: ['alola'],
        );
        final normalForm = PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 1,
          imageId: 38,
          types: ['fire'],
          exclusiveRegions: [],
        );
        final vulnona = Pokemon(
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
          forms: [normalForm, alolaForm],
        );

        final entry = DexDisplayEntry(
          pokemon: vulnona,
          uniqueId: '38_alola__1728412345678_0',
          displaySuffix: ' (Alola)',
          imageUrl:
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10104.png',
        );

        // Verify resolvedForm resolves properly to alola despite instance ID
        expect(entry.resolvedForm, isNotNull);
        expect(entry.resolvedForm!.name, 'alola');
        expect(entry.resolvedForm!.types, ['ice', 'fairy']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiProvider(
                providers: [
                  ChangeNotifierProvider<DexProvider>.value(value: mockProvider),
                  ChangeNotifierProvider<SettingsProvider>.value(
                    value: mockSettingsProvider,
                  ),
                ],
                child: Column(
                  children: [
                    PokemonHeaderWidget(
                      entry: entry,
                      wantShiny: false,
                      onShinyToggled: () {},
                      shinyToggleKey: GlobalKey(),
                      currentForm: entry.resolvedForm,
                    ),
                    PokemonBasicInfoWidget(
                      entry: entry,
                      provider: mockProvider,
                      basicInfoKey: GlobalKey(),
                      currentForm: entry.resolvedForm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Basic info widget must render EIS and FEE, and NOT FEUER
        expect(find.text('EIS'), findsOneWidget);
        expect(find.text('FEE'), findsOneWidget);
        expect(find.text('FEUER'), findsNothing);

        // Header gradient must contain ice and fairy colors
        final containerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).gradient is LinearGradient,
        );
        expect(containerFinder, findsOneWidget);
        final container = tester.widget<Container>(containerFinder);
        final gradient =
            (container.decoration as BoxDecoration).gradient as LinearGradient;
        expect(gradient.colors.first, pokemonTypeColors['ice']!.withValues(alpha: 0.5));
        expect(gradient.colors[1], pokemonTypeColors['fairy']!.withValues(alpha: 0.5));
      },
    );

    testWidgets(
      'Normales Vulnona (38_normal) zeigt FEUER Typ und nicht Eis/Fee',
      (WidgetTester tester) async {
        final alolaForm = PokemonForm(
          name: 'alola',
          formType: 'regional',
          minGen: 7,
          imageId: 10104,
          types: ['ice', 'fairy'],
          exclusiveRegions: ['alola'],
        );
        final normalForm = PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 1,
          imageId: 38,
          types: ['fire'],
          exclusiveRegions: [],
        );
        final vulnona = Pokemon(
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
          forms: [normalForm, alolaForm],
        );

        final entry = DexDisplayEntry(
          pokemon: vulnona,
          uniqueId: '38_normal',
          displaySuffix: '',
          imageUrl:
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/38.png',
        );

        expect(entry.resolvedForm, isNotNull);
        expect(entry.resolvedForm!.name, 'normal');
        expect(entry.resolvedForm!.types, ['fire']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiProvider(
                providers: [
                  ChangeNotifierProvider<DexProvider>.value(value: mockProvider),
                  ChangeNotifierProvider<SettingsProvider>.value(
                    value: mockSettingsProvider,
                  ),
                ],
                child: PokemonBasicInfoWidget(
                  entry: entry,
                  provider: mockProvider,
                  basicInfoKey: GlobalKey(),
                  currentForm: entry.resolvedForm,
                ),
              ),
            ),
          ),
        );

        expect(find.text('FEUER'), findsOneWidget);
        expect(find.text('EIS'), findsNothing);
        expect(find.text('FEE'), findsNothing);
      },
    );
  });
}
