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
  });
}
