import 'dart:ui';
import 'window_detector.dart';

/// Represents a captured video/screen frame.
class CapturedFrame {
  final int width;
  final int height;
  final List<int> bytes;

  const CapturedFrame({
    required this.width,
    required this.height,
    required this.bytes,
  });
}

/// Abstract contract for grabbing screen or window pixels on desktop.
abstract class DesktopCaptureDriver {
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
  });
}

/// Default desktop capture driver with native window capture hook and graceful fallback.
class DefaultDesktopCaptureDriver implements DesktopCaptureDriver {
  final Future<CapturedFrame?> Function(DesktopWindowInfo window, Rect? cropRegion)?
      nativeCaptureHandler;

  const DefaultDesktopCaptureDriver({this.nativeCaptureHandler});

  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
  }) async {
    if (nativeCaptureHandler != null) {
      return await nativeCaptureHandler!(window, cropRegion);
    }
    // Fallback: Returns null if no native capture handler is bound in current environment
    return null;
  }
}
