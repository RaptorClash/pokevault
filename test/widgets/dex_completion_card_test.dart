import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_card_models.dart';
import 'package:pokevault/models/dex_progress_models.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/widgets/dex_card/dex_completion_card.dart';
import 'package:pokevault/l10n/app_translations.dart';

void main() {
  Pokemon createTestPokemon(int id, String nameDe, String nameEn) {
    return Pokemon(
      id: id,
      nameDe: nameDe,
      nameEn: nameEn,
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
      pokemon: createTestPokemon(id, name, name),
      displaySuffix: '',
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
    );
  }

  final testDex = UserDex(
    id: 'kanto_dex',
    title: 'Kanto Living Dex',
    region: 'kanto',
    includeGenders: false,
    includeRegional: false,
    includeMega: false,
    includeGMax: false,
    includeOther: false,
    isShinyDex: false,
    caughtIds: ['1', '4', '7'],
    shinyIds: ['6'],
    alphaIds: ['143'],
  );

  final testStats = DexProgressStats(
    totalCount: 151,
    caughtCount: 151,
    percentage: 100.0,
    shinyCount: 18,
    alphaCount: 6,
    generationStats: [
      ProgressItem.create(
        key: 'gen_1',
        name: 'Gen 1: Kanto',
        caught: 151,
        total: 151,
        color: const Color(0xFFEF5350),
      ),
    ],
    typeStats: [
      ProgressItem.create(
        key: 'water',
        name: 'Wasser',
        caught: 32,
        total: 32,
        color: const Color(0xFF6390F0),
      ),
      ProgressItem.create(
        key: 'fire',
        name: 'Feuer',
        caught: 12,
        total: 12,
        color: const Color(0xFFEE8130),
      ),
    ],
    variantStats: [],
  );

  final testEntries = [
    createEntry(1, 'Bisasam'),
    createEntry(4, 'Glumanda'),
    createEntry(6, 'Glurak'),
    createEntry(7, 'Schiggy'),
  ];

  Widget buildCardWidget({
    required DexCardConfig config,
    UserDex? dex,
    DexProgressStats? stats,
    List<DexDisplayEntry>? entries,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: DexCompletionCard(
            dex: dex ?? testDex,
            stats: stats ?? testStats,
            entries: entries ?? testEntries,
            config: config,
          ),
        ),
      ),
    );
  }

  group('DexCompletionCard Widget Tests', () {
    testWidgets('Renders Style 1: The Analyst without overflow', (tester) async {
      final config = DexCardConfig(
        style: DexCardStyle.analyst,
        ratio: DexCardRatio.landscape16_9,
        watermarkPokemon: const DexCardPokemonWatermark(
          pokemonId: 6,
          name: 'Glurak',
          imageUrl: 'https://example.com/6.png',
        ),
      );

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCardWidget(config: config));
      await tester.pumpAndSettle();

      expect(find.text('Kanto Living Dex'), findsOneWidget);
      expect(find.text('151 / 151 Gefangen'), findsWidgets);
      expect(find.text('Shinies'), findsOneWidget);
      expect(find.text('Alphas'), findsOneWidget);
    });

    testWidgets('Renders Style 2: Trainer Certificate without overflow', (tester) async {
      final config = DexCardConfig(
        style: DexCardStyle.certificate,
        ratio: DexCardRatio.landscape16_9,
      );

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCardWidget(config: config));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offizielles Pokédex-Diplom'), findsOneWidget);
      expect(find.text('Kanto Living Dex Zertifikat'), findsOneWidget);
      expect(find.text('Gefangen'), findsOneWidget);
      expect(find.text('Shiny Funde'), findsOneWidget);
      expect(find.text('Champion-Siegel ★★★★★'), findsOneWidget);
    });

    testWidgets('Renders Style 3: Living Dex Mosaic with cells without overflow', (tester) async {
      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        ratio: DexCardRatio.landscape16_9,
      );

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCardWidget(config: config));
      await tester.pumpAndSettle();

      expect(find.text('LIVING DEX VISUAL GRID'), findsOneWidget);
      expect(find.text('Kanto Living Dex Kachel-Mosaik'), findsOneWidget);
      expect(find.byKey(const Key('mosaic_grid')), findsOneWidget);
    });

    testWidgets('Renders Style 4: Minimalist Glass without overflow', (tester) async {
      final config = DexCardConfig(
        style: DexCardStyle.minimalist,
        ratio: DexCardRatio.landscape16_9,
      );

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCardWidget(config: config));
      await tester.pumpAndSettle();

      expect(find.text('Kanto Living Dex'), findsOneWidget);
      expect(find.text('POKEVAULT PROGRESS SUMMARY'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('Renders in 1:1 Square and 9:16 Story format without overflow', (tester) async {
      for (final ratio in [DexCardRatio.square1_1, DexCardRatio.portrait9_16]) {
        final config = DexCardConfig(
          style: DexCardStyle.analyst,
          ratio: ratio,
        );

        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(buildCardWidget(config: config));
        await tester.pumpAndSettle();

        expect(find.text('Kanto Living Dex'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('Adversarial Test: Small Screen 320x480 Mobile without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      for (final style in DexCardStyle.values) {
        final config = DexCardConfig(
          style: style,
          ratio: DexCardRatio.landscape16_9,
        );

        await tester.pumpWidget(buildCardWidget(config: config));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Adversarial Test: Empty dex (0% complete, 0 pokemon) renders cleanly', (tester) async {
      final emptyDex = UserDex(
        id: 'empty',
        title: 'Empty Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      final emptyStats = DexProgressStats.empty();

      final config = DexCardConfig(style: DexCardStyle.analyst);

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: emptyDex,
        stats: emptyStats,
        entries: [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Empty Dex'), findsOneWidget);
      expect(find.text('0 / 0 Gefangen'), findsWidgets);
    });

    testWidgets('Adversarial Test: Ultra long dex title is truncated/wrapped gracefully', (tester) async {
      final longDex = UserDex(
        id: 'long',
        title: 'Ultra Mega Hyper Complete Kanto Galar Alola Paldea Master Living Dex Edition 2026',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      final config = DexCardConfig(style: DexCardStyle.certificate);

      await tester.pumpWidget(buildCardWidget(config: config, dex: longDex));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders custom trainer note when configured', (tester) async {
      final config = DexCardConfig(
        style: DexCardStyle.analyst,
        customTrainerNote: 'OT: Trainer Red #00001',
      );

      await tester.pumpWidget(buildCardWidget(config: config));
      await tester.pumpAndSettle();

      expect(find.text('OT: Trainer Red #00001'), findsOneWidget);
    });

    testWidgets('Fixes generation breakdown fraction wrapping: 170/421 has maxLines 1 and adequate width', (tester) async {
      final customStats = DexProgressStats(
        totalCount: 421,
        caughtCount: 170,
        percentage: 40.38,
        shinyCount: 12,
        alphaCount: 4,
        generationStats: [
          ProgressItem.create(
            key: 'gen_1',
            name: 'Gen 1: Kanto',
            caught: 170,
            total: 421,
            color: const Color(0xFFEF5350),
          ),
        ],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(style: DexCardStyle.analyst);

      await tester.pumpWidget(buildCardWidget(config: config, stats: customStats));
      await tester.pumpAndSettle();

      final fractionFinder = find.text('170/421');
      expect(fractionFinder, findsOneWidget);

      final Text textWidget = tester.widget(fractionFinder);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('Displays all 9 generations in Analyst Landscape mode without truncating at 3', (tester) async {
      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final nationalStats = DexProgressStats(
        totalCount: 1025,
        caughtCount: 500,
        percentage: 48.78,
        shinyCount: 20,
        alphaCount: 10,
        generationStats: [
          ProgressItem.create(key: 'gen_1', name: 'Gen 1: Kanto', caught: 170, total: 421, color: Colors.red),
          ProgressItem.create(key: 'gen_2', name: 'Gen 2: Johto', caught: 100, total: 214, color: Colors.amber),
          ProgressItem.create(key: 'gen_3', name: 'Gen 3: Hoenn', caught: 159, total: 211, color: Colors.blue),
          ProgressItem.create(key: 'gen_4', name: 'Gen 4: Sinnoh', caught: 11, total: 144, color: Colors.indigo),
          ProgressItem.create(key: 'gen_5', name: 'Gen 5: Einall', caught: 0, total: 172, color: Colors.grey),
          ProgressItem.create(key: 'gen_6', name: 'Gen 6: Kalos', caught: 72, total: 99, color: Colors.purple),
          ProgressItem.create(key: 'gen_7', name: 'Gen 7: Alola', caught: 86, total: 108, color: Colors.orange),
          ProgressItem.create(key: 'gen_8', name: 'Gen 8: Galar', caught: 0, total: 154, color: Colors.cyan),
          ProgressItem.create(key: 'gen_9', name: 'Gen 9: Paldea', caught: 0, total: 124, color: Colors.teal),
        ],
        typeStats: [],
        variantStats: [
          ProgressItem.create(key: 'mega', name: 'Mega-Formen', caught: 10, total: 46),
          ProgressItem.create(key: 'gmax', name: 'Gigadynamax', caught: 5, total: 32),
          ProgressItem.create(key: 'alola', name: 'Alola-Formen', caught: 12, total: 18),
          ProgressItem.create(key: 'galar', name: 'Galar-Formen', caught: 8, total: 19),
        ],
      );

      final config = DexCardConfig(
        style: DexCardStyle.analyst,
        ratio: DexCardRatio.landscape16_9,
        showGenerations: true,
        showVariants: true,
      );

      await tester.pumpWidget(buildCardWidget(config: config, stats: nationalStats));
      await tester.pumpAndSettle();

      // All 9 generations MUST be visible, not just 1-3!
      expect(find.text('Gen 1: Kanto'), findsOneWidget);
      expect(find.text('Gen 2: Johto'), findsOneWidget);
      expect(find.text('Gen 3: Hoenn'), findsOneWidget);
      expect(find.text('Gen 4: Sinnoh'), findsOneWidget);
      expect(find.text('Gen 5: Einall'), findsOneWidget);
      expect(find.text('Gen 6: Kalos'), findsOneWidget);
      expect(find.text('Gen 7: Alola'), findsOneWidget);
      expect(find.text('Gen 8: Galar'), findsOneWidget);
      expect(find.text('Gen 9: Paldea'), findsOneWidget);

      // And all variants must be visible, not cut off at 3!
      expect(find.text('Mega-Formen'), findsOneWidget);
      expect(find.text('Gigadynamax'), findsOneWidget);
      expect(find.text('Alola-Formen'), findsOneWidget);
      expect(find.text('Galar-Formen'), findsOneWidget);
    });

    testWidgets('Toggling showOnlyStartedGenerations hides 0-caught generations', (tester) async {
      final nationalStats = DexProgressStats(
        totalCount: 1025,
        caughtCount: 500,
        percentage: 48.78,
        shinyCount: 20,
        alphaCount: 10,
        generationStats: [
          ProgressItem.create(key: 'gen_1', name: 'Gen 1: Kanto', caught: 170, total: 421),
          ProgressItem.create(key: 'gen_2', name: 'Gen 2: Johto', caught: 100, total: 214),
          ProgressItem.create(key: 'gen_3', name: 'Gen 3: Hoenn', caught: 159, total: 211),
          ProgressItem.create(key: 'gen_4', name: 'Gen 4: Sinnoh', caught: 11, total: 144),
          ProgressItem.create(key: 'gen_5', name: 'Gen 5: Einall', caught: 0, total: 172),
          ProgressItem.create(key: 'gen_6', name: 'Gen 6: Kalos', caught: 72, total: 99),
          ProgressItem.create(key: 'gen_7', name: 'Gen 7: Alola', caught: 86, total: 108),
          ProgressItem.create(key: 'gen_8', name: 'Gen 8: Galar', caught: 0, total: 154),
          ProgressItem.create(key: 'gen_9', name: 'Gen 9: Paldea', caught: 0, total: 124),
        ],
        typeStats: [],
        variantStats: [],
      );

      // 1. showOnlyStartedGenerations: true -> Gen 5, 8, 9 (caught == 0) are hidden
      final startedOnlyConfig = DexCardConfig(
        style: DexCardStyle.analyst,
        showGenerations: true,
        showOnlyStartedGenerations: true,
      );

      await tester.pumpWidget(buildCardWidget(config: startedOnlyConfig, stats: nationalStats));
      await tester.pumpAndSettle();

      expect(find.text('Gen 1: Kanto'), findsOneWidget);
      expect(find.text('Gen 2: Johto'), findsOneWidget);
      expect(find.text('Gen 3: Hoenn'), findsOneWidget);
      expect(find.text('Gen 4: Sinnoh'), findsOneWidget);
      expect(find.text('Gen 5: Einall'), findsNothing);
      expect(find.text('Gen 6: Kalos'), findsOneWidget);
      expect(find.text('Gen 7: Alola'), findsOneWidget);
      expect(find.text('Gen 8: Galar'), findsNothing);
      expect(find.text('Gen 9: Paldea'), findsNothing);

      // 2. showOnlyStartedGenerations: false -> all 9 are shown
      final allGensConfig = DexCardConfig(
        style: DexCardStyle.analyst,
        showGenerations: true,
        showOnlyStartedGenerations: false,
      );

      await tester.pumpWidget(buildCardWidget(config: allGensConfig, stats: nationalStats));
      await tester.pumpAndSettle();

      expect(find.text('Gen 5: Einall'), findsOneWidget);
      expect(find.text('Gen 8: Galar'), findsOneWidget);
      expect(find.text('Gen 9: Paldea'), findsOneWidget);
    });

    testWidgets('Displays all 9 generations in 1:1 Square and 9:16 Portrait without overflow', (tester) async {
      final nationalStats = DexProgressStats(
        totalCount: 1025,
        caughtCount: 500,
        percentage: 48.78,
        shinyCount: 20,
        alphaCount: 10,
        generationStats: [
          ProgressItem.create(key: 'gen_1', name: 'Gen 1: Kanto', caught: 50, total: 100, color: Colors.red),
          ProgressItem.create(key: 'gen_2', name: 'Gen 2: Johto', caught: 50, total: 100, color: Colors.amber),
          ProgressItem.create(key: 'gen_3', name: 'Gen 3: Hoenn', caught: 50, total: 100, color: Colors.blue),
          ProgressItem.create(key: 'gen_4', name: 'Gen 4: Sinnoh', caught: 50, total: 100, color: Colors.purple),
          ProgressItem.create(key: 'gen_5', name: 'Gen 5: Einall', caught: 50, total: 100, color: Colors.grey),
          ProgressItem.create(key: 'gen_6', name: 'Gen 6: Kalos', caught: 50, total: 100, color: Colors.teal),
          ProgressItem.create(key: 'gen_7', name: 'Gen 7: Alola', caught: 50, total: 100, color: Colors.orange),
          ProgressItem.create(key: 'gen_8', name: 'Gen 8: Galar', caught: 50, total: 100, color: Colors.cyan),
          ProgressItem.create(key: 'gen_9', name: 'Gen 9: Paldea', caught: 50, total: 100, color: Colors.indigo),
        ],
        typeStats: [],
        variantStats: [
          ProgressItem.create(key: 'regular', name: 'Standard', caught: 40, total: 80),
          ProgressItem.create(key: 'regional', name: 'Regionalformen', caught: 12, total: 18),
          ProgressItem.create(key: 'mega', name: 'Mega-Entwicklungen', caught: 10, total: 46),
          ProgressItem.create(key: 'gmax', name: 'Gigadynamax', caught: 5, total: 32),
        ],
      );

      for (final ratio in [DexCardRatio.square1_1, DexCardRatio.portrait9_16]) {
        tester.view.physicalSize = ratio.exportDimensions;
        tester.view.devicePixelRatio = 1.0;

        final config = DexCardConfig(
          style: DexCardStyle.analyst,
          ratio: ratio,
          showGenerations: true,
          showVariants: true,
        );

        await tester.pumpWidget(buildCardWidget(config: config, stats: nationalStats));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Gen 1: Kanto'), findsOneWidget);
        expect(find.text('Gen 2: Johto'), findsOneWidget);
        expect(find.text('Gen 3: Hoenn'), findsOneWidget);
        expect(find.text('Gen 4: Sinnoh'), findsOneWidget);
        expect(find.text('Gen 5: Einall'), findsOneWidget);
        expect(find.text('Gen 6: Kalos'), findsOneWidget);
        expect(find.text('Gen 7: Alola'), findsOneWidget);
        expect(find.text('Gen 8: Galar'), findsOneWidget);
        expect(find.text('Gen 9: Paldea'), findsOneWidget);

        expect(find.text('Standard'), findsOneWidget);
        expect(find.text('Regionalformen'), findsOneWidget);
        expect(find.text('Mega-Entwicklungen'), findsOneWidget);
        expect(find.text('Gigadynamax'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('Adversarial Test: Empty generations state and zero-caught filtering', (tester) async {
      // 1. Generation stats empty
      const emptyGensStats = DexProgressStats(
        totalCount: 151,
        caughtCount: 50,
        percentage: 33.1,
        shinyCount: 2,
        alphaCount: 1,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(style: DexCardStyle.analyst, showGenerations: true);
      await tester.pumpWidget(buildCardWidget(config: config, stats: emptyGensStats));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. All generations have 0 caught, and showOnlyStartedGenerations: true
      final zeroCaughtStats = DexProgressStats(
        totalCount: 1000,
        caughtCount: 0,
        percentage: 0.0,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [
          ProgressItem.create(key: 'gen_1', name: 'Gen 1', caught: 0, total: 151),
          ProgressItem.create(key: 'gen_2', name: 'Gen 2', caught: 0, total: 100),
        ],
        typeStats: [],
        variantStats: [],
      );

      final startedOnlyConfig = DexCardConfig(
        style: DexCardStyle.analyst,
        showGenerations: true,
        showOnlyStartedGenerations: true,
      );

      await tester.pumpWidget(buildCardWidget(config: startedOnlyConfig, stats: zeroCaughtStats));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Gen 1'), findsNothing);
    });

    testWidgets('Generations card renders all generations stacked vertically in a single column', (tester) async {
      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final nineGenStats = DexProgressStats(
        totalCount: 900,
        caughtCount: 450,
        percentage: 50.0,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: List.generate(
          9,
          (i) => ProgressItem.create(
            key: 'gen_${i + 1}',
            name: 'Gen ${i + 1}',
            caught: 50,
            total: 100,
            color: Colors.blue,
          ),
        ),
        typeStats: [],
        variantStats: [],
      );

      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final config = DexCardConfig(style: DexCardStyle.analyst);
      await tester.pumpWidget(buildCardWidget(config: config, stats: nineGenStats));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify all 9 generations are rendered
      for (int i = 1; i <= 9; i++) {
        expect(find.text('Gen $i'), findsOneWidget);
      }

      // Verify all 9 generations are strictly vertically stacked under each other
      for (int i = 1; i < 9; i++) {
        final topGen = tester.getTopLeft(find.text('Gen $i')).dy;
        final nextGen = tester.getTopLeft(find.text('Gen ${i + 1}')).dy;
        expect(topGen, lessThan(nextGen),
            reason: 'Gen $i must be vertically above Gen ${i + 1} in single column');
      }

      // Verify 9 generations distribute to fill the card height harmoniously without leaving a dark empty void
      final totalVerticalSpan = tester.getTopLeft(find.text('Gen 9')).dy - tester.getTopLeft(find.text('Gen 1')).dy;
      expect(totalVerticalSpan, greaterThan(350),
          reason: '9 stacked generations must distribute harmoniously across the card height');
    });

    testWidgets('Type coverage displays chips according to typeDisplayLimit (default 18, 6, 12)', (tester) async {
      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final all18TypeStats = DexProgressStats(
        totalCount: 180,
        caughtCount: 90,
        percentage: 50.0,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: List.generate(
          18,
          (i) => ProgressItem.create(
            key: 'type_${i + 1}',
            name: 'Typ ${i + 1}',
            caught: 5,
            total: 10,
            color: Colors.indigo,
          ),
        ),
        variantStats: [],
      );

      // 1. Default (18): displays all 18 types
      final configDefault = DexCardConfig(style: DexCardStyle.analyst);
      await tester.pumpWidget(buildCardWidget(config: configDefault, stats: all18TypeStats));
      await tester.pumpAndSettle();
      for (int i = 1; i <= 18; i++) {
        expect(find.text('Typ $i: 5/10'), findsOneWidget);
      }

      // 2. Limit 6: displays only first 6 types
      final config6 = DexCardConfig(style: DexCardStyle.analyst, typeDisplayLimit: 6);
      await tester.pumpWidget(buildCardWidget(config: config6, stats: all18TypeStats));
      await tester.pumpAndSettle();
      for (int i = 1; i <= 6; i++) {
        expect(find.text('Typ $i: 5/10'), findsOneWidget);
      }
      expect(find.text('Typ 7: 5/10'), findsNothing);
      expect(find.text('Typ 18: 5/10'), findsNothing);

      // 3. Limit 12: displays first 12 types
      final config12 = DexCardConfig(style: DexCardStyle.analyst, typeDisplayLimit: 12);
      await tester.pumpWidget(buildCardWidget(config: config12, stats: all18TypeStats));
      await tester.pumpAndSettle();
      for (int i = 1; i <= 12; i++) {
        expect(find.text('Typ $i: 5/10'), findsOneWidget);
      }
      expect(find.text('Typ 13: 5/10'), findsNothing);
      expect(find.text('Typ 18: 5/10'), findsNothing);

      // 4. Verify contrast: bright colors (like Electric yellow and Ice cyan) use black text for legibility
      final brightTypeStats = DexProgressStats(
        totalCount: 30,
        caughtCount: 15,
        percentage: 50.0,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: [
          ProgressItem.create(key: 'electric', name: 'Elektro', caught: 5, total: 10, color: const Color(0xFFF7D02C)),
          ProgressItem.create(key: 'ice', name: 'Eis', caught: 3, total: 10, color: const Color(0xFF96D9D6)),
          ProgressItem.create(key: 'water', name: 'Wasser', caught: 8, total: 10, color: const Color(0xFF6390F0)),
        ],
        variantStats: [],
      );
      await tester.pumpWidget(buildCardWidget(config: configDefault, stats: brightTypeStats));
      await tester.pumpAndSettle();

      final elektroText = tester.widget<Text>(find.text('Elektro: 5/10'));
      expect(elektroText.style?.color, equals(Colors.black));

      final eisText = tester.widget<Text>(find.text('Eis: 3/10'));
      expect(eisText.style?.color, equals(Colors.black));

      final wasserText = tester.widget<Text>(find.text('Wasser: 8/10'));
      expect(wasserText.style?.color, equals(Colors.white));
    });

    testWidgets('Adversarial Test: Language switch DE <-> EN updates generation header and labels', (tester) async {
      final statsWithGens = DexProgressStats(
        totalCount: 151,
        caughtCount: 100,
        percentage: 66.2,
        shinyCount: 5,
        alphaCount: 2,
        generationStats: [
          ProgressItem.create(key: 'gen_1', name: 'Gen 1: Kanto', caught: 100, total: 151),
        ],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(style: DexCardStyle.analyst);

      // DE mode
      Translator.currentLanguage = 'de';
      await tester.pumpWidget(buildCardWidget(config: config, stats: statsWithGens));
      await tester.pumpAndSettle();
      expect(find.text('GENERATIONEN'), findsOneWidget);

      // EN mode
      Translator.currentLanguage = 'en';
      await tester.pumpWidget(buildCardWidget(config: config, stats: statsWithGens));
      await tester.pumpAndSettle();
      expect(find.text('GENERATIONS'), findsOneWidget);

      // Reset
      Translator.currentLanguage = 'de';
    });

    testWidgets('Toggles Variant Breakdown according to showVariants config', (tester) async {
      final variantStats = DexProgressStats(
        totalCount: 151,
        caughtCount: 151,
        percentage: 100.0,
        shinyCount: 10,
        alphaCount: 5,
        generationStats: [],
        typeStats: [],
        variantStats: [
          ProgressItem.create(
            key: 'mega',
            name: 'Mega-Formen',
            caught: 5,
            total: 46,
            color: const Color(0xFF9333EA),
          ),
        ],
      );

      // 1. showVariants: true -> renders 'Mega-Formen'
      final configWithVariants = DexCardConfig(
        style: DexCardStyle.analyst,
        showVariants: true,
      );
      await tester.pumpWidget(buildCardWidget(config: configWithVariants, stats: variantStats));
      await tester.pumpAndSettle();
      expect(find.text('Mega-Formen'), findsOneWidget);

      // 2. showVariants: false -> does not render 'Mega-Formen'
      final configWithoutVariants = DexCardConfig(
        style: DexCardStyle.analyst,
        showVariants: false,
      );
      await tester.pumpWidget(buildCardWidget(config: configWithoutVariants, stats: variantStats));
      await tester.pumpAndSettle();
      expect(find.text('Mega-Formen'), findsNothing);
    });

    testWidgets('Toggles Special Collections and Box Stats', (tester) async {
      final richDex = UserDex(
        id: 'rich_dex',
        title: 'Master Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtRibbons: {'1': ['champ_ribbon']},
        caughtTeraTypes: {'1': ['stellar']},
        caughtLanguages: {'1': ['jpn']},
      );

      // When enabled, Shinies/Alphas/Boxes are shown
      final configAllOn = DexCardConfig(
        style: DexCardStyle.analyst,
        showSpecialCollections: true,
        showBoxStats: true,
      );
      await tester.pumpWidget(buildCardWidget(config: configAllOn, dex: richDex));
      await tester.pumpAndSettle();
      expect(find.text('Shinies'), findsWidgets);
      expect(find.text('PC-Boxen'), findsWidgets);

      // When toggled off, they are hidden
      final configOff = DexCardConfig(
        style: DexCardStyle.analyst,
        showSpecialCollections: false,
        showBoxStats: false,
      );
      await tester.pumpWidget(buildCardWidget(config: configOff, dex: richDex));
      await tester.pumpAndSettle();
      expect(find.text('Shinies'), findsNothing);
      expect(find.text('PC-Boxen'), findsNothing);
    });

    testWidgets('Toggles PokéVault watermark branding in footer', (tester) async {
      final configWithWatermark = DexCardConfig(
        style: DexCardStyle.analyst,
        showWatermarkLogo: true,
      );
      await tester.pumpWidget(buildCardWidget(config: configWithWatermark));
      await tester.pumpAndSettle();
      expect(find.text('PokéVault'), findsOneWidget);

      final configWithoutWatermark = DexCardConfig(
        style: DexCardStyle.analyst,
        showWatermarkLogo: false,
      );
      await tester.pumpWidget(buildCardWidget(config: configWithoutWatermark));
      await tester.pumpAndSettle();
      expect(find.text('PokéVault'), findsNothing);
    });

    testWidgets('Toggles Completion Date on Certificate and Mosaic cards', (tester) async {
      final configWithDate = DexCardConfig(
        style: DexCardStyle.certificate,
        showDate: true,
        completionDate: DateTime(2026, 10, 21),
      );
      await tester.pumpWidget(buildCardWidget(config: configWithDate));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026'), findsWidgets);

      final configWithoutDate = DexCardConfig(
        style: DexCardStyle.certificate,
        showDate: false,
        completionDate: DateTime(2026, 10, 21),
      );
      await tester.pumpWidget(buildCardWidget(config: configWithoutDate));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026'), findsNothing);

      // Verify Mosaic style also respects showDate
      final configMosaicDate = DexCardConfig(
        style: DexCardStyle.mosaic,
        showDate: true,
        completionDate: DateTime(2026, 10, 21),
      );
      await tester.pumpWidget(buildCardWidget(config: configMosaicDate));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026'), findsWidgets);

      final configMosaicNoDate = DexCardConfig(
        style: DexCardStyle.mosaic,
        showDate: false,
        completionDate: DateTime(2026, 10, 21),
      );
      await tester.pumpWidget(buildCardWidget(config: configMosaicNoDate));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026'), findsNothing);
    });

    testWidgets('Displays Tera types and Language metadata when present in rich dex', (tester) async {
      final richDex = UserDex(
        id: 'rich_dex',
        title: 'Master Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtRibbons: {'1': ['champ_ribbon']},
        caughtTeraTypes: {'1': ['stellar'], '4': ['fire']},
        caughtLanguages: {'1': ['jpn'], '4': ['fre']},
      );

      final config = DexCardConfig(
        style: DexCardStyle.analyst,
        showSpecialCollections: true,
      );
      await tester.pumpWidget(buildCardWidget(config: config, dex: richDex));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tera'), findsWidgets);
      expect(find.textContaining('Sprachen'), findsWidgets);
    });

    testWidgets('Box details includes full boxes, partial boxes, and gaps info', (tester) async {
      final config = DexCardConfig(
        style: DexCardStyle.analyst,
        showBoxStats: true,
      );
      await tester.pumpWidget(buildCardWidget(config: config));
      await tester.pumpAndSettle();

      // For 151 caught out of 151: 5 full boxes, 1 partial box (1 pokemon), 0 gaps
      expect(find.textContaining('voll'), findsWidgets);
      expect(find.textContaining('teilw.'), findsWidgets);
    });

    testWidgets('Adversarial Test: National Dex with 9 generations, 4 variants and all toggles enabled in all ratios without overflow', (tester) async {
      final nationalStats = DexProgressStats(
        totalCount: 1025,
        caughtCount: 890,
        percentage: 86.83,
        shinyCount: 140,
        alphaCount: 35,
        generationStats: List.generate(
          9,
          (i) => ProgressItem.create(
            key: 'gen_${i + 1}',
            name: 'Gen ${i + 1}',
            caught: 100,
            total: 114,
            color: Colors.blue,
          ),
        ),
        typeStats: List.generate(
          18,
          (i) => ProgressItem.create(
            key: 'type_$i',
            name: 'Type $i',
            caught: 50,
            total: 60,
            color: Colors.red,
          ),
        ),
        variantStats: [
          ProgressItem.create(key: 'mega', name: 'Mega', caught: 46, total: 46),
          ProgressItem.create(key: 'gmax', name: 'Gigadynamax', caught: 30, total: 32),
          ProgressItem.create(key: 'alola', name: 'Alola-Formen', caught: 18, total: 18),
          ProgressItem.create(key: 'galar', name: 'Galar-Formen', caught: 15, total: 19),
        ],
      );

      final richDex = UserDex(
        id: 'national_dex',
        title: 'National Living Dex Complete Master Edition',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        caughtRibbons: {'1': ['champ']},
        caughtTeraTypes: {'1': ['stellar']},
        caughtLanguages: {'1': ['jpn']},
      );

      final config = DexCardConfig(
        showGenerations: true,
        showVariants: true,
        showTypes: true,
        showSpecialCollections: true,
        showBoxStats: true,
        showDate: true,
        showWatermarkLogo: true,
        customTrainerNote: 'Trainer Marvin • Pokémon HOME',
      );

      for (final style in DexCardStyle.values) {
        for (final ratio in DexCardRatio.values) {
          tester.view.physicalSize = ratio.exportDimensions;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(buildCardWidget(
            config: config.copyWith(style: style, ratio: ratio),
            dex: richDex,
            stats: nationalStats,
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('FittedBox and adequate label widths prevent text truncation on long generation and variant names', (tester) async {
      final nationalStats = DexProgressStats(
        totalCount: 1450,
        caughtCount: 598,
        percentage: 41.24,
        shinyCount: 20,
        alphaCount: 10,
        generationStats: [
          ProgressItem.create(key: 'gen_1', name: 'Gen 1: Kanto', caught: 170, total: 421, color: Colors.red),
          ProgressItem.create(key: 'gen_2', name: 'Gen 2: Johto', caught: 100, total: 214, color: Colors.amber),
          ProgressItem.create(key: 'gen_3', name: 'Gen 3: Hoenn', caught: 159, total: 211, color: Colors.blue),
          ProgressItem.create(key: 'gen_4', name: 'Gen 4: Sinnoh', caught: 11, total: 144, color: Colors.purple),
          ProgressItem.create(key: 'gen_5', name: 'Gen 5: Einall', caught: 0, total: 172, color: Colors.grey),
          ProgressItem.create(key: 'gen_6', name: 'Gen 6: Kalos', caught: 72, total: 99, color: Colors.teal),
          ProgressItem.create(key: 'gen_7', name: 'Gen 7: Alola', caught: 86, total: 108, color: Colors.orange),
          ProgressItem.create(key: 'gen_8', name: 'Gen 8: Galar', caught: 0, total: 154, color: Colors.cyan),
          ProgressItem.create(key: 'gen_9', name: 'Gen 9: Paldea', caught: 0, total: 124, color: Colors.indigo),
        ],
        typeStats: [],
        variantStats: [
          ProgressItem.create(key: 'regular', name: 'Standard', caught: 550, total: 1200),
          ProgressItem.create(key: 'regional', name: 'Regionalformen', caught: 25, total: 55),
          ProgressItem.create(key: 'mega', name: 'Mega-Entwicklungen', caught: 15, total: 46),
          ProgressItem.create(key: 'gmax', name: 'Gigadynamax', caught: 8, total: 32),
        ],
      );

      final config = DexCardConfig(
        style: DexCardStyle.analyst,
        ratio: DexCardRatio.landscape16_9,
        showGenerations: true,
        showVariants: true,
      );

      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCardWidget(config: config, stats: nationalStats));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify that every generation and variant uses FittedBox with BoxFit.scaleDown
      final fittedBoxes = tester.widgetList<FittedBox>(find.byType(FittedBox));
      expect(fittedBoxes.any((fb) => fb.fit == BoxFit.scaleDown), isTrue);

      // Verify exact full names are present in the widget tree
      expect(find.text('Gen 4: Sinnoh'), findsOneWidget);
      expect(find.text('Gen 9: Paldea'), findsOneWidget);
      expect(find.text('Mega-Entwicklungen'), findsOneWidget);
      expect(find.text('Regionalformen'), findsOneWidget);
      expect(find.text('Gigadynamax'), findsOneWidget);
    });

    testWidgets('Mosaic Mode (Pokemon): Renders all 1929 entries via CustomPaint without any truncation', (tester) async {
      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Create 1929 entries
      final national1929Entries = List.generate(
        1929,
        (i) => createEntry(i + 1, 'Pokemon ${i + 1}'),
      );

      final largeDex = UserDex(
        id: 'nat_1929',
        title: 'Complete National Living Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        caughtIds: ['1', '2', '3', '4', '5'],
        shinyIds: ['3'],
        alphaIds: ['5'],
      );

      const stats1929 = DexProgressStats(
        totalCount: 1929,
        caughtCount: 5,
        percentage: (5 / 1929) * 100,
        shinyCount: 1,
        alphaCount: 1,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        ratio: DexCardRatio.landscape16_9,
        mosaicMode: DexMosaicMode.pokemon,
      );

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: largeDex,
        stats: stats1929,
        entries: national1929Entries,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify that CustomPaint is used instead of a clipped GridView
      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('mosaic_grid')),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsWidgets);

      // Extract painter and verify ALL 1929 colors are present
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder.first);
      final dynamic painter = customPaintWidget.painter;
      expect(painter, isNotNull);
      expect(painter.itemColors.length, 1929);

      // Verify specific colors:
      // index 0: '1' -> caught, not shiny/alpha -> Emerald 0xFF10B981
      expect(painter.itemColors[0], equals(const Color(0xFF10B981)));
      // index 2: '3' -> shiny -> Gold 0xFFF59E0B
      expect(painter.itemColors[2], equals(const Color(0xFFF59E0B)));
      // index 4: '5' -> alpha -> Red 0xFFEF4444
      expect(painter.itemColors[4], equals(const Color(0xFFEF4444)));
      // index 10: '11' -> uncaught -> Slate 0xFF1E293B
      expect(painter.itemColors[10], equals(const Color(0xFF1E293B)));

      // Verify legend contains Caught (5), Shiny (1), Alpha (1), Missing (1924)
      expect(find.textContaining('Gefangen (5)'), findsOneWidget);
      expect(find.textContaining('Shiny (1)'), findsOneWidget);
      expect(find.textContaining('Alpha (1)'), findsOneWidget);
      expect(find.textContaining('Fehlend (1924)'), findsOneWidget);
      expect(find.textContaining('1929 Pokémon'), findsOneWidget);
    });

    testWidgets('Mosaic Mode (Boxes): Renders exactly 65 PC boxes for 1929 items with box completeness colors', (tester) async {
      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final national1929Entries = List.generate(
        1929,
        (i) => createEntry(i + 1, 'Pokemon ${i + 1}'),
      );

      // Box 1 (1-30) full: 30 caught
      // Box 2 (31-60) partial: 10 caught
      // Boxes 3-65 empty: 0 caught
      final caughtIds = <String>[
        for (int i = 1; i <= 30; i++) '$i',
        for (int i = 31; i <= 40; i++) '$i',
      ];

      final dex = UserDex(
        id: 'nat_boxes',
        title: 'Boxes Living Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        caughtIds: caughtIds,
      );

      const stats = DexProgressStats(
        totalCount: 1929,
        caughtCount: 40,
        percentage: (40 / 1929) * 100,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        ratio: DexCardRatio.landscape16_9,
        mosaicMode: DexMosaicMode.boxes,
      );

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: dex,
        stats: stats,
        entries: national1929Entries,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('mosaic_grid')),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsWidgets);

      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder.first);
      final dynamic painter = customPaintWidget.painter;
      // 1929 / 30 ceil = 65 boxes
      expect(painter.itemColors.length, 65);

      // Box 0: full -> Emerald 0xFF10B981
      expect(painter.itemColors[0], equals(const Color(0xFF10B981)));
      // Box 1: partial -> Sky Blue 0xFF38BDF8
      expect(painter.itemColors[1], equals(const Color(0xFF38BDF8)));
      // Box 2: empty -> Slate 0xFF1E293B
      expect(painter.itemColors[2], equals(const Color(0xFF1E293B)));

      // Legend in Boxes mode
      expect(find.textContaining('Volle Boxen (1)'), findsOneWidget);
      expect(find.textContaining('Angefangene (1)'), findsOneWidget);
      expect(find.textContaining('Leere (63)'), findsOneWidget);
      expect(find.textContaining('65 Boxen'), findsOneWidget);
    });

    testWidgets('Mosaic Edge Cases: 0 entries and 1 entry render cleanly without error', (tester) async {
      // 0 entries
      final config = DexCardConfig(style: DexCardStyle.mosaic);
      await tester.pumpWidget(buildCardWidget(
        config: config,
        entries: [],
        stats: const DexProgressStats(
          totalCount: 0,
          caughtCount: 0,
          percentage: 0,
          shinyCount: 0,
          alphaCount: 0,
          generationStats: [],
          typeStats: [],
          variantStats: [],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('0 Pokémon'), findsOneWidget);

      // 1 entry
      final singleEntry = [createEntry(1, 'Bisasam')];
      await tester.pumpWidget(buildCardWidget(
        config: config,
        entries: singleEntry,
        stats: const DexProgressStats(
          totalCount: 1,
          caughtCount: 1,
          percentage: 100,
          shinyCount: 0,
          alphaCount: 0,
          generationStats: [],
          typeStats: [],
          variantStats: [],
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Adversarial Test: 100% complete National Dex (1929 items) in Boxes Mode marks final box 65 as FULL and green', (tester) async {
      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final national1929Entries = List.generate(
        1929,
        (i) => createEntry(i + 1, 'Pokemon ${i + 1}'),
      );

      // All 1929 caught
      final caughtIds = [for (int i = 1; i <= 1929; i++) '$i'];

      final dex = UserDex(
        id: 'nat_100',
        title: 'Complete Living Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        caughtIds: caughtIds,
      );

      const stats = DexProgressStats(
        totalCount: 1929,
        caughtCount: 1929,
        percentage: 100.0,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        ratio: DexCardRatio.landscape16_9,
        mosaicMode: DexMosaicMode.boxes,
      );

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: dex,
        stats: stats,
        entries: national1929Entries,
      ));
      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('mosaic_grid')),
        matching: find.byType(CustomPaint),
      );
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder.first);
      final dynamic painter = customPaintWidget.painter;

      expect(painter.itemColors.length, 65);
      // All 65 boxes must be Emerald (0xFF10B981) - including box 65 with 9 items!
      for (int i = 0; i < 65; i++) {
        expect(painter.itemColors[i], equals(const Color(0xFF10B981)),
            reason: 'Box index $i must be full (Emerald)');
      }

      // Legend must report 65 Full, 0 Partial, 0 Empty
      expect(find.textContaining('Volle Boxen (65)'), findsOneWidget);
      expect(find.textContaining('Angefangene (0)'), findsOneWidget);
      expect(find.textContaining('Leere (0)'), findsOneWidget);
      expect(find.textContaining('65 Boxen (1929/1929 Pokémon)'), findsOneWidget);
    });

    testWidgets('Adversarial Test: 100% complete Kanto Dex (151 items) in Boxes Mode marks box 6 (1 item) as FULL', (tester) async {
      tester.view.physicalSize = DexCardRatio.landscape16_9.exportDimensions;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final kanto151Entries = List.generate(
        151,
        (i) => createEntry(i + 1, 'Pokemon ${i + 1}'),
      );

      final caughtIds = [for (int i = 1; i <= 151; i++) '$i'];

      final dex = UserDex(
        id: 'kanto_100',
        title: 'Kanto 151',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: caughtIds,
      );

      const stats = DexProgressStats(
        totalCount: 151,
        caughtCount: 151,
        percentage: 100.0,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        ratio: DexCardRatio.landscape16_9,
        mosaicMode: DexMosaicMode.boxes,
      );

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: dex,
        stats: stats,
        entries: kanto151Entries,
      ));
      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('mosaic_grid')),
        matching: find.byType(CustomPaint),
      );
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder.first);
      final dynamic painter = customPaintWidget.painter;

      expect(painter.itemColors.length, 6);
      expect(painter.itemColors[5], equals(const Color(0xFF10B981)),
          reason: 'Box 6 (holding Mew #151) must be full');

      expect(find.textContaining('Volle Boxen (6)'), findsOneWidget);
      expect(find.textContaining('Angefangene (0)'), findsOneWidget);
      expect(find.textContaining('Leere (0)'), findsOneWidget);
    });

    testWidgets('Adversarial Test: Empty entries list fallback still synchronizes painter and legend', (tester) async {
      final dex = UserDex(
        id: 'fallback_dex',
        title: 'Fallback Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: [],
      );

      const stats = DexProgressStats(
        totalCount: 151,
        caughtCount: 65, // 2 full boxes (60), 1 partial box (5), 3 empty boxes
        percentage: (65 / 151) * 100,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        mosaicMode: DexMosaicMode.boxes,
      );

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: dex,
        stats: stats,
        entries: [],
      ));
      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('mosaic_grid')),
        matching: find.byType(CustomPaint),
      );
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder.first);
      final dynamic painter = customPaintWidget.painter;

      expect(painter.itemColors.length, 6);
      expect(painter.itemColors[0], equals(const Color(0xFF10B981))); // Full
      expect(painter.itemColors[1], equals(const Color(0xFF10B981))); // Full
      expect(painter.itemColors[2], equals(const Color(0xFF38BDF8))); // Partial
      expect(painter.itemColors[3], equals(const Color(0xFF1E293B))); // Empty
      expect(painter.itemColors[4], equals(const Color(0xFF1E293B))); // Empty
      expect(painter.itemColors[5], equals(const Color(0xFF1E293B))); // Empty

      expect(find.textContaining('Volle Boxen (2)'), findsOneWidget);
      expect(find.textContaining('Angefangene (1)'), findsOneWidget);
      expect(find.textContaining('Leere (3)'), findsOneWidget);
    });

    testWidgets('Adversarial Test: showSpecialCollections=false paints Shinies/Alphas as Emerald in Pokémon Mosaic Mode', (tester) async {
      final entries = [
        createEntry(1, 'Bisasam'),
        createEntry(2, 'Bisaknosp'),
      ];

      final dex = UserDex(
        id: 'special_test',
        title: 'Special Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1', '2'],
        shinyIds: ['1'],
        alphaIds: ['2'],
      );

      const stats = DexProgressStats(
        totalCount: 2,
        caughtCount: 2,
        percentage: 100,
        shinyCount: 1,
        alphaCount: 1,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        mosaicMode: DexMosaicMode.pokemon,
        showSpecialCollections: false,
      );

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: dex,
        stats: stats,
        entries: entries,
      ));
      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('mosaic_grid')),
        matching: find.byType(CustomPaint),
      );
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder.first);
      final dynamic painter = customPaintWidget.painter;

      // Both should be Emerald (0xFF10B981) because special collections is disabled
      expect(painter.itemColors[0], equals(const Color(0xFF10B981)));
      expect(painter.itemColors[1], equals(const Color(0xFF10B981)));
    });

    testWidgets('Adversarial Test: Legend swatch color for Missing and Empty uses Color(0xFF1E293B) matching grid tiles', (tester) async {
      // 1. Pokémon Mode with missing entries
      final entries = [
        createEntry(1, 'Bisasam'),
        createEntry(2, 'Bisaknosp'),
      ];

      final dex = UserDex(
        id: 'missing_swatch_test',
        title: 'Missing Swatch Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1'], // #1 caught, #2 missing
      );

      const stats = DexProgressStats(
        totalCount: 2,
        caughtCount: 1,
        percentage: 50,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final configPokemon = DexCardConfig(
        style: DexCardStyle.mosaic,
        mosaicMode: DexMosaicMode.pokemon,
      );

      await tester.pumpWidget(buildCardWidget(
        config: configPokemon,
        dex: dex,
        stats: stats,
        entries: entries,
      ));
      await tester.pumpAndSettle();

      // Find the legend item for "Fehlend (1)"
      final missingTextFinder = find.textContaining('Fehlend (1)');
      expect(missingTextFinder, findsOneWidget);

      final missingRowFinder = find.ancestor(
        of: missingTextFinder,
        matching: find.byType(Row),
      );
      final containerFinder = find.descendant(
        of: missingRowFinder,
        matching: find.byType(Container),
      );
      final containerWidget = tester.widget<Container>(containerFinder.first);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF1E293B)),
          reason: 'Legend swatch for missing Pokémon must match tile color 0xFF1E293B');

      // 2. Boxes Mode with empty boxes
      final configBoxes = DexCardConfig(
        style: DexCardStyle.mosaic,
        mosaicMode: DexMosaicMode.boxes,
      );

      await tester.pumpWidget(buildCardWidget(
        config: configBoxes,
        dex: dex,
        stats: stats,
        entries: entries,
      ));
      await tester.pumpAndSettle();

      final emptyTextFinder = find.textContaining('Leere');
      if (emptyTextFinder.evaluate().isNotEmpty) {
        final emptyRowFinder = find.ancestor(
          of: emptyTextFinder,
          matching: find.byType(Row),
        );
        final emptyContainerFinder = find.descendant(
          of: emptyRowFinder,
          matching: find.byType(Container),
        );
        final emptyBoxDecoration =
            tester.widget<Container>(emptyContainerFinder.first).decoration as BoxDecoration;
        expect(emptyBoxDecoration.color, equals(const Color(0xFF1E293B)),
            reason: 'Legend swatch for empty boxes must match tile color 0xFF1E293B');
      }
    });

    testWidgets('Adversarial Test: Custom boxes with capacity=0 evaluates fullBoxes correctly and uniformly', (tester) async {
      final customBox = CustomBoxState(
        title: 'Special Box',
        columns: 0,
        rows: 0, // Unset / zero capacity (capacity = 0)
        pokemonIds: ['1', '2', '3'],
      );

      final dex = UserDex(
        id: 'custom_dex',
        title: 'Custom Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1', '2', '3'], // All 3 caught
        customBoxes: [customBox],
      );

      const stats = DexProgressStats(
        totalCount: 3,
        caughtCount: 3,
        percentage: 100,
        shinyCount: 0,
        alphaCount: 0,
        generationStats: [],
        typeStats: [],
        variantStats: [],
      );

      final config = DexCardConfig(
        style: DexCardStyle.mosaic,
        mosaicMode: DexMosaicMode.boxes,
      );

      await tester.pumpWidget(buildCardWidget(
        config: config,
        dex: dex,
        stats: stats,
        entries: [
          createEntry(1, 'Bisasam'),
          createEntry(2, 'Bisaknosp'),
          createEntry(3, 'Bisaflor'),
        ],
      ));
      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('mosaic_grid')),
        matching: find.byType(CustomPaint),
      );
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder.first);
      final dynamic painter = customPaintWidget.painter;

      // Single box should be Full -> Emerald 0xFF10B981
      expect(painter.itemColors.length, 1);
      expect(painter.itemColors[0], equals(const Color(0xFF10B981)));

      expect(find.textContaining('Volle Boxen (1)'), findsOneWidget);
      expect(find.textContaining('Angefangene (0)'), findsOneWidget);
      expect(find.textContaining('Leere (0)'), findsOneWidget);
    });
  });
}
