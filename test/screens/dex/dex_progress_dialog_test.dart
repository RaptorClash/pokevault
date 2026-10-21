import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/widgets/dex_progress_dialog.dart';
import 'package:pokevault/l10n/app_translations.dart';

Pokemon _createTestPokemon({
  required int id,
  String nameDe = 'TestMon',
  String nameEn = 'TestMon',
  List<String> types = const ['normal'],
  String formType = 'normal',
  String formName = 'normal',
}) {
  return Pokemon(
    id: id,
    nameDe: nameDe,
    nameEn: nameEn,
    hasGenderDifferences: false,
    genderRate: 4,
    captureRate: 255,
    evolutionChainId: 1,
    eggGroups: ['monster'],
    weight: 10.0,
    speed: 50,
    forms: [
      PokemonForm(
        name: formName,
        formType: formType,
        minGen: 1,
        imageId: id,
        types: types,
        exclusiveRegions: [],
      ),
    ],
  );
}

DexDisplayEntry _createEntry({
  required Pokemon pokemon,
  required String uniqueId,
  PokemonForm? form,
}) {
  return DexDisplayEntry(
    pokemon: pokemon,
    uniqueId: uniqueId,
    displaySuffix: '',
    imageUrl: 'https://example.com/$uniqueId.png',
    form: form ?? (pokemon.forms.isNotEmpty ? pokemon.forms.first : null),
  );
}

void main() {
  setUp(() {
    Translator.currentLanguage = 'de';
  });

  group('DexProgressDialog Widget Tests', () {
    testWidgets('renders dialog correctly with progress, counts, and tabs', (tester) async {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Kanto Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal'],
        shinyIds: ['1_normal'],
        alphaIds: ['1_normal'],
      );

      final p1 = _createTestPokemon(id: 1, nameDe: 'Bisasam', types: ['grass', 'poison']);
      final p2 = _createTestPokemon(id: 4, nameDe: 'Glumanda', types: ['fire']);
      final entries = [
        _createEntry(pokemon: p1, uniqueId: '1_normal'),
        _createEntry(pokemon: p2, uniqueId: '4_normal'),
      ];

      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DexProgressDialog.show(
                    context,
                    liveDex: dex,
                    entries: entries,
                    onFilterSelected: (filter) {
                      selectedFilter = filter;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify title & dex name
      expect(find.textContaining('Kanto Living Dex'), findsOneWidget);
      expect(find.textContaining('50.0%'), findsWidgets);
      expect(find.textContaining('1 / 2'), findsWidgets);
      expect(find.textContaining('1 Shinies'), findsOneWidget);
      expect(find.textContaining('1 Alphas'), findsOneWidget);

      // Verify Tabs exist
      expect(find.textContaining('Generationen'), findsOneWidget);
      expect(find.textContaining('Typen'), findsOneWidget);
      expect(find.textContaining('Varianten'), findsOneWidget);

      // Tab 1: Generationen is active by default
      expect(find.textContaining('Gen 1: Kanto'), findsOneWidget);

      // Switch to Tab 2: Typen
      await tester.tap(find.textContaining('Typen'));
      await tester.pumpAndSettle();
      expect(find.text('Pflanze'), findsOneWidget);
      expect(find.text('Gift'), findsOneWidget);
      expect(find.text('Feuer'), findsOneWidget);

      // Switch to Tab 3: Varianten
      await tester.tap(find.textContaining('Varianten'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Reguläre Formen'), findsOneWidget);

      // Test 1-click filter button: Nur Fehlende anzeigen
      final showMissingBtn = find.textContaining('Nur Fehlende anzeigen');
      expect(showMissingBtn, findsOneWidget);
      await tester.tap(showMissingBtn);
      await tester.pumpAndSettle();

      // Dialog should be popped and filter should be 'uncaught'
      expect(selectedFilter, 'uncaught');
      expect(find.textContaining('Kanto Living Dex • Gesamt-Übersicht'), findsNothing);
    });

    testWidgets('filter button "Nur Gefangene anzeigen" selects "caught" filter', (tester) async {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Kanto Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DexProgressDialog.show(
                    context,
                    liveDex: dex,
                    entries: [],
                    onFilterSelected: (filter) => selectedFilter = filter,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final showCaughtBtn = find.textContaining('Nur Gefangene');
      expect(showCaughtBtn, findsOneWidget);
      await tester.tap(showCaughtBtn);
      await tester.pumpAndSettle();

      expect(selectedFilter, 'caught');
    });

    testWidgets('filter button "Alle anzeigen" selects "all" filter', (tester) async {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Kanto Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DexProgressDialog.show(
                    context,
                    liveDex: dex,
                    entries: [],
                    onFilterSelected: (filter) => selectedFilter = filter,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final showAllBtn = find.text(Translator.get('dex_progress_show_all'));
      expect(showAllBtn, findsOneWidget);
      await tester.tap(showAllBtn);
      await tester.pumpAndSettle();

      expect(selectedFilter, 'all');
    });

    testWidgets('landscape / short screen (640x320) renders without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(640.0, 320.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dex = UserDex(
        id: 'test_dex',
        title: 'Kanto Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal'],
      );

      final p1 = _createTestPokemon(id: 1, nameDe: 'Bisasam', types: ['grass', 'poison']);
      final entries = [_createEntry(pokemon: p1, uniqueId: '1_normal')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DexProgressDialog.show(
                    context,
                    liveDex: dex,
                    entries: entries,
                    onFilterSelected: (_) {},
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape mobile bottom sheet (360x320) renders without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360.0, 320.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dex = UserDex(
        id: 'test_dex',
        title: 'Kanto Living Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1_normal'],
      );

      final p1 = _createTestPokemon(id: 1, nameDe: 'Bisasam', types: ['grass', 'poison']);
      final entries = [_createEntry(pokemon: p1, uniqueId: '1_normal')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DexProgressDialog.show(
                    context,
                    liveDex: dex,
                    entries: entries,
                    onFilterSelected: (_) {},
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
