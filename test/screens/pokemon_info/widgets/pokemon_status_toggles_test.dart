import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_info_widgets.dart';
import 'package:pokevault/l10n/app_translations.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  group('PokemonStatusTogglesWidget Tests - Multi-Language', () {
    late MockDexProvider mockProvider;

    setUp(() {
      mockProvider = MockDexProvider();
      when(() => mockProvider.togglePokemon(any(), any())).thenAnswer((_) {});
      when(() => mockProvider.toggleShiny(any(), any())).thenAnswer((_) {});
    });

    final expectedTranslations = {
      'de': 'Gefangen Status',
      'en': 'Caught Status',
    };

    for (var entry in expectedTranslations.entries) {
      final lang = entry.key;
      final expectedText = entry.value;

      testWidgets(
        'Rendert korrekte Strings und reagiert auf Klick in Sprache: $lang',
        (WidgetTester tester) async {
          Translator.currentLanguage = lang;

          final dummyPokemon = Pokemon(
            id: 1,
            nameDe: 'Bisasam',
            nameEn: 'Bulbasaur',
            hasGenderDifferences: false,
            genderRate: 1,
            captureRate: 45,
            evolutionChainId: 1,
            eggGroups: [],
            weight: 6.9,
            speed: 45,
            forms: [],
          );
          final dummyEntry = DexDisplayEntry(
            pokemon: dummyPokemon,
            uniqueId: '1_normal',
            displaySuffix: '',
            imageUrl: '',
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PokemonStatusTogglesWidget(
                  dexId: 'dex_123',
                  entry: dummyEntry,
                  isCaught: false,
                  isShiny: true,
                  provider: mockProvider,
                  caughtStatusKey: GlobalKey(),
                  shinyStatusKey: GlobalKey(),
                ),
              ),
            ),
          );

          expect(find.text(expectedText), findsOneWidget);

          await tester.tap(find.text(expectedText));
          await tester.pumpAndSettle();

          verify(
            () => mockProvider.togglePokemon('dex_123', '1_normal'),
          ).called(1);

          clearInteractions(mockProvider);
        },
      );
    }
  });
}
