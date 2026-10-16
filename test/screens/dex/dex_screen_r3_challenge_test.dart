import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/dex_screen.dart';

void main() {
  group('R3 Adversarial Challenge: Compilation & Deep Copy Independence', () {
    test('VERIFICATION 1: dex_screen.dart compilation check', () {
      // If dex_screen.dart has syntax or duplicate definition errors, this test will fail at compile time.
      expect(DexScreen, isNotNull);
    });

    test('VERIFICATION 2: Deep copy independence of _customBoxesSnapshot', () {
      final box1 = CustomBoxState(
        title: 'Original Box 1',
        pokemonIds: ['P1', 'P2', 'P3'],
        columns: 5,
        rows: 6,
        autoFlow: false,
        autoShift: true,
      );
      final box2 = CustomBoxState(
        title: 'Original Box 2',
        pokemonIds: ['P4', 'P5'],
        columns: 5,
        rows: 6,
        autoFlow: false,
        autoShift: true,
      );

      final liveDex = UserDex(
        id: 'test_dex',
        title: 'Test Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        viewMode: 'box',
        customBoxes: [box1, box2],
      );

      // Snapshot creation exactly as implemented in DexScreen line 1275:
      final snapshot = liveDex.customBoxes.map((b) => b.copyWith()).toList();

      // MUTATIONS during edit mode:
      // 1. In-place modification of pokemonIds
      liveDex.customBoxes[0].pokemonIds.add('P_NEW_MUTATED');
      liveDex.customBoxes[0].pokemonIds[0] = 'P1_MUTATED';

      // 2. In-place modification of box properties
      liveDex.customBoxes[0].title = 'Mutated Box Title';
      liveDex.customBoxes[0].columns = 6;
      liveDex.customBoxes[0].autoFlow = true;

      // 3. Structural modification of box list
      liveDex.customBoxes.removeAt(1);
      liveDex.customBoxes.add(CustomBoxState(title: 'Brand New Box', pokemonIds: ['P999']));

      // CHALLENGE: Snapshot must remain completely untouched!
      expect(snapshot.length, equals(2));
      expect(snapshot[0].title, equals('Original Box 1'));
      expect(snapshot[0].pokemonIds, equals(['P1', 'P2', 'P3']));
      expect(snapshot[0].columns, equals(5));
      expect(snapshot[0].autoFlow, isFalse);

      expect(snapshot[1].title, equals('Original Box 2'));
      expect(snapshot[1].pokemonIds, equals(['P4', 'P5']));
    });

    test('VERIFICATION 3: Rollback restores exact structure and cleans orphan caught IDs', () {
      final box1 = CustomBoxState(
        title: 'Box 1',
        pokemonIds: ['P1', 'P2__initial_123'],
        columns: 5,
        rows: 6,
      );
      final liveDex = UserDex(
        id: 'test_dex',
        title: 'Test Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        viewMode: 'box',
        customBoxes: [box1],
        caughtIds: ['P1', 'P2__initial_123'],
      );

      // Snapshot upon entering edit mode
      final snapshot = liveDex.customBoxes.map((b) => b.copyWith()).toList();

      // Intermediate edits: add new pokemon with generated instance id
      const newInstanceId = 'P3__added_456';
      liveDex.customBoxes[0].pokemonIds.add(newInstanceId);
      liveDex.caughtIds.add(newInstanceId);
      liveDex.customBoxes[0].title = 'Altered Box 1';

      // Confirm intermediate state
      expect(liveDex.customBoxes[0].pokemonIds.contains(newInstanceId), isTrue);
      expect(liveDex.caughtIds.contains(newInstanceId), isTrue);

      // Rollback execution exactly as implemented in DexScreen lines 310-320:
      liveDex.customBoxes = snapshot.map((b) => b.copyWith()).toList();
      liveDex.caughtIds.removeWhere((id) =>
          id.contains('__') &&
          !liveDex.customBoxes.expand((b) => b.pokemonIds).contains(id));

      // CHALLENGE: Rollback must restore original titles, pokemonIds, and prune newly caught orphan
      expect(liveDex.customBoxes.length, equals(1));
      expect(liveDex.customBoxes[0].title, equals('Box 1'));
      expect(liveDex.customBoxes[0].pokemonIds, equals(['P1', 'P2__initial_123']));
      expect(liveDex.caughtIds.contains(newInstanceId), isFalse);
      expect(liveDex.caughtIds.contains('P2__initial_123'), isTrue);
    });
  });
}
