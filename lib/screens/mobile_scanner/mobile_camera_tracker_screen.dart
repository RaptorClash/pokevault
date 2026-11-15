import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
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
import '../../services/database_service.dart';
import '../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../services/desktop_tracker/evolution_chain_helper.dart';
import '../../services/desktop_tracker/tracker_alert_service.dart';
import '../../services/desktop_tracker/windows_desktop_bridge.dart';
import '../../services/mobile_scanner/camera_frame_processor.dart';
import '../../services/mobile_scanner/camera_scan_region.dart';
import '../../services/mobile_scanner/mobile_camera_source.dart';
import '../../services/mobile_scanner/mobile_camera_tracker_service.dart';
import '../../services/mobile_scanner/mobile_ocr_driver.dart';
import '../../services/scanner_core/media/image_frame_decoder.dart';
import '../../services/scanner_core/models/scanner_event.dart';
import '../../services/scanner_core/models/scanner_settings.dart';
import '../../services/scanner_core/scanner_coordinator.dart';
import '../../services/scanner_core/scanner_persistence_service.dart';
import '../../utils/dex_logic_helper.dart';
import '../desktop_tracker/widgets/custom_pattern_studio_dialog.dart';
import '../desktop_tracker/widgets/dex_selection_modal.dart';
import 'widgets/camera_region_overlay.dart';
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
    with SingleTickerProviderStateMixin {
  static const String _regionsPrefsKey = 'pokevault_mobile_camera_regions_v1';
  static const String _scanModePrefsKey =
      'pokevault_mobile_camera_scan_mode_v1';
  static const String _multiSlotsPrefsKey = 'pokevault_mobile_multi_slots_v1';

  late final MobileCameraSource _cameraSource;
  late final bool _ownsCameraSource;
  final MobileCameraTrackerService _trackerService =
      MobileCameraTrackerService.instance;
  final ScannerPersistenceService _persistenceService =
      ScannerPersistenceService();
  late final TrackerAlertService _alertService;
  late final TabController _splitTabController;

  StreamSubscription<ScannerEvent>? _eventSub;
  StreamSubscription<List<ScannerEvent>>? _focusSub;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  bool _isInitializingCamera = false;
  bool _permissionDenied = false;
  String? _cameraErrorText;
  bool _convertingFrame = false;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  double _zoomLevel = 1.0;
  bool _torchEnabled = false;
  double? _livePreviewAspectRatio;

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
  EvolutionCheckStatus? _activeEvolutionStatus;
  final Map<int, Map<String, dynamic>?> _evoChainCache = {};
  int? _lastEvoPokemonId;
  String _lastEvoDexKey = '';

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
    _splitTabController = TabController(length: 3, vsync: this);
    _selectedDexId = widget.initialDexId ?? _trackerService.activeDexId;
    _permissionDenied = widget.simulatePermissionDenied;
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
        ocrDriver: MobileOcrDriver(),
        preprocessProfile: widget.coordinator.settings.preprocessProfile,
      );
      _ownsCameraSource = true;
    }

    // Re-attach seamlessly if returning from PiP or reuse live session
    final existingController = _trackerService.activeCameraController;
    if (existingController is CameraController &&
        existingController.value.isInitialized) {
      _cameraController = existingController;
      _torchEnabled = _trackerService.torchEnabledNotifier.value;
      _zoomLevel = _trackerService.zoomLevelNotifier.value;
    }

    _scanMode = _cameraSource.scanMode;
    _autoPreset = _cameraSource.autoPreset;
    _regions = _cameraSource.regions;
    _multiSlotIds = List<int>.from(_regions.multiSlotIds);
    if (widget.availableCamerasOverride != null) {
      _cameras = widget.availableCamerasOverride!;
      final backIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIdx >= 0 ? backIdx : 0;
    }

    widget.coordinator.bindSource(_cameraSource);
    widget.coordinator.start();

    _trackerService.startSession(
      coordinator: widget.coordinator,
      cameraSource: _cameraSource,
      dexId: _selectedDexId,
      pipCameraPreviewBuilder: _buildPipPreviewWidget,
      onExpandFromPip: _reopenFromPip,
      onToggleTorch: _toggleTorch,
    );
    _trackerService.attachPipCallbacks(onDisposeCamera: _disposeHardwareCamera);
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
        _cameraController == null) {
      unawaited(_initHardwareCamera());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncOcrLanguageTag();
  }

  @override
  void dispose() {
    _splitTabController.dispose();
    _eventSub?.cancel();
    _focusSub?.cancel();

    if (!_handedOffToPip) {
      unawaited(_disableWakelock());
      unawaited(_disposeHardwareCamera());
      unawaited(_trackerService.stopSession());
      if (_ownsCameraSource) {
        unawaited(_cameraSource.dispose());
      }
    }
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
        final mode = MobileCameraScanMode.values.where((m) => m.name == savedMode).firstOrNull;
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

  Future<void> _initHardwareCamera() async {
    if (_isInitializingCamera) return;
    setState(() {
      _isInitializingCamera = true;
      _cameraErrorText = null;
      _permissionDenied = false;
    });

    try {
      _cameras = widget.availableCamerasOverride ?? await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isInitializingCamera = false;
          _cameraErrorText = 'Keine Kamera auf diesem Gerät gefunden.';
        });
        return;
      }

      final backIdx = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIdx >= 0 ? backIdx : 0;
      await _startCameraController(_cameras[_selectedCameraIndex]);
    } on CameraException catch (e) {
      if (!mounted) return;
      final code = e.code.toLowerCase();
      final isDenied =
          code.contains('access') || code.contains('denied') || code.contains('permission');
      setState(() {
        _isInitializingCamera = false;
        _permissionDenied = isDenied;
        _cameraErrorText = e.description ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
        _cameraErrorText = e.toString();
      });
    }
  }

  Future<void> _startCameraController(CameraDescription desc) async {
    final prev = _cameraController;
    _cameraController = null;
    if (prev != null) {
      try {
        if (prev.value.isStreamingImages) {
          await prev.stopImageStream();
        }
        await prev.dispose();
      } catch (_) {}
    }

    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    final minZoom = await controller.getMinZoomLevel();
    final maxZoom = await controller.getMaxZoomLevel();
    await controller.startImageStream((image) {
      unawaited(_handleCameraImage(image, desc.sensorOrientation));
    });

    if (!mounted) {
      try {
        await controller.stopImageStream();
        await controller.dispose();
      } catch (_) {}
      return;
    }

    _trackerService.activeCameraController = controller;
    setState(() {
      _cameraController = controller;
      _isInitializingCamera = false;
      _permissionDenied = false;
      _minZoom = minZoom;
      _maxZoom = math.max(minZoom, maxZoom);
      _zoomLevel = minZoom;
      _torchEnabled = false;
    });
  }

  Future<void> _disposeHardwareCamera() async {
    final controller = _cameraController ??
        (_trackerService.activeCameraController is CameraController
            ? _trackerService.activeCameraController as CameraController
            : null);
    _cameraController = null;
    _trackerService.activeCameraController = null;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _handleCameraImage(
    CameraImage image,
    int sensorOrientation,
  ) async {
    if (_convertingFrame || !_isScanningActive) return;
    _convertingFrame = true;
    try {
      CapturedFrame? upright;
      if (image.planes.length >= 3) {
        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];
        upright = CameraFrameProcessor.convertYuv420ToBgraFrame(
          width: image.width,
          height: image.height,
          yBytes: yPlane.bytes,
          uBytes: uPlane.bytes,
          vBytes: vPlane.bytes,
          yRowStride: yPlane.bytesPerRow,
          uvRowStride: uPlane.bytesPerRow,
          uvPixelStride: uPlane.bytesPerPixel ?? 1,
          sensorOrientation: sensorOrientation,
        );
      } else if (image.planes.isNotEmpty) {
        final p = image.planes.first;
        final rowBytes = image.width * 4;
        Uint8List bgra;
        if (p.bytesPerRow == rowBytes && p.bytes.length >= rowBytes * image.height) {
          bgra = p.bytes.sublist(0, rowBytes * image.height);
        } else {
          bgra = Uint8List(rowBytes * image.height);
          for (int y = 0; y < image.height; y++) {
            final srcStart = y * p.bytesPerRow;
            final dstStart = y * rowBytes;
            if (srcStart + rowBytes <= p.bytes.length) {
              bgra.setRange(dstStart, dstStart + rowBytes, p.bytes, srcStart);
            }
          }
        }
        upright = CameraFrameProcessor.rotateBgraFrame(
          CapturedFrame(
            width: image.width,
            height: image.height,
            bytes: bgra,
            pixelFormat: 'bgra8888',
            captureMethod: 'mobile_camera_bgra',
          ),
          sensorOrientation,
        );
      }

      if (upright != null) {
        final nextAspect = upright.width / math.max(1, upright.height);
        if (mounted &&
            (_livePreviewAspectRatio == null ||
                (_livePreviewAspectRatio! - nextAspect).abs() > 0.05)) {
          setState(() => _livePreviewAspectRatio = nextAspect);
        }
        await _cameraSource.submitCameraFrame(upright);
      }
    } finally {
      _convertingFrame = false;
    }
  }

  void _syncOcrLanguageTag() {
    String effectiveLang = widget.coordinator.settings.ocrLanguage;
    if (effectiveLang == 'auto') {
      try {
        effectiveLang =
            Provider.of<SettingsProvider>(context, listen: false)
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

    var stored = event;
    if (widget.coordinator.settings.autoMarkCaught &&
        event.type == ScannerEventType.caught &&
        event.pokemonId != null) {
      final dexProv = Provider.of<DexProvider>(context, listen: false);
      final dex = _getActiveDex(dexProv);
      if (dex != null) {
        final idStr = event.pokemonId.toString();
        stored = event.copyWith(
          autoAddedCaught: !dex.caughtIds.contains(idStr),
          autoAddedShiny: event.isShiny && !dex.shinyIds.contains(idStr),
          autoAddedAlpha: event.isAlpha && !dex.alphaIds.contains(idStr),
        );
      }
    }

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
    final pid = event?.pokemonId;
    if (pid == null || activeDex == null) {
      if (_activeEvolutionStatus != null) {
        setState(() => _activeEvolutionStatus = null);
        _trackerService.updateEvolutionStatus(null);
      }
      return;
    }

    final dexSig = '${activeDex.id}_${activeDex.caughtIds.length}';
    if (_lastEvoPokemonId == pid && _lastEvoDexKey == dexSig) return;
    _lastEvoPokemonId = pid;
    _lastEvoDexKey = dexSig;

    final byId = {for (final p in dexProv.allPokemon) p.id: p};
    final target = byId[pid];
    if (target == null || target.evolutionChainId == -1) {
      setState(() => _activeEvolutionStatus = null);
      _trackerService.updateEvolutionStatus(null);
      return;
    }

    final chainId = target.evolutionChainId;
    String lang = 'de';
    try {
      lang = Provider.of<SettingsProvider>(context, listen: false)
          .effectivePokemonLanguage;
    } catch (_) {}

    if (_evoChainCache.containsKey(chainId)) {
      final status = EvolutionChainHelper.evaluate(
        pokemonId: pid,
        chainData: _evoChainCache[chainId],
        activeDex: activeDex,
        pokemonById: byId,
        languageCode: lang,
      );
      setState(() => _activeEvolutionStatus = status);
      _trackerService.updateEvolutionStatus(status);
      return;
    }

    unawaited(() async {
      try {
        final chain = await DatabaseService.instance.getEvolutionChain(chainId);
        _evoChainCache[chainId] = chain;
        if (!mounted) return;
        final status = EvolutionChainHelper.evaluate(
          pokemonId: pid,
          chainData: chain,
          activeDex: activeDex,
          pokemonById: byId,
          languageCode: lang,
        );
        setState(() => _activeEvolutionStatus = status);
        _trackerService.updateEvolutionStatus(status);
      } catch (_) {}
    }());
  }

  UserDex? _getActiveDex(DexProvider dexProvider) {
    final dexes = dexProvider.userDexes;
    if (dexes.isEmpty) return null;
    _selectedDexId ??= dexes.first.id;
    return dexes.cast<UserDex?>().firstWhere(
          (d) => d?.id == _selectedDexId,
          orElse: () => dexes.first,
        );
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

    final idStr = pokemonId.toString();
    if (!targetDex.caughtIds.contains(idStr)) targetDex.caughtIds.add(idStr);
    if (isShiny && !targetDex.shinyIds.contains(idStr)) {
      targetDex.shinyIds.add(idStr);
    }
    if (isAlpha && !targetDex.alphaIds.contains(idStr)) {
      targetDex.alphaIds.add(idStr);
    }

    try {
      await DatabaseService.instance.savePokemonStatus(
        targetDex.id,
        idStr,
        isCaught: true,
        isShiny: isShiny ? true : null,
        isAlpha: isAlpha ? true : null,
      );
    } catch (_) {}

    await dexProv.saveUserDexAndSync(targetDex);
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
    CapturedFrame? frame;
    if (widget.photoFramePicker != null) {
      frame = await widget.photoFramePicker!();
    } else {
      const typeGroup = XTypeGroup(
        label: 'Bilder',
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      frame = await ImageFrameDecoder.decodeBytesToBgraFrame(bytes);
    }

    if (frame == null || !mounted) return;
    await _cameraSource.processPhotoFrame(frame);
  }

  Future<void> _toggleTorch() async {
    final next = !_torchEnabled;
    final ctrl = _cameraController;
    if (ctrl != null && ctrl.value.isInitialized) {
      try {
        await ctrl.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      } catch (_) {}
    }
    _trackerService.torchEnabledNotifier.value = next;
    if (mounted) setState(() => _torchEnabled = next);
  }

  Future<void> _setZoom(double zoom) async {
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    final ctrl = _cameraController;
    if (ctrl != null && ctrl.value.isInitialized) {
      try {
        await ctrl.setZoomLevel(clamped);
      } catch (_) {}
    }
    _trackerService.zoomLevelNotifier.value = clamped;
    if (mounted) setState(() => _zoomLevel = clamped);
  }

  Future<void> _selectCameraByIndex(int index) async {
    if (index < 0 || index >= _cameras.length) return;
    setState(() => _selectedCameraIndex = index);
    if (!widget.disableHardwareCamera) {
      await _startCameraController(_cameras[index]);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _selectCameraByIndex((_selectedCameraIndex + 1) % _cameras.length);
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
    final nextRegions = _regions
        .where((r) => r.slotId != slotId)
        .toList(growable: false);
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
          .map(
            (r) => r.slotId == slotId ? r.copyWith(enabled: enableNext) : r,
          )
          .toList(growable: false),
    );
  }

  Future<void> _handleTapCameraFocus(Offset normalizedPoint) async {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    try {
      await ctrl.setFocusPoint(normalizedPoint);
      await ctrl.setExposurePoint(normalizedPoint);
    } catch (_) {}
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
      } else {
        widget.coordinator.stop();
      }
    });
    _trackerService.isPausedNotifier.value = !_isScanningActive;
  }

  void _minimizeToPip() {
    _handedOffToPip = true;
    _trackerService.attachPipCallbacks(
      pipCameraPreviewBuilder: _buildPipPreviewWidget,
      onExpandFromPip: _reopenFromPip,
      onToggleTorch: _toggleTorch,
      onDisposeCamera: _disposeHardwareCamera,
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
    final ctrl = _cameraController;
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
    final ev = _events[index];
    final dexProv = Provider.of<DexProvider>(context, listen: false);
    final allPokemon = dexProv.allPokemon;
    var query = ev.matchedName;
    var isShiny = ev.isShiny;
    var isAlpha = ev.isAlpha;
    var selectedType = ev.type;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          final candidates = allPokemon
              .where(
                (p) =>
                    p.nameDe.toLowerCase().contains(query.toLowerCase()) ||
                    p.nameEn.toLowerCase().contains(query.toLowerCase()) ||
                    p.id.toString() == query.trim(),
              )
              .take(8)
              .toList();

          return AlertDialog(
            title: const Text('Ereignis korrigieren', style: TextStyle(fontSize: 16)),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<ScannerEventType>(
                      segments: const [
                        ButtonSegment(
                          value: ScannerEventType.caught,
                          label: Text('Gefangen'),
                        ),
                        ButtonSegment(
                          value: ScannerEventType.encounter,
                          label: Text('Begegnung'),
                        ),
                      ],
                      selected: {
                        selectedType == ScannerEventType.caught
                            ? ScannerEventType.caught
                            : ScannerEventType.encounter,
                      },
                      onSelectionChanged: (s) =>
                          setDlg(() => selectedType = s.first),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('✨ Shiny'),
                          selected: isShiny,
                          onSelected: (v) => setDlg(() => isShiny = v),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('🔥 Alpha'),
                          selected: isAlpha,
                          onSelected: (v) => setDlg(() => isAlpha = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Pokémon suchen',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setDlg(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    ...candidates.map(
                      (p) => ListTile(
                        dense: true,
                        title: Text('${p.nameDe} (#${p.id})'),
                        onTap: () {
                          final updated = ev.copyWith(
                            pokemonId: p.id,
                            matchedName: p.nameDe,
                            type: selectedType,
                            isShiny: isShiny,
                            isAlpha: isAlpha,
                          );
                          setState(() => _events[index] = updated);
                          if (selectedType == ScannerEventType.caught) {
                            unawaited(
                              _markPokemonCaughtInDex(
                                p.id,
                                isShiny: isShiny,
                                isAlpha: isAlpha,
                              ),
                            );
                          }
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Schließen'),
              ),
            ],
          );
        },
      ),
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

  void _showStarterFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Team- & Starter-Schutz'),
        content: const Text(
          'Ignorierte Pokémon (z. B. dein eigenes Starter-Pokémon aus "Los, Pikachu!") werden bei Kampfeintritten übersprungen, bis du sie hier wieder entfernst.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
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
            ChoiceChip(
              key: const Key('btn_scan_mode_auto'),
              label: const Text('Auto', style: TextStyle(fontSize: 11)),
              selected: _scanMode == MobileCameraScanMode.autoFull,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => _setScanMode(MobileCameraScanMode.autoFull),
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
            const SizedBox(width: 4),
            IconButton(
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
    );
  }

  Widget _buildCameraViewport() {
    return Container(
      key: const Key('mobile_camera_preview_surface'),
      color: const Color(0xFF0A0C12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_permissionDenied)
            Center(
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
                            onPressed: _initHardwareCamera,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Erneut versuchen'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _importAndScanPhoto,
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Foto scannen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            _buildFeedWithOverlay(),
            Positioned(
              right: 8,
              top: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _cameraSideButton(
                    icon: _isScanningActive ? Icons.pause : Icons.play_arrow,
                    tooltip: _isScanningActive ? 'Pause' : 'Fortsetzen',
                    onTap: _toggleScanning,
                    active: _isScanningActive,
                  ),
                  const SizedBox(height: 6),
                  _cameraSideButton(
                    icon: _torchEnabled ? Icons.flash_on : Icons.flash_off,
                    tooltip: 'Taschenlampe',
                    onTap: _toggleTorch,
                    active: _torchEnabled,
                  ),
                  if (_cameras.length > 1) ...[
                    const SizedBox(height: 6),
                    _cameraSideButton(
                      icon: Icons.cameraswitch_outlined,
                      tooltip: 'Kamera wechseln',
                      onTap: _switchCamera,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _cameraSideButton(
                    icon: Icons.touch_app,
                    tooltip: 'Jetzt scannen',
                    onTap: () => unawaited(_cameraSource.triggerSingleScan()),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedWithOverlay() {
    final ctrl = _cameraController;
    final hasLiveCtrl = ctrl != null && ctrl.value.isInitialized;
    final aspect = _livePreviewAspectRatio ??
        (hasLiveCtrl ? (1 / ctrl.value.aspectRatio) : null);

    final overlay = CameraRegionOverlay(
      scanMode: _scanMode,
      autoPreset: _autoPreset,
      regions: _regions,
      activeBrushRole: _activeBrushTarget.role,
      activeBrush: _activeBrushTarget,
      isEditing: _isEditingRegions,
      onRegionsChanged: _updateRegions,
      onTapCameraFocus: _handleTapCameraFocus,
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
          child: _isInitializingCamera
              ? const CircularProgressIndicator(color: Colors.cyanAccent)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_outlined,
                      color: Colors.white24,
                      size: 40,
                    ),
                    if (_cameraErrorText != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _cameraErrorText!,
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
        if (_scanMode == MobileCameraScanMode.customRegions)
          _buildDrawBrushBar(),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraViewport(),
              if (focusEvent != null)
                Positioned(
                  left: 10,
                  right: 52,
                  bottom: 8,
                  child: _buildCompactFocusPill(focusEvent),
                ),
            ],
          ),
        ),
        _buildFullscreenBottomPanel(
          activeDex: activeDex,
          byId: byId,
          maxHeight: math.max(90, mediaH * 0.42),
        ),
      ],
    );
  }

  Widget _buildDrawBrushBar() {
    final colors = Theme.of(context).colorScheme;
    final slotIds = _effectiveMultiSlotIds;
    return Container(
      key: const Key('mobile_draw_brush_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Zone A', style: TextStyle(fontSize: 10)),
              selected: _activeBrushTarget == CameraBrushTarget.zoneA(),
              visualDensity: VisualDensity.compact,
              onSelected: (_) =>
                  setState(() => _activeBrushTarget = CameraBrushTarget.zoneA()),
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Zone B (Fokus)', style: TextStyle(fontSize: 10)),
              selected: _activeBrushTarget == CameraBrushTarget.zoneB(),
              visualDensity: VisualDensity.compact,
              onSelected: (_) =>
                  setState(() => _activeBrushTarget = CameraBrushTarget.zoneB()),
            ),
            for (final slotId in slotIds) ...[
              const SizedBox(width: 4),
              ChoiceChip(
                label: Text('#$slotId Scan', style: const TextStyle(fontSize: 10)),
                selected:
                    _activeBrushTarget == CameraBrushTarget.multiScan(slotId),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(
                  () => _activeBrushTarget = CameraBrushTarget.multiScan(slotId),
                ),
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: Text('#$slotId Fokus', style: const TextStyle(fontSize: 10)),
                selected:
                    _activeBrushTarget == CameraBrushTarget.multiFocus(slotId),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(
                  () => _activeBrushTarget = CameraBrushTarget.multiFocus(slotId),
                ),
              ),
            ],
            const SizedBox(width: 4),
            ActionChip(
              avatar: const Icon(Icons.add, size: 14),
              label: const Text('Instanz', style: TextStyle(fontSize: 10)),
              visualDensity: VisualDensity.compact,
              onPressed: _addMultiSlot,
            ),
            const SizedBox(width: 6),
            FilterChip(
              label: Text(
                _isEditingRegions ? 'Bearbeiten' : 'Gesperrt',
                style: const TextStyle(fontSize: 10),
              ),
              selected: _isEditingRegions,
              visualDensity: VisualDensity.compact,
              onSelected: (v) => setState(() => _isEditingRegions = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFocusPill(ScannerEvent ev) {
    final pid = ev.pokemonId;
    final caught = pid != null && _isPokemonCaughtInActiveDex(pid);
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${ev.isShiny ? '✨ ' : ''}${ev.isAlpha ? '🔥 ' : ''}${ev.matchedName}${pid != null ? ' (#$pid)' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (_activeEvolutionStatus != null &&
                      _activeEvolutionStatus!.hasEvolutions)
                    Text(
                      _activeEvolutionStatus!.summaryLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (pid != null)
              TextButton(
                onPressed: () => _markPokemonCaughtInDex(
                  pid,
                  isShiny: ev.isShiny,
                  isAlpha: ev.isAlpha,
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor:
                      caught ? Colors.greenAccent : Colors.cyanAccent,
                ),
                child: Text(
                  caught ? 'Im Dex ✓' : '+ Eintragen',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenBottomPanel({
    required UserDex? activeDex,
    required Map<int, Pokemon> byId,
    required double maxHeight,
  }) {
    final colors = Theme.of(context).colorScheme;
    if (!_isDrawerExpanded) {
      return InkWell(
        onTap: () => setState(() => _isDrawerExpanded = true),
        child: Container(
          key: const Key('mobile_collapsed_bottom_bar'),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_up, color: colors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Fokus, Zonen & Feed (${_events.length})',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurface, fontSize: 12),
                ),
              ),
              Text(
                activeDex?.title ?? '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: maxHeight,
      child: _buildTabbedPanel(
        activeDex: activeDex,
        byId: byId,
        headerAction: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _isDrawerExpanded = false),
        ),
      ),
    );
  }

  Widget _buildSplitLayout({
    required DexProvider dexProv,
    required UserDex? activeDex,
    required Map<int, Pokemon> byId,
    required bool isLandscape,
  }) {
    if (isLandscape) {
      return Column(
        children: [
          _buildTopToolbar(dexProv, activeDex),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 5, child: _buildCameraViewport()),
                Expanded(
                  flex: 6,
                  child: _buildTabbedPanel(activeDex: activeDex, byId: byId),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildTopToolbar(dexProv, activeDex),
        if (_scanMode == MobileCameraScanMode.customRegions)
          _buildDrawBrushBar(),
        Expanded(flex: 4, child: _buildCameraViewport()),
        Expanded(
          flex: 6,
          child: _buildTabbedPanel(activeDex: activeDex, byId: byId),
        ),
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
                  evolutionStatus: _activeEvolutionStatus,
                  pokemonById: byId,
                  ignoredPokemonIds:
                      widget.coordinator.settings.ignoredPokemonIds,
                  isPokemonCaught: _isPokemonCaughtInActiveDex,
                  onSelectDex: () => _openTargetDexModal(dexProv),
                  onOpenStarterFilterInfo: _showStarterFilterDialog,
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
                  torchEnabled: _torchEnabled,
                  zoomLevel: _zoomLevel,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  cameras: _cameras,
                  selectedCameraIndex: _selectedCameraIndex,
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
                  onToggleTorch: () => unawaited(_toggleTorch()),
                  onZoomChanged: (z) => unawaited(_setZoom(z)),
                  onSelectCameraIndex: (idx) =>
                      unawaited(_selectCameraByIndex(idx)),
                  onSwitchCamera: () => unawaited(_switchCamera()),
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
