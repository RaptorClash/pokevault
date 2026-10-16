import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import 'package:pokevault/services/database_service.dart';
import '../../e2e/e2e_test_helper.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDatabaseService mockDb;
  late MockSettingsProvider mockSettings;
  late MockTutorialProvider mockTutorial;

  setUpAll(() {
    registerFallbackValue(
      UserDex(
        id: 'dummy',
        title: 'dummy',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      ),
    );
    registerFallbackValue(<String, List<String>>{});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDb = MockDatabaseService();
    mockSettings = MockSettingsProvider();
    mockTutorial = MockTutorialProvider();

    when(() => mockDb.getAllPokemon()).thenAnswer((_) async => []);
    when(() => mockDb.getAllDexOrders()).thenAnswer((_) async => {});
    when(() => mockDb.getBallUrls()).thenAnswer((_) async => {});
    when(() => mockDb.getAllUserDexes()).thenAnswer((_) async => []);
    when(() => mockDb.getAllFolders()).thenAnswer((_) async => []);
    when(() => mockDb.getAllRibbons()).thenAnswer((_) async => []);
    when(() => mockDb.getStructure()).thenAnswer((_) async => {'root': []});
    when(() => mockDb.saveUserDex(any())).thenAnswer((_) async {});
    when(() => mockDb.saveStructure(any())).thenAnswer((_) async {});
    when(() => mockDb.savePokemonStatus(
          any(),
          any(),
          isCaught: any(named: 'isCaught'),
          isShiny: any(named: 'isShiny'),
          isAlpha: any(named: 'isAlpha'),
        )).thenAnswer((_) async {});

    when(() => mockSettings.currentLanguage).thenReturn('en');
    when(() => mockTutorial.hasSeenFeature(any())).thenReturn(true);
  });

  group('Distinct Instance Caught Independence Tests', () {
    test('Newly added instance of an already caught Pokémon starts as uncaught in DexLogicHelper', () {
      final dex = createTestUserDex(
        id: 'dex_1',
        title: 'Kanto Dex',
        caughtIds: ['25_normal', '25_normal__inst1'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__inst1'],
          ),
        ],
      );

      // Existing instance is caught
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isTrue);
      // Base ID is caught
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);

      // Add a second instance of the same Pokémon (Pikachu) to the box
      const newInstanceId = '25_normal__inst2';
      dex.customBoxes.first.pokemonIds.add(newInstanceId);

      // CRITICAL: The newly added instance MUST NOT inherit caught status from base ID!
      expect(DexLogicHelper.isPokemonCaught(dex, newInstanceId), isFalse);
    });

    testWidgets('DexBoxView renders already-caught instance as caught and newly-added instance as uncaught (grayscale)', (tester) async {
      final pokePikachu = createTestPokemon(id: 25, nameEn: 'Pikachu');
      const inst1Id = '25_normal__inst1';
      const inst2Id = '25_normal__inst2';

      final dex = createTestUserDex(
        id: 'dex_1',
        title: 'Kanto Dex',
        caughtIds: ['25_normal', inst1Id],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: [inst1Id, inst2Id],
            columns: 2,
            rows: 1,
          ),
        ],
      );

      final entries = [
        createTestEntry(
          pokemon: pokePikachu,
          uniqueId: inst1Id,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
        ),
        createTestEntry(
          pokemon: pokePikachu,
          uniqueId: inst2Id,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
        ),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries, crossAxisCount: 2);

      final mockProvider = MockDexProvider();
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: dex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
          isEditMode: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        mockTutorialProvider: mockTutorial,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Look for the green catching_pokemon icons indicating caught status
      final catchIcons = find.byWidgetPredicate((w) =>
          w is Icon &&
          w.icon == Icons.catching_pokemon &&
          w.color == Colors.green);
      // Only the first instance is caught, so exactly 1 green catch icon should exist
      expect(catchIcons, findsOneWidget);

      // Find grayscale ColorFiltered widgets in the tree
      // The uncaught instance must have a grayscale filter applied
      final grayscaleWidgets = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered)).where((cf) => isGrayscaleFilter(cf.colorFilter));
      expect(grayscaleWidgets.isNotEmpty, isTrue);
    });

    test('DexProvider.togglePokemon toggles instances independently in custom boxes', () async {
      final dex = createTestUserDex(
        id: 'dex_test',
        title: 'Custom Dex',
        caughtIds: ['25_normal', '25_normal__inst1'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__inst1', '25_normal__inst2'],
          ),
        ],
      );

      final dexProvider = DexProvider(databaseService: mockDb);
      dexProvider.userDexes = [dex];

      try {
        // Initially inst1 is caught, inst2 is uncaught
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);

        // 1. Toggle inst2 -> now caught
        dexProvider.togglePokemon('dex_test', '25_normal__inst2');
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isTrue);
        expect(dex.caughtIds.contains('25_normal'), isTrue);

        // 2. Uncheck inst1 -> inst1 becomes uncaught, inst2 REMAINS CAUGHT!
        dexProvider.togglePokemon('dex_test', '25_normal__inst1');
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isTrue);
        // BaseId is still caught because inst2 is still caught in custom boxes
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);

        // 3. Uncheck inst2 -> both are uncaught, baseId is also removed from caughtIds
        dexProvider.togglePokemon('dex_test', '25_normal__inst2');
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isFalse);
      } finally {
        await Future.delayed(const Duration(milliseconds: 100));
        dexProvider.dispose();
      }
    });

    testWidgets('Tapping uncaught instance in DexBoxView invokes provider.togglePokemon with distinct instanceId', (tester) async {
      final pokePikachu = createTestPokemon(id: 25, nameEn: 'Pikachu');
      const inst1Id = '25_normal__inst1';
      const inst2Id = '25_normal__inst2';

      final dex = createTestUserDex(
        id: 'dex_tap_test',
        title: 'Tap Test Dex',
        caughtIds: ['25_normal', inst1Id],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: [inst1Id, inst2Id],
            columns: 2,
            rows: 1,
          ),
        ],
      );

      final entries = [
        createTestEntry(
          pokemon: pokePikachu,
          uniqueId: inst1Id,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
        ),
        createTestEntry(
          pokemon: pokePikachu,
          uniqueId: inst2Id,
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
        ),
      ];
      final boxData = createTestBoxData(title: 'Box 1', entries: entries, crossAxisCount: 2);

      final mockProvider = MockDexProvider();
      when(() => mockProvider.userDexes).thenReturn([dex]);
      when(() => mockProvider.togglePokemon(any(), any())).thenReturn(null);

      await tester.pumpWidget(wrapWithApp(
        child: DexBoxView(
          boxes: [boxData],
          liveDex: dex,
          provider: mockProvider,
          pageController: PageController(),
          separateForms: true,
          highlightedIds: const {},
          isSearchActive: false,
          isEditMode: false,
        ),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        mockTutorialProvider: mockTutorial,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final cardInkWells = find.ancestor(
        of: find.byType(CachedNetworkImage),
        matching: find.byType(InkWell),
      );
      expect(cardInkWells, findsNWidgets(2));

      // Tap second card (inst2, currently uncaught)
      await tester.tap(cardInkWells.at(1));
      await tester.pump();
      verify(() => mockProvider.togglePokemon('dex_tap_test', inst2Id)).called(1);

      // Tap first card (inst1, currently caught)
      await tester.tap(cardInkWells.at(0));
      await tester.pump();
      verify(() => mockProvider.togglePokemon('dex_tap_test', inst1Id)).called(1);
    });

    test('BoxSequenceManager insertion of already-caught species produces uncaught instance', () {
      final dex = createTestUserDex(
        id: 'seq_test',
        title: 'Seq Dex',
        caughtIds: ['25_normal', '25_normal__inst1'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__inst1'],
            columns: 5,
            rows: 6,
          ),
        ],
      );

      const newInstanceId = '25_normal__123456789_0';
      BoxSequenceManager.insertWithShiftAndOverflow(
        dex: dex,
        boxIndex: 0,
        slotIndex: 1,
        pokemonId: newInstanceId,
      );

      expect(dex.customBoxes.first.pokemonIds, contains(newInstanceId));
      expect(dex.caughtIds.contains(newInstanceId), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, newInstanceId), isFalse);
    });

    test('BoxContentEditScreen adding an already caught species creates uncaught instance and preserves caughtIds', () {
      final dex = createTestUserDex(
        id: 'box_edit_test',
        title: 'Edit Test Dex',
        caughtIds: ['25_normal', '25_normal__inst1'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__inst1', ''],
            columns: 5,
            rows: 6,
          ),
        ],
      );

      // Simulate the exact logic executed by BoxContentEditScreen._pickPokemon
      const selectedId = '25_normal';
      final isShinySelection = selectedId.startsWith('shiny:');
      final baseId = DexLogicHelper.getBaseId(selectedId);
      final instanceId = '${baseId}__${DateTime.now().millisecondsSinceEpoch}_12345_1';

      dex.customBoxes.first.pokemonIds[1] = instanceId;
      if (isShinySelection && !dex.shinyIds.contains(instanceId)) {
        dex.shinyIds.add(instanceId);
      }

      // The new instance is in the box
      expect(dex.customBoxes.first.pokemonIds[1], equals(instanceId));
      // caughtIds does NOT have instanceId
      expect(dex.caughtIds.contains(instanceId), isFalse);
      // isPokemonCaught evaluates to false
      expect(DexLogicHelper.isPokemonCaught(dex, instanceId), isFalse);
      // The original instance is still caught
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isTrue);
    });

    test('Newly added duplicate instance is uncaught when baseId is in caughtIds', () {
      final dex = createTestUserDex(
        id: 'custom_dex_dup_inst',
        title: 'Custom Dup Dex',
        caughtIds: ['25_normal'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__orig'],
            columns: 5,
            rows: 6,
          ),
        ],
      );

      // The primary instance inherits caught status
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__orig'), isTrue);

      // Add a duplicate Pikachu to Box 1
      const newInstanceId = '25_normal__999888_1';
      dex.customBoxes.first.pokemonIds.add(newInstanceId);

      // The original instance remains caught, but the new duplicate MUST be uncaught
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__orig'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, newInstanceId), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);
    });

    test('Existing dex preservation: 680 caught base IDs in caughtIds are preserved as caught in custom boxes', () {
      final caughtList = List.generate(680, (i) => '${i + 1}_normal');
      final allSlots = List.generate(1020, (i) => '${i + 1}_normal__timestamp_$i');
      final dex = createTestUserDex(
        id: 'national_dex_680',
        title: 'Nationaldex',
        caughtIds: caughtList,
        customBoxes: [
          CustomBoxState(
            title: 'Kanto 1',
            pokemonIds: allSlots.sublist(0, 30),
            columns: 5,
            rows: 6,
          ),
          CustomBoxState(
            title: 'Remaining Boxes',
            pokemonIds: allSlots.sublist(30),
            columns: 5,
            rows: 6,
          ),
        ],
      );

      // DexLogicHelper getCaughtCount must return 680
      expect(DexLogicHelper.getCaughtCount(dex), equals(680));
      // First 680 box entries are evaluated as caught
      for (int i = 0; i < 680; i++) {
        expect(DexLogicHelper.isPokemonCaught(dex, allSlots[i]), isTrue, reason: 'Slot $i should be caught');
      }
      // Remaining 340 entries are uncaught
      for (int i = 680; i < 1020; i++) {
        expect(DexLogicHelper.isPokemonCaught(dex, allSlots[i]), isFalse, reason: 'Slot $i should be uncaught');
      }
    });

    test('3 identical species instances: toggling #2 to caught, moving to Box 2 keeps #1 and #3 uncaught', () async {
      final dex = createTestUserDex(
        id: 'multi_inst_dex',
        title: 'Multi Instance Dex',
        caughtIds: [],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__inst1', '25_normal__inst2', '25_normal__inst3'],
            columns: 5,
            rows: 6,
          ),
          CustomBoxState(
            title: 'Box 2',
            pokemonIds: ['', '', ''],
            columns: 5,
            rows: 6,
          ),
        ],
      );

      final dexProvider = DexProvider(databaseService: mockDb);
      dexProvider.userDexes = [dex];

      try {
        // All 3 start uncaught
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst3'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isFalse);

        // Toggle instance #2 to caught
        dexProvider.togglePokemon('multi_inst_dex', '25_normal__inst2');
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst3'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);

        // Move instance #2 to Box 2, slot 0
        BoxSequenceManager.movePokemon(
          dex: dex,
          sourceId: '25_normal__inst2',
          targetBoxIndex: 1,
          targetSlotIndex: 0,
        );

        // Verify placement
        expect(dex.customBoxes[0].pokemonIds, isNot(contains('25_normal__inst2')));
        expect(dex.customBoxes[1].pokemonIds[0], equals('25_normal__inst2'));

        // Invariance check: instances #1 and #3 in Box 1 remain UNCAUGHT, instance #2 in Box 2 remains CAUGHT
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst3'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);
      } finally {
        await Future.delayed(const Duration(milliseconds: 100));
        dexProvider.dispose();
      }
    });

    test('Legacy dex with only baseId caught: toggling duplicate #2 to caught preserves instance #1 as caught', () async {
      final dex = createTestUserDex(
        id: 'legacy_toggle_dex',
        title: 'Legacy Toggle Dex',
        caughtIds: ['25_normal'], // Only baseId in caughtIds (legacy state)
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__inst1', '25_normal__inst2'],
            columns: 5,
            rows: 6,
          ),
        ],
      );

      final dexProvider = DexProvider(databaseService: mockDb);
      dexProvider.userDexes = [dex];

      try {
        // Initially: inst1 is caught (primary inherits from baseId), inst2 is uncaught
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isFalse);
        expect(DexLogicHelper.getCaughtCount(dex), equals(1));

        // Toggle duplicate inst2 to caught
        dexProvider.togglePokemon('legacy_toggle_dex', '25_normal__inst2');

        // CRITICAL: inst1 MUST STILL BE CAUGHT!
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isTrue,
            reason: 'Primary instance must NOT lose caught status when duplicate is toggled caught');
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isTrue);
        expect(dex.caughtIds, contains('25_normal__inst1'));
        expect(dex.caughtIds, contains('25_normal__inst2'));
        expect(dex.caughtIds, contains('25_normal'));
        expect(DexLogicHelper.getCaughtCount(dex), equals(2));

        // Now toggle inst1 to uncaught
        dexProvider.togglePokemon('legacy_toggle_dex', '25_normal__inst1');
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isTrue);
        expect(dex.caughtIds, contains('25_normal'), reason: 'baseId remains caught while inst2 is caught');
        expect(DexLogicHelper.getCaughtCount(dex), equals(1));

        // Toggle inst2 to uncaught
        dexProvider.togglePokemon('legacy_toggle_dex', '25_normal__inst2');
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isFalse);
        expect(dex.caughtIds, isNot(contains('25_normal')), reason: 'baseId removed when all instances are uncaught');
        expect(DexLogicHelper.getCaughtCount(dex), equals(0));
      } finally {
        await Future.delayed(const Duration(milliseconds: 100));
        dexProvider.dispose();
      }
    });

    test('Legacy dex with only baseId shiny/alpha: toggling duplicate #2 preserves instance #1', () async {
      final dex = createTestUserDex(
        id: 'legacy_shiny_alpha_dex',
        title: 'Legacy Shiny Alpha Dex',
        shinyIds: ['25_normal'],
        alphaIds: ['25_normal'],
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__inst1', '25_normal__inst2'],
            columns: 5,
            rows: 6,
          ),
        ],
      );

      final dexProvider = DexProvider(databaseService: mockDb);
      dexProvider.userDexes = [dex];

      try {
        expect(DexLogicHelper.isPokemonShiny(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonShiny(dex, '25_normal__inst2'), isFalse);
        expect(DexLogicHelper.isPokemonAlpha(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonAlpha(dex, '25_normal__inst2'), isFalse);

        // Toggle shiny on inst2
        dexProvider.toggleShiny('legacy_shiny_alpha_dex', '25_normal__inst2');
        expect(DexLogicHelper.isPokemonShiny(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonShiny(dex, '25_normal__inst2'), isTrue);

        // Toggle alpha on inst2
        await dexProvider.toggleAlpha('legacy_shiny_alpha_dex', '25_normal__inst2');
        expect(DexLogicHelper.isPokemonAlpha(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonAlpha(dex, '25_normal__inst2'), isTrue);
      } finally {
        await Future.delayed(const Duration(milliseconds: 100));
        dexProvider.dispose();
      }
    });

    test('ensurePrimaryInstancePersisted locks existing instance caught status when inserting before it', () {
      final dex = createTestUserDex(
        id: 'prepend_test_dex',
        title: 'Prepend Test Dex',
        caughtIds: ['25_normal'], // legacy caught
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_normal__existing'],
            columns: 5,
            rows: 6,
          ),
        ],
      );

      // Before inserting, lock primary instance
      DexLogicHelper.ensurePrimaryInstancePersisted(dex, '25_normal');
      expect(dex.caughtIds, contains('25_normal__existing'));

      // Prepend a new duplicate instance before the existing one
      dex.customBoxes.first.pokemonIds.insert(0, '25_normal__new');

      // Newly prepended instance is UNCAUGHT, existing instance REMAIN CAUGHT
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__new'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__existing'), isTrue);
    });

    test('getCaughtCount respects ignoredIds and deduplicates canonical base IDs', () {
      final dex = createTestUserDex(
        id: 'count_dex',
        title: 'Count Dex',
        caughtIds: ['1_normal', '2_normal', '3_normal', '1_normal__dup'],
        ignoredIds: ['2_normal'],
      );

      // In regular dex (customBoxes empty), ignore 2_normal and deduplicate 1_normal
      expect(DexLogicHelper.getCaughtCount(dex), equals(2)); // only 1_normal and 3_normal

      // In custom boxes dex
      dex.customBoxes = [
        CustomBoxState(
          title: 'Box 1',
          pokemonIds: ['1_normal__1', '2_normal__1', '3_normal__1'],
        ),
      ];
      dex.caughtIds = ['1_normal__1', '2_normal__1', '3_normal__1'];
      // 2_normal is ignored
      expect(DexLogicHelper.getCaughtCount(dex), equals(2));
    });
  });
}
