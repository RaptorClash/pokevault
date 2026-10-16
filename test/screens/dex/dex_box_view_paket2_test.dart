import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import '../../e2e/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockProvider;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
  });

  group('DexBoxView Paket 2 Tests', () {
    testWidgets('Dropping on card center invokes onSwapPokemon (1:1 Swap)', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      String? swappedSourceId;
      int? swappedTargetBox;
      int? swappedTargetIndex;

      String? movedSourceId;

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
          onSwapPokemon: (sourceId, targetBox, targetIndex) {
            swappedSourceId = sourceId;
            swappedTargetBox = targetBox;
            swappedTargetIndex = targetIndex;
          },
          onMovePokemon: (sourceId, targetBox, targetIndex) {
            movedSourceId = sourceId;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final secondCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Drag to center of second card
      await gesture.moveTo(secondCenter);
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(swappedSourceId, equals('1'));
      expect(swappedTargetBox, equals(0));
      expect(swappedTargetIndex, equals(1));
      expect(movedSourceId, isNull, reason: 'Center drop should swap, not shift/insert');
    });

    testWidgets('Dropping on card left edge invokes onMovePokemon (Insert with Shift)', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      String? swappedSourceId;
      String? movedSourceId;
      int? movedTargetBox;
      int? movedTargetIndex;

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
          onSwapPokemon: (sourceId, targetBox, targetIndex) {
            swappedSourceId = sourceId;
          },
          onMovePokemon: (sourceId, targetBox, targetIndex) {
            movedSourceId = sourceId;
            movedTargetBox = targetBox;
            movedTargetIndex = targetIndex;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final secondTopLeft = tester.getTopLeft(find.byType(DragTarget<String>).at(1));
      // Point close to the left edge of slot 2
      final secondEdge = secondTopLeft + const Offset(10, 30);

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Drag to edge of second card
      await gesture.moveTo(secondEdge);
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(movedSourceId, equals('1'));
      expect(movedTargetBox, equals(0));
      expect(movedTargetIndex, equals(1));
      expect(swappedSourceId, isNull, reason: 'Edge drop should insert/move, not swap');
    });

    testWidgets('Hovering over card center renders swap visual feedback (scale 1.05 and amber glow)', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
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
          isEditMode: true,
          onSwapPokemon: (s, b, i) {},
          onMovePokemon: (s, b, i) {},
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final secondCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Move to center of second card
      await gesture.moveTo(secondCenter);
      await tester.pump();

      // Verify scale 1.05 is active on AnimatedScale
      final animatedScales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));
      expect(animatedScales.any((scale) => scale.scale == 1.05), isTrue,
          reason: 'Hovering center must scale card up for swap indication');

      // Finish drag
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Static + button in gap has touch target of at least 44x44 and invokes onInsertPokemon', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int? tappedInsertBox;
      int? tappedInsertIndex;

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
          onInsertPokemon: (boxIndex, insertIndex) {
            tappedInsertBox = boxIndex;
            tappedInsertIndex = insertIndex;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Look for the static '+' button
      final addIcons = find.byIcon(Icons.add);
      expect(addIcons, findsWidgets);

      // Verify that the GestureDetector has at least 44x44 touch target
      final plusGestureFinders = find.ancestor(
        of: addIcons.first,
        matching: find.byType(GestureDetector),
      );
      expect(plusGestureFinders, findsWidgets);

      final containerFinder = find.ancestor(
        of: addIcons.first,
        matching: find.byType(Container),
      );
      final containers = tester.widgetList<Container>(containerFinder);
      final touchTarget = containers.firstWhere(
        (c) => (c.constraints?.minWidth ?? 0) >= 44 || (c.constraints?.maxWidth ?? 0) >= 44,
        orElse: () => Container(),
      );
      expect(touchTarget.constraints?.maxWidth, greaterThanOrEqualTo(44.0));

      // Tap the + button
      await tester.tap(addIcons.first);
      await tester.pump();

      expect(tappedInsertBox, isNotNull);
      expect(tappedInsertIndex, isNotNull);
    });

    testWidgets('Dragging reveals edge autoscroll and chevron DragTargets for cross-box navigation', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final entries1 = [createTestEntry(pokemon: poke1, uniqueId: '1')];
      final entries2 = [createTestEntry(pokemon: poke1, uniqueId: '2')];

      final box1 = createTestBoxData(title: 'Box 1', entries: entries1);
      final box2 = createTestBoxData(title: 'Box 2', entries: entries2);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

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
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Before dragging: exactly 1 DragTarget for slot
      final initialDragTargetCount = tester.widgetList(find.byType(DragTarget<String>)).length;

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // While dragging: extra DragTargets appear for edge autoscroll zones and chevrons
      final draggingDragTargetCount = tester.widgetList(find.byType(DragTarget<String>)).length;
      expect(draggingDragTargetCount, greaterThan(initialDragTargetCount),
          reason: 'Active drag must enable edge and chevron DragTargets for cross-box navigation');

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Drag starting at extreme edge of card A still reliably swaps when dropped on center of card B', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      String? swappedSourceId;
      int? swappedTargetBox;
      int? swappedTargetIndex;

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
          onSwapPokemon: (sourceId, targetBox, targetIndex) {
            swappedSourceId = sourceId;
            swappedTargetBox = targetBox;
            swappedTargetIndex = targetIndex;
          },
          onMovePokemon: (s, b, i) {},
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstTopLeft = tester.getTopLeft(find.byType(LongPressDraggable<String>).first);
      final secondCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      // User starts long-press near the extreme edge (e.g. +4, +4) of card 1
      final gesture = await tester.startGesture(firstTopLeft + const Offset(4, 4));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Move directly to the center of card 2
      await gesture.moveTo(secondCenter);
      await tester.pump();

      // Drop on center
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(swappedSourceId, equals('1'), reason: 'Center drop must swap even if drag started at extreme edge');
      expect(swappedTargetBox, equals(0));
      expect(swappedTargetIndex, equals(1));
    });

    testWidgets('Hovering center of a card shows swap badge and does NOT trigger insertion seam on adjacent cards', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final poke3 = createTestPokemon(id: 3, nameEn: 'Venusaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
        createTestEntry(pokemon: poke3, uniqueId: '3'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
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
          isEditMode: true,
          onSwapPokemon: (s, b, i) {},
          onMovePokemon: (s, b, i) {},
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final secondCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Hover over slot 1 center
      await gesture.moveTo(secondCenter);
      await tester.pump();

      // Should show swap badge
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      // No card should slide right with (0.06, 0.0)
      final animatedSlides = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(animatedSlides.any((slide) => slide.offset == const Offset(0.06, 0.0)), isFalse,
          reason: 'No card should slide right when hovering for swap');

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
