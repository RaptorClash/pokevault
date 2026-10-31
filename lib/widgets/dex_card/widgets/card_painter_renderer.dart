import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Status of an individual PC Box or Box partition on the completion card.
class CardBoxItemStatus {
  final int caught;
  final int capacity;
  final Color color;
  final bool isFull;
  final bool isPartial;
  final bool isEmpty;

  const CardBoxItemStatus({
    required this.caught,
    required this.capacity,
    required this.color,
    required this.isFull,
    required this.isPartial,
    required this.isEmpty,
  });
}

/// Aggregated PC Box metrics for Living Dex cards.
class CardBoxDetails {
  final int totalBoxes;
  final int fullBoxes;
  final int partialBoxes;
  final int emptyBoxes;
  final int gapsRemaining;

  const CardBoxDetails({
    required this.totalBoxes,
    required this.fullBoxes,
    required this.partialBoxes,
    required this.emptyBoxes,
    required this.gapsRemaining,
  });
}

/// Aggregated special collection stats (Shinies, Alphas, Ribbons, etc.).
class CardSpecialStats {
  final int shinies;
  final int alphas;
  final int ribbons;
  final int teraTypes;
  final int languages;

  const CardSpecialStats({
    required this.shinies,
    required this.alphas,
    required this.ribbons,
    required this.teraTypes,
    required this.languages,
  });
}

typedef BoxItemStatus = CardBoxItemStatus;
typedef BoxDetails = CardBoxDetails;
typedef SpecialStats = CardSpecialStats;

/// Custom painter for drawing smooth circular progress gauges without raster artifacts.
class CircularGaugePainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  CircularGaugePainter({
    required this.percentage,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = (percentage.clamp(0.0, 100.0) / 100.0) * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

/// Custom painter for rendering the entire Living Dex as an adaptive visual grid heatmap.
/// Mathematically guarantees that ALL entries fit into the canvas without clipping or truncation.
class MosaicHeatmapPainter extends CustomPainter {
  final List<Color> itemColors;
  final double scale;

  MosaicHeatmapPainter({
    required this.itemColors,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int n = itemColors.length;
    if (n == 0 || size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final double a = w / h;

    final int bestC = (math.sqrt(n * a)).round().clamp(1, n);
    double bestCellSize = -1.0;
    int optimalC = bestC;
    int optimalR = (n / bestC).ceil();
    double optimalGap = 1.0;

    for (int testC = math.max(1, bestC - 5);
        testC <= math.min(n, bestC + 5);
        testC++) {
      final testR = (n / testC).ceil();
      final idealGap = math.min(
          2.5 * scale, math.min((w / testC) * 0.15, (h / testR) * 0.15));
      final testGap = math.max(0.0, idealGap);
      final cellW = (w - (testC - 1) * testGap) / testC;
      final cellH = (h - (testR - 1) * testGap) / testR;
      final s = math.min(cellW, cellH);
      if (s > bestCellSize) {
        bestCellSize = s;
        optimalC = testC;
        optimalR = testR;
        optimalGap = testGap;
      }
    }

    if (bestCellSize <= 0) return;

    final double gridW = optimalC * bestCellSize + (optimalC - 1) * optimalGap;
    final double gridH = optimalR * bestCellSize + (optimalR - 1) * optimalGap;
    final double startX = (w - gridW) / 2;
    final double startY = (h - gridH) / 2;

    final double cornerRadius = (bestCellSize * 0.2).clamp(0.5, 4.0 * scale);
    final Radius r = Radius.circular(cornerRadius);

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final col = i % optimalC;
      final row = i ~/ optimalC;
      final x = startX + col * (bestCellSize + optimalGap);
      final y = startY + row * (bestCellSize + optimalGap);
      final rect = Rect.fromLTWH(x, y, bestCellSize, bestCellSize);

      paint.color = itemColors[i];
      if (bestCellSize >= 6.0 && cornerRadius >= 1.0) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, r), paint);
      } else {
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MosaicHeatmapPainter oldDelegate) {
    if (oldDelegate.scale != scale ||
        oldDelegate.itemColors.length != itemColors.length) {
      return true;
    }
    for (int i = 0; i < itemColors.length; i++) {
      if (oldDelegate.itemColors[i] != itemColors[i]) {
        return true;
      }
    }
    return false;
  }
}
