import 'dart:async';
import 'dart:typed_data';
import '../desktop_tracker/desktop_capture_driver.dart';

/// Manages camera frame acquisition with live streaming as the primary path and
/// automatic `takePicture` timer polling fallback (for Web / non-streaming desktop backends).
class CameraFramePump {
  final Future<void> Function() startImageStream;
  final Future<void> Function() stopImageStream;
  final Future<Uint8List?> Function() captureStillBytes;
  final Future<CapturedFrame?> Function(Uint8List bytes) decodeStillFrame;
  final Future<void> Function(CapturedFrame frame) onDecodedFrame;
  final Duration pollInterval;
  final bool forcePollingFallback;

  bool _isRunning = false;
  bool _isDisposed = false;
  bool _isUsingPollingFallback = false;
  bool _streamActive = false;
  bool _pollInFlight = false;
  Timer? _pollTimer;

  CameraFramePump({
    required this.startImageStream,
    required this.stopImageStream,
    required this.captureStillBytes,
    required this.decodeStillFrame,
    required this.onDecodedFrame,
    this.pollInterval = const Duration(milliseconds: 450),
    this.forcePollingFallback = false,
  });

  bool get isRunning => _isRunning;
  bool get isUsingPollingFallback => _isUsingPollingFallback;

  Future<void> start() async {
    if (_isDisposed) return;
    _isRunning = true;

    if (!forcePollingFallback && !_isUsingPollingFallback) {
      try {
        await startImageStream();
        if (_isDisposed || !_isRunning) {
          await _safeStopStream();
          return;
        }
        _streamActive = true;
        return;
      } on UnimplementedError {
        _isUsingPollingFallback = true;
      } catch (_) {
        _isUsingPollingFallback = true;
      }
    } else {
      _isUsingPollingFallback = true;
    }

    _startPollTimer();
  }

  Future<void> pause() async {
    _isRunning = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_streamActive) {
      await _safeStopStream();
    }
  }

  Future<void> resume() async {
    if (_isDisposed || _isRunning) return;
    await start();
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _isRunning = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_streamActive) {
      await _safeStopStream();
    }
  }

  Future<void> _safeStopStream() async {
    _streamActive = false;
    try {
      await stopImageStream();
    } catch (_) {}
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    if (_isDisposed || !_isRunning) return;
    // Trigger an immediate first tick plus periodic ticks
    unawaited(_tickPoll());
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_tickPoll());
    });
  }

  Future<void> _tickPoll() async {
    if (_isDisposed || !_isRunning || _pollInFlight) return;
    _pollInFlight = true;
    try {
      final bytes = await captureStillBytes();
      if (_isDisposed || !_isRunning || bytes == null || bytes.isEmpty) {
        return;
      }
      final frame = await decodeStillFrame(bytes);
      if (_isDisposed || !_isRunning || frame == null) {
        return;
      }
      await onDecodedFrame(frame);
    } catch (_) {
      // Transient camera capture hiccups must not crash the scan loop
    } finally {
      _pollInFlight = false;
    }
  }
}
