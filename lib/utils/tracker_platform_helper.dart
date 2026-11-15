import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;

/// Central platform capability guard separating Desktop Tracker (Windows/Linux/macOS)
/// from Mobile Camera Tracker (Android/iOS).
class TrackerPlatformHelper {
  TrackerPlatformHelper._();

  @visibleForTesting
  static bool Function()? debugIsDesktopOverride;

  @visibleForTesting
  static bool Function()? debugIsMobileOverride;

  /// Resets test overrides back to real platform detection.
  @visibleForTesting
  static void resetDebugOverrides() {
    debugIsDesktopOverride = null;
    debugIsMobileOverride = null;
  }

  /// True on Windows, Linux, and macOS (never on web, Android, or iOS).
  static bool get isDesktop {
    final override = debugIsDesktopOverride;
    if (override != null) return override();
    if (kIsWeb) return false;
    return io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS;
  }

  /// True on Android and iOS (never on web or desktop).
  static bool get isMobile {
    final override = debugIsMobileOverride;
    if (override != null) return override();
    if (kIsWeb) return false;
    return io.Platform.isAndroid || io.Platform.isIOS;
  }
}
