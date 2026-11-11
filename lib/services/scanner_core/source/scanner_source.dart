import 'dart:async';

/// Abstract source providing OCR text stream from cameras, screen-capture, or test mocks.
abstract class ScannerSource {
  Stream<String> get textStream;
  Future<void> start();
  Future<void> stop();
  bool get isRunning;
  Future<void> dispose();
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
