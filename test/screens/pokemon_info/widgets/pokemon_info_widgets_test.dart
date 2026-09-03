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
import 'package:pokevault/l10n/app_translations.dart';

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
      Translator.currentLanguage = 'de';
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
  });
}
