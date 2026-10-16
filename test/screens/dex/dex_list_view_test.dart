import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/screens/dex/dex_list_view.dart';
import 'package:pokevault/screens/pokemon_info/pokemon_info_screen.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DexListView Widget Tests', () {
    late MockDexProvider mockDexProvider;
    late MockSettingsProvider mockSettingsProvider;

    setUp(() {
      mockDexProvider = MockDexProvider();
      mockSettingsProvider = MockSettingsProvider();

      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockDexProvider.togglePokemon(any(), any())).thenAnswer((_) async {});
      when(() => mockDexProvider.allPokemon).thenReturn([]);
      when(() => mockDexProvider.ballUrls).thenReturn({});
    });

    testWidgets('Renders empty placeholder message when displayList is empty', (tester) async {
      final dex = createTestUserDex(id: 'dex_empty');

      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: const [],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      expect(find.textContaining('Dieser Dex ist leer'), findsOneWidget);
    });

    testWidgets('Renders Pokemon cards with ID, name and image', (tester) async {
      final poke1 = createTestPokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur');
      final poke2 = createTestPokemon(id: 4, nameDe: 'Glumanda', nameEn: 'Charmander');

      final entry1 = createTestEntry(pokemon: poke1, uniqueId: '1');
      final entry2 = createTestEntry(pokemon: poke2, uniqueId: '4');

      final dex = createTestUserDex(
        id: 'dex_normal',
        caughtIds: ['1'], // Bisasam is caught, Glumanda is not
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: [entry1, entry2],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      // IDs
      expect(find.text('#001'), findsOneWidget);
      expect(find.text('#004'), findsOneWidget);

      // Names
      expect(find.text('Bisasam'), findsOneWidget);
      expect(find.text('Glumanda'), findsOneWidget);

      // Caught badge
      expect(find.byIcon(Icons.catching_pokemon), findsWidgets);
    });

    testWidgets('Shows shiny indicator when Pokemon is marked shiny in dex', (tester) async {
      final poke = createTestPokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu');
      final entry = createTestEntry(pokemon: poke, uniqueId: '25');

      final dex = createTestUserDex(
        id: 'dex_shiny',
        caughtIds: ['25'],
        shinyIds: ['25'],
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: [entry],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      // Shiny star icon
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Tapping a card invokes provider.togglePokemon', (tester) async {
      final poke = createTestPokemon(id: 7, nameDe: 'Schiggy', nameEn: 'Squirtle');
      final entry = createTestEntry(pokemon: poke, uniqueId: '7');

      final dex = createTestUserDex(id: 'dex_tap');

      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: [entry],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Schiggy'));
      await tester.pump();

      verify(() => mockDexProvider.togglePokemon(dex.id, '7')).called(1);
    });

    testWidgets('Long press on card navigates to PokemonInfoScreen', (tester) async {
      final poke = createTestPokemon(id: 1, nameDe: 'Bisasam');
      final entry = createTestEntry(pokemon: poke, uniqueId: '1');
      final dex = createTestUserDex(id: 'dex_nav');

      when(() => mockDexProvider.allPokemon).thenReturn([poke]);

      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: [entry],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Bisasam'));
      await tester.pumpAndSettle();

      expect(find.byType(PokemonInfoScreen), findsOneWidget);
    });

    testWidgets('Secondary tap (right click) on card navigates to PokemonInfoScreen', (tester) async {
      final poke = createTestPokemon(id: 1, nameDe: 'Bisasam');
      final entry = createTestEntry(pokemon: poke, uniqueId: '1');
      final dex = createTestUserDex(id: 'dex_sec_nav');

      when(() => mockDexProvider.allPokemon).thenReturn([poke]);

      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: [entry],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Bisasam'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      expect(find.byType(PokemonInfoScreen), findsOneWidget);
    });

    testWidgets('Adapts grid column count according to viewport width', (tester) async {
      final poke = createTestPokemon(id: 1, nameDe: 'Bisasam');
      final entry = createTestEntry(pokemon: poke, uniqueId: '1');
      final dex = createTestUserDex(id: 'dex_responsive');

      // Test mobile width (400px -> 3 columns)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: [entry],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);
      final GridView gridView = tester.widget(gridViewFinder);
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3));

      // Test large desktop width (1300px -> 8 columns)
      tester.view.physicalSize = const Size(1300, 900);
      await tester.pumpWidget(
        wrapWithApp(
          child: DexListView(
            displayList: [entry],
            liveDex: dex,
            provider: mockDexProvider,
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await tester.pump();

      final GridView desktopGridView = tester.widget(find.byType(GridView));
      final desktopDelegate = desktopGridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(desktopDelegate.crossAxisCount, equals(8));
    });
  });
}
