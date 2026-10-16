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

  group('Challenger M4-1 Iteration 3 - Widget UI Stress Tests', () {
    testWidgets('UI-1: Multi-box cascade in BoxContentEditScreen deletes tail box without popping edited root box', (tester) async {
      final t1 = List.generate(30, (i) => 'T1_${i + 1}');
      final t2 = List.generate(30, (i) => 'T2_${i + 1}');
      final t3 = ['T3_TAIL'];

      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: t1, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: t2, columns: 5, rows: 6);
      final box3 = createTestCustomBox(title: 'Test 3', pokemonIds: t3, columns: 5, rows: 6);

      final liveDex = createTestUserDex(
        id: 'dex_ui_1',
        title: 'Cascade UI Dex',
        customBoxes: [box1, box2, box3],
      );

      final allEntries = <DexDisplayEntry>[
        createTestEntry(
          pokemon: createTestPokemon(id: 1, nameEn: 'Bulbasaur'),
          uniqueId: 'T1_1',
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
      expect(find.byIcon(Icons.clear), findsWidgets);

      // Clear slot 0 in Test 1
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pumpAndSettle();

      // Invariants:
      // 1. Root box Test 1 was NOT deleted, so editor remains open
      expect(didPop, isFalse);
      expect(find.text('Test 1'), findsOneWidget);

      // 2. Test 3 was emptied and deleted from dex
      expect(liveDex.customBoxes.length, equals(2));
      expect(liveDex.customBoxes.any((b) => b.title == 'Test 3'), isFalse);

      // 3. Test 1 size remains 30, with Test 2 head pulled into slot 29
      expect(box1.pokemonIds.length, equals(30));
      expect(box1.pokemonIds.last, equals('T2_1'));
      expect(box2.pokemonIds.last, equals('T3_TAIL'));
    });

    testWidgets('UI-2: BoxContentEditScreen auto-pops when edited tail box is auto-deleted', (tester) async {
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ['T1_1', 'T1_2'], columns: 1, rows: 2);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ['T2_ONLY'], columns: 1, rows: 2);

      final liveDex = createTestUserDex(
        id: 'dex_ui_2',
        title: 'AutoPop Dex',
        customBoxes: [box1, box2],
      );

      final allEntries = <DexDisplayEntry>[
        createTestEntry(
          pokemon: createTestPokemon(id: 25, nameEn: 'Pikachu'),
          uniqueId: 'T2_ONLY',
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

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      expect(find.text('Test 2'), findsOneWidget);

      // Clear the solitary slot in Test 2
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pumpAndSettle();

      // Screen auto-pops because Test 2 was deleted
      expect(didPop, isTrue);
      expect(liveDex.customBoxes.length, equals(1));
      expect(liveDex.customBoxes.first.title, equals('Test 1'));
    });

    testWidgets('UI-3: Standalone box "Kanto Tausch" in BoxContentEditScreen is cleared without deleting box or popping screen', (tester) async {
      final kantoTausch = createTestCustomBox(title: 'Kanto Tausch', pokemonIds: ['KT_SINGLE'], columns: 1, rows: 2);
      final test1 = createTestCustomBox(title: 'Test 1', pokemonIds: ['T1_1', 'T1_2'], columns: 1, rows: 2);

      final liveDex = createTestUserDex(
        id: 'dex_ui_3',
        title: 'Standalone UI Dex',
        customBoxes: [kantoTausch, test1],
      );

      final allEntries = <DexDisplayEntry>[
        createTestEntry(
          pokemon: createTestPokemon(id: 7, nameEn: 'Squirtle'),
          uniqueId: 'KT_SINGLE',
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
                            boxIndex: 0, // Editing "Kanto Tausch"
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

      expect(find.text('Kanto Tausch'), findsOneWidget);

      // Clear the solitary item
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pumpAndSettle();

      // Standalone box is protected: never deleted, screen never pops
      expect(didPop, isFalse);
      expect(find.text('Kanto Tausch'), findsOneWidget);
      expect(liveDex.customBoxes.length, equals(2));
      expect(liveDex.customBoxes[0].title, equals('Kanto Tausch'));
      expect(liveDex.customBoxes[0].pokemonIds.where((id) => id.isNotEmpty), isEmpty);
      expect(test1.pokemonIds, equals(['T1_1', 'T1_2']), reason: 'Test 1 must be completely untouched');
    });

    testWidgets('UI-4: DexScreen PageController clamps from Page 2 to Page 1 when Page 2 is auto-deleted during batch deletion', (tester) async {
      final pageController = PageController(initialPage: 2);

      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ['A1', 'A2'], columns: 1, rows: 2);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: ['B1', 'B2'], columns: 1, rows: 2);
      final box3 = createTestCustomBox(title: 'Test 3', pokemonIds: ['C1'], columns: 1, rows: 2);

      final liveDex = createTestUserDex(
        id: 'dex_ui_4',
        title: 'Batch Delete Clamping Dex',
        customBoxes: [box1, box2, box3],
      );

      final selectedKeys = <String>{'2_0'}; // Deleting C1 in Test 3

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
                          BoxSequenceManager.batchRemoveWithShiftBack(
                            dex: liveDex,
                            selectedKeys: selectedKeys.toList(),
                          );
                          selectedKeys.clear();

                          // Mirror DexScreen page clamping
                          if (pageController.hasClients && liveDex.customBoxes.isNotEmpty) {
                            int targetPage = pageController.page?.round() ?? 0;
                            if (targetPage >= liveDex.customBoxes.length) {
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

      // Verify on Page 2 ("Test 3")
      expect(pageController.page, equals(2.0));
      expect(find.text('Test 3'), findsOneWidget);

      // Perform batch delete
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Test 3 deleted -> page clamps to Page 1 ("Test 2") smoothly without error
      expect(liveDex.customBoxes.length, equals(2));
      expect(pageController.page, equals(1.0));
      expect(find.text('Test 2'), findsOneWidget);
      expect(find.text('Test 3'), findsNothing);
    });
  });
}
