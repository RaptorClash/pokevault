import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_window_source.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';

class MockCaptureDriver implements DesktopCaptureDriver {
  int captureCount = 0;
  Rect? lastCrop;
  DesktopWindowInfo? lastWindow;

  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
  }) async {
    captureCount++;
    lastWindow = window;
    lastCrop = cropRegion;
    return const CapturedFrame(
      width: 800,
      height: 600,
      bytes: [1, 2, 3],
    );
  }
}

class MockOcrDriver implements DesktopOcrDriver {
  String textToReturn = 'Glumanda wurde gefangen!';
  int ocrCount = 0;

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    ocrCount++;
    if (textToReturn.isEmpty) return [];
    return [textToReturn];
  }
}

void main() {
  group('DesktopWindowSource Tests (TDD)', () {
    late MockCaptureDriver captureDriver;
    late MockOcrDriver ocrDriver;
    late DesktopWindowSource source;

    setUp(() {
      captureDriver = MockCaptureDriver();
      ocrDriver = MockOcrDriver();
      source = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
        pollInterval: const Duration(milliseconds: 50),
      );
    });

    tearDown(() async {
      await source.dispose();
    });

    test('Initial state is stopped with no text emitted', () {
      expect(source.isRunning, isFalse);
    });

    test('Periodically captures selected window and streams OCR text', () async {
      const window = DesktopWindowInfo(id: 123, title: 'mGBA - Pokemon');
      source.setSelectedWindow(window);
      source.setCropRegion(const Rect.fromLTWH(0, 400, 800, 200));

      final emitted = <String>[];
      final sub = source.textStream.listen(emitted.add);

      await source.start();
      expect(source.isRunning, isTrue);

      // Wait for at least 2 ticks
      await Future.delayed(const Duration(milliseconds: 140));

      expect(emitted, contains('Glumanda wurde gefangen!'));
      expect(captureDriver.captureCount, greaterThanOrEqualTo(2));
      expect(captureDriver.lastWindow?.id, 123);
      expect(captureDriver.lastCrop?.top, 400);
      expect(ocrDriver.ocrCount, greaterThanOrEqualTo(2));

      await source.stop();
      expect(source.isRunning, isFalse);
      await sub.cancel();
    });

    test('Does not capture if no window is selected', () async {
      source.setSelectedWindow(null);
      await source.start();

      await Future.delayed(const Duration(milliseconds: 80));
      expect(captureDriver.captureCount, 0);

      await source.stop();
    });
  });
}
