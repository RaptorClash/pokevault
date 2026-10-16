import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'e2e_test_helper.dart';
import 'e2e_box_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockProvider;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
    E2EBoxActions.resetHandlers();
  });

  group('R2 Smart Drag & Drop Insertion E2E Tests - Tier 1: Feature Coverage', () {
    test('T1.1: Move forward in box inserts at target and shifts intermediate items left', () {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['A', 'B', 'C', 'D'],
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box],
      );

      // Moving A (index 0) to index 2:
      // Expected shift: B and C shift left, A inserted at index 2 -> [B, C, A, D]
      // (Naive swap would produce [C, B, A, D])
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 0,
        targetSlotIndex: 2,
      );

      expect(dex.customBoxes[0].pokemonIds.sublist(0, 4), equals(['B', 'C', 'A', 'D']),
          reason: 'Moving item 0 to 2 must shift intermediate items left, producing [B, C, A, D]');
    });

    test('T1.2: Move backward in box inserts at target and shifts intermediate items right', () {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['A', 'B', 'C', 'D'],
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box],
      );

      // Moving D (index 3) to index 1:
      // Expected shift: B and C shift right, D inserted at index 1 -> [A, D, B, C]
      // (Naive swap would produce [A, D, C, B])
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'D',
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      );

      expect(dex.customBoxes[0].pokemonIds.sublist(0, 4), equals(['A', 'D', 'B', 'C']),
          reason: 'Moving item 3 to 1 must shift subsequent items right, producing [A, D, B, C]');
    });

    test('T1.3: Moving to first slot (index 0) shifts all following items right', () {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['A', 'B', 'C'],
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box],
      );

      // Move C (index 2) to index 0:
      // Expected: [C, A, B]
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'C',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      expect(dex.customBoxes[0].pokemonIds.sublist(0, 3), equals(['C', 'A', 'B']),
          reason: 'Moving to index 0 must shift all preceding items right, producing [C, A, B]');
    });

    test('T1.4: Moving to last occupied slot shifts preceding items', () {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['A', 'B', 'C'],
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box],
      );

      // Move A (index 0) to index 2:
      // Expected: [B, C, A]
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 0,
        targetSlotIndex: 2,
      );

      expect(dex.customBoxes[0].pokemonIds.sublist(0, 3), equals(['B', 'C', 'A']),
          reason: 'Moving first item to last slot must shift intermediate items, producing [B, C, A]');
    });

    test('T1.5: Cross-box move inserts into target box at specified slot and shifts target box items', () {
      final box1 = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['A', 'B'],
      );
      final box2 = createTestCustomBox(
        title: 'Box 2',
        pokemonIds: ['X', 'Y', 'Z'],
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box1, box2],
      );

      // Move A from Box 1 to Box 2 at index 1:
      // In Box 2, Y and Z shift right: [X, A, Y, Z]
      // In Box 1, A is removed: [B]
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 1,
        targetSlotIndex: 1,
      );

      expect(dex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['X', 'A', 'Y', 'Z']),
          reason: 'Cross-box move must insert at targetSlotIndex and shift target box items right');
      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['B']),
          reason: 'Source box must have moved item removed');
    });
  });

  group('R2 Smart Drag & Drop Insertion E2E Tests - Tier 2: Boundary & Corner Cases', () {
    test('T2.1: Single-element box move to index 0 leaves item at index 0', () {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['Solo']);
      final dex = createTestUserDex(id: 'dex1', title: 'Kanto', customBoxes: [box]);

      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'Solo',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).toList(), equals(['Solo']));
    });

    test('T2.2: Dropping item onto its own current index is a strict no-op', () {
      final initialList = ['A', 'B', 'C', 'D'];
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: initialList);
      final dex = createTestUserDex(id: 'dex1', title: 'Kanto', customBoxes: [box]);

      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'B',
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      );

      expect(dex.customBoxes[0].pokemonIds.sublist(0, 4), equals(initialList),
          reason: 'Dropping onto same index must maintain exact original ordering');
    });

    test('T2.3: Dropping into an empty slot places item into slot without shifting other filled slots', () {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['A', 'B', '', 'C', ''],
      );
      final dex = createTestUserDex(id: 'dex1', title: 'Kanto', customBoxes: [box]);

      // Move A to empty slot index 2
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'A',
        targetBoxIndex: 0,
        targetSlotIndex: 2,
      );

      final occupied = dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).toSet();
      expect(occupied, equals({'A', 'B', 'C'}),
          reason: 'All Pokémon must be preserved when moving into an empty slot');
    });

    test('T2.4: Conservation of elements: item count and set of IDs strictly preserved after move', () {
      final ids = ['P1', 'P2', 'P3', 'P4', 'P5'];
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ids);
      final dex = createTestUserDex(id: 'dex1', title: 'Kanto', customBoxes: [box]);

      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: 'P3',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      final result = dex.customBoxes[0].pokemonIds.sublist(0, 5);
      expect(result.length, equals(ids.length));
      expect(result.toSet(), equals(ids.toSet()), reason: 'No items lost or duplicated during move');
    });

    test('T2.5: Multi-move sequence preserves all IDs and achieves final expected ordering', () {
      // Sequence of moves:
      // Start: [1, 2, 3, 4]
      // Move 4 to 0 -> [4, 1, 2, 3]
      // Move 3 to 1 -> [4, 3, 1, 2]
      // Move 2 to 0 -> [2, 4, 3, 1]
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1', '2', '3', '4']);
      final dex = createTestUserDex(id: 'dex1', title: 'Kanto', customBoxes: [box]);

      E2EBoxActions.movePokemon(dex: dex, sourceId: '4', targetBoxIndex: 0, targetSlotIndex: 0);
      E2EBoxActions.movePokemon(dex: dex, sourceId: '3', targetBoxIndex: 0, targetSlotIndex: 1);
      E2EBoxActions.movePokemon(dex: dex, sourceId: '2', targetBoxIndex: 0, targetSlotIndex: 0);

      expect(dex.customBoxes[0].pokemonIds.sublist(0, 4), equals(['2', '4', '3', '1']));
    });
  });

  group('R2 Smart Drag & Drop Insertion E2E Tests - Tier 3: Cross-Feature Combinations', () {
    testWidgets('T3.1: Drag and drop in DexBoxView UI renders LongPressDraggable and DragTarget widgets in edit mode', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      // Pump in edit mode
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
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(find.byType(LongPressDraggable<String>), findsWidgets,
          reason: 'Pokémon cards in edit mode must be wrapped with LongPressDraggable');
      expect(find.byType(DragTarget<String>), findsWidgets,
          reason: 'Pokémon slots in edit mode must be wrapped with DragTarget');
    });

    test('T3.2: Reordering items in box preserves caught status association for all shifted items', () {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1__c', '2__u', '3__c'],
      );
      // '1' and '3' are caught; '2' is uncaught
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box],
        caughtIds: ['1', '3'],
      );

      // Shift '3__c' to index 0 -> ['3__c', '1__c', '2__u']
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: '3__c',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      expect(dex.customBoxes[0].pokemonIds.sublist(0, 3), equals(['3__c', '1__c', '2__u']));
      // Caught IDs set remains unmodified
      expect(dex.caughtIds, contains('1'));
      expect(dex.caughtIds, contains('3'));
      expect(dex.caughtIds, isNot(contains('2')));
    });
  });

  group('R2 Smart Drag & Drop Insertion E2E Tests - Tier 4: Real-World Acceptance Scenarios', () {
    test('T4.1 Acceptance: Re-arranging Starter trio [Bulbasaur, Charmander, Squirtle] inserts Squirtle between Bulbasaur and Charmander', () {
      // User has starters in order: Bulbasaur (1), Charmander (4), Squirtle (7)
      final box = createTestCustomBox(
        title: 'Starters',
        pokemonIds: ['1__bulba', '4__char', '7__squirtle'],
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box],
      );

      // User drags Squirtle (index 2) and drops between Bulbasaur and Charmander (slot index 1)
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: '7__squirtle',
        targetBoxIndex: 0,
        targetSlotIndex: 1,
      );

      // Requirement: Charmander must shift right to make room, NOT swap with Squirtle!
      // Expected: [Bulbasaur, Squirtle, Charmander]
      // (Naive swap would produce [Bulbasaur, Squirtle, Squirtle] or swap with Charmander producing [Bulbasaur, Squirtle, 4__char])
      expect(
        dex.customBoxes[0].pokemonIds.sublist(0, 3),
        equals(['1__bulba', '7__squirtle', '4__char']),
        reason: 'Dragging Squirtle to index 1 must shift Charmander right, producing [Bulbasaur, Squirtle, Charmander]',
      );
    });

    test('T4.2 Acceptance: Dragging Pokémon from end of full team to first position shifts entire team rightward', () {
      final teamIds = [
        '25__pika',
        '1__bulba',
        '4__char',
        '7__squirt',
        '133__eevee',
        '143__snorlax',
      ];
      final box = createTestCustomBox(
        title: 'My Team',
        pokemonIds: teamIds,
      );
      final dex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [box],
      );

      // User drags Snorlax (index 5) to leader position (index 0)
      E2EBoxActions.movePokemon(
        dex: dex,
        sourceId: '143__snorlax',
        targetBoxIndex: 0,
        targetSlotIndex: 0,
      );

      expect(
        dex.customBoxes[0].pokemonIds.sublist(0, 6),
        equals([
          '143__snorlax',
          '25__pika',
          '1__bulba',
          '4__char',
          '7__squirt',
          '133__eevee',
        ]),
        reason: 'Moving Snorlax to index 0 must shift all 5 preceding Pokémon rightwards by one slot',
      );
    });
  });
}
