import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_source.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';

class _FakeRegionOcrDriver implements DesktopOcrDriver {
  final List<CapturedFrame> seenFrames = [];
  String Function(CapturedFrame frame) handler;

  _FakeRegionOcrDriver(this.handler);

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    seenFrames.add(frame);
    final out = handler(frame);
    return out.isEmpty ? const [] : [out];
  }
}

CapturedFrame _makeTwoToneFrame({
  int width = 20,
  int height = 20,
  int topVal = 20,
  int bottomVal = 240,
}) {
  final bytes = Uint8List(width * height * 4);
  for (int y = 0; y < height; y++) {
    final val = y < height ~/ 2 ? topVal : bottomVal;
    for (int x = 0; x < width; x++) {
      final off = (y * width + x) * 4;
      bytes[off] = val;
      bytes[off + 1] = val;
      bytes[off + 2] = val;
      bytes[off + 3] = 255;
    }
  }
  return CapturedFrame(
    width: width,
    height: height,
    bytes: bytes,
    pixelFormat: 'bgra8888',
    captureMethod: 'test_cam',
  );
}

void main() {
  group('MobileCameraSource Tests (TDD)', () {
    test('autoFull mode scans entire frame and skips duplicate unchanged frames', () async {
      final ocr = _FakeRegionOcrDriver((_) => 'Glumanda wurde gefangen!');
      final source = MobileCameraSource(
        ocrDriver: ocr,
        pollInterval: const Duration(milliseconds: 50),
      );
      final emitted = <String>[];
      final sub = source.textStream.listen(emitted.add);

      await source.start();
      expect(source.isRunning, isTrue);

      final frame1 = _makeTwoToneFrame();
      await source.submitCameraFrame(frame1, bypassThrottle: true);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, ['Glumanda wurde gefangen!']);
      expect(ocr.seenFrames.length, 1);
      expect(ocr.seenFrames.first.width, 20);
      expect(ocr.seenFrames.first.height, 20);

      // Submitting exact same frame again should be skipped by fingerprint deduplication
      await source.submitCameraFrame(frame1, bypassThrottle: true);
      expect(ocr.seenFrames.length, 1);

      await sub.cancel();
      await source.dispose();
    });

    test('customRegions mode strictly crops and routes Zone A, Zone B, and Multi-Instance slots', () async {
      final ocr = _FakeRegionOcrDriver((frame) {
        // Top half has pixel value 20 -> enemy HUD; bottom half has pixel value 240 -> catch box
        final firstBlue = frame.bytes.isNotEmpty ? frame.bytes[0] : 0;
        if (firstBlue < 100) return 'Wildes Pikachu';
        return 'Klasse! Glumanda wurde gefangen!';
      });

      final source = MobileCameraSource(ocrDriver: ocr);
      source.setScanMode(MobileCameraScanMode.customRegions);
      source.setRegions([
        NormalizedScanRect(
          id: 'zone_a',
          role: CameraZoneRole.scan,
          left: 0.0,
          top: 0.5,
          width: 1.0,
          height: 0.5,
          colorHex: 0xFF10B981,
          label: 'Zone A',
        ),
        NormalizedScanRect(
          id: 'zone_b',
          role: CameraZoneRole.focus,
          left: 0.0,
          top: 0.0,
          width: 1.0,
          height: 0.5,
          colorHex: 0xFF06B6D4,
          label: 'Zone B',
          encounterOnly: true,
        ),
        NormalizedScanRect(
          id: 'multi_2',
          role: CameraZoneRole.multiInstance,
          slotId: 2,
          left: 0.0,
          top: 0.0,
          width: 0.5,
          height: 0.5,
          colorHex: 0xFFEC4899,
          label: 'Instanz #2',
          encounterOnly: true,
        ),
      ]);

      final scanTexts = <String>[];
      final focusTexts = <String>[];
      final multiEmissions = <MultiInstanceTextEmission>[];
      final s1 = source.textStream.listen(scanTexts.add);
      final s2 = source.focusTextStream.listen(focusTexts.add);
      final s3 = source.multiInstanceTextStream.listen(multiEmissions.add);

      await source.start();
      await source.submitCameraFrame(_makeTwoToneFrame(), bypassThrottle: true);
      await Future<void>.delayed(Duration.zero);

      expect(scanTexts, ['Klasse! Glumanda wurde gefangen!']);
      expect(focusTexts, ['Wildes Pikachu']);
      expect(multiEmissions.length, 1);
      expect(multiEmissions.first.slotId, 2);
      expect(multiEmissions.first.encounterOnly, isTrue);
      expect(multiEmissions.first.rawText, 'Wildes Pikachu');

      // Cropped frames must match region heights (half of 20 = 10)
      expect(ocr.seenFrames.every((f) => f.height == 10), isTrue);
      expect(source.scanLogsNotifier.value, isNotEmpty);

      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
      await source.dispose();
    });

    test('throttles rapid camera frames according to pollInterval unless bypassThrottle is true', () async {
      final ocr = _FakeRegionOcrDriver((_) => 'Pikachu wurde gefangen!');
      final source = MobileCameraSource(
        ocrDriver: ocr,
        pollInterval: const Duration(milliseconds: 500),
      );
      await source.start();

      await source.submitCameraFrame(_makeTwoToneFrame(bottomVal: 200));
      await source.submitCameraFrame(_makeTwoToneFrame(bottomVal: 210)); // throttled
      expect(ocr.seenFrames.length, 1);

      await source.processPhotoFrame(_makeTwoToneFrame(bottomVal: 220)); // immediate photo scan
      expect(ocr.seenFrames.length, 2);

      await source.dispose();
    });

    test('multiInstance paired Zone A (scan) and Zone B (focus) emit matching slotId and separate status notifiers', () async {
      final ocr = _FakeRegionOcrDriver((frame) {
        final firstBlue = frame.bytes.isNotEmpty ? frame.bytes[0] : 0;
        return firstBlue < 100 ? 'Wildes Pikachu' : 'Glumanda wurde gefangen!';
      });

      final source = MobileCameraSource(ocrDriver: ocr);
      source.setScanMode(MobileCameraScanMode.customRegions);
      source.setRegions([
        NormalizedScanRect(
          id: 'multi_2_scan',
          role: CameraZoneRole.multiInstance,
          slotId: 2,
          left: 0.0,
          top: 0.5,
          width: 1.0,
          height: 0.5,
          colorHex: 0xFFA855F7,
          label: '#2 Zone A · Scan',
          encounterOnly: false,
        ),
        NormalizedScanRect(
          id: 'multi_2_focus',
          role: CameraZoneRole.multiInstance,
          slotId: 2,
          left: 0.0,
          top: 0.0,
          width: 1.0,
          height: 0.5,
          colorHex: 0xFFA855F7,
          label: '#2 Zone B · Fokus',
          encounterOnly: true,
        ),
      ]);

      final emissions = <MultiInstanceTextEmission>[];
      final sub = source.multiInstanceTextStream.listen(emissions.add);
      await source.start();
      await source.submitCameraFrame(_makeTwoToneFrame(), bypassThrottle: true);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.length, 2);
      expect(emissions[0].slotId, 2);
      expect(emissions[0].encounterOnly, isFalse);
      expect(emissions[0].rawText, 'Glumanda wurde gefangen!');
      expect(emissions[1].slotId, 2);
      expect(emissions[1].encounterOnly, isTrue);
      expect(emissions[1].rawText, 'Wildes Pikachu');

      expect(source.liveScanStatusNotifier.value.recognizedLines, ['Glumanda wurde gefangen!']);
      expect(source.liveFocusStatusNotifier.value.recognizedLines, ['Wildes Pikachu']);

      await sub.cancel();
      await source.dispose();
    });

    test('shouldProcessFrameNow respects running state and pollInterval before frame conversion', () async {
      final ocr = _FakeRegionOcrDriver((_) => 'Pikachu');
      final source = MobileCameraSource(
        ocrDriver: ocr,
        pollInterval: const Duration(milliseconds: 500),
      );

      expect(source.shouldProcessFrameNow(), isFalse);
      await source.start();
      expect(source.shouldProcessFrameNow(), isTrue);

      await source.submitCameraFrame(_makeTwoToneFrame(bottomVal: 200));
      // Immediately after processing, shouldProcessFrameNow returns false until pollInterval elapses
      expect(source.shouldProcessFrameNow(), isFalse);

      await source.dispose();
    });
  });
}
