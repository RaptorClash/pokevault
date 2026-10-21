import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/pokemon_info/widgets/lazy_expansion_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LazyExpansionCard Quality Gate & Lifecycle Tests', () {
    testWidgets('Children are NOT built when card is collapsed', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyExpansionCard(
              title: const Text('Fundorte'),
              builder: (context) {
                buildCount++;
                return const Text('Inhalt Fundorte');
              },
            ),
          ),
        ),
      );

      // Verify header is visible
      expect(find.text('Fundorte'), findsOneWidget);

      // Verify content is NOT in tree and builder was NEVER called
      expect(find.text('Inhalt Fundorte'), findsNothing);
      expect(buildCount, equals(0),
          reason: 'Builder must not be executed when the card is collapsed');
    });

    testWidgets('Children ARE built when card is tapped to expand', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyExpansionCard(
              title: const Text('Bänder'),
              builder: (context) {
                buildCount++;
                return const Text('Inhalt Bänder');
              },
            ),
          ),
        ),
      );

      // Tap the card header to expand
      await tester.tap(find.text('Bänder'));
      await tester.pumpAndSettle();

      // Verify content is now in tree and builder was called
      expect(find.text('Inhalt Bänder'), findsOneWidget);
      expect(buildCount, greaterThan(0),
          reason: 'Builder must be executed when user opens card');
    });

    testWidgets('Children are DISPOSED from memory when card is collapsed again', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyExpansionCard(
              title: const Text('Zeichen'),
              builder: (context) {
                return const Text('Inhalt Zeichen');
              },
            ),
          ),
        ),
      );

      // Expand
      await tester.tap(find.text('Zeichen'));
      await tester.pumpAndSettle();
      expect(find.text('Inhalt Zeichen'), findsOneWidget);

      // Collapse again
      await tester.tap(find.text('Zeichen'));
      await tester.pumpAndSettle();

      // Verify content is completely removed from widget tree (maintainState: false)
      expect(find.text('Inhalt Zeichen'), findsNothing,
          reason: 'Collapsed card must release child widgets to reclaim RAM');
    });

    testWidgets('Renders leading, title, and custom trailing widget correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyExpansionCard(
              leading: const Icon(Icons.egg, key: ValueKey('test_icon')),
              title: const Text('Zucht'),
              trailing: const Text('3 / 10', key: ValueKey('test_badge')),
              builder: (context) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('test_icon')), findsOneWidget);
      expect(find.text('Zucht'), findsOneWidget);
      expect(find.byKey(const ValueKey('test_badge')), findsOneWidget);
    });

    testWidgets('Supports initiallyExpanded true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyExpansionCard(
              initiallyExpanded: true,
              title: const Text('Offen'),
              builder: (context) => const Text('Direkt Sichtbar'),
            ),
          ),
        ),
      );

      expect(find.text('Offen'), findsOneWidget);
      expect(find.text('Direkt Sichtbar'), findsOneWidget);
    });
  });
}
