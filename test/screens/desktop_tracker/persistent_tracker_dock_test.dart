import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/persistent_tracker_dock.dart';
import 'package:pokevault/services/desktop_tracker/desktop_tracker_service.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/utils/tracker_platform_helper.dart';

class _MockDexProvider extends Mock implements DexProvider {}

void main() {
  group('PersistentTrackerDock Widget Tests (TDD)', () {
    late UserDex mockDex;

    setUp(() {
      mockDex = UserDex(
        id: 'dex_nat',
        title: 'Nationaldex',
        region: 'national',
        isShinyDex: false,
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: ['1', '2'],
      );
    });

    testWidgets('Renders persistent dock with live encounter info and dex status', (tester) async {
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Glumanda',
        pokemonId: 4,
        isShiny: true,
        rawText: 'Ein wildes schillerndes Glumanda erscheint!',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PersistentTrackerDock(
              latestEvent: event,
              activeDex: mockDex,
              isScanningActive: true,
              onOpenHud: () {},
              onOpenSetup: () {},
              onTogglePause: () {},
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.textContaining('Glumanda'), findsOneWidget);
      expect(find.textContaining('Fehlt im Ziel-Dex'), findsOneWidget);
      expect(find.byKey(const Key('btn_dock_open_hud')), findsOneWidget);
      expect(find.byKey(const Key('btn_dock_open_setup')), findsOneWidget);
    });

    testWidgets('Triggers action callbacks on button taps', (tester) async {
      bool hudOpened = false;
      bool setupOpened = false;
      bool pauseToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PersistentTrackerDock(
              latestEvent: null,
              activeDex: mockDex,
              isScanningActive: true,
              onOpenHud: () => hudOpened = true,
              onOpenSetup: () => setupOpened = true,
              onTogglePause: () => pauseToggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_dock_open_hud')));
      await tester.pump();
      expect(hudOpened, isTrue);

      await tester.tap(find.byKey(const Key('btn_dock_open_setup')));
      await tester.pump();
      expect(setupOpened, isTrue);

      await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
      await tester.pump();
      expect(pauseToggled, isTrue);
    });

    testWidgets('shows HUD active state, LIVE/PAUSIERT badge, and quick + Eintragen action', (tester) async {
      bool markCaughtTapped = false;
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Pikachu',
        pokemonId: 25,
        rawText: 'Wildes Pikachu',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PersistentTrackerDock(
              latestEvent: event,
              activeDex: mockDex,
              isScanningActive: true,
              isHudVisible: true,
              activeSourceTitle: 'melonDS',
              onOpenHud: () {},
              onOpenSetup: () {},
              onTogglePause: () {},
              onMarkCaught: () => markCaughtTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.textContaining('HUD aktiv'), findsOneWidget);
      expect(find.textContaining('melonDS'), findsOneWidget);

      final markBtn = find.byKey(const Key('btn_dock_mark_caught'));
      expect(markBtn, findsOneWidget);
      await tester.tap(markBtn);
      await tester.pump();
      expect(markCaughtTapped, isTrue);
    });

    testWidgets('PersistentTrackerDockHost pauses without closing, resumes, and closes cleanly on X', (tester) async {
      TrackerPlatformHelper.debugIsDesktopOverride = () => true;
      addTearDown(TrackerPlatformHelper.resetDebugOverrides);
      addTearDown(() async {
        await DesktopTrackerService.instance.stopTracking();
      });

      final mockDexProvider = _MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn([mockDex]);
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);

      final coordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const []),
        settings: ScannerSettings.defaults(),
      );
      DesktopTrackerService.instance.startTracking(
        coordinator: coordinator,
        dexId: mockDex.id,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DexProvider>.value(
          value: mockDexProvider,
          child: MaterialApp(
            home: Scaffold(
              body: const Center(child: Text('Home')),
              bottomNavigationBar: PersistentTrackerDockHost(
                onOpenSetup: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PersistentTrackerDock), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      // Pause button MUST pause without closing/terminating the dock!
      await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
      await tester.pump();

      expect(find.byType(PersistentTrackerDock), findsOneWidget);
      expect(find.text('PAUSIERT'), findsOneWidget);
      expect(DesktopTrackerService.instance.isTrackingActive, isTrue);
      expect(DesktopTrackerService.instance.isPaused, isTrue);

      // Resume button restores LIVE state
      await tester.tap(find.byKey(const Key('btn_dock_toggle_pause')));
      await tester.pump();

      expect(find.byType(PersistentTrackerDock), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(DesktopTrackerService.instance.isPaused, isFalse);

      // Close (X) button terminates tracking and removes the dock
      await tester.tap(find.byKey(const Key('btn_dock_close')));
      await tester.pump();

      expect(DesktopTrackerService.instance.isTrackingActive, isFalse);
      expect(find.byType(PersistentTrackerDock), findsNothing);
      await coordinator.dispose();
    });
  });
}
