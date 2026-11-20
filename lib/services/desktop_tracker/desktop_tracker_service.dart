import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../scanner_core/models/scanner_event.dart';
import '../scanner_core/scanner_coordinator.dart';
import 'desktop_window_source.dart';
import 'evolution_chain_helper.dart';
import 'screen_region.dart';
import 'window_detector.dart';
import 'windows_desktop_bridge.dart';

/// Central singleton service coordinating background desktop tracker sessions,
/// streaming live events to both the full setup screen, persistent dock bars,
/// and floating overlay HUDs across PokéVault.
class DesktopTrackerService {
  static final DesktopTrackerService _instance =
      DesktopTrackerService._internal();
  factory DesktopTrackerService() => _instance;
  static DesktopTrackerService get instance => _instance;

  DesktopTrackerService._internal();

  ScannerCoordinator? _coordinator;
  DesktopWindowSource? _windowSource;
  String? _activeDexId;
  StreamSubscription<ScannerEvent>? _eventSubscription;
  DesktopPlatformBridge? _nativeBridge;
  ScreenRegion? _activeScreenRegion;
  Uint8List? _activeSnippetPreview;
  DesktopWindowInfo? _activeWindow;
  bool _hudCompact = false;
  bool _hudPinned = true;
  double _hudOpacity = 0.92;
  String _evolutionSummary = '';
  bool _hasMissingEvolutions = false;
  bool _ownsWindowSource = false;
  List<OverlayBorderSpec> _activeOverlayBorders = const [];
  bool Function(int pokemonId)? _isCaughtChecker;
  Future<void> Function(ScannerEvent event)? _onHudMarkCaughtCallback;
  Future<void> Function(ScannerEvent event)? _onBackgroundAutoCatchCallback;
  final List<ScannerEvent> _recentEvents = [];

  List<ScannerEvent> get recentEvents => List.unmodifiable(_recentEvents);

  final ValueNotifier<ScannerEvent?> latestEventNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> showFloatingHudNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier(false);

  ScannerCoordinator? get coordinator => _coordinator;
  DesktopWindowSource? get windowSource => _windowSource;
  String? get activeDexId => _activeDexId;
  ScannerEvent? get latestEvent => latestEventNotifier.value;
  bool get isTrackingActive => isTrackingNotifier.value;
  bool get showFloatingHud => showFloatingHudNotifier.value;
  bool get isPaused => isPausedNotifier.value;
  ScreenRegion? get activeScreenRegion => _activeScreenRegion;
  Uint8List? get activeSnippetPreview => _activeSnippetPreview;
  DesktopWindowInfo? get activeWindow => _activeWindow;

  set isPaused(bool value) {
    isPausedNotifier.value = value;
  }

  void setActiveDexId(String? dexId) {
    _activeDexId = dexId;
    _syncNativeHudIfVisible();
  }

  void configureNativeHudBridge({
    DesktopPlatformBridge? bridge,
    bool Function(int pokemonId)? isCaughtChecker,
    Future<void> Function(ScannerEvent event)? onMarkCaught,
  }) {
    _nativeBridge = bridge;
    if (isCaughtChecker != null) {
      _isCaughtChecker = isCaughtChecker;
    }
    if (onMarkCaught != null) {
      _onHudMarkCaughtCallback = onMarkCaught;
    }
    if (bridge != null) {
      bridge.onHudAction = _handleNativeHudAction;
    }
  }

  void configureBackgroundHandlers({
    bool Function(int pokemonId)? isCaughtChecker,
    Future<void> Function(ScannerEvent event)? onMarkCaught,
    Future<void> Function(ScannerEvent event)? onBackgroundAutoCatch,
  }) {
    if (isCaughtChecker != null) {
      _isCaughtChecker = isCaughtChecker;
    }
    if (onMarkCaught != null) {
      _onHudMarkCaughtCallback = onMarkCaught;
    }
    _onBackgroundAutoCatchCallback = onBackgroundAutoCatch;
    _syncNativeHudIfVisible();
  }

  void recordUiEvent(ScannerEvent event) {
    if (_recentEvents.isEmpty || _recentEvents.first != event) {
      _recentEvents.insert(0, event);
      if (_recentEvents.length > 50) {
        _recentEvents.removeLast();
      }
    }
  }

  bool get hasMarkCaughtHandler => _onHudMarkCaughtCallback != null;

  Future<void> markLatestEventCaught() async {
    final ev = latestEventNotifier.value;
    if (ev != null && _onHudMarkCaughtCallback != null) {
      await _onHudMarkCaughtCallback!(ev);
      _syncNativeHudIfVisible();
    }
  }

  void updateHudTarget({
    DesktopWindowInfo? window,
    ScreenRegion? screenRegion,
    Uint8List? snippetPreview,
  }) {
    _activeWindow = window;
    _activeScreenRegion = screenRegion;
    if (screenRegion == null) {
      _activeSnippetPreview = null;
    } else if (snippetPreview != null) {
      _activeSnippetPreview = snippetPreview;
    }
    _syncNativeHudIfVisible();
  }

  void updateHudPresentation({
    bool? isCompact,
    bool? isPinned,
    double? opacity,
  }) {
    if (isCompact != null) _hudCompact = isCompact;
    if (isPinned != null) _hudPinned = isPinned;
    if (opacity != null) _hudOpacity = opacity;
    _syncNativeHudIfVisible();
  }

  Rect? resolveHudAnchorRect() {
    if (_activeScreenRegion != null && _activeScreenRegion!.isAbsoluteScreen) {
      return _activeScreenRegion!.toRect();
    }
    return _activeWindow?.bounds;
  }

  void updateEvolutionStatus(EvolutionCheckStatus? status) {
    final nextSummary = status?.hudShortLabel ?? '';
    final nextMissing = status?.hasMissingEvolutions ?? false;
    if (_evolutionSummary == nextSummary &&
        _hasMissingEvolutions == nextMissing) {
      return;
    }
    _evolutionSummary = nextSummary;
    _hasMissingEvolutions = nextMissing;
    _syncNativeHudIfVisible();
  }

  NativeHudState buildNativeHudState() {
    final ev = latestEventNotifier.value;
    final pid = ev?.pokemonId;
    final isCaught =
        pid != null && _isCaughtChecker != null ? _isCaughtChecker!(pid) : false;

    return NativeHudState(
      pokemonName: ev?.matchedName ?? 'Warte auf Spiel...',
      pokemonId: pid,
      isShiny: ev?.isShiny ?? false,
      isCaught: isCaught,
      isCompact: _hudCompact,
      isPinned: _hudPinned,
      opacity: _hudOpacity,
      hasEvent: ev != null,
      anchorRect: resolveHudAnchorRect(),
      evolutionSummary: _evolutionSummary,
      hasMissingEvolutions: _hasMissingEvolutions,
      instanceLabel:
          ev?.instanceIndex != null ? '#${ev!.instanceIndex}' : null,
    );
  }

  void startTracking({
    required ScannerCoordinator coordinator,
    DesktopWindowSource? windowSource,
    String? dexId,
    bool ownsWindowSource = false,
  }) {
    final previousSource = _windowSource;
    final previouslyOwned = _ownsWindowSource;
    _coordinator = coordinator;
    _windowSource = windowSource;
    _activeDexId = dexId;
    _ownsWindowSource = ownsWindowSource;

    if (previousSource != null &&
        !identical(previousSource, windowSource) &&
        previouslyOwned) {
      unawaited(previousSource.dispose());
    }

    _eventSubscription?.cancel();
    _eventSubscription = coordinator.events.listen(handleScannerEvent);

    isTrackingNotifier.value = true;
    isPausedNotifier.value = false;
  }

  void handleScannerEvent(ScannerEvent event) {
    recordUiEvent(event);
    latestEventNotifier.value = event;
    if (_onBackgroundAutoCatchCallback != null) {
      _onBackgroundAutoCatchCallback!(event)
          .then((_) => _syncNativeHudIfVisible());
    } else {
      _syncNativeHudIfVisible();
    }
  }

  Future<void> setFloatingHudVisible(bool visible) async {
    showFloatingHudNotifier.value = visible;
    final bridge = _nativeBridge;
    if (bridge == null) return;
    if (visible) {
      await bridge.showFloatingHud(buildNativeHudState());
    } else {
      await bridge.hideFloatingHud();
    }
  }

  void toggleFloatingHud() {
    setFloatingHudVisible(!showFloatingHudNotifier.value);
  }

  void _syncNativeHudIfVisible() {
    final bridge = _nativeBridge;
    if (bridge == null || !showFloatingHudNotifier.value) return;
    bridge.updateFloatingHud(buildNativeHudState());
  }

  void _handleNativeHudAction(NativeHudAction action) {
    switch (action.type) {
      case NativeHudActionType.close:
        showFloatingHudNotifier.value = false;
        break;
      case NativeHudActionType.compactChanged:
        if (action.boolValue != null) {
          _hudCompact = action.boolValue!;
        }
        break;
      case NativeHudActionType.pinnedChanged:
        if (action.boolValue != null) {
          _hudPinned = action.boolValue!;
        }
        break;
      case NativeHudActionType.markCaught:
        final ev = latestEventNotifier.value;
        if (ev != null && _onHudMarkCaughtCallback != null) {
          _onHudMarkCaughtCallback!(ev).then((_) => _syncNativeHudIfVisible());
        }
        break;
      case NativeHudActionType.moved:
        break;
    }
  }

  void updateOverlayBorders(List<OverlayBorderSpec> borders) {
    _activeOverlayBorders = List.unmodifiable(borders);
  }

  void togglePause() {
    isPausedNotifier.value = !isPausedNotifier.value;
    final paused = isPausedNotifier.value;
    if (paused) {
      _coordinator?.stop();
    } else {
      _coordinator?.start();
    }
    if (_activeOverlayBorders.isNotEmpty) {
      final syncedBorders = paused
          ? _activeOverlayBorders
              .map(
                (b) => OverlayBorderSpec(
                  id: b.id,
                  region: b.region,
                  colorArgb: 0xFFF59E0B,
                  label: b.label.isEmpty ? 'Pause' : '${b.label} (Pause)',
                  visible: b.visible,
                ),
              )
              .toList(growable: false)
          : _activeOverlayBorders;
      _nativeBridge?.setOverlayBorders(syncedBorders);
    } else if (_activeScreenRegion != null) {
      _nativeBridge?.setScanRegionBorder(
        _activeScreenRegion,
        active: !paused,
      );
    }
    _syncNativeHudIfVisible();
  }

  Future<void> stopTracking() async {
    final bridge = _nativeBridge;
    final eventSub = _eventSubscription;
    final coordinator = _coordinator;
    final windowSource = _windowSource;
    final shouldDisposeSource = _ownsWindowSource;

    _nativeBridge = null;
    _isCaughtChecker = null;
    _onHudMarkCaughtCallback = null;
    _onBackgroundAutoCatchCallback = null;
    _eventSubscription = null;
    _coordinator = null;
    _windowSource = null;
    _ownsWindowSource = false;
    _activeDexId = null;
    _activeOverlayBorders = const [];
    _recentEvents.clear();
    _activeScreenRegion = null;
    _activeSnippetPreview = null;
    _activeWindow = null;

    isTrackingNotifier.value = false;
    isPausedNotifier.value = false;
    showFloatingHudNotifier.value = false;
    latestEventNotifier.value = null;

    try {
      await bridge?.hideFloatingHud();
      await bridge?.setScanRegionBorder(null);
      await bridge?.setOverlayBorders(const []);
    } catch (_) {}

    await eventSub?.cancel();
    await coordinator?.stop();
    if (shouldDisposeSource) {
      await windowSource?.dispose();
    }
  }
}
