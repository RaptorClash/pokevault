import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import '../desktop_tracker/desktop_capture_driver.dart';
import '../scanner_core/models/scanner_settings.dart';
import 'camera_scan_region.dart';

/// Pure-Dart image conversion, orientation, preview-to-frame ROI mapping,
/// strict pixel cropping, and display-glare preprocessing for mobile camera frames.
class CameraFrameProcessor {
  CameraFrameProcessor._();

  /// Converts Android/iOS YUV420 planes into an upright BGRA8888 [CapturedFrame].
  static CapturedFrame? convertYuv420ToBgraFrame({
    required int width,
    required int height,
    required Uint8List yBytes,
    required Uint8List uBytes,
    required Uint8List vBytes,
    required int yRowStride,
    required int uvRowStride,
    required int uvPixelStride,
    int sensorOrientation = 0,
    String captureMethod = 'mobile_camera_yuv',
  }) {
    if (width <= 0 || height <= 0) return null;
    if (yBytes.isEmpty || uBytes.isEmpty || vBytes.isEmpty) return null;

    final rgbaBgra = Uint8List(width * height * 4);
    for (int y = 0; y < height; y++) {
      final yRowOffset = y * yRowStride;
      final uvRowOffset = (y >> 1) * uvRowStride;
      for (int x = 0; x < width; x++) {
        final yIdx = yRowOffset + x;
        final uvIdx = uvRowOffset + (x >> 1) * uvPixelStride;
        if (yIdx >= yBytes.length ||
            uvIdx >= uBytes.length ||
            uvIdx >= vBytes.length) {
          continue;
        }
        final yVal = yBytes[yIdx];
        final uVal = uBytes[uvIdx];
        final vVal = vBytes[uvIdx];

        final c = yVal - 16;
        final d = uVal - 128;
        final e = vVal - 128;

        final r = ((298 * c + 409 * e + 128) >> 8).clamp(0, 255);
        final g = ((298 * c - 100 * d - 208 * e + 128) >> 8).clamp(0, 255);
        final b = ((298 * c + 516 * d + 128) >> 8).clamp(0, 255);

        final outIdx = (y * width + x) * 4;
        rgbaBgra[outIdx] = b;
        rgbaBgra[outIdx + 1] = g;
        rgbaBgra[outIdx + 2] = r;
        rgbaBgra[outIdx + 3] = 255;
      }
    }

    final baseFrame = CapturedFrame(
      width: width,
      height: height,
      bytes: rgbaBgra,
      pixelFormat: 'bgra8888',
      captureMethod: captureMethod,
    );
    return rotateBgraFrame(baseFrame, sensorOrientation);
  }

  /// Rotates a BGRA8888 [CapturedFrame] clockwise by 0, 90, 180, or 270 degrees.
  static CapturedFrame rotateBgraFrame(CapturedFrame frame, int degrees) {
    final norm = ((degrees % 360) + 360) % 360;
    if (norm == 0 ||
        frame.width <= 0 ||
        frame.height <= 0 ||
        frame.pixelFormat != 'bgra8888') {
      return frame;
    }

    final srcW = frame.width;
    final srcH = frame.height;
    final src = frame.bytes;
    if (src.length < srcW * srcH * 4) return frame;

    final swap = norm == 90 || norm == 270;
    final dstW = swap ? srcH : srcW;
    final dstH = swap ? srcW : srcH;
    final dst = Uint8List(dstW * dstH * 4);

    for (int sy = 0; sy < srcH; sy++) {
      for (int sx = 0; sx < srcW; sx++) {
        int dx;
        int dy;
        switch (norm) {
          case 90:
            dx = srcH - 1 - sy;
            dy = sx;
            break;
          case 180:
            dx = srcW - 1 - sx;
            dy = srcH - 1 - sy;
            break;
          case 270:
            dx = sy;
            dy = srcW - 1 - sx;
            break;
          default:
            dx = sx;
            dy = sy;
        }
        final sOff = (sy * srcW + sx) * 4;
        final dOff = (dy * dstW + dx) * 4;
        dst[dOff] = src[sOff];
        dst[dOff + 1] = src[sOff + 1];
        dst[dOff + 2] = src[sOff + 2];
        dst[dOff + 3] = src[sOff + 3];
      }
    }

    return CapturedFrame(
      width: dstW,
      height: dstH,
      bytes: dst,
      pixelFormat: 'bgra8888',
      captureMethod: frame.captureMethod,
    );
  }

  /// Maps a rectangle drawn in camera preview widget coordinates into normalized `[0..1]`
  /// frame coordinates, compensating for [BoxFit.cover] / [BoxFit.contain] letterboxing or cropping.
  static Rect mapWidgetRectToNormalized({
    required Rect widgetRect,
    required Size widgetSize,
    required Size frameSize,
    BoxFit fit = BoxFit.cover,
  }) {
    if (widgetSize.width <= 0 ||
        widgetSize.height <= 0 ||
        frameSize.width <= 0 ||
        frameSize.height <= 0) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }

    final fitted = applyBoxFit(fit, frameSize, widgetSize);
    final sourceSize = fitted.source;
    final destSize = fitted.destination;
    final srcDx = (frameSize.width - sourceSize.width) / 2.0;
    final srcDy = (frameSize.height - sourceSize.height) / 2.0;
    final dstDx = (widgetSize.width - destSize.width) / 2.0;
    final dstDy = (widgetSize.height - destSize.height) / 2.0;

    final scaleX = destSize.width / sourceSize.width;
    final scaleY = destSize.height / sourceSize.height;
    if (scaleX <= 0 || scaleY <= 0) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }

    final frameLeft =
        (srcDx + (widgetRect.left - dstDx) / scaleX).clamp(0.0, frameSize.width);
    final frameTop =
        (srcDy + (widgetRect.top - dstDy) / scaleY).clamp(0.0, frameSize.height);
    final frameRight =
        (srcDx + (widgetRect.right - dstDx) / scaleX).clamp(0.0, frameSize.width);
    final frameBottom =
        (srcDy + (widgetRect.bottom - dstDy) / scaleY).clamp(0.0, frameSize.height);

    final normL = (frameLeft / frameSize.width).clamp(0.0, 1.0);
    final normT = (frameTop / frameSize.height).clamp(0.0, 1.0);
    final normR = (frameRight / frameSize.width).clamp(normL, 1.0);
    final normB = (frameBottom / frameSize.height).clamp(normT, 1.0);

    return Rect.fromLTRB(normL, normT, normR, normB);
  }

  /// Strictly crops a BGRA8888 [CapturedFrame] to the pixel bounds of [region],
  /// guaranteeing no text outside the drawn rectangle leaks into OCR.
  static CapturedFrame? cropFrameToNormalizedRect(
    CapturedFrame frame,
    NormalizedScanRect region,
  ) {
    if (frame.width <= 0 ||
        frame.height <= 0 ||
        frame.pixelFormat != 'bgra8888') {
      return null;
    }
    final expectedLen = frame.width * frame.height * 4;
    if (frame.bytes.length < expectedLen) return null;

    final x0 = (region.left * frame.width).floor().clamp(0, frame.width - 1);
    final y0 = (region.top * frame.height).floor().clamp(0, frame.height - 1);
    final cropW = math.max(
      1,
      math.min(frame.width - x0, (region.width * frame.width).round()),
    );
    final cropH = math.max(
      1,
      math.min(frame.height - y0, (region.height * frame.height).round()),
    );

    final out = Uint8List(cropW * cropH * 4);
    final src = frame.bytes;
    final rowBytes = cropW * 4;
    for (int row = 0; row < cropH; row++) {
      final srcStart = ((y0 + row) * frame.width + x0) * 4;
      final dstStart = row * rowBytes;
      out.setRange(dstStart, dstStart + rowBytes, src, srcStart);
    }

    return CapturedFrame(
      width: cropW,
      height: cropH,
      bytes: out,
      pixelFormat: 'bgra8888',
      captureMethod: '${frame.captureMethod ?? 'camera'}_roi',
    );
  }

  /// Applies contrast/luminance preprocessing suited to photographed LCD/OLED displays.
  static CapturedFrame applyPreprocessProfile(
    CapturedFrame frame,
    OcrPreprocessProfile profile,
  ) {
    if (profile == OcrPreprocessProfile.standard ||
        frame.width <= 0 ||
        frame.height <= 0 ||
        frame.bytes.isEmpty ||
        frame.pixelFormat != 'bgra8888') {
      return frame;
    }

    final bytes = Uint8List.fromList(frame.bytes);
    final pixelCount = frame.width * frame.height;
    if (bytes.length < pixelCount * 4) return frame;

    // Sample luminance min/max to stretch washed-out camera display contrast
    int minLuma = 255;
    int maxLuma = 0;
    final step = pixelCount > 4000 ? pixelCount ~/ 2000 : 1;
    for (int p = 0; p < pixelCount; p += step) {
      final off = p * 4;
      final luma =
          (bytes[off + 2] * 299 + bytes[off + 1] * 587 + bytes[off] * 114) ~/
              1000;
      if (luma < minLuma) minLuma = luma;
      if (luma > maxLuma) maxLuma = luma;
    }

    final span = maxLuma - minLuma;
    if (span < 8) return frame;

    final contrastBoost =
        profile == OcrPreprocessProfile.pixelArtDs ? 1.25 : 1.15;

    for (int i = 0; i + 3 < bytes.length; i += 4) {
      for (int c = 0; c < 3; c++) {
        final stretched = ((bytes[i + c] - minLuma) * 255.0) / span;
        final boosted = ((stretched - 128.0) * contrastBoost) + 128.0;
        bytes[i + c] = boosted.round().clamp(0, 255);
      }
    }

    return CapturedFrame(
      width: frame.width,
      height: frame.height,
      bytes: bytes,
      pixelFormat: frame.pixelFormat,
      captureMethod: frame.captureMethod,
    );
  }

  /// Converts a BGRA8888 [CapturedFrame] to NV21 (`Y` plane followed by interleaved `VU` chroma)
  /// required by Android Google ML Kit `InputImage.fromBytes`.
  static Uint8List bgraToNv21(CapturedFrame frame) {
    final w = frame.width;
    final h = frame.height;
    if (w <= 0 || h <= 0 || frame.bytes.length < w * h * 4) {
      return Uint8List(0);
    }
    final frameSize = w * h;
    final nv21 = Uint8List(frameSize + (w * h ~/ 2));
    int yIndex = 0;
    int uvIndex = frameSize;

    for (int j = 0; j < h; j++) {
      for (int i = 0; i < w; i++) {
        final off = (j * w + i) * 4;
        final b = frame.bytes[off];
        final g = frame.bytes[off + 1];
        final r = frame.bytes[off + 2];

        final y = (((66 * r + 129 * g + 25 * b + 128) >> 8) + 16).clamp(0, 255);
        nv21[yIndex++] = y;

        if ((j & 1) == 0 && (i & 1) == 0 && uvIndex + 1 < nv21.length) {
          final u = (((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128).clamp(0, 255);
          final v = (((112 * r - 94 * g - 18 * b + 128) >> 8) + 128).clamp(0, 255);
          nv21[uvIndex++] = v;
          nv21[uvIndex++] = u;
        }
      }
    }
    return nv21;
  }
}
