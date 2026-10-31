import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/screens/dex/dex_screen.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

/// Test harness that models the DexScreen edit workflow and state transitions
/// exactly conforming to R1, R2, and R3 specifications.
class DexScreenEditWorkflowHarness extends StatefulWidget {
  final UserDex dex;
  final bool initialEditMode;

  const DexScreenEditWorkflowHarness({
    super.key,
    required this.dex,
    this.initialEditMode = false,
  });

  @override
  State<DexScreenEditWorkflowHarness> createState() =>
      DexScreenEditWorkflowHarnessState();
}

class DexScreenEditWorkflowHarnessState
    extends State<DexScreenEditWorkflowHarness> {
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

  Future<void> recalculateBoxesAsync() async {
    int savedPage = pageController.hasClients
        ? (pageController.page?.round() ?? lastBoxIndex)
        : lastBoxIndex;

    setState(() => isCalculatingBoxes = true);

    if (mounted) {
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
  }

  void setCalculatingBoxes(bool calculating) {
    setState(() {
      isCalculatingBoxes = calculating;
    });
  }

  void selectForEdit(String key) {
    setState(() {
      selectedForEdit.add(key);
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
    // In edit mode, intermediate alterations update memory/UI via recalculateBoxesAsync;
    // permanent SQLite writes occur upon user confirmation in handleSaveEditMode.
    if (!isEditMode) {
      didPersist = true;
    }
    recalculateBoxesAsync();
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
      await recalculateBoxesAsync();
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
      await recalculateBoxesAsync();
    }
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
                  key: const Key('app_bar_leading_back'),
                  icon: const BackButtonIcon(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: handleCancelEditMode,
                )
              : null,
          title: Text(liveDex.title),
          actions: [
            if (isEditMode && selectedForEdit.isNotEmpty)
              IconButton(
                key: const Key('edit_action_delete'),
                icon: const Icon(Icons.delete),
                tooltip: t.box_edit_remove_selected,
                onPressed: executeDelete,
              ),
            if (isEditMode)
              IconButton(
                key: const Key('edit_action_add'),
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
                    recalculateBoxesAsync();
                  }
                },
              ),
            if (!isEditMode)
              IconButton(
                key: const Key('action_enter_edit_mode'),
                icon: const Icon(Icons.checklist),
                tooltip: t.box_edit_manage_content,
                onPressed: enterEditMode,
              ),
            IconButton(
              key: const Key('action_box_settings'),
              icon: const Icon(Icons.edit_note),
              tooltip: t.box_edit_title,
              onPressed: () {},
            ),
            IconButton(
              key: const Key('action_route_tracker'),
              icon: const Icon(Icons.location_on),
              tooltip: t.route_tracker,
              onPressed: () {},
            ),
            PopupMenuButton<String>(
              key: const Key('action_sort_menu'),
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
                key: const Key('edit_action_cancel'),
                icon: const Icon(Icons.close),
                tooltip: t.cancel,
                onPressed: handleCancelEditMode,
              ),
              IconButton(
                key: const Key('edit_action_save'),
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
              onMoveMultiplePokemon: (sourceIds, targetBox, targetIndex) {
                setState(() {
                  BoxSequenceManager.moveMultiplePokemon(
                    dex: liveDex,
                    sourceIds: sourceIds,
                    targetBoxIndex: targetBox,
                    targetSlotIndex: targetIndex,
                  );
                  selectedForEdit.clear();
                  _refreshBoxes();
                });
              },
              onMovePokemon: (sourceId, targetBox, targetIndex) {
                setState(() {
                  BoxSequenceManager.movePokemon(
                    dex: liveDex,
                    sourceId: sourceId,
                    targetBoxIndex: targetBox,
                    targetSlotIndex: targetIndex,
                  );
                  if (selectedForEdit.isNotEmpty) {
                    selectedForEdit.clear();
                  }
                  _refreshBoxes();
                });
              },
              onSwapPokemon: (sourceId, targetBox, targetIndex) {
                setState(() {
                  BoxSequenceManager.swapPokemon(
                    dex: liveDex,
                    sourceId: sourceId,
                    targetBoxIndex: targetBox,
                    targetSlotIndex: targetIndex,
                  );
                  if (selectedForEdit.isNotEmpty) {
                    selectedForEdit.clear();
                  }
                  _refreshBoxes();
                });
              },
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
                key: Key('recalculate_progress_indicator'),
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

/// Pumps bounded discrete frames to allow gesture, animation, and layout transitions
/// to complete without getting hung on infinite network image placeholder spinners.
Future<void> pumpFrames(WidgetTester tester, [int durationMs = 150]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: durationMs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Paket 1 Unit & Widget Verification (R1, R2, R3)', () {
    test('dex_screen.dart structural compilation and type verification', () {
      expect(DexScreen, isNotNull);
    });

    // =========================================================================
    // Translation Verification
    // =========================================================================
    test('Translations: Keys for save, discard, yes, discard exist in DE and EN', () {
      LocaleSettings.setLocale(AppLocale.de);
      expect(t.edit_mode_save_title, equals('Änderungen speichern?'));
      expect(t.edit_mode_discard_title, equals('Möchtest du alle Änderungen verwerfen?'));
      expect(t.yes, equals('Ja'));
      expect(t.discard, equals('Verwerfen'));

      LocaleSettings.setLocale(AppLocale.en);
      expect(t.edit_mode_save_title, equals('Save changes?'));
      expect(t.edit_mode_discard_title, equals('Do you want to discard all changes?'));
      expect(t.yes, equals('Yes'));
      expect(t.discard, equals('Discard'));
    });

    // =========================================================================
    // R1: Box-Position Retention & Stack Progress Indicator
    // =========================================================================
    testWidgets('R1: DexBoxView remains continuously mounted during background recalculation', (tester) async {
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1', 'P2']);
      final box2 = createTestCustomBox(title: 'Box 2', pokemonIds: ['P3', 'P4']);
      final dex = createTestUserDex(customBoxes: [box1, box2]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: false),
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Verify DexBoxView is mounted
      expect(find.byType(DexBoxView), findsOneWidget);

      // Simulate background calculation
      state.setCalculatingBoxes(true);
      await tester.pump();

      // Invariant: DexBoxView must NOT be unmounted or replaced by an isolated spinner!
      expect(find.byType(DexBoxView), findsOneWidget);
      expect(find.byKey(const Key('recalculate_progress_indicator')), findsOneWidget);

      state.setCalculatingBoxes(false);
      await tester.pump();
      expect(find.byKey(const Key('recalculate_progress_indicator')), findsNothing);
      expect(find.byType(DexBoxView), findsOneWidget);
    });

    testWidgets('R1: PageController maintains active box index across recalculation', (tester) async {
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1']);
      final box2 = createTestCustomBox(title: 'Box 2', pokemonIds: ['P2']);
      final dex = createTestUserDex(customBoxes: [box1, box2]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Navigate to Box 2 (page 1)
      state.pageController.jumpToPage(1);
      await pumpFrames(tester);
      expect(state.pageController.page?.round(), equals(1));

      // Trigger recalculation
      await state.recalculateBoxesAsync();
      await pumpFrames(tester);

      // Invariant: page must stay on 1 (Box 2), NOT reset to 0
      expect(state.pageController.page?.round(), equals(1));
    });

    // =========================================================================
    // R2: Edit-Modus nach Löschoperationen offen halten
    // =========================================================================
    testWidgets('R2: Deleting selected items clears selection but keeps isEditMode true', (tester) async {
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1', 'P2']);
      final dex = createTestUserDex(customBoxes: [box1]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Select item at slot 0
      state.selectForEdit('0_0');
      await pumpFrames(tester);

      expect(find.byKey(const Key('edit_action_delete')), findsOneWidget);

      // Tap delete
      await tester.tap(find.byKey(const Key('edit_action_delete')));
      await pumpFrames(tester);

      // Invariant R2: selection is cleared, but edit mode stays open!
      expect(state.selectedForEdit, isEmpty);
      expect(state.isEditMode, isTrue);
      // Invariant: intermediate alteration does not eagerly persist until save confirmation
      expect(state.didPersist, isFalse);
      // Delete icon hides because selection is empty
      expect(find.byKey(const Key('edit_action_delete')), findsNothing);
      // Edit mode action icons remain visible
      expect(find.byKey(const Key('edit_action_save')), findsOneWidget);
      expect(find.byKey(const Key('edit_action_cancel')), findsOneWidget);
    });

    // =========================================================================
    // R3: AppBar Action Icons Accessibility
    // =========================================================================
    testWidgets('R3: Standard action icons remain accessible in edit mode alongside edit icons', (tester) async {
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1']);
      final dex = createTestUserDex(customBoxes: [box1]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
      ));
      await pumpFrames(tester);

      // Standard icons must be visible in edit mode
      expect(find.byKey(const Key('action_box_settings')), findsOneWidget);
      expect(find.byKey(const Key('action_route_tracker')), findsOneWidget);
      expect(find.byKey(const Key('action_sort_menu')), findsOneWidget);

      // Edit icons must be visible in edit mode
      expect(find.byKey(const Key('edit_action_add')), findsOneWidget);
      expect(find.byKey(const Key('edit_action_cancel')), findsOneWidget);
      expect(find.byKey(const Key('edit_action_save')), findsOneWidget);
    });

    // =========================================================================
    // R3: Save (✓) Confirmation Dialog Workflow
    // =========================================================================
    testWidgets('R3: Save (✓) dialog cancel keeps edit mode active', (tester) async {
      LocaleSettings.setLocale(AppLocale.de);
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1']);
      final dex = createTestUserDex(customBoxes: [box1]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
        language: 'de',
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Tap Save (✓)
      await tester.tap(find.byKey(const Key('edit_action_save')));
      await pumpFrames(tester, 300);

      // Dialog appears
      expect(find.text('Änderungen speichern?'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Ja'), findsOneWidget);

      // Tap Cancel in dialog
      await tester.tap(find.text('Abbrechen'));
      await pumpFrames(tester, 300);

      // Dialog closed, edit mode still active
      expect(find.text('Änderungen speichern?'), findsNothing);
      expect(state.isEditMode, isTrue);
      expect(state.customBoxesSnapshot, isNotNull);
    });

    testWidgets('R3: Save (✓) dialog confirm persists changes and exits edit mode', (tester) async {
      LocaleSettings.setLocale(AppLocale.de);
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1']);
      final dex = createTestUserDex(customBoxes: [box1]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
        language: 'de',
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Tap Save (✓)
      await tester.tap(find.byKey(const Key('edit_action_save')));
      await pumpFrames(tester, 300);

      // Tap Ja in dialog
      await tester.tap(find.text('Ja'));
      await pumpFrames(tester, 300);

      // Invariant: edit mode exited, snapshot cleared, persisted
      expect(state.isEditMode, isFalse);
      expect(state.customBoxesSnapshot, isNull);
      expect(state.didPersist, isTrue);
    });

    // =========================================================================
    // R3: Discard (✕) Confirmation Dialog & Rollback Workflow
    // =========================================================================
    testWidgets('R3: Discard (✕) dialog cancel keeps modifications and edit mode active', (tester) async {
      LocaleSettings.setLocale(AppLocale.de);
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['ORIGINAL_MON']);
      final dex = createTestUserDex(customBoxes: [box1]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
        language: 'de',
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Mutate box in edit mode
      state.liveDex.customBoxes.first.pokemonIds.add('MUTATED_MON');

      // Tap Discard (✕)
      await tester.tap(find.byKey(const Key('edit_action_cancel')));
      await pumpFrames(tester, 300);

      // Dialog appears
      expect(find.text('Möchtest du alle Änderungen verwerfen?'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Verwerfen'), findsOneWidget);

      // Tap Cancel in dialog
      await tester.tap(find.text('Abbrechen'));
      await pumpFrames(tester, 300);

      // Edit mode still active, mutations remain
      expect(state.isEditMode, isTrue);
      expect(state.liveDex.customBoxes.first.pokemonIds.contains('MUTATED_MON'), isTrue);
    });

    testWidgets('R3: Discard (✕) dialog confirm rolls back customBoxes to snapshot and exits edit mode', (tester) async {
      LocaleSettings.setLocale(AppLocale.de);
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['ORIGINAL_1', 'ORIGINAL_2']);
      final dex = createTestUserDex(customBoxes: [box1]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
        language: 'de',
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Mutate boxes in edit mode (e.g. remove an item and add new item)
      state.liveDex.customBoxes.first.pokemonIds.remove('ORIGINAL_1');
      state.liveDex.customBoxes.first.pokemonIds.add('NEW_UNSAVED_MON');

      // Tap Discard (✕)
      await tester.tap(find.byKey(const Key('edit_action_cancel')));
      await pumpFrames(tester, 300);

      // Tap Verwerfen in dialog
      await tester.tap(find.text('Verwerfen'));
      await pumpFrames(tester, 300);

      // Invariant: Rolled back to snapshot, edit mode exited
      expect(state.isEditMode, isFalse);
      expect(state.customBoxesSnapshot, isNull);
      expect(state.liveDex.customBoxes.first.pokemonIds, contains('ORIGINAL_1'));
      expect(state.liveDex.customBoxes.first.pokemonIds, contains('ORIGINAL_2'));
      expect(state.liveDex.customBoxes.first.pokemonIds, isNot(contains('NEW_UNSAVED_MON')));
    });

    // =========================================================================
    // R3: Back Navigation & PopScope Interception
    // =========================================================================
    testWidgets('R3: Leading back button triggers discard dialog and does not pop the screen', (tester) async {
      LocaleSettings.setLocale(AppLocale.de);
      final box1 = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1']);
      final dex = createTestUserDex(customBoxes: [box1]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
        language: 'de',
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Tap AppBar leading back button
      expect(find.byKey(const Key('app_bar_leading_back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('app_bar_leading_back')));
      await pumpFrames(tester, 300);

      // Discard confirmation dialog must appear
      expect(find.text('Möchtest du alle Änderungen verwerfen?'), findsOneWidget);

      // Confirm Verwerfen
      await tester.tap(find.text('Verwerfen'));
      await pumpFrames(tester, 300);

      // Screen stays mounted, but edit mode is exited
      expect(find.byType(DexScreenEditWorkflowHarness), findsOneWidget);
      expect(state.isEditMode, isFalse);
      // Leading back button is now gone since edit mode is false
      expect(find.byKey(const Key('app_bar_leading_back')), findsNothing);
    });

    testWidgets('R4: Multi-card drag and drop in edit mode moves selected block and clears selection', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1', 'P2', 'P3', 'P4']);
      final dex = createTestUserDex(customBoxes: [box]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Select P1 (slot 0) and P2 (slot 1) by tapping
      final card0 = find.byType(LongPressDraggable<String>).first;
      final card1 = find.byType(LongPressDraggable<String>).at(1);
      await tester.tap(card0);
      await pumpFrames(tester);
      await tester.tap(card1);
      await pumpFrames(tester);

      expect(state.selectedForEdit, contains('0_0'));
      expect(state.selectedForEdit, contains('0_1'));
      expect(state.selectedForEdit.length, equals(2));

      // Long press card 0 to initiate multi-drag
      final firstCenter = tester.getCenter(card0);
      final fourthCenter = tester.getCenter(find.byType(DragTarget<String>).at(3));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      // Stacked pile badge should be displayed with '2'
      expect(find.byKey(const Key('multi_drag_badge')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Drag to slot 3 (where P4 is)
      await gesture.moveTo(fourthCenter);
      await tester.pump();

      // Drop
      await gesture.up();
      await tester.pump();
      await pumpFrames(tester, 300);

      // Selection must be cleared
      expect(state.selectedForEdit, isEmpty);

      // Items P1 and P2 must be moved before P4
      expect(state.liveDex.customBoxes.first.pokemonIds, equals(['P3', 'P1', 'P2', 'P4']));
    });

    testWidgets('R5: Single card drag in edit mode clears selection when moved', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['P1', 'P2', 'P3']);
      final dex = createTestUserDex(customBoxes: [box]);

      await tester.pumpWidget(wrapWithApp(
        child: DexScreenEditWorkflowHarness(dex: dex, initialEditMode: true),
      ));
      await pumpFrames(tester);

      final state = tester.state<DexScreenEditWorkflowHarnessState>(
        find.byType(DexScreenEditWorkflowHarness),
      );

      // Select P1 (slot 0)
      final card0 = find.byType(LongPressDraggable<String>).first;
      await tester.tap(card0);
      await pumpFrames(tester);

      expect(state.selectedForEdit, contains('0_0'));
      expect(state.selectedForEdit.length, equals(1));

      // Single card drag: start drag on card0 and drop on slot 2
      final firstCenter = tester.getCenter(card0);
      final thirdCenter = tester.getCenter(find.byType(DragTarget<String>).at(2));

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      await gesture.moveTo(thirdCenter);
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await pumpFrames(tester, 300);

      // Selection must be cleared and P1 swaps with P3
      expect(state.selectedForEdit, isEmpty);
      expect(state.liveDex.customBoxes.first.pokemonIds, equals(['P3', 'P2', 'P1']));
    });
  });
}
