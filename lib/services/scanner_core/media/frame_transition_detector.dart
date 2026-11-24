import 'dart:math' as math;
import '../../desktop_tracker/desktop_capture_driver.dart';

/// Visual screen-transition edge detected on a slot's captured frame.
enum FrameTransitionType {
  blackScreenEnded,
  whiteScreenEnded,
}

/// Immutable event emitted when a slot finishes a solid black/white screen transition.
class FrameTransitionEvent {
  final int slotId;
  final FrameTransitionType type;
  final int durationMs;
  final double averageLuma;
  final DateTime timestamp;

  const FrameTransitionEvent({
    required this.slotId,
    required this.type,
    required this.durationMs,
    required this.averageLuma,
    required this.timestamp,
  });
}

enum _SlotLuminanceState {
  normal,
  inBlack,
  inWhite,
}

class _SlotTracker {
  _SlotLuminanceState state = _SlotLuminanceState.normal;
  bool hasSeenNormal = false;
  Duration? transitionStartedAt;
}

/// Cross-platform luminance edge detector for detecting soft-resets and loading screens.
///
/// Tracks per-slot transitions (`normal -> black/white (>= minTransitionDuration) -> normal`)
/// with hysteresis and ignores brief flicker or static continuous dark/white frames.
class FrameTransitionDetector {
  int blackThreshold;
  int whiteThreshold;
  final int hysteresisMargin;
  final double maxSolidStdDev;
  Duration minTransitionDuration;
  final Duration Function()? elapsedClock;
  final Stopwatch _monotonic = Stopwatch()..start();
  final Map<int, _SlotTracker> _slots = {};

  FrameTransitionDetector({
    this.blackThreshold = 18,
    this.whiteThreshold = 240,
    this.hysteresisMargin = 10,
    this.maxSolidStdDev = 22.0,
    this.minTransitionDuration = const Duration(milliseconds: 300),
    this.elapsedClock,
  });

  void setMinTransitionDuration(Duration duration) {
    final clampedMs = duration.inMilliseconds.clamp(150, 5000);
    minTransitionDuration = Duration(milliseconds: clampedMs);
  }

  void updateThresholds({int? blackThreshold, int? whiteThreshold}) {
    if (blackThreshold != null) {
      this.blackThreshold = blackThreshold.clamp(5, 80);
    }
    if (whiteThreshold != null) {
      this.whiteThreshold = whiteThreshold.clamp(175, 252);
    }
  }

  Duration get _now => elapsedClock?.call() ?? _monotonic.elapsed;

  /// Clears transition state for [slotId], or all slots if omitted.
  void reset([int? slotId]) {
    if (slotId != null) {
      _slots.remove(slotId);
    } else {
      _slots.clear();
    }
  }

  /// Samples average BT.601 luminance and standard deviation of [frame] (`bgra8888`),
  /// or returns `null` if invalid.
  static ({double avgLuma, double stdDev})? sampleFrameLuminance(
    CapturedFrame frame,
  ) {
    if (frame.width <= 0 || frame.height <= 0) return null;
    if (frame.pixelFormat != 'bgra8888') return null;
    final expectedBytes = frame.width * frame.height * 4;
    if (frame.bytes.length < expectedBytes || expectedBytes < 4) return null;

    final totalPixels = frame.width * frame.height;
    final step = totalPixels > 2400 ? totalPixels ~/ 1200 : 1;
    int sum = 0;
    int sumSq = 0;
    int count = 0;

    for (int px = 0; px < totalPixels; px += step) {
      final idx = px * 4;
      final b = frame.bytes[idx];
      final g = frame.bytes[idx + 1];
      final r = frame.bytes[idx + 2];
      final luma = (r * 299 + g * 587 + b * 114) ~/ 1000;
      sum += luma;
      sumSq += luma * luma;
      count++;
    }
    if (count == 0) return null;
    final mean = sum / count;
    final variance = math.max(0.0, (sumSq / count) - (mean * mean));
    return (avgLuma: mean, stdDev: math.sqrt(variance));
  }

  /// Samples average BT.601 luminance of [frame] (`bgra8888`), or returns `null` if invalid.
  static double? sampleAverageLuma(CapturedFrame frame) {
    return sampleFrameLuminance(frame)?.avgLuma;
  }

  /// Analyzes [frame] for [slotId] and returns a [FrameTransitionEvent] only when
  /// a valid uniform black or white transition ends and returns to normal imagery.
  FrameTransitionEvent? analyzeFrame(CapturedFrame frame, {int slotId = 0}) {
    final sample = sampleFrameLuminance(frame);
    if (sample == null) return null;
    final avgLuma = sample.avgLuma;
    final stdDev = sample.stdDev;

    final tracker = _slots.putIfAbsent(slotId, _SlotTracker.new);
    final now = _now;

    switch (tracker.state) {
      case _SlotLuminanceState.normal:
        if (avgLuma <= blackThreshold && stdDev <= maxSolidStdDev) {
          tracker.state = _SlotLuminanceState.inBlack;
          tracker.transitionStartedAt = now;
        } else if (avgLuma >= whiteThreshold && stdDev <= maxSolidStdDev) {
          tracker.state = _SlotLuminanceState.inWhite;
          tracker.transitionStartedAt = now;
        } else {
          tracker.hasSeenNormal = true;
        }
        return null;

      case _SlotLuminanceState.inBlack:
        if (avgLuma <= blackThreshold + hysteresisMargin &&
            stdDev <= maxSolidStdDev + 6.0) {
          return null;
        }
        final started = tracker.transitionStartedAt;
        final duration = started != null ? now - started : Duration.zero;
        final validNormalRecovery =
            tracker.hasSeenNormal && duration >= minTransitionDuration;

        if (avgLuma >= whiteThreshold && stdDev <= maxSolidStdDev) {
          tracker.state = _SlotLuminanceState.inWhite;
          tracker.transitionStartedAt = now;
          return null;
        }
        tracker.state = _SlotLuminanceState.normal;
        tracker.hasSeenNormal = true;
        tracker.transitionStartedAt = null;

        if (validNormalRecovery) {
          return FrameTransitionEvent(
            slotId: slotId,
            type: FrameTransitionType.blackScreenEnded,
            durationMs: duration.inMilliseconds,
            averageLuma: avgLuma,
            timestamp: DateTime.now(),
          );
        }
        return null;

      case _SlotLuminanceState.inWhite:
        if (avgLuma >= whiteThreshold - hysteresisMargin &&
            stdDev <= maxSolidStdDev + 6.0) {
          return null;
        }
        final started = tracker.transitionStartedAt;
        final duration = started != null ? now - started : Duration.zero;
        final validNormalRecovery =
            tracker.hasSeenNormal && duration >= minTransitionDuration;

        if (avgLuma <= blackThreshold && stdDev <= maxSolidStdDev) {
          tracker.state = _SlotLuminanceState.inBlack;
          tracker.transitionStartedAt = now;
          return null;
        }
        tracker.state = _SlotLuminanceState.normal;
        tracker.hasSeenNormal = true;
        tracker.transitionStartedAt = null;

        if (validNormalRecovery) {
          return FrameTransitionEvent(
            slotId: slotId,
            type: FrameTransitionType.whiteScreenEnded,
            durationMs: duration.inMilliseconds,
            averageLuma: avgLuma,
            timestamp: DateTime.now(),
          );
        }
        return null;
    }
  }
}
