import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';
import 'package:pokevault/services/mobile_scanner/mobile_camera_source.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';

class _FakeRegionOcrDriver implements DisposableOcrDriver {
  final List<CapturedFrame> seenFrames = [];
  String Function(CapturedFrame frame) handler;
  bool disposed = false;

  _FakeRegionOcrDriver(this.handler);

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    seenFrames.add(frame);
    final out = handler(frame);
    return out.isEmpty ? const [] : [out];
  }

  @override
  Future<void> dispose() async {
    disposed = true;
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

    test('customRegions focus-only mode still tracks transitions and emits full upright frame for visual shiny color check', () async {
      final ocr = _FakeRegionOcrDriver((_) => 'Wildes Pikachu');
      final source = MobileCameraSource(
        ocrDriver: ocr,
        pollInterval: const Duration(milliseconds: 50),
      );
      source.setScanMode(MobileCameraScanMode.customRegions);
      source.setRegions([
        NormalizedScanRect(
          id: 'focus_only',
          role: CameraZoneRole.focus,
          left: 0.0,
          top: 0.5,
          width: 1.0,
          height: 0.5,
          colorHex: 0xFF3B82F6,
          label: 'Enemy HUD',
          encounterOnly: true,
        ),
      ]);

      final visualFrames = <SlotVisualFrame>[];
      final visSub = source.visualFrameStream.listen(visualFrames.add);

      await source.start();
      // Full upright frame is 20x20, cropped focus region is 20x10
      await source.submitCameraFrame(_makeTwoToneFrame(width: 20, height: 20), bypassThrottle: true);
      await Future<void>.delayed(Duration.zero);

      expect(visualFrames, isNotEmpty);
      expect(visualFrames.first.frame?.height, equals(20));

      // stop() resets transition detector and drops in-flight stopped OCR emissions
      await source.stop();
      await visSub.cancel();
      await source.dispose();
      expect(ocr.disposed, isTrue);
    });

    test('dispose cancels in-flight processPhotoFrame updates without FlutterError and disposes ocrDriver', () async {
      final ocrCompleter = Completer<List<String>>();
      final slowOcr = _CompleterOcrDriver(ocrCompleter.future);
      final source = MobileCameraSource(ocrDriver: slowOcr);
      await source.start();

      final scanFuture = source.processPhotoFrame(_makeTwoToneFrame());
      await Future<void>.delayed(Duration.zero);

      await source.dispose();
      expect(slowOcr.disposed, isTrue);

      // Resolving OCR after dispose must NOT mutate disposed ValueNotifiers
      ocrCompleter.complete(const ['Pikachu']);
      await scanFuture;
    });

    test('multiInstance paired scan+focus regions emit single visual frame (cropped) and single transition check per slot', () async {
      final ocr = _FakeRegionOcrDriver((_) => 'Wildes Pikachu');
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
          label: '#2 Scan',
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
          label: '#2 Focus',
          encounterOnly: true,
        ),
      ]);

      final visualFrames = <SlotVisualFrame>[];
      final visSub = source.visualFrameStream.listen(visualFrames.add);

      await source.start();
      await source.submitCameraFrame(
        _makeTwoToneFrame(width: 20, height: 20),
        bypassThrottle: true,
      );
      await Future<void>.delayed(Duration.zero);

      // Must emit only 1 visual frame for slot 2 (from scan region) using the cropped 20x10 frame, NOT 20x20 full frame
      expect(visualFrames, hasLength(1));
      expect(visualFrames.single.slotId, 2);
      expect(visualFrames.single.frame?.height, 10);

      await visSub.cancel();
      await source.dispose();
    });

    test('dispose mid-multi-region scan prevents OCR calls on subsequent regions and after dispose', () async {
      final firstCallStarted = Completer<void>();
      final firstCallRelease = Completer<List<String>>();
      int ocrCalls = 0;
      bool disposedWhenCalled = false;

      final gatedOcr = _GatedOcrDriver(
        onRecognize: (_) async {
          ocrCalls++;
          if (ocrCalls == 1) {
            firstCallStarted.complete();
            return firstCallRelease.future;
          }
          disposedWhenCalled = true;
          return const ['Pikachu'];
        },
      );

      final source = MobileCameraSource(ocrDriver: gatedOcr);
      source.setScanMode(MobileCameraScanMode.customRegions);
      source.setRegions([
        NormalizedScanRect(
          id: 'reg_1',
          role: CameraZoneRole.scan,
          left: 0.0,
          top: 0.0,
          width: 0.5,
          height: 1.0,
          colorHex: 0xFF10B981,
          label: 'R1',
        ),
        NormalizedScanRect(
          id: 'reg_2',
          role: CameraZoneRole.focus,
          left: 0.5,
          top: 0.0,
          width: 0.5,
          height: 1.0,
          colorHex: 0xFF3B82F6,
          label: 'R2',
          encounterOnly: true,
        ),
      ]);

      await source.start();
      final submitFuture = source.submitCameraFrame(
        _makeTwoToneFrame(width: 20, height: 20),
        bypassThrottle: true,
      );
      await firstCallStarted.future;

      await source.dispose();
      firstCallRelease.complete(const ['Glumanda']);
      await submitFuture;

      expect(ocrCalls, 1);
      expect(disposedWhenCalled, isFalse);

      // Post-dispose calls must be safe no-ops
      await source.submitCameraFrame(
        _makeTwoToneFrame(width: 20, height: 20, bottomVal: 180),
        bypassThrottle: true,
      );
      await source.triggerSingleScan();
      expect(ocrCalls, 1);
    });

    test('OCR exception in one custom region does not abort remaining regions or poison fingerprint', () async {
      bool failRegion1 = true;
      int region1Calls = 0;
      int region2Calls = 0;

      final flakyOcr = _GatedOcrDriver(
        onRecognize: (frame) async {
          // Left half vs right half: use pixel difference or call order
          final isRegion1 = frame.bytes[0] < 100;
          if (isRegion1) {
            region1Calls++;
            if (failRegion1) throw StateError('MLKit transient error');
            return const ['Glumanda wurde gefangen!'];
          }
          region2Calls++;
          return const ['Wildes Pikachu'];
        },
      );

      final source = MobileCameraSource(ocrDriver: flakyOcr);
      source.setScanMode(MobileCameraScanMode.customRegions);
      source.setRegions([
        NormalizedScanRect(
          id: 'r1',
          role: CameraZoneRole.scan,
          left: 0.0,
          top: 0.0,
          width: 1.0,
          height: 0.5,
          colorHex: 0xFF10B981,
          label: 'Top',
        ),
        NormalizedScanRect(
          id: 'r2',
          role: CameraZoneRole.focus,
          left: 0.0,
          top: 0.5,
          width: 1.0,
          height: 0.5,
          colorHex: 0xFF3B82F6,
          label: 'Bottom',
          encounterOnly: true,
        ),
      ]);

      final focusTexts = <String>[];
      final scanTexts = <String>[];
      final s1 = source.focusTextStream.listen(focusTexts.add);
      final s2 = source.textStream.listen(scanTexts.add);

      await source.start();
      final frame = _makeTwoToneFrame(width: 20, height: 20);
      await source.submitCameraFrame(frame, bypassThrottle: true);
      await Future<void>.delayed(Duration.zero);

      expect(region1Calls, 1);
      expect(region2Calls, 1);
      expect(focusTexts, ['Wildes Pikachu']);

      // Retry exact same frame once region1 recovers -> must NOT be skipped by poisoned fingerprint
      failRegion1 = false;
      await source.submitCameraFrame(frame, bypassThrottle: true);
      await Future<void>.delayed(Duration.zero);

      expect(region1Calls, 2);
      expect(scanTexts, ['Glumanda wurde gefangen!']);

      await s1.cancel();
      await s2.cancel();
      await source.dispose();
    });
  });
}

class _CompleterOcrDriver implements DisposableOcrDriver {
  final Future<List<String>> future;
  bool disposed = false;
  _CompleterOcrDriver(this.future);

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) => future;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _GatedOcrDriver implements DisposableOcrDriver {
  final Future<List<String>> Function(CapturedFrame frame) onRecognize;
  bool disposed = false;
  _GatedOcrDriver({required this.onRecognize});

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) => onRecognize(frame);

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
