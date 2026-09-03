import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_avatar.dart';
import 'package:pokevault/l10n/app_translations.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  group('PokemonAvatar Widget Tests', () {
    late MockDexProvider mockProvider;
    late MockSettingsProvider mockSettingsProvider;
    late Pokemon dummyPokemon;

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
      when(() => mockProvider.allPokemon).thenReturn([dummyPokemon]);
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      Translator.currentLanguage = 'de';
    });

    Widget buildAvatar({
      required bool isShiny,
      required String gender,
      bool isCarrier = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<DexProvider>.value(value: mockProvider),
              ChangeNotifierProvider<SettingsProvider>.value(
                value: mockSettingsProvider,
              ),
            ],
            child: PokemonAvatar(
              id: 25,
              isShiny: isShiny,
              gender: gender,
              isCarrier: isCarrier,
            ),
          ),
        ),
      );
    }

    testWidgets('Rendert Shiny-Stern, wenn isShiny true ist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildAvatar(isShiny: true, gender: 'any'));
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Rendert Geschlechts-Icons in den korrekten Farben', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildAvatar(isShiny: false, gender: 'm'));
      final maleIcon = tester.widget<Icon>(find.byIcon(Icons.male));
      expect(maleIcon.color, equals(Colors.blueAccent));

      await tester.pumpWidget(buildAvatar(isShiny: false, gender: 'f'));
      final femaleIcon = tester.widget<Icon>(find.byIcon(Icons.female));
      expect(femaleIcon.color, equals(Colors.pinkAccent));
    });

    testWidgets('Blendet Shiny-Stern aus, wenn Pokémon eine Gen-Trägerin ist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildAvatar(isShiny: true, gender: 'f', isCarrier: true),
      );
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.textContaining('Trägerin'), findsOneWidget);
    });

    testWidgets('Rendert das korrekte Image-Widget (Web vs. Native)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildAvatar(isShiny: false, gender: 'any'));

      if (kIsWeb) {
        expect(find.byType(Image), findsWidgets);
      } else {
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      }
    });
  });
}
