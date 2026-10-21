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

    testWidgets('Setzt memCacheWidth und memCacheHeight basierend auf width und height', (
      WidgetTester tester,
    ) async {
      if (kIsWeb) return;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversalPokeImage(
              imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
              width: 84,
              height: 84,
            ),
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.width, 84.0);
      expect(cachedImage.height, 84.0);
      expect(cachedImage.memCacheWidth, isNotNull);
      expect(cachedImage.memCacheHeight, isNotNull);
    });

    testWidgets('Verwendet explizite cacheWidth und cacheHeight wenn angegeben', (
      WidgetTester tester,
    ) async {
      if (kIsWeb) return;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversalPokeImage(
              imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
              cacheWidth: 168,
              cacheHeight: 168,
            ),
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.memCacheWidth, 168);
      expect(cachedImage.memCacheHeight, 168);
    });

    testWidgets('Wendet sichere Standardbegrenzung an wenn width und height null sind', (
      WidgetTester tester,
    ) async {
      if (kIsWeb) return;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversalPokeImage(
              imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
            ),
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      // Darf niemals null sein, um unkomprimierte 1GB-Spikes zu verhindern
      expect(cachedImage.memCacheWidth, isNotNull);
      expect(cachedImage.memCacheHeight, isNotNull);
      expect(cachedImage.memCacheWidth, lessThanOrEqualTo(400));
      expect(cachedImage.memCacheHeight, lessThanOrEqualTo(400));
    });
  });
}
