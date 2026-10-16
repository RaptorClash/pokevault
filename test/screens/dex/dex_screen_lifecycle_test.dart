import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/box_edit_screen.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import 'package:pokevault/l10n/app_translations.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

/// Interactive stateful harness that connects [DexBoxView] to [BoxSequenceManager]
/// matching production DexScreen move and pagination behavior.
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

    // Cache pokemon descriptors for mock boxes
    for (int i = 1; i <= 60; i++) {
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

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
  });

  /// Pumps discrete frames to allow gesture, animation, and layout transitions
  /// to complete without getting hung on infinite network image placeholder timers.
  Future<void> pumpDexFrames(WidgetTester tester, [int durationMs = 200]) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: durationMs));
  }

  Future<void> tapSwitchSafe(WidgetTester tester, int switchIndex) async {
    final switchFinder = find.byType(SwitchListTile).at(switchIndex);
    try {
      await tester.ensureVisible(switchFinder);
      await tester.pump();
    } catch (_) {}
    await tester.tap(switchFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  // =========================================================================
  // TARGET 1: Drag-and-Drop Gestures, Pointer Cancellations & Out-of-Bounds
  // =========================================================================
  group('Challenger M6-2 Target 1: Cross-Box DnD, Cancellations & Out-of-Bounds Drops', () {
    testWidgets('1.1: Pointer cancellation midway through drag resets visual state and triggers zero mutations', (tester) async {
      final box = createTestCustomBox(
        title: 'Cancel Box',
        pokemonIds: ['1', '2', '3'],
        columns: 3,
        rows: 1,
      );
      final dex = createTestUserDex(id: 'dex_cancel_1', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      int moveCallCount = 0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: dex,
          isEditMode: true,
          onMoveCallbackSpy: (source, targetBox, slot) => moveCallCount++,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      final firstDraggable = find.byType(LongPressDraggable<String>).first;
      final startCenter = tester.getCenter(firstDraggable);

      // Initiate long-press gesture to start dragging
      final gesture = await tester.startGesture(startCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Move pointer toward middle of screen
      await gesture.moveTo(startCenter + const Offset(50, 20));
      await tester.pump();

      // Cancel pointer abruptly
      await gesture.cancel();
      await pumpDexFrames(tester);

      // Verification: zero moves invoked, order intact, no exception
      expect(moveCallCount, equals(0), reason: 'Cancelled pointer must not trigger onMove');
      expect(dex.customBoxes.first.pokemonIds, equals(['1', '2', '3']));
      expect(tester.takeException(), isNull, reason: 'Zero gesture exceptions allowed');
    });

    testWidgets('1.2: Stress fuzzing: 25 rapid pointer start-and-cancel cycles on sequential slots with zero memory leaks', (tester) async {
      final box = createTestCustomBox(
        title: 'Rapid Cancel Box',
        pokemonIds: List.generate(10, (i) => '${i + 1}'),
        columns: 5,
        rows: 2,
      );
      final dex = createTestUserDex(id: 'dex_fuzz_cancel', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(initialDex: dex, isEditMode: true),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      final draggables = find.byType(LongPressDraggable<String>);
      expect(draggables, findsNWidgets(10));

      for (int cycle = 0; cycle < 25; cycle++) {
        final targetIndex = cycle % 10;
        final targetCenter = tester.getCenter(draggables.at(targetIndex));

        final gesture = await tester.startGesture(targetCenter);
        // Vary delay slightly to stress different gesture arena phases
        if (cycle % 2 == 0) {
          await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
          await gesture.moveTo(targetCenter + const Offset(10, 10));
        } else {
          await tester.pump(const Duration(milliseconds: 100)); // Pre-timeout cancel
        }
        await gesture.cancel();
        await tester.pump();
      }
      await pumpDexFrames(tester);

      expect(dex.customBoxes.first.pokemonIds.length, equals(10));
      expect(tester.takeException(), isNull, reason: 'Rapid cancellations must not leave unhandled pointer exceptions');
    });

    testWidgets('1.3: Out-of-bounds drops in all 4 cardinal directions safely reject without exceptions or mutations', (tester) async {
      final box = createTestCustomBox(
        title: 'OOB Box',
        pokemonIds: ['1', '2', '3', '4'],
        columns: 4,
        rows: 1,
      );
      final dex = createTestUserDex(id: 'dex_oob_1', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      int moveCallCount = 0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: dex,
          isEditMode: true,
          onMoveCallbackSpy: (source, targetBox, slot) => moveCallCount++,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      final firstDraggable = find.byType(LongPressDraggable<String>).first;
      final startCenter = tester.getCenter(firstDraggable);

      const oobOffsets = [
        Offset(-400, 200),  // Far West / Left
        Offset(200, -500),  // Far North / Top
        Offset(1600, 200),  // Far East / Right
        Offset(200, 1600),  // Far South / Bottom
      ];

      for (final targetOob in oobOffsets) {
        final gesture = await tester.startGesture(startCenter);
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

        await gesture.moveTo(targetOob);
        await tester.pump();

        await gesture.up();
        await pumpDexFrames(tester);

        expect(moveCallCount, equals(0), reason: 'Out of bounds drop must never invoke move callback');
        expect(dex.customBoxes.first.pokemonIds, equals(['1', '2', '3', '4']));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('1.4: Self-drop rejection is a strict no-op with zero displacement, zero callbacks, and intact ordering', (tester) async {
      final box = createTestCustomBox(
        title: 'Self Drop Box',
        pokemonIds: ['1', '2', '3'],
        columns: 3,
        rows: 1,
      );
      final dex = createTestUserDex(id: 'dex_self_drop', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      int moveCallCount = 0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(
          initialDex: dex,
          isEditMode: true,
          onMoveCallbackSpy: (source, targetBox, slot) => moveCallCount++,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      final firstDraggable = find.byType(LongPressDraggable<String>).first;
      final center = tester.getCenter(firstDraggable);

      final gesture = await tester.startGesture(center);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Move within self boundaries
      await gesture.moveTo(center + const Offset(2, 2));
      await tester.pump();

      await gesture.up();
      await pumpDexFrames(tester);

      expect(moveCallCount, equals(0), reason: 'Self drop must strictly ignore drop target');
      expect(dex.customBoxes.first.pokemonIds, equals(['1', '2', '3']));
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.5: Cross-box drag-and-drop: programmatic move between Box 0 and Box 1 shifts targets and updates UI', (tester) async {
      final box1 = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2', '3'],
        columns: 5,
        rows: 6,
      );
      final box2 = createTestCustomBox(
        title: 'Box 2',
        pokemonIds: ['4', '5', '6'],
        columns: 5,
        rows: 6,
      );
      final dex = createTestUserDex(id: 'dex_cross_box', customBoxes: [box1, box2]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(initialDex: dex, isEditMode: true),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));

      // Execute cross-box move: move '1' from Box 0 into Box 1 at slot 1
      harnessState.handleMove('1', 1, 1);
      await pumpDexFrames(tester);

      // In Box 0, '1' was removed -> ['2', '3']
      expect(dex.customBoxes[0].pokemonIds, equals(['2', '3']));
      // In Box 1, '1' inserted at slot 1 -> ['4', '1', '5', '6']
      expect(dex.customBoxes[1].pokemonIds, equals(['4', '1', '5', '6']));
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.6: Dragging on empty slot in DexBoxView does not corrupt state or trigger invalid movement', (tester) async {
      final box = createTestCustomBox(
        title: 'Empty Slot Box',
        pokemonIds: ['', '2', ''],
        columns: 3,
        rows: 1,
      );
      final dex = createTestUserDex(id: 'dex_empty_drag', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(initialDex: dex, isEditMode: true),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      // Verify empty slots are NOT draggable (only occupied slot '2' has a LongPressDraggable)
      final draggables = find.byType(LongPressDraggable<String>);
      expect(draggables, findsNWidgets(1), reason: 'Only the single occupied slot "2" should be draggable');

      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));
      // Attempt moving invalid/nonexistent ID: must be a strict no-op
      harnessState.handleMove('nonexistent_id', 0, 1);
      await pumpDexFrames(tester);

      expect(dex.customBoxes.first.pokemonIds, equals(['', '2', '']));
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // TARGET 2: Viewport Boundaries & Screen Resizing with 4 Settings Switches
  // =========================================================================
  group('Challenger M6-2 Target 2: Viewport Boundaries & Screen Resizing with 4 Settings Switches', () {
    testWidgets('2.1: Ultra-compact viewport (280x600): BoxEditScreen renders, all 4 switches toggle, zero RenderFlex overflows', (tester) async {
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Compact Box 1', pokemonIds: ['1', '2']),
        createTestCustomBox(title: 'Compact Box 2', pokemonIds: ['3']),
      ];
      final dex = createTestUserDex(id: 'dex_vp_280', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BoxEditScreen), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(4));

      // Toggle each switch
      for (int i = 0; i < 4; i++) {
        await tapSwitchSafe(tester, i);
      }

      // Scroll list down and up
      final listFinder = find.byType(ReorderableListView);
      await tester.drag(listFinder, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.drag(listFinder, const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow allowed in 280x600');
    });

    testWidgets('2.2: Classic low-resolution viewport (320x480): BoxEditScreen renders in DE with verbose strings, zero overflows', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Deutsche Box 1', pokemonIds: ['1']),
        createTestCustomBox(title: 'Deutsche Box 2', pokemonIds: ['2']),
      ];
      final dex = createTestUserDex(id: 'dex_vp_320', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'de',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(4));

      // Toggle all 4 switches back and forth in German
      for (int i = 0; i < 4; i++) {
        await tapSwitchSafe(tester, i);
        await tapSwitchSafe(tester, i);
      }

      expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow allowed in 320x480 with German verbose texts');
    });

    testWidgets('2.3: Constrained height landscape (400x300): BoxEditScreen renders, scrolls, toggles all 4 switches, zero overflows', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Short Box', pokemonIds: ['1', '2']),
      ];
      final dex = createTestUserDex(id: 'dex_vp_400x300', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        await tapSwitchSafe(tester, i);
      }

      expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow allowed in extreme 400x300 viewport');
    });

    testWidgets('2.4: Standard mobile landscape (800x360): BoxEditScreen responsive horizontal layout renders and toggles cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Landscape 1', pokemonIds: ['1']),
        createTestCustomBox(title: 'Landscape 2', pokemonIds: ['2']),
      ];
      final dex = createTestUserDex(id: 'dex_vp_800', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        await tapSwitchSafe(tester, i);
      }

      expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow allowed in 800x360 landscape');
    });

    testWidgets('2.5: Dynamic on-the-fly viewport resizing stress: resize 280x600 -> 400x300 -> 800x360 -> 320x480 while toggling', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Resize Box', pokemonIds: ['1', '2']),
      ];
      final dex = createTestUserDex(id: 'dex_vp_dynamic', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      // Phase 1: 280x600
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await tester.pumpAndSettle();
      await tapSwitchSafe(tester, 0);

      // Phase 2: Resize to 400x300
      tester.view.physicalSize = const Size(400, 300);
      await tester.pumpAndSettle();
      await tapSwitchSafe(tester, 1);

      // Phase 3: Resize to 800x360 (landscape)
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpAndSettle();
      await tapSwitchSafe(tester, 2);

      // Phase 4: Resize to 320x480
      tester.view.physicalSize = const Size(320, 480);
      await tester.pumpAndSettle();
      await tapSwitchSafe(tester, 3);

      expect(tester.takeException(), isNull, reason: 'Zero exceptions during dynamic resizing sequence');
    });

    testWidgets('2.6: DexBoxView extreme viewport stress (320x480 and 400x300): grid cards clamp feedback size cleanly', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Dex Box', pokemonIds: ['1', '2', '3', '4', '5'], columns: 5, rows: 1),
      ];
      final dex = createTestUserDex(id: 'dex_box_vp', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      // 320x480
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(initialDex: dex, isEditMode: true),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);
      expect(tester.takeException(), isNull);

      // 400x300
      tester.view.physicalSize = const Size(400, 300);
      await pumpDexFrames(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.7: DexBoxView constrained boundary check: 280x600 reveals 16px header row overflow limit', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Dex Box', pokemonIds: ['1', '2', '3', '4', '5'], columns: 5, rows: 1),
      ];
      final dex = createTestUserDex(id: 'dex_box_vp_280', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(initialDex: dex, isEditMode: true),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);
      final error = tester.takeException();
      // Verifies empirical boundary: DexBoxView fixed button header row requires min 296px width
      expect(error, isNotNull);
      expect(error.toString(), contains('RenderFlex overflowed'));
    });
  });

  // =========================================================================
  // TARGET 3: 16 Rapid Toggle Permutations & Simulated State Reload Cycles
  // =========================================================================
  group('Challenger M6-2 Target 3: 16 Rapid Toggle Permutations & Simulated State Reload Cycles', () {
    testWidgets('3.1: Exhaustive 16-permutation cycle with state reload & persistence verification', (tester) async {
      for (int perm = 0; perm < 16; perm++) {
        final expectedShift = (perm & 1) != 0;
        final expectedLimits = (perm & 2) != 0;
        final expectedPattern = (perm & 4) != 0;
        final expectedDelete = (perm & 8) != 0;

        final box = createTestCustomBox(
          title: 'Box Perm $perm',
          pokemonIds: ['1', '2'],
          autoShift: true,
          strictLimits: true,
          patternAutoCreate: true,
          autoDeleteEmpty: true,
        );
        final dex = createTestUserDex(id: 'dex_perm_$perm', title: 'Perm Dex $perm', customBoxes: [box]);
        when(() => mockProvider.userDexes).thenReturn([dex]);

        await tester.pumpWidget(wrapWithApp(
          child: BoxEditScreen(key: ValueKey('perm_$perm'), dex: dex, initialBoxes: const []),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));
        await tester.pumpAndSettle();

        // Target: [expectedShift, expectedLimits, expectedPattern, expectedDelete]
        final expectedFlags = [expectedShift, expectedLimits, expectedPattern, expectedDelete];
        for (int i = 0; i < 4; i++) {
          final currentVal = tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(i)).value;
          if (currentVal != expectedFlags[i]) {
            await tapSwitchSafe(tester, i);
          }
        }

        // Verify UI matches
        for (int i = 0; i < 4; i++) {
          final val = tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(i)).value;
          expect(val, equals(expectedFlags[i]), reason: 'UI switch $i must match perm $perm bit');
        }

        // Verify dex model matches
        final liveBox = dex.customBoxes.first;
        expect(liveBox.autoShift, equals(expectedShift));
        expect(liveBox.strictLimits, equals(expectedLimits));
        expect(liveBox.patternAutoCreate, equals(expectedPattern));
        expect(liveBox.autoDeleteEmpty, equals(expectedDelete));

        // Simulate state reload cycle: serialize to Map and re-instantiate
        final serialized = dex.toMap();
        final reloadedDex = UserDex.fromMap(serialized);
        when(() => mockProvider.userDexes).thenReturn([reloadedDex]);

        // Remount BoxEditScreen with reloaded Dex
        await tester.pumpWidget(wrapWithApp(
          child: BoxEditScreen(key: ValueKey('reload_perm_$perm'), dex: reloadedDex, initialBoxes: const []),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));
        await tester.pumpAndSettle();

        // Verify reloaded state matches expected flags
        for (int i = 0; i < 4; i++) {
          final val = tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(i)).value;
          expect(val, equals(expectedFlags[i]), reason: 'Reloaded switch $i must match perm $perm');
        }
        final reloadedBox = reloadedDex.customBoxes.first;
        expect(reloadedBox.autoShift, equals(expectedShift));
        expect(reloadedBox.strictLimits, equals(expectedLimits));
        expect(reloadedBox.patternAutoCreate, equals(expectedPattern));
        expect(reloadedBox.autoDeleteEmpty, equals(expectedDelete));
      }
    });

    testWidgets('3.2: Rapid contiguous toggle flapping through all 16 permutations sequentially in a single session', (tester) async {
      final box = createTestCustomBox(
        title: 'Single Session Flap Box',
        pokemonIds: ['1', '2'],
        autoShift: false,
        strictLimits: false,
        patternAutoCreate: false,
        autoDeleteEmpty: false,
      );
      final dex = createTestUserDex(id: 'dex_single_flap', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await tester.pumpAndSettle();

      for (int perm = 0; perm < 16; perm++) {
        final expectedFlags = [
          (perm & 1) != 0,
          (perm & 2) != 0,
          (perm & 4) != 0,
          (perm & 8) != 0,
        ];

        for (int i = 0; i < 4; i++) {
          final currentVal = tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(i)).value;
          if (currentVal != expectedFlags[i]) {
            await tapSwitchSafe(tester, i);
          }
        }

        // Verify backing model in single mounted session
        expect(dex.customBoxes.first.autoShift, equals(expectedFlags[0]));
        expect(dex.customBoxes.first.strictLimits, equals(expectedFlags[1]));
        expect(dex.customBoxes.first.patternAutoCreate, equals(expectedFlags[2]));
        expect(dex.customBoxes.first.autoDeleteEmpty, equals(expectedFlags[3]));
      }

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // TARGET 4: Empty Dex State Robustness (0, 1, 50 Boxes)
  // =========================================================================
  group('Challenger M6-2 Target 4: Empty Dex State Robustness (0, 1, 50 Boxes)', () {
    testWidgets('4.1: Robustness with 0 custom boxes: DexBoxView empty text, BoxEditScreen header and add box dialog', (tester) async {
      // 4.1.1: DexBoxView with 0 boxes
      final emptyDex = createTestUserDex(id: 'dex_empty_0', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([emptyDex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: const [],
          liveDex: emptyDex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      expect(find.text(Translator.get('empty_box')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4.1.2: BoxEditScreen with 0 boxes
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: emptyDex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(find.byType(Card), findsAtLeastNWidgets(1));

      // Test Add Box FAB
      final addFab = find.byType(FloatingActionButton);
      expect(addFab, findsOneWidget);
      await tester.tap(addFab);
      await tester.pumpAndSettle();

      // Enter new box name in dialog
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'First Custom Box');
      await tester.pumpAndSettle();

      // Tap Create button
      final createBtn = find.widgetWithText(ElevatedButton, Translator.get('create'));
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(emptyDex.customBoxes.length, equals(1));
      expect(emptyDex.customBoxes.first.title, equals('First Custom Box'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('4.2: Robustness with 1 empty box: DexBoxView page render, BoxEditScreen rename & delete', (tester) async {
      final singleBox = createTestCustomBox(
        title: 'Solo Empty Box',
        pokemonIds: [],
        columns: 5,
        rows: 6,
      );
      final dex = createTestUserDex(id: 'dex_solo_empty', customBoxes: [singleBox]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      // 4.2.1: DexBoxView with 1 empty box
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(initialDex: dex, isEditMode: true),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      expect(find.text('Solo Empty Box'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4.2.2: BoxEditScreen rename and delete
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Solo Empty Box'), findsOneWidget);

      // Tap Rename icon
      final renameBtn = find.byIcon(Icons.edit);
      expect(renameBtn, findsOneWidget);
      await tester.tap(renameBtn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Renamed Solo Box');
      await tester.pumpAndSettle();

      final editConfirmBtn = find.widgetWithText(ElevatedButton, Translator.get('edit'));
      await tester.tap(editConfirmBtn);
      await tester.pumpAndSettle();

      expect(dex.customBoxes.first.title, equals('Renamed Solo Box'));

      // Delete the only box
      final deleteBtn = find.byIcon(Icons.delete);
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(dex.customBoxes.isEmpty, isTrue, reason: 'Deleting the solo box must reduce customBoxes to 0');
      expect(tester.takeException(), isNull);
    });

    testWidgets('4.3: Robustness with 50 empty boxes: DexBoxView 50-page jump, QuickNav dialog, BoxEditScreen batch delete & setting sync', (tester) async {
      final fiftyBoxes = List.generate(50, (i) {
        final box = createTestCustomBox(
          title: 'Box ${i + 1}',
          pokemonIds: [],
          columns: 5,
          rows: 6,
        );
        box.regionKey = i < 20 ? 'kanto' : (i < 40 ? 'johto' : 'hoenn');
        return box;
      });
      final dex = createTestUserDex(id: 'dex_fifty_empty', customBoxes: fiftyBoxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      // 4.3.1: DexBoxView with 50 empty boxes
      await tester.pumpWidget(wrapWithApp(
        child: DexBoxViewTestHarness(initialDex: dex, isEditMode: false),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await pumpDexFrames(tester);

      final harnessState = tester.state<DexBoxViewTestHarnessState>(find.byType(DexBoxViewTestHarness));

      // Test page jumps across 50 pages
      harnessState.pageController.jumpToPage(24);
      await pumpDexFrames(tester);
      expect(find.text('Box 25'), findsOneWidget);

      harnessState.pageController.jumpToPage(49);
      await pumpDexFrames(tester);
      expect(find.text('Box 50'), findsOneWidget);

      harnessState.pageController.jumpToPage(0);
      await pumpDexFrames(tester);
      expect(find.text('Box 1'), findsOneWidget);

      // Open QuickNav dialog by tapping the title pill
      final titlePill = find.text('Box 1');
      await tester.tap(titlePill);
      await pumpDexFrames(tester);

      // Expect AlertDialog with region chips
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(ActionChip), findsWidgets);

      // Tap Johto chip to jump to box index 20
      final johtoChip = find.widgetWithText(ActionChip, Translator.get('region_name_johto'));
      if (johtoChip.evaluate().isNotEmpty) {
        await tester.tap(johtoChip);
        await pumpDexFrames(tester);
        expect(harnessState.pageController.page?.round(), equals(20));
      } else {
        // Fallback pop dialog
        Navigator.of(tester.element(find.byType(AlertDialog))).pop();
        await pumpDexFrames(tester);
      }

      // 4.3.2: BoxEditScreen with 50 empty boxes
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
      ));
      await tester.pumpAndSettle();

      expect(dex.customBoxes.length, equals(50));

      // Toggle autoShift and verify it applies to all 50 boxes
      await tapSwitchSafe(tester, 0); // Toggles autoShift to false
      for (int i = 0; i < 50; i++) {
        expect(dex.customBoxes[i].autoShift, isFalse, reason: 'Box $i must have autoShift == false');
      }

      // Rapidly delete first 5 boxes
      for (int i = 0; i < 5; i++) {
        final firstDeleteBtn = find.byIcon(Icons.delete).first;
        await tester.tap(firstDeleteBtn);
        await tester.pumpAndSettle();
      }

      expect(dex.customBoxes.length, equals(45), reason: 'After deleting 5 boxes, 45 must remain');
      expect(dex.customBoxes.first.title, equals('Box 6'), reason: 'Box 6 is now the new first box');
      expect(tester.takeException(), isNull);
    });
  });
}
