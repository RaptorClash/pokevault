import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/scanner_core/models/scanner_settings.dart'
    show ScanRegionPreset;
import 'camera_region_overlay.dart';

/// Camera live preview surface with scan-region overlay, permission-denied recovery banner,
/// and quick floating side controls (pause, torch, switch camera, manual scan).
class MobileCameraViewport extends StatelessWidget {
  final GlobalKey tutorialKey;
  final CameraController? cameraController;
  final bool permissionDenied;
  final bool isInitializingCamera;
  final String? cameraErrorText;
  final double? livePreviewAspectRatio;
  final MobileCameraScanMode scanMode;
  final ScanRegionPreset autoPreset;
  final List<NormalizedScanRect> regions;
  final CameraBrushTarget activeBrushTarget;
  final bool isEditingRegions;
  final bool isScanningActive;
  final bool supportsTorchControl;
  final bool torchEnabled;
  final int cameraCount;
  final ValueChanged<List<NormalizedScanRect>> onRegionsChanged;
  final ValueChanged<Offset> onTapCameraFocus;
  final VoidCallback onRetryCamera;
  final VoidCallback onImportPhoto;
  final VoidCallback onToggleScanning;
  final VoidCallback onToggleTorch;
  final VoidCallback onSwitchCamera;
  final VoidCallback onTriggerManualScan;

  const MobileCameraViewport({
    super.key,
    required this.tutorialKey,
    required this.cameraController,
    required this.permissionDenied,
    required this.isInitializingCamera,
    required this.cameraErrorText,
    required this.livePreviewAspectRatio,
    required this.scanMode,
    required this.autoPreset,
    required this.regions,
    required this.activeBrushTarget,
    required this.isEditingRegions,
    required this.isScanningActive,
    required this.supportsTorchControl,
    required this.torchEnabled,
    required this.cameraCount,
    required this.onRegionsChanged,
    required this.onTapCameraFocus,
    required this.onRetryCamera,
    required this.onImportPhoto,
    required this.onToggleScanning,
    required this.onToggleTorch,
    required this.onSwitchCamera,
    required this.onTriggerManualScan,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: tutorialKey,
      child: Container(
        key: const Key('mobile_camera_preview_surface'),
        color: const Color(0xFF0A0C12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (permissionDenied)
              _buildPermissionDeniedBanner()
            else ...[
              _buildFeedWithOverlay(context),
              Positioned(
                right: 8,
                top: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cameraSideButton(
                      icon: isScanningActive ? Icons.pause : Icons.play_arrow,
                      tooltip: isScanningActive ? 'Pause' : 'Fortsetzen',
                      onTap: onToggleScanning,
                      active: isScanningActive,
                    ),
                    if (supportsTorchControl) ...[
                      const SizedBox(height: 6),
                      _cameraSideButton(
                        icon: torchEnabled ? Icons.flash_on : Icons.flash_off,
                        tooltip: 'Taschenlampe',
                        onTap: onToggleTorch,
                        active: torchEnabled,
                      ),
                    ],
                    if (cameraCount > 1) ...[
                      const SizedBox(height: 6),
                      _cameraSideButton(
                        icon: Icons.cameraswitch_outlined,
                        tooltip: 'Kamera wechseln',
                        onTap: onSwitchCamera,
                      ),
                    ],
                    const SizedBox(height: 6),
                    _cameraSideButton(
                      icon: Icons.touch_app,
                      tooltip: 'Jetzt scannen',
                      onTap: onTriggerManualScan,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedBanner() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Container(
          key: const Key('camera_permission_denied_banner'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.redAccent,
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamerazugriff verweigert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bitte erlaube den Kamerazugriff in den Systemeinstellungen oder importiere stattdessen ein Foto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRetryCamera,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Erneut versuchen'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onImportPhoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Foto scannen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedWithOverlay(BuildContext context) {
    final ctrl = cameraController;
    final hasLiveCtrl = ctrl != null && ctrl.value.isInitialized;
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final isMobilePortraitPlugin =
        !kIsWeb &&
        isPortrait &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final controllerAspect = hasLiveCtrl
        ? (isMobilePortraitPlugin
            ? (1 / ctrl.value.aspectRatio)
            : ctrl.value.aspectRatio)
        : null;
    final aspect = livePreviewAspectRatio ?? controllerAspect;

    final overlay = CameraRegionOverlay(
      scanMode: scanMode,
      autoPreset: autoPreset,
      regions: regions,
      activeBrushRole: activeBrushTarget.role,
      activeBrush: activeBrushTarget,
      isEditing: isEditingRegions,
      onRegionsChanged: onRegionsChanged,
      onTapCameraFocus: onTapCameraFocus,
    );

    if (hasLiveCtrl) {
      return Center(
        child: AspectRatio(
          aspectRatio: aspect ?? 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(ctrl),
              overlay,
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: isInitializingCamera
              ? const CircularProgressIndicator(color: Colors.cyanAccent)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_outlined,
                      color: Colors.white24,
                      size: 40,
                    ),
                    if (cameraErrorText != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          cameraErrorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        overlay,
      ],
    );
  }

  Widget _cameraSideButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: active
          ? Colors.cyanAccent.withValues(alpha: 0.28)
          : Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.cyanAccent : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
