import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/box_edit_screen.dart';
import 'package:pokevault/l10n/app_translations.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

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

  Finder getAutoShiftSwitch() => find.byWidgetPredicate((w) =>
      w is SwitchListTile &&
      (w.title.toString().toLowerCase().contains('shift') ||
       w.subtitle.toString().toLowerCase().contains('shift')));

  Finder getStrictLimitsSwitch() => find.byWidgetPredicate((w) =>
      w is SwitchListTile &&
      (w.title.toString().toLowerCase().contains('limit') ||
       w.title.toString().toLowerCase().contains('capacity') ||
       w.subtitle.toString().toLowerCase().contains('limit')));

  Finder getPatternAutoCreateSwitch() => find.byWidgetPredicate((w) =>
      w is SwitchListTile &&
      (w.title.toString().toLowerCase().contains('pattern') ||
       w.title.toString().toLowerCase().contains('auto-create') ||
       w.title.toString().toLowerCase().contains('create') ||
       w.subtitle.toString().toLowerCase().contains('pattern')));

  Finder getAutoDeleteEmptySwitch() => find.byWidgetPredicate((w) =>
      w is SwitchListTile &&
      (w.title.toString().toLowerCase().contains('empty') ||
       w.title.toString().toLowerCase().contains('delete') ||
       w.subtitle.toString().toLowerCase().contains('empty') ||
       w.subtitle.toString().toLowerCase().contains('delete')));

  // =========================================================================
  // SUITE 1: Multi-Box Synchronization & Edge Box Counts (0, 1, 12, 25 boxes)
  // =========================================================================
  group('Challenger M5-1 Suite 1: Multi-Box Synchronization & Scale Invariants', () {
    testWidgets('1.1: Empty Dex (0 boxes) toggling all 4 switches succeeds without exception', (tester) async {
      final dex = createTestUserDex(id: 'dex_0_box', title: 'Zero Box Dex', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      final finders = [
        getAutoShiftSwitch(),
        getStrictLimitsSwitch(),
        getPatternAutoCreateSwitch(),
        getAutoDeleteEmptySwitch(),
      ];

      for (final f in finders) {
        expect(f, findsOneWidget);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      expect(dex.customBoxes.isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2: Single Box (1 box) synchronization flips model and UI synchronously', (tester) async {
      final box = createTestCustomBox(
        title: 'Solo Box',
        pokemonIds: ['1'],
        autoShift: true,
        strictLimits: true,
        patternAutoCreate: true,
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(id: 'dex_1_box', title: 'Single Box Dex', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      // Flip autoShift OFF
      await tester.tap(getAutoShiftSwitch());
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(getAutoShiftSwitch()).value, isFalse);
      expect(dex.customBoxes.first.autoShift, isFalse);

      // Flip strictLimits OFF
      await tester.tap(getStrictLimitsSwitch());
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(getStrictLimitsSwitch()).value, isFalse);
      expect(dex.customBoxes.first.strictLimits, isFalse);

      // Other 2 switches remain true
      expect(tester.widget<SwitchListTile>(getPatternAutoCreateSwitch()).value, isTrue);
      expect(dex.customBoxes.first.patternAutoCreate, isTrue);
      expect(tester.widget<SwitchListTile>(getAutoDeleteEmptySwitch()).value, isTrue);
      expect(dex.customBoxes.first.autoDeleteEmpty, isTrue);

      expect(tester.takeException(), isNull);
    });

    testWidgets('1.3: 12 Boxes with heterogeneous initial states synchronize uniformly across all boxes', (tester) async {
      final boxes = List.generate(12, (i) => createTestCustomBox(
        title: 'Kanto ${i + 1}',
        pokemonIds: ['P$i'],
        autoShift: i % 2 == 0,
        strictLimits: i % 3 == 0,
        patternAutoCreate: i % 4 == 0,
        autoDeleteEmpty: i % 5 == 0,
      ));
      final dex = createTestUserDex(id: 'dex_12_box', title: '12 Box Dex', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      // Toggle autoShift
      final autoShiftFinder = getAutoShiftSwitch();
      final currentAutoShift = tester.widget<SwitchListTile>(autoShiftFinder).value;
      await tester.tap(autoShiftFinder);
      await tester.pumpAndSettle();

      final expectedAutoShift = !currentAutoShift;
      expect(dex.customBoxes.length, 12);
      for (int i = 0; i < 12; i++) {
        expect(dex.customBoxes[i].autoShift, equals(expectedAutoShift),
            reason: 'Box $i must synchronize autoShift to $expectedAutoShift');
      }

      // Toggle patternAutoCreate
      final patternFinder = getPatternAutoCreateSwitch();
      final currentPattern = tester.widget<SwitchListTile>(patternFinder).value;
      await tester.tap(patternFinder);
      await tester.pumpAndSettle();

      final expectedPattern = !currentPattern;
      for (int i = 0; i < 12; i++) {
        expect(dex.customBoxes[i].patternAutoCreate, equals(expectedPattern),
            reason: 'Box $i must synchronize patternAutoCreate to $expectedPattern');
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('1.4: 25 Boxes large-scale synchronization maintains complete consistency', (tester) async {
      final boxes = List.generate(25, (i) => createTestCustomBox(
        title: 'Box ${i + 1}',
        pokemonIds: ['Pkmn_${i * 2}'],
        autoShift: true,
        strictLimits: true,
        patternAutoCreate: true,
        autoDeleteEmpty: true,
      ));
      final dex = createTestUserDex(id: 'dex_25_box', title: '25 Box Dex', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      final finders = [
        getAutoShiftSwitch(),
        getStrictLimitsSwitch(),
        getPatternAutoCreateSwitch(),
        getAutoDeleteEmptySwitch(),
      ];

      // Turn all 4 switches OFF
      for (final f in finders) {
        if (tester.widget<SwitchListTile>(f).value == true) {
          await tester.tap(f);
          await tester.pumpAndSettle();
        }
      }

      expect(dex.customBoxes.length, 25);
      expect(dex.customBoxes.every((b) =>
          !b.autoShift && !b.strictLimits && !b.patternAutoCreate && !b.autoDeleteEmpty), isTrue,
          reason: 'All 25 boxes must have all 4 flags set to false');

      // Turn all 4 switches back ON
      for (final f in finders) {
        if (tester.widget<SwitchListTile>(f).value == false) {
          await tester.tap(f);
          await tester.pumpAndSettle();
        }
      }

      expect(dex.customBoxes.every((b) =>
          b.autoShift && b.strictLimits && b.patternAutoCreate && b.autoDeleteEmpty), isTrue,
          reason: 'All 25 boxes must synchronize back to true');

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // SUITE 2: Rapid Toggle Alternation Invariance & Flapping Stability
  // =========================================================================
  group('Challenger M5-1 Suite 2: Rapid Toggle Alternation Invariance', () {
    testWidgets('2.1: 10 consecutive alternating flips on single toggle deterministically preserves final parity', (tester) async {
      final box = createTestCustomBox(title: 'Flap Box A', pokemonIds: ['1'], autoShift: true);
      final dex = createTestUserDex(id: 'dex_flap_a', title: 'Flap Dex A', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      final switchFinder = getAutoShiftSwitch();
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      // Perform 10 consecutive flips (even number -> true)
      for (int i = 0; i < 10; i++) {
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
        final expected = (i % 2 == 0) ? false : true;
        expect(tester.widget<SwitchListTile>(switchFinder).value, equals(expected));
        expect(dex.customBoxes.first.autoShift, equals(expected));
      }

      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
      expect(dex.customBoxes.first.autoShift, isTrue);

      // 11th flip (odd total) -> must flip to false
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
      expect(dex.customBoxes.first.autoShift, isFalse);

      expect(tester.takeException(), isNull);
    });

    testWidgets('2.2: Interleaved multi-switch flapping across all 4 toggles maintains strict state isolation', (tester) async {
      final box = createTestCustomBox(
        title: 'Multi Flap Box',
        pokemonIds: ['10', '20'],
        autoShift: true,
        strictLimits: true,
        patternAutoCreate: true,
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(id: 'dex_multi_flap', title: 'Multi Flap Dex', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      final finders = [
        getAutoShiftSwitch(),
        getStrictLimitsSwitch(),
        getPatternAutoCreateSwitch(),
        getAutoDeleteEmptySwitch(),
      ];

      // 5 complete cycles across all 4 toggles (each toggled 5 times = odd total -> false)
      for (int cycle = 0; cycle < 5; cycle++) {
        for (final f in finders) {
          await tester.tap(f);
          await tester.pumpAndSettle();
        }
      }

      for (int i = 0; i < finders.length; i++) {
        final val = tester.widget<SwitchListTile>(finders[i]).value;
        expect(val, isFalse, reason: 'Switch $i after 5 cycles must be false');
      }
      expect(dex.customBoxes.first.autoShift, isFalse);
      expect(dex.customBoxes.first.strictLimits, isFalse);
      expect(dex.customBoxes.first.patternAutoCreate, isFalse);
      expect(dex.customBoxes.first.autoDeleteEmpty, isFalse);

      // 1 more cycle across all 4 toggles (each toggled 6 times total = even total -> true)
      for (final f in finders) {
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      for (int i = 0; i < finders.length; i++) {
        final val = tester.widget<SwitchListTile>(finders[i]).value;
        expect(val, isTrue, reason: 'Switch $i after 6 cycles must be true');
      }
      expect(dex.customBoxes.first.autoShift, isTrue);
      expect(dex.customBoxes.first.strictLimits, isTrue);
      expect(dex.customBoxes.first.patternAutoCreate, isTrue);
      expect(dex.customBoxes.first.autoDeleteEmpty, isTrue);

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // SUITE 3: New Box Inheritance & Dynamic State Invariance
  // =========================================================================
  group('Challenger M5-1 Suite 3: Box Inheritance & Sequential Addition', () {
    testWidgets('3.1: Sequential box creation with interleaved settings inversions retains global coherence', (tester) async {
      final dex = createTestUserDex(id: 'dex_dyn_inherit', title: 'Dynamic Inherit Dex', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      // 1. Add Box 1 (inherits initial defaults: all true)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'First Box');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Translator.get('create')));
      await tester.pumpAndSettle();

      expect(dex.customBoxes.length, 1);
      expect(dex.customBoxes[0].autoShift, isTrue);
      expect(dex.customBoxes[0].strictLimits, isTrue);

      // 2. Flip autoShift to false
      await tester.tap(getAutoShiftSwitch());
      await tester.pumpAndSettle();
      expect(dex.customBoxes[0].autoShift, isFalse);

      // 3. Add Box 2 (inherits autoShift == false, strictLimits == true)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Second Box');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Translator.get('create')));
      await tester.pumpAndSettle();

      expect(dex.customBoxes.length, 2);
      expect(dex.customBoxes[1].autoShift, isFalse);
      expect(dex.customBoxes[1].strictLimits, isTrue);

      // 4. Flip strictLimits to false
      await tester.tap(getStrictLimitsSwitch());
      await tester.pumpAndSettle();
      expect(dex.customBoxes[0].strictLimits, isFalse);
      expect(dex.customBoxes[1].strictLimits, isFalse);

      // 5. Add Box 3 (inherits autoShift == false, strictLimits == false)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Third Box');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Translator.get('create')));
      await tester.pumpAndSettle();

      expect(dex.customBoxes.length, 3);
      expect(dex.customBoxes[2].autoShift, isFalse);
      expect(dex.customBoxes[2].strictLimits, isFalse);

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // SUITE 4: Model Invariants & 16-Permutation Serialization Integrity
  // =========================================================================
  group('Challenger M5-1 Suite 4: Model Invariants & 16-Permutation Serialization', () {
    test('4.1: CustomBoxState toMap / fromMap round-trip preserves all 16 boolean flag permutations', () {
      final booleans = [false, true];
      int permutationCount = 0;

      for (final shift in booleans) {
        for (final strict in booleans) {
          for (final pattern in booleans) {
            for (final delEmpty in booleans) {
              permutationCount++;
              final original = CustomBoxState(
                title: 'Permutation $permutationCount',
                pokemonIds: ['P1', 'P2'],
                columns: 6,
                rows: 5,
                autoFlow: false,
                autoShift: shift,
                strictLimits: strict,
                patternAutoCreate: pattern,
                autoDeleteEmpty: delEmpty,
              );

              final map = original.toMap();
              final restored = CustomBoxState.fromMap(map);

              expect(restored.title, equals(original.title));
              expect(restored.capacity, equals(30));
              expect(restored.autoShift, equals(shift), reason: 'Perm $permutationCount autoShift');
              expect(restored.strictLimits, equals(strict), reason: 'Perm $permutationCount strictLimits');
              expect(restored.patternAutoCreate, equals(pattern), reason: 'Perm $permutationCount patternAutoCreate');
              expect(restored.autoDeleteEmpty, equals(delEmpty), reason: 'Perm $permutationCount autoDeleteEmpty');
            }
          }
        }
      }

      expect(permutationCount, equals(16));
    });

    test('4.2: UserDex toMap / fromMap serialization encodes customBoxes JSON with full fidelity', () {
      final boxes = [
        CustomBoxState(
          title: 'Box Alpha',
          pokemonIds: ['1', '2'],
          autoShift: false,
          strictLimits: true,
          patternAutoCreate: false,
          autoDeleteEmpty: true,
        ),
        CustomBoxState(
          title: 'Box Beta',
          pokemonIds: ['3', '4', '5'],
          autoShift: true,
          strictLimits: false,
          patternAutoCreate: true,
          autoDeleteEmpty: false,
        ),
      ];

      final dex = UserDex(
        id: 'ser_dex_test',
        title: 'Serialization Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: boxes,
      );

      final map = dex.toMap();
      expect(map['custom_boxes'], isNotNull);

      final rawJson = map['custom_boxes'] as String;
      final List decodedList = jsonDecode(rawJson);
      expect(decodedList.length, equals(2));

      expect(decodedList[0]['title'], equals('Box Alpha'));
      expect(decodedList[0]['autoShift'], isFalse);
      expect(decodedList[0]['strictLimits'], isTrue);
      expect(decodedList[0]['patternAutoCreate'], isFalse);
      expect(decodedList[0]['autoDeleteEmpty'], isTrue);

      expect(decodedList[1]['title'], equals('Box Beta'));
      expect(decodedList[1]['autoShift'], isTrue);
      expect(decodedList[1]['strictLimits'], isFalse);
      expect(decodedList[1]['patternAutoCreate'], isTrue);
      expect(decodedList[1]['autoDeleteEmpty'], isFalse);

      final restoredDex = UserDex.fromMap(map);
      expect(restoredDex.customBoxes.length, equals(2));
      expect(restoredDex.customBoxes[0].autoShift, isFalse);
      expect(restoredDex.customBoxes[0].strictLimits, isTrue);
      expect(restoredDex.customBoxes[1].autoShift, isTrue);
      expect(restoredDex.customBoxes[1].strictLimits, isFalse);
    });

    test('4.3: In-memory SQLite table insertion and retrieval preserves exact JSON settings', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE user_dexes (
              id TEXT PRIMARY KEY,
              title TEXT,
              region TEXT,
              include_genders INTEGER,
              include_regional INTEGER,
              include_mega INTEGER,
              include_gmax INTEGER,
              include_other INTEGER,
              include_trades INTEGER,
              include_gifts INTEGER,
              include_glitch INTEGER,
              is_shiny_dex INTEGER,
              view_mode TEXT,
              sort_mode TEXT,
              mega_sort TEXT,
              gmax_sort TEXT,
              regional_sort TEXT,
              custom_boxes TEXT,
              updated_at INTEGER,
              deleted_at INTEGER
            )
          ''');
        },
      );

      final box = CustomBoxState(
        title: 'SQLite Mem Box',
        pokemonIds: ['25'],
        autoShift: false,
        strictLimits: false,
        patternAutoCreate: true,
        autoDeleteEmpty: false,
      );

      final dex = UserDex(
        id: 'mem_dex_1',
        title: 'In-Memory Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [box],
      );

      final dexMap = dex.toMap();
      dexMap.remove('caught_ids');
      dexMap.remove('shiny_ids');
      dexMap.remove('alpha_ids');
      dexMap.remove('ignored_ids');
      dexMap.remove('caught_ribbons');
      dexMap.remove('caught_tera_types');
      dexMap.remove('caught_languages');
      dexMap['updated_at'] = DateTime.now().toUtc().millisecondsSinceEpoch;
      dexMap['deleted_at'] = 0;

      await db.insert('user_dexes', dexMap);

      final rows = await db.query('user_dexes', where: 'id = ?', whereArgs: ['mem_dex_1']);
      expect(rows.length, equals(1));

      final retrievedDex = UserDex.fromMap(rows.first);
      expect(retrievedDex.customBoxes.length, equals(1));
      expect(retrievedDex.customBoxes.first.title, equals('SQLite Mem Box'));
      expect(retrievedDex.customBoxes.first.autoShift, isFalse);
      expect(retrievedDex.customBoxes.first.strictLimits, isFalse);
      expect(retrievedDex.customBoxes.first.patternAutoCreate, isTrue);
      expect(retrievedDex.customBoxes.first.autoDeleteEmpty, isFalse);

      await db.close();
    });
  });
}
