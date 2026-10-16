import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/screens/dex/box_content_edit_screen.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import '../../e2e/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Challenger M4-2 Stress Target 1: Root Box Protection Invariants', () {
    test('1.1: Sole remaining box "Test 1" with 1 item is NEVER deleted when that item is deleted', () {
      final box1 = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: ['SOLITARY_MON'],
        columns: 5,
        rows: 6,
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(
        id: 'dex_t1_1',
        title: 'Sole Box Test',
        customBoxes: [box1],
      );

      // Remove the solitary item
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Invariant: Root box must be preserved
      expect(dex.customBoxes.length, equals(1),
          reason: 'Sole remaining box must never be deleted, even if emptied');
      expect(dex.customBoxes.first.title, equals('Test 1'));
      expect(dex.customBoxes.first.pokemonIds.where((id) => id.isNotEmpty), isEmpty);
    });

    test('1.2: Sole remaining full box (30 items) cleared item-by-item is NEVER deleted at any step', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: ids30,
        columns: 5,
        rows: 6,
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(
        id: 'dex_t1_2',
        title: 'Full Clear Test',
        customBoxes: [box1],
      );

      // Progressively remove each item from slot 0
      for (int step = 0; step < 30; step++) {
        expect(dex.customBoxes.length, equals(1));
        expect(dex.customBoxes.first.title, equals('Test 1'));
        BoxSequenceManager.removeWithShiftBack(
          dex: dex,
          boxIndex: 0,
          slotIndex: 0,
        );
      }

      // After all 30 removals, Test 1 must remain as empty root box
      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes.first.title, equals('Test 1'));
      expect(dex.customBoxes.first.pokemonIds.where((id) => id.isNotEmpty), isEmpty);
    });

    test('1.3: Batch deletion of ALL items in sole box preserves root box', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: ids30,
        columns: 5,
        rows: 6,
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(
        id: 'dex_t1_3',
        title: 'Batch All Test',
        customBoxes: [box1],
      );

      final allKeys = List.generate(30, (i) => '0_$i');
      BoxSequenceManager.batchRemoveWithShiftBack(
        dex: dex,
        selectedKeys: allKeys,
      );

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes.first.title, equals('Test 1'));
      expect(dex.customBoxes.first.pokemonIds.where((id) => id.isNotEmpty), isEmpty);
    });

    test('1.4: Multi-sequence isolation: emptying root of sequence A does not delete it when sequence B exists', () {
      final boxA = createTestCustomBox(
        title: 'Kanto 1',
        pokemonIds: ['K1_Only'],
        columns: 5,
        rows: 6,
        autoDeleteEmpty: true,
      );
      final boxB = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: ['T1_Only'],
        columns: 5,
        rows: 6,
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(
        id: 'dex_t1_4',
        title: 'Multi Sequence Test',
        customBoxes: [boxA, boxB],
      );

      // Remove from Kanto 1 (root of Kanto sequence)
      BoxSequenceManager.removeWithShiftBack(
        dex: dex,
        boxIndex: 0,
        slotIndex: 0,
      );

      // Kanto 1 is root of its sequence, so it must NOT be deleted even though Test 1 also exists
      expect(dex.customBoxes.length, equals(2));
      expect(dex.customBoxes[0].title, equals('Kanto 1'));
      expect(dex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty), isEmpty);
      expect(dex.customBoxes[1].title, equals('Test 1'));
      expect(dex.customBoxes[1].pokemonIds, equals(['T1_Only']));
    });
  });

  group('Challenger M4-2 Stress Target 2: Deleting Slot 0 vs Deleting Slot 29 in Full Box', () {
    test('2.1: Deleting slot 0 in full Test 1 pulls Test 2 head into slot 29 and shifts 1..29 to 0..28', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final idsTest2 = ['T2_Head', 'T2_Tail'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex_t2_1', customBoxes: [box1, box2]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 0);

      // Test 1: size remains 30
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      // First item is M_2 (shifted left)
      expect(dex.customBoxes[0].pokemonIds[0], equals('M_2'));
      // 29th item was M_30, now at index 28
      expect(dex.customBoxes[0].pokemonIds[28], equals('M_30'));
      // Slot 29 receives pulled head from Test 2
      expect(dex.customBoxes[0].pokemonIds[29], equals('T2_Head'));

      // Test 2: lost its head
      expect(dex.customBoxes[1].pokemonIds, equals(['T2_Tail']));
    });

    test('2.2: Deleting slot 29 in full Test 1 preserves 0..28 in place and pulls Test 2 head directly into slot 29', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final idsTest2 = ['T2_Head', 'T2_Tail'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex_t2_2', customBoxes: [box1, box2]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 29);

      // Test 1: size remains 30
      expect(dex.customBoxes[0].pokemonIds.length, equals(30));
      // Items 0..28 are completely undisturbed
      for (int i = 0; i < 29; i++) {
        expect(dex.customBoxes[0].pokemonIds[i], equals('M_${i + 1}'));
      }
      // Slot 29 directly receives pulled head from Test 2
      expect(dex.customBoxes[0].pokemonIds[29], equals('T2_Head'));

      // Test 2: lost its head
      expect(dex.customBoxes[1].pokemonIds, equals(['T2_Tail']));
    });

    test('2.3: Deleting slot 0 vs slot 29 when Test 2 has exactly 1 item causes Test 2 auto-deletion in both cases', () {
      // Sub-case A: Slot 0
      final idsA = List.generate(30, (i) => 'A_${i + 1}');
      final box1A = createTestCustomBox(title: 'Test 1', pokemonIds: idsA, columns: 5, rows: 6);
      final box2A = createTestCustomBox(title: 'Test 2', pokemonIds: ['PULL_A'], columns: 5, rows: 6);
      final dexA = createTestUserDex(id: 'dex_a', customBoxes: [box1A, box2A]);

      BoxSequenceManager.removeWithShiftBack(dex: dexA, boxIndex: 0, slotIndex: 0);

      expect(dexA.customBoxes.length, equals(1));
      expect(dexA.customBoxes.first.title, equals('Test 1'));
      expect(dexA.customBoxes.first.pokemonIds.length, equals(30));
      expect(dexA.customBoxes.first.pokemonIds[0], equals('A_2'));
      expect(dexA.customBoxes.first.pokemonIds[29], equals('PULL_A'));

      // Sub-case B: Slot 29
      final idsB = List.generate(30, (i) => 'B_${i + 1}');
      final box1B = createTestCustomBox(title: 'Test 1', pokemonIds: idsB, columns: 5, rows: 6);
      final box2B = createTestCustomBox(title: 'Test 2', pokemonIds: ['PULL_B'], columns: 5, rows: 6);
      final dexB = createTestUserDex(id: 'dex_b', customBoxes: [box1B, box2B]);

      BoxSequenceManager.removeWithShiftBack(dex: dexB, boxIndex: 0, slotIndex: 29);

      expect(dexB.customBoxes.length, equals(1));
      expect(dexB.customBoxes.first.title, equals('Test 1'));
      expect(dexB.customBoxes.first.pokemonIds.length, equals(30));
      expect(dexB.customBoxes.first.pokemonIds[0], equals('B_1'));
      expect(dexB.customBoxes.first.pokemonIds[29], equals('PULL_B'));
    });

    test('2.4: Out-of-bounds slotIndex (-1, 30, 999) on full box are safe no-ops', () {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final dex = createTestUserDex(id: 'dex_oob', customBoxes: [box1]);

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: -1);
      expect(dex.customBoxes.first.pokemonIds.length, equals(30));

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 30);
      expect(dex.customBoxes.first.pokemonIds.length, equals(30));

      BoxSequenceManager.removeWithShiftBack(dex: dex, boxIndex: 0, slotIndex: 999);
      expect(dex.customBoxes.first.pokemonIds.length, equals(30));
    });
  });

  group('Challenger M4-2 Stress Target 3: PageController Clamping on Overflow Deletion', () {
    testWidgets('3.1: Active Page 1 clamps to Page 0 when overflow box page is deleted', (tester) async {
      final pageController = PageController(initialPage: 1);
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ['P1_MON'], columns: 5, rows: 6);
      final liveDex = createTestUserDex(id: 'dex_clamp_1', customBoxes: [box1, box2]);

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          // Remove from box 0, which pulls P1_MON from box 1 and auto-deletes box 1
                          BoxSequenceManager.removeWithShiftBack(
                            dex: liveDex,
                            boxIndex: 0,
                            slotIndex: 0,
                          );

                          // Mirror DexScreen post-frame clamping logic
                          if (pageController.hasClients) {
                            int targetPage = pageController.page?.round() ?? 0;
                            if (targetPage >= liveDex.customBoxes.length && liveDex.customBoxes.isNotEmpty) {
                              targetPage = liveDex.customBoxes.length - 1;
                            }
                            if (targetPage < 0) targetPage = 0;
                            pageController.jumpToPage(targetPage);
                          }
                        });
                      },
                    ),
                  ],
                ),
                body: PageView.builder(
                  controller: pageController,
                  itemCount: liveDex.customBoxes.length,
                  itemBuilder: (ctx, index) => Center(
                    child: Text(liveDex.customBoxes[index].title),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Verify initial state: Page 1 ("Test 2")
      expect(pageController.page, equals(1.0));
      expect(find.text('Test 2'), findsOneWidget);

      // Tap delete to empty Test 2
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Verify clamped state: Page 0 ("Test 1") without crash or RangeError
      expect(liveDex.customBoxes.length, equals(1));
      expect(pageController.page, equals(0.0));
      expect(find.text('Test 1'), findsOneWidget);
      expect(find.text('Test 2'), findsNothing);
    });

    testWidgets('3.2: Active Page 2 clamps to Page 1 when tail box in 3-box sequence is deleted', (tester) async {
      final pageController = PageController(initialPage: 2);
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: List.generate(30, (i) => 'A_${i + 1}'), columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: List.generate(30, (i) => 'B_${i + 1}'), columns: 5, rows: 6);
      final box3 = createTestCustomBox(title: 'Test 3', pokemonIds: ['C_ONLY'], columns: 5, rows: 6);
      final liveDex = createTestUserDex(id: 'dex_clamp_2', customBoxes: [box1, box2, box3]);

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          BoxSequenceManager.removeWithShiftBack(
                            dex: liveDex,
                            boxIndex: 0,
                            slotIndex: 0,
                          );

                          if (pageController.hasClients) {
                            int targetPage = pageController.page?.round() ?? 0;
                            if (targetPage >= liveDex.customBoxes.length && liveDex.customBoxes.isNotEmpty) {
                              targetPage = liveDex.customBoxes.length - 1;
                            }
                            if (targetPage < 0) targetPage = 0;
                            pageController.jumpToPage(targetPage);
                          }
                        });
                      },
                    ),
                  ],
                ),
                body: PageView.builder(
                  controller: pageController,
                  itemCount: liveDex.customBoxes.length,
                  itemBuilder: (ctx, index) => Center(
                    child: Text(liveDex.customBoxes[index].title),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(pageController.page, equals(2.0));
      expect(find.text('Test 3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Test 3 was emptied and auto-deleted; page clamps to Page 1 ("Test 2")
      expect(liveDex.customBoxes.length, equals(2));
      expect(pageController.page, equals(1.0));
      expect(find.text('Test 2'), findsOneWidget);
      expect(find.text('Test 3'), findsNothing);
    });
  });

  group('Challenger M4-2 Stress Target 4: Auto-pop Behavior in BoxContentEditScreen', () {
    testWidgets('4.1: BoxContentEditScreen auto-pops when currently edited overflow box is auto-deleted', (tester) async {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final idsTest2 = ['T2_Single'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final liveDex = createTestUserDex(
        id: 'dex_autopop_1',
        title: 'Auto Pop Test',
        customBoxes: [box1, box2],
      );

      final allEntries = <DexDisplayEntry>[
        createTestEntry(
          pokemon: createTestPokemon(id: 1, nameEn: 'Bulbasaur'),
          uniqueId: 'T2_Single',
        ),
      ];

      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (ctx) => Scaffold(
                body: Builder(
                  builder: (innerCtx) => TextButton(
                    onPressed: () {
                      Navigator.of(innerCtx).push(
                        MaterialPageRoute(
                          builder: (_) => BoxContentEditScreen(
                            dex: liveDex,
                            boxIndex: 1, // Editing "Test 2"
                            allAvailableEntries: allEntries,
                          ),
                        ),
                      ).then((_) {
                        didPop = true;
                      });
                    },
                    child: const Text('Open Editor'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open BoxContentEditScreen
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      expect(find.text('Test 2'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear icon on slot 0 of "Test 2"
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Screen must automatically pop because Test 2 was deleted
      expect(didPop, isTrue, reason: 'BoxContentEditScreen must pop when edited box is deleted');
      expect(liveDex.customBoxes.length, equals(1));
      expect(liveDex.customBoxes.first.title, equals('Test 1'));
    });

    testWidgets('4.2: BoxContentEditScreen does NOT pop when editing root box and clearing its sole item', (tester) async {
      final box1 = createTestCustomBox(
        title: 'Test 1',
        pokemonIds: ['ROOT_SINGLE'],
        columns: 5,
        rows: 6,
      );
      final liveDex = createTestUserDex(
        id: 'dex_autopop_2',
        title: 'Root Clear Editor Test',
        customBoxes: [box1],
      );

      final allEntries = <DexDisplayEntry>[
        createTestEntry(
          pokemon: createTestPokemon(id: 25, nameEn: 'Pikachu'),
          uniqueId: 'ROOT_SINGLE',
        ),
      ];

      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (ctx) => Scaffold(
                body: Builder(
                  builder: (innerCtx) => TextButton(
                    onPressed: () {
                      Navigator.of(innerCtx).push(
                        MaterialPageRoute(
                          builder: (_) => BoxContentEditScreen(
                            dex: liveDex,
                            boxIndex: 0, // Editing root box "Test 1"
                            allAvailableEntries: allEntries,
                          ),
                        ),
                      ).then((_) {
                        didPop = true;
                      });
                    },
                    child: const Text('Open Editor'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      expect(find.text('Test 1'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear icon on root box item
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Invariant: Root box is NOT deleted, so screen does NOT pop!
      expect(didPop, isFalse, reason: 'Root box is preserved, so screen must remain open');
      expect(find.text('Test 1'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing, reason: 'Item was cleared, no remove icon remains');
      expect(liveDex.customBoxes.length, equals(1));
    });

    testWidgets('4.3: BoxContentEditScreen does NOT pop when clearing item in Test 1 triggers deletion of Test 2', (tester) async {
      final ids30 = List.generate(30, (i) => 'M_${i + 1}');
      final idsTest2 = ['T2_OnlyOne'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final liveDex = createTestUserDex(
        id: 'dex_autopop_3',
        title: 'Test 1 Edit Test 2 Deleted',
        customBoxes: [box1, box2],
      );

      final allEntries = <DexDisplayEntry>[
        createTestEntry(
          pokemon: createTestPokemon(id: 1, nameEn: 'Bulbasaur'),
          uniqueId: 'M_1',
        ),
      ];

      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (ctx) => Scaffold(
                body: Builder(
                  builder: (innerCtx) => TextButton(
                    onPressed: () {
                      Navigator.of(innerCtx).push(
                        MaterialPageRoute(
                          builder: (_) => BoxContentEditScreen(
                            dex: liveDex,
                            boxIndex: 0, // Editing "Test 1"
                            allAvailableEntries: allEntries,
                          ),
                        ),
                      ).then((_) {
                        didPop = true;
                      });
                    },
                    child: const Text('Open Editor'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      expect(find.text('Test 1'), findsOneWidget);

      // Clear slot 0 in Test 1. This pulls T2_OnlyOne from Test 2 into Test 1, deleting Test 2.
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pumpAndSettle();

      // Test 1 is still alive! Test 2 was deleted. Screen must stay open on Test 1.
      expect(didPop, isFalse, reason: 'Test 1 was NOT deleted, so screen must remain open');
      expect(find.text('Test 1'), findsOneWidget);
      expect(liveDex.customBoxes.length, equals(1));
      expect(liveDex.customBoxes.first.title, equals('Test 1'));
      expect(liveDex.customBoxes.first.pokemonIds.last, equals('T2_OnlyOne'));
    });
  });
}
