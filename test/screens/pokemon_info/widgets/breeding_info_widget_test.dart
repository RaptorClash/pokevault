import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/breeding_info_widget.dart';
import 'package:pokevault/l10n/app_translations.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  group('BreedingInfoWidget UI Tests', () {
    late MockDexProvider mockProvider;
    late MockSettingsProvider mockSettingsProvider;

    setUp(() {
      Translator.currentLanguage = 'de';
      mockProvider = MockDexProvider();
      mockSettingsProvider = MockSettingsProvider();
      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    });

    Widget buildWidget(int genderRate) {
      final testPokemon = Pokemon(
        id: 1,
        nameDe: 'Test',
        nameEn: 'Test',
        hasGenderDifferences: false,
        genderRate: genderRate,
        captureRate: 45,
        evolutionChainId: -1,
        eggGroups: ['Monster'],
        weight: 1.0,
        speed: 1,
        forms: [],
      );

      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<DexProvider>.value(value: mockProvider),
              ChangeNotifierProvider<SettingsProvider>.value(
                value: mockSettingsProvider,
              ),
            ],
            child: BreedingInfoWidget(pokemon: testPokemon),
          ),
        ),
      );
    }

    testWidgets('Rendert Geschlechtslos korrekt (genderRate = -1)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(-1));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.transgender), findsOneWidget);
      expect(
        find.textContaining('Geschlechtslos', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Rendert 50/50 Geschlechter korrekt (genderRate = 4)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(4));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wc), findsOneWidget);
      expect(find.textContaining('50%', findRichText: true), findsWidgets);
    });
  });
}
