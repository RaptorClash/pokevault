import 'dart:async';
import 'dart:ui';
import '../scanner_core/source/scanner_source.dart';
import 'desktop_capture_driver.dart';
import 'desktop_ocr_driver.dart';
import 'window_detector.dart';

/// Periodic window capture source that grabs frames from a chosen desktop window,
/// crops the dialogue/textbox area, runs local OCR, and feeds the stream to [ScannerCoordinator].
class DesktopWindowSource implements ScannerSource {
  final DesktopCaptureDriver captureDriver;
  final DesktopOcrDriver ocrDriver;
  final Duration pollInterval;

  DesktopWindowInfo? _selectedWindow;
  Rect? _cropRegion;
  Timer? _pollTimer;
  bool _running = false;

  final StreamController<String> _textController =
      StreamController<String>.broadcast();

  DesktopWindowSource({
    required this.captureDriver,
    required this.ocrDriver,
    this.pollInterval = const Duration(milliseconds: 1200),
  });

  @override
  Stream<String> get textStream => _textController.stream;

  @override
  bool get isRunning => _running;

  DesktopWindowInfo? get selectedWindow => _selectedWindow;

  Rect? get cropRegion => _cropRegion;

  /// Selects the target window to monitor. If cropRegion is not set, defaults
  /// to the lower dialogue region.
  void setSelectedWindow(DesktopWindowInfo? window) {
    _selectedWindow = window;
    if (window != null && _cropRegion == null) {
      _cropRegion = WindowDetector().calculateDefaultDialogueRegion(
        windowWidth: window.width,
        windowHeight: window.height,
      );
    }
  }

  void setCropRegion(Rect? region) {
    _cropRegion = region;
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollOnce());
  }

  @override
  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    final window = _selectedWindow;
    if (window == null || !_running) return;

    try {
      final frame = await captureDriver.captureWindow(
        window: window,
        cropRegion: _cropRegion,
      );

      if (frame != null) {
        final recognizedLines = await ocrDriver.recognizeText(frame);
        for (final line in recognizedLines) {
          if (line.trim().isNotEmpty) {
            _textController.add(line.trim());
          }
        }
      }
    } catch (_) {
      // Ignore transient capture or OCR errors during window resize or minimization
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _textController.close();
  }
}
