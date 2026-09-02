import 'dart:ui';
import 'package:flutter/material.dart';

class HolePainter extends CustomPainter {
  final Rect? rect;

  HolePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (rect != null) {
      path.addRRect(RRect.fromRectAndRadius(rect!, const Radius.circular(16)));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) =>
      oldDelegate.rect != rect;
}

class LightningPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;

  LightningPainter({
    required this.start,
    required this.end,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0 || progress <= 0.0) return;

    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(
        alpha: (1.0 - progress).clamp(0.0, 1.0),
      )
      ..strokeWidth = 3 + (5 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    int steps = 6;
    for (int i = 1; i <= steps; i++) {
      double t = i / steps;
      double dx = lerpDouble(start.dx, end.dx, t)!;
      double dy = lerpDouble(start.dy, end.dy, t)!;

      if (i < steps) {
        dx += (i % 2 == 0 ? 30 : -30);
        dy += (i % 2 == 0 ? -30 : 30);
      }

      path.lineTo(dx, dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.start != start;
}
