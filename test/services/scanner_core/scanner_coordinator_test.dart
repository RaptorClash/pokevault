import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/engine/ocr_detection_engine.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import 'package:pokevault/services/scanner_core/feedback/scanner_feedback.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_coordinator.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';

class TestFeedback implements ScannerFeedback {
  final List<String> calls = [];

  @override
  Future<void> onCaught(ScannerEvent event) async {
    calls.add('caught:${event.matchedName}');
  }

  @override
  Future<void> onEncounter(ScannerEvent event) async {
    calls.add('encounter:${event.matchedName}');
  }

  @override
  Future<void> onEvolved(ScannerEvent event) async {
    calls.add('evolved:${event.matchedName}');
  }

  @override
  Future<void> onShiny(ScannerEvent event) async {
    calls.add('shiny:${event.matchedName}');
  }
}

void main() {
  group('ScannerCoordinator Tests (TDD)', () {
    late PokemonFuzzyMatcher matcher;
    late OcrDetectionEngine engine;
    late MockScannerSource mockSource;
    late TestFeedback feedback;
    late ScannerCoordinator coordinator;

    setUp(() {
      matcher = PokemonFuzzyMatcher.withEntries([
        const PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
        const PokemonMatcherEntry(id: 5, name: 'Glutexo', language: 'de'),
        const PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
      ]);
      engine = OcrDetectionEngine();
      mockSource = MockScannerSource();
      feedback = TestFeedback();

      coordinator = ScannerCoordinator(
        engine: engine,
        matcher: matcher,
        settings: ScannerSettings.defaults(),
        feedback: feedback,
      );
      coordinator.bindSource(mockSource);
    });

    tearDown(() async {
      await coordinator.dispose();
      await mockSource.dispose();
    });

    test('Processes catch event from stream and triggers feedback', () async {
      final events = <ScannerEvent>[];
      final sub = coordinator.events.listen(events.add);

      mockSource.emitText('Glumanda wurde gefangen!');
      await pumpEventQueue();

      expect(events.length, 1);
      final ev = events.first;
      expect(ev.type, ScannerEventType.caught);
      expect(ev.pokemonId, 4);
      expect(ev.matchedName, 'Glumanda');
      expect(feedback.calls, contains('caught:Glumanda'));

      await sub.cancel();
    });

    test('Debounces rapid duplicate text within cooldown window', () async {
      final events = <ScannerEvent>[];
      final sub = coordinator.events.listen(events.add);

      // Emit exact same catch text 4 times consecutively
      mockSource.emitText('Glumanda wurde gefangen!');
      mockSource.emitText('Glumanda wurde gefangen!');
      mockSource.emitText('Glumanda wurde gefangen!');
      mockSource.emitText('Glumanda wurde gefangen!');
      await pumpEventQueue();

      // Duplicate filter must keep only 1 event
      expect(events.length, 1);

      await sub.cancel();
    });

    test('Processes evolution and resolves pre-evolution metadata', () async {
      final events = <ScannerEvent>[];
      final sub = coordinator.events.listen(events.add);

      coordinator.updateSettings(
        coordinator.settings.copyWith(
          livingDexEvolutionAction: LivingDexEvolutionAction.autoRemovePreEvolution,
        ),
      );

      mockSource.emitText('Glumanda hat sich zu Glutexo entwickelt!');
      await pumpEventQueue();

      expect(events.length, 1);
      final ev = events.first;
      expect(ev.type, ScannerEventType.evolved);
      expect(ev.pokemonId, 5);
      expect(ev.matchedName, 'Glutexo');
      expect(ev.preEvolutionId, 4);
      expect(ev.preEvolutionName, 'Glumanda');
      expect(feedback.calls, contains('evolved:Glutexo'));

      await sub.cancel();
    });

    test('Direct text processing via processText API', () async {
      final ev = await coordinator.processText('Pikachu wurde gefangen!');
      expect(ev, isNotNull);
      expect(ev!.type, ScannerEventType.caught);
      expect(ev.pokemonId, 25);
    });

    test('Lifecycle start and stop properly controls scanner source', () async {
      expect(mockSource.isRunning, isFalse);
      await coordinator.start();
      expect(mockSource.isRunning, isTrue);
      await coordinator.stop();
      expect(mockSource.isRunning, isFalse);
    });

    test('Resolves garbled Zurrokex Black log end-to-end via Smart-Search and exposes Top-3 alternatives', () async {
      final smartCoordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
          PokemonMatcherEntry(id: 560, name: 'Irokex', language: 'de'),
          PokemonMatcherEntry(id: 570, name: 'Zorua', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await smartCoordinator.dispose());

      const blackLog = '[110/601 melonDS 1.1\n'
          'File System View Config Help\n'
          'Klasse!\n'
          'Zr-rrokex wrde aefar«t!\n'
          '14 so\n'
          '150/204';

      final ev = await smartCoordinator.processText(blackLog);
      expect(ev, isNotNull);
      expect(ev!.type, ScannerEventType.caught);
      expect(ev.pokemonId, 559);
      expect(ev.matchedName, 'Zurrokex');
      expect(ev.isSmartMatch, isTrue);
      expect(ev.alternatives, isNotEmpty);
      expect(ev.alternatives.first.pokemonId, 559);
      expect(ev.autoAddedCaught, isFalse);

      final updated = ev.copyWith(autoAddedCaught: true);
      expect(updated.autoAddedCaught, isTrue);
    });

    test('ignoredPokemonIds blocks starter/team catches and encounters', () async {
      final guardedCoordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 497, name: 'Serpiroyal', language: 'de'),
          PokemonMatcherEntry(id: 551, name: 'Ganovil', language: 'de'),
        ]),
        settings: ScannerSettings.defaults().copyWith(
          ignoredPokemonIds: const [497],
        ),
      );
      addTearDown(() async => await guardedCoordinator.dispose());

      final blocked = await guardedCoordinator.processText('Serpiroyal wurde gefangen!');
      expect(blocked, isNull);

      final allowed = await guardedCoordinator.processText('Ganovil wurde gefangen!');
      expect(allowed, isNotNull);
      expect(allowed!.pokemonId, 551);
      expect(allowed.type, ScannerEventType.caught);
    });

    test('processFrameText supports encounterOnly and multi-encounter enemies with per-ID cooldown', () async {
      final multiCoordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 551, name: 'Ganovil', language: 'de'),
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await multiCoordinator.dispose());

      final focusBatches = <List<ScannerEvent>>[];
      final focusSub = multiCoordinator.activeFocusStream.listen(focusBatches.add);
      addTearDown(() async => await focusSub.cancel());

      final enemies = await multiCoordinator.processFrameText(
        'Zurrokex Lv.16   Flampion Lv.16   Ganovil Lv.17',
        encounterOnly: true,
        allowMultiEncounter: true,
      );

      expect(enemies.map((e) => e.pokemonId).toList(), [559, 554, 551]);
      expect(enemies.every((e) => e.type == ScannerEventType.encounter), isTrue);

      await Future.delayed(Duration.zero);
      expect(focusBatches, isNotEmpty);
      expect(focusBatches.last.map((e) => e.pokemonId).toList(), [559, 554, 551]);
    });

    test('Single-screen battle state machine suppresses repeat encounter spam until battle ends or species changes', () async {
      final battleCoordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 551, name: 'Ganovil', language: 'de'),
          PokemonMatcherEntry(id: 497, name: 'Serpiroyal', language: 'de'),
        ]),
        settings: ScannerSettings.defaults().copyWith(
          ignoredPokemonIds: const [497],
        ),
        encounterCooldown: const Duration(milliseconds: 5),
      );
      addTearDown(() async => await battleCoordinator.dispose());

      // Frame 1: Wild encounter starts battle
      final ev1 = await battleCoordinator.processText('Ein wildes Flampion erscheint!');
      expect(ev1, isNotNull);
      expect(ev1!.pokemonId, 554);
      expect(ev1.type, ScannerEventType.encounter);

      // Frame 2: Player action menu in same battle ("Klas soll Serpirogal tl.rt?") -> ignored
      final menu = await battleCoordinator.processText('Klas soll Serpirogal tl.rt?');
      expect(menu, isNull);

      // Wait longer than legacy 5ms cooldown and re-scan enemy HUD / garbled Flampion text
      await Future.delayed(const Duration(milliseconds: 20));
      final duplicateInSameBattle = await battleCoordinator.processText("Fdlanp,io.n");
      expect(duplicateInSameBattle, isNull,
          reason: 'Must not spam duplicate BEGEGNUNG events while the same wild battle is ongoing');

      // Battle ends via Escape ("Erfolgreich geflohen!") -> resets battle state
      await battleCoordinator.processText('Du bist erfolgreich geflohen!');
      await Future.delayed(const Duration(milliseconds: 10));

      // Frame 4: New wild encounter with Flampion AFTER fleeing -> logs cleanly again!
      final evAfterFlee = await battleCoordinator.processText('Ein wildes Flampion erscheint!');
      expect(evAfterFlee, isNotNull);
      expect(evAfterFlee!.pokemonId, 554);
    });

    test('processFrameText attaches multi-instance slot metadata when provided', () async {
      final slotCoordinator = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
      );
      addTearDown(() async => await slotCoordinator.dispose());

      final events = await slotCoordinator.processFrameText(
        'Flampion Lv.15',
        encounterOnly: true,
        instanceIndex: 2,
        instanceColorHex: 0xFFEC4899,
      );
      expect(events, hasLength(1));
      expect(events.first.instanceIndex, 2);
      expect(events.first.instanceColorHex, 0xFFEC4899);
    });

    test('Coupled Scan #N and Focus #N share battle state per slot while multiple instances isolate cleanly', () async {
      final source = _FakeCoupledMultiSource();
      final coord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
          PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
          PokemonMatcherEntry(id: 497, name: 'Serpiroyal', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
        encounterCooldown: const Duration(milliseconds: 5),
      );
      addTearDown(() async {
        await coord.dispose();
        await source.dispose();
      });

      final emitted = <ScannerEvent>[];
      coord.events.listen(emitted.add);
      coord.bindSource(source);

      // 1. Focus #2 detects Flampion -> BEGEGNUNG #2
      source.emitMulti(const MultiInstanceTextEmission(
        slotId: 2,
        colorHex: 0xFFA855F7,
        rawText: 'Flampion Lv.15',
        encounterOnly: true,
      ));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted, hasLength(1));
      expect(emitted.last.instanceIndex, 2);
      expect(emitted.last.type, ScannerEventType.encounter);
      expect(emitted.last.pokemonId, 554);

      // 2. Scan #2 sees battle prompt ("Was soll Serpiroyal tun?") -> suppressed
      source.emitMulti(const MultiInstanceTextEmission(
        slotId: 2,
        colorHex: 0xFFA855F7,
        rawText: 'Was soll Serpiroyal tun?',
        encounterOnly: false,
      ));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted, hasLength(1));

      // 3. Focus #3 (independent instance) detects Zurrokex -> BEGEGNUNG #3 cleanly
      source.emitMulti(const MultiInstanceTextEmission(
        slotId: 3,
        colorHex: 0xFFEC4899,
        rawText: 'Zurrokex Lv.16',
        encounterOnly: true,
      ));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted, hasLength(2));
      expect(emitted.last.instanceIndex, 3);
      expect(emitted.last.pokemonId, 559);

      // 4. Focus #2 re-reads Flampion in same battle -> deduplicated by slot #2 active battle
      source.emitMulti(const MultiInstanceTextEmission(
        slotId: 2,
        colorHex: 0xFFA855F7,
        rawText: 'Flampion Lv.15',
        encounterOnly: true,
      ));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted, hasLength(2));

      // 5. Scan #2 catches Flampion -> emits FANG #2 without blocked by encounter cooldown
      source.emitMulti(const MultiInstanceTextEmission(
        slotId: 2,
        colorHex: 0xFFA855F7,
        rawText: 'Flampion wurde gefangen!',
        encounterOnly: false,
      ));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted, hasLength(3));
      expect(emitted.last.instanceIndex, 2);
      expect(emitted.last.type, ScannerEventType.caught);
      expect(emitted.last.pokemonId, 554);
    });

    test('serializes concurrent processFrameText calls to prevent duplicate emissions', () async {
      final slowFeedback = _SlowTestFeedback();
      final concurrentCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'en'),
        ]),
        feedback: slowFeedback,
      );
      final emitted = <ScannerEvent>[];
      concurrentCoord.events.listen(emitted.add);

      final f1 = concurrentCoord.processFrameText('Wild Pikachu appeared!');
      final f2 = concurrentCoord.processFrameText('Wild Pikachu appeared!');
      await Future.wait([f1, f2]);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(emitted, hasLength(1));
      await concurrentCoord.dispose();
    });

    test('Smart battle set prevents re-emitting already seen species when one enemy faints or second enemy appears on next frame', () async {
      final battleCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 88, name: 'Sleima', language: 'de'),
          PokemonMatcherEntry(id: 41, name: 'Zubat', language: 'de'),
          PokemonMatcherEntry(id: 83, name: 'Porenta', language: 'de'),
        ]),
        settings: ScannerSettings.defaults(),
        encounterCooldown: const Duration(milliseconds: 5),
      );
      addTearDown(() async => await battleCoord.dispose());

      final feedEvents = <ScannerEvent>[];
      final focusBatches = <List<ScannerEvent>>[];
      battleCoord.events.listen(feedEvents.add);
      battleCoord.activeFocusStream.listen(focusBatches.add);

      // Frame 1: only Sleima recognized initially -> emits Sleima
      await battleCoord.processFrameText(
        'Sleima ♀ Lv.17',
        encounterOnly: true,
        allowMultiEncounter: true,
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(feedEvents.map((e) => e.pokemonId).toList(), [88]);
      expect(focusBatches.last.map((e) => e.pokemonId).toList(), [88]);

      // Frame 2: Sleima + Zubat both recognized -> only Zubat added to feed, focus has both
      await battleCoord.processFrameText(
        'Sleima ♀ Lv.17\nZubat ♂ Lv.15',
        encounterOnly: true,
        allowMultiEncounter: true,
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(feedEvents.map((e) => e.pokemonId).toList(), [88, 41]);
      expect(focusBatches.last.map((e) => e.pokemonId).toList(), [88, 41]);

      // Frame 3: Sleima faints -> only Zubat remains in HUD -> focus updates to [Zubat], ZERO duplicate feed spam!
      await battleCoord.processFrameText(
        'Zubat ♂ Lv.15',
        encounterOnly: true,
        allowMultiEncounter: true,
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(feedEvents.map((e) => e.pokemonId).toList(), [88, 41]);
      expect(focusBatches.last.map((e) => e.pokemonId).toList(), [41]);

      // Battle ends -> new horde battle aggregates Zubat x3 + Porenta x1
      await battleCoord.processFrameText('Du bist erfolgreich geflohen!');
      await battleCoord.processFrameText(
        'Zubat Lv.7\nZubat Lv.7\nZubat Lv.7\nPorenta Lv.8',
        encounterOnly: true,
        allowMultiEncounter: true,
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(focusBatches.last, hasLength(2));
      expect(focusBatches.last[0].pokemonId, 41);
      expect(focusBatches.last[0].encounterCount, 3);
      expect(focusBatches.last[1].pokemonId, 83);
      expect(focusBatches.last[1].encounterCount, 1);
    });

    test('20-minute smart battle-refresh suppresses duplicates across >3 min battles without re-triggering', () async {
      expect(ScannerCoordinator.battleTimeout, const Duration(minutes: 20));

      var fakeElapsed = Duration.zero;
      final timedCoord = ScannerCoordinator(
        engine: engine,
        matcher: matcher,
        settings: ScannerSettings.defaults(),
        feedback: feedback,
        encounterCooldown: Duration.zero,
        elapsedClock: () => fakeElapsed,
      );
      addTearDown(timedCoord.dispose);

      final emitted = <ScannerEvent>[];
      timedCoord.events.listen(emitted.add);

      // t = 0: encounter starts
      await timedCoord.processFrameText('Pikachu Lv.12', encounterOnly: true);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));

      // t = 2m: opponent still visible -> refreshes lastSeenAt
      fakeElapsed = const Duration(minutes: 2);
      await timedCoord.processFrameText('Pikachu Lv.12', encounterOnly: true);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));

      // t = 4m (past legacy 3-minute timeout!) -> STILL suppressed because t=2m refreshed lastSeenAt
      fakeElapsed = const Duration(minutes: 4);
      await timedCoord.processFrameText('Pikachu Lv.12', encounterOnly: true);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));

      // t = 18m (< 20m since t=4m) -> still active battle
      fakeElapsed = const Duration(minutes: 18);
      await timedCoord.processFrameText('Pikachu Lv.12', encounterOnly: true);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));

      // t = 40m (> 20m since t=18m) -> timeout expired -> fresh encounter emitted
      fakeElapsed = const Duration(minutes: 40);
      await timedCoord.processFrameText('Pikachu Lv.12', encounterOnly: true);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(2));
    });

    test('drop-oldest per-slot backpressure drops stale queued bursts while preserving latest frame', () async {
      final slowCoord = ScannerCoordinator(
        engine: engine,
        matcher: matcher,
        settings: ScannerSettings.defaults().copyWith(
          playAudioFeedback: true,
        ),
        feedback: _SlowTestFeedback(),
        encounterCooldown: Duration.zero,
      );
      addTearDown(slowCoord.dispose);

      final emitted = <ScannerEvent>[];
      slowCoord.events.listen(emitted.add);

      // Burst 12 encounter frames into the same slot while the first frame is blocked in slow feedback
      final futures = <Future<List<ScannerEvent>>>[];
      futures.add(slowCoord.processFrameText('Ein wildes Glumanda erscheint!', instanceIndex: 1));
      for (int i = 0; i < 10; i++) {
        futures.add(slowCoord.processFrameText('Ein wildes Glutexo erscheint!', instanceIndex: 1));
      }
      futures.add(slowCoord.processFrameText('Ein wildes Pikachu erscheint!', instanceIndex: 1));

      final results = await Future.wait(futures);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // First frame and final frame must complete cleanly; excess middle frames were dropped
      expect(results.first.map((e) => e.pokemonId), contains(4));
      expect(emitted.last.pokemonId, 25);
      expect(slowCoord.debugDroppedFramesCount, greaterThan(0));
    });

    test('setEffectiveOcrLanguage and settings.ocrLanguage scope matcher to active game language', () async {
      final langMatcher = PokemonFuzzyMatcher.withEntries(const [
        PokemonMatcherEntry(id: 541, name: 'Folikon', language: 'de'),
        PokemonMatcherEntry(id: 862, name: 'Barrikadax', language: 'de'),
        PokemonMatcherEntry(id: 862, name: 'Ixon', language: 'fr'),
      ]);
      final langCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: langMatcher,
        settings: ScannerSettings.defaults(),
        encounterCooldown: Duration.zero,
      );
      addTearDown(langCoord.dispose);

      langCoord.setEffectiveOcrLanguage('de');
      expect(langCoord.effectiveOcrLanguage, 'de');
      expect(langMatcher.activeLanguage, 'de');

      final emitted = <ScannerEvent>[];
      langCoord.events.listen(emitted.add);

      // Frame 1: clean Folikon encounter
      await langCoord.processFrameText('Folikon Lv.22', encounterOnly: true);
      // Frame 2: garbled Zone B text with 'ikon' (would previously false-match FR 'Ixon' at 75%)
      await langCoord.processFrameText(
        'Folik.on\n2-2\nmtmm\nF 011 ikon',
        encounterOnly: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.single.pokemonId, 541);
      expect(emitted.single.matchedName, 'Folikon');

      // Explicit settings override changes matcher language even if effectiveOcrLanguage stays 'de'
      langCoord.updateSettings(langCoord.settings.copyWith(ocrLanguage: 'fr'));
      expect(langMatcher.activeLanguage, 'fr');
    });

    test('Zone B resolves leetspeak split token "F 011 ikon" even without clean name line', () async {
      final hudMatcher = PokemonFuzzyMatcher.withEntries(const [
        PokemonMatcherEntry(id: 541, name: 'Folikon', language: 'de'),
        PokemonMatcherEntry(id: 862, name: 'Barrikadax', language: 'de'),
      ])
        ..setActiveLanguage('de');
      final hudCoord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: hudMatcher,
        settings: ScannerSettings.defaults(),
        encounterCooldown: Duration.zero,
      );
      addTearDown(hudCoord.dispose);

      final emitted = <ScannerEvent>[];
      hudCoord.events.listen(emitted.add);

      await hudCoord.processFrameText(
        '2-2\nmtmm\nF 011 ikon',
        encounterOnly: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.single.pokemonId, 541);
      expect(emitted.single.matchedName, 'Folikon');
    });

    test('bindSource catches processFrameText errors and applies slot customPatternFilter', () async {
      final throwingFeedback = _ThrowingFeedback();
      final source = _FakeCoupledMultiSource();
      final coord = ScannerCoordinator(
        engine: OcrDetectionEngine(),
        matcher: PokemonFuzzyMatcher.withEntries(const [
          PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
        ]),
        settings: const ScannerSettings(
          playAudioFeedback: true,
          customPatterns: [
            CustomOcrPattern(
              id: 'shiny_hunt:h1:trig_0',
              template: 'Custom Phrase {pokemon}',
              eventType: ScannerEventType.encounter,
            ),
            CustomOcrPattern(
              id: 'shiny_hunt:h2:trig_0',
              template: 'Custom Phrase {pokemon}',
              eventType: ScannerEventType.encounter,
            ),
          ],
        ),
        feedback: throwingFeedback,
        encounterCooldown: Duration.zero,
      );
      addTearDown(() async {
        await coord.dispose();
        await source.dispose();
      });

      coord.setSlotCustomPatternFilter(
        (slotId, patternId) =>
            slotId == 2 ? patternId.startsWith('shiny_hunt:h2:') : true,
      );

      final emitted = <ScannerEvent>[];
      coord.events.listen(emitted.add);

      // Slot 2 must match shiny_hunt:h2:trig_0, NOT be shadowed by shiny_hunt:h1:trig_0
      final evs = await coord.processFrameText(
        'Custom Phrase Pikachu',
        instanceIndex: 2,
      );
      expect(evs, hasLength(1));
      expect(evs.single.matchedCustomPatternId, 'shiny_hunt:h2:trig_0');

      // Error inside feedback via bindSource must not throw an unhandled zone error
      throwingFeedback.shouldThrow = true;
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        coord.bindSource(source);
        source.emitMulti(
          const MultiInstanceTextEmission(
            slotId: 2,
            colorHex: 0xFFA855F7,
            rawText: 'Custom Phrase Pikachu',
            encounterOnly: false,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (err, _) {
        uncaught.add(err);
      });
      expect(uncaught, isEmpty);
    });
  });
}

class _ThrowingFeedback implements ScannerFeedback {
  bool shouldThrow = false;
  @override
  Future<void> onCaught(ScannerEvent event) async {}
  @override
  Future<void> onEncounter(ScannerEvent event) async {
    if (shouldThrow) throw StateError('audio boom');
  }
  @override
  Future<void> onEvolved(ScannerEvent event) async {}
  @override
  Future<void> onShiny(ScannerEvent event) async {}
}

class _SlowTestFeedback implements ScannerFeedback {
  @override
  Future<void> onCaught(ScannerEvent event) async =>
      Future.delayed(const Duration(milliseconds: 25));

  @override
  Future<void> onEncounter(ScannerEvent event) async =>
      Future.delayed(const Duration(milliseconds: 25));

  @override
  Future<void> onEvolved(ScannerEvent event) async {}

  @override
  Future<void> onShiny(ScannerEvent event) async {}
}

class _FakeCoupledMultiSource implements MultiInstanceScannerSource {
  final _textCtrl = StreamController<String>.broadcast();
  final _multiCtrl = StreamController<MultiInstanceTextEmission>.broadcast();

  void emitMulti(MultiInstanceTextEmission emission) => _multiCtrl.add(emission);

  @override
  Stream<String> get textStream => _textCtrl.stream;

  @override
  Stream<MultiInstanceTextEmission> get multiInstanceTextStream => _multiCtrl.stream;

  @override
  bool get isRunning => true;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _textCtrl.close();
    await _multiCtrl.close();
  }
}
