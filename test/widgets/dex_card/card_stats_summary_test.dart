import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_card_models.dart';
import 'package:pokevault/models/dex_progress_models.dart';
import 'package:pokevault/widgets/dex_card/widgets/card_painter_renderer.dart';
import 'package:pokevault/widgets/dex_card/widgets/card_stats_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    variantStats: [
      ProgressItem.create(
        key: 'forms',
        name: 'Formen',
        caught: 10,
        total: 10,
        color: const Color(0xFF42A5F5),
      ),
    ],
    typeStats: [
      ProgressItem.create(
        key: 'fire',
        name: 'Feuer',
        caught: 12,
        total: 12,
        color: const Color(0xFFFFA726),
      ),
    ],
  );

  final testConfig = DexCardConfig(
    style: DexCardStyle.analyst,
    ratio: DexCardRatio.landscape16_9,
    showDate: true,
    showBoxStats: true,
    mosaicMode: DexMosaicMode.pokemon,
    typeDisplayLimit: 6,
  );

  const testBoxDetails = CardBoxDetails(
    totalBoxes: 5,
    fullBoxes: 5,
    partialBoxes: 0,
    emptyBoxes: 0,
    gapsRemaining: 0,
  );

  const testSpecialStats = CardSpecialStats(
    shinies: 18,
    alphas: 6,
    ribbons: 2,
    teraTypes: 0,
    languages: 1,
  );

  Widget buildTestWidget({
    DexProgressStats? stats,
    DexCardConfig? config,
    double scale = 1.0,
    bool isEn = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CardStatsSummary(
          stats: stats ?? testStats,
          config: config ?? testConfig,
          scale: scale,
          isEn: isEn,
          gaps: 0,
          boxDetails: testBoxDetails,
          specialStats: testSpecialStats,
        ),
      ),
    );
  }

  group('CardStatsSummary TDD Tests', () {
    testWidgets('Renders KPI tiles, progress gauge, and generation stats', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());

      // Progress and percentage
      expect(find.textContaining('100%'), findsWidgets);
      expect(find.textContaining('151'), findsWidgets);

      // KPI row labels or numbers
      expect(find.textContaining('Gen 1: Kanto'), findsOneWidget);
    });

    testWidgets('Renders English labels when isEn is true', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(isEn: true));

      expect(find.textContaining('100%'), findsWidgets);
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
