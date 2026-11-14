import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../desktop_tracker/desktop_capture_driver.dart';

/// Platform-agnostic image byte decoder converting PNG/JPG/WebP/BMP photos or screenshots
/// into raw BGRA8888 [CapturedFrame] payloads for OCR preprocessing and testing.
class ImageFrameDecoder {
  static Future<CapturedFrame?> decodeBytesToBgraFrame(
    Uint8List encodedBytes, {
    String captureMethod = 'photo_file',
  }) async {
    if (encodedBytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(encodedBytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = image.width;
      final height = image.height;
      image.dispose();
      codec.dispose();
      if (byteData == null || width <= 0 || height <= 0) return null;

      final rgba = byteData.buffer.asUint8List();
      final bgra = Uint8List(rgba.length);
      for (int i = 0; i + 3 < rgba.length; i += 4) {
        bgra[i] = rgba[i + 2]; // B
        bgra[i + 1] = rgba[i + 1]; // G
        bgra[i + 2] = rgba[i]; // R
        bgra[i + 3] = rgba[i + 3]; // A
      }

      return CapturedFrame(
        width: width,
        height: height,
        bytes: bgra,
        pixelFormat: 'bgra8888',
        captureMethod: captureMethod,
      );
    } catch (_) {
      return null;
    }
  }
}
