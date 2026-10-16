import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockProvider;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
  });

  group('DexBoxView Multi-Card Drag & Drop Tests', () {
    testWidgets('Multi-drag initiation displays stacked pile feedback and counter badge', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final poke3 = createTestPokemon(id: 3, nameEn: 'Venusaur');
      final poke4 = createTestPokemon(id: 4, nameEn: 'Charmander');

      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
        createTestEntry(pokemon: poke3, uniqueId: '3'),
        createTestEntry(pokemon: poke4, uniqueId: '4'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2', '3', '4']),
        ],
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
          isEditMode: true,
          selectedForEdit: const {'0_0', '0_1', '0_2'},
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Visual feedback: Stacked card pile with counter badge showing '3'
      expect(find.byKey(const Key('multi_drag_badge')), findsOneWidget);
      expect(find.byKey(const Key('multi_drag_count_text')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Dropping multi-drag payload on card invokes onMoveMultiplePokemon', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final poke3 = createTestPokemon(id: 3, nameEn: 'Venusaur');
      final poke4 = createTestPokemon(id: 4, nameEn: 'Charmander');

      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
        createTestEntry(pokemon: poke3, uniqueId: '3'),
        createTestEntry(pokemon: poke4, uniqueId: '4'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2', '3', '4']),
        ],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      List<String>? multiMovedIds;
      int? multiTargetBox;
      int? multiTargetSlot;
      String? swappedSourceId;

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
          selectedForEdit: const {'0_0', '0_1'},
          onMoveMultiplePokemon: (ids, targetBox, targetIndex) {
            multiMovedIds = ids;
            multiTargetBox = targetBox;
            multiTargetSlot = targetIndex;
          },
          onSwapPokemon: (sourceId, targetBox, targetIndex) {
            swappedSourceId = sourceId;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final fourthCenter = tester.getCenter(find.byType(DragTarget<String>).at(3));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Drag to center of fourth card (slot 3)
      await gesture.moveTo(fourthCenter);
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(multiMovedIds, equals(['1', '2']), reason: 'Both selected cards must be moved as a block');
      expect(multiTargetBox, equals(0));
      expect(multiTargetSlot, equals(3));
      expect(swappedSourceId, isNull, reason: 'Multi-drag must NOT trigger a 1:1 swap');
    });

    testWidgets('Dropping multi-drag payload on empty slot invokes onMoveMultiplePokemon', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');

      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
        createTestEntry(pokemon: poke1, uniqueId: ''),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2', '']),
        ],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      List<String>? multiMovedIds;
      int? multiTargetBox;
      int? multiTargetSlot;

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
          selectedForEdit: const {'0_0', '0_1'},
          onMoveMultiplePokemon: (ids, targetBox, targetIndex) {
            multiMovedIds = ids;
            multiTargetBox = targetBox;
            multiTargetSlot = targetIndex;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final emptySlotCenter = tester.getCenter(find.byType(DragTarget<String>).at(2));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Drag to empty slot at index 2
      await gesture.moveTo(emptySlotCenter);
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(multiMovedIds, equals(['1', '2']));
      expect(multiTargetBox, equals(0));
      expect(multiTargetSlot, equals(2));
    });

    testWidgets('Long-pressing unselected card while others are selected preserves single-card drag', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final poke3 = createTestPokemon(id: 3, nameEn: 'Venusaur');

      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
        createTestEntry(pokemon: poke3, uniqueId: '3'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2', '3']),
        ],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      List<String>? multiMovedIds;
      String? swappedSourceId;
      int? swappedTargetSlot;

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
          // Cards 0 and 1 are selected. Card 2 ('3') is NOT selected!
          selectedForEdit: const {'0_0', '0_1'},
          onMoveMultiplePokemon: (ids, targetBox, targetIndex) {
            multiMovedIds = ids;
          },
          onSwapPokemon: (sourceId, targetBox, targetIndex) {
            swappedSourceId = sourceId;
            swappedTargetSlot = targetIndex;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Long press card 2 (Venusaur, uniqueId '3') which is unselected
      final thirdCenter = tester.getCenter(find.byType(LongPressDraggable<String>).at(2));
      final firstCenter = tester.getCenter(find.byType(DragTarget<String>).first);

      final gesture = await tester.startGesture(thirdCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Pile badge should NOT be visible because this is a single unselected card drag
      expect(find.byKey(const Key('multi_drag_badge')), findsNothing);

      // Drag to center of card 0 (Bulbasaur)
      await gesture.moveTo(firstCenter);
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should perform normal single-card swap
      expect(swappedSourceId, equals('3'));
      expect(swappedTargetSlot, equals(0));
      expect(multiMovedIds, isNull, reason: 'Single card drag must not invoke onMoveMultiplePokemon');
    });

    testWidgets('Multi-drag cancellation cleanly resets dragged state', (tester) async {
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
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2']),
        ],
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
          isEditMode: true,
          selectedForEdit: const {'0_0', '0_1'},
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      expect(find.byKey(const Key('multi_drag_badge')), findsOneWidget);

      // Move completely out of bounds (top-left offscreen)
      await gesture.moveTo(const Offset(-100, -100));
      await tester.pump();

      // Release / Cancel drag
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Feedback should be destroyed and badge gone
      expect(find.byKey(const Key('multi_drag_badge')), findsNothing);
    });

    testWidgets('Fallback: Dropping multi-drag payload without callback executes BoxSequenceManager.moveMultiplePokemon directly', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final poke3 = createTestPokemon(id: 3, nameEn: 'Venusaur');
      final poke4 = createTestPokemon(id: 4, nameEn: 'Charmander');

      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
        createTestEntry(pokemon: poke3, uniqueId: '3'),
        createTestEntry(pokemon: poke4, uniqueId: '4'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2', '3', '4']),
        ],
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
          isEditMode: true,
          selectedForEdit: const {'0_0', '0_1'},
          // onMoveMultiplePokemon is NOT provided -> fallback should trigger
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final fourthCenter = tester.getCenter(find.byType(DragTarget<String>).at(3));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      await gesture.moveTo(fourthCenter);
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In customBoxes, inserting at slot 3 (where '4' is) places '1' and '2' before '4'
      expect(liveDex.customBoxes[0].pokemonIds, equals(['3', '1', '2', '4']),
          reason: 'Direct fallback must move multiple pokemon block cleanly via BoxSequenceManager');
    });

    testWidgets('Multi-drag reveals edge autoscroll DragTargets', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');

      final box1 = createTestBoxData(title: 'Box 1', entries: [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ]);
      final box2 = createTestBoxData(title: 'Box 2', entries: [
        createTestEntry(pokemon: poke1, uniqueId: '3'),
      ]);

      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2']),
          CustomBoxState(title: 'Box 2', pokemonIds: ['3']),
        ],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [box1, box2],
          liveDex: liveDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
          isEditMode: true,
          selectedForEdit: const {'0_0', '0_1'},
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Before drag: edge targets are not rendered
      expect(find.byIcon(Icons.chevron_left), findsOneWidget); // Header button only
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // During multi-drag: chevron drag targets appear in the header and overlay zones
      expect(find.byType(DragTarget<String>), findsWidgets);

      // Move gesture over left edge drag target (x: 20, y: 300)
      await gesture.moveTo(const Offset(20, 300));
      await tester.pump();

      // The left chevron in the edge DragTarget overlay must now be visible!
      // (Total chevron_left: 1 in header + 1 in edge overlay = 2)
      expect(find.byIcon(Icons.chevron_left), findsNWidgets(2));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Dropping multi-drag payload onto one of the dragged cards is rejected', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final poke3 = createTestPokemon(id: 3, nameEn: 'Venusaur');

      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
        createTestEntry(pokemon: poke3, uniqueId: '3'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Kanto',
        customBoxes: [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1', '2', '3']),
        ],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      bool callbackInvoked = false;

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
          selectedForEdit: const {'0_0', '0_1'},
          onMoveMultiplePokemon: (ids, b, i) {
            callbackInvoked = true;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final secondCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Drag to slot 1 (which contains '2', also in the dragged group)
      await gesture.moveTo(secondCenter);
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Callback must NOT have been invoked because drop on self/group member is rejected
      expect(callbackInvoked, isFalse);
    });
  });
}

