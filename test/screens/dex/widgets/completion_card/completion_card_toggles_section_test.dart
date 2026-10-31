import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_card_models.dart';
import 'package:pokevault/screens/dex/widgets/completion_card/completion_card_toggles_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testConfig = DexCardConfig(
    style: DexCardStyle.analyst,
    ratio: DexCardRatio.landscape16_9,
    showGenerations: true,
    showVariants: true,
    showTypes: true,
    showSpecialCollections: true,
    showBoxStats: true,
    showDate: true,
    showWatermarkLogo: true,
    typeDisplayLimit: 6,
  );

  Widget buildTestWidget({
    DexCardConfig? config,
    bool isEn = false,
    ValueChanged<DexCardConfig>? onConfigChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CompletionCardTogglesSection(
            config: config ?? testConfig,
            isEn: isEn,
            onConfigChanged: onConfigChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('CompletionCardTogglesSection TDD Tests', () {
    testWidgets('Renders detail toggles with required keys', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byKey(const Key('toggle_generations')), findsOneWidget);
      expect(find.byKey(const Key('toggle_variants')), findsOneWidget);
      expect(find.byKey(const Key('toggle_types')), findsOneWidget);
      expect(find.byKey(const Key('toggle_special_collections')), findsOneWidget);
      expect(find.byKey(const Key('toggle_box_stats')), findsOneWidget);
      expect(find.byKey(const Key('toggle_date')), findsOneWidget);
      expect(find.byKey(const Key('toggle_watermark_logo')), findsOneWidget);
    });

    testWidgets('Toggling switch triggers onConfigChanged', (tester) async {
      DexCardConfig? updated;
      await tester.pumpWidget(buildTestWidget(
        onConfigChanged: (cfg) => updated = cfg,
      ));

      await tester.tap(find.byKey(const Key('toggle_date')));
      expect(updated, isNotNull);
      expect(updated!.showDate, isFalse);
    });

    testWidgets('Shows type limit segment when types toggle is enabled', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byKey(const Key('segment_type_display_limit')), findsOneWidget);
    });

    testWidgets('Adversarial Viewport: Renders on 320px narrow screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      expect(tester.takeException(), isNull);
    });
  });
}
