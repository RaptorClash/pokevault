import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/scanner_core/media/visual_shiny_detector.dart';

CapturedFrame _makeSolidBgraFrame({
  required int width,
  required int height,
  required int r,
  required int g,
  required int b,
  String pixelFormat = 'bgra8888',
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
    pixelFormat: pixelFormat,
  );
}

void main() {
  group('SparkleDelayDetector', () {
    test('learns baseline over first 3 encounters without false positives, then detects delayed shiny without polluting baseline', () {
      final detector = SparkleDelayDetector();
      var now = Duration.zero;

      // 3 normal encounters (~1500ms)
      for (final ms in [1500, 1550, 1480]) {
        detector.onEncounterCounted(1, now);
        now += Duration(milliseconds: ms);
        final sig = detector.onBattleMenuSeen(
          1,
          now,
          delayThresholdMs: 1000,
        );
        expect(sig, isNull);
        now += const Duration(seconds: 2);
      }

      // 4th encounter: +1300ms sparkle delay (2800ms total vs ~1500ms median)
      detector.onEncounterCounted(1, now);
      now += const Duration(milliseconds: 2800);
      final shinySig = detector.onBattleMenuSeen(
        1,
        now,
        delayThresholdMs: 1000,
      );
      expect(shinySig, isNotNull);
      expect(shinySig!.slotId, equals(1));
      expect(shinySig.source, equals(ShinyDetectionSource.sparkleDelay));
      expect(shinySig.score, greaterThanOrEqualTo(1000));

      // 5th encounter: back to normal 1520ms -> must still NOT trigger (baseline unpolluted)
      now += const Duration(seconds: 2);
      detector.onEncounterCounted(1, now);
      now += const Duration(milliseconds: 1520);
      expect(
        detector.onBattleMenuSeen(1, now, delayThresholdMs: 1000),
        isNull,
      );
    });

    test('ignores AFK outliers (>15s) and too-fast noise (<200ms)', () {
      final detector = SparkleDelayDetector();
      var now = Duration.zero;

      for (final ms in [1200, 1250, 1220]) {
        detector.onEncounterCounted(1, now);
        now += Duration(milliseconds: ms);
        expect(detector.onBattleMenuSeen(1, now, delayThresholdMs: 800), isNull);
        now += const Duration(seconds: 1);
      }

      // AFK pause 20 seconds
      detector.onEncounterCounted(1, now);
      now += const Duration(seconds: 20);
      expect(detector.onBattleMenuSeen(1, now, delayThresholdMs: 800), isNull);

      // Too fast < 200ms
      detector.onEncounterCounted(1, now);
      now += const Duration(milliseconds: 100);
      expect(detector.onBattleMenuSeen(1, now, delayThresholdMs: 800), isNull);
    });

    test('isolates baselines across slots and supports reset', () {
      final detector = SparkleDelayDetector();
      var now = Duration.zero;

      for (final ms in [1000, 1020, 990]) {
        detector.onEncounterCounted(1, now);
        now += Duration(milliseconds: ms);
        detector.onBattleMenuSeen(1, now, delayThresholdMs: 800);
        now += const Duration(seconds: 1);
      }

      // Slot 2 has 0 baseline samples -> 2500ms must NOT trigger yet
      detector.onEncounterCounted(2, now);
      now += const Duration(milliseconds: 2500);
      expect(detector.onBattleMenuSeen(2, now, delayThresholdMs: 800), isNull);

      detector.reset(1);
      detector.onEncounterCounted(1, now);
      now += const Duration(milliseconds: 2500);
      expect(detector.onBattleMenuSeen(1, now, delayThresholdMs: 800), isNull);

      detector.reset();
    });
  });

  group('VisualShinyColorDetector', () {
    test('learns per-(slot, species) baseline and detects vivid hue shift without polluting baseline', () {
      final detector = VisualShinyColorDetector();
      final blueFrame = _makeSolidBgraFrame(width: 64, height: 64, r: 30, g: 110, b: 235);
      final greenFrame = _makeSolidBgraFrame(width: 64, height: 64, r: 30, g: 220, b: 65);

      for (int i = 0; i < 3; i++) {
        final sig = detector.analyzeEncounterFrame(
          blueFrame,
          slotId: 1,
          speciesKey: '25',
          deviationThreshold: 0.38,
        );
        expect(sig, isNull);
      }

      final shinySig = detector.analyzeEncounterFrame(
        greenFrame,
        slotId: 1,
        speciesKey: '25',
        deviationThreshold: 0.38,
      );
      expect(shinySig, isNotNull);
      expect(shinySig!.slotId, equals(1));
      expect(shinySig.source, equals(ShinyDetectionSource.colorDeviation));
      expect(shinySig.score, greaterThanOrEqualTo(0.38));

      // Subsequent normal blue frame still matches baseline cleanly
      expect(
        detector.analyzeEncounterFrame(
          blueFrame,
          slotId: 1,
          speciesKey: '25',
          deviationThreshold: 0.38,
        ),
        isNull,
      );
    });

    test('rejects low-chroma black/white/gray frames and invalid pixel formats', () {
      final detector = VisualShinyColorDetector();
      final black = _makeSolidBgraFrame(width: 32, height: 32, r: 5, g: 5, b: 5);
      final white = _makeSolidBgraFrame(width: 32, height: 32, r: 248, g: 248, b: 248);
      final gray = _makeSolidBgraFrame(width: 32, height: 32, r: 128, g: 128, b: 128);
      final wrongFmt = _makeSolidBgraFrame(
        width: 32,
        height: 32,
        r: 20,
        g: 220,
        b: 20,
        pixelFormat: 'png',
      );
      const empty = CapturedFrame(width: 0, height: 0, bytes: [], pixelFormat: 'bgra8888');

      for (final f in [black, white, gray, wrongFmt, empty]) {
        expect(
          detector.analyzeEncounterFrame(
            f,
            slotId: 1,
            speciesKey: '4',
            deviationThreshold: 0.3,
          ),
          isNull,
        );
      }
    });

    test('isolates baselines across species and resets cleanly', () {
      final detector = VisualShinyColorDetector();
      final blue = _makeSolidBgraFrame(width: 48, height: 48, r: 30, g: 110, b: 235);
      final red = _makeSolidBgraFrame(width: 48, height: 48, r: 230, g: 45, b: 45);

      for (int i = 0; i < 3; i++) {
        detector.analyzeEncounterFrame(
          blue,
          slotId: 1,
          speciesKey: 'species_a',
          deviationThreshold: 0.35,
        );
      }

      // Different species has no baseline yet
      expect(
        detector.analyzeEncounterFrame(
          red,
          slotId: 1,
          speciesKey: 'species_b',
          deviationThreshold: 0.35,
        ),
        isNull,
      );

      detector.reset(1);
      expect(
        detector.analyzeEncounterFrame(
          red,
          slotId: 1,
          speciesKey: 'species_a',
          deviationThreshold: 0.35,
        ),
        isNull,
      );
    });
  });
}
