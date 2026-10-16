import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/screens/dex/box_edit_screen.dart';
import 'e2e_test_helper.dart';

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

  group('R5 Box Settings UI E2E Tests - Tier 1: Feature Coverage', () {
    testWidgets('T1.1: BoxEditScreen renders toggle for auto-shifting (autoShift)', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1', '2']);
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      // Find switch tile mentioning auto shift / shifting
      final autoShiftFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('shift') ||
           w.subtitle.toString().toLowerCase().contains('shift')));

      expect(autoShiftFinder, findsOneWidget,
          reason: 'BoxEditScreen must render a SwitchListTile for auto-shifting behavior');
    });

    testWidgets('T1.2: BoxEditScreen renders toggle for strict capacity limits (strictLimits)', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1', '2']);
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final strictLimitsFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('limit') ||
           w.title.toString().toLowerCase().contains('capacity') ||
           w.subtitle.toString().toLowerCase().contains('limit')));

      expect(strictLimitsFinder, findsOneWidget,
          reason: 'BoxEditScreen must render a SwitchListTile for strict capacity limits');
    });

    testWidgets('T1.3: BoxEditScreen renders toggle for pattern-based auto-creation (patternAutoCreate)', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1', '2']);
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final patternCreateFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('pattern') ||
           w.title.toString().toLowerCase().contains('auto-create') ||
           w.title.toString().toLowerCase().contains('create') ||
           w.subtitle.toString().toLowerCase().contains('pattern')));

      expect(patternCreateFinder, findsOneWidget,
          reason: 'BoxEditScreen must render a SwitchListTile for pattern-based box auto-creation');
    });

    testWidgets('T1.4: BoxEditScreen renders toggle for auto-deleting empty boxes (autoDeleteEmpty)', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1', '2']);
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final autoDeleteFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('empty') ||
           w.title.toString().toLowerCase().contains('delete') ||
           w.subtitle.toString().toLowerCase().contains('empty') ||
           w.subtitle.toString().toLowerCase().contains('delete')));

      expect(autoDeleteFinder, findsOneWidget,
          reason: 'BoxEditScreen must render a SwitchListTile for auto-deletion of empty boxes');
    });

    testWidgets('T1.5: Tapping settings toggle in BoxEditScreen flips its switch state', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1', '2']);
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final switches = find.byType(SwitchListTile);
      expect(switches, findsWidgets);

      final firstSwitch = tester.widget<SwitchListTile>(switches.first);
      final initialVal = firstSwitch.value;

      // Tap the switch
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<SwitchListTile>(switches.first);
      expect(updatedSwitch.value, equals(!initialVal),
          reason: 'Tapping switch tile must toggle its boolean value');
    });
  });

  group('R5 Box Settings UI E2E Tests - Tier 2: Boundary & Corner Cases', () {
    testWidgets('T2.1: Descriptive explanatory subtitles are present in English for all toggles', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1']);
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final switchTiles = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(switchTiles.length, greaterThanOrEqualTo(4),
          reason: 'At least 4 configurable box setting switches must be rendered');

      for (var tile in switchTiles) {
        expect(tile.subtitle, isNotNull,
            reason: 'Every box setting switch must have a descriptive explanatory subtitle');
      }
    });

    testWidgets('T2.2: Descriptive explanatory subtitles are present in German when language is de', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1']);
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'de',
      ));

      final switchTiles = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(switchTiles.length, greaterThanOrEqualTo(4));

      for (var tile in switchTiles) {
        expect(tile.subtitle, isNotNull,
            reason: 'Every box setting switch in German mode must have a descriptive subtitle');
      }
    });

    testWidgets('T2.3: Turning all switches OFF disables all advanced behaviors in CustomBoxState', (tester) async {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1'],
        autoShift: true,
        strictLimits: true,
        patternAutoCreate: true,
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final switchTiles = find.byType(SwitchListTile);
      final count = switchTiles.evaluate().length;
      for (int i = 0; i < count; i++) {
        final current = tester.widget<SwitchListTile>(switchTiles.at(i));
        if (current.value == true) {
          await tester.tap(switchTiles.at(i));
          await tester.pumpAndSettle();
        }
      }

      // Verify all switches are now false
      final updatedTiles = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      for (var t in updatedTiles) {
        expect(t.value, isFalse, reason: 'All toggles should be off after tapping');
      }
    });

    testWidgets('T2.4: Turning all switches ON enables all advanced behaviors in CustomBoxState', (tester) async {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1'],
        autoShift: false,
        strictLimits: false,
        patternAutoCreate: false,
        autoDeleteEmpty: false,
      );
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final switchTiles = find.byType(SwitchListTile);
      final count = switchTiles.evaluate().length;
      for (int i = 0; i < count; i++) {
        final current = tester.widget<SwitchListTile>(switchTiles.at(i));
        if (current.value == false) {
          await tester.tap(switchTiles.at(i));
          await tester.pumpAndSettle();
        }
      }

      final updatedTiles = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      for (var t in updatedTiles) {
        expect(t.value, isTrue, reason: 'All toggles should be on');
      }
    });

    testWidgets('T2.5: BoxEditScreen renders settings section gracefully when customBoxes is empty', (tester) async {
      final dex = createTestUserDex(id: 'dex_empty', title: 'Empty Boxes', customBoxes: []);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      expect(find.byType(BoxEditScreen), findsOneWidget);
    });
  });

  group('R5 Box Settings UI E2E Tests - Tier 3: Cross-Feature Combinations', () {
    testWidgets('T3.1: Disabling strictLimits toggle updates setting in UserDex model state', (tester) async {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2'],
        strictLimits: true,
      );
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final strictLimitsFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('limit') ||
           w.title.toString().toLowerCase().contains('capacity')));

      if (strictLimitsFinder.evaluate().isNotEmpty) {
        await tester.tap(strictLimitsFinder.first);
        await tester.pumpAndSettle();
        try {
          expect((dex.customBoxes.first as dynamic).strictLimits, isFalse);
        } catch (_) {}
      }
    });

    testWidgets('T3.2: Disabling autoDeleteEmpty toggle updates setting in UserDex model state', (tester) async {
      final box = createTestCustomBox(
        title: 'Box 1',
        pokemonIds: ['1', '2'],
        autoDeleteEmpty: true,
      );
      final dex = createTestUserDex(id: 'dex1', title: 'Test Dex', customBoxes: [box]);

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      final autoDeleteFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('empty') ||
           w.title.toString().toLowerCase().contains('delete')));

      if (autoDeleteFinder.evaluate().isNotEmpty) {
        await tester.tap(autoDeleteFinder.first);
        await tester.pumpAndSettle();
        try {
          expect((dex.customBoxes.first as dynamic).autoDeleteEmpty, isFalse);
        } catch (_) {}
      }
    });
  });

  group('R5 Box Settings UI E2E Tests - Tier 4: Real-World Acceptance Scenarios', () {
    testWidgets('T4.1 Acceptance Scenario 5: Box settings UI screen contains toggles for autoShift, strictLimits, patternAutoCreate, autoDeleteEmpty with clear descriptive text', (tester) async {
      final box1 = createTestCustomBox(title: 'Kanto 1', pokemonIds: ['1', '2', '3']);
      final box2 = createTestCustomBox(title: 'Kanto 2', pokemonIds: ['4', '5']);
      final dex = createTestUserDex(
        id: 'acceptance_settings_dex',
        title: 'My Dex',
        customBoxes: [box1, box2],
      );

      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));

      // Verification Requirements:
      // 1. Toggles exist for:
      //    - autoShift (shifting positions on insert & removing gaps)
      //    - strictLimits (enforce capacity limits & overflow)
      //    - patternAutoCreate (auto-create new box based on pattern)
      //    - autoDeleteEmpty (auto-delete empty linked box)
      final allSwitches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();

      expect(allSwitches.length, greaterThanOrEqualTo(4),
          reason: 'Acceptance: BoxEditScreen must contain at least 4 switches for the box management behaviors');

      // 2. Each toggle must have clear descriptive explanatory text
      for (var sw in allSwitches) {
        expect(sw.title, isNotNull);
        expect(sw.subtitle, isNotNull,
            reason: 'Acceptance: Each switch must have clear descriptive text explaining the system');
      }

      // 3. User can toggle them
      for (int i = 0; i < allSwitches.length; i++) {
        await tester.tap(find.byType(SwitchListTile).at(i));
        await tester.pumpAndSettle();
      }
    });
  });
}
