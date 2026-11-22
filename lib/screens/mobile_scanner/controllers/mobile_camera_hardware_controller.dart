import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../../services/mobile_scanner/camera_frame_pump.dart';
import '../../../services/mobile_scanner/camera_image_converter.dart';
import '../../../services/mobile_scanner/mobile_camera_source.dart';
import '../../../services/mobile_scanner/mobile_camera_tracker_service.dart';
import '../../../services/scanner_core/media/image_frame_decoder.dart';

/// Manages the hardware camera lifecycle, stream frame pumping, zoom, torch,
/// tap-to-focus, and session reattachment across PiP transitions.
class MobileCameraHardwareController extends ChangeNotifier {
  final MobileCameraTrackerService trackerService;
  final MobileCameraSource cameraSource;
  final int Function() getScanIntervalMs;
  final bool Function() isScanningActive;
  final bool disableHardwareCamera;
  final bool simulatePermissionDenied;
  final List<CameraDescription>? availableCamerasOverride;

  CameraController? controller;
  CameraFramePump? framePump;
  List<CameraDescription> cameras = const [];
  int selectedCameraIndex = 0;
  bool isInitializing = false;
  bool permissionDenied = false;
  String? cameraErrorText;
  bool _convertingFrame = false;
  double minZoom = 1.0;
  double maxZoom = 1.0;
  double zoomLevel = 1.0;
  bool torchEnabled = false;
  double? livePreviewAspectRatio;
  bool _disposed = false;

  MobileCameraHardwareController({
    required this.trackerService,
    required this.cameraSource,
    required this.getScanIntervalMs,
    required this.isScanningActive,
    this.disableHardwareCamera = false,
    this.simulatePermissionDenied = false,
    this.availableCamerasOverride,
  }) : permissionDenied = simulatePermissionDenied {
    if (availableCamerasOverride != null) {
      cameras = availableCamerasOverride!;
      final backIdx = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      selectedCameraIndex = backIdx >= 0 ? backIdx : 0;
    }
  }

  bool get supportsTorchControl =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Reattaches an existing initialized [CameraController] when returning from PiP.
  void tryReattachExisting() {
    final existingController = trackerService.activeCameraController;
    if (existingController is CameraController &&
        existingController.value.isInitialized) {
      controller = existingController;
      framePump = trackerService.activeFramePump;
      cameras = trackerService.cachedCameras;
      selectedCameraIndex = trackerService.selectedCameraIndex;
      minZoom = trackerService.minZoom;
      maxZoom = trackerService.maxZoom;
      livePreviewAspectRatio = trackerService.previewAspectRatioNotifier.value;
      torchEnabled = trackerService.torchEnabledNotifier.value;
      zoomLevel = trackerService.zoomLevelNotifier.value;
    }
  }

  Future<void> initHardwareCamera() async {
    if (isInitializing || disableHardwareCamera || simulatePermissionDenied) {
      return;
    }
    isInitializing = true;
    cameraErrorText = null;
    permissionDenied = false;
    _safeNotify();

    try {
      cameras = availableCamerasOverride ?? await availableCameras();
      if (cameras.isEmpty) {
        isInitializing = false;
        cameraErrorText = 'Keine Kamera auf diesem Gerät gefunden.';
        _safeNotify();
        return;
      }

      final backIdx = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      selectedCameraIndex = backIdx >= 0 ? backIdx : 0;
      await startCameraController(cameras[selectedCameraIndex]);
    } on CameraException catch (e) {
      final formatted = CameraImageConverter.formatCameraError(e);
      isInitializing = false;
      permissionDenied = formatted.isPermissionDenied;
      cameraErrorText = formatted.message;
      _safeNotify();
    } catch (e) {
      isInitializing = false;
      cameraErrorText = e.toString();
      _safeNotify();
    }
  }

  Future<void> startCameraController(CameraDescription desc) async {
    await framePump?.dispose();
    framePump = null;

    final prev = controller;
    controller = null;
    if (prev != null) {
      try {
        if (prev.value.isStreamingImages) {
          await prev.stopImageStream();
        }
        await prev.dispose();
      } catch (_) {}
    }

    final nextCtrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: CameraImageConverter.preferredImageFormatGroup(),
    );

    await nextCtrl.initialize();

    double nextMinZoom = 1.0;
    double nextMaxZoom = 1.0;
    try {
      nextMinZoom = await nextCtrl.getMinZoomLevel();
      nextMaxZoom = await nextCtrl.getMaxZoomLevel();
    } catch (_) {
      nextMinZoom = 1.0;
      nextMaxZoom = 1.0;
    }

    final pump = CameraFramePump(
      startImageStream: () => nextCtrl.startImageStream((image) {
        unawaited(_handleCameraImage(image, desc));
      }),
      stopImageStream: () async {
        if (nextCtrl.value.isStreamingImages) {
          await nextCtrl.stopImageStream();
        }
      },
      captureStillBytes: () async {
        if (!nextCtrl.value.isInitialized) return null;
        final xfile = await nextCtrl.takePicture();
        return await xfile.readAsBytes();
      },
      decodeStillFrame: (bytes) => ImageFrameDecoder.decodeBytesToBgraFrame(
        bytes,
        captureMethod: kIsWeb ? 'web_webcam_poll' : 'camera_still_poll',
      ),
      onDecodedFrame: (frame) async {
        final nextAspect = frame.width / math.max(1, frame.height);
        trackerService.previewAspectRatioNotifier.value = nextAspect;
        if (!_disposed &&
            (livePreviewAspectRatio == null ||
                (livePreviewAspectRatio! - nextAspect).abs() > 0.05)) {
          livePreviewAspectRatio = nextAspect;
          _safeNotify();
        }
        await cameraSource.submitCameraFrame(frame);
      },
      pollInterval: Duration(milliseconds: getScanIntervalMs()),
      forcePollingFallback: kIsWeb,
    );
    await pump.start();

    if (_disposed) {
      await pump.dispose();
      try {
        await nextCtrl.dispose();
      } catch (_) {}
      return;
    }

    framePump = pump;
    controller = nextCtrl;
    trackerService.activeCameraController = nextCtrl;
    trackerService.activeFramePump = pump;
    trackerService.cachedCameras = cameras;
    trackerService.selectedCameraIndex = selectedCameraIndex;
    trackerService.minZoom = nextMinZoom;
    trackerService.maxZoom = math.max(nextMinZoom, nextMaxZoom);

    isInitializing = false;
    permissionDenied = false;
    minZoom = nextMinZoom;
    maxZoom = math.max(nextMinZoom, nextMaxZoom);
    zoomLevel = nextMinZoom;
    torchEnabled = false;
    _safeNotify();
  }

  Future<void> _handleCameraImage(
    CameraImage image,
    CameraDescription desc,
  ) async {
    if (_convertingFrame ||
        !isScanningActive() ||
        !cameraSource.shouldProcessFrameNow()) {
      return;
    }

    _convertingFrame = true;
    try {
      final upright = await CameraImageConverter.convertCameraImageInIsolate(
        image,
        desc.sensorOrientation,
        deviceOrientation: controller?.value.deviceOrientation,
        isFrontCamera: desc.lensDirection == CameraLensDirection.front,
      );
      if (upright != null) {
        final nextAspect = upright.width / math.max(1, upright.height);
        trackerService.previewAspectRatioNotifier.value = nextAspect;
        if (!_disposed &&
            (livePreviewAspectRatio == null ||
                (livePreviewAspectRatio! - nextAspect).abs() > 0.05)) {
          livePreviewAspectRatio = nextAspect;
          _safeNotify();
        }
        await cameraSource.submitCameraFrame(upright);
      }
    } finally {
      _convertingFrame = false;
    }
  }

  Future<void> disposeHardwareCamera() async {
    await framePump?.dispose();
    framePump = null;
    trackerService.activeFramePump = null;

    final ctrl = controller ??
        (trackerService.activeCameraController is CameraController
            ? trackerService.activeCameraController as CameraController
            : null);
    controller = null;
    trackerService.activeCameraController = null;
    if (ctrl != null) {
      try {
        if (ctrl.value.isStreamingImages) {
          await ctrl.stopImageStream();
        }
      } catch (_) {}
      try {
        await ctrl.dispose();
      } catch (_) {}
    }
  }

  Future<void> toggleTorch() async {
    final next = !torchEnabled;
    final ctrl = controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      try {
        await ctrl.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      } catch (_) {}
    }
    torchEnabled = next;
    trackerService.torchEnabledNotifier.value = next;
    _safeNotify();
  }

  Future<void> setZoom(double zoom) async {
    final clamped = zoom.clamp(minZoom, maxZoom);
    final ctrl = controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      try {
        await ctrl.setZoomLevel(clamped);
      } catch (_) {}
    }
    zoomLevel = clamped;
    trackerService.zoomLevelNotifier.value = clamped;
    _safeNotify();
  }

  Future<void> selectCameraByIndex(int index) async {
    if (index < 0 || index >= cameras.length) return;
    selectedCameraIndex = index;
    _safeNotify();
    if (!disableHardwareCamera) {
      await startCameraController(cameras[index]);
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;
    await selectCameraByIndex((selectedCameraIndex + 1) % cameras.length);
  }

  Future<void> handleTapCameraFocus(Offset normalizedPoint) async {
    final ctrl = controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    try {
      await ctrl.setFocusPoint(normalizedPoint);
      await ctrl.setExposurePoint(normalizedPoint);
    } catch (_) {}
  }

  void handleAppLifecycleChange(AppLifecycleState state) {
    if (disableHardwareCamera || simulatePermissionDenied) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(disposeHardwareCamera());
    } else if (state == AppLifecycleState.resumed) {
      if (controller == null && !isInitializing) {
        unawaited(initHardwareCamera());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
