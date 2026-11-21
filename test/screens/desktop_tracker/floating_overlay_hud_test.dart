import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/floating_overlay_hud.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';

void main() {
  group('FloatingOverlayHud Widget Tests (TDD)', () {
    testWidgets('Renders HUD with waiting state when latestEvent is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FloatingOverlayHud(),
          ),
        ),
      );

      expect(find.text('PokéVault HUD'), findsOneWidget);
      expect(find.textContaining('Warte auf Spiel'), findsOneWidget);
    });

    testWidgets('Renders detected Pokémon with shiny badge and triggers mark caught', (tester) async {
      bool caughtTriggered = false;

      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Glumanda',
        pokemonId: 4,
        isShiny: true,
        rawText: 'Ein wildes schillerndes Glumanda erscheint!',
        timestamp: DateTime.now(),
      );

      final userDex = UserDex(
        id: 'dex_test',
        title: 'Nationaldex',
        region: 'national',
        isShinyDex: false,
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingOverlayHud(
              latestEvent: event,
              activeDex: userDex,
              onMarkCaught: () => caughtTriggered = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Glumanda'), findsOneWidget);
      expect(find.textContaining('SHINY'), findsOneWidget);
      expect(find.textContaining('Fehlt im Ziel-Dex'), findsOneWidget);

      final catchBtn = find.byKey(const Key('btn_hud_mark_caught'));
      expect(catchBtn, findsOneWidget);
      await tester.tap(catchBtn);
      await tester.pump();

      expect(caughtTriggered, isTrue);
    });

    testWidgets('Toggles compact mode and adjusts opacity slider', (tester) async {
      double? changedOpacity;
      bool compactMode = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: FloatingOverlayHud(
                  isCompact: compactMode,
                  onCompactChanged: (val) => setState(() => compactMode = val),
                  onOpacityChanged: (val) => changedOpacity = val,
                ),
              ),
            );
          },
        ),
      );

      // Initially expanded: Opacity slider visible
      expect(find.byKey(const Key('hud_opacity_slider')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hud_opacity_slider')));
      await tester.pump();
      expect(changedOpacity, isNotNull);

      // Tap compact toggle button
      final toggleCompactBtn = find.byKey(const Key('btn_hud_toggle_compact'));
      expect(toggleCompactBtn, findsOneWidget);
      await tester.tap(toggleCompactBtn);
      await tester.pumpAndSettle();

      expect(compactMode, isTrue);
      // In compact mode, opacity slider is hidden
      expect(find.byKey(const Key('hud_opacity_slider')), findsNothing);
    });

    testWidgets('Renders evolution status badge and multi-instance badge without overflow', (tester) async {
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Flampion',
        pokemonId: 554,
        rawText: 'Ein wildes Flampion erscheint!',
        timestamp: DateTime.now(),
        instanceIndex: 2,
        instanceColorHex: 0xFFEC4899,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingOverlayHud(
              latestEvent: event,
              evolutionSummary: 'Entw.: Flampivian fehlt!',
              hasMissingEvolutions: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Flampion'), findsOneWidget);
      expect(find.textContaining('#2'), findsOneWidget);
      expect(find.textContaining('Flampivian fehlt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders multi-encounter enemies with encounterCount and per-enemy + Dex actions', (tester) async {
      final markedIds = <int>[];
      final userDex = UserDex(
        id: 'dex_test',
        title: 'Nationaldex',
        region: 'national',
        isShinyDex: false,
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: const ['88'],
      );
      final sleima = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Sleima',
        pokemonId: 88,
        rawText: 'Sleima\nZubat',
        timestamp: DateTime.now(),
      );
      final zubat = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Zubat',
        pokemonId: 41,
        encounterCount: 3,
        rawText: 'Sleima\nZubat',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingOverlayHud(
              latestEvent: zubat,
              focusEvents: [sleima, zubat],
              activeDex: userDex,
              onMarkEventCaught: (ev) {
                if (ev.pokemonId != null) markedIds.add(ev.pokemonId!);
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('2 Gegner'), findsOneWidget);
      expect(find.textContaining('Sleima'), findsOneWidget);
      expect(find.textContaining('Zubat'), findsOneWidget);
      expect(find.textContaining('×3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_hud_mark_caught_41')));
      await tester.pump();
      expect(markedIds, [41]);
      expect(tester.takeException(), isNull);
    });
  });
}
