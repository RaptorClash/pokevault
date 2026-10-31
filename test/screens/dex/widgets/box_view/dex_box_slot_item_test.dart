import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/screens/dex/delegates/box_action_delegate.dart';
import 'package:pokevault/screens/dex/widgets/box_view/dex_box_slot_item.dart';
import '../../../../e2e/helpers/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockProvider;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockProvider = MockDexProvider();
    mockSettings = MockSettingsProvider();
  });

  Pokemon createDummyPokemon({int id = 1, String name = 'Bulbasaur'}) {
    return Pokemon(
      id: id,
      nameDe: name,
      nameEn: name,
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: 255,
      evolutionChainId: -1,
      eggGroups: [],
      weight: 1.0,
      speed: 10,
      forms: [],
    );
  }

  DexDisplayEntry createDummyEntry({int id = 1, String uniqueId = '1_normal'}) {
    return DexDisplayEntry(
      pokemon: createDummyPokemon(id: id),
      uniqueId: uniqueId,
      displaySuffix: '',
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
    );
  }

  UserDex createDummyDex({
    String id = 'test_dex',
    List<String> caughtIds = const [],
    bool isShinyDex = false,
  }) {
    return UserDex(
      id: id,
      title: 'Test Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: true,
      includeMega: true,
      includeGMax: true,
      includeOther: false,
      isShinyDex: isShinyDex,
      caughtIds: caughtIds,
    );
  }

  Widget buildSlotWidget({
    required DexDisplayEntry entry,
    required UserDex liveDex,
    required BoxActionDelegate actionDelegate,
    bool isEditMode = false,
    Set<String> selectedForEdit = const {},
    Set<String> highlightedIds = const {},
    bool isSearchActive = false,
  }) {
    final boxData = BoxData('Box 1', 'kanto', [entry], 6);
    return wrapWithApp(
      child: Material(
        child: SizedBox(
          width: 80,
          height: 80,
          child: DexBoxSlotItem(
            entry: entry,
            index: 0,
            boxIndex: 0,
            box: boxData,
            boxes: [boxData],
            boxOrderedEntries: [entry],
            liveDex: liveDex,
            provider: mockProvider,
            pageController: PageController(),
            isEditMode: isEditMode,
            selectedForEdit: selectedForEdit,
            highlightedIds: highlightedIds,
            isSearchActive: isSearchActive,
            actionDelegate: actionDelegate,
            isDragging: false,
            draggedMultiIds: const [],
            hoveredSlotIndex: null,
            hoveredBoxIndex: null,
            hoveredIsEdge: false,
            onHoverChanged: (_, _, _) {},
            onDragStateChanged: (_, _) {},
            onStopEdgeScroll: () {},
            getSelectedPokemonIds: () => [],
            screenWidth: 800,
          ),
        ),
      ),
      mockDexProvider: mockProvider,
      mockSettingsProvider: mockSettings,
    );
  }

  group('DexBoxSlotItem - Styling and Tap Verification (TDD)', () {
    testWidgets('Caught Pokémon renders with vibrant green background and green border', (tester) async {
      final entry = createDummyEntry(id: 1, uniqueId: '1_normal');
      final dex = createDummyDex(caughtIds: ['1_normal', '1']);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(buildSlotWidget(
        entry: entry,
        liveDex: dex,
        actionDelegate: const DefaultBoxActionDelegate(),
      ));
      await tester.pump();

      // Verify slot container decoration
      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final boxDec = widget.decoration as BoxDecoration;
          return boxDec.color == Colors.green.withValues(alpha: 0.15);
        }
        return false;
      });

      expect(containerFinder, findsOneWidget,
          reason: 'Slot must render with Colors.green.withValues(alpha: 0.15) when caught');

      final decoratedContainer = tester.widget<Container>(containerFinder);
      final boxDec = decoratedContainer.decoration as BoxDecoration;
      expect((boxDec.border as Border?)?.top.color, equals(Colors.green));
      expect((boxDec.border as Border?)?.top.width, equals(2));
    });

    testWidgets('Uncaught Pokémon renders with cardColor and subtle border', (tester) async {
      final entry = createDummyEntry(id: 1, uniqueId: '1_normal');
      final dex = createDummyDex(caughtIds: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(buildSlotWidget(
        entry: entry,
        liveDex: dex,
        actionDelegate: const DefaultBoxActionDelegate(),
      ));
      await tester.pump();

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final boxDec = widget.decoration as BoxDecoration;
          return boxDec.color != Colors.green.withValues(alpha: 0.15);
        }
        return false;
      });

      expect(containerFinder, findsWidgets);
    });

    testWidgets('Tapping on a slot reliably triggers provider.togglePokemon', (tester) async {
      final entry = createDummyEntry(id: 25, uniqueId: '25_normal');
      final dex = createDummyDex(caughtIds: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);
      when(() => mockProvider.togglePokemon(any(), any())).thenReturn(null);

      await tester.pumpWidget(buildSlotWidget(
        entry: entry,
        liveDex: dex,
        actionDelegate: const DefaultBoxActionDelegate(),
      ));
      await tester.pump();

      // Tap the slot item
      await tester.tap(find.byType(DexBoxSlotItem));
      await tester.pump();

      verify(() => mockProvider.togglePokemon('test_dex', '25_normal')).called(1);
    });

    testWidgets('Tapping in edit mode triggers actionDelegate.onSelectionChanged', (tester) async {
      final entry = createDummyEntry(id: 1, uniqueId: '1_normal');
      final dex = createDummyDex();
      when(() => mockProvider.userDexes).thenReturn([dex]);

      int? selectedBox, selectedItem;
      final delegate = DefaultBoxActionDelegate(
        onSelectionChangedHandler: (b, i) {
          selectedBox = b;
          selectedItem = i;
        },
      );

      await tester.pumpWidget(buildSlotWidget(
        entry: entry,
        liveDex: dex,
        actionDelegate: delegate,
        isEditMode: true,
      ));
      await tester.pump();

      await tester.tap(find.byType(DexBoxSlotItem));
      await tester.pump();

      expect(selectedBox, equals(0));
      expect(selectedItem, equals(0));
      verifyNever(() => mockProvider.togglePokemon(any(), any()));
    });
  });
}
