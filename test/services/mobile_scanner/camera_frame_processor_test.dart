import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/mobile_scanner/camera_frame_processor.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';

void main() {
  group('CameraFrameProcessor Tests (TDD & Adversarial)', () {
    test('strict ROI crop excludes all pixels outside NormalizedScanRect', () {
      // Create a 10x10 BGRA frame where left half is pure black (0) and right half is white (255)
      const w = 10;
      const h = 10;
      final bytes = Uint8List(w * h * 4);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final off = (y * w + x) * 4;
          final val = x >= 5 ? 255 : 0;
          bytes[off] = val;
          bytes[off + 1] = val;
          bytes[off + 2] = val;
          bytes[off + 3] = 255;
        }
      }
      final frame = CapturedFrame(
        width: w,
        height: h,
        bytes: bytes,
        pixelFormat: 'bgra8888',
      );

      final rightOnly = NormalizedScanRect(
        id: 'right',
        role: CameraZoneRole.scan,
        left: 0.5,
        top: 0.0,
        width: 0.5,
        height: 1.0,
        colorHex: 0xFF10B981,
        label: 'Right',
      );

      final cropped = CameraFrameProcessor.cropFrameToNormalizedRect(frame, rightOnly);
      expect(cropped, isNotNull);
      expect(cropped!.width, 5);
      expect(cropped.height, 10);
      // Every cropped pixel must be white (255), zero black pixels leaked from outside
      for (int i = 0; i < cropped.bytes.length; i += 4) {
        expect(cropped.bytes[i], 255);
        expect(cropped.bytes[i + 1], 255);
        expect(cropped.bytes[i + 2], 255);
      }
    });

    test('converts YUV420 planes to BGRA8888 and rotates 90 degrees accurately', () {
      // 4x2 frame in YUV420: top row bright (Y=235), bottom row dark (Y=16)
      const width = 4;
      const height = 2;
      final yPlane = Uint8List.fromList([
        235, 235, 235, 235,
        16, 16, 16, 16,
      ]);
      final uPlane = Uint8List.fromList([128, 128]);
      final vPlane = Uint8List.fromList([128, 128]);

      final frame = CameraFrameProcessor.convertYuv420ToBgraFrame(
        width: width,
        height: height,
        yBytes: yPlane,
        uBytes: uPlane,
        vBytes: vPlane,
        yRowStride: 4,
        uvRowStride: 2,
        uvPixelStride: 1,
        sensorOrientation: 90,
      );

      expect(frame, isNotNull);
      // 90 deg rotation swaps 4x2 -> 2x4
      expect(frame!.width, 2);
      expect(frame.height, 4);
      expect(frame.pixelFormat, 'bgra8888');
      expect(frame.bytes.length, 2 * 4 * 4);
    });

    test('maps widget rect to normalized frame coordinates under BoxFit.cover', () {
      // Frame is 1600x900 (16:9 landscape), Widget preview is 400x400 (1:1 square)
      // Under BoxFit.cover, height fits 400 -> scaled width = 400 * (16/9) = 711.11
      // Center of widget (0..400, 0..400) corresponds to middle horizontal slice of frame
      final mapped = CameraFrameProcessor.mapWidgetRectToNormalized(
        widgetRect: const Rect.fromLTWH(0, 0, 400, 400),
        widgetSize: const Size(400, 400),
        frameSize: const Size(1600, 900),
        fit: BoxFit.cover,
      );

      expect(mapped.top, closeTo(0.0, 0.01));
      expect(mapped.height, closeTo(1.0, 0.01));
      expect(mapped.left, greaterThan(0.2));
      expect(mapped.width, closeTo(900 / 1600, 0.02));
    });

    test('applyPreprocessProfile enhances low-contrast cameraDisplay frames safely', () {
      final bytes = Uint8List(4 * 4 * 4);
      for (int i = 0; i < 16; i++) {
        final v = i < 8 ? 90 : 140;
        bytes[i * 4] = v;
        bytes[i * 4 + 1] = v;
        bytes[i * 4 + 2] = v;
        bytes[i * 4 + 3] = 255;
      }
      final frame = CapturedFrame(
        width: 4,
        height: 4,
        bytes: bytes,
        pixelFormat: 'bgra8888',
      );

      final enhanced = CameraFrameProcessor.applyPreprocessProfile(
        frame,
        OcrPreprocessProfile.cameraDisplay,
      );
      expect(enhanced.width, 4);
      expect(enhanced.height, 4);
      // Contrast stretch should separate darks (<90) and brights (>140)
      expect(enhanced.bytes[0], lessThan(90));
      expect(enhanced.bytes[15 * 4], greaterThan(140));
    });

    test('handles zero/empty frames gracefully without throwing', () {
      final empty = CapturedFrame(
        width: 0,
        height: 0,
        bytes: Uint8List(0),
        pixelFormat: 'bgra8888',
      );
      final rect = NormalizedScanRect(
        id: 'a',
        role: CameraZoneRole.scan,
        left: 0,
        top: 0,
        width: 1,
        height: 1,
        colorHex: 0xFF10B981,
        label: 'A',
      );
      expect(CameraFrameProcessor.cropFrameToNormalizedRect(empty, rect), isNull);
      expect(
        CameraFrameProcessor.applyPreprocessProfile(
          empty,
          OcrPreprocessProfile.cameraDisplay,
        ).bytes,
        isEmpty,
      );
    });

    test('bgraToEvenAlignedNv21 safely aligns odd dimensions without truncating chroma', () {
      const w = 101;
      const h = 51;
      final bgra = Uint8List(w * h * 4);
      for (int i = 0; i < bgra.length; i += 4) {
        bgra[i] = 80;
        bgra[i + 1] = 160;
        bgra[i + 2] = 220;
        bgra[i + 3] = 255;
      }
      final frame = CapturedFrame(
        width: w,
        height: h,
        bytes: bgra,
        pixelFormat: 'bgra8888',
      );

      final aligned = CameraFrameProcessor.bgraToEvenAlignedNv21(frame);
      expect(aligned.width.isEven, isTrue);
      expect(aligned.height.isEven, isTrue);
      expect(aligned.width, greaterThanOrEqualTo(100));
      expect(aligned.height, greaterThanOrEqualTo(50));
      expect(
        aligned.bytes.length,
        aligned.width * aligned.height + (aligned.width * aligned.height ~/ 2),
      );
    });

    test('convertTwoPlaneYuvToBgraFrame decodes 2-plane NV21/NV12 frames and rotates accurately', () {
      const width = 4;
      const height = 2;
      final yPlane = Uint8List.fromList([
        235, 235, 235, 235,
        16, 16, 16, 16,
      ]);
      // Interleaved VU (NV21) for 2x1 chroma blocks -> 4 bytes
      final vuPlane = Uint8List.fromList([128, 128, 128, 128]);

      final frame = CameraFrameProcessor.convertTwoPlaneYuvToBgraFrame(
        width: width,
        height: height,
        yBytes: yPlane,
        uvBytes: vuPlane,
        yRowStride: 4,
        uvRowStride: 4,
        isNv21Order: true,
        sensorOrientation: 90,
      );

      expect(frame, isNotNull);
      expect(frame!.width, 2);
      expect(frame.height, 4);
      expect(frame.pixelFormat, 'bgra8888');
      expect(frame.bytes.length, 2 * 4 * 4);
    });

    test('resolveEffectiveRotationDegrees accounts for device orientation and lens direction', () {
      // Back camera with sensorOrientation 90:
      // PortraitUp (0 deg) -> 90 deg rotation needed
      expect(
        CameraFrameProcessor.resolveEffectiveRotationDegrees(
          sensorOrientation: 90,
          deviceRotationDegrees: 0,
          isFrontCamera: false,
        ),
        90,
      );
      // LandscapeLeft (90 deg CCW / deviceOrientation.landscapeLeft) -> 0 deg rotation needed
      expect(
        CameraFrameProcessor.resolveEffectiveRotationDegrees(
          sensorOrientation: 90,
          deviceRotationDegrees: 90,
          isFrontCamera: false,
        ),
        0,
      );
      // LandscapeRight (270 deg) -> 180 deg rotation needed
      expect(
        CameraFrameProcessor.resolveEffectiveRotationDegrees(
          sensorOrientation: 90,
          deviceRotationDegrees: 270,
          isFrontCamera: false,
        ),
        180,
      );
      // Front camera sensorOrientation 270 in PortraitUp -> 270 deg
      expect(
        CameraFrameProcessor.resolveEffectiveRotationDegrees(
          sensorOrientation: 270,
          deviceRotationDegrees: 0,
          isFrontCamera: true,
        ),
        270,
      );
    });
  });
}
