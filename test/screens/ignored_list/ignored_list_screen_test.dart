import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/screens/ignored_list/ignored_list_screen.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IgnoredListScreen Widget Tests', () {
    late MockDexProvider mockDexProvider;
    late MockSettingsProvider mockSettingsProvider;
    late MockTutorialProvider mockTutorialProvider;

    setUp(() {
      mockDexProvider = MockDexProvider();
      mockSettingsProvider = MockSettingsProvider();
      mockTutorialProvider = MockTutorialProvider();

      when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
      when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
      when(() => mockDexProvider.restorePokemon(any(), any())).thenAnswer((_) async {});
    });

    testWidgets('Shows empty state message when ignoredIds is empty', (tester) async {
      final dex = createTestUserDex(id: 'dex_ignored_empty', ignoredIds: []);
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final poke = createTestPokemon(id: 1, nameDe: 'Bisasam');
      final entry = createTestEntry(pokemon: poke, uniqueId: '1');

      await tester.pumpWidget(
        wrapWithApp(
          child: IgnoredListScreen(
            dexId: dex.id,
            allRawEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          mockTutorialProvider: mockTutorialProvider,
          language: 'de',
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(Translator.get('empty_ignored')), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('Renders ignored Pokemon with name, ID, and restore button', (tester) async {
      final dex = createTestUserDex(id: 'dex_with_ignored', ignoredIds: ['1']);
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final poke = createTestPokemon(id: 1, nameDe: 'Bisasam', nameEn: 'Bulbasaur');
      final entry = createTestEntry(pokemon: poke, uniqueId: '1');

      await tester.pumpWidget(
        wrapWithApp(
          child: IgnoredListScreen(
            dexId: dex.id,
            allRawEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          mockTutorialProvider: mockTutorialProvider,
          language: 'de',
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Bisasam'), findsOneWidget);
      expect(find.text('#001'), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
      expect(find.text(Translator.get('restore_pokemon')), findsOneWidget);
    });

    testWidgets('Tapping restore button invokes provider.restorePokemon', (tester) async {
      final dex = createTestUserDex(id: 'dex_restore', ignoredIds: ['4']);
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final poke = createTestPokemon(id: 4, nameDe: 'Glumanda', nameEn: 'Charmander');
      final entry = createTestEntry(pokemon: poke, uniqueId: '4');

      await tester.pumpWidget(
        wrapWithApp(
          child: IgnoredListScreen(
            dexId: dex.id,
            allRawEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          mockTutorialProvider: mockTutorialProvider,
          language: 'de',
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(() => mockDexProvider.restorePokemon(dex.id, '4')).called(1);
    });

    testWidgets('Displays multiple ignored Pokémon and filters out non-ignored entries', (tester) async {
      final dex = createTestUserDex(
        id: 'dex_multiple_ignored',
        ignoredIds: ['1', '7'], // Bisasam and Schiggy ignored, Glumanda NOT ignored
      );
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final poke1 = createTestPokemon(id: 1, nameDe: 'Bisasam');
      final poke2 = createTestPokemon(id: 4, nameDe: 'Glumanda');
      final poke3 = createTestPokemon(id: 7, nameDe: 'Schiggy');

      final entry1 = createTestEntry(pokemon: poke1, uniqueId: '1');
      final entry2 = createTestEntry(pokemon: poke2, uniqueId: '4');
      final entry3 = createTestEntry(pokemon: poke3, uniqueId: '7');

      await tester.pumpWidget(
        wrapWithApp(
          child: IgnoredListScreen(
            dexId: dex.id,
            allRawEntries: [entry1, entry2, entry3],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          mockTutorialProvider: mockTutorialProvider,
          language: 'de',
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Bisasam'), findsOneWidget);
      expect(find.text('Schiggy'), findsOneWidget);
      expect(find.text('Glumanda'), findsNothing);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('Triggers tutorial overlay when ignored_restore feature has not been seen', (tester) async {
      when(() => mockTutorialProvider.hasSeenFeature('ignored_restore')).thenReturn(false);
      when(() => mockTutorialProvider.markFeatureAsSeen(any())).thenAnswer((_) async {});

      final dex = createTestUserDex(id: 'dex_tutorial', ignoredIds: ['1']);
      when(() => mockDexProvider.userDexes).thenReturn([dex]);

      final poke = createTestPokemon(id: 1, nameDe: 'Bisasam');
      final entry = createTestEntry(pokemon: poke, uniqueId: '1');

      final appWidget = wrapWithApp(
        child: IgnoredListScreen(
          dexId: dex.id,
          allRawEntries: [entry],
        ),
        mockDexProvider: mockDexProvider,
        mockSettingsProvider: mockSettingsProvider,
        mockTutorialProvider: mockTutorialProvider,
        language: 'de',
      );
      when(() => mockTutorialProvider.hasSeenFeature('ignored_restore')).thenReturn(false);

      await tester.pumpWidget(appWidget);
      // Advance past the 500ms postFrame delay and the 300ms dialog transition
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TutorialOverlay), findsOneWidget);
    });
  });
}
