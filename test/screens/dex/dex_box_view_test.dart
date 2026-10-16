import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/dex_view_models.dart';
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

  group('DexBoxView Drag & Drop Widget Tests', () {
    testWidgets('Drag gesture invokes onMovePokemon callback with correct indices', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 2, nameEn: 'Ivysaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        createTestEntry(pokemon: poke2, uniqueId: '2'),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

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
          onMovePokemon: (sourceId, targetBox, targetIndex) {
            movedSourceId = sourceId;
            movedTargetBox = targetBox;
            movedTargetIndex = targetIndex;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      expect(find.byType(LongPressDraggable<String>), findsNWidgets(2));
      expect(find.byType(DragTarget<String>), findsNWidgets(2));

      // Obtain coordinates before initiating drag
      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final secondCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      // Start drag with long press gesture
      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Move to second slot
      await gesture.moveTo(secondCenter);
      await tester.pump();

      // Release gesture to drop
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(movedSourceId, equals('1'));
      expect(movedTargetBox, equals(0));
      expect(movedTargetIndex, equals(1));
    });

    testWidgets('Hovering over occupied card renders insertion indicator seam', (tester) async {
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
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final secondCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Hover over second slot without releasing
      await gesture.moveTo(secondCenter);
      await tester.pump();

      // AnimatedSlide with offset (0.06, 0.0) indicates targeted card displacement
      final animatedSlides = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(animatedSlides.any((slide) => slide.offset == const Offset(0.06, 0.0)), isTrue,
          reason: 'Targeted card must slide right to make space for insertion');

      // Finish gesture
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Hovering over empty slot transforms add icon to downward arrow', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        DexDisplayEntry.emptyEntry,
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
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Initially only Icons.add is displayed
      expect(find.byIcon(Icons.arrow_downward), findsNothing);

      final firstCenter = tester.getCenter(find.byType(LongPressDraggable<String>).first);
      final emptySlotCenter = tester.getCenter(find.byType(DragTarget<String>).at(1));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Hover over empty slot
      await gesture.moveTo(emptySlotCenter);
      await tester.pump();

      // Verify downward arrow indicator appears
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget,
          reason: 'Hovering over empty slot should display downward arrow');

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Tapping empty slot invokes onInsertPokemon', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameEn: 'Bulbasaur');
      final entries = [
        createTestEntry(pokemon: poke1, uniqueId: '1'),
        DexDisplayEntry.emptyEntry,
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries);
      final liveDex = createTestUserDex(id: 'dex1', title: 'Kanto');

      when(() => mockProvider.userDexes).thenReturn([liveDex]);

      int? insertedBox;
      int? insertedSlot;

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
            insertedBox = boxIndex;
            insertedSlot = insertIndex;
          },
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));

      // Tap the empty slot (index 1)
      final emptySlot = find.byType(DragTarget<String>).at(1);
      await tester.tap(emptySlot);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(insertedBox, equals(0));
      expect(insertedSlot, equals(1));
    });
  });
}
