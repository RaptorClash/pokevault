import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../main.dart' show appNavigatorKey;
import '../../models/pokemon.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/camera_ocr/platform_camera_ocr_driver.dart';
import '../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../services/desktop_tracker/tracker_alert_service.dart';
import '../../services/desktop_tracker/windows_desktop_bridge.dart';
import '../../services/mobile_scanner/camera_image_converter.dart';
import '../../services/mobile_scanner/camera_scan_region.dart';
import '../../services/mobile_scanner/mobile_camera_source.dart';
import '../../services/mobile_scanner/mobile_camera_tracker_service.dart';
import '../../services/scanner_core/models/scanner_event.dart';
import '../../services/scanner_core/models/scanner_settings.dart';
import '../../services/scanner_core/scanner_coordinator.dart';
import '../../services/scanner_core/scanner_persistence_service.dart';
import '../../utils/dex_logic_helper.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../desktop_tracker/controllers/desktop_tracker_dex_controller.dart';
import '../desktop_tracker/widgets/custom_pattern_studio_dialog.dart';
import '../desktop_tracker/widgets/dex_selection_modal.dart';
import 'controllers/mobile_camera_hardware_controller.dart';
import 'controllers/mobile_scanner_tutorial_controller.dart';
import 'widgets/mobile_camera_viewport.dart';
import 'widgets/mobile_scanner_bottom_panel.dart';
import 'widgets/mobile_scanner_dialogs.dart';
import 'widgets/mobile_tracker_tabs.dart';

/// Feature-complete Mobile Camera Tracker screen supporting Auto full-frame OCR,
/// freely drawn/resizable rectangle zones, Fullscreen/Split-Screen/PiP modes,
/// hardware camera controls, photo import, and direct Pokédex/evolution tracking.
class MobileCameraTrackerScreen extends StatefulWidget {
  final ScannerCoordinator coordinator;
  final MobileCameraSource? cameraSource;
  final String? initialDexId;
  final bool disableHardwareCamera;
  final bool simulatePermissionDenied;
  final Future<CapturedFrame?> Function()? photoFramePicker;
  final bool initialSplitView;
  final List<CameraDescription>? availableCamerasOverride;

  const MobileCameraTrackerScreen({
    super.key,
    required this.coordinator,
    this.cameraSource,
    this.initialDexId,
    this.disableHardwareCamera = false,
    this.simulatePermissionDenied = false,
    this.photoFramePicker,
    this.initialSplitView = false,
    this.availableCamerasOverride,
  });

  @override
  State<MobileCameraTrackerScreen> createState() =>
      _MobileCameraTrackerScreenState();
}

class _MobileCameraTrackerScreenState extends State<MobileCameraTrackerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const String _regionsPrefsKey = 'pokevault_mobile_camera_regions_v1';
  static const String _scanModePrefsKey =
      'pokevault_mobile_camera_scan_mode_v1';
  static const String _multiSlotsPrefsKey = 'pokevault_mobile_multi_slots_v1';

  final GlobalKey _tutModesKey = GlobalKey();
  final GlobalKey _tutPhotoKey = GlobalKey();
  final GlobalKey _tutPipKey = GlobalKey();
  final GlobalKey _tutViewportKey = GlobalKey();
  final GlobalKey _tutBottomPanelKey = GlobalKey();

  late final MobileCameraSource _cameraSource;
  late final bool _ownsCameraSource;
  final MobileCameraTrackerService _trackerService =
      MobileCameraTrackerService.instance;
  final ScannerPersistenceService _persistenceService =
      ScannerPersistenceService();
  late final TrackerAlertService _alertService;
  late final TabController _splitTabController;
  late final MobileCameraHardwareController _hardwareController;
  late final MobileScannerTutorialController _tutorialController;

  StreamSubscription<ScannerEvent>? _eventSub;
  StreamSubscription<List<ScannerEvent>>? _focusSub;

  MobileScannerViewMode _viewMode = MobileScannerViewMode.fullscreen;
  MobileCameraScanMode _scanMode = MobileCameraScanMode.autoFull;
  ScanRegionPreset _autoPreset = ScanRegionPreset.fullWindow;
  CameraBrushTarget _activeBrushTarget = CameraBrushTarget.zoneA();
  bool _isEditingRegions = true;
  List<NormalizedScanRect> _regions = const [];
  List<int> _multiSlotIds = [];

  String? _selectedDexId;
  bool _isScanningActive = true;
  bool _handedOffToPip = false;
  bool _isDrawerExpanded = false;

  final List<ScannerEvent> _events = [];
  List<ScannerEvent> _activeFocusEvents = const [];
  final Map<int, ScannerEvent> _focusByInstance = {};
  final DesktopTrackerDexController _dexController =
      DesktopTrackerDexController();

  List<int> get _effectiveMultiSlotIds {
    final merged = {..._multiSlotIds, ..._regions.multiSlotIds}.toList()
      ..sort();
    return merged;
  }

  List<ScannerEvent> get _combinedFocusEvents {
    if (_focusByInstance.length > 1) {
      final sortedKeys = _focusByInstance.keys.toList()..sort();
      return sortedKeys.map((k) => _focusByInstance[k]!).toList(growable: false);
    }
    return _activeFocusEvents;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _splitTabController = TabController(length: 3, vsync: this);
    _selectedDexId = widget.initialDexId ?? _trackerService.activeDexId;
    if (widget.initialSplitView) {
      _viewMode = MobileScannerViewMode.split;
    }

    _alertService = TrackerAlertService(
      soundPlayer: (_) {
        if (_alertService.settings.hapticEnabled) {
          unawaited(HapticFeedback.mediumImpact());
        }
      },
      visualAlertHandler: (_) {},
    );

    if (widget.cameraSource != null) {
      _cameraSource = widget.cameraSource!;
      _ownsCameraSource = false;
    } else {
      _cameraSource = MobileCameraSource(
        ocrDriver: createPlatformCameraOcrDriver(
          initialPreprocessProfile: widget.coordinator.settings.preprocessProfile,
        ),
        preprocessProfile: widget.coordinator.settings.preprocessProfile,
      );
      _ownsCameraSource = true;
    }

    _hardwareController = MobileCameraHardwareController(
      trackerService: _trackerService,
      cameraSource: _cameraSource,
      getScanIntervalMs: () => widget.coordinator.settings.scanIntervalMs,
      isScanningActive: () => _isScanningActive,
      disableHardwareCamera: widget.disableHardwareCamera,
      simulatePermissionDenied: widget.simulatePermissionDenied,
      availableCamerasOverride: widget.availableCamerasOverride,
    );
    _hardwareController.tryReattachExisting();

    _tutorialController = MobileScannerTutorialController(
      viewportKey: _tutViewportKey,
      modesKey: _tutModesKey,
      photoKey: _tutPhotoKey,
      pipKey: _tutPipKey,
      bottomPanelKey: _tutBottomPanelKey,
    );

    _scanMode = _cameraSource.scanMode;
    _autoPreset = _cameraSource.autoPreset;
    _regions = _cameraSource.regions;
    _multiSlotIds = List<int>.from(_regions.multiSlotIds);

    widget.coordinator.bindSource(_cameraSource);
    widget.coordinator.start();

    _trackerService.startSession(
      coordinator: widget.coordinator,
      cameraSource: _cameraSource,
      dexId: _selectedDexId,
      pipCameraPreviewBuilder: _buildPipPreviewWidget,
      onExpandFromPip: _reopenFromPip,
      onToggleTorch: _hardwareController.toggleTorch,
      ownsCameraSource: _ownsCameraSource,
    );
    _trackerService.attachPipCallbacks(
      onDisposeCamera: _hardwareController.disposeHardwareCamera,
      onDisableWakelock: _disableWakelock,
    );
    if (_trackerService.viewMode == MobileScannerViewMode.pip) {
      _trackerService.exitPipMode(targetMode: _viewMode);
    }

    _eventSub = widget.coordinator.events.listen(_onScannerEvent);
    _focusSub = widget.coordinator.activeFocusStream.listen((focusGroup) {
      if (!mounted) return;
      setState(() {
        _activeFocusEvents = focusGroup;
        if (focusGroup.isEmpty) {
          _focusByInstance.clear();
        } else {
          for (final ev in focusGroup) {
            _focusByInstance[ev.instanceIndex ?? 1] = ev;
          }
        }
      });
      if (focusGroup.isNotEmpty) {
        _refreshEvolutionFor(focusGroup.first);
      }
    });

    unawaited(_enableWakelock());
    unawaited(_loadPersistedState());
    if (!widget.disableHardwareCamera &&
        !widget.simulatePermissionDenied &&
        _hardwareController.controller == null) {
      unawaited(_hardwareController.initHardwareCamera());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tutorialController.maybeShowIfNeeded(
          context,
          getViewMode: () => _viewMode,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_handedOffToPip) return;
    _hardwareController.handleAppLifecycleChange(state);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncOcrLanguageTag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TutorialOverlay.resetShowing();
    _splitTabController.dispose();
    _eventSub?.cancel();
    _focusSub?.cancel();

    if (!_handedOffToPip) {
      unawaited(_disableWakelock());
      unawaited(_hardwareController.disposeHardwareCamera());
      unawaited(_trackerService.stopSession());
    }
    _hardwareController.dispose();
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final regionsRaw = prefs.getString(_regionsPrefsKey);
      if (regionsRaw != null && regionsRaw.isNotEmpty && mounted) {
        final decoded = jsonDecode(regionsRaw);
        if (decoded is List) {
          final parsed = decoded
              .whereType<Map>()
              .map(
                (m) => NormalizedScanRect.fromMap(Map<String, dynamic>.from(m)),
              )
              .toList(growable: false);
          if (parsed.isNotEmpty && _regions.isEmpty) {
            setState(() => _regions = parsed);
            _trackerService.setRegions(parsed);
          }
        }
      }
      final savedMode = prefs.getString(_scanModePrefsKey);
      if (savedMode != null && mounted && _cameraSource.regions.isEmpty) {
        final mode = MobileCameraScanMode.values
            .where((m) => m.name == savedMode)
            .firstOrNull;
        if (mode != null) {
          setState(() => _scanMode = mode);
          _trackerService.setScanMode(mode);
        }
      }
      final savedSlotsRaw = prefs.getString(_multiSlotsPrefsKey);
      if (savedSlotsRaw != null && savedSlotsRaw.isNotEmpty && mounted) {
        final decodedSlots = jsonDecode(savedSlotsRaw);
        if (decodedSlots is List) {
          final slotInts = decodedSlots.whereType<int>().where((id) => id >= 2).toList()
            ..sort();
          if (slotInts.isNotEmpty && _multiSlotIds.isEmpty) {
            setState(() => _multiSlotIds = slotInts);
          }
        }
      }

      final current = widget.coordinator.settings;
      final savedSettings = await _persistenceService.loadScannerSettings(
        base: current,
      );
      if (!mounted) return;
      final merged = current.copyWith(
        scanIntervalMs: savedSettings.scanIntervalMs,
        autoMarkCaught: savedSettings.autoMarkCaught,
        ocrLanguage: savedSettings.ocrLanguage,
        customPatterns: savedSettings.customPatterns,
        ignoredPokemonIds: savedSettings.ignoredPokemonIds,
      );
      widget.coordinator.updateSettings(merged);
      _cameraSource.setPollInterval(
        Duration(milliseconds: merged.scanIntervalMs),
      );
      _syncOcrLanguageTag();
    } catch (_) {}
  }

  Future<void> _saveRegions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _regionsPrefsKey,
        jsonEncode(_regions.map((r) => r.toMap()).toList()),
      );
      await prefs.setString(_scanModePrefsKey, _scanMode.name);
      await prefs.setString(_multiSlotsPrefsKey, jsonEncode(_effectiveMultiSlotIds));
    } catch (_) {}
  }

  void _syncOcrLanguageTag() {
    String effectiveLang = widget.coordinator.settings.ocrLanguage;
    if (effectiveLang == 'auto') {
      try {
        effectiveLang = Provider.of<SettingsProvider>(context, listen: false)
            .effectivePokemonLanguage;
      } catch (_) {
        effectiveLang = 'de';
      }
    }
    final mapped = WindowsDesktopBridge.mapPokemonLanguageToBcp47(effectiveLang);
    if (_cameraSource.ocrLanguageTag != mapped) {
      _cameraSource.setOcrLanguageTag(mapped);
    }
  }

  void _onScannerEvent(ScannerEvent event) {
    if (!mounted) return;
    _alertService.handleEvent(event);

    final dexProv = Provider.of<DexProvider>(context, listen: false);
    final stored = DesktopTrackerDexController.prepareIncomingEvent(
      event,
      targetDex: _getActiveDex(dexProv),
      autoMarkCaught: widget.coordinator.settings.autoMarkCaught,
    );

    setState(() {
      _events.insert(0, stored);
      if (_events.length > 50) _events.removeLast();
    });

    _refreshEvolutionFor(stored);

    if (widget.coordinator.settings.autoMarkCaught &&
        stored.type == ScannerEventType.caught &&
        stored.pokemonId != null) {
      unawaited(
        _markPokemonCaughtInDex(
          stored.pokemonId!,
          isShiny: stored.isShiny,
          isAlpha: stored.isAlpha,
          silent: true,
        ),
      );
    }
  }

  void _refreshEvolutionFor(ScannerEvent? event) {
    if (!mounted) return;
    final dexProv = Provider.of<DexProvider>(context, listen: false);
    final activeDex = _getActiveDex(dexProv);
    String lang = 'de';
    try {
      lang = Provider.of<SettingsProvider>(context, listen: false)
          .effectivePokemonLanguage;
    } catch (_) {}

    _dexController.refreshEvolutionStatusFor(
      event: event,
      activeDex: activeDex,
      dexProvider: dexProv,
      languageCode: lang,
      isMounted: () => mounted,
      onStatusChanged: (_) {
        if (mounted) setState(() {});
      },
      onSyncServiceStatus: _trackerService.updateEvolutionStatus,
    );
  }

  UserDex? _getActiveDex(DexProvider dexProvider) {
    final resolved =
        DesktopTrackerDexController.resolveTargetDex(dexProvider, _selectedDexId);
    if (resolved != null) {
      _selectedDexId ??= resolved.id;
    }
    return resolved;
  }

  bool _isPokemonCaughtInActiveDex(int pokemonId) {
    if (!mounted) return false;
    try {
      final dexProv = Provider.of<DexProvider>(context, listen: false);
      final dex = _getActiveDex(dexProv);
      if (dex == null) return false;
      return DexLogicHelper.isPokemonCaught(dex, pokemonId.toString());
    } catch (_) {
      return false;
    }
  }

  Future<void> _markPokemonCaughtInDex(
    int pokemonId, {
    bool isShiny = false,
    bool isAlpha = false,
    bool silent = false,
  }) async {
    final dexProv = Provider.of<DexProvider>(context, listen: false);
    final targetDex = _getActiveDex(dexProv);
    if (targetDex == null) return;

    await DesktopTrackerDexController.persistCaughtStatus(
      dexProv,
      targetDex,
      pokemonId,
      isShiny: isShiny,
      isAlpha: isAlpha,
    );

    if (!mounted) return;
    setState(() {});
    _refreshEvolutionFor(_events.isNotEmpty ? _events.first : null);
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

  Future<void> _importAndScanPhoto() async {
    final frame = await CameraImageConverter.pickAndDecodePhotoFrame(
      overridePicker: widget.photoFramePicker,
    );
    if (frame == null || !mounted) return;
    await _cameraSource.processPhotoFrame(frame);
  }

  void _selectBrushTarget(CameraBrushTarget target) {
    setState(() {
      _activeBrushTarget = target;
      _scanMode = MobileCameraScanMode.customRegions;
      _isEditingRegions = true;
    });
    _trackerService.setScanMode(MobileCameraScanMode.customRegions);
    unawaited(_saveRegions());
  }

  void _addMultiSlot() {
    final nextSlot = _regions.nextMultiSlotId(_multiSlotIds);
    setState(() {
      _multiSlotIds = [..._effectiveMultiSlotIds, nextSlot]..sort();
      _activeBrushTarget = CameraBrushTarget.multiScan(nextSlot);
      _scanMode = MobileCameraScanMode.customRegions;
      _isEditingRegions = true;
    });
    _trackerService.setScanMode(MobileCameraScanMode.customRegions);
    unawaited(_saveRegions());
  }

  void _removeMultiSlot(int slotId) {
    final nextRegions =
        _regions.where((r) => r.slotId != slotId).toList(growable: false);
    setState(() {
      _multiSlotIds = _multiSlotIds.where((id) => id != slotId).toList();
      _focusByInstance.remove(slotId);
      if (_activeBrushTarget.slotId == slotId &&
          _activeBrushTarget.role == CameraZoneRole.multiInstance) {
        _activeBrushTarget = CameraBrushTarget.zoneA();
      }
      _regions = nextRegions;
    });
    _trackerService.setRegions(nextRegions);
    unawaited(_saveRegions());
  }

  void _toggleMultiSlotEnabled(int slotId) {
    final slotRegions = _regions.where((r) => r.slotId == slotId).toList();
    if (slotRegions.isEmpty) return;
    final enableNext = !slotRegions.every((r) => r.enabled);
    _updateRegions(
      _regions
          .map((r) => r.slotId == slotId ? r.copyWith(enabled: enableNext) : r)
          .toList(growable: false),
    );
  }

  void _setScanMode(MobileCameraScanMode mode) {
    setState(() => _scanMode = mode);
    _trackerService.setScanMode(mode);
    unawaited(_saveRegions());
  }

  void _updateRegions(List<NormalizedScanRect> next) {
    setState(() => _regions = next);
    _trackerService.setRegions(next);
    unawaited(_saveRegions());
  }

  void _toggleScanning() {
    setState(() {
      _isScanningActive = !_isScanningActive;
      if (_isScanningActive) {
        widget.coordinator.start();
        unawaited(_hardwareController.framePump?.resume());
      } else {
        widget.coordinator.stop();
        unawaited(_hardwareController.framePump?.pause());
      }
    });
    _trackerService.isPausedNotifier.value = !_isScanningActive;
  }

  void _minimizeToPip() {
    _handedOffToPip = true;
    _trackerService.attachPipCallbacks(
      pipCameraPreviewBuilder: _buildPipPreviewWidget,
      onExpandFromPip: _reopenFromPip,
      onToggleTorch: _hardwareController.toggleTorch,
      onDisposeCamera: _hardwareController.disposeHardwareCamera,
      onDisableWakelock: _disableWakelock,
    );
    _trackerService.enterPipMode();
    Navigator.of(context).pop();
  }

  void _reopenFromPip() {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => MobileCameraTrackerScreen(
          coordinator: widget.coordinator,
          cameraSource: _cameraSource,
          initialDexId: _selectedDexId,
          disableHardwareCamera: widget.disableHardwareCamera,
          simulatePermissionDenied: widget.simulatePermissionDenied,
          photoFramePicker: widget.photoFramePicker,
          availableCamerasOverride: widget.availableCamerasOverride,
        ),
      ),
    );
  }

  Widget _buildPipPreviewWidget(BuildContext context) {
    final ctrl = _hardwareController.controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      return CameraPreview(ctrl);
    }
    return Container(
      color: const Color(0xFF151822),
      child: const Center(
        child: Icon(Icons.photo_camera, color: Colors.white30, size: 26),
      ),
    );
  }

  void _openTargetDexModal(DexProvider dexProv) {
    showDialog(
      context: context,
      builder: (ctx) => DexSelectionModal(
        userDexes: dexProv.userDexes,
        selectedDexId: _selectedDexId,
        onDexSelected: (dex) {
          setState(() => _selectedDexId = dex.id);
          _trackerService.setActiveDexId(dex.id);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _openCustomPatternsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CustomPatternStudioDialog(
        initialPatterns: widget.coordinator.settings.customPatterns,
        matcher: widget.coordinator.matcher,
        initialProfile: widget.coordinator.settings.preprocessProfile,
        onPatternsChanged: (patterns) {
          final next = widget.coordinator.settings.copyWith(
            customPatterns: patterns,
          );
          widget.coordinator.updateSettings(next);
          unawaited(_persistenceService.saveScannerSettings(next));
          setState(() {});
        },
        onRunPhotoOcr: (frame, profile) async {
          final lines = await _cameraSource.ocrDriver.recognizeText(frame);
          return OcrRecognitionResult(
            lines: lines,
            resolvedLanguageTag: _cameraSource.ocrLanguageTag,
          );
        },
      ),
    );
  }

  Future<void> _openEventCorrectionDialog(int index) async {
    if (index < 0 || index >= _events.length) return;
    final dexProv = Provider.of<DexProvider>(context, listen: false);
    await showMobileEventCorrectionDialog(
      context: context,
      event: _events[index],
      allPokemon: dexProv.allPokemon,
      onEventUpdated: (updated) {
        setState(() => _events[index] = updated);
        if (updated.type == ScannerEventType.caught &&
            updated.pokemonId != null) {
          unawaited(
            _markPokemonCaughtInDex(
              updated.pokemonId!,
              isShiny: updated.isShiny,
              isAlpha: updated.isAlpha,
            ),
          );
        }
      },
    );
  }

  void _updateSettings(ScannerSettings next) {
    widget.coordinator.updateSettings(next);
    _cameraSource.setPollInterval(Duration(milliseconds: next.scanIntervalMs));
    _cameraSource.setPreprocessProfile(next.preprocessProfile);
    unawaited(_persistenceService.saveScannerSettings(next));
    setState(() {});
  }

  void _ignorePokemon(int pokemonId, {String? displayName}) {
    final cur = widget.coordinator.settings.ignoredPokemonIds;
    if (cur.contains(pokemonId)) return;
    _updateSettings(
      widget.coordinator.settings.copyWith(
        ignoredPokemonIds: [...cur, pokemonId],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${displayName ?? '#$pokemonId'} wird ignoriert.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _unignorePokemon(int pokemonId) {
    final cur = widget.coordinator.settings.ignoredPokemonIds;
    _updateSettings(
      widget.coordinator.settings.copyWith(
        ignoredPokemonIds: cur.where((id) => id != pokemonId).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dexProv = Provider.of<DexProvider>(context);
    final activeDex = _getActiveDex(dexProv);
    final byId = {for (final p in dexProv.allPokemon) p.id: p};
    final media = MediaQuery.sizeOf(context);
    final isLandscape = media.width > media.height && media.height < 520;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _hardwareController,
      builder: (context, _) {
        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: _viewMode == MobileScannerViewMode.split
                  ? _buildSplitLayout(
                      dexProv: dexProv,
                      activeDex: activeDex,
                      byId: byId,
                      isLandscape: isLandscape,
                    )
                  : _buildFullscreenLayout(
                      dexProv: dexProv,
                      activeDex: activeDex,
                      byId: byId,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopToolbar(DexProvider dexProv, UserDex? activeDex) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('mobile_tracker_top_toolbar'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.onSurface, size: 20),
              tooltip: 'Schließen',
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.of(context).pop(),
            ),
            InkWell(
              onTap: () => _openTargetDexModal(dexProv),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book, size: 14, color: colors.primary),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        activeDex?.title ?? 'Ziel-Dex',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            KeyedSubtree(
              key: _tutModesKey,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    key: const Key('btn_scan_mode_auto'),
                    label: const Text('Auto', style: TextStyle(fontSize: 11)),
                    selected: _scanMode == MobileCameraScanMode.autoFull,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) =>
                        _setScanMode(MobileCameraScanMode.autoFull),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    key: const Key('btn_scan_mode_draw'),
                    label: const Text('Vierecke', style: TextStyle(fontSize: 11)),
                    selected: _scanMode == MobileCameraScanMode.customRegions,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) =>
                        _setScanMode(MobileCameraScanMode.customRegions),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (_cameraSource.ocrDriver is WebOcrStatusReportingDriver)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ValueListenableBuilder<WebOcrEngineStatus>(
                  valueListenable:
                      (_cameraSource.ocrDriver as WebOcrStatusReportingDriver)
                          .statusListenable,
                  builder: (context, status, _) {
                    return Container(
                      key: const Key('web_ocr_status_pill'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.displayLabelDe,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    );
                  },
                ),
              ),
            KeyedSubtree(
              key: _tutPhotoKey,
              child: IconButton(
                key: const Key('btn_import_photo_scan'),
                icon: Icon(
                  Icons.photo_library_outlined,
                  color: colors.onSurface,
                  size: 20,
                ),
                tooltip: 'Foto scannen',
                visualDensity: VisualDensity.compact,
                onPressed: _importAndScanPhoto,
              ),
            ),
            KeyedSubtree(
              key: _tutPipKey,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('btn_toggle_split_view'),
                    icon: Icon(
                      _viewMode == MobileScannerViewMode.split
                          ? Icons.fullscreen
                          : Icons.view_agenda_outlined,
                      color: colors.primary,
                      size: 20,
                    ),
                    tooltip: _viewMode == MobileScannerViewMode.split
                        ? 'Vollbild'
                        : 'Split-Screen',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final next = _viewMode == MobileScannerViewMode.split
                          ? MobileScannerViewMode.fullscreen
                          : MobileScannerViewMode.split;
                      setState(() => _viewMode = next);
                      _trackerService.setViewMode(next);
                    },
                  ),
                  IconButton(
                    key: const Key('btn_minimize_to_pip'),
                    icon: Icon(
                      Icons.picture_in_picture_alt,
                      color: colors.onSurface,
                      size: 20,
                    ),
                    tooltip: 'Als Mini-Fenster (PiP)',
                    visualDensity: VisualDensity.compact,
                    onPressed: _minimizeToPip,
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('btn_mobile_scanner_help'),
              icon: Icon(
                Icons.help_outline,
                color: colors.primary,
                size: 20,
              ),
              tooltip: 'Scanner-Tutorial',
              visualDensity: VisualDensity.compact,
              onPressed: () => _tutorialController.startTutorial(
                context,
                getViewMode: () => _viewMode,
                force: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewport() {
    return MobileCameraViewport(
      tutorialKey: _tutViewportKey,
      cameraController: _hardwareController.controller,
      permissionDenied: _hardwareController.permissionDenied,
      isInitializingCamera: _hardwareController.isInitializing,
      cameraErrorText: _hardwareController.cameraErrorText,
      livePreviewAspectRatio: _hardwareController.livePreviewAspectRatio,
      scanMode: _scanMode,
      autoPreset: _autoPreset,
      regions: _regions,
      activeBrushTarget: _activeBrushTarget,
      isEditingRegions: _isEditingRegions,
      isScanningActive: _isScanningActive,
      supportsTorchControl: _hardwareController.supportsTorchControl,
      torchEnabled: _hardwareController.torchEnabled,
      cameraCount: _hardwareController.cameras.length,
      onRegionsChanged: _updateRegions,
      onTapCameraFocus: _hardwareController.handleTapCameraFocus,
      onRetryCamera: () => unawaited(_hardwareController.initHardwareCamera()),
      onImportPhoto: _importAndScanPhoto,
      onToggleScanning: _toggleScanning,
      onToggleTorch: () => unawaited(_hardwareController.toggleTorch()),
      onSwitchCamera: () => unawaited(_hardwareController.switchCamera()),
      onTriggerManualScan: () => unawaited(_cameraSource.triggerSingleScan()),
    );
  }

  Widget _buildBrushBar() {
    return MobileDrawBrushBar(
      activeBrushTarget: _activeBrushTarget,
      multiSlotIds: _effectiveMultiSlotIds,
      isEditingRegions: _isEditingRegions,
      onSelectBrushTarget: (target) =>
          setState(() => _activeBrushTarget = target),
      onAddMultiSlot: _addMultiSlot,
      onEditingChanged: (v) => setState(() => _isEditingRegions = v),
    );
  }

  Widget _buildFullscreenLayout({
    required DexProvider dexProv,
    required UserDex? activeDex,
    required Map<int, Pokemon> byId,
  }) {
    final focusEvent = _activeFocusEvents.isNotEmpty
        ? _activeFocusEvents.first
        : (_events.isNotEmpty ? _events.first : null);
    final mediaH = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        _buildTopToolbar(dexProv, activeDex),
        if (_scanMode == MobileCameraScanMode.customRegions) _buildBrushBar(),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildViewport(),
              if (focusEvent != null)
                Positioned(
                  left: 10,
                  right: 52,
                  bottom: 8,
                  child: MobileCompactFocusPill(
                    event: focusEvent,
                    isCaught: focusEvent.pokemonId != null &&
                        _isPokemonCaughtInActiveDex(focusEvent.pokemonId!),
                    evolutionStatus: _dexController.activeEvolutionStatus,
                    onMarkCaught: focusEvent.pokemonId != null
                        ? () => unawaited(
                              _markPokemonCaughtInDex(
                                focusEvent.pokemonId!,
                                isShiny: focusEvent.isShiny,
                                isAlpha: focusEvent.isAlpha,
                              ),
                            )
                        : null,
                  ),
                ),
            ],
          ),
        ),
        MobileFullscreenBottomPanel(
          tutorialKey: _tutBottomPanelKey,
          isExpanded: _isDrawerExpanded,
          eventCount: _events.length,
          activeDex: activeDex,
          maxHeight: math.max(90, mediaH * 0.42),
          onExpandedChanged: (v) => setState(() => _isDrawerExpanded = v),
          buildTabbedPanel: (headerAction) => _buildTabbedPanel(
            activeDex: activeDex,
            byId: byId,
            headerAction: headerAction,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitLayout({
    required DexProvider dexProv,
    required UserDex? activeDex,
    required Map<int, Pokemon> byId,
    required bool isLandscape,
  }) {
    final content = isLandscape
        ? Row(
            children: [
              Expanded(flex: 5, child: _buildViewport()),
              Expanded(
                flex: 6,
                child: _buildTabbedPanel(activeDex: activeDex, byId: byId),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(flex: 4, child: _buildViewport()),
              Expanded(
                flex: 6,
                child: _buildTabbedPanel(activeDex: activeDex, byId: byId),
              ),
            ],
          );

    return Column(
      children: [
        _buildTopToolbar(dexProv, activeDex),
        if (_scanMode == MobileCameraScanMode.customRegions) _buildBrushBar(),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildTabbedPanel({
    required UserDex? activeDex,
    required Map<int, Pokemon> byId,
    Widget? headerAction,
  }) {
    final dexProv = Provider.of<DexProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _splitTabController,
                  isScrollable: false,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(key: Key('split_tab_focus'), text: 'Fokus & Dex'),
                    Tab(key: Key('split_tab_zones'), text: 'Zonen & Kamera'),
                    Tab(key: Key('split_tab_feed'), text: 'Feed & Diagnose'),
                  ],
                ),
              ),
              ?headerAction,
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _splitTabController,
              children: [
                MobileFocusDexTab(
                  activeDex: activeDex,
                  activeFocusEvents: _combinedFocusEvents,
                  latestEvent: _events.isNotEmpty ? _events.first : null,
                  evolutionStatus: _dexController.activeEvolutionStatus,
                  pokemonById: byId,
                  ignoredPokemonIds:
                      widget.coordinator.settings.ignoredPokemonIds,
                  isPokemonCaught: _isPokemonCaughtInActiveDex,
                  onSelectDex: () => _openTargetDexModal(dexProv),
                  onOpenStarterFilterInfo: () =>
                      showMobileStarterFilterDialog(context),
                  onUnignorePokemon: _unignorePokemon,
                  onIgnorePokemon: _ignorePokemon,
                  onMarkCaught: (pid, {isShiny = false, isAlpha = false}) =>
                      unawaited(
                    _markPokemonCaughtInDex(
                      pid,
                      isShiny: isShiny,
                      isAlpha: isAlpha,
                    ),
                  ),
                ),
                MobileZonesCameraTab(
                  scanMode: _scanMode,
                  autoPreset: _autoPreset,
                  regions: _regions,
                  activeBrushTarget: _activeBrushTarget,
                  multiSlotIds: _effectiveMultiSlotIds,
                  isEditingRegions: _isEditingRegions,
                  settings: widget.coordinator.settings,
                  ocrLanguageCode: widget.coordinator.settings.ocrLanguage,
                  alertSettings: _alertService.settings,
                  torchEnabled: _hardwareController.torchEnabled,
                  zoomLevel: _hardwareController.zoomLevel,
                  minZoom: _hardwareController.minZoom,
                  maxZoom: _hardwareController.maxZoom,
                  cameras: _hardwareController.cameras,
                  selectedCameraIndex: _hardwareController.selectedCameraIndex,
                  onScanModeChanged: _setScanMode,
                  onAutoPresetChanged: (p) {
                    setState(() => _autoPreset = p);
                    _cameraSource.setAutoPreset(p);
                  },
                  onSelectBrushTarget: _selectBrushTarget,
                  onEditingChanged: (v) =>
                      setState(() => _isEditingRegions = v),
                  onAddMultiSlot: _addMultiSlot,
                  onRemoveMultiSlot: _removeMultiSlot,
                  onToggleMultiSlotEnabled: _toggleMultiSlotEnabled,
                  onClearRegions: () => _updateRegions(const []),
                  onDeleteRegion: (id) => _updateRegions(
                    _regions.where((r) => r.id != id).toList(),
                  ),
                  onToggleRegionEnabled: (id) => _updateRegions(
                    _regions
                        .map(
                          (r) => r.id == id ? r.copyWith(enabled: !r.enabled) : r,
                        )
                        .toList(),
                  ),
                  onToggleTorch: () =>
                      unawaited(_hardwareController.toggleTorch()),
                  onZoomChanged: (z) =>
                      unawaited(_hardwareController.setZoom(z)),
                  onSelectCameraIndex: (idx) =>
                      unawaited(_hardwareController.selectCameraByIndex(idx)),
                  onSwitchCamera: () =>
                      unawaited(_hardwareController.switchCamera()),
                  onImportPhoto: () => unawaited(_importAndScanPhoto()),
                  onSettingsChanged: _updateSettings,
                  onOcrLanguageChanged: (lang) {
                    _updateSettings(
                      widget.coordinator.settings.copyWith(ocrLanguage: lang),
                    );
                    _syncOcrLanguageTag();
                  },
                  onAlertSettingsChanged: (a) {
                    setState(() => _alertService.updateSettings(a));
                  },
                  onOpenCustomPatterns: _openCustomPatternsDialog,
                ),
                MobileFeedDiagnoseTab(
                  events: _events,
                  cameraSource: _cameraSource,
                  onCorrectEvent: (i) =>
                      unawaited(_openEventCorrectionDialog(i)),
                  onDeleteEvent: (i) {
                    if (i >= 0 && i < _events.length) {
                      setState(() => _events.removeAt(i));
                    }
                  },
                  onMarkCaught: (pid, {isShiny = false, isAlpha = false}) =>
                      unawaited(
                    _markPokemonCaughtInDex(
                      pid,
                      isShiny: isShiny,
                      isAlpha: isAlpha,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
