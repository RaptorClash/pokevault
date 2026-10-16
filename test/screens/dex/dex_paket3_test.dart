import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import 'package:pokevault/screens/dex/pokemon_search_selection.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/screens/dex/box_content_edit_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../e2e/e2e_test_helper.dart';

Pokemon _makePokemon({
  required int id,
  required String nameDe,
  required String nameEn,
  String formName = 'normal',
  String formType = 'normal',
  List<String> types = const ['normal'],
}) {
  return Pokemon(
    id: id,
    nameDe: nameDe,
    nameEn: nameEn,
    hasGenderDifferences: false,
    genderRate: 1,
    captureRate: 45,
    evolutionChainId: 1,
    eggGroups: ['monster'],
    weight: 10.0,
    speed: 50,
    forms: [
      PokemonForm(
        name: formName,
        formType: formType,
        minGen: 1,
        imageId: id,
        types: types,
        exclusiveRegions: [],
      )
    ],
  );
}

DexDisplayEntry _makeEntry({
  required Pokemon pokemon,
  required String uniqueId,
  String displaySuffix = '',
}) {
  return DexDisplayEntry(
    pokemon: pokemon,
    uniqueId: uniqueId,
    displaySuffix: displaySuffix,
    imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  late MockDexProvider mockProvider;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
  });

  group('Paket 3 - PokemonSearchSelectionScreen Tests', () {
    late List<DexDisplayEntry> testEntries;

    setUp(() {
      testEntries = [
        // Kanto (1-151)
        _makeEntry(
          pokemon: _makePokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur', types: ['grass', 'poison']),
          uniqueId: '1_normal',
        ),
        _makeEntry(
          pokemon: _makePokemon(id: 6, nameDe: 'Glurak', nameEn: 'Charizard', types: ['fire', 'flying']),
          uniqueId: '6_normal',
        ),
        _makeEntry(
          pokemon: _makePokemon(id: 6, nameDe: 'Glurak (Mega X)', nameEn: 'Charizard (Mega X)', formName: 'mega-x', formType: 'mega', types: ['fire', 'dragon']),
          uniqueId: '6_mega-x',
          displaySuffix: 'Mega X',
        ),
        _makeEntry(
          pokemon: _makePokemon(id: 6, nameDe: 'Glurak (GMax)', nameEn: 'Charizard (GMax)', formName: 'gmax', formType: 'gmax', types: ['fire', 'flying']),
          uniqueId: '6_gmax',
          displaySuffix: 'G-Max',
        ),
        _makeEntry(
          pokemon: _makePokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu', types: ['electric']),
          uniqueId: '25_normal',
        ),
        _makeEntry(
          pokemon: _makePokemon(id: 37, nameDe: 'Vulpix (Alola)', nameEn: 'Vulpix (Alola)', formName: 'alola', formType: 'regional', types: ['ice']),
          uniqueId: '37_alola',
          displaySuffix: 'Alola',
        ),
        _makeEntry(
          pokemon: _makePokemon(id: 150, nameDe: 'Mewtu (Mega X)', nameEn: 'Mewtwo (Mega X)', formName: 'mega_x', formType: 'mega', types: ['psychic', 'fighting']),
          uniqueId: '150_mega_x',
          displaySuffix: 'Mega X',
        ),
        _makeEntry(
          pokemon: _makePokemon(id: 128, nameDe: 'Tauros (Paldea)', nameEn: 'Tauros (Paldea)', formName: 'paldea_combat_breed', formType: 'regional', types: ['fighting']),
          uniqueId: '128_paldea_combat_breed',
          displaySuffix: 'Paldea',
        ),
        // Johto (152-251)
        _makeEntry(
          pokemon: _makePokemon(id: 152, nameDe: 'Endivie', nameEn: 'Chikorita', types: ['grass']),
          uniqueId: '152_normal',
        ),
        // Hoenn (252-386)
        _makeEntry(
          pokemon: _makePokemon(id: 252, nameDe: 'Geckarbor', nameEn: 'Treecko', types: ['grass']),
          uniqueId: '252_normal',
        ),
        // Sinnoh (387-493)
        _makeEntry(
          pokemon: _makePokemon(id: 387, nameDe: 'Chelast', nameEn: 'Turtwig', types: ['grass']),
          uniqueId: '387_normal',
        ),
        // Einall (494-649)
        _makeEntry(
          pokemon: _makePokemon(id: 494, nameDe: 'Victini', nameEn: 'Victini', types: ['psychic', 'fire']),
          uniqueId: '494_normal',
        ),
        // Kalos (650-721)
        _makeEntry(
          pokemon: _makePokemon(id: 650, nameDe: 'Igamaro', nameEn: 'Chespin', types: ['grass']),
          uniqueId: '650_normal',
        ),
        // Alola (722-809)
        _makeEntry(
          pokemon: _makePokemon(id: 722, nameDe: 'Bauz', nameEn: 'Rowlet', types: ['grass', 'flying']),
          uniqueId: '722_normal',
        ),
        // Galar (810-898)
        _makeEntry(
          pokemon: _makePokemon(id: 810, nameDe: 'Chimpep', nameEn: 'Grookey', types: ['grass']),
          uniqueId: '810_normal',
        ),
        // Hisui (899-905)
        _makeEntry(
          pokemon: _makePokemon(id: 899, nameDe: 'Damenhir', nameEn: 'Wyrdeer', types: ['normal', 'psychic']),
          uniqueId: '899_normal',
        ),
        // Paldea (906+)
        _makeEntry(
          pokemon: _makePokemon(id: 906, nameDe: 'Felori', nameEn: 'Sprigatito', types: ['grass']),
          uniqueId: '906_normal',
        ),
      ];
    });

    testWidgets('Renders top search bar, region filter chips, and form filter chips', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      // Search bar
      expect(find.byType(TextField), findsOneWidget);

      // Region chips
      expect(find.text('Kanto'), findsOneWidget);
      expect(find.text('Johto'), findsOneWidget);
      expect(find.text('Hoenn'), findsOneWidget);
      expect(find.text('Sinnoh'), findsOneWidget);
      expect(find.text('Kalos'), findsOneWidget);
      expect(find.text('Alola'), findsWidgets); // chip + card suffix
      expect(find.text('Galar'), findsOneWidget);
      expect(find.text('Hisui'), findsOneWidget);
      expect(find.text('Paldea'), findsWidgets); // chip + card suffix

      // Form chips
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Mega'), findsOneWidget);
      expect(find.text('Gigadynamax'), findsOneWidget);
      expect(find.text('Regionalformen'), findsOneWidget);

      // Placeholder insert button in AppBar
      expect(find.byKey(const Key('insert_placeholder_button')), findsOneWidget);
    });

    testWidgets('Tapping insert_placeholder_button pops screen with "placeholder"', (tester) async {
      String? returnedResult;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final placeholderBtn = find.byKey(const Key('insert_placeholder_button'));
      expect(placeholderBtn, findsOneWidget);

      await tester.tap(placeholderBtn);
      await tester.pumpAndSettle();

      expect(returnedResult, equals('placeholder'));
    });

    testWidgets('PokemonSearchSelectionScreen renders dedicated Platzhalter card as first item in grid when browsing', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        language: 'de',
        child: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      // Both the AppBar button and the grid card are rendered
      expect(find.byKey(const Key('insert_placeholder_button')), findsOneWidget);
      final placeholderCard = find.byKey(const Key('pokemon_search_placeholder_card'));
      expect(placeholderCard, findsOneWidget);

      // Dedicated card has Platzhalter label and #---
      expect(find.descendant(of: placeholderCard, matching: find.text('Platzhalter')), findsOneWidget);
      expect(find.descendant(of: placeholderCard, matching: find.text('#---')), findsOneWidget);
    });

    testWidgets('Tapping the Platzhalter card in the grid pops screen with "placeholder"', (tester) async {
      String? returnedResult;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final placeholderCard = find.byKey(const Key('pokemon_search_placeholder_card'));
      expect(placeholderCard, findsOneWidget);

      await tester.tap(placeholderCard);
      await tester.pumpAndSettle();

      expect(returnedResult, equals('placeholder'));
    });

    testWidgets('Searching for a specific Pokémon hides the Platzhalter card', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      await tester.enterText(find.byType(TextField), 'Pikachu');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pokemon_search_placeholder_card')), findsNothing);
      expect(find.widgetWithText(Card, 'Pikachu'), findsOneWidget);
    });

    testWidgets('Searching for "platzhalter" displays the Platzhalter card', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      await tester.enterText(find.byType(TextField), 'platzhalter');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pokemon_search_placeholder_card')), findsOneWidget);
    });

    testWidgets('Searching for English and German synonyms ("empty", "blank", "freier slot", "leerer", "#---") displays the Platzhalter card', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      for (final term in ['empty', 'blank', 'freier slot', 'leerer', '#---']) {
        await tester.enterText(find.byType(TextField), term);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('pokemon_search_placeholder_card')),
          findsOneWidget,
          reason: 'Expected placeholder card for query "$term"',
        );
      }
    });

    testWidgets('Single-character or short non-matching queries ("p", "e", "pi") do NOT display the Platzhalter card', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      for (final term in ['p', 'e', 'pi', 's']) {
        await tester.enterText(find.byType(TextField), term);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('pokemon_search_placeholder_card')),
          findsNothing,
          reason: 'Placeholder card should not show for short query "$term"',
        );
      }
    });

    testWidgets('Searching by name instantly filters the grid', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      await tester.enterText(find.byType(TextField), 'Pikachu');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Card, 'Pikachu'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
      expect(find.text('Glurak'), findsNothing);
    });

    testWidgets('Searching by Pokédex number matches exact ID', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      await tester.enterText(find.byType(TextField), '25');
      await tester.pumpAndSettle();

      expect(find.text('Pikachu'), findsOneWidget);
      expect(find.text('#025'), findsOneWidget);
    });

    testWidgets('Tapping Region filter chip filters entries to that region', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      // Tap Johto chip
      await tester.tap(find.text('Johto'));
      await tester.pumpAndSettle();

      expect(find.text('Endivie'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
      expect(find.text('Pikachu'), findsNothing);
      expect(find.text('Felori'), findsNothing);
    });

    testWidgets('Tapping Form filter chip filters entries to that form category', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      // Tap Mega form chip
      await tester.tap(find.text('Mega'));
      await tester.pumpAndSettle();

      expect(find.text('Glurak (Mega X)'), findsOneWidget);
      expect(find.text('Mewtu (Mega X)'), findsOneWidget);
      expect(find.text('Pikachu'), findsNothing);
      expect(find.text('Bisasam'), findsNothing);
    });

    testWidgets('Searching with padded number #001 or 001 matches Bulbasaur', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      await tester.enterText(find.byType(TextField), '#001');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Card, 'Bisasam'), findsOneWidget);
      expect(find.widgetWithText(Card, '#001'), findsOneWidget);
      expect(find.text('Pikachu'), findsNothing);

      await tester.enterText(find.byType(TextField), '001');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Card, 'Bisasam'), findsOneWidget);
      expect(find.text('Pikachu'), findsNothing);
    });

    testWidgets('Searching with #025 matches Pikachu', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      await tester.enterText(find.byType(TextField), '#025');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Card, 'Pikachu'), findsOneWidget);
      expect(find.text('Bisasam'), findsNothing);
    });

    testWidgets('Regional forms with underscored form names match Regional chip', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
      ));

      await tester.tap(find.text('Regionalformen'));
      await tester.pumpAndSettle();

      expect(find.text('Tauros (Paldea)'), findsOneWidget);
      expect(find.text('Vulpix (Alola)'), findsOneWidget);
      expect(find.text('Pikachu'), findsNothing);
    });

    testWidgets('Tapping a card pops screen and returns uniqueId', (tester) async {
      String? returnedResult;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => PokemonSearchSelectionScreen(allAvailableEntries: testEntries),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap on Bisasam card
      await tester.tap(find.text('Bisasam'));
      await tester.pumpAndSettle();

      expect(returnedResult, equals('1_normal'));
    });
  });

  group('Paket 3 - Platzhalter-System (Fixierte Lücken) Tests', () {
    test('DexLogicHelper.isPlaceholder correctly detects placeholder IDs', () {
      expect(DexLogicHelper.isPlaceholder('placeholder'), isTrue);
      expect(DexLogicHelper.isPlaceholder('placeholder__12345_hash'), isTrue);
      expect(DexLogicHelper.isPlaceholder('empty_placeholder'), isTrue);
      expect(DexLogicHelper.isPlaceholder('empty_placeholder__123'), isTrue);
      expect(DexLogicHelper.isPlaceholder('1_normal'), isFalse);
      expect(DexLogicHelper.isPlaceholder('25_normal__123'), isFalse);
      expect(DexLogicHelper.isPlaceholder(''), isFalse);
      expect(DexLogicHelper.isPlaceholder(null), isFalse);
    });

    test('DexDisplayEntry.isPlaceholder correctly evaluates instance IDs', () {
      final placeholder = DexDisplayEntry.placeholderEntry('placeholder__123');
      expect(placeholder.isPlaceholder, isTrue);

      final normal = _makeEntry(
        pokemon: _makePokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur'),
        uniqueId: '1_normal__123',
      );
      expect(normal.isPlaceholder, isFalse);
    });

    test('DexLogicHelper.generateBoxes creates placeholder entries for placeholder IDs', () {
      final dex = createTestUserDex(id: 'dex1', title: 'Box Dex');
      dex.customBoxes = [
        CustomBoxState(
          title: 'Box 1',
          pokemonIds: ['1_normal', 'placeholder__999', '2_normal'],
        ),
      ];

      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1_normal'),
        createTestEntry(pokemon: poke2, uniqueId: '2_normal'),
      ];

      final boxes = DexLogicHelper.generateBoxes(entries, true, dex);
      expect(boxes.length, equals(1));

      final boxEntries = boxes.first.entries;
      expect(boxEntries[0].uniqueId, equals('1_normal'));
      expect(boxEntries[1].isPlaceholder, isTrue);
      expect(boxEntries[1].uniqueId, equals('placeholder__999'));
      expect(boxEntries[2].uniqueId, equals('2_normal'));
    });

    test('removeWithShiftBack protects placeholders and does NOT collapse them', () {
      final dex = createTestUserDex(id: 'dex1', title: 'Protected Placeholder Dex');
      final box1 = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', 'placeholder__1', 'P2', 'P3'],
        autoShift: true,
      );
      dex.customBoxes = [box1];

      // Removing P1 (index 0) before placeholder:
      // P1 is removed, but placeholder at index 1 does NOT move to index 0!
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Placeholder must remain at index 1! Slot 0 was cleared without shifting placeholder forward.
      expect(box1.pokemonIds[1], equals('placeholder__1'));
      expect(box1.pokemonIds[2], equals('P2'));
      expect(box1.pokemonIds[3], equals('P3'));
    });

    test('removeWithShiftBack shifts items after a placeholder while keeping placeholder fixed', () {
      final dex = createTestUserDex(id: 'dex1', title: 'Protected Placeholder Dex');
      final box1 = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', 'placeholder__1', 'P2', 'P3'],
        autoShift: true,
      );
      dex.customBoxes = [box1];

      // Removing P2 (index 2) after placeholder:
      // P3 shifts to index 2, placeholder at index 1 remains untouched!
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 2,
      );

      expect(box1.pokemonIds[0], equals('P1'));
      expect(box1.pokemonIds[1], equals('placeholder__1'));
      expect(box1.pokemonIds[2], equals('P3'));
    });

    test('removeWithShiftBack explicitly deleting placeholder removes the placeholder item', () {
      final dex = createTestUserDex(id: 'dex1', title: 'Delete Placeholder Dex');
      final box1 = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', 'placeholder__1', 'P2'],
        autoShift: true,
      );
      dex.customBoxes = [box1];

      // User explicitly deletes the placeholder at index 1
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 1,
      );

      expect(box1.pokemonIds.contains('placeholder__1'), isFalse);
      expect(box1.pokemonIds[0], equals('P1'));
      expect(box1.pokemonIds[1], equals('P2'));
    });

    test('removeWithShiftBack never pulls a placeholder from next linked box', () {
      final dex = createTestUserDex(id: 'dex1', title: 'Multi Box Placeholder Dex');
      final box1 = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', 'P2'],
        autoShift: true,
      );
      final box2 = CustomBoxState(
        title: 'Box 2',
        pokemonIds: ['placeholder__2', 'P3'],
        autoShift: true,
      );
      dex.customBoxes = [box1, box2];

      // Remove P2 from Box 1. Since Box 2 starts with a placeholder, it must NOT pull the placeholder into Box 1!
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 1,
      );

      expect(box1.pokemonIds, equals(['P1']));
      expect(box2.pokemonIds[0], equals('placeholder__2'));
    });

    testWidgets('DexBoxView renders placeholder card with dashed outline in normal mode', (tester) async {
      final placeholderEntry = DexDisplayEntry.placeholderEntry('placeholder__99');
      final boxData = createTestBoxData(
        title: 'Box 1',
        entries: [placeholderEntry],
      );
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int? insertedBoxIndex;
      int? insertedSlotIndex;

      await tester.pumpWidget(wrapWithApp(
        language: 'de',
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
          isEditMode: false,
          onInsertPokemon: (bIdx, sIdx) {
            insertedBoxIndex = bIdx;
            insertedSlotIndex = sIdx;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Finds the DashedRRectPainter
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Platzhalter'), findsOneWidget);
      expect(find.byIcon(Icons.crop_free), findsOneWidget);

      // Tapping placeholder card in normal mode calls onInsertPokemon
      await tester.tap(find.text('Platzhalter'));
      await tester.pump();

      expect(insertedBoxIndex, equals(0));
      expect(insertedSlotIndex, equals(0));
    });

    testWidgets('DexBoxView in edit mode allows selecting placeholder for deletion', (tester) async {
      final placeholderEntry = DexDisplayEntry.placeholderEntry('placeholder__99');
      final boxData = createTestBoxData(
        title: 'Box 1',
        entries: [placeholderEntry],
      );
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int? selectedBox;
      int? selectedSlot;

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
          isEditMode: true,
          selectedForEdit: const {'0_0'},
          onSelectionChanged: (bIdx, sIdx) {
            selectedBox = bIdx;
            selectedSlot = sIdx;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // With selectedForEdit = {'0_0'}, it shows the remove circle overlay
      expect(find.byIcon(Icons.remove_circle), findsOneWidget);

      // Tapping triggers onSelectionChanged
      await tester.tap(find.byIcon(Icons.remove_circle));
      await tester.pump();

      expect(selectedBox, equals(0));
      expect(selectedSlot, equals(0));
    });

    test('insertWithShiftAndOverflow absorbs empty gaps before placeholders without shifting placeholder or overflowing', () {
      final dex = createTestUserDex(id: 'dex1', title: 'Absorb Dex');
      final box = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', 'placeholder__1', 'P2', 'P3'],
        autoShift: true,
      );
      dex.customBoxes = [box];

      // Remove P1 at 0: slot 0 becomes empty '', placeholder remains at 1
      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);
      expect(box.pokemonIds[0], equals(''));
      expect(box.pokemonIds[1], equals('placeholder__1'));

      // Insert new item at slot 0: should fill slot 0 without pushing placeholder or overflowing
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
        pokemonId: 'P_New',
      );

      expect(box.pokemonIds[0], equals('P_New'));
      expect(box.pokemonIds[1], equals('placeholder__1'));
      expect(box.pokemonIds[2], equals('P2'));
      expect(box.pokemonIds[3], equals('P3'));
      expect(box.pokemonIds.length, equals(4)); // length did not increase!
      expect(dex.customBoxes.length, equals(1)); // no overflow box created!
    });

    test('Box check-all ignores placeholders and does not add placeholder to caughtIds', () {
      final placeholderEntry = DexDisplayEntry.placeholderEntry('placeholder__1');
      final pokeEntry = createTestEntry(pokemon: createTestPokemon(id: 1, nameEn: 'Bulbasaur'), uniqueId: '1_normal');

      final boxData = createTestBoxData(
        title: 'Box 1',
        entries: [pokeEntry, placeholderEntry],
      );

      // Verify that validEntries excluding placeholders only contains real pokemon
      final validEntries = boxData.entries.where((e) => e.uniqueId.isNotEmpty && !e.isPlaceholder).toList();
      expect(validEntries.length, equals(1));
      expect(validEntries.first.uniqueId, equals('1_normal'));
    });

    test('cross-box move does not collapse placeholders in source box', () {
      final dex = createTestUserDex(id: 'dex1', title: 'Cross Move Dex');
      final sourceBox = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', 'P2', 'placeholder__1', 'P3'],
        autoShift: true,
      );
      final targetBox = CustomBoxState(
        title: 'Box 2',
        pokemonIds: ['T1'],
        autoShift: true,
      );
      dex.customBoxes = [sourceBox, targetBox];

      // Move P1 (index 0) from Box 1 to Box 2:
      // In Box 1, P2 shifts to 0, slot 1 becomes empty, placeholder at index 2 is PROTECTED!
      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: 'P1',
        targetBoxIndex: 1,
        targetSlotIndex: 1,
      );

      expect(sourceBox.pokemonIds[0], equals('P2'));
      expect(sourceBox.pokemonIds[1], equals(''));
      expect(sourceBox.pokemonIds[2], equals('placeholder__1'));
      expect(sourceBox.pokemonIds[3], equals('P3'));
      expect(targetBox.pokemonIds.contains('P1'), isTrue);
    });

    testWidgets('DexBoxView does not render 3-dots box menu (placeholder removed from header)', (tester) async {
      final boxData = createTestBoxData(
        title: 'Box 1',
        entries: [DexDisplayEntry.placeholderEntry('placeholder__1')],
      );
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');
      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        language: 'de',
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
          isEditMode: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final menuButton = find.byKey(const ValueKey('box_menu_0'));
      expect(menuButton, findsNothing);
      expect(find.text('Platzhalter einfügen'), findsNothing);
    });

    testWidgets('BoxContentEditScreen selecting placeholder via PokemonSearchSelectionScreen inserts placeholder into slot', (tester) async {
      final liveDex = createTestUserDex(id: 'dex1', title: 'Edit Content Dex');
      final box = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['', 'P1'],
        columns: 2,
        rows: 1,
      );
      liveDex.customBoxes = [box];

      await tester.pumpWidget(MaterialApp(
        home: BoxContentEditScreen(
          dex: liveDex,
          boxIndex: 0,
          allAvailableEntries: const [],
        ),
      ));

      // Tap on empty slot (+)
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Tap the dedicated placeholder card in selection screen
      final placeholderCard = find.byKey(const Key('pokemon_search_placeholder_card'));
      expect(placeholderCard, findsOneWidget);
      await tester.tap(placeholderCard);
      await tester.pumpAndSettle();

      // Slot 0 was empty, now filled with placeholder
      expect(box.pokemonIds[0].startsWith('placeholder__'), isTrue);
    });

    testWidgets('BoxContentEditScreen has insert placeholder action in AppBar', (tester) async {
      final liveDex = createTestUserDex(id: 'dex1', title: 'Edit Content Dex');
      final box = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', ''],
        columns: 2,
        rows: 1,
      );
      liveDex.customBoxes = [box];

      await tester.pumpWidget(MaterialApp(
        home: BoxContentEditScreen(
          dex: liveDex,
          boxIndex: 0,
          allAvailableEntries: const [],
        ),
      ));

      final placeholderBtn = find.byKey(const Key('box_content_insert_placeholder'));
      expect(placeholderBtn, findsOneWidget);

      await tester.tap(placeholderBtn);
      await tester.pumpAndSettle();

      // Slot 1 was empty, now filled with placeholder
      expect(box.pokemonIds[1].startsWith('placeholder__'), isTrue);
    });

    testWidgets('BoxContentEditScreen replacing a placeholder slot with a selected Pokemon updates the slot', (tester) async {
      final liveDex = createTestUserDex(id: 'dex1', title: 'Edit Content Dex');
      final box = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['placeholder__existing', 'P1'],
        columns: 2,
        rows: 1,
      );
      liveDex.customBoxes = [box];

      final pokemon = createTestPokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu');
      final entry = createTestEntry(pokemon: pokemon, uniqueId: '25_normal');

      await tester.pumpWidget(MaterialApp(
        home: BoxContentEditScreen(
          dex: liveDex,
          boxIndex: 0,
          allAvailableEntries: [entry],
        ),
      ));

      // Tap on placeholder slot (slot 0)
      await tester.tap(find.text('Platzhalter').first);
      await tester.pumpAndSettle();

      // Tap on Pikachu
      await tester.tap(find.text('Pikachu'));
      await tester.pumpAndSettle();

      // Slot 0 is now filled with Pikachu instance ID, not placeholder
      expect(box.pokemonIds[0].startsWith('25_normal__'), isTrue);
      expect(DexLogicHelper.isPlaceholder(box.pokemonIds[0]), isFalse);
    });

    testWidgets('PokemonSearchSelectionScreen AppBar placeholder button renders compact localized label and returns "placeholder"', (tester) async {
      String? result;
      await tester.pumpWidget(wrapWithApp(
        language: 'de',
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => const PokemonSearchSelectionScreen(allAvailableEntries: []),
                ),
              );
            },
            child: const Text('Launch'),
          ),
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      final btn = find.byKey(const Key('insert_placeholder_button'));
      expect(btn, findsOneWidget);
      expect(find.descendant(of: btn, matching: find.text('Platzhalter')), findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(result, equals('placeholder'));
    });
  });
}
