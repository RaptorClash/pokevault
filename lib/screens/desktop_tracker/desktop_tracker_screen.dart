import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart' as io;

import '../../i18n/strings.g.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../services/desktop_tracker/desktop_ocr_driver.dart';
import '../../services/desktop_tracker/desktop_system_snipping_service.dart';
import '../../services/desktop_tracker/desktop_tracker_service.dart';
import '../../services/desktop_tracker/desktop_window_source.dart';
import '../../services/desktop_tracker/screen_region.dart';
import '../../services/desktop_tracker/tracker_alert_service.dart';
import '../../services/desktop_tracker/window_detector.dart';
import '../../services/desktop_tracker/windows_desktop_bridge.dart';
import '../../services/mobile_scanner/camera_scan_region.dart';
import '../../services/mobile_scanner/mobile_camera_source.dart';
import '../../services/scanner_core/models/scanner_event.dart';
import '../../services/scanner_core/models/scanner_settings.dart';
import '../../services/scanner_core/scanner_coordinator.dart';
import '../../services/scanner_core/scanner_persistence_service.dart';
import '../../services/shiny_auto_counter/shiny_auto_counter_service.dart';
import '../../utils/dex_logic_helper.dart';
import '../../utils/tracker_platform_helper.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import 'controllers/desktop_tracker_dex_controller.dart';
import 'controllers/desktop_tracker_tutorial_controller.dart';
import 'controllers/desktop_tracker_webcam_controller.dart';
import 'controllers/desktop_tracker_zones_controller.dart';
import 'widgets/custom_pattern_studio_dialog.dart';
import 'widgets/desktop_event_feed_card.dart';
import 'widgets/desktop_live_focus_bar.dart';
import 'widgets/desktop_multi_instance_card.dart';
import 'widgets/desktop_scan_region_section.dart';
import 'widgets/desktop_target_focus_card.dart';
import 'widgets/desktop_tracker_dialogs.dart';
import 'widgets/desktop_webcam_stage.dart';
import 'widgets/desktop_window_control_card.dart';
import 'widgets/dex_selection_modal.dart';
import 'widgets/floating_overlay_hud.dart';
import 'widgets/screen_snipping_overlay.dart';
import 'widgets/tracker_settings_dialog.dart';

/// Full Desktop Tracker Dashboard supporting Full Screen, Always-on-Top Mini-HUD, and Silent tracking.
class DesktopTrackerScreen extends StatefulWidget {
  final ScannerCoordinator coordinator;
  final List<DesktopWindowInfo> detectedWindows;
  final DesktopWindowSource? windowSource;
  final DesktopSystemSnippingService? snippingService;
  final String? initialDexId;
  final Future<ScreenRegionCaptureResult?> Function()? desktopSnippingLauncher;
  final Future<CapturedFrame?> Function()? sandboxImagePicker;
  final DesktopPlatformBridge? nativeBridge;
  final List<CameraDescription>? availableCamerasOverride;
  final bool disableHardwareCamera;
  final DesktopOcrDriver? cameraOcrDriverOverride;
  final bool keepTrackingInBackground;

  const DesktopTrackerScreen({
    super.key,
    required this.coordinator,
    this.detectedWindows = const [],
    this.windowSource,
    this.snippingService,
    this.initialDexId,
    this.desktopSnippingLauncher,
    this.sandboxImagePicker,
    this.nativeBridge,
    this.availableCamerasOverride,
    this.disableHardwareCamera = false,
    this.cameraOcrDriverOverride,
    this.keepTrackingInBackground = false,
  });

  @override
  State<DesktopTrackerScreen> createState() => _DesktopTrackerScreenState();
}

class _DesktopTrackerScreenState extends State<DesktopTrackerScreen> {
  List<DesktopWindowInfo> _windows = [];
  DesktopWindowInfo? _selectedWindow;
  String? _selectedDexId;
  final List<ScannerEvent> _events = [];
  StreamSubscription<ScannerEvent>? _eventSub;
  StreamSubscription<List<ScannerEvent>>? _activeFocusSub;
  List<ScannerEvent> _activeFocusEvents = const [];
  bool _showFloatingHud = false;
  bool _isSnippingMode = false;
  bool _isSnippingForFocusZone = false;
  bool _isSnippingForExtraFocusBox = false;
  bool _isLaunchingSnipping = false;
  ScreenRegion? _customScreenRegion;
  Uint8List? _snippetPreviewBytes;
  Uint8List? _focusSnippetPreviewBytes;
  String _ocrLanguageTag = 'de-DE';
  bool _ocrUsedFallbackLanguage = false;
  String? _ocrFallbackResolvedTag;
  late final TrackerAlertService _alertService;
  double _hudOpacity = 0.90;
  bool _hudCompact = false;
  bool _hudPinned = true;
  final ValueNotifier<Offset> _hudPositionNotifier =
      ValueNotifier<Offset>(const Offset(20, 20));
  bool _isScanningActive = true;
  bool _hasUserToggledScan = false;
  bool _isRefreshingWindows = false;
  ScanRegionPreset _scanRegion = ScanRegionPreset.fullWindow;
  late final DesktopWindowSource _activeWindowSource;
  late final DesktopSystemSnippingService _snippingService;
  final ScannerPersistenceService _persistenceService =
      ScannerPersistenceService();
  final DesktopTrackerDexController _dexController =
      DesktopTrackerDexController();
  final DesktopTrackerTutorialController _tutorialController =
      DesktopTrackerTutorialController();
  late final DesktopTrackerWebcamController _webcamController;
  int? _snippingMultiSlotId;
  bool _snippingMultiIsFocus = false;
  bool _showZoneAInfo = false;
  bool _showZoneBInfo = false;
  bool _showScanProfileInfo = false;
  bool _isEditingCameraRegions = false;
  bool _hasShownSelfScanDialogThisSession = false;
  DexProvider? _dexProvider;

  bool get _isLiveWindows =>
      !kIsWeb &&
      io.Platform.isWindows &&
      !io.Platform.environment.containsKey('FLUTTER_TEST');

  bool get _showOverlayControls =>
      TrackerPlatformHelper.isDesktopOverlaySupported ||
      widget.nativeBridge != null;

  bool get _isCameraSourceSelected => _selectedWindow?.isCameraSource ?? false;

  DesktopPlatformBridge? get _effectiveNativeBridge =>
      widget.nativeBridge ??
      (_isLiveWindows ? WindowsDesktopBridge.instance : null);

  MobileCameraSource _ensureCameraSource() {
    return _webcamController.ensureCameraSource(
      ocrLanguageTag: _ocrLanguageTag,
      scanRegion: _scanRegion,
    );
  }

  void _onWebcamControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _alertService = TrackerAlertService();
    _snippingService =
        widget.snippingService ?? DesktopSystemSnippingService.instance;
    _selectedDexId = widget.initialDexId;
    _webcamController = DesktopTrackerWebcamController(
      bridgeResolver: () => _effectiveNativeBridge,
      cameraOcrDriverOverride: widget.cameraOcrDriverOverride,
      disableHardwareCamera: widget.disableHardwareCamera,
      sandboxImagePicker: widget.sandboxImagePicker,
      initialCameras: widget.availableCamerasOverride,
    )..addListener(_onWebcamControllerChanged);

    final bridge = _effectiveNativeBridge;
    _activeWindowSource = widget.windowSource ??
        (bridge != null
            ? DesktopWindowSource(
                captureDriver: WindowsDesktopCaptureDriver(bridge: bridge),
                ocrDriver: WindowsDesktopOcrDriver(
                  bridge: bridge,
                  initialPreprocessProfile:
                      widget.coordinator.settings.preprocessProfile,
                  onRecognitionResult: _handleOcrMetaResult,
                ),
                nativeBridge: bridge,
              )
            : DesktopWindowSource(
                captureDriver: const DefaultDesktopCaptureDriver(),
                ocrDriver: DefaultDesktopOcrDriver(),
              ));

    _activeWindowSource.setPollInterval(
      Duration(milliseconds: widget.coordinator.settings.scanIntervalMs),
    );
    _activeWindowSource.setPreprocessProfile(
      widget.coordinator.settings.preprocessProfile,
    );
    _activeWindowSource.setLiveFocusPreset(
      widget.coordinator.settings.liveFocusPreset,
    );
    _activeWindowSource.setExtraFocusRegions(
      widget.coordinator.settings.extraFocusRegions,
    );
    _activeWindowSource.setMultiInstanceSlots(
      widget.coordinator.settings.multiInstanceSlots,
    );
    _activeWindowSource.setMaskSelfWindow(
      widget.coordinator.settings.maskSelfWindow,
    );
    _activeWindowSource.setPreviewPolicy(enabled: true, maxWidth: 320);
    _activeWindowSource.selfWindowOverlapNotifier
        .addListener(_onSelfWindowOverlapChanged);
    unawaited(_loadPersistedSettings());
    final service = DesktopTrackerService.instance;
    final reusedExistingSession = widget.windowSource != null &&
        service.isTrackingActive &&
        identical(service.windowSource, _activeWindowSource);
    _customScreenRegion =
        service.activeScreenRegion ?? _activeWindowSource.screenRegion;
    _snippetPreviewBytes = service.activeSnippetPreview;
    _showFloatingHud = service.showFloatingHud;

    if (widget.windowSource != null) {
      _selectedWindow =
          widget.windowSource!.selectedWindow ?? service.activeWindow;
      final restoredCrop = widget.windowSource!.cropRegion;
      if (_selectedWindow != null &&
          restoredCrop != null &&
          _customScreenRegion == null) {
        final detector = WindowDetector();
        for (final preset in ScanRegionPreset.values) {
          if (detector.calculateScanRegion(
                preset,
                windowWidth: _selectedWindow!.width,
                windowHeight: _selectedWindow!.height,
              ) ==
              restoredCrop) {
            _scanRegion = preset;
            break;
          }
        }
      }
      if (service.recentEvents.isNotEmpty) {
        _events.addAll(service.recentEvents);
      }
      if (reusedExistingSession) {
        _isScanningActive = !service.isPaused;
        _hasUserToggledScan = true;
      }
    }

    service.showFloatingHudNotifier
        .addListener(_onServiceHudVisibilityChanged);
    service.isPausedNotifier.addListener(_onServicePausedChanged);
    service.configureBackgroundHandlers(onBackgroundAutoCatch: null);

    service.configureNativeHudBridge(
      bridge: bridge,
      isCaughtChecker: _isPokemonIdCaughtInActiveDex,
      onMarkCaught: (ev) async {
        if (ev.pokemonId != null) {
          await _markPokemonCaughtInDex(
            ev.pokemonId!,
            isShiny: ev.isShiny,
            isAlpha: ev.isAlpha,
          );
        }
      },
    );

    widget.coordinator.bindSource(_activeWindowSource);
    _syncAutoScanState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!reusedExistingSession) {
        service.startTracking(
          coordinator: widget.coordinator,
          windowSource: _activeWindowSource,
          activeSource: _isCameraSourceSelected
              ? _ensureCameraSource()
              : _activeWindowSource,
          dexId: _selectedDexId,
          ownsWindowSource:
              widget.keepTrackingInBackground && widget.windowSource == null,
          initiallyPaused: !_isScanningActive,
        );
        service.updateHudTarget(
          window: _selectedWindow,
          screenRegion: _customScreenRegion,
          snippetPreview: _snippetPreviewBytes,
        );
      }
      _tutorialController.showIfNeeded(
        context: context,
        isMounted: mounted,
        showOverlayControls: _showOverlayControls,
      );
    });

    if (widget.detectedWindows.isNotEmpty) {
      _windows = List.from(widget.detectedWindows);
      if (widget.availableCamerasOverride != null) {
        _webcamController.cameras =
            List.unmodifiable(widget.availableCamerasOverride!);
        _windows.addAll(
          _buildCameraWindowEntries(
            _webcamController.cameras,
            includeFallbackIfEmpty: false,
          ),
        );
      }
      _activeWindowSource.updateKnownWindows(_windows);
      _selectDefaultWindow();
    } else if (!_showOverlayControls) {
      if (widget.availableCamerasOverride != null) {
        _webcamController.cameras =
            List.unmodifiable(widget.availableCamerasOverride!);
        _windows = _buildCameraWindowEntries(
          _webcamController.cameras,
          includeFallbackIfEmpty: true,
        );
        _activeWindowSource.updateKnownWindows(_windows);
        _selectDefaultWindow();
      } else {
        _windows = [DesktopWindowInfo.webcamFallbackPhoto()];
        _activeWindowSource.updateKnownWindows(_windows);
        _selectDefaultWindow();
        if (!io.Platform.environment.containsKey('FLUTTER_TEST')) {
          _isRefreshingWindows = true;
          _loadWindowsAsync();
        }
      }
    } else if (_isLiveWindows) {
      _isRefreshingWindows = true;
      _loadWindowsAsync();
    } else {
      _windows = WindowDetector().getFallbackWindows();
      if (widget.availableCamerasOverride != null) {
        _webcamController.cameras =
            List.unmodifiable(widget.availableCamerasOverride!);
        _windows.addAll(
          _buildCameraWindowEntries(
            _webcamController.cameras,
            includeFallbackIfEmpty: false,
          ),
        );
      }
      _activeWindowSource.updateKnownWindows(_windows);
      _selectDefaultWindow();
      if (widget.availableCamerasOverride == null) {
        _loadWindowsAsync();
      }
    }

    _eventSub = widget.coordinator.events.listen((event) {
      if (!mounted) return;
      _alertService.handleEvent(event);

      final dexProvider = Provider.of<DexProvider>(context, listen: false);
      final targetDex = _getActiveDex(dexProvider);
      final storedEvent = DesktopTrackerDexController.prepareIncomingEvent(
        event,
        targetDex: targetDex,
        autoMarkCaught: widget.coordinator.settings.autoMarkCaught,
      );

      setState(() {
        _events.insert(0, storedEvent);
        if (_events.length > 50) {
          _events.removeLast();
        }
      });

      _refreshEvolutionStatusFor(storedEvent, targetDex, dexProvider);

      if (widget.coordinator.settings.autoMarkCaught &&
          storedEvent.type == ScannerEventType.caught &&
          storedEvent.pokemonId != null &&
          _selectedDexId != null) {
        _markPokemonCaughtInDex(
          storedEvent.pokemonId!,
          isShiny: storedEvent.isShiny,
          isAlpha: storedEvent.isAlpha,
          silent: true,
        );
      }
    });

    _activeFocusSub = widget.coordinator.activeFocusStream.listen((focusGroup) {
      if (!mounted) return;
      if (!listEquals(_activeFocusEvents, focusGroup)) {
        setState(() {
          _activeFocusEvents = focusGroup;
        });
      }
      if (focusGroup.isNotEmpty) {
        final dexProv = Provider.of<DexProvider>(context, listen: false);
        _refreshEvolutionStatusFor(
          focusGroup.first,
          _getActiveDex(dexProv),
          dexProv,
        );
      }
    });
  }

  void _syncAutoCounterSlots(List<MultiInstanceSlot> slots) {
    final autoCounter = ShinyAutoCounterService.instance;
    if (!autoCounter.isRunning ||
        !identical(autoCounter.coordinator, widget.coordinator)) {
      return;
    }
    final enabledSlots = slots.where((s) => s.enabled).toList();
    autoCounter.syncSlots(
      slotIds: enabledSlots.isNotEmpty
          ? enabledSlots.map((s) => s.id).toList()
          : const [1],
      slotColorOverrides: {for (final s in enabledSlots) s.id: s.colorHex},
    );
  }

  void _syncOcrLanguage({required bool listen}) {
    final appPokemonLang = _resolveAppPokemonLanguage(listen: listen);
    widget.coordinator.setEffectiveOcrLanguage(appPokemonLang);

    final configured = widget.coordinator.settings.ocrLanguage;
    final effectiveLang =
        (configured != 'auto' && configured.isNotEmpty)
            ? configured
            : appPokemonLang;

    final mappedTag =
        WindowsDesktopBridge.mapPokemonLanguageToBcp47(effectiveLang);
    if (mappedTag != _ocrLanguageTag ||
        _activeWindowSource.ocrLanguageTag != mappedTag) {
      _ocrLanguageTag = mappedTag;
      _ocrUsedFallbackLanguage = false;
      _ocrFallbackResolvedTag = null;
      _activeWindowSource.setOcrLanguageTag(mappedTag);
      _webcamController.setOcrLanguageTag(mappedTag);
    }
  }

  void _onServicePausedChanged() {
    if (!mounted) return;
    final scanning = !DesktopTrackerService.instance.isPaused;
    if (scanning != _isScanningActive) {
      setState(() => _isScanningActive = scanning);
      _syncOverlayBorders();
    }
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final current = widget.coordinator.settings;
      final saved = await _persistenceService.loadScannerSettings(base: current);
      if (!mounted) return;
      final isPristine = current.scanIntervalMs == 400 &&
          current.preprocessProfile == OcrPreprocessProfile.standard &&
          current.ocrLanguage == 'auto' &&
          current.customPatterns.isEmpty &&
          current.liveFocusPreset == LiveFocusPreset.disabled &&
          current.ignoredPokemonIds.isEmpty &&
          current.showScreenBorders &&
          current.multiInstanceSlots.isEmpty &&
          !current.maskSelfWindow &&
          !current.suppressSelfScanWarning;
      if (!isPristine) return;

      final merged = current.copyWith(
        scanIntervalMs: saved.scanIntervalMs,
        preprocessProfile: saved.preprocessProfile,
        ocrLanguage: saved.ocrLanguage,
        customPatterns: saved.customPatterns,
        liveFocusPreset: saved.liveFocusPreset == LiveFocusPreset.customRegion
            ? LiveFocusPreset.disabled
            : saved.liveFocusPreset,
        ignoredPokemonIds: saved.ignoredPokemonIds,
        showScreenBorders: saved.showScreenBorders,
        multiInstanceSlots: saved.multiInstanceSlots,
        extraFocusRegions: saved.extraFocusRegions,
        maskSelfWindow: saved.maskSelfWindow,
        suppressSelfScanWarning: saved.suppressSelfScanWarning,
      );
      if (merged.scanIntervalMs == current.scanIntervalMs &&
          merged.preprocessProfile == current.preprocessProfile &&
          merged.ocrLanguage == current.ocrLanguage &&
          merged.customPatterns.isEmpty &&
          merged.liveFocusPreset == current.liveFocusPreset &&
          merged.ignoredPokemonIds.isEmpty &&
          merged.showScreenBorders == current.showScreenBorders &&
          merged.multiInstanceSlots.isEmpty &&
          merged.extraFocusRegions.isEmpty &&
          !merged.maskSelfWindow &&
          !merged.suppressSelfScanWarning) {
        return;
      }
      widget.coordinator.updateSettings(merged);
      _activeWindowSource.setPollInterval(
        Duration(milliseconds: merged.scanIntervalMs),
      );
      _activeWindowSource.setPreprocessProfile(merged.preprocessProfile);
      _activeWindowSource.setLiveFocusPreset(merged.liveFocusPreset);
      _activeWindowSource.setExtraFocusRegions(merged.extraFocusRegions);
      _activeWindowSource.setMultiInstanceSlots(merged.multiInstanceSlots);
      _activeWindowSource.setMaskSelfWindow(merged.maskSelfWindow);
      _syncOcrLanguage(listen: false);
      _syncAutoCounterSlots(merged.multiInstanceSlots);
      _syncOverlayBorders();
      if (mounted) setState(() {});
    } catch (_) {
      // SharedPreferences unavailable in isolated unit/widget test environments
    }
  }

  String _resolveAppPokemonLanguage({bool listen = false}) {
    try {
      return Provider.of<SettingsProvider>(context, listen: listen)
          .effectivePokemonLanguage;
    } catch (_) {
      return 'de';
    }
  }

  void _updateSettingsAndPersist(ScannerSettings next) {
    widget.coordinator.updateSettings(next);
    _activeWindowSource.setPollInterval(
      Duration(milliseconds: next.scanIntervalMs),
    );
    _activeWindowSource.setPreprocessProfile(next.preprocessProfile);
    _activeWindowSource.setLiveFocusPreset(next.liveFocusPreset);
    _activeWindowSource.setExtraFocusRegions(next.extraFocusRegions);
    _activeWindowSource.setMultiInstanceSlots(next.multiInstanceSlots);
    _activeWindowSource.setMaskSelfWindow(next.maskSelfWindow);
    _syncOcrLanguage(listen: false);
    _syncOverlayBorders();
    _syncAutoCounterSlots(next.multiInstanceSlots);
    unawaited(_persistenceService.saveScannerSettings(next));
  }

  void _syncOverlayBorders() {
    DesktopTrackerZonesController.syncOverlayBorders(
      bridge: _effectiveNativeBridge,
      showScreenBorders: widget.coordinator.settings.showScreenBorders,
      selectedWindow: _selectedWindow,
      customScreenRegion: _customScreenRegion,
      cropRegion: _activeWindowSource.cropRegion,
      isScanningActive: _isScanningActive,
      liveFocusPreset: widget.coordinator.settings.liveFocusPreset,
      liveFocusScreenRegion: _activeWindowSource.liveFocusScreenRegion,
      extraFocusRegions: widget.coordinator.settings.extraFocusRegions,
      multiInstanceSlots: widget.coordinator.settings.multiInstanceSlots,
      windows: _windows,
    );
  }

  void _refreshEvolutionStatusFor(
    ScannerEvent? event,
    UserDex? activeDex,
    DexProvider dexProvider,
  ) {
    String lang = 'de';
    try {
      lang = Provider.of<SettingsProvider>(context, listen: false)
          .effectivePokemonLanguage;
    } catch (_) {
      lang = 'de';
    }
    _dexController.refreshEvolutionStatusFor(
      event: event,
      activeDex: activeDex,
      dexProvider: dexProvider,
      languageCode: lang,
      isMounted: () => mounted,
      onStatusChanged: (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _dexProvider = Provider.of<DexProvider>(context, listen: false);
    } catch (_) {}
    _syncOcrLanguage(listen: true);
  }

  void _handleOcrMetaResult(OcrRecognitionResult res) {
    if (!mounted) return;
    if (res.usedFallbackLanguage != _ocrUsedFallbackLanguage ||
        res.resolvedLanguageTag != _ocrFallbackResolvedTag) {
      setState(() {
        _ocrUsedFallbackLanguage = res.usedFallbackLanguage;
        _ocrFallbackResolvedTag = res.resolvedLanguageTag;
      });
    }
  }

  void _onServiceHudVisibilityChanged() {
    if (!mounted) return;
    final visible = DesktopTrackerService.instance.showFloatingHud;
    if (visible != _showFloatingHud) {
      setState(() => _showFloatingHud = visible);
    }
  }

  bool _isPokemonIdCaughtInActiveDex(int pokemonId) {
    if (!mounted) return false;
    try {
      final dexProvider = Provider.of<DexProvider>(context, listen: false);
      final activeDex = _getActiveDex(dexProvider);
      if (activeDex == null) return false;
      return DexLogicHelper.isPokemonCaught(activeDex, pokemonId.toString());
    } catch (_) {
      return false;
    }
  }

  Future<List<CameraDescription>> _loadCameraDescriptions() async {
    if (widget.availableCamerasOverride != null) {
      return List.unmodifiable(widget.availableCamerasOverride!);
    }
    if (!TrackerPlatformHelper.isCameraTrackerSupported) {
      return const [];
    }
    if (!kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST')) {
      return const [];
    }
    try {
      return await availableCameras();
    } catch (_) {
      return const [];
    }
  }

  List<DesktopWindowInfo> _buildCameraWindowEntries(
    List<CameraDescription> cameras, {
    required bool includeFallbackIfEmpty,
  }) {
    if (cameras.isEmpty) {
      return includeFallbackIfEmpty
          ? [DesktopWindowInfo.webcamFallbackPhoto()]
          : const [];
    }
    return [
      for (int i = 0; i < cameras.length; i++)
        DesktopWindowInfo.webcam(
          index: i,
          name: cameras[i].name,
          sensorOrientation: cameras[i].sensorOrientation,
        ),
    ];
  }

  Future<void> _loadWindowsAsync() async {
    try {
      final cams = await _loadCameraDescriptions();
      List<DesktopWindowInfo> wins;
      if (_showOverlayControls) {
        final bridge = _effectiveNativeBridge;
        final detected = bridge != null
            ? await WindowDetector(
                nativeWindowEnumerator: bridge.enumerateWindowsAndMonitors,
              ).getOpenWindowsAsync()
            : await WindowDetector().getOpenWindowsAsync();
        wins = [
          ...detected,
          ..._buildCameraWindowEntries(cams, includeFallbackIfEmpty: false),
        ];
      } else {
        wins = _buildCameraWindowEntries(cams, includeFallbackIfEmpty: true);
      }

      if (!mounted) return;
      setState(() {
        _webcamController.cameras = cams;
        _windows = wins;
        _activeWindowSource.updateKnownWindows(_windows);
        _selectDefaultWindow();
        _isRefreshingWindows = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRefreshingWindows = false;
      });
    }
  }

  bool _shouldAutoScan(DesktopWindowInfo? win, ScreenRegion? region) {
    if (region != null ||
        _activeWindowSource.liveFocusScreenRegion != null ||
        widget.coordinator.settings.extraFocusRegions.isNotEmpty) {
      return true;
    }
    return win != null && !win.isDesktopScreen;
  }

  void _bindSourceForSelection(DesktopWindowInfo? window) {
    if (window != null && window.isCameraSource) {
      if (_activeWindowSource.isRunning) {
        unawaited(_activeWindowSource.stop());
      }
      final camSource = _ensureCameraSource();
      widget.coordinator.bindSource(camSource);
      DesktopTrackerService.instance.setActiveSource(camSource);
    } else {
      final camSource = _webcamController.cameraSource;
      if (camSource != null && camSource.isRunning) {
        unawaited(camSource.stop());
      }
      widget.coordinator.bindSource(_activeWindowSource);
      DesktopTrackerService.instance.setActiveSource(_activeWindowSource);
    }
  }

  void _syncAutoScanState({bool force = false}) {
    if (_hasUserToggledScan && !force) return;
    final shouldScan = _shouldAutoScan(_selectedWindow, _customScreenRegion);
    _isScanningActive = shouldScan;
    if (DesktopTrackerService.instance.isTrackingActive) {
      DesktopTrackerService.instance.isPaused = !_isScanningActive;
    }
    if (shouldScan) {
      widget.coordinator.start();
    } else {
      widget.coordinator.stop();
    }
  }

  Future<void> _syncCameraHardwareForSelection(DesktopWindowInfo? window) {
    return _webcamController.syncHardwareForSelection(
      window: window,
      ocrLanguageTag: _ocrLanguageTag,
      scanRegion: _scanRegion,
      isMounted: () => mounted,
      isScanningActive: () => _isScanningActive,
      currentWindow: () => _selectedWindow,
    );
  }

  void _selectDefaultWindow() {
    if (_windows.isEmpty) return;

    final existing = _selectedWindow;
    if (existing != null) {
      final match = _windows.where((w) => w == existing).firstOrNull ??
          _windows.where((w) => w.id == existing.id).firstOrNull;
      if (match != null) {
        _selectedWindow = match;
        _applyScanRegion(match);
        _activeWindowSource.setSelectedWindow(_selectedWindow);
        _bindSourceForSelection(_selectedWindow);
        _syncAutoScanState();
        unawaited(_syncCameraHardwareForSelection(_selectedWindow));
        DesktopTrackerService.instance.updateHudTarget(
          window: _selectedWindow,
          screenRegion: _customScreenRegion,
        );
        return;
      }
    }

    _selectedWindow = _windows.firstWhere(
      (w) => w.isKnownEmulator,
      orElse: () => _windows.first,
    );
    _applyScanRegion(_selectedWindow);
    _activeWindowSource.setSelectedWindow(_selectedWindow);
    _bindSourceForSelection(_selectedWindow);
    _syncAutoScanState();
    unawaited(_syncCameraHardwareForSelection(_selectedWindow));
    DesktopTrackerService.instance.updateHudTarget(
      window: _selectedWindow,
      screenRegion: _customScreenRegion,
    );
    if (_customScreenRegion == null &&
        _selectedWindow != null &&
        !_selectedWindow!.isDesktopScreen &&
        !_selectedWindow!.isCameraSource) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_activeWindowSource.triggerSingleScan());
      });
    }
  }

  void _applyScanRegion(DesktopWindowInfo? window) {
    if (window == null) return;
    if (window.isCameraSource) {
      _webcamController.setAutoPreset(_scanRegion);
      return;
    }
    final region = WindowDetector().calculateScanRegion(
      _scanRegion,
      windowWidth: window.width,
      windowHeight: window.height,
    );
    _activeWindowSource.setCropRegion(region);
  }

  @override
  void dispose() {
    TutorialOverlay.resetShowing();
    _activeWindowSource.selfWindowOverlapNotifier
        .removeListener(_onSelfWindowOverlapChanged);
    final service = DesktopTrackerService.instance;
    service.showFloatingHudNotifier
        .removeListener(_onServiceHudVisibilityChanged);
    service.isPausedNotifier.removeListener(_onServicePausedChanged);
    _webcamController.removeListener(_onWebcamControllerChanged);
    _hudPositionNotifier.dispose();

    final autoCounterUsingThisCoordinator =
        ShinyAutoCounterService.instance.isRunning &&
            identical(
              ShinyAutoCounterService.instance.coordinator,
              widget.coordinator,
            );
    final keepCameraAliveForAutoCounter =
        _isCameraSourceSelected && autoCounterUsingThisCoordinator;

    final keepAlive = widget.keepTrackingInBackground &&
        (!_isCameraSourceSelected || autoCounterUsingThisCoordinator) &&
        (service.isTrackingActive ||
            _isScanningActive ||
            _hasUserToggledScan ||
            _customScreenRegion != null ||
            _showFloatingHud ||
            autoCounterUsingThisCoordinator);

    if (keepCameraAliveForAutoCounter && keepAlive) {
      service.setBackgroundCleanup(() async {
        await _webcamController.stopAndDisposeSource();
        _webcamController.dispose();
      });
    } else {
      unawaited(_webcamController.stopAndDisposeSource());
      _webcamController.dispose();
    }

    if (keepAlive) {
      _activeWindowSource.setPreviewPolicy(enabled: false);
      service.isPaused = !_isScanningActive;
      final dexProv = _dexProvider;
      final fallbackDexId = _selectedDexId;
      final autoMark = widget.coordinator.settings.autoMarkCaught;
      service.configureBackgroundHandlers(
        isCaughtChecker: (pid) {
          if (dexProv == null) return false;
          final targetDex = DesktopTrackerDexController.resolveTargetDex(
            dexProv,
            service.activeDexId ?? fallbackDexId,
          );
          return targetDex != null &&
              DexLogicHelper.isPokemonCaught(targetDex, pid.toString());
        },
        onMarkCaught: (ev) async {
          if (dexProv == null || ev.pokemonId == null) return;
          final targetDex = DesktopTrackerDexController.resolveTargetDex(
            dexProv,
            service.activeDexId ?? fallbackDexId,
          );
          if (targetDex == null) return;
          await DesktopTrackerDexController.persistCaughtStatus(
            dexProv,
            targetDex,
            ev.pokemonId!,
            isShiny: ev.isShiny,
            isAlpha: ev.isAlpha,
          );
        },
        onBackgroundAutoCatch: autoMark
            ? (ev) async {
                if (dexProv == null ||
                    ev.type != ScannerEventType.caught ||
                    ev.pokemonId == null) {
                  return;
                }
                final targetDex = DesktopTrackerDexController.resolveTargetDex(
                  dexProv,
                  service.activeDexId ?? fallbackDexId,
                );
                if (targetDex == null) return;
                await DesktopTrackerDexController.persistCaughtStatus(
                  dexProv,
                  targetDex,
                  ev.pokemonId!,
                  isShiny: ev.isShiny,
                  isAlpha: ev.isAlpha,
                );
              }
            : null,
      );
    } else {
      unawaited(_effectiveNativeBridge?.setScanRegionBorder(null));
      unawaited(_effectiveNativeBridge?.setOverlayBorders(const []));
      widget.coordinator.stop();
      if (identical(service.windowSource, _activeWindowSource)) {
        unawaited(service.stopTracking());
      } else if (widget.windowSource == null) {
        _activeWindowSource.dispose();
      }
    }

    _alertService.dispose();
    _eventSub?.cancel();
    _activeFocusSub?.cancel();
    super.dispose();
  }

  void _toggleScreenBorders(bool visible) {
    setState(() {
      _updateSettingsAndPersist(
        widget.coordinator.settings.copyWith(showScreenBorders: visible),
      );
    });
  }

  void _addMultiInstanceSlot() {
    final nextSlots = DesktopTrackerZonesController.addMultiInstanceSlot(
      widget.coordinator.settings.multiInstanceSlots,
    );
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(multiInstanceSlots: nextSlots),
    );
  }

  void _updateMultiSlot(
    int slotId,
    MultiInstanceSlot Function(MultiInstanceSlot slot) updater,
  ) {
    final nextSlots = DesktopTrackerZonesController.updateMultiSlot(
      widget.coordinator.settings.multiInstanceSlots,
      slotId,
      updater,
    );
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(multiInstanceSlots: nextSlots),
    );
    if (_isScanningActive && nextSlots.any((s) => s.hasScan || s.hasFocus)) {
      widget.coordinator.start();
      unawaited(_activeWindowSource.triggerSingleScan());
    }
  }

  Future<void> _startMultiSlotSnipping(
    int slotId, {
    required bool isFocus,
  }) async {
    if (_isLaunchingSnipping) return;

    final bridge = _effectiveNativeBridge;
    final launcher = widget.desktopSnippingLauncher ??
        (bridge != null
            ? () => bridge.startDesktopSnipping(hideAppWindow: false)
            : null);

    if (launcher == null) {
      setState(() {
        _isSnippingForFocusZone = false;
        _snippingMultiSlotId = slotId;
        _snippingMultiIsFocus = isFocus;
        _isSnippingMode = true;
      });
      return;
    }

    _isLaunchingSnipping = true;
    try {
      final result = await launcher();
      if (!mounted || result == null) return;
      _applyMultiSlotRegion(slotId, result.region, isFocus: isFocus);
    } finally {
      _isLaunchingSnipping = false;
    }
  }

  void _applyMultiSlotRegion(
    int slotId,
    ScreenRegion region, {
    required bool isFocus,
  }) {
    final nextSlots = DesktopTrackerZonesController.applyMultiSlotRegion(
      widget.coordinator.settings.multiInstanceSlots,
      slotId,
      region,
      isFocus: isFocus,
    );

    setState(() {
      _snippingMultiSlotId = null;
      _snippingMultiIsFocus = false;
      _isSnippingMode = false;
      _isScanningActive = true;
      _hasUserToggledScan = false;
    });
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(multiInstanceSlots: nextSlots),
    );
    widget.coordinator.start();
    unawaited(_activeWindowSource.triggerSingleScan());
  }

  void _removeMultiInstanceSlot(int slotId) {
    final nextSlots = DesktopTrackerZonesController.removeMultiInstanceSlot(
      widget.coordinator.settings.multiInstanceSlots,
      slotId,
    );
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(multiInstanceSlots: nextSlots),
    );
  }

  void _clearMultiInstanceSlots() {
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(multiInstanceSlots: const []),
    );
  }

  void _selectLiveFocusPreset(LiveFocusPreset preset) {
    setState(() {
      if (preset != LiveFocusPreset.customRegion) {
        _focusSnippetPreviewBytes = null;
      }
      _activeWindowSource.setLiveFocusPreset(preset);
    });
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(
        liveFocusPreset: preset,
        extraFocusRegions: preset == LiveFocusPreset.disabled
            ? const []
            : widget.coordinator.settings.extraFocusRegions,
      ),
    );
    if (preset != LiveFocusPreset.disabled &&
        (_selectedWindow != null || _customScreenRegion != null)) {
      if (!_isScanningActive) {
        setState(() {
          _isScanningActive = true;
          _hasUserToggledScan = false;
        });
        widget.coordinator.start();
      }
      unawaited(_activeWindowSource.triggerSingleScan());
    }
  }

  Future<void> _handleStartExtraFocusBoxSnipping() async {
    if (_isLaunchingSnipping) return;

    final bridge = _effectiveNativeBridge;
    final launcher = widget.desktopSnippingLauncher ??
        (bridge != null
            ? () => bridge.startDesktopSnipping(hideAppWindow: false)
            : null);

    if (launcher == null) {
      setState(() {
        _isSnippingForFocusZone = false;
        _isSnippingForExtraFocusBox = true;
        _isSnippingMode = true;
      });
      return;
    }

    _isLaunchingSnipping = true;
    try {
      final result = await launcher();
      if (!mounted || result == null) return;
      _appendExtraFocusRegion(result.region);
    } finally {
      _isLaunchingSnipping = false;
    }
  }

  void _appendExtraFocusRegion(ScreenRegion region) {
    final nextRegions = <ScreenRegion>[
      ...widget.coordinator.settings.extraFocusRegions,
      ScreenRegion(
        x: region.x,
        y: region.y,
        width: region.width,
        height: region.height,
        isAbsoluteScreen: region.isAbsoluteScreen,
        label:
            '${t.scanner_zone_focus_label} B${widget.coordinator.settings.extraFocusRegions.length + 2}',
      ),
    ];
    setState(() {
      _isSnippingForExtraFocusBox = false;
      _isSnippingMode = false;
      _isScanningActive = true;
      _hasUserToggledScan = false;
    });
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(extraFocusRegions: nextRegions),
    );
    widget.coordinator.start();
    unawaited(_activeWindowSource.triggerSingleScan());
  }

  void _removeExtraFocusRegion(int index) {
    final current = widget.coordinator.settings.extraFocusRegions;
    if (index < 0 || index >= current.length) return;
    final nextRegions = [
      for (int i = 0; i < current.length; i++)
        if (i != index) current[i],
    ];
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(extraFocusRegions: nextRegions),
    );
  }

  Future<void> _handleStartLiveFocusSnipping() async {
    if (_isLaunchingSnipping) return;

    final bridge = _effectiveNativeBridge;
    final launcher = widget.desktopSnippingLauncher ??
        (bridge != null
            ? () => bridge.startDesktopSnipping(hideAppWindow: false)
            : null);

    if (launcher == null) {
      setState(() {
        _isSnippingForFocusZone = true;
        _isSnippingMode = true;
      });
      return;
    }

    _isLaunchingSnipping = true;
    try {
      final result = await launcher();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _focusSnippetPreviewBytes = result.previewBytes;
          _activeWindowSource.setLiveFocusScreenRegion(result.region);
          _isScanningActive = true;
          _hasUserToggledScan = false;
        });
        _updateSettingsAndPersist(
          widget.coordinator.settings.copyWith(
            liveFocusPreset: LiveFocusPreset.customRegion,
          ),
        );
        widget.coordinator.start();
        unawaited(_activeWindowSource.triggerSingleScan());
      }
    } finally {
      _isLaunchingSnipping = false;
    }
  }

  void _ignoreTeamPokemon(int pokemonId, {String? displayName}) {
    final current = widget.coordinator.settings.ignoredPokemonIds;
    if (current.contains(pokemonId)) return;
    final updated = List<int>.unmodifiable([...current, pokemonId]);
    setState(() {
      _activeFocusEvents = _activeFocusEvents
          .where((e) => e.pokemonId != pokemonId)
          .toList(growable: false);
    });
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(ignoredPokemonIds: updated),
    );
    if (mounted) {
      final label = displayName ?? '#$pokemonId';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label wird als eigenes Team ignoriert.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _unignoreTeamPokemon(int pokemonId) {
    final current = widget.coordinator.settings.ignoredPokemonIds;
    if (!current.contains(pokemonId)) return;
    final updated = List<int>.unmodifiable(
      current.where((id) => id != pokemonId),
    );
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(ignoredPokemonIds: updated),
    );
  }

  void _refreshWindows() {
    setState(() => _isRefreshingWindows = true);
    _loadWindowsAsync();
  }

  void _onWindowSelected(DesktopWindowInfo? window) {
    setState(() {
      _selectedWindow = window;
      _customScreenRegion = null;
      _snippetPreviewBytes = null;
      _activeWindowSource.setScreenRegion(null);
      _applyScanRegion(window);
      _activeWindowSource.setSelectedWindow(window);
      _bindSourceForSelection(window);
      _hasUserToggledScan = false;
      _syncAutoScanState(force: true);
    });
    _syncOverlayBorders();
    unawaited(_syncCameraHardwareForSelection(window));
    DesktopTrackerService.instance.updateHudTarget(
      window: window,
      screenRegion: null,
    );
    if (window != null && !window.isCameraSource) {
      if (window.isDesktopScreen) {
        unawaited(_activeWindowSource.capturePreviewOnly());
      } else {
        unawaited(_activeWindowSource.triggerSingleScan());
      }
    }
  }

  void _updateScanInterval(int intervalMs) {
    final clamped = ScannerSettings.clampScanIntervalMs(intervalMs);
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(scanIntervalMs: clamped),
    );
    setState(() {});
  }

  void _updatePreprocessProfile(OcrPreprocessProfile profile) {
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(preprocessProfile: profile),
    );
    setState(() {});
  }

  Future<void> _correctEventAt(
    int index, {
    required int newPokemonId,
    required String newPokemonName,
    bool? isShiny,
    bool? isAlpha,
  }) async {
    if (index < 0 || index >= _events.length) return;
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final targetDex = _getActiveDex(dexProvider);

    await DesktopTrackerDexController.correctEventAt(
      events: _events,
      index: index,
      newPokemonId: newPokemonId,
      newPokemonName: newPokemonName,
      dexProvider: dexProvider,
      targetDex: targetDex,
      autoMarkCaught: widget.coordinator.settings.autoMarkCaught,
      isShiny: isShiny,
      isAlpha: isAlpha,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteEventAt(int index) async {
    if (index < 0 || index >= _events.length) return;
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final targetDex = _getActiveDex(dexProvider);

    await DesktopTrackerDexController.deleteEventAt(
      events: _events,
      index: index,
      dexProvider: dexProvider,
      targetDex: targetDex,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openEventCorrectionDialog(int index) async {
    if (index < 0 || index >= _events.length) return;
    final ev = _events[index];
    await DesktopTrackerDialogs.showEventCorrection(
      context,
      event: ev,
      matcher: widget.coordinator.matcher,
      onCorrect: ({
        required newPokemonId,
        required newPokemonName,
        required isShiny,
        required isAlpha,
      }) async {
        final liveIndex = _events.indexOf(ev);
        if (liveIndex < 0) return;
        await _correctEventAt(
          liveIndex,
          newPokemonId: newPokemonId,
          newPokemonName: newPokemonName,
          isShiny: isShiny,
          isAlpha: isAlpha,
        );
      },
      onDelete: () async {
        final liveIndex = _events.indexOf(ev);
        if (liveIndex < 0) return;
        await _deleteEventAt(liveIndex);
      },
      onIgnoreTeam: (id, name) => _ignoreTeamPokemon(id, displayName: name),
    );
  }

  void _onScanRegionChanged(ScanRegionPreset preset) {
    setState(() {
      _scanRegion = preset;
      _applyScanRegion(_selectedWindow);
    });
    if (_shouldAutoScan(_selectedWindow, _customScreenRegion)) {
      unawaited(_activeWindowSource.triggerSingleScan());
    }
  }

  Future<void> _toggleFloatingHud() async {
    final next = !_showFloatingHud;
    setState(() => _showFloatingHud = next);
    DesktopTrackerService.instance.updateHudTarget(
      window: _selectedWindow,
      screenRegion: _customScreenRegion,
      snippetPreview: _snippetPreviewBytes,
    );
    DesktopTrackerService.instance.updateHudPresentation(
      isCompact: _hudCompact,
      isPinned: _hudPinned,
      opacity: _hudOpacity,
    );
    await DesktopTrackerService.instance.setFloatingHudVisible(next);
  }

  Future<void> _handleStartSnipping() async {
    if (_isCameraSourceSelected) {
      setState(() => _isEditingCameraRegions = !_isEditingCameraRegions);
      return;
    }
    if (_isLaunchingSnipping) return;

    final bridge = _effectiveNativeBridge;
    final launcher = widget.desktopSnippingLauncher ??
        (bridge != null
            ? () => bridge.startDesktopSnipping(hideAppWindow: false)
            : null);

    if (launcher == null) {
      setState(() {
        _isSnippingForFocusZone = false;
        _isSnippingMode = true;
      });
      return;
    }

    _isLaunchingSnipping = true;
    try {
      final result = await launcher();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _customScreenRegion = result.region;
          _snippetPreviewBytes = result.previewBytes;
          _activeWindowSource.setScreenRegion(result.region);
          _isScanningActive = true;
          _hasUserToggledScan = false;
        });
        widget.coordinator.start();
        DesktopTrackerService.instance.isPaused = false;
        DesktopTrackerService.instance.updateHudTarget(
          window: _selectedWindow,
          screenRegion: result.region,
          snippetPreview: result.previewBytes,
        );
        _syncOverlayBorders();
        unawaited(_activeWindowSource.triggerSingleScan());
      }
    } finally {
      _isLaunchingSnipping = false;
    }
  }

  void _toggleScanning() {
    setState(() {
      _hasUserToggledScan = true;
      _isScanningActive = !_isScanningActive;
      DesktopTrackerService.instance.isPaused = !_isScanningActive;
      if (_isScanningActive) {
        widget.coordinator.start();
        unawaited(_webcamController.cameraFramePump?.resume());
      } else {
        widget.coordinator.stop();
        unawaited(_webcamController.cameraFramePump?.pause());
      }
    });
    _syncOverlayBorders();
  }

  Future<void> _triggerManualScan() async {
    final win = _selectedWindow;
    if (win == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kein Zielfenster oder Desktop ausgewählt.'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (win.isCameraSource) {
      await _ensureCameraSource().triggerSingleScan();
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanne "${win.title}"...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _activeWindowSource.triggerSingleScan();
  }

  Future<void> _handleSystemDesktopSnipping() async {
    final success = await _snippingService.triggerWindowsScreenclip();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Windows-Snipping aktiv (Win+Shift+S): Ziehe den Bereich über deinen Desktop/Emulator!',
          ),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final frame = await _snippingService.captureDesktopSnippet();
    if (!mounted) return;
    if (frame != null) {
      await _activeWindowSource.processSnippet(frame);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Desktop-Ausschnitt (${frame.width}x${frame.height} px) übernommen!',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handlePasteFromClipboard() async {
    final frame = await _snippingService.captureDesktopSnippet();
    if (!mounted) return;

    if (frame != null) {
      await _activeWindowSource.processSnippet(frame);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Screenshot (${frame.width}x${frame.height} px) aus Zwischenablage übernommen!',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kein Bild in der Windows-Zwischenablage. Nutze Win+Shift+S zum Ausschneiden.',
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markPokemonCaughtInDex(
    int pokemonId, {
    bool isShiny = false,
    bool isAlpha = false,
    bool silent = false,
  }) async {
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final targetDex = _getActiveDex(dexProvider);
    if (targetDex == null) return;

    await DesktopTrackerDexController.persistCaughtStatus(
      dexProvider,
      targetDex,
      pokemonId,
      isShiny: isShiny,
      isAlpha: isAlpha,
    );

    if (mounted) {
      setState(() {});
      _refreshEvolutionStatusFor(
        _events.isNotEmpty ? _events.first : null,
        targetDex,
        dexProvider,
      );
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('In "${targetDex.title}" eingetragen!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  UserDex? _getActiveDex(DexProvider dexProvider) {
    final resolved =
        DesktopTrackerDexController.resolveTargetDex(dexProvider, _selectedDexId);
    if (resolved != null) {
      _selectedDexId ??= resolved.id;
    }
    return resolved;
  }

  void _openTargetDexModal(DexProvider dexProvider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DexSelectionModal(
        userDexes: dexProvider.userDexes,
        selectedDexId: _selectedDexId,
        onDexSelected: (dex) {
          setState(() {
            _selectedDexId = dex.id;
          });
          DesktopTrackerService.instance.setActiveDexId(dex.id);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _openAlertSettingsDialog() {
    DesktopTrackerDialogs.showAlertSettings(
      context,
      alertService: _alertService,
    );
  }

  void _openSettingsModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => TrackerSettingsDialog(
        currentPreset: _scanRegion,
        settings: widget.coordinator.settings,
        onPresetChanged: _onScanRegionChanged,
        onSettingsChanged: (newSettings) {
          _updateSettingsAndPersist(newSettings);
          setState(() {});
        },
      ),
    );
  }

  void _selectPresetMode(ScanRegionPreset preset) {
    setState(() {
      _customScreenRegion = null;
      _snippetPreviewBytes = null;
      _scanRegion = preset;
      if (_isCameraSourceSelected) {
        _webcamController.cameraScanMode = MobileCameraScanMode.autoFull;
        _isEditingCameraRegions = false;
        _ensureCameraSource()
          ..setScanMode(MobileCameraScanMode.autoFull)
          ..setAutoPreset(preset);
      } else {
        _activeWindowSource.setScreenRegion(null);
        _applyScanRegion(_selectedWindow);
      }
      _hasUserToggledScan = false;
      _syncAutoScanState(force: true);
    });
    _syncOverlayBorders();
    DesktopTrackerService.instance.updateHudTarget(
      window: _selectedWindow,
      screenRegion: null,
    );
    if (_shouldAutoScan(_selectedWindow, null)) {
      if (_isCameraSourceSelected) {
        unawaited(_ensureCameraSource().triggerSingleScan());
      } else {
        unawaited(_activeWindowSource.triggerSingleScan());
      }
    }
  }

  Future<void> _openCustomPatternsDialog() async {
    final liveFrame =
        _activeWindowSource.liveScanStatusNotifier.value.latestFrame;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => CustomPatternStudioDialog(
        initialPatterns: widget.coordinator.settings.customPatterns,
        matcher: widget.coordinator.matcher,
        initialProfile: widget.coordinator.settings.preprocessProfile,
        latestLiveFrame: liveFrame,
        sandboxImagePicker: widget.sandboxImagePicker,
        onPatternsChanged: (next) {
          _updateSettingsAndPersist(
            widget.coordinator.settings.copyWith(customPatterns: next),
          );
          if (mounted) setState(() {});
        },
        onRunPhotoOcr: (frame, profile) async {
          final driver = _activeWindowSource.ocrDriver;
          if (driver is WindowsDesktopOcrDriver) {
            return driver.recognizeTextDetailed(
              frame,
              profileOverride: profile,
            );
          }
          final lines = await driver.recognizeText(frame);
          return OcrRecognitionResult(lines: lines, ocrSucceeded: true);
        },
      ),
    );
  }

  void _switchWebcam() {
    final camEntries =
        _windows.where((w) => w.isCameraSource && w.cameraIndex >= 0).toList();
    if (camEntries.length < 2) return;
    final curIdx = camEntries.indexOf(_selectedWindow ?? camEntries.first);
    final next = camEntries[(curIdx + 1) % camEntries.length];
    _onWindowSelected(next);
  }

  Future<void> _importPhotoForWebcam() async {
    await _webcamController.importPhotoForWebcam(
      ocrLanguageTag: _ocrLanguageTag,
      scanRegion: _scanRegion,
      isMounted: () => mounted,
      beforeProcess: (_) => _bindSourceForSelection(_selectedWindow),
    );
  }

  void _onSelfWindowOverlapChanged() {
    if (!mounted) return;
    if (!_activeWindowSource.selfWindowOverlapNotifier.value) return;
    final current = widget.coordinator.settings;
    if (current.maskSelfWindow ||
        current.suppressSelfScanWarning ||
        _hasShownSelfScanDialogThisSession) {
      return;
    }
    _hasShownSelfScanDialogThisSession = true;
    Future<void>.microtask(() async {
      if (!mounted) return;
      final res = await DesktopTrackerDialogs.showSelfScanOverlapDialog(context);
      if (!mounted || res == null) return;
      final next = widget.coordinator.settings.copyWith(
        maskSelfWindow: res.maskSelfWindow,
        suppressSelfScanWarning:
            res.suppressWarning ||
            widget.coordinator.settings.suppressSelfScanWarning,
      );
      _updateSettingsAndPersist(next);
      if (mounted) setState(() {});
    });
  }

  Future<void> _openEnlargedPreview({
    required CapturedFrame? liveFrame,
    required Uint8List? fallbackPng,
    required String title,
    ValueListenable<LiveOcrScanStatus>? statusListenable,
    ValueListenable<CapturedFrame?>? frameListenable,
    ValueListenable<Map<String, CapturedFrame>>? boxFramesListenable,
    ValueListenable<Map<String, String>>? boxPreviewsListenable,
    String? boxKey,
  }) async {
    _activeWindowSource.setPreviewPolicy(enabled: true, maxWidth: 960);
    try {
      await DesktopTrackerDialogs.showEnlargedPreview(
        context,
        liveFrame: liveFrame,
        fallbackPng: fallbackPng,
        title: title,
        statusListenable: statusListenable,
        frameListenable: frameListenable,
        boxFramesListenable: boxFramesListenable,
        boxPreviewsListenable: boxPreviewsListenable,
        boxKey: boxKey,
      );
    } finally {
      if (mounted) {
        _activeWindowSource.setPreviewPolicy(enabled: true, maxWidth: 320);
      }
    }
  }

  Widget _buildScanRegionSection(bool isDark) {
    return DesktopScanRegionSection(
      bordersToggleKey: _tutorialController.bordersToggleKey,
      zoneASectionKey: _tutorialController.zoneASectionKey,
      zoneBSectionKey: _tutorialController.zoneBSectionKey,
      multiSectionKey: _tutorialController.multiSectionKey,
      showOverlayControls: _showOverlayControls,
      isDark: isDark,
      settings: widget.coordinator.settings,
      customScreenRegion: _customScreenRegion,
      snippetPreviewBytes: _snippetPreviewBytes,
      scanRegion: _scanRegion,
      selectedWindow: _selectedWindow,
      isScanningActive: _isScanningActive,
      showZoneAInfo: _showZoneAInfo,
      windowSource: _activeWindowSource,
      liveFocusZoneBar: DesktopLiveFocusZoneBar(
        settings: widget.coordinator.settings,
        windowSource: _activeWindowSource,
        focusSnippetPreviewBytes: _focusSnippetPreviewBytes,
        showZoneBInfo: _showZoneBInfo,
        isDark: isDark,
        isScanningActive: _isScanningActive,
        selectedWindow: _selectedWindow,
        onShowEnlargedPreview: _openEnlargedPreview,
        onToggleInfo: () => setState(() => _showZoneBInfo = !_showZoneBInfo),
        onSelectPreset: _selectLiveFocusPreset,
        onStartSnipping: _handleStartLiveFocusSnipping,
        onAddExtraFocusBox: _handleStartExtraFocusBoxSnipping,
        onRemoveExtraFocusBox: _removeExtraFocusRegion,
        onUnignorePokemon: _unignoreTeamPokemon,
      ),
      multiInstanceCard: DesktopMultiInstanceCard(
        slots: widget.coordinator.settings.multiInstanceSlots,
        windows: _windows,
        isDark: isDark,
        onAddSlot: _addMultiInstanceSlot,
        onClearSlots: _clearMultiInstanceSlots,
        onRemoveSlot: _removeMultiInstanceSlot,
        onUpdateSlot: _updateMultiSlot,
        onStartSnipping: _startMultiSlotSnipping,
      ),
      refreshRateAndPatternsBar: DesktopRefreshRateAndPatternsBar(
        settings: widget.coordinator.settings,
        showScanProfileInfo: _showScanProfileInfo,
        isDark: isDark,
        onToggleInfo: () =>
            setState(() => _showScanProfileInfo = !_showScanProfileInfo),
        onUpdatePreprocessProfile: _updatePreprocessProfile,
        onUpdateScanInterval: _updateScanInterval,
        onOpenCustomPatterns: _openCustomPatternsDialog,
        onUpdateOcrLanguage: (lang) {
          _updateSettingsAndPersist(
            widget.coordinator.settings.copyWith(ocrLanguage: lang),
          );
          if (mounted) setState(() {});
        },
        effectiveLanguageTag: _ocrLanguageTag,
      ),
      onToggleScreenBorders: _toggleScreenBorders,
      onToggleZoneAInfo: () =>
          setState(() => _showZoneAInfo = !_showZoneAInfo),
      onSelectPresetMode: _selectPresetMode,
      onStartSnipping: _handleStartSnipping,
      onShowEnlargedPreview: _openEnlargedPreview,
    );
  }

  Widget _buildRightColumn(
    UserDex? activeDex,
    bool isDark, {
    required bool isWide,
  }) {
    final feedCard = DesktopEventFeedCard(
      tutorialKey: _tutorialController.eventFeedKey,
      events: _events,
      activeDex: activeDex,
      isDark: isDark,
      onClearEvents: () => setState(() => _events.clear()),
      onEditEvent: _openEventCorrectionDialog,
      onMarkCaught: (id, {required isShiny, required isAlpha}) =>
          _markPokemonCaughtInDex(id, isShiny: isShiny, isAlpha: isAlpha),
    );
    if (!_isCameraSourceSelected) {
      return isWide ? feedCard : SizedBox(height: 360, child: feedCard);
    }

    final selectedCamTitle = _selectedWindow?.title ?? '📷 Webcam / Foto-Scan';
    final liveCamCount =
        _windows.where((w) => w.isCameraSource && w.cameraIndex >= 0).length;
    final webcamStage = DesktopWebcamStage(
      cameraTitle: selectedCamTitle,
      cameraController: _webcamController.cameraController,
      isInitializing: _webcamController.isInitializingCamera,
      errorText: _webcamController.cameraErrorText,
      isPermissionDenied: _webcamController.isCameraPermissionDenied,
      isTrackingActive: _isScanningActive,
      hasMultipleCameras: liveCamCount > 1,
      isEditingRegions: _isEditingCameraRegions,
      scanMode: _webcamController.cameraScanMode,
      autoPreset: _scanRegion,
      regions: _webcamController.cameraRegions,
      activeBrushRole: CameraZoneRole.scan,
      webOcrStatusListenable: _webcamController.webOcrStatusListenable,
      onRegionsChanged: (nextRegions) {
        setState(() {
          _webcamController.cameraRegions = nextRegions;
          _webcamController.cameraScanMode = MobileCameraScanMode.customRegions;
        });
        _ensureCameraSource()
          ..setScanMode(MobileCameraScanMode.customRegions)
          ..setRegions(nextRegions);
      },
      onToggleEditRegions: () {
        setState(() => _isEditingCameraRegions = !_isEditingCameraRegions);
      },
      onImportPhoto: _importPhotoForWebcam,
      onSwitchCamera: liveCamCount > 1 ? _switchWebcam : null,
      onRetryCamera: () =>
          unawaited(_syncCameraHardwareForSelection(_selectedWindow)),
    );

    if (isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          webcamStage,
          const SizedBox(height: 12),
          Expanded(child: feedCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        webcamStage,
        const SizedBox(height: 12),
        SizedBox(height: 360, child: feedCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dexProvider = Provider.of<DexProvider>(context);
    final activeDex = _getActiveDex(dexProvider);
    final latestEvent = _events.isNotEmpty ? _events.first : null;

    final validSelectedWindow = _windows.any((w) => w == _selectedWindow)
        ? _windows.firstWhere((w) => w == _selectedWindow)
        : (_windows.any((w) => w.id == _selectedWindow?.id)
            ? _windows.firstWhere((w) => w.id == _selectedWindow?.id)
            : (_windows.isNotEmpty ? _windows.first : null));

    final windowControlCard = DesktopWindowControlCard(
      sourceTutorialKey: _tutorialController.sourceSectionKey,
      targetDexTutorialKey: _tutorialController.targetDexSectionKey,
      windows: _windows,
      validSelectedWindow: validSelectedWindow,
      customScreenRegion: _customScreenRegion,
      isRefreshingWindows: _isRefreshingWindows,
      showOverlayControls: _showOverlayControls,
      showFloatingHud: _showFloatingHud,
      isScanningActive: _isScanningActive,
      activeDex: activeDex,
      dexProvider: dexProvider,
      isDark: isDark,
      scanRegionSection: _buildScanRegionSection(isDark),
      onRefreshWindows: _refreshWindows,
      onExitCustomRegion: () => _selectPresetMode(_scanRegion),
      onWindowSelected: _onWindowSelected,
      onChangeDex: () => _openTargetDexModal(dexProvider),
      onToggleFloatingHud: _toggleFloatingHud,
      onTriggerManualScan: _triggerManualScan,
      onToggleScanning: _toggleScanning,
    );

    final targetFocusCard = DesktopTargetFocusCard(
      latestEvent: latestEvent,
      activeFocusEvents: _activeFocusEvents,
      activeEvolutionStatus: _dexController.activeEvolutionStatus,
      activeDex: activeDex,
      isDark: isDark,
      onMarkCaught: (id, {required isShiny, required isAlpha}) =>
          _markPokemonCaughtInDex(id, isShiny: isShiny, isAlpha: isAlpha),
      onSelectAlternative: ({required pokemonId, required pokemonName}) =>
          _correctEventAt(
        0,
        newPokemonId: pokemonId,
        newPokemonName: pokemonName,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _showOverlayControls
                        ? 'Desktop Tracker & Overlay'
                        : 'Webcam Tracker',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (constraints.maxWidth > 220) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isScanningActive
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isScanningActive
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _isScanningActive ? Colors.green : Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isScanningActive ? 'OCR Aktiv' : 'Pausiert',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                _isScanningActive ? Colors.green : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (constraints.maxWidth > 360) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: t.scanner_settings_ocr_lang_title,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openSettingsModal,
                      child: Container(
                        key: const Key('badge_ocr_language'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _ocrUsedFallbackLanguage &&
                                  _ocrFallbackResolvedTag != null
                              ? 'OCR: $_ocrLanguageTag (Fallback: $_ocrFallbackResolvedTag)'
                              : 'OCR: $_ocrLanguageTag',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          if (_showOverlayControls)
            KeyedSubtree(
              key: _tutorialController.hudKey,
              child: IconButton(
                key: const Key('btn_open_floating_hud'),
                icon: Icon(
                  _showFloatingHud
                      ? Icons.picture_in_picture
                      : Icons.picture_in_picture_alt,
                  color: _showFloatingHud ? const Color(0xFFEF5350) : null,
                ),
                tooltip: _showFloatingHud
                    ? 'Floating HUD schließen'
                    : 'Floating HUD öffnen',
                onPressed: _toggleFloatingHud,
              ),
            ),
          IconButton(
            key: const Key('btn_alert_settings'),
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Alarm- & Töne-Einstellungen',
            onPressed: _openAlertSettingsDialog,
          ),
          IconButton(
            key: const Key('btn_refresh_windows_appbar'),
            icon: _isRefreshingWindows
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Fenster aktualisieren',
            onPressed: _refreshWindows,
          ),
          IconButton(
            key: const Key('btn_tracker_settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: _openSettingsModal,
          ),
          IconButton(
            key: const Key('btn_desktop_scanner_help'),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Scanner-Tutorial',
            onPressed: () => _tutorialController.start(
              context: context,
              isMounted: mounted,
              showOverlayControls: _showOverlayControls,
              force: true,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 820;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 380,
                            child: RepaintBoundary(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    windowControlCard,
                                    const SizedBox(height: 14),
                                    targetFocusCard,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildRightColumn(
                              activeDex,
                              isDark,
                              isWide: true,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            windowControlCard,
                            const SizedBox(height: 14),
                            targetFocusCard,
                            const SizedBox(height: 14),
                            _buildRightColumn(
                              activeDex,
                              isDark,
                              isWide: false,
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
          if (_showFloatingHud && _effectiveNativeBridge == null)
            ValueListenableBuilder<Offset>(
              key: const Key('hud_position_listener'),
              valueListenable: _hudPositionNotifier,
              builder: (context, hudPos, child) => Positioned(
                left: hudPos.dx,
                top: hudPos.dy,
                child: child!,
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  _hudPositionNotifier.value += details.delta;
                },
                child: FloatingOverlayHud(
                  latestEvent: latestEvent,
                  focusEvents: _activeFocusEvents,
                  activeDex: activeDex,
                  isCompact: _hudCompact,
                  initialOpacity: _hudOpacity,
                  isPinned: _hudPinned,
                  evolutionSummary:
                      _dexController.activeEvolutionStatus?.hudShortLabel,
                  hasMissingEvolutions: _dexController
                          .activeEvolutionStatus?.hasMissingEvolutions ??
                      false,
                  onClose: () => setState(() => _showFloatingHud = false),
                  onCompactChanged: (c) => setState(() => _hudCompact = c),
                  onPinnedChanged: (p) => setState(() => _hudPinned = p),
                  onOpacityChanged: (o) => setState(() => _hudOpacity = o),
                  onMarkCaught: () {
                    if (latestEvent?.pokemonId != null) {
                      _markPokemonCaughtInDex(
                        latestEvent!.pokemonId!,
                        isShiny: latestEvent.isShiny,
                        isAlpha: latestEvent.isAlpha,
                      );
                    }
                  },
                  onMarkEventCaught: (ev) {
                    if (ev.pokemonId != null) {
                      _markPokemonCaughtInDex(
                        ev.pokemonId!,
                        isShiny: ev.isShiny,
                        isAlpha: ev.isAlpha,
                      );
                    }
                  },
                ),
              ),
            ),
          if (_isSnippingMode)
            Positioned.fill(
              child: ScreenSnippingOverlay(
                targetWindow: _selectedWindow,
                desktopBackgroundBytes: switch (
                    _activeWindowSource.latestSnippetFrame?.bytes) {
                  final Uint8List bytes => bytes,
                  final List<int> list => Uint8List.fromList(list),
                  null => null,
                },
                onTriggerWindowsSnipping: _handleSystemDesktopSnipping,
                onPasteFromClipboard: _handlePasteFromClipboard,
                onRegionSelected: (region) {
                  if (_snippingMultiSlotId != null) {
                    _applyMultiSlotRegion(
                      _snippingMultiSlotId!,
                      region,
                      isFocus: _snippingMultiIsFocus,
                    );
                    return;
                  }
                  if (_isSnippingForExtraFocusBox) {
                    _appendExtraFocusRegion(region);
                    return;
                  }
                  if (_isSnippingForFocusZone) {
                    setState(() {
                      _isSnippingForFocusZone = false;
                      _isSnippingMode = false;
                      _focusSnippetPreviewBytes = null;
                      _activeWindowSource.setLiveFocusScreenRegion(region);
                      _isScanningActive = true;
                      _hasUserToggledScan = false;
                    });
                    _updateSettingsAndPersist(
                      widget.coordinator.settings.copyWith(
                        liveFocusPreset: LiveFocusPreset.customRegion,
                      ),
                    );
                    widget.coordinator.start();
                    DesktopTrackerService.instance.isPaused = false;
                    unawaited(_activeWindowSource.triggerSingleScan());
                    return;
                  }
                  setState(() {
                    _customScreenRegion = region;
                    _isSnippingMode = false;
                    _activeWindowSource.setScreenRegion(region);
                    _isScanningActive = true;
                    _hasUserToggledScan = false;
                  });
                  widget.coordinator.start();
                  DesktopTrackerService.instance.isPaused = false;
                  DesktopTrackerService.instance.updateHudTarget(
                    window: _selectedWindow,
                    screenRegion: region,
                  );
                  _syncOverlayBorders();
                  unawaited(_activeWindowSource.triggerSingleScan());
                },
                onCancel: () {
                  setState(() {
                    _snippingMultiSlotId = null;
                    _snippingMultiIsFocus = false;
                    _isSnippingForFocusZone = false;
                    _isSnippingForExtraFocusBox = false;
                    _isSnippingMode = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
