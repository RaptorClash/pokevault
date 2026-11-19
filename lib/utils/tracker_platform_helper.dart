import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;

/// Central platform capability guard separating Desktop Overlay Tracker (Windows)
/// and Camera/Webcam Tracker (Android, iOS, Windows, Linux, macOS, Web).
class TrackerPlatformHelper {
  const TrackerPlatformHelper._();

  /// Optional test overrides for deterministic platform gating tests.
  @visibleForTesting
  static bool Function()? debugIsDesktopOverride;

  @visibleForTesting
  static bool Function()? debugIsMobileOverride;

  @visibleForTesting
  static bool Function()? debugIsWebOverride;

  @visibleForTesting
  static bool Function()? debugOverlaySupportedOverride;

  @visibleForTesting
  static bool Function()? debugCameraSupportedOverride;

  @visibleForTesting
  static void resetDebugOverrides() {
    debugIsDesktopOverride = null;
    debugIsMobileOverride = null;
    debugIsWebOverride = null;
    debugOverlaySupportedOverride = null;
    debugCameraSupportedOverride = null;
  }

  /// True when running inside a web browser (`kIsWeb`).
  static bool get isWeb {
    final override = debugIsWebOverride;
    if (override != null) return override();
    return kIsWeb;
  }

  /// True on desktop operating systems (Windows, macOS, Linux).
  static bool get isDesktop {
    final override = debugIsDesktopOverride;
    if (override != null) return override();
    if (isWeb) return false;
    return io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS;
  }

  /// True on mobile operating systems (Android, iOS).
  static bool get isMobile {
    final override = debugIsMobileOverride;
    if (override != null) return override();
    if (isWeb) return false;
    return io.Platform.isAndroid || io.Platform.isIOS;
  }

  /// True where the native Desktop Overlay Tracker (Win32 HUD + window/monitor snipping) is supported.
  static bool get isDesktopOverlaySupported {
    final override = debugOverlaySupportedOverride;
    if (override != null) return override();
    if (isWeb) return false;
    return io.Platform.isWindows;
  }

  /// True on all platforms offering live Hardware-Camera / Webcam / Photo scanning
  /// (Android, iOS, Windows, Linux, macOS, and Web).
  static bool get isCameraTrackerSupported {
    final override = debugCameraSupportedOverride;
    if (override != null) return override();
    if (isWeb) return true;
    return isMobile || isDesktop;
  }
}
