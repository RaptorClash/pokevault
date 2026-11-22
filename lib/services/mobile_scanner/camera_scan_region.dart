import 'dart:math' as math;
import 'dart:ui';
import '../scanner_core/models/scanner_settings.dart';

/// Semantic role of a user-drawn camera scan rectangle.
enum CameraZoneRole {
  /// Primary text/dialogue/catch zone (Zone A, green).
  scan,

  /// Opponent HUD live-focus zone (Zone B, cyan, encounter-only).
  focus,

  /// Additional coupled multi-instance scan zone (#1, #2, ...).
  multiInstance,
}

/// Active camera scan mode on mobile.
enum MobileCameraScanMode {
  /// Scans the entire visible camera frame (or selected preset region).
  autoFull,

  /// Scans strictly inside user-drawn rectangles on the camera preview.
  customRegions,
}

/// Visual layout mode for the Mobile Camera Tracker.
enum MobileScannerViewMode {
  /// Fullscreen camera preview with compact floating HUD & collapsible bottom drawer.
  fullscreen,

  /// Split-screen: live camera & zone editor on top, tabbed tracker dashboard below.
  split,

  /// Minimized draggable in-app Picture-in-Picture overlay over the rest of PokéVault.
  pip,
}

/// Normalized (`0.0 .. 1.0`) rectangle relative to the upright camera frame.
class NormalizedScanRect {
  static const double minSize = 0.04;

  final String id;
  final CameraZoneRole role;
  final int? slotId;
  final double left;
  final double top;
  final double width;
  final double height;
  final int colorHex;
  final String label;
  final bool encounterOnly;
  final bool enabled;

  factory NormalizedScanRect({
    required String id,
    required CameraZoneRole role,
    int? slotId,
    required double left,
    required double top,
    required double width,
    required double height,
    required int colorHex,
    required String label,
    bool encounterOnly = false,
    bool enabled = true,
  }) {
    final safeW = width.clamp(minSize, 1.0).toDouble();
    final safeH = height.clamp(minSize, 1.0).toDouble();
    final safeL = left.clamp(0.0, 1.0 - safeW).toDouble();
    final safeT = top.clamp(0.0, 1.0 - safeH).toDouble();
    return NormalizedScanRect._(
      id: id,
      role: role,
      slotId: slotId,
      left: safeL,
      top: safeT,
      width: safeW,
      height: safeH,
      colorHex: colorHex,
      label: label,
      encounterOnly: encounterOnly,
      enabled: enabled,
    );
  }

  const NormalizedScanRect._({
    required this.id,
    required this.role,
    this.slotId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.colorHex,
    required this.label,
    required this.encounterOnly,
    required this.enabled,
  });

  /// Creates a [NormalizedScanRect] from pixel coordinates within a frame of size [frameWidth] x [frameHeight].
  factory NormalizedScanRect.fromPixelRect({
    required String id,
    required CameraZoneRole role,
    required Rect pixelRect,
    required double frameWidth,
    required double frameHeight,
    required int colorHex,
    required String label,
    int? slotId,
    bool encounterOnly = false,
    bool enabled = true,
  }) {
    final safeFw = math.max(1.0, frameWidth);
    final safeFh = math.max(1.0, frameHeight);
    return NormalizedScanRect(
      id: id,
      role: role,
      slotId: slotId,
      left: pixelRect.left / safeFw,
      top: pixelRect.top / safeFh,
      width: pixelRect.width / safeFw,
      height: pixelRect.height / safeFh,
      colorHex: colorHex,
      label: label,
      encounterOnly: encounterOnly,
      enabled: enabled,
    );
  }

  Rect toNormalizedRect() => Rect.fromLTWH(left, top, width, height);

  /// Converts normalized coordinates into pixel coordinates for a target canvas or frame.
  Rect toPixelRect(double targetWidth, double targetHeight) {
    return Rect.fromLTWH(
      left * targetWidth,
      top * targetHeight,
      width * targetWidth,
      height * targetHeight,
    );
  }

  NormalizedScanRect copyWith({
    String? id,
    CameraZoneRole? role,
    int? slotId,
    double? left,
    double? top,
    double? width,
    double? height,
    int? colorHex,
    String? label,
    bool? encounterOnly,
    bool? enabled,
  }) {
    return NormalizedScanRect(
      id: id ?? this.id,
      role: role ?? this.role,
      slotId: slotId ?? this.slotId,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      colorHex: colorHex ?? this.colorHex,
      label: label ?? this.label,
      encounterOnly: encounterOnly ?? this.encounterOnly,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.name,
        if (slotId != null) 'slotId': slotId,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'colorHex': colorHex,
        'label': label,
        'encounterOnly': encounterOnly,
        'enabled': enabled,
      };

  factory NormalizedScanRect.fromMap(Map<String, dynamic> map) {
    CameraZoneRole parsedRole = CameraZoneRole.scan;
    final roleName = map['role']?.toString();
    for (final value in CameraZoneRole.values) {
      if (value.name == roleName) {
        parsedRole = value;
        break;
      }
    }
    return NormalizedScanRect(
      id: map['id']?.toString() ?? 'zone_a',
      role: parsedRole,
      slotId: (map['slotId'] as num?)?.toInt(),
      left: (map['left'] as num?)?.toDouble() ?? 0.05,
      top: (map['top'] as num?)?.toDouble() ?? 0.65,
      width: (map['width'] as num?)?.toDouble() ?? 0.9,
      height: (map['height'] as num?)?.toDouble() ?? 0.25,
      colorHex: (map['colorHex'] as num?)?.toInt() ?? 0xFF10B981,
      label: map['label']?.toString() ?? 'Zone A',
      encounterOnly: map['encounterOnly'] as bool? ?? false,
      enabled: map['enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NormalizedScanRect) return false;
    return id == other.id &&
        role == other.role &&
        slotId == other.slotId &&
        (left - other.left).abs() < 0.0001 &&
        (top - other.top).abs() < 0.0001 &&
        (width - other.width).abs() < 0.0001 &&
        (height - other.height).abs() < 0.0001 &&
        colorHex == other.colorHex &&
        label == other.label &&
        encounterOnly == other.encounterOnly &&
        enabled == other.enabled;
  }

  @override
  int get hashCode => Object.hash(
        id,
        role,
        slotId,
        left,
        top,
        width,
        height,
        colorHex,
        label,
        encounterOnly,
        enabled,
      );
}

/// Identifies a specific drawing brush target on the mobile camera overlay.
class CameraBrushTarget {
  final CameraZoneRole role;
  final int slotId;
  final bool encounterOnly;
  final int colorHex;
  final String label;

  const CameraBrushTarget({
    required this.role,
    required this.slotId,
    required this.encounterOnly,
    required this.colorHex,
    required this.label,
  });

  /// Stable region ID generated when drawing with this brush.
  String get regionId {
    if (role == CameraZoneRole.scan) return 'zone_a';
    if (role == CameraZoneRole.focus) return 'zone_b';
    return 'multi_${slotId}_${encounterOnly ? 'focus' : 'scan'}';
  }

  /// Primary Zone A (Scan) brush for main instance #1.
  factory CameraBrushTarget.zoneA() => const CameraBrushTarget(
        role: CameraZoneRole.scan,
        slotId: 1,
        encounterOnly: false,
        colorHex: 0xFF10B981,
        label: 'Zone A · Scan',
      );

  /// Primary Zone B (Focus, encounter-only) brush for main instance #1.
  factory CameraBrushTarget.zoneB() => const CameraBrushTarget(
        role: CameraZoneRole.focus,
        slotId: 1,
        encounterOnly: true,
        colorHex: 0xFF06B6D4,
        label: 'Zone B · Fokus',
      );

  /// Multi-instance Zone A (Scan) brush for [slotId] (#2, #3, ...).
  factory CameraBrushTarget.multiScan(int slotId) {
    final colorHex =
        MultiInstanceGridHelper.colorForIndex(slotId > 0 ? slotId - 1 : 0);
    return CameraBrushTarget(
      role: CameraZoneRole.multiInstance,
      slotId: slotId,
      encounterOnly: false,
      colorHex: colorHex,
      label: '#$slotId Zone A · Scan',
    );
  }

  /// Multi-instance Zone B (Focus, encounter-only) brush for [slotId] (#2, #3, ...).
  factory CameraBrushTarget.multiFocus(int slotId) {
    final colorHex =
        MultiInstanceGridHelper.colorForIndex(slotId > 0 ? slotId - 1 : 0);
    return CameraBrushTarget(
      role: CameraZoneRole.multiInstance,
      slotId: slotId,
      encounterOnly: true,
      colorHex: colorHex,
      label: '#$slotId Zone B · Fokus',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CameraBrushTarget &&
            other.role == role &&
            other.slotId == slotId &&
            other.encounterOnly == encounterOnly;
  }

  @override
  int get hashCode => Object.hash(role, slotId, encounterOnly);
}

/// Convenience queries for paired multi-instance Zone A/B scan rectangles.
extension MobileMultiInstanceHelper on List<NormalizedScanRect> {
  /// Sorted unique multi-instance slot IDs (>= 2) present in this list.
  List<int> get multiSlotIds {
    final ids = where(
      (r) => r.role == CameraZoneRole.multiInstance && r.slotId != null,
    ).map((r) => r.slotId!).toSet().toList();
    ids.sort();
    return ids;
  }

  /// Returns Zone A (Scan, `encounterOnly == false`) for multi-instance [slotId].
  NormalizedScanRect? scanRectForSlot(int slotId) {
    for (final r in this) {
      if (r.role == CameraZoneRole.multiInstance &&
          r.slotId == slotId &&
          !r.encounterOnly) {
        return r;
      }
    }
    return null;
  }

  /// Returns Zone B (Focus, `encounterOnly == true`) for multi-instance [slotId].
  NormalizedScanRect? focusRectForSlot(int slotId) {
    for (final r in this) {
      if (r.role == CameraZoneRole.multiInstance &&
          r.slotId == slotId &&
          r.encounterOnly) {
        return r;
      }
    }
    return null;
  }

  /// Computes the next unused multi-instance slot ID starting at 2.
  int nextMultiSlotId([Iterable<int> existingSlots = const []]) {
    final used = <int>{...multiSlotIds, ...existingSlots};
    int next = 2;
    while (used.contains(next)) {
      next++;
    }
    return next;
  }
}
