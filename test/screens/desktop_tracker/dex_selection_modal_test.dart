import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/dex_selection_modal.dart';

void main() {
  group('DexSelectionModal Widget Tests (TDD)', () {
    late List<UserDex> mockDexes;

    setUp(() {
      mockDexes = [
        UserDex(
          id: 'dex_nat',
          title: 'Nationaldex',
          region: 'national',
          isShinyDex: false,
          includeGenders: false,
          includeRegional: true,
          includeMega: false,
          includeGMax: false,
          includeOther: false,
          caughtIds: ['1', '2', '3'],
        ),
        UserDex(
          id: 'dex_kanto',
          title: 'Kanto Dex',
          region: 'kanto',
          isShinyDex: false,
          includeGenders: false,
          includeRegional: false,
          includeMega: false,
          includeGMax: false,
          includeOther: false,
          caughtIds: ['1', '4'],
        ),
      ];
    });

    testWidgets('Renders modal with dexes and marks currently selected dex', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DexSelectionModal(
              userDexes: mockDexes,
              selectedDexId: 'dex_nat',
              onDexSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Ziel-Pokédex auswählen'), findsOneWidget);
      expect(find.text('Nationaldex'), findsOneWidget);
      expect(find.text('Kanto Dex'), findsOneWidget);
      expect(find.text('Aktiv ✔'), findsOneWidget);
    });

    testWidgets('Filters dexes by search query and triggers onDexSelected on tap', (tester) async {
      UserDex? chosenDex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DexSelectionModal(
              userDexes: mockDexes,
              selectedDexId: 'dex_nat',
              onDexSelected: (dex) => chosenDex = dex,
            ),
          ),
        ),
      );

      // Enter search query
      final searchInput = find.byKey(const Key('input_search_dex'));
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'Kanto');
      await tester.pump();

      // Nationaldex should now be filtered out
      expect(find.text('Nationaldex'), findsNothing);
      expect(find.text('Kanto Dex'), findsOneWidget);

      // Tap on Kanto Dex card
      await tester.tap(find.text('Kanto Dex'));
      await tester.pump();

      expect(chosenDex, isNotNull);
      expect(chosenDex!.id, 'dex_kanto');
    });
  });
}
