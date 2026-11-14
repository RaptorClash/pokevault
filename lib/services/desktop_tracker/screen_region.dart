import 'dart:math' as math;
import 'dart:ui';

/// Represents a designated screen or window region for capture and text recognition.
class ScreenRegion {
  final double x;
  final double y;
  final double width;
  final double height;
  final bool isAbsoluteScreen;
  final String? label;

  ScreenRegion({
    required this.x,
    required this.y,
    required double width,
    required double height,
    this.isAbsoluteScreen = false,
    this.label,
  })  : width = math.max(10.0, width),
        height = math.max(10.0, height);

  factory ScreenRegion.fromRect(
    Rect rect, {
    bool isAbsoluteScreen = false,
    String? label,
  }) {
    return ScreenRegion(
      x: rect.left,
      y: rect.top,
      width: rect.width,
      height: rect.height,
      isAbsoluteScreen: isAbsoluteScreen,
      label: label,
    );
  }

  Rect toRect() => Rect.fromLTWH(x, y, width, height);

  String get description {
    final w = width.round();
    final h = height.round();
    if (label != null && label!.isNotEmpty) {
      return '$label (${w}x$h px)';
    }
    return '${w}x$h px';
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isAbsoluteScreen': isAbsoluteScreen,
      'label': label,
    };
  }

  factory ScreenRegion.fromMap(Map<String, dynamic> map) {
    return ScreenRegion(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 100.0,
      height: (map['height'] as num?)?.toDouble() ?? 100.0,
      isAbsoluteScreen: map['isAbsoluteScreen'] as bool? ?? false,
      label: map['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScreenRegion) return false;
    return (x - other.x).abs() < 0.001 &&
        (y - other.y).abs() < 0.001 &&
        (width - other.width).abs() < 0.001 &&
        (height - other.height).abs() < 0.001 &&
        isAbsoluteScreen == other.isAbsoluteScreen &&
        label == other.label;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height, isAbsoluteScreen, label);

  @override
  String toString() =>
      'ScreenRegion(x: $x, y: $y, w: $width, h: $height, abs: $isAbsoluteScreen, label: $label)';
}
