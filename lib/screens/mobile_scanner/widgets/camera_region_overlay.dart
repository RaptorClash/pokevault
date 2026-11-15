import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';

/// Interactive touch overlay over the mobile camera preview allowing users to
/// switch between Auto full-frame scanning and freely drawn/resizable/movable
/// scan rectangles (Zone A, Zone B, Multi-Instance #1..N).
class CameraRegionOverlay extends StatefulWidget {
  final MobileCameraScanMode scanMode;
  final ScanRegionPreset autoPreset;
  final List<NormalizedScanRect> regions;
  final CameraZoneRole activeBrushRole;
  final CameraBrushTarget? activeBrush;
  final bool isEditing;
  final bool showBorderOutlines;
  final ValueChanged<List<NormalizedScanRect>> onRegionsChanged;
  final ValueChanged<Offset>? onTapCameraFocus;

  const CameraRegionOverlay({
    super.key,
    required this.scanMode,
    this.autoPreset = ScanRegionPreset.fullWindow,
    required this.regions,
    required this.activeBrushRole,
    this.activeBrush,
    required this.isEditing,
    this.showBorderOutlines = true,
    required this.onRegionsChanged,
    this.onTapCameraFocus,
  });

  @override
  State<CameraRegionOverlay> createState() => _CameraRegionOverlayState();
}

class _CameraRegionOverlayState extends State<CameraRegionOverlay> {
  Offset? _drawStart;
  Offset? _drawCurrent;
  String? _selectedRegionId;

  @override
  Widget build(BuildContext context) {
    if (widget.scanMode == MobileCameraScanMode.autoFull) {
      return _buildAutoModeOverlay();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = math.max(1.0, constraints.maxWidth);
        final h = math.max(1.0, constraints.maxHeight);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Empty canvas gesture detector for drawing new rectangles
            Positioned.fill(
              child: GestureDetector(
                key: const Key('camera_region_canvas'),
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  if (_selectedRegionId != null) {
                    setState(() => _selectedRegionId = null);
                    return;
                  }
                  if (!widget.isEditing && widget.onTapCameraFocus != null) {
                    widget.onTapCameraFocus!(
                      Offset(
                        (details.localPosition.dx / w).clamp(0.0, 1.0),
                        (details.localPosition.dy / h).clamp(0.0, 1.0),
                      ),
                    );
                  }
                },
                onPanStart: widget.isEditing
                    ? (details) {
                        setState(() {
                          _selectedRegionId = null;
                          _drawStart = details.localPosition;
                          _drawCurrent = details.localPosition;
                        });
                      }
                    : null,
                onPanUpdate: widget.isEditing
                    ? (details) {
                        setState(() {
                          _drawCurrent = Offset(
                            details.localPosition.dx.clamp(0.0, w),
                            details.localPosition.dy.clamp(0.0, h),
                          );
                        });
                      }
                    : null,
                onPanEnd: widget.isEditing ? (_) => _commitDrawnRect(w, h) : null,
                onPanCancel: widget.isEditing
                    ? () => setState(() {
                          _drawStart = null;
                          _drawCurrent = null;
                        })
                    : null,
                child: const SizedBox.expand(),
              ),
            ),

            // Live drawing preview rectangle
            if (_drawStart != null && _drawCurrent != null)
              _buildDraftRectOverlay(),

            // Existing drawn rectangles
            if (widget.showBorderOutlines)
              for (final region in widget.regions)
                _buildRegionWidget(region, w, h),
          ],
        );
      },
    );
  }

  Widget _buildAutoModeOverlay() {
    if (!widget.showBorderOutlines) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.65),
            width: 1.5,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            key: const Key('auto_full_scan_badge'),
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              'AUTO-MODUS · ${widget.autoPreset.labelDe}',
              style: const TextStyle(
                color: Color(0xFF6EE7B7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftRectOverlay() {
    final left = math.min(_drawStart!.dx, _drawCurrent!.dx);
    final top = math.min(_drawStart!.dy, _drawCurrent!.dy);
    final width = (_drawStart!.dx - _drawCurrent!.dx).abs();
    final height = (_drawStart!.dy - _drawCurrent!.dy).abs();
    final color = widget.activeBrush != null
        ? Color(widget.activeBrush!.colorHex)
        : _colorForRole(widget.activeBrushRole);

    return Positioned(
      left: left,
      top: top,
      width: math.max(2, width),
      height: math.max(2, height),
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionWidget(
    NormalizedScanRect region,
    double canvasW,
    double canvasH,
  ) {
    final px = region.toPixelRect(canvasW, canvasH);
    final color = Color(region.colorHex);
    final isSelected = _selectedRegionId == region.id;

    return Positioned(
      left: px.left,
      top: px.top,
      width: px.width,
      height: px.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: Key('region_box_${region.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_selectedRegionId != region.id) {
                  setState(() {
                    _selectedRegionId = region.id;
                  });
                }
              },
              onPanUpdate: widget.isEditing
                  ? (details) => _moveRegion(region, details.delta, canvasW, canvasH)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.22 : 0.12),
                  border: Border.all(
                    color: isSelected ? Colors.white : color,
                    width: isSelected ? 2.5 : 2.0,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Label badge
          Positioned(
            top: -18,
            left: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
                child: Text(
                  region.label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          // Selected quick actions (Role toggle + Delete) inside box bounds for reliable hit-testing
          if (isSelected && widget.isEditing)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (region.role == CameraZoneRole.multiInstance)
                      InkWell(
                        onTap: () => _toggleEncounterOnly(region),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Text(
                            region.encounterOnly ? 'Fokus' : 'Scan',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    InkWell(
                      key: Key('btn_delete_region_${region.id}'),
                      onTap: () => _deleteRegion(region.id),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bottom-right resize handle
          if (widget.isEditing)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                key: Key('resize_handle_${region.id}'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) =>
                    _resizeRegion(region, details.delta, canvasW, canvasH),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _commitDrawnRect(double canvasW, double canvasH) {
    final start = _drawStart;
    final current = _drawCurrent;
    setState(() {
      _drawStart = null;
      _drawCurrent = null;
    });
    if (start == null || current == null) return;

    final leftPx = math.min(start.dx, current.dx);
    final topPx = math.min(start.dy, current.dy);
    final widthPx = (start.dx - current.dx).abs();
    final heightPx = (start.dy - current.dy).abs();

    // Ignore accidental tiny taps
    if (widthPx < 16 || heightPx < 16) return;

    final nextList = List<NormalizedScanRect>.from(widget.regions);
    final targetBrush = widget.activeBrush;
    final role = targetBrush?.role ?? widget.activeBrushRole;

    late final NormalizedScanRect created;
    if (role == CameraZoneRole.scan) {
      nextList.removeWhere((r) => r.id == 'zone_a');
      created = NormalizedScanRect.fromPixelRect(
        id: 'zone_a',
        role: CameraZoneRole.scan,
        pixelRect: Rect.fromLTWH(leftPx, topPx, widthPx, heightPx),
        frameWidth: canvasW,
        frameHeight: canvasH,
        colorHex: 0xFF10B981,
        label: 'Zone A · Scan',
      );
    } else if (role == CameraZoneRole.focus) {
      nextList.removeWhere((r) => r.id == 'zone_b');
      created = NormalizedScanRect.fromPixelRect(
        id: 'zone_b',
        role: CameraZoneRole.focus,
        pixelRect: Rect.fromLTWH(leftPx, topPx, widthPx, heightPx),
        frameWidth: canvasW,
        frameHeight: canvasH,
        colorHex: 0xFF06B6D4,
        label: 'Zone B · Fokus',
        encounterOnly: true,
      );
    } else if (targetBrush != null &&
        targetBrush.role == CameraZoneRole.multiInstance) {
      nextList.removeWhere((r) => r.id == targetBrush.regionId);
      created = NormalizedScanRect.fromPixelRect(
        id: targetBrush.regionId,
        role: CameraZoneRole.multiInstance,
        slotId: targetBrush.slotId,
        pixelRect: Rect.fromLTWH(leftPx, topPx, widthPx, heightPx),
        frameWidth: canvasW,
        frameHeight: canvasH,
        colorHex: targetBrush.colorHex,
        label: targetBrush.label,
        encounterOnly: targetBrush.encounterOnly,
      );
    } else {
      final nextSlot = nextList.nextMultiSlotId();
      final fallbackBrush = CameraBrushTarget.multiScan(nextSlot);
      nextList.removeWhere((r) => r.id == fallbackBrush.regionId);
      created = NormalizedScanRect.fromPixelRect(
        id: fallbackBrush.regionId,
        role: CameraZoneRole.multiInstance,
        slotId: nextSlot,
        pixelRect: Rect.fromLTWH(leftPx, topPx, widthPx, heightPx),
        frameWidth: canvasW,
        frameHeight: canvasH,
        colorHex: fallbackBrush.colorHex,
        label: fallbackBrush.label,
        encounterOnly: false,
      );
    }

    nextList.add(created);
    setState(() => _selectedRegionId = created.id);
    widget.onRegionsChanged(List.unmodifiable(nextList));
  }

  void _moveRegion(
    NormalizedScanRect region,
    Offset delta,
    double canvasW,
    double canvasH,
  ) {
    final dxNorm = delta.dx / canvasW;
    final dyNorm = delta.dy / canvasH;
    final updated = region.copyWith(
      left: (region.left + dxNorm).clamp(0.0, 1.0 - region.width),
      top: (region.top + dyNorm).clamp(0.0, 1.0 - region.height),
    );
    _replaceRegion(updated);
  }

  void _resizeRegion(
    NormalizedScanRect region,
    Offset delta,
    double canvasW,
    double canvasH,
  ) {
    final dwNorm = delta.dx / canvasW;
    final dhNorm = delta.dy / canvasH;
    final nextW = (region.width + dwNorm)
        .clamp(NormalizedScanRect.minSize, 1.0 - region.left);
    final nextH = (region.height + dhNorm)
        .clamp(NormalizedScanRect.minSize, 1.0 - region.top);
    final updated = region.copyWith(width: nextW, height: nextH);
    _replaceRegion(updated);
  }

  void _toggleEncounterOnly(NormalizedScanRect region) {
    _replaceRegion(region.copyWith(encounterOnly: !region.encounterOnly));
  }

  void _deleteRegion(String id) {
    setState(() {
      if (_selectedRegionId == id) _selectedRegionId = null;
    });
    widget.onRegionsChanged(
      List.unmodifiable(widget.regions.where((r) => r.id != id)),
    );
  }

  void _replaceRegion(NormalizedScanRect updated) {
    final next = widget.regions
        .map((r) => r.id == updated.id ? updated : r)
        .toList(growable: false);
    widget.onRegionsChanged(List.unmodifiable(next));
  }

  Color _colorForRole(CameraZoneRole role) => switch (role) {
        CameraZoneRole.scan => const Color(0xFF10B981),
        CameraZoneRole.focus => const Color(0xFF06B6D4),
        CameraZoneRole.multiInstance => const Color(0xFFA855F7),
      };
}
