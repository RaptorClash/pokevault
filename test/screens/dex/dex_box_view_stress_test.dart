import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

/// Interactive stateful harness that connects [DexBoxView] to [BoxSequenceManager]
/// exactly as [DexScreen] does.
class DexBoxViewTestHarness extends StatefulWidget {
  final UserDex initialDex;
  final bool isEditMode;
  final void Function(String sourceId, int targetBox, int targetSlot)? onMoveCallbackSpy;

  const DexBoxViewTestHarness({
    super.key,
    required this.initialDex,
    this.isEditMode = true,
    this.onMoveCallbackSpy,
  });

  @override
  State<DexBoxViewTestHarness> createState() => DexBoxViewTestHarnessState();
}

class DexBoxViewTestHarnessState extends State<DexBoxViewTestHarness> {
  late UserDex dex;
  late PageController pageController;
  final Map<String, Pokemon> pokemonMap = {};

  @override
  void initState() {
    super.initState();
    dex = widget.initialDex;
    pageController = PageController();

    // Cache pokemon descriptors
    for (int i = 1; i <= 20; i++) {
      pokemonMap['$i'] = createTestPokemon(id: i, nameEn: 'Pokemon_$i');
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  List<BoxData> get boxes {
    return dex.customBoxes.map((cb) {
      final entries = cb.pokemonIds.map((id) {
        if (id.isEmpty) return DexDisplayEntry.emptyEntry;
        final baseIdStr = DexLogicHelper.getBaseId(id);
        final pId = int.tryParse(baseIdStr) ?? 1;
        final pokemon = pokemonMap[baseIdStr] ?? createTestPokemon(id: pId, nameEn: 'Pokemon_$pId');
        return createTestEntry(pokemon: pokemon, uniqueId: id);
      }).toList();
      return BoxData(cb.title, cb.regionKey, entries, cb.columns);
    }).toList();
  }

  void handleMove(String sourceId, int targetBox, int targetSlot) {
    widget.onMoveCallbackSpy?.call(sourceId, targetBox, targetSlot);
    setState(() {
      BoxSequenceManager.movePokemon(
        dex: dex,
        sourceId: sourceId,
        targetBoxIndex: targetBox,
        targetSlotIndex: targetSlot,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DexBoxView(
      boxes: boxes,
      liveDex: dex,
      provider: MockDexProvider(),
      pageController: pageController,
      separateForms: true,
      highlightedIds: const {},
      isSearchActive: false,
      isEditMode: widget.isEditMode,
      onMovePokemon: handleMove,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockProvider;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
  });

  group('Challenger M3-1 Empirical DnD Stress Harness', () {
    // ------------------------------------------------------------------------
    // SCENARIO 1: Drag onto Self (strict no-op)
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 1: Dragging card onto itself is a strict no-op with zero visual displacement or callback', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '3'],
        columns: 3,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_1',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int moveCallCount = 0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
          onMoveCallbackSpy: (source, box, slot) {
            moveCallCount++;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(find.byType(LongPressDraggable<String>), findsNWidgets(3));

      // 1. Hover on Self
      final firstDraggable = find.byType(LongPressDraggable<String>).first;
      final firstCenter = tester.getCenter(firstDraggable);

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Move slightly within own card bounding box
      await gesture.moveTo(firstCenter);
      await tester.pump();

      // Verify that NO AnimatedSlide on any card has offset (0.06, 0.0)
      final slidesDuringSelfHover = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(
        slidesDuringSelfHover.any((slide) => slide.offset != Offset.zero),
        isFalse,
        reason: 'Self-hover must NOT produce any displacement offset on any card',
      );

      // Verify that no caret dots or insertion lines are rendered
      // Carets are 8x8 circular containers
      final selfHoverContainers = tester.widgetList<Container>(find.byType(Container));
      final hasCaretCircle = selfHoverContainers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.shape == BoxShape.circle && c.constraints?.maxWidth == 8;
      });
      expect(hasCaretCircle, isFalse, reason: 'Self-hover must NOT render caret circles');

      // 2. Drop on Self
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Assert onMovePokemon was NOT called
      expect(moveCallCount, equals(0), reason: 'Self-drop must NOT invoke onMovePokemon callback');

      // Assert slot 0, 1, 2 ordering is completely unchanged
      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['1', '2', '3']));
    });

    // ------------------------------------------------------------------------
    // SCENARIO 2: Drag Between Occupied Slots (Card nudge, insertion line, and shift)
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 2A: Forward drag between occupied slots shifts intermediate cards left', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '3', '4'],
        columns: 4,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_2a',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      String? movedSource;
      int? movedTargetSlot;

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
          onMoveCallbackSpy: (source, box, slot) {
            movedSource = source;
            movedTargetSlot = slot;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCard = find.byType(LongPressDraggable<String>).at(0);
      final thirdCard = find.byType(DragTarget<String>).at(2);

      final firstCenter = tester.getCenter(firstCard);
      final thirdCenter = tester.getCenter(thirdCard);

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Hover over slot 2 ('3')
      await gesture.moveTo(thirdCenter);
      await tester.pump();

      // Verify card nudge offset on targeted slot
      final slides = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide)).toList();
      expect(
        slides.any((s) => s.offset == const Offset(0.06, 0.0)),
        isTrue,
        reason: 'Targeted occupied card must nudge right by 0.06',
      );

      // Verify insertion indicator line (Container with width 4) exists
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasInsertionBar = containers.any((c) => c.constraints?.maxWidth == 4);
      expect(hasInsertionBar, isTrue, reason: 'Vertical insertion glow bar must appear during hover');

      // Drop on slot 2
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(movedSource, equals('1'));
      expect(movedTargetSlot, equals(2));

      // After dropping '1' at slot 2:
      // Initial: ['1', '2', '3', '4']
      // '1' is removed, intermediate cards shift left, '1' inserted at slot 2:
      // Result: ['2', '3', '1', '4']
      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      expect(
        harnessState.dex.customBoxes.first.pokemonIds,
        equals(['2', '3', '1', '4']),
        reason: 'Subsequent cards must shift left, NOT swap with target slot',
      );
    });

    testWidgets('SCENARIO 2B: Backward drag between occupied slots shifts intermediate cards right', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '3', '4'],
        columns: 4,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_2b',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Drag slot 3 ('4') to slot 1 ('2')
      final fourthCard = find.byType(LongPressDraggable<String>).at(3);
      final secondCard = find.byType(DragTarget<String>).at(1);

      final fourthCenter = tester.getCenter(fourthCard);
      final secondCenter = tester.getCenter(secondCard);

      final gesture = await tester.startGesture(fourthCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      await gesture.moveTo(secondCenter);
      await tester.pump();

      // Drop on slot 1
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initial: ['1', '2', '3', '4']
      // '4' is removed: ['1', '2', '3']
      // '4' is inserted at slot 1: ['1', '4', '2', '3']
      // Intermediate cards '2' and '3' shifted right!
      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      expect(
        harnessState.dex.customBoxes.first.pokemonIds,
        equals(['1', '4', '2', '3']),
        reason: 'Backward drag must shift intermediate cards right',
      );
    });

    // ------------------------------------------------------------------------
    // SCENARIO 3: Drag onto Empty Slots (Frame highlight, placement without shifting filled slots)
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 3: Dragging onto empty slot highlights frame and places without shifting filled slots', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '', ''],
        columns: 4,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_3',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Before drag: two filled slots (LongPressDraggable), two empty slots (size 24 add icon)
      expect(find.byType(LongPressDraggable<String>), findsNWidgets(2));
      final emptySlotAddIcons = find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.add && w.size == 24);
      expect(emptySlotAddIcons, findsNWidgets(2));
      expect(find.byIcon(Icons.arrow_downward), findsNothing);

      final firstCenter = tester.getCenter(find.byType(DragTarget<String>).at(0));
      final empty2Center = tester.getCenter(find.byType(DragTarget<String>).at(2));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Hover over empty slot 2
      await gesture.moveTo(empty2Center);
      await tester.pump();

      // Verify targeted empty slot transforms add icon to arrow_downward
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget, reason: 'Hovered empty slot must show downward arrow');
      // Verify other empty slot still shows add icon
      expect(emptySlotAddIcons, findsOneWidget, reason: 'Non-hovered empty slot must keep add icon');

      // Drop on empty slot 2
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initial: ['1', '2', '', '']
      // Target slot 2 is empty. Item '1' is placed at slot 2, slot 0 is cleared.
      // Filled slot 1 ('2') must NOT be shifted!
      // Result: ['', '2', '1', '']
      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      expect(
        harnessState.dex.customBoxes.first.pokemonIds,
        equals(['', '2', '1', '']),
        reason: 'Dropping onto empty slot must place item without shifting other filled slots',
      );
    });

    // ------------------------------------------------------------------------
    // SCENARIO 4: Rapid Consecutive Drags & Scrubbing
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 4A: Rapid consecutive drag interactions maintain consistent state without dropping events', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '3', '4', '5', ''],
        columns: 6,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_4a',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      Future<void> executeDrag(int fromSlot, int toSlot) async {
        // Record slot coordinates BEFORE starting drag gesture
        final fromCenter = tester.getCenter(find.byType(DragTarget<String>).at(fromSlot));
        final toCenter = tester.getCenter(find.byType(DragTarget<String>).at(toSlot));

        final gesture = await tester.startGesture(fromCenter);
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
        await gesture.moveTo(toCenter);
        await tester.pump();
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));

      // Step 1: Drag slot 0 ('1') to slot 3 ('4')
      // ['1', '2', '3', '4', '5', ''] -> ['2', '3', '4', '1', '5', '']
      await executeDrag(0, 3);
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['2', '3', '4', '1', '5', '']));

      // Step 2: Drag slot 4 ('5') to slot 0 ('2')
      // ['2', '3', '4', '1', '5', ''] -> ['5', '2', '3', '4', '1', '']
      await executeDrag(4, 0);
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['5', '2', '3', '4', '1', '']));

      // Step 3: Drag slot 3 ('4') to empty slot 5
      // ['5', '2', '3', '4', '1', ''] -> ['5', '2', '3', '', '1', '4']
      await executeDrag(3, 5);
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['5', '2', '3', '', '1', '4']));

      // Step 4: Drag slot 0 ('5') to slot 0 (self-drop) -> strict no-op
      await executeDrag(0, 0);
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['5', '2', '3', '', '1', '4']));

      // Step 5: Drag slot 4 ('1') to slot 3 (now empty slot) -> places into empty slot without shift
      // ['5', '2', '3', '', '1', '4'] -> ['5', '2', '3', '1', '', '4']
      await executeDrag(4, 3);
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['5', '2', '3', '1', '', '4']));

      // Step 6: Drag slot 5 ('4') to slot 1 ('2')
      // ['5', '2', '3', '1', '', '4'] -> '4' inserted at 1, intermediate cards '2','3','1','' shift right
      // Initial: ['5', '2', '3', '1', '', '4']
      // Remove '4' at 5: ['5', '2', '3', '1', '']
      // Insert '4' at 1: ['5', '4', '2', '3', '1', '']
      await executeDrag(5, 1);
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['5', '4', '2', '3', '1', '']));
    });

    testWidgets('SCENARIO 4B: Scrubbing hover across multiple slots dynamically updates indicator and restores previous slots', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '3', '4'],
        columns: 4,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_4b',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Obtain slot centers BEFORE initiating drag
      final center0 = tester.getCenter(find.byType(DragTarget<String>).at(0));
      final center1 = tester.getCenter(find.byType(DragTarget<String>).at(1));
      final center2 = tester.getCenter(find.byType(DragTarget<String>).at(2));
      final center3 = tester.getCenter(find.byType(DragTarget<String>).at(3));

      final gesture = await tester.startGesture(center0);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // 1. Move to slot 1
      await gesture.moveTo(center1);
      await tester.pump();
      int displacedCount = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .where((s) => s.offset == const Offset(0.06, 0.0)).length;
      expect(displacedCount, equals(1), reason: 'Only slot 1 should be displaced');

      // 2. Scrub to slot 2 without releasing
      await gesture.moveTo(center2);
      await tester.pump();
      displacedCount = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .where((s) => s.offset == const Offset(0.06, 0.0)).length;
      expect(displacedCount, equals(1), reason: 'Slot 1 must restore and only slot 2 should be displaced');

      // 3. Scrub to slot 3 without releasing
      await gesture.moveTo(center3);
      await tester.pump();
      displacedCount = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .where((s) => s.offset == const Offset(0.06, 0.0)).length;
      expect(displacedCount, equals(1), reason: 'Only slot 3 should be displaced');

      // 4. Scrub back to slot 1 without releasing
      await gesture.moveTo(center1);
      await tester.pump();
      displacedCount = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .where((s) => s.offset == const Offset(0.06, 0.0)).length;
      expect(displacedCount, equals(1), reason: 'Only slot 1 should be displaced after return');

      // 5. Release on slot 1
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['2', '1', '3', '4']));
    });

    // ------------------------------------------------------------------------
    // SCENARIO 5: Edit Mode Disabled Immunity
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 5: Non-edit mode strictly disables draggables preventing accidental movement', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2'],
        columns: 2,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_5',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int moveCallCount = 0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: false, // EDIT MODE OFF
          onMoveCallbackSpy: (_, _, _) => moveCallCount++,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Draggables must not be present when isEditMode is false
      expect(find.byType(LongPressDraggable<String>), findsNothing);
      expect(moveCallCount, equals(0));
    });

    // ------------------------------------------------------------------------
    // SCENARIO 6: Realistic Instance IDs with Timestamps & Keys
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 6: Complex instance IDs with double underscores correctly suppress self-drop and execute shift', (tester) async {
      const id1 = '1__1712345678000_12345';
      const id2 = '2__1712345678000_67890';
      const id3 = '3__1712345678000_54321';

      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: [id1, id2, id3],
        columns: 3,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_6',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int moveCallCount = 0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
          onMoveCallbackSpy: (_, _, _) => moveCallCount++,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // 1. Self hover on id1
      final center0 = tester.getCenter(find.byType(DragTarget<String>).at(0));
      final gesture = await tester.startGesture(center0);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(center0);
      await tester.pump();

      // No slide displacement on self hover
      final slidesDuringSelfHover = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(slidesDuringSelfHover.any((slide) => slide.offset != Offset.zero), isFalse);

      // Self drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(moveCallCount, equals(0), reason: 'Complex instance ID self-drop must be rejected');

      // 2. Drag id1 to slot 2 (over id3)
      final center2 = tester.getCenter(find.byType(DragTarget<String>).at(2));
      final gesture2 = await tester.startGesture(center0);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture2.moveTo(center2);
      await tester.pump();

      // Targeted slot nudges
      final slides = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(slides.any((s) => s.offset == const Offset(0.06, 0.0)), isTrue);

      await gesture2.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(moveCallCount, equals(1));
      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals([id2, id3, id1]));
    });

    // ------------------------------------------------------------------------
    // SCENARIO 7: Cross-Box Move with Sequence Overflow
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 7: Cross-box move from Box 0 into full Box 1 cascades overflow into auto-created Box 2', (tester) async {
      // Box 1 has ['1'], Box 2 is full with ['2', '3'] (capacity 2)
      final box1 = createTestCustomBox(
        title: 'Kanto 1',
        pokemonIds: ['1'],
        columns: 2,
        rows: 1,
        strictLimits: true,
        patternAutoCreate: true,
      );
      final box2 = createTestCustomBox(
        title: 'Kanto 2',
        pokemonIds: ['2', '3'],
        columns: 2,
        rows: 1,
        strictLimits: true,
        patternAutoCreate: true,
      );

      final liveDex = createTestUserDex(
        id: 'dex_stress_7',
        customBoxes: [box1, box2],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      late DexBoxViewTestHarnessState harnessState;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));

      // Simulate cross-box move: moving '1' from Box 0 into Box 1 at slot 0
      harnessState.handleMove('1', 1, 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Box 0 should be empty
      expect(harnessState.dex.customBoxes[0].pokemonIds, isEmpty);
      // Box 1 should receive '1' at slot 0, shift '2' to slot 1, and '3' should overflow
      expect(harnessState.dex.customBoxes[1].pokemonIds, equals(['1', '2']));
      // A new box 'Kanto 3' must be created containing the overflow item '3'!
      expect(harnessState.dex.customBoxes.length, equals(3));
      expect(harnessState.dex.customBoxes[2].title, equals('Kanto 3'));
      expect(harnessState.dex.customBoxes[2].pokemonIds, equals(['3']));
    });

    // ------------------------------------------------------------------------
    // SCENARIO 8: Gesture Cancellation (Drag Aborted)
    // ------------------------------------------------------------------------
    testWidgets('SCENARIO 8: Aborting drag off-target restores initial UI without mutating state', (tester) async {
      final customBox = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '3'],
        columns: 3,
        rows: 1,
      );
      final liveDex = createTestUserDex(
        id: 'dex_stress_8',
        customBoxes: [customBox],
      );

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int moveCallCount = 0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: liveDex,
          isEditMode: true,
          onMoveCallbackSpy: (_, _, _) => moveCallCount++,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final center0 = tester.getCenter(find.byType(DragTarget<String>).at(0));
      final gesture = await tester.startGesture(center0);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Drag completely off-screen (e.g. into the Scaffold app bar or negative coordinates)
      await gesture.moveTo(const Offset(-100, -100));
      await tester.pump();

      // Release off-screen
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(moveCallCount, equals(0), reason: 'Cancelled drag must not invoke onMovePokemon');
      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      expect(harnessState.dex.customBoxes.first.pokemonIds, equals(['1', '2', '3']));
    });
  });
}
