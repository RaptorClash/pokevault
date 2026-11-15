import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart' as io;
import '../../models/pokemon.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../services/desktop_tracker/desktop_ocr_driver.dart';
import '../../services/desktop_tracker/desktop_system_snipping_service.dart';
import '../../services/desktop_tracker/desktop_tracker_service.dart';
import '../../services/desktop_tracker/desktop_window_source.dart';
import '../../services/desktop_tracker/evolution_chain_helper.dart';
import '../../services/desktop_tracker/window_detector.dart';
import '../../services/desktop_tracker/windows_desktop_bridge.dart';
import '../../services/scanner_core/models/scanner_event.dart';
import '../../services/scanner_core/models/scanner_settings.dart';
import '../../services/scanner_core/scanner_coordinator.dart';
import '../../services/scanner_core/scanner_persistence_service.dart';
import '../../services/desktop_tracker/screen_region.dart';
import '../../services/desktop_tracker/tracker_alert_service.dart';
import '../../utils/dex_logic_helper.dart';
import 'widgets/custom_pattern_studio_dialog.dart';
import 'widgets/dex_selection_modal.dart';
import 'widgets/floating_overlay_hud.dart';
import 'widgets/screen_snipping_overlay.dart';

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
  Offset _hudPosition = const Offset(20, 20);
  bool _isScanningActive = true;
  bool _hasUserToggledScan = false;
  bool _isRefreshingWindows = false;
  ScanRegionPreset _scanRegion = ScanRegionPreset.fullWindow;
  late final DesktopWindowSource _activeWindowSource;
  late final DesktopSystemSnippingService _snippingService;
  final ScannerPersistenceService _persistenceService =
      ScannerPersistenceService();
  final Map<int, Map<String, dynamic>?> _evoChainCache = {};
  EvolutionCheckStatus? _activeEvolutionStatus;
  int? _lastEvoPokemonId;
  String? _lastEvoDexKey;
  int? _snippingMultiSlotId;
  bool _snippingMultiIsFocus = false;
  bool _showZoneAInfo = false;
  bool _showZoneBInfo = false;
  bool _showScanProfileInfo = false;

  bool get _isLiveWindows =>
      !kIsWeb &&
      io.Platform.isWindows &&
      !io.Platform.environment.containsKey('FLUTTER_TEST');

  DesktopPlatformBridge? get _effectiveNativeBridge =>
      widget.nativeBridge ??
      (_isLiveWindows ? WindowsDesktopBridge.instance : null);

  @override
  void initState() {
    super.initState();
    _alertService = TrackerAlertService();
    _snippingService = widget.snippingService ?? DesktopSystemSnippingService.instance;
    _selectedDexId = widget.initialDexId;

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
    _activeWindowSource.setMultiInstanceSlots(
      widget.coordinator.settings.multiInstanceSlots,
    );
    unawaited(_loadPersistedSettings());
    _customScreenRegion = DesktopTrackerService.instance.activeScreenRegion ??
        _activeWindowSource.screenRegion;
    _snippetPreviewBytes = DesktopTrackerService.instance.activeSnippetPreview;
    _showFloatingHud = DesktopTrackerService.instance.showFloatingHud;

    DesktopTrackerService.instance.showFloatingHudNotifier
        .addListener(_onServiceHudVisibilityChanged);

    DesktopTrackerService.instance.configureNativeHudBridge(
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
      DesktopTrackerService.instance.startTracking(
        coordinator: widget.coordinator,
        windowSource: _activeWindowSource,
        dexId: _selectedDexId,
      );
    });

    if (widget.detectedWindows.isNotEmpty) {
      _windows = List.from(widget.detectedWindows);
      _activeWindowSource.updateKnownWindows(_windows);
      _selectDefaultWindow();
    } else if (_isLiveWindows) {
      _isRefreshingWindows = true;
      _loadWindowsAsync();
    } else {
      _windows = WindowDetector().getFallbackWindows();
      _activeWindowSource.updateKnownWindows(_windows);
      _selectDefaultWindow();
      _loadWindowsAsync();
    }

    _eventSub = widget.coordinator.events.listen((event) {
      if (!mounted) return;
      _alertService.handleEvent(event);

      var storedEvent = event;
      if (widget.coordinator.settings.autoMarkCaught &&
          event.type == ScannerEventType.caught &&
          event.pokemonId != null) {
        final dexProvider = Provider.of<DexProvider>(context, listen: false);
        final targetDex = _getActiveDex(dexProvider);
        if (targetDex != null) {
          final idStr = event.pokemonId.toString();
          storedEvent = event.copyWith(
            autoAddedCaught: !targetDex.caughtIds.contains(idStr),
            autoAddedShiny: event.isShiny && !targetDex.shinyIds.contains(idStr),
            autoAddedAlpha: event.isAlpha && !targetDex.alphaIds.contains(idStr),
          );
        }
      }

      setState(() {
        _events.insert(0, storedEvent);
        if (_events.length > 50) {
          _events.removeLast();
        }
      });

      // Refresh evolution tracking indicator whenever latest encounter/catch updates
      final dexProv = Provider.of<DexProvider>(context, listen: false);
      _refreshEvolutionStatusFor(storedEvent, _getActiveDex(dexProv), dexProv);

      // Auto-mark caught if configured
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
      setState(() {
        _activeFocusEvents = focusGroup;
      });
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
          current.multiInstanceSlots.isEmpty;
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
      );
      if (merged.scanIntervalMs == current.scanIntervalMs &&
          merged.preprocessProfile == current.preprocessProfile &&
          merged.ocrLanguage == current.ocrLanguage &&
          merged.customPatterns.isEmpty &&
          merged.liveFocusPreset == current.liveFocusPreset &&
          merged.ignoredPokemonIds.isEmpty &&
          merged.showScreenBorders == current.showScreenBorders &&
          merged.multiInstanceSlots.isEmpty) {
        return;
      }
      widget.coordinator.updateSettings(merged);
      _activeWindowSource.setPollInterval(
        Duration(milliseconds: merged.scanIntervalMs),
      );
      _activeWindowSource.setPreprocessProfile(merged.preprocessProfile);
      _activeWindowSource.setLiveFocusPreset(merged.liveFocusPreset);
      _activeWindowSource.setMultiInstanceSlots(merged.multiInstanceSlots);
      didChangeDependencies();
      _syncOverlayBorders();
      if (mounted) setState(() {});
    } catch (_) {
      // SharedPreferences unavailable in isolated unit/widget test environments
    }
  }

  void _updateSettingsAndPersist(ScannerSettings next) {
    widget.coordinator.updateSettings(next);
    _activeWindowSource.setPollInterval(Duration(milliseconds: next.scanIntervalMs));
    _activeWindowSource.setPreprocessProfile(next.preprocessProfile);
    _activeWindowSource.setLiveFocusPreset(next.liveFocusPreset);
    _activeWindowSource.setMultiInstanceSlots(next.multiInstanceSlots);
    didChangeDependencies();
    _syncOverlayBorders();
    unawaited(_persistenceService.saveScannerSettings(next));
  }

  ScreenRegion? _resolveAbsoluteZoneARegion() {
    if (_customScreenRegion != null && _customScreenRegion!.isAbsoluteScreen) {
      return _customScreenRegion;
    }
    final win = _selectedWindow;
    final bounds = win?.bounds;
    final crop = _activeWindowSource.cropRegion;
    if (win != null && !win.isDesktopScreen && bounds != null && crop != null) {
      return ScreenRegion(
        x: bounds.left + crop.left,
        y: bounds.top + crop.top,
        width: crop.width,
        height: crop.height,
        isAbsoluteScreen: true,
        label: 'Zone A',
      );
    }
    return null;
  }

  ScreenRegion? _resolveAbsoluteZoneBRegion() {
    final preset = widget.coordinator.settings.liveFocusPreset;
    if (preset == LiveFocusPreset.disabled) return null;
    if (preset == LiveFocusPreset.customRegion) {
      final r = _activeWindowSource.liveFocusScreenRegion;
      if (r != null && r.isAbsoluteScreen) return r;
      return null;
    }
    final win = _selectedWindow;
    final bounds = win?.bounds;
    if (win == null || win.isDesktopScreen || bounds == null) return null;
    final crop = WindowDetector().calculateEnemyHudCropRegion(
      preset,
      windowWidth: win.width,
      windowHeight: win.height,
    );
    if (crop == null) return null;
    return ScreenRegion(
      x: bounds.left + crop.left,
      y: bounds.top + crop.top,
      width: crop.width,
      height: crop.height,
      isAbsoluteScreen: true,
      label: 'Fokus',
    );
  }

  void _syncOverlayBorders() {
    final bridge = _effectiveNativeBridge;
    if (bridge == null) return;
    if (!widget.coordinator.settings.showScreenBorders) {
      unawaited(bridge.setScanRegionBorder(null));
      unawaited(bridge.setOverlayBorders(const []));
      return;
    }

    final multiSlots = widget.coordinator.settings.multiInstanceSlots;
    final specs = <OverlayBorderSpec>[];
    final zoneARegion = _resolveAbsoluteZoneARegion();
    if (zoneARegion != null &&
        (_customScreenRegion != null || _isScanningActive)) {
      specs.add(
        OverlayBorderSpec(
          id: 'zone_a',
          region: zoneARegion,
          colorArgb: _isScanningActive ? 0xFF10B981 : 0xFFF59E0B,
          label: multiSlots.isNotEmpty ? 'Scan #1' : 'Scan',
        ),
      );
    }

    final zoneBRegion = _resolveAbsoluteZoneBRegion();
    if (zoneBRegion != null) {
      specs.add(
        OverlayBorderSpec(
          id: 'zone_b',
          region: zoneBRegion,
          colorArgb: 0xFF06B6D4,
          label: multiSlots.isNotEmpty ? 'Fokus #1' : 'Fokus',
        ),
      );
    }

    final detector = WindowDetector();
    for (final slot in multiSlots) {
      if (!slot.enabled) continue;
      final boundWin = _resolveMultiSlotWindow(slot);

      if (slot.hasScan) {
        ScreenRegion? scanAbs;
        if (slot.scanRegion != null && slot.scanRegion!.isAbsoluteScreen) {
          scanAbs = slot.scanRegion;
        } else if (boundWin != null &&
            boundWin.bounds != null &&
            !boundWin.isDesktopScreen) {
          final crop = detector.calculateScanRegion(
            slot.scanPreset,
            windowWidth: boundWin.width,
            windowHeight: boundWin.height,
          );
          scanAbs = ScreenRegion(
            x: boundWin.bounds!.left + crop.left,
            y: boundWin.bounds!.top + crop.top,
            width: crop.width,
            height: crop.height,
            isAbsoluteScreen: true,
          );
        }
        if (scanAbs != null) {
          specs.add(
            OverlayBorderSpec(
              id: 'multi_${slot.id}_scan',
              region: scanAbs,
              colorArgb: slot.colorHex,
              label: 'Scan ${slot.label}',
            ),
          );
        }
      }

      if (slot.hasFocus) {
        ScreenRegion? focusAbs;
        if (slot.focusPreset == LiveFocusPreset.customRegion &&
            slot.focusRegion != null &&
            slot.focusRegion!.isAbsoluteScreen) {
          focusAbs = slot.focusRegion;
        } else if (slot.focusPreset != LiveFocusPreset.disabled &&
            slot.focusPreset != LiveFocusPreset.customRegion &&
            boundWin != null &&
            boundWin.bounds != null &&
            !boundWin.isDesktopScreen) {
          final crop = detector.calculateEnemyHudCropRegion(
            slot.focusPreset,
            windowWidth: boundWin.width,
            windowHeight: boundWin.height,
          );
          if (crop != null) {
            focusAbs = ScreenRegion(
              x: boundWin.bounds!.left + crop.left,
              y: boundWin.bounds!.top + crop.top,
              width: crop.width,
              height: crop.height,
              isAbsoluteScreen: true,
            );
          }
        }
        if (focusAbs != null) {
          specs.add(
            OverlayBorderSpec(
              id: 'multi_${slot.id}_focus',
              region: focusAbs,
              colorArgb: slot.colorHex,
              label: 'Fokus ${slot.label}',
            ),
          );
        }
      }
    }

    unawaited(bridge.setScanRegionBorder(null));
    unawaited(bridge.setOverlayBorders(specs));
  }

  DesktopWindowInfo? _resolveMultiSlotWindow(MultiInstanceSlot slot) {
    if (!slot.isWindowBound) return null;
    final candidates = [
      ..._windows,
      ?_selectedWindow,
    ];
    if (slot.windowHwnd != null && slot.windowHwnd != 0) {
      for (final w in candidates) {
        if (w.hwnd == slot.windowHwnd) return w;
      }
    }
    if (slot.windowId != null && slot.windowId != 0) {
      for (final w in candidates) {
        if (w.id == slot.windowId) return w;
      }
    }
    if (slot.windowTitle != null && slot.windowTitle!.isNotEmpty) {
      for (final w in candidates) {
        if (w.title == slot.windowTitle) return w;
      }
    }
    return null;
  }

  void _refreshEvolutionStatusFor(
    ScannerEvent? event,
    UserDex? activeDex,
    DexProvider dexProvider,
  ) {
    final pid = event?.pokemonId;
    if (pid == null || pid <= 0 || activeDex == null) {
      if (_activeEvolutionStatus != null) {
        setState(() => _activeEvolutionStatus = null);
      }
      DesktopTrackerService.instance.updateEvolutionStatus(null);
      return;
    }

    final dexSig =
        '${activeDex.id}:${activeDex.caughtIds.length}:${activeDex.shinyIds.length}';
    if (_lastEvoPokemonId == pid &&
        _lastEvoDexKey == dexSig &&
        _activeEvolutionStatus != null) {
      return;
    }
    _lastEvoPokemonId = pid;
    _lastEvoDexKey = dexSig;

    final byId = <int, Pokemon>{
      for (final p in dexProvider.allPokemon) p.id: p,
    };
    final target = byId[pid];
    if (target == null || target.evolutionChainId == -1) {
      setState(() => _activeEvolutionStatus = null);
      DesktopTrackerService.instance.updateEvolutionStatus(null);
      return;
    }

    final chainId = target.evolutionChainId;
    String lang = 'de';
    try {
      lang = Provider.of<SettingsProvider>(context, listen: false)
          .effectivePokemonLanguage;
    } catch (_) {
      lang = 'de';
    }
    if (_evoChainCache.containsKey(chainId)) {
      final status = EvolutionChainHelper.evaluate(
        pokemonId: pid,
        chainData: _evoChainCache[chainId],
        activeDex: activeDex,
        pokemonById: byId,
        languageCode: lang,
      );
      if (mounted) {
        setState(() => _activeEvolutionStatus = status);
      }
      DesktopTrackerService.instance.updateEvolutionStatus(status);
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
        DesktopTrackerService.instance.updateEvolutionStatus(status);
      } catch (_) {
        // Ignore in isolated widget tests without sqlite
      }
    }());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final configured = widget.coordinator.settings.ocrLanguage;
    String effectiveLang = configured;
    if (effectiveLang == 'auto') {
      try {
        final settingsProvider = Provider.of<SettingsProvider>(context);
        effectiveLang = settingsProvider.effectivePokemonLanguage;
      } catch (_) {
        effectiveLang = 'de';
      }
    }

    final mappedTag = WindowsDesktopBridge.mapPokemonLanguageToBcp47(effectiveLang);
    if (mappedTag != _ocrLanguageTag || _activeWindowSource.ocrLanguageTag != mappedTag) {
      _ocrLanguageTag = mappedTag;
      _ocrUsedFallbackLanguage = false;
      _ocrFallbackResolvedTag = null;
      _activeWindowSource.setOcrLanguageTag(mappedTag);
    }
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

  Future<void> _loadWindowsAsync() async {
    try {
      final bridge = _effectiveNativeBridge;
      final wins = bridge != null
          ? await WindowDetector(
              nativeWindowEnumerator: bridge.enumerateWindowsAndMonitors,
            ).getOpenWindowsAsync()
          : await WindowDetector().getOpenWindowsAsync();
      if (!mounted) return;
      setState(() {
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
    if (region != null) return true;
    return win != null && !win.isDesktopScreen;
  }

  void _syncAutoScanState({bool force = false}) {
    if (_hasUserToggledScan && !force) return;
    final shouldScan = _shouldAutoScan(_selectedWindow, _customScreenRegion);
    _isScanningActive = shouldScan;
    if (shouldScan) {
      widget.coordinator.start();
    } else {
      widget.coordinator.stop();
    }
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
        _syncAutoScanState();
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
    _syncAutoScanState();
    DesktopTrackerService.instance.updateHudTarget(
      window: _selectedWindow,
      screenRegion: _customScreenRegion,
    );
    if (_customScreenRegion == null &&
        _selectedWindow != null &&
        !_selectedWindow!.isDesktopScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_activeWindowSource.triggerSingleScan());
      });
    }
  }

  void _applyScanRegion(DesktopWindowInfo? window) {
    if (window == null) return;
    final region = WindowDetector().calculateScanRegion(
      _scanRegion,
      windowWidth: window.width,
      windowHeight: window.height,
    );
    _activeWindowSource.setCropRegion(region);
  }

  @override
  void dispose() {
    unawaited(_effectiveNativeBridge?.setScanRegionBorder(null));
    unawaited(_effectiveNativeBridge?.setOverlayBorders(const []));
    DesktopTrackerService.instance.showFloatingHudNotifier
        .removeListener(_onServiceHudVisibilityChanged);
    widget.coordinator.stop();
    if (widget.windowSource == null) {
      _activeWindowSource.dispose();
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
    final existing = widget.coordinator.settings.multiInstanceSlots;
    final maxId = existing.fold<int>(1, (m, s) => s.id > m ? s.id : m);
    final nextId = maxId + 1;
    final newSlot = MultiInstanceSlot(
      id: nextId,
      label: '#$nextId',
      colorHex: MultiInstanceGridHelper.colorForIndex(nextId - 2),
      scanEnabled: true,
      scanPreset: ScanRegionPreset.bottomDialogue,
      focusPreset: LiveFocusPreset.disabled,
    );
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(
        multiInstanceSlots: List.unmodifiable([...existing, newSlot]),
      ),
    );
  }

  void _updateMultiSlot(
    int slotId,
    MultiInstanceSlot Function(MultiInstanceSlot slot) updater,
  ) {
    final nextSlots = widget.coordinator.settings.multiInstanceSlots
        .map((s) => s.id == slotId ? updater(s) : s)
        .toList(growable: false);
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(
        multiInstanceSlots: List.unmodifiable(nextSlots),
      ),
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
    final nextSlots = widget.coordinator.settings.multiInstanceSlots.map((slot) {
      if (slot.id != slotId) return slot;
      if (isFocus) {
        return slot.copyWith(
          enabled: true,
          focusPreset: LiveFocusPreset.customRegion,
          focusRegion: ScreenRegion(
            x: region.x,
            y: region.y,
            width: region.width,
            height: region.height,
            isAbsoluteScreen: true,
            label: 'Fokus ${slot.label}',
          ),
        );
      }
      return slot.copyWith(
        enabled: true,
        scanEnabled: true,
        scanRegion: ScreenRegion(
          x: region.x,
          y: region.y,
          width: region.width,
          height: region.height,
          isAbsoluteScreen: true,
          label: 'Scan ${slot.label}',
        ),
      );
    }).toList(growable: false);

    setState(() {
      _snippingMultiSlotId = null;
      _snippingMultiIsFocus = false;
      _isSnippingMode = false;
      _isScanningActive = true;
      _hasUserToggledScan = false;
    });
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(
        multiInstanceSlots: List.unmodifiable(nextSlots),
      ),
    );
    widget.coordinator.start();
    unawaited(_activeWindowSource.triggerSingleScan());
  }

  void _removeMultiInstanceSlot(int slotId) {
    final nextSlots = widget.coordinator.settings.multiInstanceSlots
        .where((s) => s.id != slotId)
        .toList(growable: false);
    setState(() {});
    _updateSettingsAndPersist(
      widget.coordinator.settings.copyWith(
        multiInstanceSlots: List.unmodifiable(nextSlots),
      ),
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
      widget.coordinator.settings.copyWith(liveFocusPreset: preset),
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

  String _resolvePokemonName(DexProvider dexProvider, int pokemonId) {
    for (final p in dexProvider.allPokemon) {
      if (p.id == pokemonId) return p.nameDe;
    }
    return '#$pokemonId';
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
      _hasUserToggledScan = false;
      _syncAutoScanState(force: true);
    });
    _syncOverlayBorders();
    DesktopTrackerService.instance.updateHudTarget(
      window: window,
      screenRegion: null,
    );
    if (window != null) {
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

  bool _hasOtherCaughtEvent(
    int excludeIndex,
    int pokemonId, {
    bool requireShiny = false,
    bool requireAlpha = false,
  }) {
    for (int i = 0; i < _events.length; i++) {
      if (i == excludeIndex) continue;
      final ev = _events[i];
      if (ev.type != ScannerEventType.caught || ev.pokemonId != pokemonId) {
        continue;
      }
      if (requireShiny && !ev.isShiny) continue;
      if (requireAlpha && !ev.isAlpha) continue;
      return true;
    }
    return false;
  }

  Future<void> _correctEventAt(
    int index, {
    required int newPokemonId,
    required String newPokemonName,
    bool? isShiny,
    bool? isAlpha,
  }) async {
    if (index < 0 || index >= _events.length) return;
    final oldEvent = _events[index];
    final nextShiny = isShiny ?? oldEvent.isShiny;
    final nextAlpha = isAlpha ?? oldEvent.isAlpha;

    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final targetDex = _getActiveDex(dexProvider);

    bool addedCaught = false;
    bool addedShiny = false;
    bool addedAlpha = false;
    bool removeCaught = false;
    bool removeShiny = false;
    bool removeAlpha = false;
    bool dexMutated = false;
    final oldId = oldEvent.pokemonId;

    if (targetDex != null && oldEvent.type == ScannerEventType.caught) {
      if (oldId != null) {
        final oldIdStr = oldId.toString();
        final changingSpecies = oldId != newPokemonId;
        removeCaught = oldEvent.autoAddedCaught &&
            changingSpecies &&
            !_hasOtherCaughtEvent(index, oldId);
        removeShiny = oldEvent.autoAddedShiny &&
            (changingSpecies || !nextShiny) &&
            !_hasOtherCaughtEvent(index, oldId, requireShiny: true);
        removeAlpha = oldEvent.autoAddedAlpha &&
            (changingSpecies || !nextAlpha) &&
            !_hasOtherCaughtEvent(index, oldId, requireAlpha: true);

        if (removeCaught && targetDex.caughtIds.remove(oldIdStr)) {
          dexMutated = true;
        }
        if (removeShiny && targetDex.shinyIds.remove(oldIdStr)) {
          dexMutated = true;
        }
        if (removeAlpha && targetDex.alphaIds.remove(oldIdStr)) {
          dexMutated = true;
        }
      }

      if (widget.coordinator.settings.autoMarkCaught) {
        final newIdStr = newPokemonId.toString();
        final sameId = oldId == newPokemonId;
        addedCaught = (sameId && oldEvent.autoAddedCaught) ||
            !targetDex.caughtIds.contains(newIdStr);
        addedShiny = nextShiny &&
            ((sameId && oldEvent.autoAddedShiny) ||
                !targetDex.shinyIds.contains(newIdStr));
        addedAlpha = nextAlpha &&
            ((sameId && oldEvent.autoAddedAlpha) ||
                !targetDex.alphaIds.contains(newIdStr));

        if (!targetDex.caughtIds.contains(newIdStr)) {
          targetDex.caughtIds.add(newIdStr);
          dexMutated = true;
        }
        if (nextShiny && !targetDex.shinyIds.contains(newIdStr)) {
          targetDex.shinyIds.add(newIdStr);
          dexMutated = true;
        }
        if (nextAlpha && !targetDex.alphaIds.contains(newIdStr)) {
          targetDex.alphaIds.add(newIdStr);
          dexMutated = true;
        }
      }
    }

    if (mounted) {
      setState(() {
        _events[index] = oldEvent.copyWith(
          pokemonId: newPokemonId,
          matchedName: newPokemonName,
          isShiny: nextShiny,
          isAlpha: nextAlpha,
          autoAddedCaught: addedCaught,
          autoAddedShiny: addedShiny,
          autoAddedAlpha: addedAlpha,
        );
      });
    }

    if (targetDex != null && dexMutated) {
      if (oldId != null && (removeCaught || removeShiny || removeAlpha)) {
        try {
          await DatabaseService.instance.savePokemonStatus(
            targetDex.id,
            oldId.toString(),
            isCaught: removeCaught ? false : null,
            isShiny: removeShiny ? false : null,
            isAlpha: removeAlpha ? false : null,
          );
        } catch (_) {
          // DatabaseService might be in memory in widget tests
        }
      }
      if (widget.coordinator.settings.autoMarkCaught) {
        try {
          await DatabaseService.instance.savePokemonStatus(
            targetDex.id,
            newPokemonId.toString(),
            isCaught: true,
            isShiny: nextShiny ? true : null,
            isAlpha: nextAlpha ? true : null,
          );
        } catch (_) {
          // DatabaseService might be in memory in widget tests
        }
      }
      await dexProvider.saveUserDexAndSync(targetDex);
    }
  }

  Future<void> _deleteEventAt(int index) async {
    if (index < 0 || index >= _events.length) return;
    final oldEvent = _events[index];
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final targetDex = _getActiveDex(dexProvider);

    if (targetDex != null &&
        oldEvent.type == ScannerEventType.caught &&
        oldEvent.pokemonId != null) {
      final oldId = oldEvent.pokemonId!;
      final oldIdStr = oldId.toString();
      final removeCaught =
          oldEvent.autoAddedCaught && !_hasOtherCaughtEvent(index, oldId);
      final removeShiny = oldEvent.autoAddedShiny &&
          !_hasOtherCaughtEvent(index, oldId, requireShiny: true);
      final removeAlpha = oldEvent.autoAddedAlpha &&
          !_hasOtherCaughtEvent(index, oldId, requireAlpha: true);

      bool dexMutated = false;
      if (removeCaught && targetDex.caughtIds.remove(oldIdStr)) {
        dexMutated = true;
      }
      if (removeShiny && targetDex.shinyIds.remove(oldIdStr)) {
        dexMutated = true;
      }
      if (removeAlpha && targetDex.alphaIds.remove(oldIdStr)) {
        dexMutated = true;
      }

      setState(() {
        _events.removeAt(index);
      });

      if (dexMutated) {
        try {
          await DatabaseService.instance.savePokemonStatus(
            targetDex.id,
            oldIdStr,
            isCaught: removeCaught ? false : null,
            isShiny: removeShiny ? false : null,
            isAlpha: removeAlpha ? false : null,
          );
        } catch (_) {}
        try {
          await dexProvider.saveUserDexAndSync(targetDex);
        } catch (_) {}
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _events.removeAt(index);
    });
  }

  Future<void> _openEventCorrectionDialog(int index) async {
    if (index < 0 || index >= _events.length) return;
    final ev = _events[index];
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final allPokemon = dexProvider.allPokemon;
    final pokemonMap = <int, Pokemon>{for (final p in allPokemon) p.id: p};
    String query = '';
    bool shinyDraft = ev.isShiny;
    bool alphaDraft = ev.isAlpha;

    // Precompute Top-10 OCR probabilities once before opening dialog
    final rawRankedMap = <int, double>{};
    for (final alt in ev.alternatives) {
      final prev = rawRankedMap[alt.pokemonId] ?? 0.0;
      if (alt.confidence > prev) rawRankedMap[alt.pokemonId] = alt.confidence;
    }
    for (final fuzzy in widget.coordinator.matcher.matchTopK(
      ev.rawText,
      limit: 10,
      threshold: 0.20,
    )) {
      final prev = rawRankedMap[fuzzy.pokemonId] ?? 0.0;
      if (fuzzy.confidence > prev) {
        rawRankedMap[fuzzy.pokemonId] = fuzzy.confidence;
      }
    }
    if (ev.pokemonId != null && !rawRankedMap.containsKey(ev.pokemonId)) {
      rawRankedMap[ev.pokemonId!] = ev.confidence;
    }

    String resolveCandidateName(int id, [String? fallback]) {
      return pokemonMap[id]?.nameDe ?? fallback ?? '#$id';
    }

    final precomputedTop10 = rawRankedMap.entries
        .map((e) => (
              id: e.key,
              name: resolveCandidateName(
                e.key,
                e.key == ev.pokemonId ? ev.matchedName : null,
              ),
              confidence: e.value,
            ))
        .toList()
      ..sort((a, b) {
        final cmp = b.confidence.compareTo(a.confidence);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
    final top10List = precomputedTop10.take(10).toList(growable: false);

    await showDialog<void>(
      context: context,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              final q = query.trim().toLowerCase();
              final candidates = <({int id, String name, int? pct})>[];
              final seenIds = <int>{};

              if (q.isEmpty) {
                for (final top in top10List) {
                  if (!seenIds.add(top.id)) continue;
                  candidates.add((
                    id: top.id,
                    name: top.name,
                    pct: (top.confidence * 100).round().clamp(1, 100),
                  ));
                }
              } else {
                final fuzzySearch = widget.coordinator.matcher.matchTopK(
                  q,
                  limit: 15,
                  threshold: 0.25,
                );
                for (final fuzzy in fuzzySearch) {
                  if (!seenIds.add(fuzzy.pokemonId)) continue;
                  candidates.add((
                    id: fuzzy.pokemonId,
                    name: resolveCandidateName(fuzzy.pokemonId, fuzzy.canonicalName),
                    pct: (fuzzy.confidence * 100).round().clamp(1, 100),
                  ));
                }
                for (final Pokemon p in allPokemon) {
                  if (seenIds.contains(p.id)) continue;
                  final matchesQuery = p.nameDe.toLowerCase().contains(q) ||
                      p.nameEn.toLowerCase().contains(q) ||
                      p.id.toString().contains(q);
                  if (matchesQuery) {
                    seenIds.add(p.id);
                    final rawPct = rawRankedMap[p.id];
                    candidates.add((
                      id: p.id,
                      name: p.nameDe,
                      pct: rawPct != null
                          ? (rawPct * 100).round().clamp(1, 100)
                          : null,
                    ));
                    if (candidates.length >= 40) break;
                  }
                }
              }

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.auto_fix_high, size: 18, color: Colors.indigoAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ereignis korrigieren',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OCR: "${ev.rawText.replaceAll('\n', ' · ')}"',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Shiny ✨', style: TextStyle(fontSize: 11)),
                              selected: shinyDraft,
                              onSelected: (v) => setDialogState(() => shinyDraft = v),
                            ),
                            FilterChip(
                              label: const Text('Alpha', style: TextStyle(fontSize: 11)),
                              selected: alphaDraft,
                              onSelected: (v) => setDialogState(() => alphaDraft = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const Key('correction_search_field'),
                          onChanged: (v) => setDialogState(() => query = v),
                          decoration: InputDecoration(
                            hintText: 'Alle Pokémon durchsuchen (Name oder #ID)...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (q.isEmpty && top10List.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'TOP-10 OCR-TREFFER (NACH WAHRSCHEINLICHKEIT)',
                            key: Key('correction_top_candidates_header'),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        if (candidates.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Kein passendes Pokémon gefunden.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        else
                          ...candidates.map((cand) {
                            final isCurrent = cand.id == ev.pokemonId;
                            final pct = cand.pct;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Material(
                                color: isCurrent
                                    ? Colors.indigoAccent.withValues(alpha: 0.14)
                                    : Colors.black.withValues(alpha: 0.12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isCurrent
                                        ? Colors.indigoAccent.withValues(alpha: 0.5)
                                        : Colors.white10,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                key: Key('edit_pick_pokemon_${cand.id}'),
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    color: Colors.black26,
                                    child: Image.network(
                                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${shinyDraft ? 'shiny/' : ''}${cand.id}.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.catching_pokemon,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cand.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '#${cand.id.toString().padLeft(3, '0')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: pct != null
                                    ? Container(
                                        key: Key('correction_pct_badge_${cand.id}'),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (pct >= 70
                                                  ? Colors.green
                                                  : (pct >= 45
                                                      ? Colors.lightBlueAccent
                                                      : Colors.blueGrey))
                                              .withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$pct%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: pct >= 70
                                                ? Colors.greenAccent
                                                : (pct >= 45
                                                    ? Colors.lightBlueAccent
                                                    : Colors.grey.shade300),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right, size: 16),
                                onTap: () async {
                                  Navigator.of(dialogCtx).pop();
                                  await _correctEventAt(
                                    index,
                                    newPokemonId: cand.id,
                                    newPokemonName: cand.name,
                                    isShiny: shinyDraft,
                                    isAlpha: alphaDraft,
                                  );
                                },
                              ),
                              ),
                            );
                          }),
                        if (ev.pokemonId != null) ...[
                          const Divider(height: 18),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orangeAccent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Eigenes Team / Starter dauerhaft ignorieren?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Sperrt diese Art dauerhaft für künftige OCR-Fänge (z. B. deinen eigenen Starter im Kampfmenü).',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    key: Key('btn_ignore_team_pokemon_${ev.pokemonId}'),
                                    onPressed: () async {
                                      final targetId = ev.pokemonId!;
                                      final targetName = ev.matchedName;
                                      _ignoreTeamPokemon(
                                        targetId,
                                        displayName: targetName,
                                      );
                                      Navigator.of(dialogCtx).pop();
                                      await _deleteEventAt(index);
                                    },
                                    icon: const Icon(
                                      Icons.shield_outlined,
                                      size: 15,
                                      color: Colors.orangeAccent,
                                    ),
                                    label: Text(
                                      '${ev.matchedName} dauerhaft ignorieren',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orangeAccent,
                                      side: BorderSide(
                                        color: Colors.orangeAccent.withValues(alpha: 0.45),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogCtx).pop();
                      await _deleteEventAt(index);
                    },
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Entfernen',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Abbrechen'),
                  ),
                ],
              );
            },
          );
        },
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
      if (_isScanningActive) {
        widget.coordinator.start();
      } else {
        widget.coordinator.stop();
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
          content: Text('Windows-Snipping aktiv (Win+Shift+S): Ziehe den Bereich über deinen Desktop/Emulator!'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Try reading snippet from clipboard
    await Future.delayed(const Duration(milliseconds: 100));
    final frame = await _snippingService.captureDesktopSnippet();
    if (frame != null) {
      await _activeWindowSource.processSnippet(frame);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Desktop-Ausschnitt (${frame.width}x${frame.height} px) übernommen!'),
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
          content: Text('Screenshot (${frame.width}x${frame.height} px) aus Zwischenablage übernommen!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kein Bild in der Windows-Zwischenablage. Nutze Win+Shift+S zum Ausschneiden.'),
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

    final idStr = pokemonId.toString();
    if (!targetDex.caughtIds.contains(idStr)) {
      targetDex.caughtIds.add(idStr);
    }
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
    } catch (_) {
      // DatabaseService might be mocked or in memory in tests
    }

    await dexProvider.saveUserDexAndSync(targetDex);

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
    final dexes = dexProvider.userDexes;
    if (dexes.isEmpty) return null;
    _selectedDexId ??= dexes.first.id;
    return dexes.cast<UserDex?>().firstWhere(
          (d) => d?.id == _selectedDexId,
          orElse: () => dexes.first,
        );
  }

  void _openTargetDexModal(DexProvider dexProvider) {
    showDialog(
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
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final settings = _alertService.settings;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Color(0xFFFBC02D), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Alarm- & Signal-Einstellungen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      key: const Key('switch_sound_enabled'),
                      title: const Text('Akustische Signale (Töne)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: const Text('Spielt Signal-Töne bei Spielereignissen ab', style: TextStyle(fontSize: 11)),
                      value: settings.soundEnabled,
                      onChanged: (val) {
                        setDialogState(() {
                          _alertService.updateSettings(settings.copyWith(soundEnabled: val));
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('switch_sound_shiny'),
                      title: const Text('✨ Schillernde Pokémon (Shiny-Gong)', style: TextStyle(fontSize: 13)),
                      value: settings.soundOnShiny,
                      onChanged: settings.soundEnabled
                          ? (val) {
                              setDialogState(() {
                                _alertService.updateSettings(settings.copyWith(soundOnShiny: val));
                              });
                            }
                          : null,
                    ),
                    SwitchListTile(
                      key: const Key('switch_sound_alpha'),
                      title: const Text('🔴 Alpha- & Herrscher-Pokémon', style: TextStyle(fontSize: 13)),
                      value: settings.soundOnAlpha,
                      onChanged: settings.soundEnabled
                          ? (val) {
                              setDialogState(() {
                                _alertService.updateSettings(settings.copyWith(soundOnAlpha: val));
                              });
                            }
                          : null,
                    ),
                    SwitchListTile(
                      key: const Key('switch_sound_normal'),
                      title: const Text('⚪ Normale Fänge / Begegnungen', style: TextStyle(fontSize: 13)),
                      value: settings.soundOnNormal,
                      onChanged: settings.soundEnabled
                          ? (val) {
                              setDialogState(() {
                                _alertService.updateSettings(settings.copyWith(soundOnNormal: val));
                              });
                            }
                          : null,
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('switch_visual_glow'),
                      title: const Text('Optischer Glow & Pulsieren bei Shiny', style: TextStyle(fontSize: 13)),
                      value: settings.visualGlowEnabled,
                      onChanged: (val) {
                        setDialogState(() {
                          _alertService.updateSettings(settings.copyWith(visualGlowEnabled: val));
                        });
                      },
                    ),
                  ],
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
        );
      },
    );
  }

  void _openSettingsModal() {
    showDialog(
      context: context,
      builder: (ctx) => _TrackerSettingsDialog(
        currentPreset: _scanRegion,
        settings: widget.coordinator.settings,
        onPresetChanged: (preset) {
          _onScanRegionChanged(preset);
        },
        onSettingsChanged: (newSettings) {
          _updateSettingsAndPersist(newSettings);
          setState(() {});
        },
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'Desktop Tracker & Overlay',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (constraints.maxWidth > 220) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                            color: _isScanningActive ? Colors.green : Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isScanningActive ? 'OCR Aktiv' : 'Pausiert',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isScanningActive ? Colors.green : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (constraints.maxWidth > 360) ...[
                  const SizedBox(width: 6),
                  Container(
                    key: const Key('badge_ocr_language'),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _ocrUsedFallbackLanguage && _ocrFallbackResolvedTag != null
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
                ],
              ],
            );
          },
        ),
        actions: [
          IconButton(
            key: const Key('btn_open_floating_hud'),
            icon: Icon(
              _showFloatingHud ? Icons.picture_in_picture : Icons.picture_in_picture_alt,
              color: _showFloatingHud ? const Color(0xFFEF5350) : null,
            ),
            tooltip: _showFloatingHud ? 'Floating HUD schließen' : 'Floating HUD öffnen',
            onPressed: _toggleFloatingHud,
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
                          // Left Column: Control Panel (380px)
                          SizedBox(
                            width: 380,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildWindowControlCard(validSelectedWindow, activeDex, dexProvider, isDark, theme),
                                  const SizedBox(height: 14),
                                  _buildTargetFocusCard(latestEvent, activeDex, isDark, theme),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right Column: Live Event Feed
                          Expanded(
                            child: _buildEventFeedCard(activeDex, isDark, theme),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildWindowControlCard(validSelectedWindow, activeDex, dexProvider, isDark, theme),
                            const SizedBox(height: 14),
                            _buildTargetFocusCard(latestEvent, activeDex, isDark, theme),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 360,
                              child: _buildEventFeedCard(activeDex, isDark, theme),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
          if (_showFloatingHud && _effectiveNativeBridge == null)
            Positioned(
              left: _hudPosition.dx,
              top: _hudPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _hudPosition += details.delta;
                  });
                },
                child: FloatingOverlayHud(
                  latestEvent: latestEvent,
                  activeDex: activeDex,
                  isCompact: _hudCompact,
                  initialOpacity: _hudOpacity,
                  isPinned: _hudPinned,
                  evolutionSummary: _activeEvolutionStatus?.hudShortLabel,
                  hasMissingEvolutions:
                      _activeEvolutionStatus?.hasMissingEvolutions ?? false,
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
                ),
              ),
            ),
          if (_isSnippingMode)
            Positioned.fill(
              child: ScreenSnippingOverlay(
                targetWindow: _selectedWindow,
                desktopBackgroundBytes: _activeWindowSource.latestSnippetFrame != null
                    ? Uint8List.fromList(_activeWindowSource.latestSnippetFrame!.bytes)
                    : null,
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
                    _isSnippingMode = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWindowControlCard(
    DesktopWindowInfo? validSelectedWindow,
    UserDex? activeDex,
    DexProvider dexProvider,
    bool isDark,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scan-Quelle / Zielfenster',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                TextButton.icon(
                  key: const Key('btn_refresh_windows'),
                  onPressed: _refreshWindows,
                  icon: _isRefreshingWindows
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(
                    _isRefreshingWindows ? 'Lade...' : 'Aktualisieren',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            if (_customScreenRegion != null) ...[
              const SizedBox(height: 6),
              Container(
                key: const Key('custom_region_source_banner'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.crop_free, size: 15, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Eigener Desktop-Bereich',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '${_customScreenRegion!.width.round()}×${_customScreenRegion!.height.round()} px '
                            'bei (${_customScreenRegion!.x.round()}, ${_customScreenRegion!.y.round()})',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      key: const Key('btn_exit_custom_region'),
                      onPressed: () => _selectPresetMode(_scanRegion),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: const Text(
                        'Zu Fenster',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              InputDecorator(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DesktopWindowInfo>(
                    key: const Key('emulator_dropdown'),
                    value: validSelectedWindow,
                    isExpanded: true,
                    items: _windows.map((w) {
                      final icon = w.isKnownEmulator
                          ? '🎮'
                          : (w.isDesktopScreen ? '🖥️' : '🪟');
                      final metaParts = <String>[
                        if (!w.isDesktopScreen &&
                            w.processName != null &&
                            w.processName!.isNotEmpty)
                          w.processName!,
                        '${w.width.round()}×${w.height.round()}',
                        if (w.isMinimized) 'minimiert',
                      ];
                      return DropdownMenuItem<DesktopWindowInfo>(
                        value: w,
                        child: Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: w.isKnownEmulator
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              flex: 0,
                              child: Text(
                                metaParts.join(' · '),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _onWindowSelected,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Target Dex Preview Card (Replacing old dropdown)
            _buildTargetDexCard(activeDex, dexProvider, isDark, theme),

            const SizedBox(height: 10),

            // Scan Region Section (Full Window vs Dialogue vs Live-OCR Snipping)
            _buildScanRegionSection(isDark, theme),

            const SizedBox(height: 10),

            // Quick Actions: Launch Floating HUD
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('btn_launch_floating_hud'),
                    onPressed: _toggleFloatingHud,
                    icon: Icon(
                      _showFloatingHud ? Icons.picture_in_picture : Icons.picture_in_picture_alt,
                      size: 16,
                      color: const Color(0xFFEF5350),
                    ),
                    label: Text(
                      _showFloatingHud ? 'HUD schließen' : 'Floating HUD öffnen',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: const BorderSide(color: Color(0xFFEF5350)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('btn_scan_now'),
                    onPressed: _triggerManualScan,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text(
                      'Jetzt scannen',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: _toggleScanning,
                    icon: Icon(_isScanningActive ? Icons.pause : Icons.play_arrow, size: 16),
                    label: Text(
                      _isScanningActive ? 'Pausieren' : 'Fortsetzen',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetDexCard(UserDex? activeDex, DexProvider dexProvider, bool isDark, ThemeData theme) {
    final cleanedWords = activeDex != null && activeDex.title.isNotEmpty
        ? activeDex.title
            .split(RegExp(r'\s+'))
            .map((w) => w.replaceAll(RegExp(r'[^A-Za-z0-9ÄÖÜäöüß]'), ''))
            .where((w) => w.isNotEmpty)
            .toList()
        : const <String>[];
    final initials = cleanedWords.isNotEmpty
        ? cleanedWords.take(2).map((w) => w[0]).join().toUpperCase()
        : 'DX';
    final stats = activeDex != null
        ? DexLogicHelper.computeDexProgress(
            activeDex,
            allPokemon: dexProvider.allPokemon,
          )
        : const TrackerDexProgress(caughtCount: 0, totalCount: 1025, percent: 0.0);
    final caughtCount = stats.caughtCount;
    final totalCount = stats.totalCount;
    final percent = stats.percent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'ZIEL-POKÉDEX',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
              ),
            ),
            Flexible(
              child: TextButton(
                key: const Key('btn_change_target_dex'),
                onPressed: () => _openTargetDexModal(dexProvider),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
                child: const Text(
                  'Dex wechseln →',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('card_active_target_dex'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openTargetDexModal(dexProvider),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                activeDex?.title ?? 'Kein Dex ausgewählt',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${(percent * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 4,
                            backgroundColor: isDark ? Colors.black38 : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$caughtCount von $totalCount gefangen',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectPresetMode(ScanRegionPreset preset) {
    setState(() {
      _customScreenRegion = null;
      _snippetPreviewBytes = null;
      _scanRegion = preset;
      _activeWindowSource.setScreenRegion(null);
      _applyScanRegion(_selectedWindow);
      _hasUserToggledScan = false;
      _syncAutoScanState(force: true);
    });
    _syncOverlayBorders();
    DesktopTrackerService.instance.updateHudTarget(
      window: _selectedWindow,
      screenRegion: null,
    );
    if (_shouldAutoScan(_selectedWindow, null)) {
      unawaited(_activeWindowSource.triggerSingleScan());
    }
  }

  Widget _buildScanPresetButton({
    required Key buttonKey,
    required ScanRegionPreset preset,
    required bool isSelected,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        key: buttonKey,
        onPressed: () => _selectPresetMode(preset),
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFFEF5350).withValues(alpha: 0.15) : null,
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFEF5350)
                : (isDark ? Colors.white24 : Colors.black12),
          ),
          foregroundColor: isSelected
              ? const Color(0xFFEF5350)
              : (isDark ? Colors.white : Colors.black87),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildInfoToggleButton({
    required Key buttonKey,
    required bool isOpen,
    required Color accentColor,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            isOpen ? Icons.info : Icons.info_outline,
            size: 14,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineInfoBanner({
    required Key boxKey,
    required Color accentColor,
    required bool isDark,
    required String title,
    required String body,
  }) {
    return Container(
      key: boxKey,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: TextStyle(
              fontSize: 10,
              height: 1.35,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanRegionSection(bool isDark, ThemeData theme) {
    final hasCustomRegion = _customScreenRegion != null;
    final isFull = !hasCustomRegion && _scanRegion == ScanRegionPreset.fullWindow;
    final isDialogue = !hasCustomRegion && _scanRegion == ScanRegionPreset.bottomDialogue;
    final isDsTop = !hasCustomRegion && _scanRegion == ScanRegionPreset.dsTopScreen;
    final isDsBottom = !hasCustomRegion && _scanRegion == ScanRegionPreset.dsBottomScreen;

    String modeLabel;
    if (hasCustomRegion) {
      modeLabel =
          '${_customScreenRegion!.width.round()}×${_customScreenRegion!.height.round()} px';
    } else if (isFull) {
      modeLabel = 'Ganzes Fenster (100%)';
    } else if (isDsTop) {
      modeLabel = 'DS Oben (Top-Screen 50%)';
    } else if (isDsBottom) {
      modeLabel = 'DS Unten (Touchscreen 50%)';
    } else {
      modeLabel = 'Textbox unten (30%)';
    }

    final showBorders = widget.coordinator.settings.showScreenBorders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Global Desktop Border Visibility Switch (#4)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: showBorders
                  ? Colors.cyanAccent.withValues(alpha: 0.45)
                  : (isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(
                showBorders ? Icons.visibility : Icons.visibility_off_outlined,
                size: 15,
                color: showBorders ? Colors.cyanAccent : Colors.grey,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Farbige Bildschirm-Rahmen anzeigen',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Switch.adaptive(
                key: const Key('switch_screen_borders'),
                value: showBorders,
                onChanged: _toggleScreenBorders,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        // ZONE A: Symmetrical Card Matching Zone B Design (#2)
        Container(
          key: const Key('scan_zone_a_card'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.crop_din,
                          size: 14,
                          color: Colors.greenAccent,
                        ),
                        const Text(
                          'SCAN-BEREICH (ZONE A)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GRÜN · TEXTBOX',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                        _buildInfoToggleButton(
                          buttonKey: const Key('btn_info_zone_a'),
                          isOpen: _showZoneAInfo,
                          accentColor: Colors.greenAccent,
                          tooltip: 'Info zu Scan-Bereich (Zone A)',
                          onPressed: () =>
                              setState(() => _showZoneAInfo = !_showZoneAInfo),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      key: const Key('label_active_scan_mode'),
                      modeLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_showZoneAInfo)
                _buildInlineInfoBanner(
                  boxKey: const Key('info_box_zone_a'),
                  accentColor: Colors.greenAccent,
                  isDark: isDark,
                  title: 'Wofür ist Scan-Bereich (Zone A)?',
                  body:
                      'Haupt-Scan-Zone für Spieltexte (z. B. Dialogbox unten). '
                      'Erkennt Fänge, Entwicklungen und wilde Begegnungen und '
                      'trägt gefangene Pokémon automatisch in deinen Ziel-Dex ein.',
                ),
              if (!hasCustomRegion) ...[
                const SizedBox(height: 8),
                Column(
                  children: [
                    Row(
                      children: [
                        _buildScanPresetButton(
                          buttonKey: const Key('btn_scan_mode_full'),
                          preset: ScanRegionPreset.fullWindow,
                          isSelected: isFull,
                          icon: Icons.fullscreen,
                          label: 'Ganzes Fenster',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildScanPresetButton(
                          buttonKey: const Key('btn_scan_mode_dialogue'),
                          preset: ScanRegionPreset.bottomDialogue,
                          isSelected: isDialogue,
                          icon: Icons.chat_bubble_outline,
                          label: 'Textbox unten',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildScanPresetButton(
                          buttonKey: const Key('btn_scan_mode_ds_top'),
                          preset: ScanRegionPreset.dsTopScreen,
                          isSelected: isDsTop,
                          icon: Icons.vertical_align_top,
                          label: 'DS Oben (Top)',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildScanPresetButton(
                          buttonKey: const Key('btn_scan_mode_ds_bottom'),
                          preset: ScanRegionPreset.dsBottomScreen,
                          isSelected: isDsBottom,
                          icon: Icons.vertical_align_bottom,
                          label: 'DS Unten (Touch)',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
        if (!hasCustomRegion &&
            (_selectedWindow?.isDesktopScreen ?? false) &&
            !_isScanningActive) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Wähle ein Emulator-Fenster oder markiere einen Live-OCR-Bereich auf dem Desktop.',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasCustomRegion || _selectedWindow != null) ...[
          const SizedBox(height: 8),
          ValueListenableBuilder<LiveOcrScanStatus>(
            valueListenable: _activeWindowSource.liveScanStatusNotifier,
            builder: (context, scanStatus, _) {
              final isMonitor =
                  !hasCustomRegion && (_selectedWindow?.isDesktopScreen ?? false);
              final accentColor = _isScanningActive ? Colors.green : Colors.amber;
              final statusText = hasCustomRegion
                  ? (_isScanningActive ? 'LIVE-OCR AKTIV' : 'LIVE-OCR PAUSIERT')
                  : isMonitor
                      ? (_isScanningActive
                          ? 'LIVE-OCR ÜBERWACHT MONITOR'
                          : 'MONITOR-VORSCHAU · PAUSIERT')
                      : (_isScanningActive
                          ? 'LIVE-OCR ÜBERWACHT FENSTER'
                          : 'FENSTER-VORSCHAU PAUSIERT');
              final recognized = scanStatus.previewText;
              final activeCrop = _activeWindowSource.cropRegion;
              final metaText = hasCustomRegion
                  ? '(${_customScreenRegion!.x.round()}, ${_customScreenRegion!.y.round()}) · '
                      '${_customScreenRegion!.width.round()}×${_customScreenRegion!.height.round()} px'
                  : '${_selectedWindow!.title} · '
                      '${(activeCrop?.width ?? _selectedWindow!.width).round()}×'
                      '${(activeCrop?.height ?? _selectedWindow!.height).round()} px';
              final intervalMs = widget.coordinator.settings.scanIntervalMs;
              final intervalLabel = intervalMs >= 1000
                  ? '${(intervalMs / 1000).toStringAsFixed(1)}s'
                  : '${intervalMs}ms';
              return Container(
                key: Key(
                  hasCustomRegion
                      ? 'desktop_snippet_preview_card'
                      : 'active_scan_preview_card',
                ),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.45)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showEnlargedPreview(
                        liveFrame: scanStatus.latestFrame,
                        fallbackPng: hasCustomRegion ? _snippetPreviewBytes : null,
                        title: metaText,
                      ),
                      child: Tooltip(
                        message: 'Live-Bild vergrößern',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 68,
                            height: 44,
                            color: Colors.black38,
                            child: _LiveFrameThumbnail(
                              liveFrame: scanStatus.latestFrame,
                              fallbackPngBytes:
                                  hasCustomRegion ? _snippetPreviewBytes : null,
                              fallbackIcon: hasCustomRegion
                                  ? Icons.crop
                                  : (isMonitor
                                      ? Icons.monitor
                                      : Icons.desktop_windows),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  scanStatus.scanCount > 0
                                      ? '$statusText · #${scanStatus.scanCount}'
                                      : statusText,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metaText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recognized.isNotEmpty
                                ? 'OCR: $recognized'
                                : (isMonitor && !_isScanningActive
                                    ? 'Vorschau ohne Auto-OCR (↻ aktualisieren)'
                                    : 'Warte auf Text (alle $intervalLabel)...'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: recognized.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMonitor)
                      IconButton(
                        key: const Key('btn_refresh_monitor_preview'),
                        tooltip: 'Monitor-Vorschau aktualisieren',
                        icon: const Icon(Icons.refresh, size: 16),
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            unawaited(_activeWindowSource.capturePreviewOnly()),
                      ),
                    if (hasCustomRegion)
                      IconButton(
                        key: const Key('btn_reset_snippet'),
                        tooltip: 'Bereich zurücksetzen',
                        icon: const Icon(Icons.close, size: 16),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _selectPresetMode(_scanRegion),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('btn_start_snipping'),
            onPressed: _handleStartSnipping,
            icon: const Icon(Icons.crop_free, size: 15, color: Colors.greenAccent),
            label: Text(
              hasCustomRegion
                  ? 'Scan-Bereich neu zeichnen'
                  : 'Scan-Bereich frei zeichnen',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: BorderSide(
                color: hasCustomRegion
                    ? Colors.greenAccent
                    : (isDark ? Colors.white24 : Colors.black26),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildLiveFocusZoneBar(isDark),
        const SizedBox(height: 10),
        _buildMultiInstanceCard(isDark),
        const SizedBox(height: 10),
        _buildRefreshRateAndPatternsBar(isDark),
      ],
    );
  }

  Widget _buildMultiInstanceCard(bool isDark) {
    final slots = widget.coordinator.settings.multiInstanceSlots;
    final activeCount = slots.where((s) => s.enabled).length;
    return Container(
      key: const Key('multi_instance_card'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slots.isNotEmpty
              ? const Color(0xFFA855F7).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFFA855F7)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'MULTI-INSTANZEN',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${activeCount + 1} aktiv',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA855F7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Zone A/B oben = Instanz #1 · Weitere Instanzen frei mit Scan/Fokus oder Fenster koppeln:',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                key: const Key('btn_multi_add_instance'),
                onPressed: _addMultiInstanceSlot,
                icon: const Icon(Icons.add_box_outlined, size: 13),
                label: Text(
                  '+ Instanz #${slots.fold<int>(1, (m, s) => s.id > m ? s.id : m) + 1}',
                  style: const TextStyle(fontSize: 10),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              if (slots.isNotEmpty)
                TextButton(
                  key: const Key('btn_multi_clear'),
                  onPressed: _clearMultiInstanceSlots,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Alle löschen', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
          if (slots.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...slots.map((slot) => _buildSingleMultiInstanceSlotCard(slot, isDark)),
          ],
        ],
      ),
    );
  }

  String _multiWindowValueForWindow(DesktopWindowInfo w) {
    return w.hwnd != 0 ? 'hwnd:${w.hwnd}' : 'id:${w.id}';
  }

  Widget _buildSingleMultiInstanceSlotCard(
    MultiInstanceSlot slot,
    bool isDark,
  ) {
    final color = Color(slot.colorHex);
    final openApps = _windows.where((w) => !w.isDesktopScreen).toList();
    String selectedWinVal = '';
    if (slot.isWindowBound) {
      if (slot.windowHwnd != null && slot.windowHwnd != 0) {
        selectedWinVal = 'hwnd:${slot.windowHwnd}';
      } else if (slot.windowId != null && slot.windowId != 0) {
        selectedWinVal = 'id:${slot.windowId}';
      }
    }

    final dropdownItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text(
          'Freie Bereiche (ohne festes Fenster)',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10),
        ),
      ),
      ...openApps.map((w) {
        return DropdownMenuItem<String>(
          value: _multiWindowValueForWindow(w),
          child: Text(
            '${w.title} (${w.width.round()}×${w.height.round()})',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        );
      }),
    ];
    if (selectedWinVal.isNotEmpty &&
        !dropdownItems.any((item) => item.value == selectedWinVal)) {
      dropdownItems.add(
        DropdownMenuItem<String>(
          value: selectedWinVal,
          child: Text(
            slot.windowTitle ?? 'Gebundenes Fenster',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
    }

    final roleSummary = switch ((slot.hasScan, slot.hasFocus)) {
      (true, true) => 'Scan + Fokus',
      (true, false) => 'Nur Scan',
      (false, true) => 'Nur Fokus',
      (false, false) => 'Bereich wählen',
    };

    return Container(
      key: Key('multi_instance_card_${slot.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191924) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: slot.enabled ? 0.65 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: 9,
                child: Text(
                  '${slot.id}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instanz ${slot.label}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      roleSummary,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: slot.enabled,
                  activeThumbColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => _updateMultiSlot(
                    slot.id,
                    (s) => s.copyWith(enabled: v),
                  ),
                ),
              ),
              IconButton(
                key: Key('btn_multi_remove_${slot.id}'),
                tooltip: 'Instanz entfernen',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.close, size: 14),
                onPressed: () => _removeMultiInstanceSlot(slot.id),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InputDecorator(
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              prefixIcon: const Icon(Icons.desktop_windows_outlined, size: 13),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 28, minHeight: 24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: Key('dropdown_multi_window_${slot.id}'),
                value: selectedWinVal,
                isExpanded: true,
                isDense: true,
                items: dropdownItems,
                onChanged: (val) {
                  if (val == null || val.isEmpty) {
                    _updateMultiSlot(
                      slot.id,
                      (s) => s.copyWith(clearWindow: true),
                    );
                    return;
                  }
                  DesktopWindowInfo? chosen;
                  for (final w in openApps) {
                    if (_multiWindowValueForWindow(w) == val) {
                      chosen = w;
                      break;
                    }
                  }
                  if (chosen != null) {
                    _updateMultiSlot(
                      slot.id,
                      (s) => s.copyWith(
                        enabled: true,
                        windowHwnd: chosen!.hwnd,
                        windowId: chosen.id,
                        windowTitle: chosen.title,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Scan #N paired controls
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 22,
                child: Switch(
                  key: Key('switch_multi_scan_${slot.id}'),
                  value: slot.scanEnabled,
                  activeThumbColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => _updateMultiSlot(
                    slot.id,
                    (s) => s.copyWith(scanEnabled: v),
                  ),
                ),
              ),
              Text(
                'Scan ${slot.label}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              OutlinedButton.icon(
                key: Key('btn_multi_draw_scan_${slot.id}'),
                onPressed: () =>
                    _startMultiSlotSnipping(slot.id, isFocus: false),
                icon: const Icon(Icons.crop_free, size: 12),
                label: Text(
                  slot.scanRegion != null ? 'Scan neu' : 'Scan zeichnen',
                  style: const TextStyle(fontSize: 9),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.55)),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
              if (slot.scanRegion != null)
                InputChip(
                  label: Text(
                    '${slot.scanRegion!.width.round()}×${slot.scanRegion!.height.round()}',
                    style: const TextStyle(fontSize: 9),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () => _updateMultiSlot(
                    slot.id,
                    (s) => s.copyWith(clearScanRegion: true),
                  ),
                ),
            ],
          ),
          if (slot.scanEnabled &&
              slot.scanRegion == null &&
              slot.isWindowBound) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: ScanRegionPreset.values.map((preset) {
                final selected = slot.scanPreset == preset;
                return ChoiceChip(
                  label: Text(preset.labelDe, style: const TextStyle(fontSize: 9)),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => _updateMultiSlot(
                    slot.id,
                    (s) => s.copyWith(scanPreset: preset),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 4),
          // Fokus #N paired controls
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.center_focus_strong, size: 13, color: color),
              Text(
                'Fokus ${slot.label}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              OutlinedButton.icon(
                key: Key('btn_multi_draw_focus_${slot.id}'),
                onPressed: () =>
                    _startMultiSlotSnipping(slot.id, isFocus: true),
                icon: const Icon(Icons.crop_free, size: 12),
                label: Text(
                  slot.focusRegion != null ? 'Fokus neu' : 'Fokus zeichnen',
                  style: const TextStyle(fontSize: 9),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.55)),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
              if (slot.focusPreset == LiveFocusPreset.customRegion &&
                  slot.focusRegion != null)
                InputChip(
                  label: Text(
                    '${slot.focusRegion!.width.round()}×${slot.focusRegion!.height.round()}',
                    style: const TextStyle(fontSize: 9),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () => _updateMultiSlot(
                    slot.id,
                    (s) => s.copyWith(
                      focusPreset: LiveFocusPreset.disabled,
                      clearFocusRegion: true,
                    ),
                  ),
                ),
            ],
          ),
          if (slot.isWindowBound) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: const [
                LiveFocusPreset.disabled,
                LiveFocusPreset.topLeft,
                LiveFocusPreset.topRight,
                LiveFocusPreset.topBanner,
              ].map((preset) {
                final selected = slot.focusPreset == preset;
                return ChoiceChip(
                  label: Text(preset.labelDe, style: const TextStyle(fontSize: 9)),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => _updateMultiSlot(
                    slot.id,
                    (s) => s.copyWith(focusPreset: preset),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveFocusZoneBar(bool isDark) {
    final activeFocusPreset = widget.coordinator.settings.liveFocusPreset;
    final focusRegion = _activeWindowSource.liveFocusScreenRegion;
    final ignoredIds = widget.coordinator.settings.ignoredPokemonIds;
    final dexProvider = Provider.of<DexProvider>(context, listen: false);

    const presetOptions = <({LiveFocusPreset preset, String label})>[
      (preset: LiveFocusPreset.disabled, label: 'Aus'),
      (preset: LiveFocusPreset.topLeft, label: '↖ Oben Links'),
      (preset: LiveFocusPreset.topRight, label: '↗ Oben Rechts'),
      (preset: LiveFocusPreset.topBanner, label: '▭ Oberer Streifen'),
    ];

    return Container(
      key: const Key('scan_zone_b_card'),
      child: Container(
        key: const Key('live_focus_zone_panel'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeFocusPreset != LiveFocusPreset.disabled
                ? Colors.cyanAccent.withValues(alpha: 0.55)
                : (isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.center_focus_strong, size: 14, color: Colors.cyanAccent),
                const Text(
                  'LIVE-FOKUS-ZONE (ZONE B)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TÜRKIS · NUR ENCOUNTER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
                _buildInfoToggleButton(
                  buttonKey: const Key('btn_info_zone_b'),
                  isOpen: _showZoneBInfo,
                  accentColor: Colors.cyanAccent,
                  tooltip: 'Info zu Live-Fokus-Zone (Zone B)',
                  onPressed: () =>
                      setState(() => _showZoneBInfo = !_showZoneBInfo),
                ),
              ],
            ),
            if (_showZoneBInfo)
              _buildInlineInfoBanner(
                boxKey: const Key('info_box_zone_b'),
                accentColor: Colors.cyanAccent,
                isDark: isDark,
                title: 'Wofür ist Live-Fokus-Zone (Zone B)?',
                body:
                    'Liest nur den Gegnernamen oben im Kampf-HUD (z. B. oben '
                    'links/rechts oder frei markiert) als Begegnung — perfekt '
                    'für Live-Fokus und Mehrfachbegegnungen, ohne eigene Pokémon '
                    'oder Teammitglieder als gefangen zu werten.',
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: presetOptions.map((opt) {
              final selected = activeFocusPreset == opt.preset;
              return ChoiceChip(
                key: Key('focus_preset_${opt.preset.name}'),
                label: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                onSelected: (_) => _selectLiveFocusPreset(opt.preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('btn_live_focus_snipping'),
              onPressed: _handleStartLiveFocusSnipping,
              icon: const Icon(Icons.crop_free, size: 14, color: Colors.cyanAccent),
              label: Text(
                activeFocusPreset == LiveFocusPreset.customRegion &&
                        focusRegion != null
                    ? 'Fokus-Bereich neu zeichnen'
                    : 'Live-Fokus-Bereich frei zeichnen',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                side: BorderSide(
                  color: activeFocusPreset == LiveFocusPreset.customRegion
                      ? Colors.cyanAccent
                      : (isDark ? Colors.white24 : Colors.black26),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (activeFocusPreset != LiveFocusPreset.disabled) ...[
            const SizedBox(height: 6),
            ValueListenableBuilder<LiveOcrScanStatus>(
              valueListenable: _activeWindowSource.liveFocusStatusNotifier,
              builder: (context, focusStatus, _) {
                final text = focusStatus.previewText;
                return Row(
                  children: [
                    if (_focusSnippetPreviewBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          _focusSnippetPreviewBytes!,
                          width: 32,
                          height: 20,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        text.isNotEmpty
                            ? 'Zone B: $text'
                            : 'Zone B aktiv (${activeFocusPreset.labelDe})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                    if (activeFocusPreset == LiveFocusPreset.customRegion)
                      IconButton(
                        tooltip: 'Fokus-Bereich deaktivieren',
                        icon: const Icon(Icons.close, size: 14),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () =>
                            _selectLiveFocusPreset(LiveFocusPreset.disabled),
                      ),
                  ],
                );
              },
            ),
          ],
          if (ignoredIds.isNotEmpty) ...[
            const Divider(height: 14),
            const Text(
              'IGNORIERTE TEAM-POKÉMON (STARTER-SCHUTZ)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ignoredIds.map((id) {
                final label = _resolvePokemonName(dexProvider, id);
                return InputChip(
                  key: Key('ignored_pokemon_chip_$id'),
                  avatar: const Icon(Icons.shield, size: 13, color: Colors.orangeAccent),
                  label: Text(
                    '$label (#$id)',
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () => _unignoreTeamPokemon(id),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildRefreshRateAndPatternsBar(bool isDark) {
    final currentIntervalMs = widget.coordinator.settings.scanIntervalMs;
    final currentProfile = widget.coordinator.settings.preprocessProfile;
    final activePatternsCount =
        widget.coordinator.settings.customPatterns.where((p) => p.enabled).length;
    const rateOptions = <({int ms, String label})>[
      (ms: 250, label: '250 ms'),
      (ms: 400, label: '400 ms'),
      (ms: 750, label: '750 ms'),
      (ms: 1200, label: '1.2 s'),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 14, color: Colors.deepPurpleAccent),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'SCAN-PROFIL',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildInfoToggleButton(
                buttonKey: const Key('btn_info_scan_profile'),
                isOpen: _showScanProfileInfo,
                accentColor: Colors.deepPurpleAccent,
                tooltip: 'Info zu den Scan-Profilen',
                onPressed: () =>
                    setState(() => _showScanProfileInfo = !_showScanProfileInfo),
              ),
            ],
          ),
          if (_showScanProfileInfo)
            _buildInlineInfoBanner(
              boxKey: const Key('info_box_scan_profile'),
              accentColor: Colors.deepPurpleAccent,
              isDark: isDark,
              title: 'Bild-Optimierung pro Quelle',
              body:
                  '• Standard: Für scharfe PC- oder HD-Fenster.\n'
                  '• Pixel-Art (DS): Schärft & skaliert pixelige DS-/GBA-Texte (z. B. melonDS, Gen 4/5).\n'
                  '• Kamera / Display: Erhöht Kontrast für blasse oder abgefilmte Bildschirme.',
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: OcrPreprocessProfile.values.map((profile) {
              final selected = currentProfile == profile;
              return ChoiceChip(
                key: Key('profile_${profile.name}'),
                label: Text(
                  profile.labelDe,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                onSelected: (_) => _updatePreprocessProfile(profile),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.speed, size: 14, color: Colors.blueAccent),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'OCR-SCAN-RATE',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                currentIntervalMs >= 1000
                    ? '${(currentIntervalMs / 1000).toStringAsFixed(1)} s'
                    : '$currentIntervalMs ms',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rateOptions.map((opt) {
              final selected = currentIntervalMs == opt.ms;
              return ChoiceChip(
                key: Key('refresh_rate_${opt.ms}'),
                label: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                onSelected: (_) => _updateScanInterval(opt.ms),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('btn_custom_patterns'),
              onPressed: _openCustomPatternsDialog,
              icon: const Icon(Icons.auto_fix_high, size: 15, color: Colors.amber),
              label: Text(
                'Eigene OCR-Muster ($activePatternsCount)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildTargetFocusCard(
    ScannerEvent? event,
    UserDex? activeDex,
    bool isDark,
    ThemeData theme,
  ) {
    final focusEvents = _activeFocusEvents.isNotEmpty
        ? _activeFocusEvents
        : (event != null ? [event] : const <ScannerEvent>[]);
    final isMultiEncounter = focusEvents.length > 1;
    final singleEvent = focusEvents.length == 1 ? focusEvents.first : event;
    final id = singleEvent?.pokemonId;
    final name = singleEvent?.matchedName ?? 'Warte auf Spiel...';
    final isCaught = activeDex != null &&
        id != null &&
        DexLogicHelper.isPokemonCaught(activeDex, id.toString());
    final isShiny = singleEvent?.isShiny ?? false;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Aktueller Live-Fokus',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                if (isMultiEncounter)
                  Container(
                    key: const Key('badge_multi_encounter'),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MEHRFACHBEGEGNUNG (${focusEvents.length})',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  )
                else if (singleEvent != null)
                  Text(
                    singleEvent.type.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: singleEvent.type == ScannerEventType.caught
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isMultiEncounter)
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 290
                      ? (constraints.maxWidth - 8) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: focusEvents.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ev = entry.value;
                      final enemyId = ev.pokemonId;
                      final enemyCaught = activeDex != null &&
                          enemyId != null &&
                          DexLogicHelper.isPokemonCaught(
                            activeDex,
                            enemyId.toString(),
                          );
                      return SizedBox(
                        width: cardWidth,
                        child: Container(
                          key: Key('focus_enemy_card_${enemyId ?? idx}'),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF242432)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: enemyCaught
                                  ? Colors.green.withValues(alpha: 0.35)
                                  : Colors.amber.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1B1B24)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: enemyId != null && enemyId > 0
                                          ? Image.network(
                                              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${ev.isShiny ? 'shiny/' : ''}$enemyId.png',
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(Icons.pets, size: 18),
                                            )
                                          : const Icon(Icons.search, size: 18, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                ev.matchedName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (ev.isShiny) ...[
                                              const SizedBox(width: 3),
                                              const Text('✨', style: TextStyle(fontSize: 11)),
                                            ],
                                          ],
                                        ),
                                        if (enemyId != null)
                                          Text(
                                            '#${enemyId.toString().padLeft(3, '0')}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: enemyCaught
                                      ? Colors.green.withValues(alpha: 0.14)
                                      : Colors.amber.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  enemyCaught ? '✓ Im Dex' : '★ Fehlt!',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: enemyCaught ? Colors.green : Colors.amber,
                                  ),
                                ),
                              ),
                              if (enemyId != null) ...[
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    key: Key('btn_mark_focus_caught_$enemyId'),
                                    onPressed: () => _markPokemonCaughtInDex(
                                      enemyId,
                                      isShiny: ev.isShiny,
                                      isAlpha: ev.isAlpha,
                                    ),
                                    icon: const Icon(Icons.add, size: 13),
                                    label: const Text(
                                      'Eintragen',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF343444) : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1B24) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: id != null && id > 0
                            ? Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${isShiny ? 'shiny/' : ''}$id.png',
                                errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 28),
                              )
                            : const Icon(Icons.search, size: 28, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isShiny) ...[
                                const SizedBox(width: 4),
                                const Text('✨', style: TextStyle(fontSize: 14)),
                              ],
                            ],
                          ),
                          if (id != null)
                            Text(
                              '#${id.toString().padLeft(3, '0')}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCaught
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCaught
                                    ? Colors.green.withValues(alpha: 0.4)
                                    : Colors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isCaught ? '✓ Im Ziel-Dex gefangen' : '★ Fehlt im Ziel-Dex!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCaught ? Colors.green : Colors.amber,
                              ),
                            ),
                          ),
                          if (singleEvent?.instanceIndex != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(singleEvent!.instanceColorHex ?? 0xFFA855F7)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Instanz #${singleEvent.instanceIndex}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (_activeEvolutionStatus != null &&
                              _activeEvolutionStatus!.hasEvolutions &&
                              _activeEvolutionStatus!.pokemonId == id) ...[
                            const SizedBox(height: 4),
                            Container(
                              key: const Key('focus_evolution_status_badge'),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: (_activeEvolutionStatus!.hasMissingEvolutions
                                        ? Colors.cyanAccent
                                        : Colors.greenAccent)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _activeEvolutionStatus!.summaryLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: _activeEvolutionStatus!.hasMissingEvolutions
                                      ? Colors.cyanAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (singleEvent != null && singleEvent.alternatives.length > 1) ...[
                const Text(
                  'SMART-ALTERNATIVEN (ANTIPPEN ZUM WECHSELN)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: singleEvent.alternatives.map((alt) {
                    final isCurrent = alt.pokemonId == id;
                    return ActionChip(
                      avatar: Icon(
                        isCurrent ? Icons.check_circle : Icons.swap_horiz,
                        size: 13,
                      ),
                      label: Text(
                        '${alt.canonicalName} ${(alt.confidence * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: isCurrent
                          ? null
                          : () => _correctEventAt(
                                0,
                                newPokemonId: alt.pokemonId,
                                newPokemonName: alt.canonicalName,
                              ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (id != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('btn_mark_caught_in_dex'),
                    onPressed: () => _markPokemonCaughtInDex(
                      id,
                      isShiny: isShiny,
                      isAlpha: singleEvent?.isAlpha ?? false,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      'In "${activeDex?.title ?? "Dex"}" eintragen',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEnlargedPreview({
    required CapturedFrame? liveFrame,
    required Uint8List? fallbackPng,
    required String title,
  }) {
    if (liveFrame == null && fallbackPng == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 640,
          height: 360,
          child: Container(
            color: Colors.black,
            child: _LiveFrameThumbnail(
              liveFrame: liveFrame,
              fallbackPngBytes: fallbackPng,
              fallbackIcon: Icons.crop_free,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventFeedCard(UserDex? activeDex, bool isDark, ThemeData theme) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 18),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Live-Ereignisse',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_events.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_events.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _events.clear()),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Leeren', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.catching_pokemon, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Warte auf In-Game Ereignisse...',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Wähle dein Emulator-Fenster aus. Fänge und Begegnungen werden automatisch erkannt.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ev = _events[index];
                        final isCaught = activeDex != null &&
                            ev.pokemonId != null &&
                            activeDex.caughtIds.contains(ev.pokemonId.toString());

                        return _buildEventTile(ev, index, isCaught, isDark, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(
    ScannerEvent ev,
    int index,
    bool isCaught,
    bool isDark,
    ThemeData theme,
  ) {
    final id = ev.pokemonId;
    final isShiny = ev.isShiny;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF343444) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B24) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: id != null && id > 0
                  ? Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${isShiny ? 'shiny/' : ''}$id.png',
                      errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 20),
                    )
                  : const Icon(Icons.help_outline, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      ev.matchedName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (ev.instanceIndex != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Color(ev.instanceColorHex ?? 0xFFA855F7)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '#${ev.instanceIndex}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (isShiny) const Text('✨'),
                    _buildEventTypeBadge(ev.type),
                    if (ev.isSmartMatch)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'SMART ${(ev.confidence * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ev.rawText.replaceAll('\n', ' · '),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                key: Key('btn_edit_event_$index'),
                tooltip: 'Ereignis korrigieren',
                onPressed: () => _openEventCorrectionDialog(index),
                icon: const Icon(Icons.edit_outlined, size: 16),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              if (id != null)
                isCaught
                    ? const Text(
                        '✓ Im Dex',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _markPokemonCaughtInDex(
                          id,
                          isShiny: isShiny,
                          isAlpha: ev.isAlpha,
                        ),
                        child: const Text(
                          '+ Eintragen',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeBadge(ScannerEventType type) {
    Color bg;
    Color fg;
    String label;

    switch (type) {
      case ScannerEventType.caught:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green;
        label = 'FANG';
        break;
      case ScannerEventType.encounter:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        label = 'BEGEGNUNG';
        break;
      case ScannerEventType.evolved:
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        label = 'ENTWICKLUNG';
        break;
      case ScannerEventType.shinyDetected:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber;
        label = 'SHINY';
        break;
      case ScannerEventType.alphaDetected:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red;
        label = 'ALPHA';
        break;
      case ScannerEventType.unknown:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = 'INFO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

/// Target Dex Selection Modal with search, progress bar, and clean Material 3 design.
class _TargetDexSelectionSheet extends StatefulWidget {
  final List<UserDex> dexes;
  final String? selectedDexId;
  final ValueChanged<String> onSelect;

  const _TargetDexSelectionSheet({
    required this.dexes,
    required this.selectedDexId,
    required this.onSelect,
  });

  @override
  State<_TargetDexSelectionSheet> createState() => _TargetDexSelectionSheetState();
}

class _TargetDexSelectionSheetState extends State<_TargetDexSelectionSheet> {
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = widget.dexes.where((d) {
      if (_filterQuery.isEmpty) return true;
      return d.title.toLowerCase().contains(_filterQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.book, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ziel-Pokédex auswählen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('dex_search_input'),
            decoration: InputDecoration(
              hintText: 'Nach Pokédex suchen...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF242432) : Colors.grey.shade100,
            ),
            onChanged: (q) => setState(() => _filterQuery = q),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Keine Pokédexe gefunden', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dex = filtered[index];
                      final isSelected = dex.id == widget.selectedDexId;
                      final stats = DexLogicHelper.computeDexProgress(dex);
                      final total = stats.totalCount;
                      final caught = stats.caughtCount;
                      final progress = stats.percent;

                      return Card(
                        key: Key('dex_item_${dex.id}'),
                        elevation: 0,
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF242432) : Colors.grey.shade50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? const Color(0xFF343444) : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => widget.onSelect(dex.id),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dex.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$caught von $total gefangen',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDark ? const Color(0xFF1B1B24) : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      isSelected ? theme.colorScheme.primary : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tracker settings dialog configuring scan region presets, polling intervals, and auto-catch options.
class _TrackerSettingsDialog extends StatefulWidget {
  final ScanRegionPreset currentPreset;
  final ScannerSettings settings;
  final ValueChanged<ScanRegionPreset> onPresetChanged;
  final ValueChanged<ScannerSettings> onSettingsChanged;

  const _TrackerSettingsDialog({
    required this.currentPreset,
    required this.settings,
    required this.onPresetChanged,
    required this.onSettingsChanged,
  });

  @override
  State<_TrackerSettingsDialog> createState() => _TrackerSettingsDialogState();
}

class _TrackerSettingsDialogState extends State<_TrackerSettingsDialog> {
  late ScanRegionPreset _preset;
  late bool _autoMark;
  late String _ocrLanguage;

  @override
  void initState() {
    super.initState();
    _preset = widget.currentPreset;
    _autoMark = widget.settings.autoMarkCaught;
    _ocrLanguage = widget.settings.ocrLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Tracker-Einstellungen', style: TextStyle(fontSize: 16)),
            ],
          ),
          IconButton(
            key: const Key('btn_close_settings'),
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scanbereich (Fensterbereich)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Wähle welcher Teil des Emulatorfensters per OCR abgetastet werden soll:',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              RadioGroup<ScanRegionPreset>(
                groupValue: _preset,
                onChanged: (p) {
                  if (p != null) {
                    setState(() => _preset = p);
                    widget.onPresetChanged(p);
                  }
                },
                child: Column(
                  children: [
                    _buildPresetOption(
                      key: 'preset_full_window',
                      preset: ScanRegionPreset.fullWindow,
                      title: 'Ganzes Fenster (Empfohlen für DS & Multi-Screen)',
                      subtitle: 'Scannt das gesamte Spielfenster (100%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_top_screen',
                      preset: ScanRegionPreset.dsTopScreen,
                      title: 'Oberer DS-Bildschirm (DS-Kämpfe & Dialoge)',
                      subtitle: 'Scannt oberen Bildschirm (0-52%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_bottom_screen',
                      preset: ScanRegionPreset.dsBottomScreen,
                      title: 'Unterer DS-Bildschirm (Touchscreen)',
                      subtitle: 'Scannt unteren Bildschirm (48-100%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_bottom_dialogue',
                      preset: ScanRegionPreset.bottomDialogue,
                      title: 'Klassische Textbox (GBA / 3DS unten)',
                      subtitle: 'Scannt Textbox am unteren Fensterrand (70-100%)',
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              SwitchListTile(
                key: const Key('switch_auto_mark_caught'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Automatisch eintragen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                  'Erkannte Fänge direkt ohne Klick im Ziel-Dex speichern',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                value: _autoMark,
                onChanged: (val) {
                  setState(() => _autoMark = val);
                  widget.onSettingsChanged(widget.settings.copyWith(autoMarkCaught: val));
                },
              ),
              const Divider(height: 24),
              const Text(
                'OCR-Sprache (Spieltext-Erkennung)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: const Key('dropdown_desktop_ocr_language'),
                initialValue: kSupportedScannerOcrLanguages
                        .any((o) => o.code == _ocrLanguage)
                    ? _ocrLanguage
                    : 'auto',
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: kSupportedScannerOcrLanguages
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.code,
                        child: Text(o.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _ocrLanguage = val);
                  widget.onSettingsChanged(
                    widget.settings.copyWith(ocrLanguage: val),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetOption({
    required String key,
    required ScanRegionPreset preset,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      key: Key(key),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Radio<ScanRegionPreset>(
        value: preset,
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      onTap: () {
        setState(() => _preset = preset);
        widget.onPresetChanged(preset);
      },
    );
  }
}

/// Renders either encoded PNG preview bytes or raw BGRA8888 [CapturedFrame] pixels.
class _LiveFrameThumbnail extends StatefulWidget {
  final CapturedFrame? liveFrame;
  final Uint8List? fallbackPngBytes;
  final IconData fallbackIcon;

  const _LiveFrameThumbnail({
    required this.liveFrame,
    required this.fallbackPngBytes,
    required this.fallbackIcon,
  });

  @override
  State<_LiveFrameThumbnail> createState() => _LiveFrameThumbnailState();
}

class _LiveFrameThumbnailState extends State<_LiveFrameThumbnail> {
  ui.Image? _decodedImage;
  CapturedFrame? _lastDecodedFrame;

  @override
  void initState() {
    super.initState();
    _maybeDecodeFrame();
  }

  @override
  void didUpdateWidget(covariant _LiveFrameThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.liveFrame, oldWidget.liveFrame)) {
      _maybeDecodeFrame();
    }
  }

  void _maybeDecodeFrame() {
    final frame = widget.liveFrame;
    if (frame == null || identical(frame, _lastDecodedFrame)) return;
    _lastDecodedFrame = frame;

    if (frame.pixelFormat == 'bgra8888' &&
        frame.width > 0 &&
        frame.height > 0 &&
        frame.bytes.length >= frame.width * frame.height * 4) {
      final rawBytes = frame.bytes is Uint8List
          ? frame.bytes as Uint8List
          : Uint8List.fromList(frame.bytes);
      ui.decodeImageFromPixels(
        rawBytes,
        frame.width,
        frame.height,
        ui.PixelFormat.bgra8888,
        (image) {
          if (!mounted || !identical(widget.liveFrame, frame)) {
            image.dispose();
            return;
          }
          final prev = _decodedImage;
          setState(() {
            _decodedImage = image;
          });
          prev?.dispose();
        },
      );
    } else if (_decodedImage != null) {
      final prev = _decodedImage;
      _decodedImage = null;
      prev?.dispose();
    }
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    _decodedImage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.liveFrame;
    if (frame != null && frame.pixelFormat == 'png' && frame.bytes.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(frame.bytes),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(widget.fallbackIcon, size: 18, color: Colors.white54),
      );
    }
    if (_decodedImage != null) {
      return RawImage(
        image: _decodedImage,
        fit: BoxFit.contain,
      );
    }
    if (widget.fallbackPngBytes != null && widget.fallbackPngBytes!.isNotEmpty) {
      return Image.memory(
        widget.fallbackPngBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(widget.fallbackIcon, size: 18, color: Colors.white54),
      );
    }
    return Center(
      child: Icon(widget.fallbackIcon, size: 18, color: Colors.white54),
    );
  }
}
