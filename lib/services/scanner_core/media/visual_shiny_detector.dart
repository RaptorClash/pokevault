import 'dart:math' as math;
import '../../desktop_tracker/desktop_capture_driver.dart';

/// Origin that triggered a Shiny alert or pause.
enum ShinyDetectionSource {
  ocrText,
  sparkleDelay,
  colorDeviation,
}

/// Visual Shiny suspect signal produced by [SparkleDelayDetector] or [VisualShinyColorDetector].
class VisualShinySignal {
  final int slotId;
  final ShinyDetectionSource source;
  final double score;
  final String details;
  final DateTime timestamp;

  const VisualShinySignal({
    required this.slotId,
    required this.source,
    required this.score,
    required this.details,
    required this.timestamp,
  });
}

class _DelaySlotState {
  Duration? encounterStartedAt;
  final List<int> baselineMs = [];
}

/// Detects Shiny sparkle animations by measuring per-slot latency between
/// encounter start and battle command menu appearance against a learned median baseline.
class SparkleDelayDetector {
  static const int minBaselineSamples = 3;
  static const int maxBaselineSamples = 10;
  static const int minValidDurationMs = 200;
  static const int maxValidDurationMs = 15000;

  final Map<int, _DelaySlotState> _slots = {};

  void onEncounterCounted(int slotId, Duration now) {
    final state = _slots.putIfAbsent(slotId, _DelaySlotState.new);
    state.encounterStartedAt = now;
  }

  void clearPendingEncounter(int slotId) {
    _slots[slotId]?.encounterStartedAt = null;
  }

  VisualShinySignal? onBattleMenuSeen(
    int slotId,
    Duration now, {
    required int delayThresholdMs,
  }) {
    final state = _slots[slotId];
    final startedAt = state?.encounterStartedAt;
    if (state == null || startedAt == null) return null;

    state.encounterStartedAt = null;
    final elapsedMs = (now - startedAt).inMilliseconds;
    if (elapsedMs < minValidDurationMs || elapsedMs > maxValidDurationMs) {
      return null;
    }

    if (state.baselineMs.length < minBaselineSamples) {
      state.baselineMs.add(elapsedMs);
      return null;
    }

    final sorted = List<int>.from(state.baselineMs)..sort();
    final medianMs = sorted[sorted.length ~/ 2];
    final deltaMs = elapsedMs - medianMs;

    if (deltaMs >= delayThresholdMs) {
      return VisualShinySignal(
        slotId: slotId,
        source: ShinyDetectionSource.sparkleDelay,
        score: deltaMs.toDouble(),
        details: '+${deltaMs}ms',
        timestamp: DateTime.now(),
      );
    }

    state.baselineMs.add(elapsedMs);
    if (state.baselineMs.length > maxBaselineSamples) {
      state.baselineMs.removeAt(0);
    }
    return null;
  }

  void reset([int? slotId]) {
    if (slotId != null) {
      _slots.remove(slotId);
    } else {
      _slots.clear();
    }
  }
}

class _ColorBaseline {
  final List<double> meanHist = List<double>.filled(16, 0.0);
  int sampleCount = 0;
}

/// Detects Shiny palette shifts from captured BGRA8888 frames using a compact 16-bin
/// normalized HSV signature per `(slotId, speciesKey)` with rolling baseline learning.
class VisualShinyColorDetector {
  static const int minBaselineSamples = 3;
  static const int maxBaselineSamples = 12;
  static const double minChromaRatio = 0.08;

  final Map<String, _ColorBaseline> _baselines = {};

  static String _key(int slotId, String speciesKey) => '$slotId::$speciesKey';

  /// Extracts a 16-bin normalized HSV histogram from the center 60% of [frame]
  /// (`bgra8888`), or returns `null` if the frame is invalid or lacks chroma.
  static List<double>? extractHistogram(CapturedFrame frame) {
    if (frame.width <= 0 || frame.height <= 0) return null;
    if (frame.pixelFormat != 'bgra8888') return null;
    final expectedBytes = frame.width * frame.height * 4;
    if (frame.bytes.length < expectedBytes || expectedBytes < 4) return null;

    final x0 = (frame.width * 0.2).floor();
    final x1 = math.max(x0 + 1, (frame.width * 0.8).ceil());
    final y0 = (frame.height * 0.2).floor();
    final y1 = math.max(y0 + 1, (frame.height * 0.8).ceil());

    final regionW = x1 - x0;
    final regionH = y1 - y0;
    final regionPixels = regionW * regionH;
    final stride = math.max(1, math.sqrt(regionPixels / 1200).floor());

    final bins = List<double>.filled(16, 0.0);
    int totalSampled = 0;
    int chromaCount = 0;

    for (int y = y0; y < y1; y += stride) {
      final rowOffset = y * frame.width;
      for (int x = x0; x < x1; x += stride) {
        final idx = (rowOffset + x) * 4;
        final b = frame.bytes[idx] / 255.0;
        final g = frame.bytes[idx + 1] / 255.0;
        final r = frame.bytes[idx + 2] / 255.0;

        final maxC = math.max(r, math.max(g, b));
        final minC = math.min(r, math.min(g, b));
        final delta = maxC - minC;
        final val = maxC;
        final sat = maxC > 0 ? delta / maxC : 0.0;

        totalSampled++;
        if (sat >= 0.22 && val >= 0.18 && val <= 0.96 && delta > 0.001) {
          chromaCount++;
          double hue;
          if (maxC == r) {
            hue = 60.0 * (((g - b) / delta) % 6.0);
          } else if (maxC == g) {
            hue = 60.0 * (((b - r) / delta) + 2.0);
          } else {
            hue = 60.0 * (((r - g) / delta) + 4.0);
          }
          if (hue < 0) hue += 360.0;
          final hueBin = ((hue / 30.0).floor()).clamp(0, 11);
          bins[hueBin] += 1.0;
        } else {
          final vBin = (val * 4.0).floor().clamp(0, 3);
          bins[12 + vBin] += 1.0;
        }
      }
    }

    if (totalSampled == 0) return null;
    if (chromaCount / totalSampled < minChromaRatio) return null;

    for (int i = 0; i < 16; i++) {
      bins[i] /= totalSampled;
    }
    return bins;
  }

  VisualShinySignal? analyzeEncounterFrame(
    CapturedFrame frame, {
    required int slotId,
    required String speciesKey,
    required double deviationThreshold,
  }) {
    final hist = extractHistogram(frame);
    if (hist == null) return null;
    return analyzeHistogram(
      hist,
      slotId: slotId,
      speciesKey: speciesKey,
      deviationThreshold: deviationThreshold,
    );
  }

  /// Evaluates a precomputed 16-bin normalized HSV histogram against the learned
  /// baseline for `(slotId, speciesKey)` and returns a signal if deviation >= [deviationThreshold].
  VisualShinySignal? analyzeHistogram(
    List<double> hist, {
    required int slotId,
    required String speciesKey,
    required double deviationThreshold,
  }) {
    if (hist.length != 16) return null;

    final k = _key(slotId, speciesKey);
    final baseline = _baselines.putIfAbsent(k, _ColorBaseline.new);

    if (baseline.sampleCount < minBaselineSamples) {
      _updateBaseline(baseline, hist);
      return null;
    }

    double l1 = 0.0;
    for (int i = 0; i < 16; i++) {
      l1 += (hist[i] - baseline.meanHist[i]).abs();
    }
    final distance = (0.5 * l1).clamp(0.0, 1.0);

    if (distance >= deviationThreshold) {
      final pct = (distance * 100).round();
      return VisualShinySignal(
        slotId: slotId,
        source: ShinyDetectionSource.colorDeviation,
        score: distance,
        details: '$pct%',
        timestamp: DateTime.now(),
      );
    }

    _updateBaseline(baseline, hist);
    return null;
  }

  void _updateBaseline(_ColorBaseline baseline, List<double> hist) {
    final n = math.min(baseline.sampleCount, maxBaselineSamples - 1);
    final weightNew = 1.0 / (n + 1);
    final weightOld = 1.0 - weightNew;
    for (int i = 0; i < 16; i++) {
      baseline.meanHist[i] =
          baseline.meanHist[i] * weightOld + hist[i] * weightNew;
    }
    if (baseline.sampleCount < maxBaselineSamples) {
      baseline.sampleCount++;
    }
  }

  void reset([int? slotId]) {
    if (slotId != null) {
      final prefix = '$slotId::';
      _baselines.removeWhere((k, _) => k.startsWith(prefix));
    } else {
      _baselines.clear();
    }
  }
}
