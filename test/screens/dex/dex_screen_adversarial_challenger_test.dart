import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

/// Challenger test harness for adversarial verification of R1 and R2
class ChallengerDexWorkflowHarness extends StatefulWidget {
  final UserDex dex;
  final bool initialEditMode;

  const ChallengerDexWorkflowHarness({
    super.key,
    required this.dex,
    this.initialEditMode = false,
  });

  @override
  State<ChallengerDexWorkflowHarness> createState() =>
      ChallengerDexWorkflowHarnessState();
}

class ChallengerDexWorkflowHarnessState
    extends State<ChallengerDexWorkflowHarness> {
  late UserDex liveDex;
  late PageController pageController;
  late bool isEditMode;
  final Set<String> selectedForEdit = {};
  List<CustomBoxState>? customBoxesSnapshot;
  int lastBoxIndex = 0;
  bool isCalculatingBoxes = false;
  List<BoxData> boxes = [];
  bool didPersist = false;

  @override
  void initState() {
    super.initState();
    liveDex = widget.dex;
    isEditMode = widget.initialEditMode;
    pageController = PageController();
    pageController.addListener(() {
      if (pageController.hasClients && pageController.page != null) {
        lastBoxIndex = pageController.page!.round();
      }
    });
    if (isEditMode) {
      customBoxesSnapshot =
          liveDex.customBoxes.map((b) => b.copyWith()).toList();
    }
    _refreshBoxes();
  }

  @override
  void dispose() {
    pageController.dispose();
    customBoxesSnapshot = null;
    super.dispose();
  }

  void _refreshBoxes() {
    boxes = liveDex.customBoxes.map((cb) {
      final entries = cb.pokemonIds.map((id) {
        if (id.isEmpty) return DexDisplayEntry.emptyEntry;
        final p = createTestPokemon(id: 1, nameEn: id);
        return createTestEntry(pokemon: p, uniqueId: id);
      }).toList();
      while (entries.length < cb.capacity) {
        entries.add(DexDisplayEntry.emptyEntry);
      }
      return BoxData(cb.title, cb.regionKey, entries, cb.columns);
    }).toList();
  }

  void recalculateBoxesSync() {
    int savedPage = pageController.hasClients
        ? (pageController.page?.round() ?? lastBoxIndex)
        : lastBoxIndex;

    setState(() => isCalculatingBoxes = true);
    _refreshBoxes();
    setState(() => isCalculatingBoxes = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (pageController.hasClients && boxes.isNotEmpty) {
        int targetPage = savedPage;
        if (targetPage >= boxes.length) {
          targetPage = boxes.length - 1;
        }
        if (targetPage < 0) {
          targetPage = 0;
        }
        if (pageController.page?.round() != targetPage) {
          pageController.jumpToPage(targetPage);
        }
        lastBoxIndex = targetPage;
      }
    });
  }

  void enterEditMode() {
    setState(() {
      customBoxesSnapshot =
          liveDex.customBoxes.map((b) => b.copyWith()).toList();
      isEditMode = true;
    });
  }

  void executeDelete() {
    setState(() {
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: liveDex,
        selectedKeys: selectedForEdit.toList(),
      );
      selectedForEdit.clear();
      // R2: isEditMode stays true!
    });
    didPersist = true;
    recalculateBoxesSync();
  }

  Future<void> handleSaveEditMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          t.edit_mode_save_title,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.yes),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        isEditMode = false;
        selectedForEdit.clear();
        customBoxesSnapshot = null;
      });
      didPersist = true;
      recalculateBoxesSync();
    }
  }

  Future<void> handleCancelEditMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          t.edit_mode_discard_title,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.discard),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        if (customBoxesSnapshot != null) {
          liveDex.customBoxes =
              customBoxesSnapshot!.map((b) => b.copyWith()).toList();
        }
        customBoxesSnapshot = null;
        selectedForEdit.clear();
        isEditMode = false;
      });
      didPersist = true;
      recalculateBoxesSync();
    }
  }

  void mutateState(VoidCallback fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isEditMode,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (isEditMode) {
          await handleCancelEditMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: isEditMode
              ? IconButton(
                  key: const Key('challenger_leading_back'),
                  icon: const BackButtonIcon(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: handleCancelEditMode,
                )
              : null,
          title: Text(liveDex.title),
          actions: [
            if (isEditMode && selectedForEdit.isNotEmpty)
              IconButton(
                key: const Key('challenger_action_delete'),
                icon: const Icon(Icons.delete),
                tooltip: t.box_edit_remove_selected,
                onPressed: executeDelete,
              ),
            if (isEditMode)
              IconButton(
                key: const Key('challenger_action_add'),
                icon: const Icon(Icons.add),
                tooltip: t.add_pokemon,
                onPressed: () {
                  final targetBoxIndex = pageController.hasClients
                      ? (pageController.page?.round() ?? lastBoxIndex)
                      : lastBoxIndex;
                  if (targetBoxIndex < liveDex.customBoxes.length) {
                    final box = liveDex.customBoxes[targetBoxIndex];
                    int targetSlot = box.pokemonIds.indexOf('');
                    if (targetSlot == -1) targetSlot = box.pokemonIds.length;
                    BoxSequenceManager.insertWithShiftAndOverflow(
                      dex: liveDex,
                      boxIndex: targetBoxIndex,
                      slotIndex: targetSlot,
                      pokemonId: 'NEW_${DateTime.now().millisecondsSinceEpoch}',
                    );
                    recalculateBoxesSync();
                  }
                },
              ),
            if (!isEditMode)
              IconButton(
                key: const Key('challenger_enter_edit_mode'),
                icon: const Icon(Icons.checklist),
                tooltip: t.box_edit_manage_content,
                onPressed: enterEditMode,
              ),
            IconButton(
              key: const Key('challenger_action_box_settings'),
              icon: const Icon(Icons.edit_note),
              tooltip: t.box_edit_title,
              onPressed: () {},
            ),
            IconButton(
              key: const Key('challenger_action_route_tracker'),
              icon: const Icon(Icons.location_on),
              tooltip: t.route_tracker,
              onPressed: () {},
            ),
            PopupMenuButton<String>(
              key: const Key('challenger_action_sort_menu'),
              icon: const Icon(Icons.sort),
              tooltip: t.tooltip_view_sort,
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'sort',
                  child: Text('Sort'),
                ),
              ],
            ),
            if (isEditMode) ...[
              IconButton(
                key: const Key('challenger_action_cancel'),
                icon: const Icon(Icons.close),
                tooltip: t.cancel,
                onPressed: handleCancelEditMode,
              ),
              IconButton(
                key: const Key('challenger_action_save'),
                icon: const Icon(Icons.check),
                tooltip: t.save,
                onPressed: handleSaveEditMode,
              ),
            ],
          ],
        ),
        body: Stack(
          children: [
            DexBoxView(
              boxes: boxes,
              liveDex: liveDex,
              provider: MockDexProvider(),
              pageController: pageController,
              separateForms: true,
              highlightedIds: const {},
              isSearchActive: false,
              isEditMode: isEditMode,
              selectedForEdit: selectedForEdit,
              onSelectionChanged: (boxIndex, itemIndex) {
                setState(() {
                  final key = '${boxIndex}_$itemIndex';
                  if (selectedForEdit.contains(key)) {
                    selectedForEdit.remove(key);
                  } else {
                    selectedForEdit.add(key);
                  }
                });
              },
            ),
            if (isCalculatingBoxes)
              const Positioned(
                key: Key('challenger_progress_indicator'),
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger Adversarial Verification (R1 & R2 Stress Tests)', () {
    // -------------------------------------------------------------------------
    // Test 1: DexBoxView non-destructive mounting & PageController stability
    // -------------------------------------------------------------------------
    testWidgets('ADV-1: DexBoxView remains continuously mounted during background recalculation without pumpAndSettle timeout', (tester) async {
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1', 'P2']);
      final box2 = createTestCustomBox(title: 'Box 2', pokemonIds: ['P3', 'P4']);
      final dex = createTestUserDex(customBoxes: [box1, box2]);

      await tester.pumpWidget(wrapWithApp(
        child: ChallengerDexWorkflowHarness(dex: dex, initialEditMode: false),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<ChallengerDexWorkflowHarnessState>(
        find.byType(ChallengerDexWorkflowHarness),
      );

      expect(find.byType(DexBoxView), findsOneWidget);

      // Trigger background calculation
      state.mutateState(() => state.isCalculatingBoxes = true);
      await tester.pump();

      // Invariant: DexBoxView must NOT be unmounted or replaced by isolated spinner
      expect(find.byType(DexBoxView), findsOneWidget);
      expect(find.byKey(const Key('challenger_progress_indicator')), findsOneWidget);

      state.mutateState(() => state.isCalculatingBoxes = false);
      await tester.pump();
      expect(find.byKey(const Key('challenger_progress_indicator')), findsNothing);
      expect(find.byType(DexBoxView), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 2: PageController maintains active page during recalculation
    // -------------------------------------------------------------------------
    testWidgets('ADV-2: PageController maintains active box index (Page 1) across recalculation', (tester) async {
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1']);
      final box2 = createTestCustomBox(title: 'Box 2', pokemonIds: ['P2']);
      final dex = createTestUserDex(customBoxes: [box1, box2]);

      await tester.pumpWidget(wrapWithApp(
        child: ChallengerDexWorkflowHarness(dex: dex, initialEditMode: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<ChallengerDexWorkflowHarnessState>(
        find.byType(ChallengerDexWorkflowHarness),
      );

      // Jump to Page 1 (Box 2)
      state.pageController.jumpToPage(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.pageController.page?.round(), equals(1));

      // Trigger recalculation
      state.recalculateBoxesSync();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Invariant: Must stay on Page 1, NEVER reset to 0
      expect(state.pageController.page?.round(), equals(1));
    });

    // -------------------------------------------------------------------------
    // Test 3: Edge condition - Overflow box complete deletion length reduction
    // -------------------------------------------------------------------------
    testWidgets('ADV-3: Deleting all items in overflow box clamps target page to length-1 without resetting to 0', (tester) async {
      // 3 boxes in numbered sequence: Test 1, Test 2, Test 3 (Test 3 has 1 item)
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ['P1', 'P2']);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ['P3', 'P4']);
      final box3 = createTestCustomBox(title: 'Test 3', pokemonIds: ['OVERFLOW_1']);
      final dex = createTestUserDex(customBoxes: [box1, box2, box3]);

      await tester.pumpWidget(wrapWithApp(
        child: ChallengerDexWorkflowHarness(dex: dex, initialEditMode: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<ChallengerDexWorkflowHarnessState>(
        find.byType(ChallengerDexWorkflowHarness),
      );

      // User navigates to Test 3 (Page 2)
      state.pageController.jumpToPage(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.pageController.page?.round(), equals(2));

      // Select the solitary item in Test 3 (slot 0 of box 2)
      state.mutateState(() => state.selectedForEdit.add('2_0'));
      await tester.pump();

      // Tap delete
      await tester.tap(find.byKey(const Key('challenger_action_delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Invariant: Test 3 is deleted. Total boxes shrink from 3 to 2.
      expect(state.liveDex.customBoxes.length, equals(2));
      expect(state.boxes.length, equals(2));

      // Invariant: PageController clamps to Page 1 (Test 2), NEVER resets to Box 0!
      expect(state.pageController.page?.round(), equals(1));
      expect(state.isEditMode, isTrue);
    });

    // -------------------------------------------------------------------------
    // Test 4: Multiple sequential batch deletions in edit mode without exiting
    // -------------------------------------------------------------------------
    testWidgets('ADV-4: Multiple sequential batch deletions keep isEditMode true throughout and rollback preserves all', (tester) async {
      LocaleSettings.setLocale(AppLocale.de);
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['A1', 'A2', 'A3', 'A4']);
      final box2 = createTestCustomBox(title: 'Box 2', pokemonIds: ['B1', 'B2', 'B3', 'B4']);
      final dex = createTestUserDex(customBoxes: [box1, box2]);

      await tester.pumpWidget(wrapWithApp(
        child: ChallengerDexWorkflowHarness(dex: dex, initialEditMode: true),
        language: 'de',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<ChallengerDexWorkflowHarnessState>(
        find.byType(ChallengerDexWorkflowHarness),
      );

      // Initial check: edit mode is active, snapshot exists, 8 total items
      expect(state.isEditMode, isTrue);
      expect(state.customBoxesSnapshot, isNotNull);
      int totalItems() => state.liveDex.customBoxes.fold(
          0, (sum, b) => sum + b.pokemonIds.where((id) => id.isNotEmpty).length);
      expect(totalItems(), equals(8));

      // --- Batch Deletion 1: Delete 2 items from Box 0 ---
      state.mutateState(() {
        state.selectedForEdit.addAll(['0_0', '0_1']);
      });
      await tester.pump();

      expect(find.byKey(const Key('challenger_action_delete')), findsOneWidget);
      await tester.tap(find.byKey(const Key('challenger_action_delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Batch 1 results
      expect(state.isEditMode, isTrue, reason: 'R2: Edit mode MUST stay true after deletion 1');
      expect(state.selectedForEdit, isEmpty, reason: 'Selection MUST be cleared after deletion 1');
      expect(find.byKey(const Key('challenger_action_delete')), findsNothing);
      expect(totalItems(), equals(6));

      // --- Batch Deletion 2: Delete 2 items from Box 1 ---
      state.mutateState(() {
        state.selectedForEdit.addAll(['1_0', '1_1']);
      });
      await tester.pump();

      expect(find.byKey(const Key('challenger_action_delete')), findsOneWidget);
      await tester.tap(find.byKey(const Key('challenger_action_delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Batch 2 results
      expect(state.isEditMode, isTrue, reason: 'R2: Edit mode MUST stay true after deletion 2');
      expect(state.selectedForEdit, isEmpty, reason: 'Selection MUST be cleared after deletion 2');
      expect(find.byKey(const Key('challenger_action_delete')), findsNothing);
      expect(totalItems(), equals(4));

      // --- Batch Deletion 3: Delete 1 item from Box 0 ---
      state.mutateState(() {
        state.selectedForEdit.add('0_0');
      });
      await tester.pump();

      expect(find.byKey(const Key('challenger_action_delete')), findsOneWidget);
      await tester.tap(find.byKey(const Key('challenger_action_delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Batch 3 results
      expect(state.isEditMode, isTrue, reason: 'R2: Edit mode MUST stay true after deletion 3');
      expect(state.selectedForEdit, isEmpty);
      expect(totalItems(), equals(3));

      // --- Now Discard (✕) -> Verify Rollback of ALL 3 batches ---
      await tester.tap(find.byKey(const Key('challenger_action_cancel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog opens
      expect(find.text('Möchtest du alle Änderungen verwerfen?'), findsOneWidget);
      await tester.tap(find.text('Verwerfen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Invariant: Edit mode exited, snapshot null, ALL 3 batch deletions rolled back to 8!
      expect(state.isEditMode, isFalse);
      expect(state.customBoxesSnapshot, isNull);
      expect(totalItems(), equals(8));
      expect(state.liveDex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['A1', 'A2', 'A3', 'A4']));
      expect(state.liveDex.customBoxes[1].pokemonIds.where((id) => id.isNotEmpty).toList(),
          equals(['B1', 'B2', 'B3', 'B4']));
    });
  });
}
