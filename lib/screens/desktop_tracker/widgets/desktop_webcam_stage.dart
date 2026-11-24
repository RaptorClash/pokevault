import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';
import '../../../services/camera_ocr/web_ocr_status.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';
import '../../mobile_scanner/widgets/camera_region_overlay.dart';

/// Widescreen Live Webcam preview card integrated into the right column of
/// [DesktopTrackerScreen] above the `Live-Ereignisse` event feed when a webcam
/// or fallback photo source is selected in `Scan-Quelle / Zielfenster`.
class DesktopWebcamStage extends StatelessWidget {
  final String cameraTitle;
  final CameraController? cameraController;
  final bool isInitializing;
  final String? errorText;
  final bool isPermissionDenied;
  final bool isTrackingActive;
  final bool hasMultipleCameras;
  final bool isEditingRegions;
  final MobileCameraScanMode scanMode;
  final ScanRegionPreset autoPreset;
  final List<NormalizedScanRect> regions;
  final CameraZoneRole activeBrushRole;
  final CameraBrushTarget? activeBrush;
  final ValueListenable<WebOcrEngineStatus>? webOcrStatusListenable;
  final ValueChanged<List<NormalizedScanRect>> onRegionsChanged;
  final VoidCallback onToggleEditRegions;
  final VoidCallback onImportPhoto;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onRetryCamera;

  const DesktopWebcamStage({
    super.key,
    required this.cameraTitle,
    required this.cameraController,
    required this.isInitializing,
    required this.errorText,
    required this.isPermissionDenied,
    required this.isTrackingActive,
    required this.hasMultipleCameras,
    required this.isEditingRegions,
    required this.scanMode,
    required this.autoPreset,
    required this.regions,
    required this.activeBrushRole,
    this.activeBrush,
    required this.onRegionsChanged,
    required this.onToggleEditRegions,
    required this.onImportPhoto,
    this.webOcrStatusListenable,
    this.onSwitchCamera,
    this.onRetryCamera,
  });

  double _resolveAspectRatio(CameraController? ctrl) {
    if (ctrl != null && ctrl.value.isInitialized) {
      final raw = ctrl.value.aspectRatio;
      if (raw.isFinite && raw > 0.2 && raw < 5.0) {
        return raw;
      }
    }
    return 16 / 9;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF151624) : colors.surfaceContainerLow;
    final borderCol = colors.outlineVariant.withValues(alpha: 0.45);
    final isLiveReady = cameraController != null &&
        cameraController!.value.isInitialized &&
        errorText == null;

    return Card(
      key: const Key('desktop_webcam_stage'),
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderCol),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderBar(context, isLiveReady),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340, minHeight: 190),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0B14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isTrackingActive ? const Color(0xFF10B981) : borderCol)
                        .withValues(alpha: 0.6),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: math.max(1.2, _resolveAspectRatio(cameraController)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPreviewSurface(context, isLiveReady),
                        Positioned.fill(
                          child: CameraRegionOverlay(
                            scanMode: scanMode,
                            autoPreset: autoPreset,
                            regions: regions,
                            activeBrushRole: activeBrushRole,
                            activeBrush: activeBrush,
                            isEditing: isEditingRegions,
                            onRegionsChanged: onRegionsChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, bool isLiveReady) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_rounded,
              size: 18,
              color: isLiveReady ? const Color(0xFF10B981) : colors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                cameraTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (webOcrStatusListenable != null) ...[
              const SizedBox(width: 8),
              ValueListenableBuilder<WebOcrEngineStatus>(
                valueListenable: webOcrStatusListenable!,
                builder: (context, status, _) {
                  final hasError =
                      status.cacheSource == WebOcrCacheSource.error ||
                          (status.errorMessage?.isNotEmpty ?? false);
                  return Container(
                    key: const Key('web_ocr_status_pill'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasError
                          ? colors.errorContainer
                          : colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.displayLabelDe,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasError
                            ? colors.onErrorContainer
                            : colors.onSecondaryContainer,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (hasMultipleCameras && onSwitchCamera != null)
              OutlinedButton.icon(
                onPressed: onSwitchCamera,
                icon: const Icon(Icons.cameraswitch_outlined, size: 15),
                label: const Text('Wechseln', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            OutlinedButton.icon(
              onPressed: onToggleEditRegions,
              icon: Icon(
                isEditingRegions ? Icons.check_circle_outline : Icons.crop_free,
                size: 15,
              ),
              label: Text(
                isEditingRegions ? 'Fertig' : 'Zonen zeichnen',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isEditingRegions ? colors.primary : null,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            FilledButton.tonalIcon(
              key: const Key('btn_desktop_webcam_import_photo'),
              onPressed: onImportPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 15),
              label: const Text('Foto scannen', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCenteredScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  Widget _buildPreviewSurface(BuildContext context, bool isLiveReady) {
    final colors = Theme.of(context).colorScheme;
    if (isLiveReady && cameraController != null) {
      return CameraPreview(cameraController!);
    }
    if (isInitializing) {
      return _buildCenteredScrollable(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(height: 10),
              Text(
                'Webcam wird initialisiert...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return _buildCenteredScrollable(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionDenied
                  ? Icons.no_photography_outlined
                  : Icons.videocam_off_outlined,
              size: 32,
              color: isPermissionDenied ? colors.error : Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              errorText ??
                  'Keine aktive Webcam ausgewählt — nutze „Foto scannen“ oder schließe eine USB-Kamera an.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (onRetryCamera != null && errorText != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onRetryCamera,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Kamera neu verbinden', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
