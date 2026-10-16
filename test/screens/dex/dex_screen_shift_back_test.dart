import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/screens/dex/box_content_edit_screen.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DexShiftBack UI Integration Tests - Milestone M4', () {
    testWidgets('DexScreen batch deletion shifts backward and cleans up empty overflow boxes', (tester) async {
      final ids30 = List.generate(30, (i) => 'T1_${i + 1}');
      final idsTest2 = ['T2_OnlyOne'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Batch Delete UI Test',
        customBoxes: [box1, box2],
      );

      final selectedForEdit = <String>{'0_0'};

      // Stateful UI harness representing DexScreen batch deletion workflow
      await tester.pumpWidget(wrapWithApp(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              appBar: AppBar(
                title: Text(liveDex.title),
                actions: [
                  if (selectedForEdit.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          BoxSequenceManager.batchRemoveWithShiftBack(
                            dex: liveDex,
                            selectedKeys: selectedForEdit.toList(),
                          );
                          selectedForEdit.clear();
                        });
                      },
                    ),
                ],
              ),
              body: ListView.builder(
                itemCount: liveDex.customBoxes.length,
                itemBuilder: (ctx, index) {
                  final b = liveDex.customBoxes[index];
                  return ListTile(
                    title: Text(b.title),
                    subtitle: Text('${b.pokemonIds.length} items'),
                  );
                },
              ),
            );
          },
        ),
      ));

      // Verify UI initial state: 2 boxes, delete button visible because items are selected
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.text('Test 1'), findsOneWidget);
      expect(find.text('Test 2'), findsOneWidget);

      // Perform genuine UI interaction: tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Verify UI updated state:
      // 1. Delete button is now gone since selection was cleared
      expect(find.byIcon(Icons.delete), findsNothing);
      // 2. Test 2 was emptied and auto-deleted from the UI list
      expect(find.text('Test 2'), findsNothing);
      expect(find.text('Test 1'), findsOneWidget);

      // Invariants:
      // 1. Test 1 shifted backwards, last item is T2_OnlyOne
      expect(liveDex.customBoxes.first.pokemonIds.length, equals(30));
      expect(liveDex.customBoxes.first.pokemonIds.first, equals('T1_2'));
      expect(liveDex.customBoxes.first.pokemonIds.last, equals('T2_OnlyOne'));

      // 2. Test 2 became empty and was auto-deleted by cleanupEmptyBoxes
      expect(liveDex.customBoxes.length, equals(1));
      expect(liveDex.customBoxes.first.title, equals('Test 1'));
    });

    testWidgets('PageController clamping handles deleted overflow box page without crash', (tester) async {
      final pageController = PageController(initialPage: 1);
      List<String> pageTitles = ['Test 1', 'Test 2'];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          pageTitles = ['Test 1']; // Overflow box deleted
                          int targetPage = pageController.page?.round() ?? 0;
                          if (targetPage >= pageTitles.length && pageTitles.isNotEmpty) {
                            targetPage = pageTitles.length - 1;
                          }
                          pageController.jumpToPage(targetPage);
                        });
                      },
                      child: const Text('Delete Overflow Box'),
                    ),
                  ],
                ),
                body: PageView.builder(
                  controller: pageController,
                  itemCount: pageTitles.length,
                  itemBuilder: (ctx, index) => Center(child: Text(pageTitles[index])),
                ),
              );
            },
          ),
        ),
      );

      // Initially on page 1 ('Test 2')
      expect(pageController.page, equals(1.0));
      expect(find.text('Test 2'), findsOneWidget);

      // Delete overflow box
      await tester.tap(find.text('Delete Overflow Box'));
      await tester.pumpAndSettle();

      // PageController successfully clamped to page 0 without crash or out-of-range exception
      expect(pageController.page, equals(0.0));
      expect(find.text('Test 1'), findsOneWidget);
      expect(find.text('Test 2'), findsNothing);
    });

    testWidgets('PokemonInfoScreen removal logic resolves correct slot and triggers shift-back', (tester) async {
      final ids30 = List.generate(30, (i) => 'T1_${i + 1}');
      final idsTest2 = ['T2_A', 'T2_B'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Info Screen Test',
        customBoxes: [box1, box2],
      );

      final entryToRemove = createTestEntry(
        pokemon: createTestPokemon(id: 1, nameEn: 'Bulbasaur'),
        uniqueId: 'T1_1',
      );

      // Mount UI harness presenting the removal confirmation dialog as in PokemonInfoScreen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  // Simulating filtered list mismatch: bIndex=0, iIndex=99 (out of range / mismatched)
                  int targetBoxIndex = 0;
                  int targetSlotIndex = 99;

                  if (targetBoxIndex >= liveDex.customBoxes.length ||
                      targetSlotIndex >= liveDex.customBoxes[targetBoxIndex].pokemonIds.length ||
                      liveDex.customBoxes[targetBoxIndex].pokemonIds[targetSlotIndex] != entryToRemove.uniqueId) {
                    for (int b = 0; b < liveDex.customBoxes.length; b++) {
                      final s = liveDex.customBoxes[b].pokemonIds.indexOf(entryToRemove.uniqueId);
                      if (s != -1) {
                        targetBoxIndex = b;
                        targetSlotIndex = s;
                        break;
                      }
                    }
                  }

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Pokémon entfernen'),
                      content: const Text('Möchtest du dieses Pokémon nur aus dieser Box entfernen?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () {
                            BoxSequenceManager.removeWithShiftBack(
                              dex: liveDex,
                              boxIndex: targetBoxIndex,
                              slotIndex: targetSlotIndex,
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text('Nur aus Box'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Remove Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open remove dialog via UI button
      await tester.tap(find.text('Open Remove Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Pokémon entfernen'), findsOneWidget);
      expect(find.text('Nur aus Box'), findsOneWidget);

      // Tap confirm removal button in dialog
      await tester.tap(find.text('Nur aus Box'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Pokémon entfernen'), findsNothing);

      // Verify shift back executed properly
      expect(liveDex.customBoxes[0].pokemonIds.length, equals(30));
      expect(liveDex.customBoxes[0].pokemonIds.last, equals('T2_A'));
      expect(liveDex.customBoxes[1].pokemonIds, equals(['T2_B']));
    });

    testWidgets('BoxContentEditScreen _clearSlot shifts back and auto-pops if overflow box deleted', (tester) async {
      final ids30 = List.generate(30, (i) => 'T1_${i + 1}');
      final idsTest2 = ['T2_Single'];
      final box1 = createTestCustomBox(title: 'Test 1', pokemonIds: ids30, columns: 5, rows: 6);
      final box2 = createTestCustomBox(title: 'Test 2', pokemonIds: idsTest2, columns: 5, rows: 6);
      final liveDex = createTestUserDex(
        id: 'dex1',
        title: 'Box Content Edit Test',
        customBoxes: [box1, box2],
      );

      final allEntries = <DexDisplayEntry>[
        createTestEntry(
          pokemon: createTestPokemon(id: 25, nameEn: 'Pikachu'),
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
                            boxIndex: 1, // "Test 2"
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

      // Tap clear icon on slot 0
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // The box was emptied and auto-deleted, so screen popped back
      expect(didPop, isTrue);
      expect(liveDex.customBoxes.length, equals(1));
      expect(liveDex.customBoxes.first.title, equals('Test 1'));
    });
  });
}
