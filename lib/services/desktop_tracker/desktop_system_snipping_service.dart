import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;
import 'desktop_capture_driver.dart';

typedef ProcessRunner = Future<io.ProcessResult> Function(String exe, List<String> args);
typedef ClipboardBytesProvider = Future<Uint8List?> Function();
typedef DimensionDecoder = Future<({int width, int height})?> Function(Uint8List bytes);

/// Service providing system-wide desktop snipping via Windows native Snipping Tool (Win+Shift+S)
/// and direct clipboard image integration for PokéVault's Desktop Tracker.
class DesktopSystemSnippingService {
  final ProcessRunner? processRunner;
  final ClipboardBytesProvider? clipboardBytesProvider;
  final DimensionDecoder? dimensionDecoder;

  static DesktopSystemSnippingService? _instance;
  static DesktopSystemSnippingService get instance => _instance ??= DesktopSystemSnippingService();

  DesktopSystemSnippingService({
    this.processRunner,
    this.clipboardBytesProvider,
    this.dimensionDecoder,
  });

  /// Triggers the native Windows Screen Snipping overlay (`ms-screenclip:` / Win+Shift+S).
  /// This opens the system crosshairs over the entire multi-monitor desktop.
  Future<bool> triggerWindowsScreenclip() async {
    try {
      if (processRunner != null) {
        final res = await processRunner!('cmd', ['/c', 'start', 'ms-screenclip:']);
        return res.exitCode == 0;
      }

      if (!kIsWeb && io.Platform.isWindows && !io.Platform.environment.containsKey('FLUTTER_TEST')) {
        final res = await io.Process.run('cmd', ['/c', 'start', 'ms-screenclip:']);
        return res.exitCode == 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves the raw image bytes from the Windows system clipboard if an image is present.
  Future<Uint8List?> getClipboardImageBytes() async {
    try {
      if (clipboardBytesProvider != null) {
        return await clipboardBytesProvider!();
      }

      if (!kIsWeb && io.Platform.isWindows && !io.Platform.environment.containsKey('FLUTTER_TEST')) {
        final tempDir = io.Platform.environment['TEMP'] ?? io.Directory.systemTemp.path;
        final outPath = '$tempDir\\pv_clipboard_${DateTime.now().millisecondsSinceEpoch}.png';

        final script = '''
Add-Type -AssemblyName System.Windows.Forms,System.Drawing;
\$img = [System.Windows.Forms.Clipboard]::GetImage();
if (\$img) {
  \$img.Save('$outPath', [System.Drawing.Imaging.ImageFormat]::Png);
  \$img.Dispose();
  Write-Host "OK";
} else {
  Write-Host "EMPTY";
}
''';

        final result = await io.Process.run(
          'powershell',
          ['-Sta', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
        ).timeout(const Duration(seconds: 4));

        if (result.exitCode == 0 && result.stdout.toString().contains('OK')) {
          final file = io.File(outPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            try {
              await file.delete();
            } catch (_) {}
            return bytes;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Decodes image dimensions (width, height) from PNG/JPEG bytes.
  Future<({int width, int height})?> _decodeDimensions(Uint8List bytes) async {
    if (dimensionDecoder != null) {
      return await dimensionDecoder!(bytes);
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      return (width: width, height: height);
    } catch (_) {
      return null;
    }
  }

  /// Grabs the desktop screenshot from the clipboard and returns a ready-to-use [CapturedFrame].
  Future<CapturedFrame?> captureDesktopSnippet() async {
    try {
      final bytes = await getClipboardImageBytes();
      if (bytes == null || bytes.isEmpty) return null;

      final dims = await _decodeDimensions(bytes);
      if (dims == null || dims.width <= 0 || dims.height <= 0) return null;

      return CapturedFrame(
        width: dims.width,
        height: dims.height,
        bytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }
}
