import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/screens/dex/dex_list_view.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockProvider;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
  });

  group('R1 Grayscale Display E2E Tests - Tier 1: Feature Coverage', () {
    testWidgets('T1.1: Caught basic Pokémon in DexBoxView renders without grayscale filter', (tester) async {
      final poke = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final entry = createTestEntry(pokemon: poke, uniqueId: '1');
      final boxData = createTestBoxData(title: 'Box 1', entries: [entry]);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: ['1'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isFalse,
          reason: 'Caught Pokémon must render in full color without grayscale matrix filter');
    });

    testWidgets('T1.2: Uncaught basic Pokémon in DexBoxView renders with grayscale matrix filter', (tester) async {
      final poke = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entry = createTestEntry(pokemon: poke, uniqueId: '2');
      final boxData = createTestBoxData(title: 'Box 1', entries: [entry]);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: [],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isTrue,
          reason: 'Uncaught Pokémon must have grayscale matrix filter applied');
    });

    testWidgets('T1.3: Caught instance ID Pokémon (with __ suffix) in DexBoxView renders in full color when base ID is caught', (tester) async {
      final poke = createTestPokemon(id: 25, nameEn: 'Pikachu');
      const instanceUniqueId = '25__1728412345678_1234';
      final entry = createTestEntry(pokemon: poke, uniqueId: instanceUniqueId);
      final boxData = createTestBoxData(title: 'Custom Box', entries: [entry]);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: ['25'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isFalse,
          reason: 'Instance ID Pokémon must render in full color when base ID is caught in caughtIds');
    });

    testWidgets('T1.4: Caught basic Pokémon in DexListView renders in full color without grayscale filter', (tester) async {
      final poke = createTestPokemon(id: 4, nameEn: 'Charmander');
      final entry = createTestEntry(pokemon: poke, uniqueId: '4');
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: ['4'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexListView(
          displayList: [entry],
          liveDex: liveDex,
          provider: mockProvider,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isFalse,
          reason: 'Caught Pokémon in list view must render in full color without grayscale matrix filter');
    });

    testWidgets('T1.5: Uncaught basic Pokémon in DexListView renders with grayscale filter', (tester) async {
      final poke = createTestPokemon(id: 5, nameEn: 'Charmeleon');
      final entry = createTestEntry(pokemon: poke, uniqueId: '5');
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: [],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexListView(
          displayList: [entry],
          liveDex: liveDex,
          provider: mockProvider,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isTrue,
          reason: 'Uncaught Pokémon in list view must render in grayscale');
    });
  });

  group('R1 Grayscale Display E2E Tests - Tier 2: Boundary & Corner Cases', () {
    testWidgets('T2.1: Empty slot in DexBoxView does not apply grayscale filter', (tester) async {
      final emptyEntry = DexDisplayEntry.emptyEntry;
      final boxData = createTestBoxData(title: 'Box 1', entries: [emptyEntry]);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isFalse,
          reason: 'Empty slot should not have any grayscale filter applied');
    });

    testWidgets('T2.2: Multiple instances with same base ID in custom box both render in full color when caught', (tester) async {
      final poke = createTestPokemon(id: 7, nameEn: 'Squirtle');
      final instance1 = createTestEntry(pokemon: poke, uniqueId: '7__inst_1');
      final instance2 = createTestEntry(pokemon: poke, uniqueId: '7__inst_2');
      final boxData = createTestBoxData(title: 'Water Box', entries: [instance1, instance2]);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: ['7'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isFalse,
          reason: 'All instances of caught Pokémon must render in full color without grayscale');
    });

    testWidgets('T2.3: Form unique ID with instance suffix (e.g. 19_alola__inst1) checks base form catch status', (tester) async {
      final poke = createTestPokemon(id: 19, nameEn: 'Rattata');
      final formEntry = createTestEntry(pokemon: poke, uniqueId: '19_alola__instance_999');
      final boxData = createTestBoxData(title: 'Alola Box', entries: [formEntry]);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Alola',
        caughtIds: ['19_alola'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isFalse,
          reason: 'Form instance ID must recognize base form ID in caughtIds');
    });

    testWidgets('T2.4: Empty caughtIds list renders all Pokémon in grayscale', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: [],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isTrue,
          reason: 'All Pokémon must render with grayscale filter when caughtIds is empty');
    });

    testWidgets('T2.5: Shiny Pokémon when caught renders in full color', (tester) async {
      final poke = createTestPokemon(id: 6, nameEn: 'Charizard');
      final entry = createTestEntry(pokemon: poke, uniqueId: '6__shiny_1');
      final boxData = createTestBoxData(title: 'Shinies', entries: [entry]);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: ['6'],
        shinyIds: ['6__shiny_1'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(hasGrayscaleFilter(tester), isFalse,
          reason: 'Caught shiny Pokémon must render in full color');
    });
  });

  group('R1 Grayscale Display E2E Tests - Tier 3: Cross-Feature Combinations', () {
    testWidgets('T3.1: Mixed caught and uncaught Pokémon in same box maintain distinct color filters', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1', imageUrl: 'https://img/1.png'),
        createTestEntry(pokemon: poke2, uniqueId: '2', imageUrl: 'https://img/2.png'),
      ];
      final boxData = createTestBoxData(title: 'Mixed Box', entries: entries);
      // Bulbasaur (1) caught, Ivysaur (2) uncaught
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: ['1'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final caughtCard = findCardForImageUrl('https://img/1.png');
      final uncaughtCard = findCardForImageUrl('https://img/2.png');

      expect(hasGrayscaleFilter(tester, uncaughtCard), isTrue,
          reason: 'Uncaught Ivysaur must have grayscale filter');
      expect(hasGrayscaleFilter(tester, caughtCard), isFalse,
          reason: 'Caught Bulbasaur must NOT have grayscale filter');
    });

    testWidgets('T3.2: Toggling caught status via Provider tap invokes toggle with correct ID', (tester) async {
      final poke = createTestPokemon(id: 150, nameEn: 'Mewtwo');
      final entry = createTestEntry(pokemon: poke, uniqueId: '150__leg_1', imageUrl: 'https://img/150.png');
      final boxData = createTestBoxData(title: 'Legendaries', entries: [entry]);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        caughtIds: [],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);
      when(() => mockProvider.togglePokemon(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Tap card to toggle caught
      await tester.tap(findCardForImageUrl('https://img/150.png'));
      await tester.pump();

      verify(() => mockProvider.togglePokemon('dex1', '150__leg_1')).called(1);
    });
  });

  group('R1 Grayscale Display E2E Tests - Tier 4: Real-World Acceptance Scenarios', () {
    testWidgets('T4.1 Acceptance Scenario 4: Caught Pokémon verified rendered in full color in box view and list view', (tester) async {
      final pikachu = createTestPokemon(id: 25, nameEn: 'Pikachu');
      final charmander = createTestPokemon(id: 4, nameEn: 'Charmander');

      final pikaEntry = createTestEntry(pokemon: pikachu, uniqueId: '25__inst', imageUrl: 'https://img/25.png');
      final charEntry = createTestEntry(pokemon: charmander, uniqueId: '4__inst', imageUrl: 'https://img/4.png');

      final boxData = createTestBoxData(
        title: 'Team 1',
        entries: [pikaEntry, charEntry],
      );

      // Pikachu (25) caught; Charmander (4) uncaught
      final liveDex = createTestUserDex(
        id: 'acceptance_dex',
        title: 'Kanto Main',
        caughtIds: ['25'],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      // 1. Verify in Box View
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final boxPikaCard = findCardForImageUrl('https://img/25.png');
      final boxCharCard = findCardForImageUrl('https://img/4.png');

      expect(hasGrayscaleFilter(tester, boxPikaCard), isFalse,
          reason: 'Caught Pikachu must be rendered in full color in box view');
      expect(hasGrayscaleFilter(tester, boxCharCard), isTrue,
          reason: 'Uncaught Charmander must be rendered in grayscale in box view');

      // 2. Verify in List View
      await tester.pumpWidget(wrapWithApp(
        child: DexListView(
          displayList: [pikaEntry, charEntry],
          liveDex: liveDex,
          provider: mockProvider,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final listPikaCard = find.ancestor(
        of: find.byWidgetPredicate((w) => w is CachedNetworkImage && w.imageUrl == 'https://img/25.png'),
        matching: find.byType(Card),
      );
      final listCharCard = find.ancestor(
        of: find.byWidgetPredicate((w) => w is CachedNetworkImage && w.imageUrl == 'https://img/4.png'),
        matching: find.byType(Card),
      );

      expect(hasGrayscaleFilter(tester, listPikaCard), isFalse,
          reason: 'Caught Pikachu must be rendered in full color in list view');
      expect(hasGrayscaleFilter(tester, listCharCard), isTrue,
          reason: 'Uncaught Charmander must be rendered in grayscale in list view');
    });
  });
}
