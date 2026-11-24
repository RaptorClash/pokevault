import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../desktop_tracker/evolution_chain_helper.dart';
import '../scanner_core/models/scanner_event.dart';
import '../scanner_core/scanner_coordinator.dart';
import '../shiny_auto_counter/shiny_auto_counter_service.dart';
import 'camera_frame_pump.dart';
import 'camera_scan_region.dart';
import 'mobile_camera_source.dart';

/// Singleton service managing the Mobile Camera Tracker session across
/// Fullscreen, Split-Screen, and draggable app-wide Picture-in-Picture (PiP) modes.
class MobileCameraTrackerService {
  static final MobileCameraTrackerService _instance =
      MobileCameraTrackerService._internal();
  factory MobileCameraTrackerService() => _instance;
  static MobileCameraTrackerService get instance => _instance;

  MobileCameraTrackerService._internal();

  ScannerCoordinator? _coordinator;
  MobileCameraSource? _cameraSource;
  String? _activeDexId;
  StreamSubscription<ScannerEvent>? _eventSub;
  StreamSubscription<List<ScannerEvent>>? _focusSub;

  WidgetBuilder? _pipCameraPreviewBuilder;
  VoidCallback? _onExpandFromPip;
  Future<void> Function()? _onToggleTorchCallback;
  Future<void> Function()? _onDisposeCameraCallback;
  Future<void> Function()? _onDisableWakelockCallback;
  Object? activeCameraController;
  CameraFramePump? activeFramePump;
  List<CameraDescription> cachedCameras = const [];
  int selectedCameraIndex = 0;
  double minZoom = 1.0;
  double maxZoom = 1.0;
  bool _ownsCameraSourceOnStop = false;

  final ValueNotifier<double?> previewAspectRatioNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPipVisibleNotifier = ValueNotifier(false);
  final ValueNotifier<Offset> pipPositionNotifier =
      ValueNotifier(const Offset(16, 96));
  final ValueNotifier<MobileScannerViewMode> viewModeNotifier =
      ValueNotifier(MobileScannerViewMode.fullscreen);
  final ValueNotifier<MobileCameraScanMode> scanModeNotifier =
      ValueNotifier(MobileCameraScanMode.autoFull);
  final ValueNotifier<List<NormalizedScanRect>> regionsNotifier =
      ValueNotifier(const []);
  final ValueNotifier<ScannerEvent?> latestEventNotifier = ValueNotifier(null);
  final ValueNotifier<List<ScannerEvent>> activeFocusNotifier =
      ValueNotifier(const []);
  final ValueNotifier<EvolutionCheckStatus?> evolutionStatusNotifier =
      ValueNotifier(null);
  final ValueNotifier<bool> torchEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<double> zoomLevelNotifier = ValueNotifier(1.0);

  ScannerCoordinator? get coordinator => _coordinator;
  MobileCameraSource? get cameraSource => _cameraSource;
  String? get activeDexId => _activeDexId;
  bool get isTrackingActive => isTrackingNotifier.value;
  bool get isPaused => isPausedNotifier.value;
  bool get isPipVisible => isPipVisibleNotifier.value;
  Offset get pipPosition => pipPositionNotifier.value;
  MobileScannerViewMode get viewMode => viewModeNotifier.value;
  MobileCameraScanMode get scanMode => scanModeNotifier.value;
  List<NormalizedScanRect> get regions => regionsNotifier.value;
  ScannerEvent? get latestEvent => latestEventNotifier.value;
  List<ScannerEvent> get activeFocus => activeFocusNotifier.value;
  WidgetBuilder? get pipCameraPreviewBuilder => _pipCameraPreviewBuilder;

  void startSession({
    required ScannerCoordinator coordinator,
    required MobileCameraSource cameraSource,
    String? dexId,
    WidgetBuilder? pipCameraPreviewBuilder,
    VoidCallback? onExpandFromPip,
    Future<void> Function()? onToggleTorch,
    bool ownsCameraSource = false,
  }) {
    _coordinator = coordinator;
    _cameraSource = cameraSource;
    _ownsCameraSourceOnStop = ownsCameraSource;
    _activeDexId = dexId;
    _pipCameraPreviewBuilder = pipCameraPreviewBuilder;
    _onExpandFromPip = onExpandFromPip;
    _onToggleTorchCallback = onToggleTorch;

    scanModeNotifier.value = cameraSource.scanMode;
    regionsNotifier.value = List.unmodifiable(cameraSource.regions);

    _eventSub?.cancel();
    _eventSub = coordinator.events.listen(handleScannerEvent);
    _focusSub?.cancel();
    _focusSub = coordinator.activeFocusStream.listen(updateActiveFocus);

    isTrackingNotifier.value = true;
    isPausedNotifier.value = false;
  }

  void attachPipCallbacks({
    WidgetBuilder? pipCameraPreviewBuilder,
    VoidCallback? onExpandFromPip,
    Future<void> Function()? onToggleTorch,
    Future<void> Function()? onDisposeCamera,
    Future<void> Function()? onDisableWakelock,
  }) {
    if (pipCameraPreviewBuilder != null) {
      _pipCameraPreviewBuilder = pipCameraPreviewBuilder;
    }
    if (onExpandFromPip != null) {
      _onExpandFromPip = onExpandFromPip;
    }
    if (onToggleTorch != null) {
      _onToggleTorchCallback = onToggleTorch;
    }
    if (onDisposeCamera != null) {
      _onDisposeCameraCallback = onDisposeCamera;
    }
    if (onDisableWakelock != null) {
      _onDisableWakelockCallback = onDisableWakelock;
    }
  }

  void setActiveDexId(String? dexId) {
    _activeDexId = dexId;
  }

  void setViewMode(MobileScannerViewMode mode) {
    viewModeNotifier.value = mode;
    isPipVisibleNotifier.value = mode == MobileScannerViewMode.pip;
  }

  void enterPipMode() {
    setViewMode(MobileScannerViewMode.pip);
  }

  void exitPipMode({
    MobileScannerViewMode targetMode = MobileScannerViewMode.fullscreen,
  }) {
    final resolved = targetMode == MobileScannerViewMode.pip
        ? MobileScannerViewMode.fullscreen
        : targetMode;
    setViewMode(resolved);
  }

  void triggerExpandFromPip() {
    exitPipMode(targetMode: MobileScannerViewMode.fullscreen);
    _onExpandFromPip?.call();
  }

  Future<void> toggleTorchFromPip() async {
    if (_onToggleTorchCallback != null) {
      await _onToggleTorchCallback!();
    } else {
      torchEnabledNotifier.value = !torchEnabledNotifier.value;
    }
  }

  /// Clamps PiP drag coordinates inside visible safe screen boundaries.
  void updatePipPosition(
    Offset nextPosition, {
    required Size screenSize,
    EdgeInsets safePadding = EdgeInsets.zero,
    Size pipSize = const Size(168, 144),
  }) {
    const double margin = 8.0;
    final minX = safePadding.left + margin;
    final minY = safePadding.top + margin;
    final maxX =
        (screenSize.width - safePadding.right - pipSize.width - margin)
            .clamp(minX, screenSize.width);
    final maxY =
        (screenSize.height - safePadding.bottom - pipSize.height - margin)
            .clamp(minY, screenSize.height);

    pipPositionNotifier.value = Offset(
      nextPosition.dx.clamp(minX, maxX).toDouble(),
      nextPosition.dy.clamp(minY, maxY).toDouble(),
    );
  }

  void setScanMode(MobileCameraScanMode mode) {
    scanModeNotifier.value = mode;
    _cameraSource?.setScanMode(mode);
  }

  void setRegions(List<NormalizedScanRect> nextRegions) {
    final immutable = List<NormalizedScanRect>.unmodifiable(nextRegions);
    regionsNotifier.value = immutable;
    _cameraSource?.setRegions(immutable);
  }

  void addOrUpdateRegion(NormalizedScanRect region) {
    final list = List<NormalizedScanRect>.from(regionsNotifier.value);
    final idx = list.indexWhere((r) => r.id == region.id);
    if (idx >= 0) {
      list[idx] = region;
    } else {
      list.add(region);
    }
    setRegions(list);
  }

  void removeRegion(String id) {
    final list = regionsNotifier.value.where((r) => r.id != id).toList();
    setRegions(list);
  }

  void handleScannerEvent(ScannerEvent event) {
    latestEventNotifier.value = event;
  }

  void updateActiveFocus(List<ScannerEvent> group) {
    activeFocusNotifier.value = List.unmodifiable(group);
  }

  void updateEvolutionStatus(EvolutionCheckStatus? status) {
    evolutionStatusNotifier.value = status;
  }

  void togglePause() {
    isPausedNotifier.value = !isPausedNotifier.value;
    if (isPausedNotifier.value) {
      _coordinator?.stop();
      unawaited(activeFramePump?.pause());
    } else {
      _coordinator?.start();
      unawaited(activeFramePump?.resume());
    }
  }

  Future<void> stopSession() async {
    isTrackingNotifier.value = false;
    isPausedNotifier.value = false;
    isPipVisibleNotifier.value = false;
    viewModeNotifier.value = MobileScannerViewMode.fullscreen;
    latestEventNotifier.value = null;
    activeFocusNotifier.value = const [];
    evolutionStatusNotifier.value = null;
    torchEnabledNotifier.value = false;
    zoomLevelNotifier.value = 1.0;
    previewAspectRatioNotifier.value = null;
    cachedCameras = const [];
    selectedCameraIndex = 0;
    minZoom = 1.0;
    maxZoom = 1.0;

    _pipCameraPreviewBuilder = null;
    _onExpandFromPip = null;
    _onToggleTorchCallback = null;
    final disposeCamera = _onDisposeCameraCallback;
    _onDisposeCameraCallback = null;
    final disableWakelock = _onDisableWakelockCallback;
    _onDisableWakelockCallback = null;
    activeCameraController = null;
    await activeFramePump?.dispose();
    activeFramePump = null;

    if (disposeCamera != null) {
      try {
        await disposeCamera();
      } catch (_) {}
    }

    if (disableWakelock != null) {
      try {
        await disableWakelock();
      } catch (_) {}
    }

    await _eventSub?.cancel();
    _eventSub = null;
    await _focusSub?.cancel();
    _focusSub = null;

    final stoppedCoordinator = _coordinator;
    ShinyAutoCounterService.instance.onSourceStopped(stoppedCoordinator);
    await _coordinator?.stop();
    if (_ownsCameraSourceOnStop) {
      await _cameraSource?.dispose();
    }
    _ownsCameraSourceOnStop = false;
    _coordinator = null;
    _cameraSource = null;
    _activeDexId = null;
  }
}
