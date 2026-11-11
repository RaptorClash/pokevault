import '../models/scanner_event.dart';

/// Abstract feedback handler for audio signals and haptic vibration.
abstract class ScannerFeedback {
  Future<void> onEncounter(ScannerEvent event);
  Future<void> onCaught(ScannerEvent event);
  Future<void> onEvolved(ScannerEvent event);
  Future<void> onShiny(ScannerEvent event);
}

/// Silent no-op feedback handler for headless tracking and test suites.
class SilentScannerFeedback implements ScannerFeedback {
  const SilentScannerFeedback();

  @override
  Future<void> onCaught(ScannerEvent event) async {}

  @override
  Future<void> onEncounter(ScannerEvent event) async {}

  @override
  Future<void> onEvolved(ScannerEvent event) async {}

  @override
  Future<void> onShiny(ScannerEvent event) async {}
}

/// Default feedback handler supporting custom callbacks for sound effects and haptic triggers.
class DefaultScannerFeedback implements ScannerFeedback {
  final Future<void> Function(ScannerEvent)? onCaughtCallback;
  final Future<void> Function(ScannerEvent)? onEncounterCallback;
  final Future<void> Function(ScannerEvent)? onEvolvedCallback;
  final Future<void> Function(ScannerEvent)? onShinyCallback;

  const DefaultScannerFeedback({
    this.onCaughtCallback,
    this.onEncounterCallback,
    this.onEvolvedCallback,
    this.onShinyCallback,
  });

  @override
  Future<void> onCaught(ScannerEvent event) async {
    if (onCaughtCallback != null) {
      await onCaughtCallback!(event);
    }
  }

  @override
  Future<void> onEncounter(ScannerEvent event) async {
    if (onEncounterCallback != null) {
      await onEncounterCallback!(event);
    }
  }

  @override
  Future<void> onEvolved(ScannerEvent event) async {
    if (onEvolvedCallback != null) {
      await onEvolvedCallback!(event);
    }
  }

  @override
  Future<void> onShiny(ScannerEvent event) async {
    if (onShinyCallback != null) {
      await onShinyCallback!(event);
    }
  }
}
