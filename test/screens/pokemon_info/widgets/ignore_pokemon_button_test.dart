import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_info_widgets.dart';

void main() {
  group('IgnorePokemonButton Widget Tests', () {
    testWidgets('Button wird gerendert und reagiert auf Klicks', (
      WidgetTester tester,
    ) async {
      bool wasClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IgnorePokemonButton(
              ignoreBtnKey: GlobalKey(),
              onIgnore: () {
                wasClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      expect(find.text('Aus Dex entfernen'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));

      await tester.pump();

      expect(wasClicked, isTrue);
    });
  });
}
