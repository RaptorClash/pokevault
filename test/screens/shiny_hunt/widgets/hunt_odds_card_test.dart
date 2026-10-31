import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/screens/shiny_hunt/widgets/hunt_odds_card.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.de);
  });

  ShinyHunt createDummyHunt({
    int currentEncounters = 100,
    double baseOdds = 100.0,
    int totalTimeSeconds = 3600,
    bool isPaused = false,
    bool isCompleted = false,
  }) {
    final now = DateTime.now();
    return ShinyHunt(
      id: 'test_hunt_1',
      title: 'Rayquaza Hunt',
      pokemonId: 384,
      pokemonName: 'Rayquaza',
      game: 'Schild',
      generation: 8.0,
      method: 'Dynamax-Abenteuer',
      baseOdds: baseOdds,
      currentEncounters: currentEncounters,
      totalTimeSeconds: totalTimeSeconds,
      status: isCompleted ? 'completed' : (isPaused ? 'paused' : 'active'),
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildTestWidget({
    required ShinyHunt hunt,
    VoidCallback? onTogglePause,
    double screenWidth = 400,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 600)),
        child: Scaffold(
          body: HuntOddsCard(
            hunt: hunt,
            onTogglePause: onTogglePause ?? () {},
          ),
        ),
      ),
    );
  }

  group('HuntOddsCard TDD Tests', () {
    testWidgets('Renders probability stats, formatted time, pace, and status badge', (tester) async {
      final hunt = createDummyHunt(
        currentEncounters: 100,
        baseOdds: 100.0,
        totalTimeSeconds: 3600,
      );

      await tester.pumpWidget(buildTestWidget(hunt: hunt));

      // 63.4% or 63.2% binomial probability for 100 encounters at 1/100
      expect(find.textContaining('%'), findsWidgets);
      expect(find.text('At Odds'), findsOneWidget);
      expect(find.textContaining('1.00x Odds'), findsOneWidget);
      expect(find.text('01:00:00'), findsOneWidget);
      expect(find.text('100 / h'), findsOneWidget);
    });

    testWidgets('Tapping pause button triggers onTogglePause callback', (tester) async {
      final hunt = createDummyHunt(isPaused: false);
      bool pauseToggled = false;

      await tester.pumpWidget(buildTestWidget(
        hunt: hunt,
        onTogglePause: () => pauseToggled = true,
      ));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause_rounded));
      expect(pauseToggled, isTrue);
    });

    testWidgets('Renders resume button when hunt is paused', (tester) async {
      final hunt = createDummyHunt(isPaused: true);

      await tester.pumpWidget(buildTestWidget(hunt: hunt));

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('Hides pause/resume button when hunt is completed', (tester) async {
      final hunt = createDummyHunt(isCompleted: true);

      await tester.pumpWidget(buildTestWidget(hunt: hunt));

      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('Adversarial Viewport: Renders on 320px narrow screen without overflow', (tester) async {
      final hunt = createDummyHunt();

      await tester.pumpWidget(buildTestWidget(
        hunt: hunt,
        screenWidth: 320,
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
