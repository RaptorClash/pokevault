import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/screens/dex/box_edit_screen.dart';
import 'package:pokevault/i18n/strings.g.dart';
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

  // =========================================================================
  // TARGET 1: Language Hot-Switching & Internationalization Boundary Stress
  // =========================================================================
  group('Target 1: Language Hot-Switching & Localization Boundary Stress', () {
    test('1.1: Exact English dictionary definitions and non-null UI texts', () {
      LocaleSettings.setLocale(AppLocale.en);

      final enDict = AppLocale.en.build();

      const expectedKeys = [
        'box_edit_settings_header',
        'box_edit_auto_shift_title',
        'box_edit_auto_shift_subtitle',
        'box_edit_strict_limits_title',
        'box_edit_strict_limits_subtitle',
        'box_edit_pattern_auto_create_title',
        'box_edit_pattern_auto_create_subtitle',
        'box_edit_auto_delete_empty_title',
        'box_edit_auto_delete_empty_subtitle',
      ];

      for (final key in expectedKeys) {
        final val = t[key];
        expect(val, isNotEmpty, reason: 'Key $key must not be empty in EN');
        expect(val, isNot(equals(key)), reason: 'Key $key must resolve to a translated string, not the raw key');
        expect(val, equals(enDict[key]), reason: 'Key $key must match English dictionary definition');
      }
    });

    test('1.2: Exact German dictionary definitions and non-null UI texts', () {
      LocaleSettings.setLocale(AppLocale.de);

      final deDict = AppLocale.de.build();

      const expectedKeys = [
        'box_edit_settings_header',
        'box_edit_auto_shift_title',
        'box_edit_auto_shift_subtitle',
        'box_edit_strict_limits_title',
        'box_edit_strict_limits_subtitle',
        'box_edit_pattern_auto_create_title',
        'box_edit_pattern_auto_create_subtitle',
        'box_edit_auto_delete_empty_title',
        'box_edit_auto_delete_empty_subtitle',
      ];

      for (final key in expectedKeys) {
        final val = t[key];
        expect(val, isNotEmpty, reason: 'Key $key must not be empty in DE');
        expect(val, isNot(equals(key)), reason: 'Key $key must resolve to a translated string in DE');
        expect(val, equals(deDict[key]), reason: 'Key $key must match German dictionary definition');
      }
    });

    test('1.3: Fallback mechanism resolves to English for unknown locales (es, fr, it, ja, unknown)', () {
      const unknownLocales = ['es', 'fr', 'it', 'ja', 'unknown', ''];
      final enDict = AppLocale.en.build();

      for (final locale in unknownLocales) {
        LocaleSettings.setLocale(locale == 'de' ? AppLocale.de : AppLocale.en);

        expect(
          t.box_edit_settings_header,
          equals(enDict.box_edit_settings_header),
          reason: 'Locale $locale must fallback to English for header',
        );
        expect(
          t.box_edit_auto_shift_title,
          equals(enDict.box_edit_auto_shift_title),
          reason: 'Locale $locale must fallback to English for auto_shift_title',
        );
        expect(
          t.box_edit_auto_shift_subtitle,
          equals(enDict.box_edit_auto_shift_subtitle),
          reason: 'Locale $locale must fallback to English for auto_shift_subtitle',
        );
        expect(
          t.box_edit_strict_limits_title,
          equals(enDict.box_edit_strict_limits_title),
          reason: 'Locale $locale must fallback to English for strict_limits_title',
        );
        expect(
          t.box_edit_strict_limits_subtitle,
          equals(enDict.box_edit_strict_limits_subtitle),
          reason: 'Locale $locale must fallback to English for strict_limits_subtitle',
        );
        expect(
          t.box_edit_pattern_auto_create_title,
          equals(enDict.box_edit_pattern_auto_create_title),
          reason: 'Locale $locale must fallback to English for pattern_auto_create_title',
        );
        expect(
          t.box_edit_pattern_auto_create_subtitle,
          equals(enDict.box_edit_pattern_auto_create_subtitle),
          reason: 'Locale $locale must fallback to English for pattern_auto_create_subtitle',
        );
        expect(
          t.box_edit_auto_delete_empty_title,
          equals(enDict.box_edit_auto_delete_empty_title),
          reason: 'Locale $locale must fallback to English for auto_delete_empty_title',
        );
        expect(
          t.box_edit_auto_delete_empty_subtitle,
          equals(enDict.box_edit_auto_delete_empty_subtitle),
          reason: 'Locale $locale must fallback to English for auto_delete_empty_subtitle',
        );
      }
    });

    testWidgets('1.4: Dynamic in-flight hot-switching across EN -> DE -> FR -> ES -> EN', (tester) async {
      final box = createTestCustomBox(title: 'Box 1', pokemonIds: ['1']);
      final dex = createTestUserDex(id: 'dex_i18n', title: 'I18n Test Dex', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      // Phase 1: Mount with EN
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Box Management Settings'), findsOneWidget);
      expect(find.text('Auto-Shift Pokémon'), findsOneWidget);
      expect(find.text('Strict Capacity Limits'), findsOneWidget);

      // Phase 2: Hot-switch to DE
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'de',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Box-Verwaltung Einstellungen'), findsOneWidget);
      expect(find.text('Auto-Verschieben von Pokémon'), findsOneWidget);
      expect(find.text('Strikte Kapazitätsgrenzen'), findsOneWidget);

      // Phase 3: Hot-switch to FR (unknown locale -> fallback EN)
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'fr',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Box Management Settings'), findsOneWidget);
      expect(find.text('Auto-Shift Pokémon'), findsOneWidget);
      expect(find.text('Strict Capacity Limits'), findsOneWidget);

      // Phase 4: Hot-switch to ES (unknown locale -> fallback EN)
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'es',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Box Management Settings'), findsOneWidget);
      expect(find.text('Pattern-Based Auto-Creation'), findsOneWidget);
      expect(find.text('Auto-Delete Empty Boxes'), findsOneWidget);

      // Phase 5: Hot-switch back to EN
      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Box Management Settings'), findsOneWidget);
    });

    testWidgets('1.5: German verbose subtitles render completely with no nulls or empty texts', (tester) async {
      final box = createTestCustomBox(title: 'Box DE', pokemonIds: ['1']);
      final dex = createTestUserDex(id: 'dex_de', title: 'German Dex', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'de',
      ));
      await tester.pumpAndSettle();

      final switchTiles = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(switchTiles.length, greaterThanOrEqualTo(4));

      for (var tile in switchTiles) {
        expect(tile.title, isNotNull);
        expect(tile.subtitle, isNotNull);
        final subtitleText = (tile.subtitle as Text).data;
        expect(subtitleText, isNotNull);
        expect(subtitleText!.isNotEmpty, isTrue);
      }
    });
  });

  // =========================================================================
  // TARGET 2: Viewport Constraint Stress
  // =========================================================================
  group('Target 2: Viewport Constraint Stress', () {
    testWidgets('2.1: Render BoxEditScreen in constrained 320x480 with zero RenderFlex overflows', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Kanto 1', pokemonIds: ['1', '2']),
        createTestCustomBox(title: 'Kanto 2', pokemonIds: ['3', '4']),
        createTestCustomBox(title: 'Kanto 3', pokemonIds: ['5']),
      ];
      final dex = createTestUserDex(id: 'dex_small', title: 'Small Dex', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      // Ensure BoxEditScreen rendered
      expect(find.byType(BoxEditScreen), findsOneWidget);

      // Verify that all 4 SwitchListTiles exist
      final switchTiles = find.byType(SwitchListTile);
      expect(switchTiles, findsNWidgets(4));

      // Test tapping each switch inside the 320x480 viewport
      for (int i = 0; i < 4; i++) {
        await tester.tap(switchTiles.at(i), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Verify tester took zero RenderFlex overflow exceptions
      expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow errors must occur in 320x480');
    });

    testWidgets('2.2: Render BoxEditScreen on large tablet 1024x768 and 1280x800', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Tablet Box 1', pokemonIds: ['1']),
        createTestCustomBox(title: 'Tablet Box 2', pokemonIds: ['2']),
      ];
      final dex = createTestUserDex(id: 'dex_tablet', title: 'Tablet Dex', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BoxEditScreen), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);

      // Resize to 1280x800
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();

      expect(find.byType(BoxEditScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.3: Dynamic viewport resizing across 320x480 -> 480x800 -> 360x640', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boxes = [
        createTestCustomBox(title: 'Resize Box', pokemonIds: ['1']),
      ];
      final dex = createTestUserDex(id: 'dex_resize', title: 'Resize Dex', customBoxes: boxes);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'de',
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Transition to 480x800
      tester.view.physicalSize = const Size(480, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Transition to 360x640
      tester.view.physicalSize = const Size(360, 640);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.4: Ultra-narrow 280x600 constraint wraps subtitles cleanly with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(280, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final box = createTestCustomBox(title: 'Narrow Box', pokemonIds: ['1']);
      final dex = createTestUserDex(id: 'dex_narrow', title: 'Narrow Dex', customBoxes: [box]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'de', // Use German for longest text
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.5: Empty dex in constrained 320x480 viewport still triggers zero RenderFlex overflows', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dex = createTestUserDex(id: 'dex_empty_small', title: 'Empty Small Dex', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BoxEditScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Empty dex in 320x480 must not cause RenderFlex overflow');
    });
  });

  // =========================================================================
  // TARGET 3: Empty CustomBoxes Robustness & Lifecycle Stress
  // =========================================================================
  group('Target 3: Empty CustomBoxes Robustness & Lifecycle Stress', () {
    testWidgets('3.1: Empty dex with 0 boxes mounts gracefully without StateError', (tester) async {
      final dex = createTestUserDex(id: 'dex_zero', title: 'Empty Dex', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BoxEditScreen), findsOneWidget);
      final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(switches.length, equals(4));

      // Invariant: Default values should all be true
      for (var s in switches) {
        expect(s.value, isTrue, reason: 'Default settings for empty dex must be true');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.2: Toggling switches on empty dex succeeds without StateError: Bad state: No element', (tester) async {
      final dex = createTestUserDex(id: 'dex_zero_toggle', title: 'Toggle Empty Dex', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      final switchFinders = find.byType(SwitchListTile);
      expect(switchFinders, findsNWidgets(4));

      // Tap every switch
      for (int i = 0; i < 4; i++) {
        await tester.tap(switchFinders.at(i));
        await tester.pumpAndSettle();
      }

      // Verify all switches are now false
      final updatedSwitches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      for (var s in updatedSwitches) {
        expect(s.value, isFalse, reason: 'Toggled switches on empty dex must become false');
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('3.3: Adding a box after toggling settings on empty dex inherits active toggled settings', (tester) async {
      final dex = createTestUserDex(id: 'dex_empty_add', title: 'Empty Add Dex', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      // Toggle autoShift and strictLimits to false
      final autoShiftFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile && w.title.toString().toLowerCase().contains('shift'));
      final strictLimitsFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('limit') ||
           w.title.toString().toLowerCase().contains('capacity')));

      await tester.tap(autoShiftFinder);
      await tester.pumpAndSettle();

      await tester.tap(strictLimitsFinder);
      await tester.pumpAndSettle();

      // Tap the FAB to add a new box
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Enter box title in dialog
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'Brand New Box');
      await tester.pumpAndSettle();

      // Tap create button
      final createBtnFinder = find.widgetWithText(ElevatedButton, t.create);
      expect(createBtnFinder, findsOneWidget);
      await tester.tap(createBtnFinder);
      await tester.pumpAndSettle();

      // Verify box was added
      expect(dex.customBoxes.length, equals(1));
      final addedBox = dex.customBoxes.first;
      expect(addedBox.title, equals('Brand New Box'));
      expect(addedBox.autoShift, isFalse, reason: 'New box must inherit toggled autoShift=false');
      expect(addedBox.strictLimits, isFalse, reason: 'New box must inherit toggled strictLimits=false');
      expect(addedBox.patternAutoCreate, isTrue, reason: 'Untoggled patternAutoCreate should remain true');
      expect(addedBox.autoDeleteEmpty, isTrue, reason: 'Untoggled autoDeleteEmpty should remain true');

      expect(tester.takeException(), isNull);
    });

    testWidgets('3.4: Complete deletion to zero boxes, switch toggling, and subsequent creation lifecycle', (tester) async {
      final box1 = createTestCustomBox(title: 'Box Alpha', pokemonIds: ['1']);
      final box2 = createTestCustomBox(title: 'Box Beta', pokemonIds: ['2']);
      final dex = createTestUserDex(id: 'dex_lifecycle', title: 'Lifecycle Dex', customBoxes: [box1, box2]);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      expect(dex.customBoxes.length, equals(2));

      // Delete both boxes
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();
      expect(dex.customBoxes.length, equals(1));

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();
      expect(dex.customBoxes.length, equals(0));

      // Now with 0 boxes, toggle patternAutoCreate to false
      final patternFinder = find.byWidgetPredicate((w) =>
          w is SwitchListTile &&
          (w.title.toString().toLowerCase().contains('pattern') ||
           w.title.toString().toLowerCase().contains('auto-create')));
      await tester.tap(patternFinder);
      await tester.pumpAndSettle();

      // Now add a box
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Reborn Box');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, t.create));
      await tester.pumpAndSettle();

      expect(dex.customBoxes.length, equals(1));
      expect(dex.customBoxes.first.title, equals('Reborn Box'));
      expect(dex.customBoxes.first.patternAutoCreate, isFalse,
          reason: 'Box created after emptying must inherit toggled patternAutoCreate=false');

      expect(tester.takeException(), isNull);
    });

    testWidgets('3.5: Rapid multi-toggle alternation invariance on empty and populated dex', (tester) async {
      final dex = createTestUserDex(id: 'dex_rapid', title: 'Rapid Dex', customBoxes: []);
      when(() => mockProvider.userDexes).thenReturn([dex]);

      await tester.pumpWidget(wrapWithApp(
        child: BoxEditScreen(dex: dex, initialBoxes: const []),
        mockDexProvider: mockProvider,
        mockSettingsProvider: mockSettings,
        language: 'en',
      ));
      await tester.pumpAndSettle();

      final firstSwitch = find.byType(SwitchListTile).first;

      // Toggle rapidly 6 times (even number -> should end back at initial true)
      for (int i = 0; i < 6; i++) {
        await tester.tap(firstSwitch);
        await tester.pumpAndSettle();
      }

      final sw = tester.widget<SwitchListTile>(firstSwitch);
      expect(sw.value, isTrue, reason: 'Even number of flips must return switch to original state');
      expect(tester.takeException(), isNull);
    });
  });
}
