import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/scanner_core/media/frame_band_cropper.dart';

void main() {
  group('FrameBandCropper Tests (TDD)', () {
    test('crops BGRA8888 frame into overlapping vertical top/bottom bands', () {
      const w = 100;
      const h = 80;
      final bytes = Uint8List(w * h * 4);
      // Mark top half blue=10, bottom half blue=220
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final off = (y * w + x) * 4;
          bytes[off] = y < 40 ? 10 : 220;
          bytes[off + 3] = 255;
        }
      }
      final frame = CapturedFrame(
        width: w,
        height: h,
        bytes: bytes,
        pixelFormat: 'bgra8888',
      );
      final bands = FrameBandCropper.splitZoneBBands(frame);

      expect(bands.length, greaterThanOrEqualTo(2));
      expect(bands[0].width, w);
      expect(bands[0].height, greaterThan(40));
      // Top band starts at y=0 (pixel 0 == 10)
      expect(bands[0].bytes[0], 10);
      // Bottom band ends at y=h-1 (last row == 220)
      final lastBand = bands[1];
      final lastPixelOff = (lastBand.height - 1) * lastBand.width * 4;
      expect(lastBand.bytes[lastPixelOff], 220);
    });

    test('adds horizontal left/right bands when frame aspect ratio is wide', () {
      const w = 240;
      const h = 80;
      final bytes = Uint8List(w * h * 4);
      final frame = CapturedFrame(
        width: w,
        height: h,
        bytes: bytes,
        pixelFormat: 'bgra8888',
      );

      final bands = FrameBandCropper.splitZoneBBands(frame);
      // Expect vertical (2) + horizontal (2) = 4 bands
      expect(bands, hasLength(4));
      expect(bands[2].width, greaterThan(120));
      expect(bands[2].height, h);
    });

    test('invertLuminanceBgra inverts light-on-dark HUD frames and skips invalid buffers safely', () {
      final frame = CapturedFrame(
        width: 2,
        height: 2,
        pixelFormat: 'bgra8888',
        bytes: Uint8List.fromList([
          10, 20, 30, 255,
          200, 210, 220, 255,
          0, 0, 0, 255,
          255, 255, 255, 255,
        ]),
      );
      final inverted = FrameBandCropper.invertLuminanceBgra(frame);
      expect(inverted, isNotNull);
      expect(inverted!.bytes[0], 245);
      expect(inverted.bytes[1], 235);
      expect(inverted.bytes[2], 225);
      expect(inverted.bytes[3], 255);
      expect(inverted.bytes[4], 55);

      const tiny = CapturedFrame(width: 10, height: 10, bytes: [1, 2, 3]);
      expect(FrameBandCropper.splitZoneBBands(tiny), isEmpty);
      expect(FrameBandCropper.invertLuminanceBgra(tiny), isNull);
    });

    test('cropRectBgra extracts exact sub-rectangle and clamps out-of-bounds cleanly', () {
      const w = 6;
      const h = 4;
      final bytes = Uint8List(w * h * 4);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final off = (y * w + x) * 4;
          bytes[off] = x * 10 + y; // B encodes (x, y)
          bytes[off + 1] = y * 20;
          bytes[off + 2] = x * 30;
          bytes[off + 3] = 255;
        }
      }
      final frame = CapturedFrame(
        width: w,
        height: h,
        bytes: bytes,
        pixelFormat: 'bgra8888',
        captureMethod: 'printwindow_pw2',
      );

      final cropped = FrameBandCropper.cropRectBgra(
        frame,
        x: 2,
        y: 1,
        width: 3,
        height: 2,
      );
      expect(cropped, isNotNull);
      expect(cropped!.width, 3);
      expect(cropped.height, 2);
      expect(cropped.captureMethod, 'printwindow_pw2');
      // Top-left pixel (2, 1) -> B = 21
      expect(cropped.bytes[0], 21);
      // Bottom-right pixel (4, 2) -> B = 42
      const lastOff = ((2 - 1) * 3 + (3 - 1)) * 4;
      expect(cropped.bytes[lastOff], 42);

      // Boundary clamping: negative/oversized rect clamps safely inside source frame
      final clamped = FrameBandCropper.cropRectBgra(
        frame,
        x: 4,
        y: 2,
        width: 10,
        height: 10,
      );
      expect(clamped, isNotNull);
      expect(clamped!.width, 2);
      expect(clamped.height, 2);
      expect(clamped.bytes[0], 42);

      // Invalid / empty dimensions or non-bgra format return null
      expect(FrameBandCropper.cropRectBgra(frame, x: 0, y: 0, width: 0, height: 2), isNull);
      expect(FrameBandCropper.cropRectBgra(frame, x: 0, y: 0, width: 2, height: 0), isNull);
      expect(
        FrameBandCropper.cropRectBgra(
          const CapturedFrame(width: 4, height: 4, bytes: [1, 2], pixelFormat: 'bgra8888'),
          x: 0,
          y: 0,
          width: 2,
          height: 2,
        ),
        isNull,
      );
    });
  });
}
