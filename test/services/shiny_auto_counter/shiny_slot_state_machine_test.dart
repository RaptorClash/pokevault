import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/media/frame_transition_detector.dart';
import 'package:pokevault/services/scanner_core/media/visual_shiny_detector.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_auto_counter_config.dart';
import 'package:pokevault/services/shiny_auto_counter/shiny_slot_state_machine.dart';

ScannerEvent _encounter({
  int pokemonId = 150,
  String name = 'Mewtu',
  bool isShiny = false,
  int encounterCount = 1,
  int slotId = 1,
}) {
  return ScannerEvent(
    type: ScannerEventType.encounter,
    pokemonId: pokemonId,
    rawText: 'Wildes $name erscheint!',
    matchedName: name,
    isShiny: isShiny,
    timestamp: DateTime(2026, 1, 1),
    instanceIndex: slotId,
    encounterCount: encounterCount,
  );
}

void main() {
  group('ShinySlotStateMachine', () {
    test('Soft Reset cycle: counts target once, blocks duplicate while idle, re-arms on reset cue or black screen', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
          minResetCooldownMs: 1200,
        ),
        elapsedClock: () => clock,
      );

      // Non-target Pokemon (e.g., professor intro Rattfratz) is ignored in targetPokemonOnly mode
      final ignoredDecision = machine.onScannerEvent(
        _encounter(pokemonId: 19, name: 'Rattfratz'),
      );
      expect(ignoredDecision.shouldIncrement, isFalse);
      expect(machine.phase, equals(ShinySlotPhase.armed));

      // Target Pokemon counts +1
      final firstCount = machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu'));
      expect(firstCount.shouldIncrement, isTrue);
      expect(firstCount.delta, equals(1));
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // Challenger: 30 minutes pause on same screen -> NEVER counts again!
      for (int minute = 1; minute <= 30; minute++) {
        clock += const Duration(minutes: 1);
        final repeat = machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu'));
        expect(repeat.shouldIncrement, isFalse);
        expect(machine.phase, equals(ShinySlotPhase.counted));
      }

      // Soft reset text cue ("Weiter") transitions counted -> rearmPending -> armed after cooldown
      final resetAccepted = machine.onResetCue(ResetCue.titleOrContinue, rawLabel: 'Weiter');
      expect(resetAccepted, isTrue);
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));

      // Too early (only 500ms after reset cue)
      clock += const Duration(milliseconds: 500);
      expect(machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu')).shouldIncrement, isFalse);

      // After minResetCooldownMs (1200ms) -> re-arms and counts next encounter
      clock += const Duration(milliseconds: 800);
      final secondCount = machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu'));
      expect(secondCount.shouldIncrement, isTrue);
      expect(secondCount.delta, equals(1));
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // Black screen transition also re-arms
      machine.onFrameTransition(
        FrameTransitionEvent(
          slotId: 1,
          type: FrameTransitionType.blackScreenEnded,
          durationMs: 500,
          averageLuma: 5,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
      clock += const Duration(milliseconds: 1300);
      final thirdCount = machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu'));
      expect(thirdCount.shouldIncrement, isTrue);
    });

    test('Wild Encounter cycle: counts all wild Pokemon including horde count, re-arms on battle end', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 25,
        targetPokemonName: 'Pikachu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          matchFilter: ShinyMatchFilter.allPokemon,
          useEventEncounterCount: true,
          minResetCooldownMs: 1000,
        ),
        elapsedClock: () => clock,
      );

      // Horde of 5 Zubats counts +5
      final hordeCount = machine.onScannerEvent(
        _encounter(pokemonId: 41, name: 'Zubat', encounterCount: 5),
      );
      expect(hordeCount.shouldIncrement, isTrue);
      expect(hordeCount.delta, equals(5));
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // Battle menu keeps it counted
      machine.onBattleCue(BattleCue.battleMenu);
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // Battle end re-arms
      machine.onBattleCue(BattleCue.battleEnded);
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));

      clock += const Duration(milliseconds: 1100);
      final nextCount = machine.onScannerEvent(_encounter(pokemonId: 25, name: 'Pikachu'));
      expect(nextCount.shouldIncrement, isTrue);
      expect(nextCount.delta, equals(1));
    });

    test('Default settings disable white screen reset to prevent false triggers on dialogue boxes', () {
      const defaults = ShinyAutoCounterSettings();
      expect(defaults.enableBlackScreenReset, isTrue);
      expect(defaults.enableWhiteScreenReset, isFalse);
      expect(defaults.blackLumaThreshold, equals(18));
      expect(defaults.whiteLumaThreshold, equals(240));
    });

    test('Egg Hatch cycle (allPokemon): Oh? + hatched message counts strictly once per egg and always re-arms', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 4,
        targetPokemonName: 'Glumanda',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.eggHatch,
          matchFilter: ShinyMatchFilter.allPokemon,
          minResetCooldownMs: 1200,
        ),
        elapsedClock: () => clock,
      );

      // "Oh?" starts hatch cycle and counts once in allPokemon filter
      final ohDecision = machine.onEggHatchCue(EggHatchCue.ohPrompt);
      expect(ohDecision.shouldIncrement, isTrue);
      expect(ohDecision.delta, equals(1));
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // Resulting eggHatched text for the same egg must NOT double-count (even if a different species hatches)
      clock += const Duration(milliseconds: 1500);
      final hatchedEvent = ScannerEvent(
        type: ScannerEventType.eggHatched,
        pokemonId: 19,
        rawText: 'Rattfratz ist aus dem Ei geschlüpft!',
        matchedName: 'Rattfratz',
        timestamp: DateTime(2026, 1, 1),
      );
      expect(machine.onScannerEvent(hatchedEvent).shouldIncrement, isFalse);
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));

      // After cooldown, slot re-arms cleanly and can count the next egg
      clock += const Duration(milliseconds: 1300);
      expect(machine.onEggHatchCue(EggHatchCue.ohPrompt).shouldIncrement, isTrue);
    });

    test('Egg Hatch (targetPokemonOnly): Oh? does NOT count early; only matching eggHatched increments', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 4,
        targetPokemonName: 'Glumanda',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.eggHatch,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
          minResetCooldownMs: 1200,
        ),
        elapsedClock: () => clock,
      );

      // Oh? waits for target species instead of incrementing early
      final ohDecision = machine.onEggHatchCue(EggHatchCue.ohPrompt);
      expect(ohDecision.shouldIncrement, isFalse);
      expect(machine.phase, equals(ShinySlotPhase.armed));

      // Wrong species hatches -> ignored, remains armed
      final wrongHatched = ScannerEvent(
        type: ScannerEventType.eggHatched,
        pokemonId: 19,
        rawText: 'Rattfratz ist aus dem Ei geschlüpft!',
        matchedName: 'Rattfratz',
        timestamp: DateTime(2026, 1, 1),
      );
      expect(machine.onScannerEvent(wrongHatched).shouldIncrement, isFalse);
      expect(machine.phase, equals(ShinySlotPhase.armed));
      expect(machine.sessionCount, equals(0));

      // Target species hatches -> counts +1 and enters rearmPending
      final targetHatched = ScannerEvent(
        type: ScannerEventType.eggHatched,
        pokemonId: 4,
        rawText: 'Glumanda ist aus dem Ei geschlüpft!',
        matchedName: 'Glumanda',
        timestamp: DateTime(2026, 1, 1),
      );
      final targetDecision = machine.onScannerEvent(targetHatched);
      expect(targetDecision.shouldIncrement, isTrue);
      expect(targetDecision.delta, equals(1));
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));
    });

    test('Overworld screenTransitionOnly mode counts valid black screen transitions', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 493,
        targetPokemonName: 'Arceus',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.screenTransitionOnly,
          minResetCooldownMs: 2500,
        ),
        elapsedClock: () => clock,
      );

      final first = machine.onFrameTransition(
        FrameTransitionEvent(
          slotId: 1,
          type: FrameTransitionType.blackScreenEnded,
          durationMs: 450,
          averageLuma: 3,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
      expect(first.shouldIncrement, isTrue);
      expect(first.delta, equals(1));

      // Too soon -> ignored
      clock += const Duration(milliseconds: 1000);
      final tooSoon = machine.onFrameTransition(
        FrameTransitionEvent(
          slotId: 1,
          type: FrameTransitionType.blackScreenEnded,
          durationMs: 450,
          averageLuma: 3,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
      expect(tooSoon.shouldIncrement, isFalse);

      // After cooldown -> counts
      clock += const Duration(milliseconds: 2000);
      final second = machine.onFrameTransition(
        FrameTransitionEvent(
          slotId: 1,
          type: FrameTransitionType.blackScreenEnded,
          durationMs: 450,
          averageLuma: 3,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
      expect(second.shouldIncrement, isTrue);
    });

    test('Shiny detection honors autoPauseSlotOnShiny toggle', () {
      var clock = Duration.zero;
      final autoPauseMachine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          autoPauseSlotOnShiny: true,
        ),
        elapsedClock: () => clock,
      );

      final shinyHit = autoPauseMachine.onScannerEvent(
        _encounter(pokemonId: 150, name: 'Mewtu', isShiny: true),
      );
      expect(shinyHit.shouldIncrement, isTrue);
      expect(shinyHit.isShiny, isTrue);
      expect(autoPauseMachine.phase, equals(ShinySlotPhase.pausedByShiny));

      // Even after reset signal, stays pausedByShiny until user manually resumes
      autoPauseMachine.onResetCue(ResetCue.titleOrContinue);
      clock += const Duration(seconds: 5);
      expect(autoPauseMachine.phase, equals(ShinySlotPhase.pausedByShiny));

      autoPauseMachine.resumeFromShinyPause();
      expect(autoPauseMachine.phase, equals(ShinySlotPhase.armed));

      // With autoPauseSlotOnShiny: false, slot keeps normal counted -> re-arm flow
      final noPauseMachine = ShinySlotStateMachine(
        slotId: 2,
        colorHex: 0xFFEC4899,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          autoPauseSlotOnShiny: false,
        ),
        elapsedClock: () => clock,
      );
      final hit2 = noPauseMachine.onScannerEvent(
        _encounter(pokemonId: 150, name: 'Mewtu', isShiny: true, slotId: 2),
      );
      expect(hit2.isShiny, isTrue);
      expect(noPauseMachine.phase, equals(ShinySlotPhase.counted));
    });

    test('Custom reset pattern re-arms counted slot', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          customResetPatterns: ['Press A to Start'],
          minResetCooldownMs: 500,
        ),
        elapsedClock: () => clock,
      );

      expect(machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu')).shouldIncrement, isTrue);
      expect(
        machine.onRawText('Welcome! Press A to Start now!'),
        isTrue,
      );
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));
      clock += const Duration(milliseconds: 600);
      expect(machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu')).shouldIncrement, isTrue);
    });

    test('Egg Hatch (allPokemon): Oh? counts +1 and subsequent shiny eggHatched triggers shiny alert + pause without double counting', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 4,
        targetPokemonName: 'Glumanda',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.eggHatch,
          matchFilter: ShinyMatchFilter.allPokemon,
          autoPauseSlotOnShiny: true,
          minResetCooldownMs: 1200,
        ),
        elapsedClock: () => clock,
      );

      final oh = machine.onEggHatchCue(EggHatchCue.ohPrompt);
      expect(oh.shouldIncrement, isTrue);
      expect(oh.delta, equals(1));
      expect(machine.phase, equals(ShinySlotPhase.counted));

      clock += const Duration(seconds: 4);
      final shinyHatched = machine.onScannerEvent(
        ScannerEvent(
          type: ScannerEventType.eggHatched,
          pokemonId: 4,
          rawText: '✨ Glumanda ist aus dem Ei geschlüpft!',
          matchedName: 'Glumanda',
          isShiny: true,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
      expect(shinyHatched.shouldIncrement, isFalse);
      expect(shinyHatched.isShiny, isTrue);
      expect(shinyHatched.isShinyAlertOnly, isTrue);
      expect(machine.phase, equals(ShinySlotPhase.pausedByShiny));
      expect(machine.sessionCount, equals(1));
    });

    test('Egg Hatch (allPokemon): non-shiny eggHatched (with or without Oh?) auto-rearms after minResetCooldownMs without black screen', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 4,
        targetPokemonName: 'Glumanda',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.eggHatch,
          matchFilter: ShinyMatchFilter.allPokemon,
          minResetCooldownMs: 1200,
        ),
        elapsedClock: () => clock,
      );

      // Cycle 1: Oh? -> non-shiny eggHatched -> auto re-arm
      expect(machine.onEggHatchCue(EggHatchCue.ohPrompt).shouldIncrement, isTrue);
      clock += const Duration(seconds: 3);
      final hatchedEvent = ScannerEvent(
        type: ScannerEventType.eggHatched,
        pokemonId: 4,
        rawText: 'Glumanda ist aus dem Ei geschlüpft!',
        matchedName: 'Glumanda',
        timestamp: DateTime(2026, 1, 1),
      );
      final afterOh = machine.onScannerEvent(hatchedEvent);
      expect(afterOh.shouldIncrement, isFalse);
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));

      clock += const Duration(milliseconds: 1300);
      // Cycle 2: direct eggHatched without Oh? -> counts +1 and auto-rearms
      final direct = machine.onScannerEvent(hatchedEvent);
      expect(direct.shouldIncrement, isTrue);
      expect(direct.delta, equals(1));
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));

      clock += const Duration(milliseconds: 1300);
      expect(machine.onEggHatchCue(EggHatchCue.ohPrompt).shouldIncrement, isTrue);
    });

    test('checkRearmReady and remainingRearmDuration track cooldown progress accurately', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          minResetCooldownMs: 1000,
        ),
        elapsedClock: () => clock,
      );

      expect(machine.remainingRearmDuration, isNull);
      expect(machine.checkRearmReady(), isFalse);

      machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu'));
      machine.onResetCue(ResetCue.titleOrContinue);
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));
      expect(machine.remainingRearmDuration, equals(const Duration(milliseconds: 1000)));

      clock += const Duration(milliseconds: 400);
      expect(machine.remainingRearmDuration, equals(const Duration(milliseconds: 600)));
      expect(machine.checkRearmReady(), isFalse);
      expect(machine.phase, equals(ShinySlotPhase.rearmPending));

      clock += const Duration(milliseconds: 600);
      expect(machine.remainingRearmDuration, equals(Duration.zero));
      expect(machine.checkRearmReady(), isTrue);
      expect(machine.phase, equals(ShinySlotPhase.armed));
    });

    test('Literal custom trigger without {pokemon} works in targetPokemonOnly and respects per-hunt scope', () {
      final machineA = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        assignedHuntId: 'hunt-a',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
        ),
      );
      final machineB = ShinySlotStateMachine(
        slotId: 2,
        colorHex: 0xFFEC4899,
        targetPokemonId: 4,
        targetPokemonName: 'Glumanda',
        assignedHuntId: 'hunt-b',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
        ),
      );

      final globalCustomEvent = ScannerEvent(
        type: ScannerEventType.encounter,
        pokemonId: null,
        rawText: 'Wähle Starter',
        matchedName: 'Wähle Starter',
        matchedCustomPatternId: 'shiny_trig_1',
        timestamp: DateTime(2026, 1, 1),
      );
      expect(machineA.onScannerEvent(globalCustomEvent).shouldIncrement, isTrue);

      final scopedCustomEvent = ScannerEvent(
        type: ScannerEventType.encounter,
        pokemonId: null,
        rawText: 'Mewtu Intro',
        matchedName: 'Mewtu Intro',
        matchedCustomPatternId: 'shiny_hunt:hunt-a:trig_2',
        timestamp: DateTime(2026, 1, 1),
      );
      machineA.forceRearm();
      expect(machineA.onScannerEvent(scopedCustomEvent).shouldIncrement, isTrue);
      expect(machineB.onScannerEvent(scopedCustomEvent).shouldIncrement, isFalse);
      expect(machineB.phase, equals(ShinySlotPhase.armed));
    });

    test('recordUndo decrements sessionCount safely and immediately re-arms slot', () {
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
        ),
      );
      expect(machine.onScannerEvent(_encounter(pokemonId: 150, name: 'Mewtu')).shouldIncrement, isTrue);
      expect(machine.sessionCount, equals(1));
      expect(machine.phase, equals(ShinySlotPhase.counted));

      machine.recordUndo(1);
      expect(machine.sessionCount, equals(0));
      expect(machine.phase, equals(ShinySlotPhase.armed));

      machine.recordUndo(5);
      expect(machine.sessionCount, equals(0));
    });

    test('defaultForHuntMethod does not misclassify German methods containing "ei" as eggHatch', () {
      expect(
        ShinyHuntDetectionModeHelpers.defaultForHuntMethod('Zeitverzerrung'),
        equals(ShinyHuntDetectionMode.wildEncounter),
      );
      expect(
        ShinyHuntDetectionModeHelpers.defaultForHuntMethod('Freie Begegnung'),
        equals(ShinyHuntDetectionMode.wildEncounter),
      );
      expect(
        ShinyHuntDetectionModeHelpers.defaultForHuntMethod('Einzelbegegnung'),
        equals(ShinyHuntDetectionMode.wildEncounter),
      );
      expect(
        ShinyHuntDetectionModeHelpers.defaultForHuntMethod('Reihen-Angeln'),
        equals(ShinyHuntDetectionMode.wildEncounter),
      );
      expect(
        ShinyHuntDetectionModeHelpers.defaultForHuntMethod('Masuda / Ei'),
        equals(ShinyHuntDetectionMode.eggHatch),
      );
      expect(
        ShinyHuntDetectionModeHelpers.defaultForHuntMethod('Eier ausbrüten'),
        equals(ShinyHuntDetectionMode.eggHatch),
      );
    });

    test('Mixed double/horde or delayed shiny OCR in counted phase still emits shinyAlert and pauses slot', () {
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 74,
        targetPokemonName: 'Kleinstein',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          matchFilter: ShinyMatchFilter.allPokemon,
          autoPauseSlotOnShiny: true,
        ),
      );

      // Event 1 from horde: 4x Zubat -> slot transitions armed -> counted
      final first = machine.onScannerEvent(
        _encounter(pokemonId: 41, name: 'Zubat', encounterCount: 4),
      );
      expect(first.shouldIncrement, isTrue);
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // Event 2 milliseconds later: Shiny Kleinstein -> must emit shinyAlert & pause!
      final second = machine.onScannerEvent(
        _encounter(pokemonId: 74, name: 'Kleinstein', isShiny: true),
      );
      expect(second.isShinyAlertOnly, isTrue);
      expect(second.isShiny, isTrue);
      expect(second.pokemonId, equals(74));
      expect(second.pokemonName, equals('Kleinstein'));
      expect(machine.phase, equals(ShinySlotPhase.pausedByShiny));
    });

    test('Nameless shinyDetected event matches in targetPokemonOnly mode', () {
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 150,
        targetPokemonName: 'Mewtu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.softReset,
          matchFilter: ShinyMatchFilter.targetPokemonOnly,
          autoPauseSlotOnShiny: true,
        ),
      );

      final dec = machine.onScannerEvent(
        ScannerEvent(
          type: ScannerEventType.shinyDetected,
          pokemonId: null,
          rawText: '✨',
          matchedName: '',
          isShiny: true,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
      expect(dec.shouldIncrement, isTrue);
      expect(dec.isShiny, isTrue);
      expect(machine.phase, equals(ShinySlotPhase.pausedByShiny));
    });

    test('onVisualShinySignal uses detected phase species when provided and suppresses duplicate alerts per encounter', () {
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 25,
        targetPokemonName: 'Pikachu',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.wildEncounter,
          matchFilter: ShinyMatchFilter.allPokemon,
          autoPauseSlotOnShiny: false,
        ),
      );

      expect(
        machine.onScannerEvent(_encounter(pokemonId: 41, name: 'Zubat')).shouldIncrement,
        isTrue,
      );

      final sig1 = VisualShinySignal(
        slotId: 1,
        source: ShinyDetectionSource.colorDeviation,
        score: 0.55,
        details: '55%',
        timestamp: DateTime(2026, 1, 1),
      );
      final alert1 = machine.onVisualShinySignal(
        sig1,
        detectedPokemonId: 41,
        detectedPokemonName: 'Zubat',
      );
      expect(alert1.isShinyAlertOnly, isTrue);
      expect(alert1.pokemonId, equals(41));
      expect(alert1.pokemonName, equals('Zubat'));

      // Second visual signal (e.g. sparkleDelay) for the exact same encounter is suppressed
      final sig2 = VisualShinySignal(
        slotId: 1,
        source: ShinyDetectionSource.sparkleDelay,
        score: 1800,
        details: '+1800ms',
        timestamp: DateTime(2026, 1, 1),
      );
      final alert2 = machine.onVisualShinySignal(
        sig2,
        detectedPokemonId: 41,
        detectedPokemonName: 'Zubat',
      );
      expect(alert2.isShinyAlertOnly, isFalse);
      expect(alert2.isShiny, isFalse);
    });

    test('Base custom patterns tagged shiny_base: do not fire when assigned hunt has explicit override removing them', () {
      const baseAndOverride = ShinyAutoCounterSettings(
        customTriggerPatterns: [
          CustomOcrPattern(
            id: 'trig_global',
            template: 'Globaler Start',
            eventType: ScannerEventType.encounter,
          ),
        ],
        huntSettingsOverrides: {
          'hunt-custom': ShinyAutoCounterSettings(
            detectionMode: ShinyHuntDetectionMode.softReset,
            customTriggerPatterns: [],
          ),
        },
      );
      final compiled = baseAndOverride.buildEngineCustomPatterns();
      final basePattern = compiled.firstWhere((p) => p.template == 'Globaler Start');
      expect(basePattern.id.startsWith('shiny_base:'), isTrue);

      final machineWithOverride = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        assignedHuntId: 'hunt-custom',
        settings: baseAndOverride.resolveForHunt(huntId: 'hunt-custom'),
      );
      machineWithOverride.setHasExplicitHuntOverride(true);

      final dec = machineWithOverride.onScannerEvent(
        ScannerEvent(
          type: ScannerEventType.encounter,
          rawText: 'Globaler Start',
          matchedName: 'Globaler Start',
          matchedCustomPatternId: basePattern.id,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
      expect(dec.shouldIncrement, isFalse);
    });

    test('Egg Hatch Oh? prompt auto-rearms safely after 18s fallback if hatched text was missed', () {
      var clock = Duration.zero;
      final machine = ShinySlotStateMachine(
        slotId: 1,
        colorHex: 0xFFA855F7,
        targetPokemonId: 4,
        targetPokemonName: 'Glumanda',
        settings: const ShinyAutoCounterSettings(
          detectionMode: ShinyHuntDetectionMode.eggHatch,
          matchFilter: ShinyMatchFilter.allPokemon,
          minResetCooldownMs: 1200,
        ),
        elapsedClock: () => clock,
      );

      expect(machine.onEggHatchCue(EggHatchCue.ohPrompt).shouldIncrement, isTrue);
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // Before 18s -> still counted
      clock += const Duration(seconds: 10);
      expect(machine.checkRearmReady(), isFalse);
      expect(machine.phase, equals(ShinySlotPhase.counted));

      // After 18s -> safety auto-rearm promotes back to armed so next egg is never stuck
      clock += const Duration(seconds: 9);
      expect(machine.checkRearmReady(), isTrue);
      expect(machine.phase, equals(ShinySlotPhase.armed));
      expect(machine.onEggHatchCue(EggHatchCue.ohPrompt).shouldIncrement, isTrue);
    });
  });
}
