import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokevault/widgets/universal_poke_image.dart';

void main() {
  group('UniversalPokeImage Widget Tests', () {
    testWidgets('Rendert korrekt basierend auf der Plattform (kIsWeb)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversalPokeImage(
              imageUrl:
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
              fallbackUrl: 'https://fallback.com/25.png',
            ),
          ),
        ),
      );

      // Je nach dem in welchem Environment der Test-Runner läuft (meistens nicht Web),
      // soll er das entsprechende Bild-Widget finden.
      if (kIsWeb) {
        expect(find.byType(Image), findsWidgets);
      } else {
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      }
    });
  });
}
