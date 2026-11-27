import 'dart:async';
import 'dart:math' as math;
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
  int _sessionGeneration = 0;
  _MobilePipLifecycleObserver? _pipLifecycleObserver;

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
    _sessionGeneration++;
    final prevSource = _cameraSource;
    final prevCoord = _coordinator;
    final prevOwned = _ownsCameraSourceOnStop;
    if (prevCoord != null && !identical(prevCoord, coordinator)) {
      ShinyAutoCounterService.instance.onSourceStopped(prevCoord);
    }
    if (prevSource != null &&
        !identical(prevSource, cameraSource) &&
        prevOwned) {
      unawaited(prevSource.dispose());
    }

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

    final (:slotIds, :slotColors) = _computeActiveSlotRouting(
      cameraSource.scanMode,
      cameraSource.regions,
    );
    ShinyAutoCounterService.instance.attachIfPending(
      coordinator: coordinator,
      source: cameraSource,
      slotIds: slotIds,
      slotColorOverrides: slotColors,
    );
  }

  ({List<int> slotIds, Map<int, int> slotColors}) _computeActiveSlotRouting(
    MobileCameraScanMode mode,
    List<NormalizedScanRect> currentRegions,
  ) {
    final multiRegions =
        currentRegions.where((r) => r.enabled && r.slotId != null).toList();
    final hasPrimaryScan = mode == MobileCameraScanMode.autoFull ||
        currentRegions.any(
          (r) =>
              r.enabled &&
              (r.role == CameraZoneRole.scan ||
                  r.role == CameraZoneRole.focus) &&
              r.slotId == null,
        );
    final slotIdSet = <int>{
      if (hasPrimaryScan || multiRegions.isEmpty) 1,
      ...multiRegions.map((r) => r.slotId!),
    };
    final slotIds = slotIdSet.toList()..sort();
    final slotColors = {
      for (final r in multiRegions) r.slotId!: r.colorHex,
    };
    return (slotIds: slotIds, slotColors: slotColors);
  }

  void _syncSlotsToAutoCounter() {
    if (_coordinator == null ||
        !identical(ShinyAutoCounterService.instance.coordinator, _coordinator)) {
      return;
    }
    final (:slotIds, :slotColors) = _computeActiveSlotRouting(
      scanModeNotifier.value,
      regionsNotifier.value,
    );
    ShinyAutoCounterService.instance.syncSlots(
      slotIds: slotIds,
      slotColorOverrides: slotColors,
    );
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
    final pipActive = mode == MobileScannerViewMode.pip;
    isPipVisibleNotifier.value = pipActive;
    if (pipActive) {
      _registerPipLifecycleObserver();
    } else {
      _unregisterPipLifecycleObserver();
    }
  }

  void _registerPipLifecycleObserver() {
    if (_pipLifecycleObserver != null) return;
    final observer = _MobilePipLifecycleObserver(this);
    _pipLifecycleObserver = observer;
    WidgetsBinding.instance.addObserver(observer);
  }

  void _unregisterPipLifecycleObserver() {
    final observer = _pipLifecycleObserver;
    if (observer == null) return;
    _pipLifecycleObserver = null;
    WidgetsBinding.instance.removeObserver(observer);
  }

  void _handlePipAppLifecycleState(AppLifecycleState state) {
    if (!isPipVisibleNotifier.value) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (!isPausedNotifier.value) {
        _coordinator?.stop();
        unawaited(activeFramePump?.pause());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!isPausedNotifier.value && isTrackingNotifier.value) {
        _coordinator?.start();
        unawaited(activeFramePump?.resume());
      }
    }
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
    final maxX = math.max(
      minX,
      screenSize.width - safePadding.right - pipSize.width - margin,
    );
    final maxY = math.max(
      minY,
      screenSize.height - safePadding.bottom - pipSize.height - margin,
    );

    pipPositionNotifier.value = Offset(
      nextPosition.dx.clamp(minX, maxX).toDouble(),
      nextPosition.dy.clamp(minY, maxY).toDouble(),
    );
  }

  void setScanMode(MobileCameraScanMode mode) {
    scanModeNotifier.value = mode;
    _cameraSource?.setScanMode(mode);
    _syncSlotsToAutoCounter();
  }

  void setRegions(List<NormalizedScanRect> nextRegions) {
    final immutable = List<NormalizedScanRect>.unmodifiable(nextRegions);
    regionsNotifier.value = immutable;
    _cameraSource?.setRegions(immutable);
    _syncSlotsToAutoCounter();
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
    if (_coordinator != null &&
        identical(ShinyAutoCounterService.instance.coordinator, _coordinator)) {
      ShinyAutoCounterService.instance.setGlobalPause(isPausedNotifier.value);
    }
  }

  Future<void> stopSession() async {
    final stopGen = ++_sessionGeneration;
    _unregisterPipLifecycleObserver();

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
    final pumpToDispose = activeFramePump;
    activeFramePump = null;

    final eventSubToCancel = _eventSub;
    _eventSub = null;
    final focusSubToCancel = _focusSub;
    _focusSub = null;
    final stoppedCoordinator = _coordinator;
    _coordinator = null;
    final sourceToDispose = _cameraSource;
    _cameraSource = null;
    final ownsSource = _ownsCameraSourceOnStop;
    _ownsCameraSourceOnStop = false;
    _activeDexId = null;

    await pumpToDispose?.dispose();

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

    await eventSubToCancel?.cancel();
    await focusSubToCancel?.cancel();

    if (stopGen == _sessionGeneration) {
      ShinyAutoCounterService.instance.onSourceStopped(stoppedCoordinator);
    }
    await stoppedCoordinator?.stop();
    if (ownsSource) {
      await sourceToDispose?.dispose();
    }
  }
}

class _MobilePipLifecycleObserver with WidgetsBindingObserver {
  final MobileCameraTrackerService _service;
  _MobilePipLifecycleObserver(this._service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _service._handlePipAppLifecycleState(state);
  }
}
