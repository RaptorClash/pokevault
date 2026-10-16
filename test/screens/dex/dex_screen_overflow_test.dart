import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import '../../e2e/e2e_test_helper.dart';

/// Interactive UI test harness mirroring the exact state management,
/// asynchronous recalculation queue, PageController preservation,
/// and insertion workflows of [DexScreen].
class DexScreenStressHarness extends StatefulWidget {
  final UserDex initialDex;
  final List<Pokemon> pokemonList;
  final bool initialEditMode;
  final Duration simulatedAsyncDelay;

  const DexScreenStressHarness({
    super.key,
    required this.initialDex,
    required this.pokemonList,
    this.initialEditMode = true,
    this.simulatedAsyncDelay = Duration.zero,
  });

  @override
  State<DexScreenStressHarness> createState() => DexScreenStressHarnessState();
}

class DexScreenStressHarnessState extends State<DexScreenStressHarness> {
  late UserDex liveDex;
  late PageController pageController;
  late bool isEditMode;
  bool isCalculatingBoxes = false;
  bool pendingRecalculate = false;
  int recalculateExecutionCount = 0;

  List<BoxData> boxes = [];
  final Map<String, Pokemon> pokemonMap = {};

  @override
  void initState() {
    super.initState();
    liveDex = widget.initialDex;
    pageController = PageController();
    isEditMode = widget.initialEditMode;

    for (var p in widget.pokemonList) {
      pokemonMap['${p.id}'] = p;
      pokemonMap['${p.id}_normal'] = p;
    }

    _recalculateBoxesSync();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _recalculateBoxesSync() {
    if (liveDex.customBoxes.isEmpty) {
      boxes = [
        BoxData('Box 1', 'custom', List.generate(30, (_) => DexDisplayEntry.emptyEntry), 5),
      ];
      return;
    }

    boxes = liveDex.customBoxes.map((cb) {
      final entries = cb.pokemonIds.map((id) {
        if (id.isEmpty) return DexDisplayEntry.emptyEntry;
        final baseIdStr = DexLogicHelper.getBaseId(id);
        final pId = int.tryParse(baseIdStr) ?? 1;
        final pokemon = pokemonMap[baseIdStr] ??
            pokemonMap['$pId'] ??
            createTestPokemon(id: pId, nameEn: 'Pokemon_$pId');
        return createTestEntry(pokemon: pokemon, uniqueId: id);
      }).toList();

      while (entries.length < cb.capacity) {
        entries.add(DexDisplayEntry.emptyEntry);
      }

      return BoxData(cb.title, cb.regionKey, entries, cb.columns);
    }).toList();
  }

  /// Faithful reproduction of DexScreen._recalculateBoxesAsync
  Future<void> recalculateBoxesAsync() async {
    if (!mounted) return;
    if (isCalculatingBoxes) {
      pendingRecalculate = true;
      return;
    }

    int? savedPage;
    if (pageController.hasClients) {
      savedPage = pageController.page?.round();
    }

    setState(() => isCalculatingBoxes = true);
    recalculateExecutionCount++;

    if (widget.simulatedAsyncDelay > Duration.zero) {
      await Future.delayed(widget.simulatedAsyncDelay);
    }

    if (!mounted) return;

    setState(() {
      _recalculateBoxesSync();
      isCalculatingBoxes = false;
    });

    if (savedPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) {
          int targetPage = savedPage!;
          if (targetPage >= boxes.length && boxes.isNotEmpty) {
            targetPage = boxes.length - 1;
          }
          pageController.jumpToPage(targetPage);
        }
      });
    }

    if (mounted && pendingRecalculate) {
      pendingRecalculate = false;
      await recalculateBoxesAsync();
    }
  }

  /// Faithful reproduction of DexScreen.onInsertPokemon
  Future<void> triggerInsertPokemon({
    required int boxIndex,
    required int insertIndex,
    required String selectedId,
  }) async {
    if (liveDex.customBoxes.isEmpty) {
      liveDex.customBoxes = boxes.map((b) {
        int c = 0;
        return CustomBoxState(
          title: b.title,
          pokemonIds: b.entries
              .map((e) => e.uniqueId.isNotEmpty
                  ? '${e.uniqueId}__${DateTime.now().millisecondsSinceEpoch}_${c++}'
                  : '')
              .toList(),
          regionKey: b.regionKey,
        );
      }).toList();
    }

    final instanceId =
        '${selectedId}__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';

    BoxSequenceManager.insertWithShiftAndOverflow(
      dex: liveDex,
      boxIndex: boxIndex,
      slotIndex: insertIndex,
      pokemonId: instanceId,
    );

    await recalculateBoxesAsync();
  }

  /// Faithful reproduction of DexScreen AppBar add button
  Future<void> triggerAppBarAdd({required String selectedId}) async {
    int currentBoxIndex = 0;
    if (pageController.hasClients) {
      currentBoxIndex = pageController.page?.round() ?? 0;
    }

    if (liveDex.customBoxes.isEmpty) {
      liveDex.customBoxes = boxes.map((b) {
        int c = 0;
        return CustomBoxState(
          title: b.title,
          pokemonIds: b.entries
              .map((e) => e.uniqueId.isNotEmpty
                  ? '${e.uniqueId}__${DateTime.now().millisecondsSinceEpoch}_${c++}'
                  : '')
              .toList(),
          regionKey: b.regionKey,
        );
      }).toList();
    }

    if (currentBoxIndex < liveDex.customBoxes.length) {
      final box = liveDex.customBoxes[currentBoxIndex];
      int targetSlot = box.pokemonIds.indexOf("");
      if (targetSlot == -1) {
        targetSlot = box.pokemonIds.length;
      }

      final instanceId =
          '${selectedId}__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';

      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: liveDex,
        boxIndex: currentBoxIndex,
        slotIndex: targetSlot,
        pokemonId: instanceId,
      );

      await recalculateBoxesAsync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(liveDex.title),
        actions: [
          if (isEditMode)
            IconButton(
              key: const Key('app_bar_add_button'),
              icon: const Icon(Icons.add),
              onPressed: () => triggerAppBarAdd(selectedId: '25'),
            ),
        ],
      ),
      body: DexBoxView(
        boxes: boxes,
        liveDex: liveDex,
        provider: MockDexProvider(),
        pageController: pageController,
        separateForms: true,
        highlightedIds: const {},
        isSearchActive: false,
        isEditMode: isEditMode,
        onInsertPokemon: (boxIndex, insertIndex) {
          triggerInsertPokemon(
            boxIndex: boxIndex,
            insertIndex: insertIndex,
            selectedId: '25',
          );
        },
      ),
    );
  }
}

extension PumpSettleHelper on WidgetTester {
  /// Pumps frames and flushes microtasks without timing out on infinite
  /// CircularProgressIndicator animation tickers from CachedNetworkImage.
  Future<void> pumpAndFlush([Duration duration = const Duration(milliseconds: 150)]) async {
    await pump();
    await pump(duration);
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

  group('Challenger M3-2: UI Insertion Overflow & Multi-Box Creation Stress Suite', () {
    // =========================================================================
    // SCENARIO 1: External Insertion into Full Box (30 items) & Auto-Creation
    // =========================================================================

    testWidgets(
      'S1.1: Inserting at index 0 into full box "Test 1" (30 items) shifts items, auto-creates "Test 2", and spills 30th item',
      (tester) async {
        final p30Ids = List.generate(30, (i) => 'P_${i + 1}');
        final box1 = createTestCustomBox(
          title: 'Test 1',
          pokemonIds: p30Ids,
          columns: 5,
          rows: 6,
        );
        final liveDex = createTestUserDex(
          id: 'dex_s1_1',
          title: 'Stress Dex S1.1',
          customBoxes: [box1],
        );

        final testPokemon = List.generate(
          35,
          (i) => createTestPokemon(id: i + 1, nameEn: 'Pokemon_${i + 1}'),
        );

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: testPokemon,
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        // Initial state assertions
        expect(find.text('Test 1'), findsOneWidget);
        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );
        expect(state.boxes.length, equals(1));
        expect(state.liveDex.customBoxes.length, equals(1));
        expect(state.liveDex.customBoxes.first.pokemonIds.length, equals(30));

        // Trigger insertion at slot 0 via UI onInsertPokemon callback
        await state.triggerInsertPokemon(
          boxIndex: 0,
          insertIndex: 0,
          selectedId: '25',
        );
        await tester.pumpAndFlush();

        // Verification 1: Exactly 2 boxes exist now
        expect(state.liveDex.customBoxes.length, equals(2),
            reason: 'Inserting into full Test 1 must auto-create Test 2');
        expect(state.boxes.length, equals(2));

        // Verification 2: First box properties
        final updatedBox1 = state.liveDex.customBoxes[0];
        expect(updatedBox1.title, equals('Test 1'));
        expect(updatedBox1.pokemonIds.length, equals(30));
        expect(updatedBox1.pokemonIds[0], startsWith('25__'),
            reason: 'Newly inserted item must be placed at index 0 with composite instance ID');
        expect(updatedBox1.pokemonIds[1], equals('P_1'),
            reason: 'Former first item must be shifted to index 1');
        expect(updatedBox1.pokemonIds[29], equals('P_29'),
            reason: '29th item should be at the end of Test 1');

        // Verification 3: Auto-created second box properties
        final updatedBox2 = state.liveDex.customBoxes[1];
        expect(updatedBox2.title, equals('Test 2'),
            reason: 'New box title must follow sequence numbering');
        expect(updatedBox2.pokemonIds.length, equals(1));
        expect(updatedBox2.pokemonIds[0], equals('P_30'),
            reason: 'Spilled 30th item must reside in Test 2 at index 0');

        // Verification 4: UI rendering verifies Box 1 title still on screen
        expect(find.text('Test 1'), findsOneWidget);

        // Verification 5: Swiping/navigating to Page 1 reveals "Test 2"
        state.pageController.jumpToPage(1);
        await tester.pumpAndFlush();
        expect(find.text('Test 2'), findsOneWidget);
      },
    );

    testWidgets(
      'S1.2: Multi-box cascading across two full linked boxes ("Test 1" & "Test 2") auto-creates "Test 3"',
      (tester) async {
        final box1Ids = List.generate(30, (i) => 'B1_${i + 1}');
        final box2Ids = List.generate(30, (i) => 'B2_${i + 1}');
        final box1 = createTestCustomBox(
          title: 'Test 1',
          pokemonIds: box1Ids,
          columns: 5,
          rows: 6,
        );
        final box2 = createTestCustomBox(
          title: 'Test 2',
          pokemonIds: box2Ids,
          columns: 5,
          rows: 6,
        );
        final liveDex = createTestUserDex(
          id: 'dex_s1_2',
          title: 'Stress Dex S1.2',
          customBoxes: [box1, box2],
        );

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );
        expect(state.liveDex.customBoxes.length, equals(2));

        // Insert at beginning of Test 1
        await state.triggerInsertPokemon(
          boxIndex: 0,
          insertIndex: 0,
          selectedId: '25',
        );
        await tester.pumpAndFlush();

        // Must cascade: Test 1 -> Test 2 -> Test 3
        expect(state.liveDex.customBoxes.length, equals(3),
            reason: 'Cascading overflow through two full boxes must auto-create Test 3');
        expect(state.liveDex.customBoxes[0].title, equals('Test 1'));
        expect(state.liveDex.customBoxes[1].title, equals('Test 2'));
        expect(state.liveDex.customBoxes[2].title, equals('Test 3'));

        expect(state.liveDex.customBoxes[0].pokemonIds.first, startsWith('25__'));
        expect(state.liveDex.customBoxes[1].pokemonIds.first, equals('B1_30'));
        expect(state.liveDex.customBoxes[2].pokemonIds.first, equals('B2_30'));
      },
    );

    testWidgets(
      'S1.3: Pattern isolation in UI — "Kanto 1" overflow auto-creates "Kanto 2" and never pollutes "Kanto Tausch"',
      (tester) async {
        final kanto1Ids = List.generate(30, (i) => 'K1_${i + 1}');
        final box1 = createTestCustomBox(title: 'Kanto 1', pokemonIds: kanto1Ids, columns: 5, rows: 6);
        final unrelatedBox = createTestCustomBox(title: 'Kanto Tausch', pokemonIds: ['Trade_1'], columns: 5, rows: 6);
        final liveDex = createTestUserDex(
          id: 'dex_s1_3',
          title: 'Stress Dex S1.3',
          customBoxes: [box1, unrelatedBox],
        );

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        // Insert into Kanto 1
        await state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: '25');
        await tester.pumpAndFlush();

        // Assert Kanto 2 was created and Kanto Tausch is untouched
        expect(state.liveDex.customBoxes.length, equals(3));
        expect(state.liveDex.customBoxes[0].title, equals('Kanto 1'));
        expect(state.liveDex.customBoxes[1].title, equals('Kanto 2'));
        expect(state.liveDex.customBoxes[2].title, equals('Kanto Tausch'));

        // Verify Kanto Tausch contents are completely isolated
        expect(state.liveDex.customBoxes[2].pokemonIds, equals(['Trade_1']),
            reason: 'Kanto Tausch must remain strictly unaffected by Kanto 1 overflow');
        expect(state.liveDex.customBoxes[1].pokemonIds, equals(['K1_30']));
      },
    );

    // =========================================================================
    // SCENARIO 2: PageView Stability & Scroll Position Retention
    // =========================================================================

    testWidgets(
      'S2.1: PageView controller retains current page index (Page 0) after insertion causes box auto-creation',
      (tester) async {
        final p30Ids = List.generate(30, (i) => 'P_${i + 1}');
        final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: p30Ids, columns: 5, rows: 6);
        final liveDex = createTestUserDex(id: 'dex_s2_1', customBoxes: [box1]);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        expect(state.pageController.page?.round(), equals(0));

        // Insert into Box 1 at slot 0
        await state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: '25');
        await tester.pumpAndFlush();

        // Verify page controller did NOT reset or get displaced
        expect(state.pageController.page?.round(), equals(0),
            reason: 'PageView must strictly retain Page 0 after auto-creation');
        expect(find.text('Box 1'), findsOneWidget);
        expect(state.boxes.length, equals(2));
      },
    );

    testWidgets(
      'S2.2: PageView controller retains Page 1 when user inserts while viewing Page 1 of multi-box sequence',
      (tester) async {
        final b1Ids = List.generate(30, (i) => 'B1_${i + 1}');
        final b2Ids = List.generate(30, (i) => 'B2_${i + 1}');
        final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: b1Ids, columns: 5, rows: 6);
        final box2 = createTestCustomBox(title: 'Box 2', pokemonIds: b2Ids, columns: 5, rows: 6);
        final liveDex = createTestUserDex(id: 'dex_s2_2', customBoxes: [box1, box2]);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        // User navigates to Page 1 ("Box 2")
        state.pageController.jumpToPage(1);
        await tester.pumpAndFlush();
        expect(state.pageController.page?.round(), equals(1));
        expect(find.text('Box 2'), findsOneWidget);

        // User inserts into Box 2 (at slotIndex 10)
        await state.triggerInsertPokemon(boxIndex: 1, insertIndex: 10, selectedId: '25');
        await tester.pumpAndFlush();

        // Verification: PageView MUST still be on Page 1!
        expect(state.pageController.page?.round(), equals(1),
            reason: 'PageView must remain stable on Page 1 (Box 2) rather than jumping to Page 0');
        expect(find.text('Box 2'), findsOneWidget);
        expect(state.boxes.length, equals(3));
        expect(state.liveDex.customBoxes[2].title, equals('Box 3'));
        expect(state.liveDex.customBoxes[2].pokemonIds, equals(['B2_30']));
      },
    );

    testWidgets(
      'S2.3: Scroll offset is retained via PageStorageKey when CustomScrollView undergoes recalculation',
      (tester) async {
        // Create 30 items
        final p30Ids = List.generate(30, (i) => 'P_${i + 1}');
        final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: p30Ids, columns: 5, rows: 6);
        final liveDex = createTestUserDex(id: 'dex_s2_3', customBoxes: [box1]);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        // Wrap in constrained height to enable vertical scroll offset
        await tester.pumpWidget(wrapWithApp(
          child: SizedBox(
            height: 350,
            width: 300,
            child: DexScreenStressHarness(
              initialDex: liveDex,
              pokemonList: const [],
              initialEditMode: true,
            ),
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final scrollableFinder = find.byWidgetPredicate(
          (w) => w is Scrollable && (w.axisDirection == AxisDirection.down || w.axisDirection == AxisDirection.up),
        ).first;
        expect(scrollableFinder, findsOneWidget);

        // Drag down to scroll
        await tester.drag(scrollableFinder, const Offset(0, -100));
        await tester.pumpAndFlush();

        final scrollPositionBefore = tester.state<ScrollableState>(scrollableFinder).position.pixels;
        expect(scrollPositionBefore, greaterThan(0.0), reason: 'Scroll position should be positive');

        // Trigger insertion
        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );
        await state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: '25');
        await tester.pumpAndFlush();

        // CustomScrollView should preserve scroll offset via PageStorageKey
        final scrollPositionAfter = tester.state<ScrollableState>(scrollableFinder).position.pixels;
        expect(scrollPositionAfter, closeTo(scrollPositionBefore, 1.0),
            reason: 'Scroll position must be preserved across insertion recalculations');
      },
    );

    // =========================================================================
    // SCENARIO 3: Multi-Insertion Sequence & Rapid Concurrency Stress
    // =========================================================================

    testWidgets(
      'S3.1: Sequential 35 insertions cascade and auto-create multiple sequence boxes with 100% item conservation',
      (tester) async {
        final initialIds = List.generate(30, (i) => 'Init_${i + 1}');
        final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: initialIds, columns: 5, rows: 6);
        final liveDex = createTestUserDex(id: 'dex_s3_1', customBoxes: [box1]);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        // Execute 35 successive insertions at index 0 of Box 1
        for (int i = 1; i <= 35; i++) {
          await state.triggerInsertPokemon(
            boxIndex: 0,
            insertIndex: 0,
            selectedId: 'New_$i',
          );
        }
        await tester.pumpAndFlush();

        // Analysis of resulting boxes:
        // Total items = 30 initial + 35 new = 65 items.
        // Box 1 capacity: 30 items
        // Box 2 capacity: 30 items
        // Box 3 capacity: 5 items
        expect(state.liveDex.customBoxes.length, equals(3),
            reason: '65 total items with 30-capacity boxes must populate exactly 3 sequence boxes');
        expect(state.liveDex.customBoxes[0].title, equals('Box 1'));
        expect(state.liveDex.customBoxes[1].title, equals('Box 2'));
        expect(state.liveDex.customBoxes[2].title, equals('Box 3'));

        expect(state.liveDex.customBoxes[0].pokemonIds.length, equals(30));
        expect(state.liveDex.customBoxes[1].pokemonIds.length, equals(30));
        expect(state.liveDex.customBoxes[2].pokemonIds.length, equals(5));

        // Conservation check: All 30 initial IDs must exist somewhere across the 3 boxes
        final allIds = state.liveDex.customBoxes.expand((b) => b.pokemonIds).toList();
        expect(allIds.length, equals(65));
        for (final initId in initialIds) {
          expect(allIds.contains(initId), isTrue,
              reason: 'Initial item $initId must not be lost during 35-step cascade');
        }

        // Verify newest inserted item is at Box 1 slot 0
        expect(state.liveDex.customBoxes[0].pokemonIds.first, startsWith('New_35__'));
      },
    );

    testWidgets(
      'S3.2: Rapid successive insertions queue via pendingRecalculate without dropping updates or freezing UI',
      (tester) async {
        final box1 = createTestCustomBox(
          title: 'Box 1',
          pokemonIds: ['A', 'B', 'C'],
          columns: 5,
          rows: 6,
        );
        final liveDex = createTestUserDex(id: 'dex_s3_2', customBoxes: [box1]);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
            simulatedAsyncDelay: const Duration(milliseconds: 50),
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        // Fire 4 insertions rapidly in the same frame/run loop
        final f1 = state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: 'X1');
        final f2 = state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: 'X2');
        final f3 = state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: 'X3');
        final f4 = state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: 'X4');

        await tester.pump(const Duration(milliseconds: 100));
        await Future.wait([f1, f2, f3, f4]);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndFlush();

        // Total items should be 3 initial + 4 new = 7
        expect(state.liveDex.customBoxes.first.pokemonIds.length, equals(7),
            reason: 'All 4 rapid asynchronous insertions must be preserved without dropped updates');
        expect(state.recalculateExecutionCount, greaterThanOrEqualTo(2),
            reason: 'Recalculation queue should process follow-up recalculation');
      },
    );

    // =========================================================================
    // SCENARIO 4: UI Interaction Affordances (AppBar Add & Slot Tapping)
    // =========================================================================

    testWidgets(
      'S4.1: Tapping AppBar Add button in edit mode inserts into current box and cascades if full',
      (tester) async {
        final p30Ids = List.generate(30, (i) => 'P_${i + 1}');
        final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: p30Ids, columns: 5, rows: 6);
        final liveDex = createTestUserDex(id: 'dex_s4_1', customBoxes: [box1]);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        expect(find.byKey(const Key('app_bar_add_button')), findsOneWidget);

        // Tap the AppBar add button
        await tester.tap(find.byKey(const Key('app_bar_add_button')));
        await tester.pumpAndFlush();

        // Verify Box 2 was auto-created because Box 1 was already full (30 items)
        expect(state.liveDex.customBoxes.length, equals(2));
        expect(state.liveDex.customBoxes[1].title, equals('Box 2'));
        expect(state.liveDex.customBoxes[1].pokemonIds.first, startsWith('25__'),
            reason: 'AppBar Add on a full box appends at capacity which overflows into Box 2');
      },
    );

    testWidgets(
      'S4.2: UI insertion when customBoxes is initially empty converts default boxes and performs overflow',
      (tester) async {
        // When user has default boxes, customBoxes is empty in UserDex
        final liveDex = createTestUserDex(id: 'dex_s4_2', customBoxes: []);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        expect(state.liveDex.customBoxes.isEmpty, isTrue);

        // Trigger insertion
        await state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: '25');
        await tester.pumpAndFlush();

        // Verify customBoxes is now populated and contains the inserted Pokémon
        expect(state.liveDex.customBoxes.isNotEmpty, isTrue);
        expect(state.liveDex.customBoxes.first.pokemonIds.first, startsWith('25__'));
      },
    );

    testWidgets(
      'S4.3: Pure Range Pattern ("1-30") overflowing in UI auto-creates "31-60"',
      (tester) async {
        final p30Ids = List.generate(30, (i) => 'Item_${i + 1}');
        final box1 = createTestCustomBox(title: '1-30', pokemonIds: p30Ids, columns: 5, rows: 6);
        final liveDex = createTestUserDex(id: 'dex_s4_3', customBoxes: [box1]);

        when(() => mockProvider.userDexes).thenReturn([liveDex]);

        await tester.pumpWidget(wrapWithApp(
          child: DexScreenStressHarness(
            initialDex: liveDex,
            pokemonList: const [],
            initialEditMode: true,
          ),
          mockDexProvider: mockProvider,
          mockSettingsProvider: mockSettings,
        ));

        final state = tester.state<DexScreenStressHarnessState>(
          find.byType(DexScreenStressHarness),
        );

        await state.triggerInsertPokemon(boxIndex: 0, insertIndex: 0, selectedId: '99');
        await tester.pumpAndFlush();

        expect(state.liveDex.customBoxes.length, equals(2));
        expect(state.liveDex.customBoxes[0].title, equals('1-30'));
        expect(state.liveDex.customBoxes[1].title, equals('31-60'),
            reason: 'Pure numeric range pattern 1-30 must auto-create 31-60');
        expect(state.liveDex.customBoxes[1].pokemonIds.first, equals('Item_30'));
      },
    );
  });
}
