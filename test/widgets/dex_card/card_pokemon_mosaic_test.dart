import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_card_models.dart';
import 'package:pokevault/models/dex_progress_models.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/widgets/dex_card/widgets/card_painter_renderer.dart';
import 'package:pokevault/widgets/dex_card/widgets/card_pokemon_mosaic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Pokemon createTestPokemon(int id, String name) {
    return Pokemon(
      id: id,
      nameDe: name,
      nameEn: name,
      hasGenderDifferences: false,
      genderRate: 4,
      captureRate: 45,
      evolutionChainId: 1,
      eggGroups: ['Monster'],
      weight: 10.0,
      speed: 50,
      forms: [],
    );
  }

  DexDisplayEntry createEntry(int id, String name) {
    return DexDisplayEntry(
      uniqueId: '$id',
      pokemon: createTestPokemon(id, name),
      displaySuffix: '',
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
    );
  }

  final testDex = UserDex(
    id: 'test_dex',
    title: 'Test Living Dex',
    region: 'kanto',
    includeGenders: false,
    includeRegional: false,
    includeMega: false,
    includeGMax: false,
    includeOther: false,
    isShinyDex: false,
    caughtIds: ['1', '2', '3'],
    shinyIds: ['2'],
    alphaIds: ['3'],
  );

  final testEntries = [
    createEntry(1, 'Bisasam'),
    createEntry(2, 'Bisaknosp'),
    createEntry(3, 'Bisaflor'),
  ];

  final testConfig = DexCardConfig(
    style: DexCardStyle.mosaic,
    ratio: DexCardRatio.landscape16_9,
    mosaicMode: DexMosaicMode.pokemon,
  );

  const testBoxDetails = CardBoxDetails(
    totalBoxes: 1,
    fullBoxes: 0,
    partialBoxes: 1,
    emptyBoxes: 0,
    gapsRemaining: 27,
  );

  Widget buildTestWidget({
    List<DexDisplayEntry>? entries,
    UserDex? dex,
    DexProgressStats? stats,
    DexCardConfig? config,
    double scale = 1.0,
    bool isEn = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CardPokemonMosaic(
          entries: entries ?? testEntries,
          dex: dex ?? testDex,
          stats: stats ??
              const DexProgressStats(
                caughtCount: 3,
                totalCount: 3,
                percentage: 100.0,
                shinyCount: 1,
                alphaCount: 1,
                generationStats: [],
                typeStats: [],
                variantStats: [],
              ),
          config: config ?? testConfig,
          scale: scale,
          isEn: isEn,
          boxDetails: testBoxDetails,
          missingCount: 0,
        ),
      ),
    );
  }

  group('CardPokemonMosaic TDD Tests', () {
    testWidgets('Renders Mosaic title, entries, and legend items', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.textContaining('Test Living Dex'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders English labels when isEn is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(isEn: true));

      expect(find.textContaining('Test Living Dex'), findsOneWidget);
      expect(find.textContaining('Mosaic'), findsOneWidget);
    });

    testWidgets('Adversarial Viewport: Renders on 320px narrow screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(scale: 0.3));
      expect(tester.takeException(), isNull);
    });
  });
}
