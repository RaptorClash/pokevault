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
      clock += const Duration(milliseconds: 200);
      expect(detector.analyzeFrame(white, slotId: 2), isNull);

      clock += const Duration(milliseconds: 200);
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

      clock += const Duration(milliseconds: 200);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);

      clock += const Duration(milliseconds: 200);
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
      clock += const Duration(milliseconds: 200);
      expect(detector.analyzeFrame(white, slotId: 1), isNull);
      clock += const Duration(milliseconds: 200);
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
      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(black, slotId: 1), isNull);
      clock += const Duration(milliseconds: 80);
      final ev = detector.analyzeFrame(normal, slotId: 1);
      expect(ev, isNotNull);
      expect(ev!.type, equals(FrameTransitionType.blackScreenEnded));
    });

    test('rejects white dialogue box with dark text (high luminance stdDev) while accepting uniform white frame', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      final normal = _solidBgraFrame(width: 20, height: 20, b: 120, g: 120, r: 120);
      // 85% white (255) + 15% black text pixels (0) -> avgLuma ~217..242 depending on ratio, high stdDev
      // Use 92% white + 8% black -> avgLuma ~234.6 (>= whiteThreshold - hysteresis / or let's use 95% white + 5% black -> avgLuma = 242.25 >= 240, stdDev ~55.6 > 22)
      const w = 20;
      const h = 20;
      final dialogBytes = Uint8List(w * h * 4);
      for (int i = 0; i < w * h; i++) {
        final isText = (i % 20) == 0; // 5% black text pixels -> avgLuma ~242.25, stdDev ~55.6
        final v = isText ? 0 : 255;
        final idx = i * 4;
        dialogBytes[idx] = v;
        dialogBytes[idx + 1] = v;
        dialogBytes[idx + 2] = v;
        dialogBytes[idx + 3] = 255;
      }
      final whiteDialogueBox = CapturedFrame(
        width: w,
        height: h,
        bytes: dialogBytes,
        pixelFormat: 'bgra8888',
      );
      final uniformWhite = _solidBgraFrame(width: 20, height: 20, b: 250, g: 250, r: 250);

      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(whiteDialogueBox, slotId: 1), isNull);
      clock += const Duration(milliseconds: 200);
      expect(detector.analyzeFrame(whiteDialogueBox, slotId: 1), isNull);
      clock += const Duration(milliseconds: 200);
      // Returning to normal after a non-uniform white dialogue box must NOT emit whiteScreenEnded
      expect(detector.analyzeFrame(normal, slotId: 1), isNull);

      // Uniform white frame DOES emit whiteScreenEnded
      clock += const Duration(milliseconds: 100);
      expect(detector.analyzeFrame(uniformWhite, slotId: 1), isNull);
      clock += const Duration(milliseconds: 200);
      expect(detector.analyzeFrame(uniformWhite, slotId: 1), isNull);
      clock += const Duration(milliseconds: 200);
      final ev = detector.analyzeFrame(normal, slotId: 1);
      expect(ev, isNotNull);
      expect(ev!.type, equals(FrameTransitionType.whiteScreenEnded));
    });

    test('updateThresholds allows configuring camera-friendly black/white thresholds dynamically', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );
      detector.updateThresholds(blackThreshold: 45, whiteThreshold: 210);

      final normal = _solidBgraFrame(width: 20, height: 20, b: 120, g: 120, r: 120);
      final dimDark = _solidBgraFrame(width: 20, height: 20, b: 35, g: 35, r: 35);

      expect(detector.analyzeFrame(normal, slotId: 1), isNull);
      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeFrame(dimDark, slotId: 1), isNull);
      clock += const Duration(milliseconds: 200);
      expect(detector.analyzeFrame(dimDark, slotId: 1), isNull);
      clock += const Duration(milliseconds: 150);
      final ev = detector.analyzeFrame(normal, slotId: 1);
      expect(ev, isNotNull);
      expect(ev!.type, equals(FrameTransitionType.blackScreenEnded));
    });

    test('analyzeLuminance matches analyzeFrame parity and handles boundary inputs safely', () {
      var clock = Duration.zero;
      final frameDet = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );
      final lumaDet = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      final normal = _solidBgraFrame(width: 16, height: 16, b: 120, g: 120, r: 120);
      final black = _solidBgraFrame(width: 16, height: 16, b: 2, g: 2, r: 2);

      // NaN / negative / >255 inputs must not crash or trigger transitions
      expect(
        lumaDet.analyzeLuminance(avgLuma: double.nan, stdDev: 0.0, slotId: 1),
        isNull,
      );
      expect(
        lumaDet.analyzeLuminance(avgLuma: -10.0, stdDev: double.nan, slotId: 1),
        isNull,
      );

      expect(frameDet.analyzeFrame(normal, slotId: 1), isNull);
      expect(lumaDet.analyzeLuminance(avgLuma: 120.0, stdDev: 0.0, slotId: 1), isNull);

      clock += const Duration(milliseconds: 100);
      expect(frameDet.analyzeFrame(black, slotId: 1), isNull);
      expect(lumaDet.analyzeLuminance(avgLuma: 2.0, stdDev: 0.0, slotId: 1), isNull);

      clock += const Duration(milliseconds: 200);
      expect(frameDet.analyzeFrame(black, slotId: 1), isNull);
      expect(lumaDet.analyzeLuminance(avgLuma: 2.0, stdDev: 0.0, slotId: 1), isNull);

      // Recovery after >= 300ms
      clock += const Duration(milliseconds: 200);
      final evFrame = frameDet.analyzeFrame(normal, slotId: 1);
      final evLuma = lumaDet.analyzeLuminance(avgLuma: 120.0, stdDev: 0.0, slotId: 1);

      expect(evFrame, isNotNull);
      expect(evLuma, isNotNull);
      expect(evLuma!.type, equals(evFrame!.type));
      expect(evLuma.durationMs, equals(evFrame.durationMs));
      expect(evLuma.slotId, equals(evFrame.slotId));
    });

    test('setSlotConfigs isolates black/white thresholds and minTransitionDuration per slot', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        blackThreshold: 18,
        whiteThreshold: 240,
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );
      detector.setSlotConfigs({
        1: const SlotTransitionConfig(
          blackThreshold: 50,
          whiteThreshold: 210,
          minTransitionDuration: Duration(milliseconds: 250),
        ),
        2: const SlotTransitionConfig(
          blackThreshold: 18,
          whiteThreshold: 240,
          minTransitionDuration: Duration(milliseconds: 500),
        ),
      });

      // Normal scene on both slots
      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 1), isNull);
      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 2), isNull);

      // Dim dark scene (luma=35) triggers Slot 1 (blackThreshold=50) but NOT Slot 2 (blackThreshold=18)
      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeLuminance(avgLuma: 35, stdDev: 2, slotId: 1), isNull);
      expect(detector.analyzeLuminance(avgLuma: 35, stdDev: 2, slotId: 2), isNull);

      clock += const Duration(milliseconds: 140);
      expect(detector.analyzeLuminance(avgLuma: 35, stdDev: 2, slotId: 1), isNull);
      expect(detector.analyzeLuminance(avgLuma: 35, stdDev: 2, slotId: 2), isNull);

      clock += const Duration(milliseconds: 120);
      final ev1 = detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 1);
      final ev2 = detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 2);
      expect(ev1, isNotNull);
      expect(ev1!.type, equals(FrameTransitionType.blackScreenEnded));
      expect(ev2, isNull);

      // Slot 2 requires >= 500ms even for true black (luma=4)
      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeLuminance(avgLuma: 4, stdDev: 1, slotId: 2), isNull);
      clock += const Duration(milliseconds: 200);
      expect(detector.analyzeLuminance(avgLuma: 4, stdDev: 1, slotId: 2), isNull);
      clock += const Duration(milliseconds: 150);
      // 350ms < 500ms -> ignored
      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 2), isNull);

      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeLuminance(avgLuma: 4, stdDev: 1, slotId: 2), isNull);
      clock += const Duration(milliseconds: 260);
      expect(detector.analyzeLuminance(avgLuma: 4, stdDev: 1, slotId: 2), isNull);
      clock += const Duration(milliseconds: 260);
      final ev2Long = detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 2);
      expect(ev2Long, isNotNull);
      expect(ev2Long!.type, equals(FrameTransitionType.blackScreenEnded));
    });

    test('single-frame flash does NOT false-trigger even when pollInterval >= minTransitionDuration', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      // Single 400ms poll gap after 1 isolated black/white sample must NOT emit
      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 1), isNull);
      clock += const Duration(milliseconds: 400);
      expect(detector.analyzeLuminance(avgLuma: 2, stdDev: 0, slotId: 1), isNull);
      clock += const Duration(milliseconds: 400);
      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 1), isNull);

      // Same for single white flash
      clock += const Duration(milliseconds: 400);
      expect(detector.analyzeLuminance(avgLuma: 250, stdDev: 0, slotId: 1), isNull);
      clock += const Duration(milliseconds: 400);
      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 1), isNull);
    });

    test('normal -> black (>= minDuration) -> brief white flash (< minDuration) -> normal emits blackScreenEnded', () {
      var clock = Duration.zero;
      final detector = FrameTransitionDetector(
        minTransitionDuration: const Duration(milliseconds: 300),
        elapsedClock: () => clock,
      );

      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 1), isNull);
      clock += const Duration(milliseconds: 50);
      expect(detector.analyzeLuminance(avgLuma: 2, stdDev: 0, slotId: 1), isNull);
      clock += const Duration(milliseconds: 400);
      expect(detector.analyzeLuminance(avgLuma: 2, stdDev: 0, slotId: 1), isNull);
      clock += const Duration(milliseconds: 400);
      // Brief white flash right after valid black -> emits blackScreenEnded on boundary instead of losing transition
      final boundaryEv = detector.analyzeLuminance(avgLuma: 250, stdDev: 0, slotId: 1);
      expect(boundaryEv, isNotNull);
      expect(boundaryEv!.type, equals(FrameTransitionType.blackScreenEnded));

      // Returning to normal after the brief (<300ms) white flash does NOT double-emit
      clock += const Duration(milliseconds: 120);
      expect(detector.analyzeLuminance(avgLuma: 120, stdDev: 5, slotId: 1), isNull);
    });
  });
}
