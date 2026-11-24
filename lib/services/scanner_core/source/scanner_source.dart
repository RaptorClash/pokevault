import 'dart:async';
import '../media/frame_transition_detector.dart';

/// Abstract source providing OCR text stream from cameras, screen-capture, or test mocks.
abstract class ScannerSource {
  Stream<String> get textStream;
  Future<void> start();
  Future<void> stop();
  bool get isRunning;
  Future<void> dispose();
}

/// Optional extension for capture sources that provide a dedicated opponent-HUD
/// stream (`focusTextStream`) in addition to the dialogue/catch stream (`textStream`).
abstract interface class DualZoneScannerSource implements ScannerSource {
  Stream<String> get focusTextStream;
}

/// Tagged OCR text emission from one numbered Multi-Instance desktop slot.
class MultiInstanceTextEmission {
  final int slotId;
  final int colorHex;
  final String rawText;
  final bool encounterOnly;

  const MultiInstanceTextEmission({
    required this.slotId,
    required this.colorHex,
    required this.rawText,
    this.encounterOnly = false,
  });
}

/// Optional extension for capture sources emitting slot-tagged multi-instance OCR frames.
abstract interface class MultiInstanceScannerSource implements ScannerSource {
  Stream<MultiInstanceTextEmission> get multiInstanceTextStream;
}

/// Optional extension for capture sources emitting luminance-based black/white transitions.
abstract interface class FrameTransitionScannerSource implements ScannerSource {
  Stream<FrameTransitionEvent> get transitionStream;
  void updateTransitionMinDuration(Duration duration);
  void updateTransitionThresholds({
    required int blackThreshold,
    required int whiteThreshold,
  });
}

/// In-memory mock scanner source for unit tests and simulations.
class MockScannerSource implements ScannerSource {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _running = false;

  @override
  Stream<String> get textStream => _controller.stream;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }

  /// Emits text into the stream if running (or directly for manual testing).
  void emitText(String text) {
    if (!_controller.isClosed) {
      _controller.add(text);
    }
  }

  @override
  Future<void> dispose() async {
    _running = false;
    await _controller.close();
  }
}
