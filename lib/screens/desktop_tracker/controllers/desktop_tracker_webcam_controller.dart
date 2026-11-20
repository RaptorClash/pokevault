import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../services/camera_ocr/platform_camera_ocr_driver.dart';
import '../../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../../services/desktop_tracker/desktop_ocr_driver.dart';
import '../../../services/desktop_tracker/window_detector.dart';
import '../../../services/desktop_tracker/windows_desktop_bridge.dart';
import '../../../services/mobile_scanner/camera_frame_pump.dart';
import '../../../services/mobile_scanner/camera_image_converter.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/mobile_scanner/mobile_camera_source.dart';
import '../../../services/scanner_core/media/image_frame_decoder.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';

/// Manages hardware webcam discovery, camera stream / polling frame pump,
/// photo import, and platform camera OCR driver lifecycle for
/// [DesktopTrackerScreen].
class DesktopTrackerWebcamController extends ChangeNotifier {
  final DesktopPlatformBridge? Function() _bridgeResolver;
  final DesktopOcrDriver? cameraOcrDriverOverride;
  final bool disableHardwareCamera;
  final Future<CapturedFrame?> Function()? sandboxImagePicker;

  List<CameraDescription> cameras = const [];
  DesktopOcrDriver? cameraOcrDriver;
  MobileCameraSource? cameraSource;
  CameraController? cameraController;
  CameraFramePump? cameraFramePump;

  bool isInitializingCamera = false;
  bool isCameraPermissionDenied = false;
  String? cameraErrorText;
  bool _convertingCameraFrame = false;

  MobileCameraScanMode cameraScanMode = MobileCameraScanMode.autoFull;
  List<NormalizedScanRect> cameraRegions = const [];

  DesktopTrackerWebcamController({
    required DesktopPlatformBridge? Function() bridgeResolver,
    this.cameraOcrDriverOverride,
    this.disableHardwareCamera = false,
    this.sandboxImagePicker,
    List<CameraDescription>? initialCameras,
  })  : _bridgeResolver = bridgeResolver,
        cameras = initialCameras ?? const [];

  ValueListenable<WebOcrEngineStatus>? get webOcrStatusListenable {
    if (!kIsWeb) return null;
    final driver = cameraOcrDriver;
    if (driver is WebOcrStatusReportingDriver) {
      return (driver as WebOcrStatusReportingDriver).statusListenable;
    }
    return null;
  }

  DesktopOcrDriver ensureCameraOcrDriver({required String ocrLanguageTag}) {
    return cameraOcrDriver ??= cameraOcrDriverOverride ??
        createPlatformCameraOcrDriver(
          windowsBridge: _bridgeResolver(),
          initialLanguageTag: ocrLanguageTag,
        );
  }

  MobileCameraSource ensureCameraSource({
    required String ocrLanguageTag,
    required ScanRegionPreset scanRegion,
  }) {
    final existing = cameraSource;
    if (existing != null) return existing;
    final source = MobileCameraSource(
      ocrDriver: ensureCameraOcrDriver(ocrLanguageTag: ocrLanguageTag),
    );
    source.setOcrLanguageTag(ocrLanguageTag);
    source.setPreprocessProfile(OcrPreprocessProfile.cameraDisplay);
    source.setAutoPreset(scanRegion);
    source.setScanMode(cameraScanMode);
    if (cameraRegions.isNotEmpty) {
      source.setRegions(cameraRegions);
    }
    cameraSource = source;
    return source;
  }

  void setOcrLanguageTag(String tag) {
    cameraSource?.setOcrLanguageTag(tag);
  }

  void setAutoPreset(ScanRegionPreset preset) {
    cameraSource?.setAutoPreset(preset);
  }

  void updateScanMode(MobileCameraScanMode mode) {
    cameraScanMode = mode;
    cameraSource?.setScanMode(mode);
    notifyListeners();
  }

  void updateRegions(List<NormalizedScanRect> regions) {
    cameraRegions = List.unmodifiable(regions);
    cameraSource?.setRegions(cameraRegions);
    notifyListeners();
  }

  Future<void> syncHardwareForSelection({
    required DesktopWindowInfo? window,
    required String ocrLanguageTag,
    required ScanRegionPreset scanRegion,
    required bool Function() isMounted,
    required bool Function() isScanningActive,
    required DesktopWindowInfo? Function() currentWindow,
  }) async {
    if (window == null || !window.isCameraSource) {
      await stopHardwareCamera();
      return;
    }
    if (window.cameraIndex < 0 || window.cameraIndex >= cameras.length) {
      await stopHardwareCamera();
      if (isMounted()) {
        isInitializingCamera = false;
        isCameraPermissionDenied = false;
        cameraErrorText = null;
        notifyListeners();
      }
      return;
    }
    if (disableHardwareCamera) {
      if (isMounted()) {
        isInitializingCamera = false;
        isCameraPermissionDenied = false;
        cameraErrorText = null;
        notifyListeners();
      }
      return;
    }
    await startHardwareCameraController(
      desc: cameras[window.cameraIndex],
      ocrLanguageTag: ocrLanguageTag,
      scanRegion: scanRegion,
      isMounted: isMounted,
      isScanningActive: isScanningActive,
      currentWindow: currentWindow,
    );
  }

  Future<void> stopHardwareCamera() async {
    await cameraFramePump?.dispose();
    cameraFramePump = null;
    final prev = cameraController;
    cameraController = null;
    if (prev != null) {
      try {
        if (prev.value.isStreamingImages) {
          await prev.stopImageStream();
        }
      } catch (_) {}
      try {
        await prev.dispose();
      } catch (_) {}
    }
  }

  Future<void> startHardwareCameraController({
    required CameraDescription desc,
    required String ocrLanguageTag,
    required ScanRegionPreset scanRegion,
    required bool Function() isMounted,
    required bool Function() isScanningActive,
    required DesktopWindowInfo? Function() currentWindow,
  }) async {
    if (!isMounted()) return;
    isInitializingCamera = true;
    cameraErrorText = null;
    isCameraPermissionDenied = false;
    notifyListeners();
    await stopHardwareCamera();

    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: CameraImageConverter.preferredImageFormatGroup(),
    );

    try {
      await controller.initialize();
      final selected = currentWindow();
      if (!isMounted() ||
          selected == null ||
          !selected.isCameraSource ||
          selected.cameraIndex != cameras.indexOf(desc)) {
        await controller.dispose();
        return;
      }
      cameraController = controller;
      final pump = CameraFramePump(
        forcePollingFallback: kIsWeb,
        startImageStream: () => controller.startImageStream(
          (img) => unawaited(
            _handleCameraStreamImage(
              img,
              desc.sensorOrientation,
              ocrLanguageTag: ocrLanguageTag,
              scanRegion: scanRegion,
              isScanningActive: isScanningActive,
            ),
          ),
        ),
        stopImageStream: () => controller.stopImageStream(),
        captureStillBytes: () async {
          if (!controller.value.isInitialized) return null;
          final xfile = await controller.takePicture();
          return xfile.readAsBytes();
        },
        decodeStillFrame: (bytes) =>
            ImageFrameDecoder.decodeBytesToBgraFrame(bytes),
        onDecodedFrame: (frame) => ensureCameraSource(
          ocrLanguageTag: ocrLanguageTag,
          scanRegion: scanRegion,
        ).submitCameraFrame(frame),
      );
      cameraFramePump = pump;
      if (isScanningActive()) {
        await pump.start();
      }
      if (!isMounted()) return;
      isInitializingCamera = false;
      notifyListeners();
    } on CameraException catch (e) {
      try {
        await controller.dispose();
      } catch (_) {}
      if (!isMounted()) return;
      final formatted = CameraImageConverter.formatCameraError(e);
      isInitializingCamera = false;
      isCameraPermissionDenied = formatted.isPermissionDenied;
      cameraErrorText = formatted.message;
      notifyListeners();
    } catch (e) {
      try {
        await controller.dispose();
      } catch (_) {}
      if (!isMounted()) return;
      isInitializingCamera = false;
      cameraErrorText = e.toString();
      notifyListeners();
    }
  }

  Future<void> _handleCameraStreamImage(
    CameraImage image,
    int sensorOrientation, {
    required String ocrLanguageTag,
    required ScanRegionPreset scanRegion,
    required bool Function() isScanningActive,
  }) async {
    if (_convertingCameraFrame || !isScanningActive()) return;
    _convertingCameraFrame = true;
    try {
      final upright = CameraImageConverter.convertToUprightBgra(
        image,
        sensorOrientation,
      );
      if (upright != null) {
        await ensureCameraSource(
          ocrLanguageTag: ocrLanguageTag,
          scanRegion: scanRegion,
        ).submitCameraFrame(upright);
      }
    } finally {
      _convertingCameraFrame = false;
    }
  }

  Future<bool> importPhotoForWebcam({
    required String ocrLanguageTag,
    required ScanRegionPreset scanRegion,
    required bool Function() isMounted,
    required void Function(MobileCameraSource source) beforeProcess,
  }) async {
    final frame = await CameraImageConverter.pickAndDecodePhotoFrame(
      overridePicker: sandboxImagePicker,
    );
    if (frame == null || !isMounted()) return false;
    final src = ensureCameraSource(
      ocrLanguageTag: ocrLanguageTag,
      scanRegion: scanRegion,
    );
    beforeProcess(src);
    await src.processPhotoFrame(frame);
    return true;
  }

  Future<void> stopAndDisposeSource() async {
    await stopHardwareCamera();
    await cameraSource?.dispose();
    cameraSource = null;
  }
}
