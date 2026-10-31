import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/widgets/hunt_game_method_selector.dart';
import 'package:pokevault/utils/shiny_hunt_odds_helper.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.de);
  });

  const testPresets = [
    ShinyMethodPreset(
      name: 'Standard (Wild Encounter)',
      defaultBaseOdds: 4096.0,
      defaultSpawns: 1,
    ),
    ShinyMethodPreset(
      name: 'Masuda-Methode',
      defaultBaseOdds: 683.0,
      oddsWithCharm: 512.0,
      defaultSpawns: 1,
    ),
  ];

  const testGames = [
    'Schwert / Schild',
    'Karmesin / Purpur',
    'HeartGold / SoulSilver',
  ];

  Widget buildTestWidget({
    String selectedGame = 'Karmesin / Purpur',
    List<String> availableGames = testGames,
    String? selectedMethod = 'Standard (Wild Encounter)',
    List<ShinyMethodPreset> availablePresets = testPresets,
    bool hasShinyCharm = false,
    ValueChanged<String?>? onGameChanged,
    ValueChanged<String?>? onMethodChanged,
    ValueChanged<bool>? onShinyCharmChanged,
    double screenWidth = 400,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 600)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: HuntGameMethodSelector(
              selectedGame: selectedGame,
              availableGames: availableGames,
              selectedMethod: selectedMethod,
              availablePresets: availablePresets,
              hasShinyCharm: hasShinyCharm,
              onGameChanged: onGameChanged ?? (_) {},
              onMethodChanged: onMethodChanged ?? (_) {},
              onShinyCharmChanged: onShinyCharmChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('HuntGameMethodSelector TDD Tests', () {
    testWidgets('Renders game dropdown, method dropdown, and shiny charm switch', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('Changing game triggers onGameChanged callback', (tester) async {
      String? changedGame;

      await tester.pumpWidget(buildTestWidget(
        onGameChanged: (g) => changedGame = g,
      ));

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schwert / Schild').last);
      await tester.pumpAndSettle();

      expect(changedGame, 'Schwert / Schild');
    });

    testWidgets('Toggling Shiny Charm triggers onShinyCharmChanged callback', (tester) async {
      bool charmState = false;

      await tester.pumpWidget(buildTestWidget(
        hasShinyCharm: false,
        onShinyCharmChanged: (c) => charmState = c,
      ));

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(charmState, isTrue);
    });

    testWidgets('Adversarial Viewport: Renders on 320px narrow screen without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(screenWidth: 320));

      expect(tester.takeException(), isNull);
    });
  });
}
