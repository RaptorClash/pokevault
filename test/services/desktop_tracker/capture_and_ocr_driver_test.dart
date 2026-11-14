import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';

void main() {
  group('Capture and OCR Driver Tests (TDD)', () {
    test('DefaultDesktopCaptureDriver invokes custom handler when provided', () async {
      const window = DesktopWindowInfo(id: 101, title: 'Test Emulator');
      const expectedFrame = CapturedFrame(width: 800, height: 600, bytes: [1, 2, 3]);

      final driver = DefaultDesktopCaptureDriver(
        nativeCaptureHandler: (w, crop, screenReg) async => expectedFrame,
      );

      final frame = await driver.captureWindow(
        window: window,
        cropRegion: const Rect.fromLTWH(0, 0, 800, 600),
      );

      expect(frame, isNotNull);
      expect(frame!.width, 800);
      expect(frame.bytes, equals([1, 2, 3]));
    });

    test('DefaultDesktopCaptureDriver supports absolute ScreenRegion capture', () async {
      const window = DesktopWindowInfo(id: 102, title: 'Screen Target');
      final screenRegion = ScreenRegion(
        x: 100,
        y: 200,
        width: 400,
        height: 150,
        isAbsoluteScreen: true,
      );

      ScreenRegion? passedRegion;
      final driver = DefaultDesktopCaptureDriver(
        nativeCaptureHandler: (w, crop, screenReg) async {
          passedRegion = screenReg;
          return const CapturedFrame(width: 400, height: 150, bytes: []);
        },
      );

      final frame = await driver.captureWindow(
        window: window,
        screenRegion: screenRegion,
      );

      expect(frame, isNotNull);
      expect(passedRegion, equals(screenRegion));
      expect(passedRegion!.isAbsoluteScreen, isTrue);
    });

    test('DefaultDesktopOcrDriver invokes custom OCR handler and trims output lines', () async {
      const frame = CapturedFrame(width: 200, height: 50, bytes: [0, 0]);
      final driver = DefaultDesktopOcrDriver(
        nativeOcrHandler: (f) async => [
          '  Ein wildes Pikachu erscheint!  ',
          '',
          '   ',
          'Bereit zum Kampf',
        ],
      );

      final lines = await driver.recognizeText(frame);
      expect(lines, contains('Ein wildes Pikachu erscheint!'));
      expect(lines, contains('Bereit zum Kampf'));
      expect(lines.length, 2);
    });

    test('Returns empty results gracefully when frame is empty or handler is null', () async {
      final driver = DefaultDesktopOcrDriver();
      const frame = CapturedFrame(width: 0, height: 0, bytes: []);
      final lines = await driver.recognizeText(frame);
      expect(lines, isEmpty);
    });
  });
}
