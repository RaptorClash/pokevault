import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_card_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/screens/dex/widgets/completion_card/completion_card_appearance_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Pokemon createPokemon(int id, String name) {
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

  final testConfig = DexCardConfig(
    style: DexCardStyle.analyst,
    ratio: DexCardRatio.landscape16_9,
    mosaicMode: DexMosaicMode.pokemon,
  );

  Widget buildTestWidget({
    DexCardConfig? config,
    bool isEn = false,
    ValueChanged<DexCardConfig>? onConfigChanged,
    List<Pokemon>? allPokemon,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CompletionCardAppearanceSection(
            config: config ?? testConfig,
            isEn: isEn,
            onConfigChanged: onConfigChanged ?? (_) {},
            allPokemon: allPokemon ?? [createPokemon(25, 'Pikachu')],
            selectedWatermarkPokemon: null,
            onWatermarkPokemonChanged: (_) {},
          ),
        ),
      ),
    );
  }

  group('CompletionCardAppearanceSection TDD Tests', () {
    testWidgets('Renders all four style tabs and ratio selector', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byKey(const Key('tab_analyst')), findsOneWidget);
      expect(find.byKey(const Key('tab_certificate')), findsOneWidget);
      expect(find.byKey(const Key('tab_mosaic')), findsOneWidget);
      expect(find.byKey(const Key('tab_minimalist')), findsOneWidget);

      expect(find.byKey(const Key('segment_mosaic_mode')), findsNothing);
    });

    testWidgets('Tapping style tab triggers onConfigChanged', (tester) async {
      DexCardConfig? updated;
      await tester.pumpWidget(buildTestWidget(
        onConfigChanged: (cfg) => updated = cfg,
      ));

      await tester.tap(find.byKey(const Key('tab_certificate')));
      expect(updated, isNotNull);
      expect(updated!.style, equals(DexCardStyle.certificate));
    });

    testWidgets('Shows mosaic mode segment when style is mosaic', (tester) async {
      final mosaicConfig = DexCardConfig(
        style: DexCardStyle.mosaic,
        ratio: DexCardRatio.landscape16_9,
        mosaicMode: DexMosaicMode.pokemon,
      );

      await tester.pumpWidget(buildTestWidget(config: mosaicConfig));

      expect(find.byKey(const Key('segment_mosaic_mode')), findsOneWidget);
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
