import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../desktop_tracker/desktop_capture_driver.dart';

/// Pure-Dart BGRA8888 sub-frame cropper and contrast helper for multi-enemy Zone B HUDs.
class FrameBandCropper {
  FrameBandCropper._();

  static const int _isolateByteThreshold = 65536;

  /// Offloads [splitZoneBBands] to a background isolate via [TransferableTypedData]
  /// for large native frames (> 64 KB), keeping small frames and Web fast and synchronous.
  static Future<List<CapturedFrame>> splitZoneBBandsAsync(
    CapturedFrame frame,
  ) async {
    if (kIsWeb || frame.bytes.length <= _isolateByteThreshold) {
      return splitZoneBBands(frame);
    }
    final width = frame.width;
    final height = frame.height;
    final pixelFormat = frame.pixelFormat;
    final captureMethod = frame.captureMethod;
    final rawTransfer = TransferableTypedData.fromList([
      Uint8List.fromList(frame.bytes),
    ]);

    final packed = await Isolate.run(() {
      final src = CapturedFrame(
        width: width,
        height: height,
        bytes: rawTransfer.materialize().asUint8List(),
        pixelFormat: pixelFormat,
        captureMethod: captureMethod,
      );
      final bands = splitZoneBBands(src);
      return [
        for (final b in bands)
          (
            width: b.width,
            height: b.height,
            bytes: TransferableTypedData.fromList([
              b.bytes is Uint8List
                  ? b.bytes as Uint8List
                  : Uint8List.fromList(b.bytes),
            ]),
            pixelFormat: b.pixelFormat,
            captureMethod: b.captureMethod,
          ),
      ];
    });

    return List.unmodifiable([
      for (final item in packed)
        CapturedFrame(
          width: item.width,
          height: item.height,
          bytes: item.bytes.materialize().asUint8List(),
          pixelFormat: item.pixelFormat,
          captureMethod: item.captureMethod,
        ),
    ]);
  }

  /// Offloads [invertLuminanceBgra] to a background isolate via [TransferableTypedData]
  /// for large native frames (> 64 KB).
  static Future<CapturedFrame?> invertLuminanceBgraAsync(
    CapturedFrame frame,
  ) async {
    if (kIsWeb || frame.bytes.length <= _isolateByteThreshold) {
      return invertLuminanceBgra(frame);
    }
    final width = frame.width;
    final height = frame.height;
    final pixelFormat = frame.pixelFormat;
    final captureMethod = frame.captureMethod;
    final rawTransfer = TransferableTypedData.fromList([
      frame.bytes is Uint8List
          ? frame.bytes as Uint8List
          : Uint8List.fromList(frame.bytes),
    ]);

    final packed = await Isolate.run(() {
      final src = CapturedFrame(
        width: width,
        height: height,
        bytes: rawTransfer.materialize().asUint8List(),
        pixelFormat: pixelFormat,
        captureMethod: captureMethod,
      );
      final inverted = invertLuminanceBgra(src);
      if (inverted == null) return null;
      return (
        width: inverted.width,
        height: inverted.height,
        bytes: TransferableTypedData.fromList([
          inverted.bytes is Uint8List
              ? inverted.bytes as Uint8List
              : Uint8List.fromList(inverted.bytes),
        ]),
        pixelFormat: inverted.pixelFormat,
        captureMethod: inverted.captureMethod,
      );
    });

    if (packed == null) return null;
    return CapturedFrame(
      width: packed.width,
      height: packed.height,
      bytes: packed.bytes.materialize().asUint8List(),
      pixelFormat: packed.pixelFormat,
      captureMethod: packed.captureMethod,
    );
  }

  /// Splits [frame] into overlapping vertical (top/bottom) and, when wide,
  /// horizontal (left/right) sub-bands so stacked or side-by-side nameplates
  /// can be OCR'd cleanly if a single full-frame pass misses lines.
  static List<CapturedFrame> splitZoneBBands(CapturedFrame frame) {
    final w = frame.width;
    final h = frame.height;
    if (w < 24 || h < 24 || frame.pixelFormat != 'bgra8888') {
      return const [];
    }
    final expectedBytes = w * h * 4;
    if (frame.bytes.length < expectedBytes) {
      return const [];
    }

    final bands = <CapturedFrame>[];

    // Overlapping vertical bands (top 58% and bottom 58%) for stacked DS/3DS HUDs
    if (h >= 40) {
      final bandH = ((h * 0.58).round()).clamp(20, h);
      final topBand = _cropBgra(frame, x: 0, y: 0, width: w, height: bandH);
      final bottomBand = _cropBgra(
        frame,
        x: 0,
        y: h - bandH,
        width: w,
        height: bandH,
      );
      if (topBand != null) bands.add(topBand);
      if (bottomBand != null) bands.add(bottomBand);
    }

    // Overlapping horizontal bands when Zone B is a wide banner/strip
    if (w >= 120 && w >= h * 1.45) {
      final bandW = ((w * 0.58).round()).clamp(40, w);
      final leftBand = _cropBgra(frame, x: 0, y: 0, width: bandW, height: h);
      final rightBand = _cropBgra(
        frame,
        x: w - bandW,
        y: 0,
        width: bandW,
        height: h,
      );
      if (leftBand != null) bands.add(leftBand);
      if (rightBand != null) bands.add(rightBand);
    }

    return List.unmodifiable(bands);
  }

  /// Creates an inverted-luminance copy of a BGRA8888 [frame] so white-on-dark
  /// nameplates (e.g. modern Switch/3DS HUDs) read cleanly through dark-on-light OCR.
  static CapturedFrame? invertLuminanceBgra(CapturedFrame frame) {
    final w = frame.width;
    final h = frame.height;
    if (w <= 0 || h <= 0 || frame.pixelFormat != 'bgra8888') return null;
    final expectedBytes = w * h * 4;
    if (frame.bytes.length < expectedBytes) return null;

    final src = frame.bytes;
    final out = Uint8List(expectedBytes);
    for (int i = 0; i < expectedBytes; i += 4) {
      out[i] = 255 - src[i];
      out[i + 1] = 255 - src[i + 1];
      out[i + 2] = 255 - src[i + 2];
      out[i + 3] = 255;
    }
    return CapturedFrame(
      width: w,
      height: h,
      bytes: out,
      pixelFormat: frame.pixelFormat,
      captureMethod: frame.captureMethod,
    );
  }

  /// Extracts a sub-rectangle `[x, y, width, height]` from a BGRA8888 [frame],
  /// clamping coordinates safely within bounds and returning `null` if invalid.
  static CapturedFrame? cropRectBgra(
    CapturedFrame frame, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final srcW = frame.width;
    final srcH = frame.height;
    if (srcW <= 0 ||
        srcH <= 0 ||
        width <= 0 ||
        height <= 0 ||
        frame.pixelFormat != 'bgra8888') {
      return null;
    }
    final expectedBytes = srcW * srcH * 4;
    if (frame.bytes.length < expectedBytes) {
      return null;
    }
    return _cropBgra(frame, x: x, y: y, width: width, height: height);
  }

  static CapturedFrame? _cropBgra(
    CapturedFrame frame, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final srcW = frame.width;
    final srcH = frame.height;
    final clampedX = x.clamp(0, srcW - 1);
    final clampedY = y.clamp(0, srcH - 1);
    final clampedW = width.clamp(1, srcW - clampedX);
    final clampedH = height.clamp(1, srcH - clampedY);
    if (clampedW <= 0 || clampedH <= 0) return null;

    final out = Uint8List(clampedW * clampedH * 4);
    final srcBytes = frame.bytes;
    final srcStride = srcW * 4;
    final dstStride = clampedW * 4;

    for (int row = 0; row < clampedH; row++) {
      final srcOff = (clampedY + row) * srcStride + clampedX * 4;
      final dstOff = row * dstStride;
      out.setRange(dstOff, dstOff + dstStride, srcBytes, srcOff);
    }

    return CapturedFrame(
      width: clampedW,
      height: clampedH,
      bytes: out,
      pixelFormat: frame.pixelFormat,
      captureMethod: frame.captureMethod,
    );
  }
}
