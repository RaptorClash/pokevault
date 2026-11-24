import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/scanner_core/media/frame_transition_detector.dart';

CapturedFrame _solidBgraFrame({
  required int width,
  required int height,
  required int b,
  required int g,
  required int r,
}) {
  final bytes = Uint8List(width * height * 4);
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = b;
    bytes[i + 1] = g;
    bytes[i + 2] = r;
    bytes[i + 3] = 255;
  }
  return CapturedFrame(
    width: width,
    height: height,
    bytes: bytes,
    pixelFormat: 'bgra8888',
  );
}

void main() {
  group('FrameTransitionDetector', () {
    test('emits exactly one blackScreenEnded event after normal -> black >= minDuration -> normal', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      final normal = _solidBgraFrame(width: 20, height: 20, b: 120, g: 120, r: 120);
      final black = _solidBgraFrame(width: 20, height: 20, b: 4, g: 4, r: 4);

      expect(detector.analyzeFrame(normal, slotId: 1), isNull);

      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);

      clock += const Duration(milliseconds: 350);
      // Still black -> no event until normal screen resumes
      expect(detector.analyzeFrame(black, slotId: 1), isNull);

      clock += const Duration(milliseconds: 50);
      final event = detector.analyzeFrame(normal, slotId: 1);
      expect(event, isNotNull);
      expect(event!.slotId, equals(1));
      expect(event.type, equals(FrameTransitionType.blackScreenEnded));
      expect(event.durationMs, greaterThanOrEqualTo(300));

      // Subsequent normal frames do not re-emit
      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
    });

    test('emits whiteScreenEnded event after normal -> white >= minDuration -> normal', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      final normal = _solidBgraFrame(width: 20, height: 20, b: 90, g: 100, r: 110);
      final white = _solidBgraFrame(width: 20, height: 20, b: 250, g: 250, r: 250);

      expect(detector.analyzeFrame(normal, slotId: 2), isNull);
      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(white, slotId: 2), isNull);

      clock += const Duration(milliseconds: 400);
      final event = detector.analyzeFrame(normal, slotId: 2);
      expect(event, isNotNull);
      expect(event!.slotId, equals(2));
      expect(event.type, equals(FrameTransitionType.whiteScreenEnded));
    });

    test('ignores brief flicker shorter than minTransitionDuration', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 350),
        elapsedClock: () => clock,
      );

      final normal = _solidBgraFrame(width: 16, height: 16, b: 100, g: 100, r: 100);
      final black = _solidBgraFrame(width: 16, height: 16, b: 0, g: 0, r: 0);

      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);
      clock += const Duration(milliseconds: 150);
      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
    });

    test('isolates state per slotId and handles invalid/empty frames safely', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      final normal = _solidBgraFrame(width: 16, height: 16, b: 100, g: 100, r: 100);
      final black = _solidBgraFrame(width: 16, height: 16, b: 0, g: 0, r: 0);

      // Invalid frames never crash or emit
      expect(
        detector.analyzeFrame(
          const CapturedFrame(width: 0, height: 0, bytes: [], pixelFormat: 'bgra8888'),
          slotId: 1,
        ),
        isNull,
      );
      expect(
        detector.analyzeFrame(
          const CapturedFrame(width: 10, height: 10, bytes: [1, 2, 3], pixelFormat: 'png'),
          slotId: 1,
        ),
        isNull,
      );

      // Slot 1 goes black, Slot 2 stays normal -> only Slot 1 emits on recovery
      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
      expect(detector.analyzeFrame(normal, slotId: 2), isNull);

      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);
      expect(detector.analyzeFrame(normal, slotId: 2), isNull);

      clock += const Duration(milliseconds: 400);
      expect(detector.analyzeFrame(normal, slotId: 2), isNull);
      final ev1 = detector.analyzeFrame(normal, slotId: 1);
      expect(ev1, isNotNull);
      expect(ev1!.slotId, equals(1));
    });

    test('starting directly on black screen does NOT fire blackScreenEnded when normal screen appears', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      final black = _solidBgraFrame(width: 20, height: 20, b: 0, g: 0, r: 0);
      final normal = _solidBgraFrame(width: 20, height: 20, b: 120, g: 120, r: 120);

      expect(detector.analyzeFrame(black, slotId: 1), isNull);
      clock += const Duration(milliseconds: 500);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);
      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
    });

    test('direct black -> white -> normal transition does not double-emit on black -> white boundary', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      final normal = _solidBgraFrame(width: 20, height: 20, b: 120, g: 120, r: 120);
      final black = _solidBgraFrame(width: 20, height: 20, b: 2, g: 2, r: 2);
      final white = _solidBgraFrame(width: 20, height: 20, b: 252, g: 252, r: 252);

      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);
      clock += const Duration(milliseconds: 400);
      // Direct jump black -> white must NOT emit blackScreenEnded
      expect(detector.analyzeFrame(white, slotId: 1), isNull);
      clock += const Duration(milliseconds: 400);
      // Returning to normal emits only whiteScreenEnded
      final ev = detector.analyzeFrame(normal, slotId: 1);
      expect(ev, isNotNull);
      expect(ev!.type, equals(FrameTransitionType.whiteScreenEnded));
    });

    test('setMinTransitionDuration updates threshold dynamically', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 350),
        elapsedClock: () => clock,
      );
      detector.setMinTransitionDuration(const Duration(milliseconds: 150));

      final normal = _solidBgraFrame(width: 20, height: 20, b: 120, g: 120, r: 120);
      final black = _solidBgraFrame(width: 20, height: 20, b: 2, g: 2, r: 2);

      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);
      clock += const Duration(milliseconds: 180);
      final ev = detector.analyzeFrame(normal, slotId: 1);
      expect(ev, isNotNull);
      expect(ev!.type, equals(FrameTransitionType.blackScreenEnded));
    });
  });
}
