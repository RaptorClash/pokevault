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
  });
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
