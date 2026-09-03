import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/breeding_step_card.dart';
import 'package:pokevault/l10n/app_translations.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  group('BreedingStepCard Widget Tests', () {
    late MockDexProvider mockProvider;
    late MockSettingsProvider mockSettingsProvider;

    setUp(() {
      mockProvider = MockDexProvider();
      mockSettingsProvider = MockSettingsProvider();

      final dummyPikachu = Pokemon(
        id: 25,
        nameDe: 'Pikachu',
        nameEn: 'Pikachu',
        hasGenderDifferences: true,
        genderRate: 4,
        captureRate: 190,
        evolutionChainId: 10,
        eggGroups: ['Fairy'],
        weight: 6.0,
        speed: 90,
        forms: [],
      );

      when(() => mockProvider.allPokemon).thenReturn([dummyPikachu]);
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    });

    Widget buildCard({required bool p1Shiny, required bool cCarrier}) {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<DexProvider>.value(value: mockProvider),
              ChangeNotifierProvider<SettingsProvider>.value(
                value: mockSettingsProvider,
              ),
            ],
            child: BreedingStepCard(
              stepNumber: 1,
              parent1Id: 25,
              p1Shiny: p1Shiny,
              p1Gender: 'm',
              p1Carrier: false,
              parent2Id: 25,
              p2Shiny: false,
              p2Gender: 'f',
              p2Carrier: false,
              childId: 25,
              cShiny: true,
              cGender: 'any',
              cCarrier: cCarrier,
              isFinal: true,
            ),
          ),
        ),
      );
    }

    testWidgets('Zeigt Schritt-Nummer und Rendert Eltern-Icons', (
      WidgetTester tester,
    ) async {
      Translator.currentLanguage = 'de';
      await tester.pumpWidget(buildCard(p1Shiny: true, cCarrier: false));

      expect(find.text('Schritt 1'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Zeigt Carrier-Info, wenn das Kind ein Gen-Träger ist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCard(p1Shiny: false, cCarrier: true));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Chance: 1:2 (Gen-Trägerin)'), findsOneWidget);
    });
  });
}
