import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/dex_card_models.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/dex/widgets/dex_completion_card_dialog.dart';
import 'package:pokevault/widgets/dex_card/dex_completion_card.dart';
import 'package:mocktail/mocktail.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
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

  final testEntries = [
    createEntry(1, 'Bisasam'),
    createEntry(4, 'Glumanda'),
    createEntry(6, 'Glurak'),
    createEntry(7, 'Schiggy'),
  ];

  late MockDexProvider mockProvider;

  setUp(() {
    mockProvider = MockDexProvider();
    when(() => mockProvider.userDexes).thenReturn([testDex]);
    when(() => mockProvider.allPokemon).thenReturn([
      createTestPokemon(1, 'Bisasam'),
      createTestPokemon(4, 'Glumanda'),
      createTestPokemon(6, 'Glurak'),
    ]);
  });

  Widget createDialogWrapper({required Widget child}) {
    return ChangeNotifierProvider<DexProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('DexCompletionCardDialog Widget Tests', () {
    testWidgets('Renders preview card, style tabs, controls and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & tabs
      expect(find.text('Erfolgs-Grafik (Living Dex)'), findsOneWidget);
      expect(find.byKey(const Key('tab_analyst')), findsOneWidget);
      expect(find.byKey(const Key('tab_certificate')), findsOneWidget);
      expect(find.byKey(const Key('tab_mosaic')), findsOneWidget);
      expect(find.byKey(const Key('tab_minimalist')), findsOneWidget);

      // Verify action buttons
      expect(find.byKey(const Key('btn_save_png')), findsOneWidget);
      expect(find.byKey(const Key('btn_share')), findsOneWidget);
      expect(find.byKey(const Key('btn_copy_text')), findsOneWidget);
    });

    testWidgets('Tapping style tabs switches card layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Certificate
      await tester.tap(find.byKey(const Key('tab_certificate')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Offizielles Pokédex-Diplom'), findsOneWidget);

      // Switch to Mosaic
      await tester.tap(find.byKey(const Key('tab_mosaic')));
      await tester.pumpAndSettle();
      expect(find.text('LIVING DEX VISUAL GRID'), findsOneWidget);

      // Switch to Minimalist
      await tester.tap(find.byKey(const Key('tab_minimalist')));
      await tester.pumpAndSettle();
      expect(find.text('POKEVAULT PROGRESS SUMMARY'), findsOneWidget);
    });

    testWidgets('Copy text button triggers clipboard and feedback', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_copy_text')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping search watermark button opens search with all pokemon and forms, selecting form updates watermark', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Create Charizard with Mega X form and Rayquaza (Gen 3, not in Kanto testEntries)
      final charizardWithForm = Pokemon(
        id: 6,
        nameDe: 'Glurak',
        nameEn: 'Charizard',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['Monster'],
        weight: 90.5,
        speed: 100,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 6,
            types: ['fire', 'flying'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'mega-x',
            formType: 'mega',
            minGen: 6,
            imageId: 10034,
            types: ['fire', 'dragon'],
            exclusiveRegions: [],
          ),
        ],
      );

      final rayquaza = createTestPokemon(384, 'Rayquaza');

      when(() => mockProvider.allPokemon).thenReturn([
        createTestPokemon(1, 'Bisasam'),
        charizardWithForm,
        rayquaza,
      ]);

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Watermark Search
      await tester.tap(find.byKey(const Key('btn_pick_watermark')));
      await tester.pumpAndSettle();

      // Verify that PokemonSearchSelectionScreen is opened
      expect(find.byType(TextField), findsOneWidget);

      // Verify Rayquaza is present even though testDex is Kanto-only
      expect(find.text('#384'), findsOneWidget);

      // Verify Mega Charizard X form card is present
      expect(find.textContaining('Mega'), findsWidgets);

      // Tap on the Mega Charizard X card or Rayquaza
      await tester.tap(find.text('#384'));
      await tester.pumpAndSettle();

      // Dialog is back and watermark is updated to Rayquaza
      expect(find.text('#384 Rayquaza'), findsOneWidget);
    });

    testWidgets('Selecting "Kein Pokémon" clears watermark and disables opacity slider', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Suchen to open search
      await tester.tap(find.byKey(const Key('btn_pick_watermark')));
      await tester.pumpAndSettle();

      // Tap "Kein Pokémon" button in AppBar
      expect(find.byKey(const Key('select_none_pokemon_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('select_none_pokemon_button')));
      await tester.pumpAndSettle();

      // Watermark is cleared
      expect(find.text('Kein Pokémon (Nur Statistiken)'), findsOneWidget);
      expect(find.text('Wasserzeichen deaktiviert'), findsOneWidget);
    });

    testWidgets('Selecting aspect ratios updates segment selection', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 1:1 Square
      await tester.tap(find.text('1:1 Quadrat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tap 9:16 Story
      await tester.tap(find.text('9:16 Story'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Selecting a Mega form card updates watermark name with form suffix', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final charizardWithForm = Pokemon(
        id: 6,
        nameDe: 'Glurak',
        nameEn: 'Charizard',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 45,
        evolutionChainId: 1,
        eggGroups: ['Monster'],
        weight: 90.5,
        speed: 100,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 1,
            imageId: 6,
            types: ['fire', 'flying'],
            exclusiveRegions: [],
          ),
          PokemonForm(
            name: 'mega-x',
            formType: 'mega',
            minGen: 6,
            imageId: 10034,
            types: ['fire', 'dragon'],
            exclusiveRegions: [],
          ),
        ],
      );

      when(() => mockProvider.allPokemon).thenReturn([
        charizardWithForm,
      ]);

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_pick_watermark')));
      await tester.pumpAndSettle();

      final megaFinder = find.textContaining('Mega');
      expect(megaFinder, findsWidgets);
      await tester.tap(megaFinder.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Glurak'), findsWidgets);
      expect(find.textContaining('Mega'), findsWidgets);
    });

    testWidgets('Tapping zoom button opens interactive zoom lightbox with InteractiveViewer', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final zoomBtn = find.byKey(const Key('btn_zoom_preview'));
      expect(zoomBtn, findsOneWidget);

      await tester.tap(zoomBtn);
      await tester.pumpAndSettle();

      // Lightbox is open and has InteractiveViewer and controls
      expect(find.byKey(const Key('card_zoom_lightbox')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byKey(const Key('btn_zoom_in')), findsOneWidget);
      expect(find.byKey(const Key('btn_zoom_out')), findsOneWidget);
      expect(find.byKey(const Key('btn_zoom_reset')), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Tap Zoom In -> scale increases to 150%
      await tester.tap(find.byKey(const Key('btn_zoom_in')));
      await tester.pumpAndSettle();
      expect(find.text('150%'), findsOneWidget);

      // Tap Reset -> scale returns to 100%
      await tester.tap(find.byKey(const Key('btn_zoom_reset')));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);

      // Close lightbox
      final closeLightboxBtn = find.byKey(const Key('btn_close_lightbox'));
      expect(closeLightboxBtn, findsOneWidget);
      await tester.tap(closeLightboxBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_zoom_lightbox')), findsNothing);
    });

    testWidgets('Entering custom trainer note updates the preview card', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final noteInput = find.byKey(const Key('input_trainer_note'));
      expect(noteInput, findsOneWidget);

      await tester.ensureVisible(noteInput);
      await tester.pumpAndSettle();

      await tester.enterText(noteInput, 'OT: Red #001');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(DexCompletionCard),
          matching: find.text('OT: Red #001'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Card element toggles are rendered and interactive', (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toggle_generations')), findsOneWidget);
      expect(find.byKey(const Key('toggle_variants')), findsOneWidget);
      expect(find.byKey(const Key('toggle_types')), findsOneWidget);
      expect(find.byKey(const Key('toggle_special_collections')), findsOneWidget);
      expect(find.byKey(const Key('toggle_box_stats')), findsOneWidget);
      expect(find.byKey(const Key('toggle_date')), findsOneWidget);
      expect(find.byKey(const Key('toggle_watermark_logo')), findsOneWidget);

      // Scroll to watermark toggle and toggle it off
      await tester.ensureVisible(find.byKey(const Key('toggle_watermark_logo')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_watermark_logo')));
      await tester.pumpAndSettle();

      // In card preview, PokéVault logo watermark should now be hidden
      expect(find.text('• Living Dex Manager'), findsNothing);
    });

    testWidgets('Toggling only started generations filters out 0-caught generations in preview', (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final multiGenDex = UserDex(
        id: 'national_test',
        title: 'National Living Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1'], // Bisasam (Gen 1) caught, Endivie (Gen 2: 152) not caught
      );

      final multiEntries = [
        createEntry(1, 'Bisasam'),
        createEntry(152, 'Endivie'),
      ];

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: multiGenDex,
            entries: multiEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially both Gen 1 and Gen 2 are shown in card preview
      expect(find.text('Gen 1: Kanto'), findsOneWidget);
      expect(find.text('Gen 2: Johto'), findsOneWidget);

      final startedGensToggle = find.byKey(const Key('toggle_only_started_generations'));
      expect(startedGensToggle, findsOneWidget);

      await tester.ensureVisible(startedGensToggle);
      await tester.pumpAndSettle();

      // Toggle ON: hide generations with 0 caught
      await tester.tap(startedGensToggle);
      await tester.pumpAndSettle();

      // Gen 1: Kanto is still shown, but Gen 2: Johto is now hidden!
      expect(find.text('Gen 1: Kanto'), findsOneWidget);
      expect(find.text('Gen 2: Johto'), findsNothing);

      // Toggle OFF: restore all generations
      await tester.tap(startedGensToggle);
      await tester.pumpAndSettle();

      expect(find.text('Gen 1: Kanto'), findsOneWidget);
      expect(find.text('Gen 2: Johto'), findsOneWidget);
    });

    testWidgets('Tapping type display limit segment switches between 6, 12, 18', (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final segmentFinder = find.byKey(const Key('segment_type_display_limit'));
      expect(segmentFinder, findsOneWidget);

      await tester.ensureVisible(segmentFinder);
      await tester.pumpAndSettle();

      // Verify label texts
      expect(find.text('Top 6'), findsOneWidget);
      expect(find.text('Top 12'), findsOneWidget);
      expect(find.text('Alle 18'), findsOneWidget);

      // Default selection should be 18
      var segment = tester.widget<SegmentedButton<int>>(segmentFinder);
      expect(segment.selected, equals({18}));
      var card = tester.widget<DexCompletionCard>(find.byType(DexCompletionCard));
      expect(card.config.typeDisplayLimit, equals(18));

      // Tap Top 6
      await tester.tap(find.text('Top 6'));
      await tester.pumpAndSettle();
      segment = tester.widget<SegmentedButton<int>>(segmentFinder);
      expect(segment.selected, equals({6}));
      card = tester.widget<DexCompletionCard>(find.byType(DexCompletionCard));
      expect(card.config.typeDisplayLimit, equals(6));

      // Tap Top 12
      await tester.tap(find.text('Top 12'));
      await tester.pumpAndSettle();
      segment = tester.widget<SegmentedButton<int>>(segmentFinder);
      expect(segment.selected, equals({12}));
      card = tester.widget<DexCompletionCard>(find.byType(DexCompletionCard));
      expect(card.config.typeDisplayLimit, equals(12));

      // Tap Alle 18
      await tester.tap(find.text('Alle 18'));
      await tester.pumpAndSettle();
      segment = tester.widget<SegmentedButton<int>>(segmentFinder);
      expect(segment.selected, equals({18}));
      card = tester.widget<DexCompletionCard>(find.byType(DexCompletionCard));
      expect(card.config.typeDisplayLimit, equals(18));

      // Toggling types OFF hides the type limit selector
      final typesToggle = find.byKey(const Key('toggle_types'));
      await tester.ensureVisible(typesToggle);
      await tester.tap(typesToggle);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('segment_type_display_limit')), findsNothing);
    });

    testWidgets('Mosaic Mode selector appears when Mosaic style is selected and updates config', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createDialogWrapper(
          child: DexCompletionCardDialog(
            liveDex: testDex,
            entries: testEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially Analyst style: segment_mosaic_mode does not exist
      expect(find.byKey(const Key('segment_mosaic_mode')), findsNothing);

      // Tap Mosaic tab
      await tester.tap(find.byKey(const Key('tab_mosaic')));
      await tester.pumpAndSettle();

      // Now segment_mosaic_mode is visible
      final mosaicSegmentFinder = find.byKey(const Key('segment_mosaic_mode'));
      expect(mosaicSegmentFinder, findsOneWidget);

      // Default selection is pokemon
      var segment = tester.widget<SegmentedButton<DexMosaicMode>>(mosaicSegmentFinder);
      expect(segment.selected, equals({DexMosaicMode.pokemon}));

      // Tap "Kachel pro PC-Box"
      await tester.tap(find.text('Kachel pro PC-Box'));
      await tester.pumpAndSettle();

      segment = tester.widget<SegmentedButton<DexMosaicMode>>(mosaicSegmentFinder);
      expect(segment.selected, equals({DexMosaicMode.boxes}));

      var card = tester.widget<DexCompletionCard>(find.byType(DexCompletionCard));
      expect(card.config.mosaicMode, equals(DexMosaicMode.boxes));

      // Tap back to "Kachel pro Pokémon"
      await tester.tap(find.text('Kachel pro Pokémon'));
      await tester.pumpAndSettle();

      segment = tester.widget<SegmentedButton<DexMosaicMode>>(mosaicSegmentFinder);
      expect(segment.selected, equals({DexMosaicMode.pokemon}));

      card = tester.widget<DexCompletionCard>(find.byType(DexCompletionCard));
      expect(card.config.mosaicMode, equals(DexMosaicMode.pokemon));

      // Switching away to Analyst hides the segment
      await tester.tap(find.byKey(const Key('tab_analyst')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('segment_mosaic_mode')), findsNothing);
    });
  });
}
