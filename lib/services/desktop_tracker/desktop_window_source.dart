import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../scanner_core/media/frame_band_cropper.dart';
import '../scanner_core/media/frame_transition_detector.dart';
import '../scanner_core/models/scanner_settings.dart';
import '../scanner_core/source/scanner_source.dart';
import 'desktop_capture_driver.dart';
import 'desktop_ocr_driver.dart';
import 'screen_region.dart';
import 'window_detector.dart';
import 'windows_desktop_bridge.dart';

/// Live telemetry emitted by [DesktopWindowSource] on every OCR scan cycle.
class LiveOcrScanStatus {
  final int scanCount;
  final DateTime? lastScanAt;
  final List<String> recognizedLines;
  final CapturedFrame? latestFrame;

  const LiveOcrScanStatus({
    this.scanCount = 0,
    this.lastScanAt,
    this.recognizedLines = const [],
    this.latestFrame,
  });

  String get previewText => recognizedLines.join(' · ');
}

/// Temporary diagnostic log entry for investigating OCR & capture behavior.
class OcrScanLogEntry {
  final int scanNumber;
  final DateTime timestamp;
  final String sourceMode;
  final String targetDescription;
  final int frameWidth;
  final int frameHeight;
  final String pixelFormat;
  final String captureMethod;
  final String frameBrightnessSummary;
  final int captureDurationMs;
  final int ocrDurationMs;
  final String requestedLanguage;
  final String resolvedLanguage;
  final bool usedFallbackLanguage;
  final List<String> availableLanguages;
  final List<String> rawLines;
  final bool ocrSucceeded;
  final String? errorHint;
  final String preprocessProfile;

  const OcrScanLogEntry({
    required this.scanNumber,
    required this.timestamp,
    required this.sourceMode,
    required this.targetDescription,
    required this.frameWidth,
    required this.frameHeight,
    required this.pixelFormat,
    required this.captureMethod,
    required this.frameBrightnessSummary,
    required this.captureDurationMs,
    required this.ocrDurationMs,
    required this.requestedLanguage,
    required this.resolvedLanguage,
    required this.usedFallbackLanguage,
    required this.availableLanguages,
    required this.rawLines,
    this.ocrSucceeded = true,
    this.errorHint,
    this.preprocessProfile = 'standard',
  });

  /// Formats this scan entry into a compact multi-line block for clipboard sharing.
  String toFormattedText({List<String>? parserNotes}) {
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    final ss = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    final avail = availableLanguages.isEmpty
        ? 'unknown'
        : availableLanguages.join(', ');
    final linesRepr = rawLines.isEmpty
        ? '<NONE>'
        : rawLines.map((l) => '"$l"').join(' | ');
    final buf = StringBuffer()
      ..writeln(
        '[$hh:$mm:$ss.$ms] #$scanNumber | mode=$sourceMode ($targetDescription) | '
        'profile=$preprocessProfile | capMethod=$captureMethod | '
        'frame=${frameWidth}x$frameHeight $pixelFormat | '
        '$frameBrightnessSummary | cap=${captureDurationMs}ms ocr=${ocrDurationMs}ms',
      )
      ..writeln(
        '  lang: req=${requestedLanguage.isEmpty ? "auto" : requestedLanguage} -> '
        'res=${resolvedLanguage.isEmpty ? "auto" : resolvedLanguage} '
        '(fallback=$usedFallbackLanguage, ok=$ocrSucceeded, avail=[$avail])'
        '${errorHint != null && errorHint!.isNotEmpty ? " err=$errorHint" : ""}',
      )
      ..write('  rawLines (${rawLines.length}): $linesRepr');
    if (parserNotes != null && parserNotes.isNotEmpty) {
      buf.write('\n  parser: ${parserNotes.join(' | ')}');
    }
    return buf.toString();
  }
}

/// Computes sampled luminance / non-black stats for diagnosing blank or dark frames.
String computeFrameBrightnessSummary(CapturedFrame frame) {
  if (frame.width <= 0 || frame.height <= 0) return 'empty-dims';
  if (frame.pixelFormat != 'bgra8888') {
    return 'fmt=${frame.pixelFormat} (${frame.bytes.length}B)';
  }
  final expectedBytes = frame.width * frame.height * 4;
  if (frame.bytes.length < expectedBytes || expectedBytes < 4) {
    return 'short-buf (${frame.bytes.length}/$expectedBytes B)';
  }

  final totalPixels = frame.width * frame.height;
  final step = totalPixels > 2400 ? totalPixels ~/ 1200 : 1;
  int minLuma = 255;
  int maxLuma = 0;
  int sumLuma = 0;
  int nonBlack = 0;
  int sampled = 0;

  for (int px = 0; px < totalPixels; px += step) {
    final off = px * 4;
    final b = frame.bytes[off];
    final g = frame.bytes[off + 1];
    final r = frame.bytes[off + 2];
    final luma = ((r * 299 + g * 587 + b * 114) ~/ 1000).clamp(0, 255);
    if (luma < minLuma) minLuma = luma;
    if (luma > maxLuma) maxLuma = luma;
    if (luma > 5) nonBlack++;
    sumLuma += luma;
    sampled++;
  }
  if (sampled == 0) return 'no-samples';
  final avg = sumLuma ~/ sampled;
  final pct = ((nonBlack * 100) / sampled).round();
  if (maxLuma <= 2) {
    return 'luma=0..$maxLuma ALL_BLACK (nonBlack=0%)';
  }
  return 'luma=$minLuma..$maxLuma avg=$avg nonBlack=$pct%';
}

/// Computes a fast, deterministic pixel-content fingerprint over evenly sampled pixels
/// using an odd pixel stride so small localized text changes never fall between
/// stride intervals and identical static frames skip expensive OCR.
int computeFrameFingerprint(CapturedFrame frame) {
  final bytes = frame.bytes;
  int hash = 2166136261;
  hash = ((hash ^ frame.width) * 16777619) & 0x7FFFFFFF;
  hash = ((hash ^ frame.height) * 16777619) & 0x7FFFFFFF;
  hash = ((hash ^ bytes.length) * 16777619) & 0x7FFFFFFF;
  if (bytes.isEmpty) return hash;

  if (bytes.length < 4) {
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash ^ bytes[i]) * 16777619) & 0x7FFFFFFF;
    }
    return hash;
  }

  final totalPixels = bytes.length ~/ 4;
  final pixelStep = totalPixels <= 2048 ? 1 : ((totalPixels ~/ 2048) | 1);
  for (int px = 0; px < totalPixels; px += pixelStep) {
    final off = px * 4;
    final rgb = bytes[off] | (bytes[off + 1] << 8) | (bytes[off + 2] << 16);
    hash = ((hash ^ rgb) * 16777619) & 0x7FFFFFFF;
  }
  for (int i = totalPixels * 4; i < bytes.length; i++) {
    hash = ((hash ^ bytes[i]) * 16777619) & 0x7FFFFFFF;
  }
  // Always mix first & last byte so small single-line bottom/top shifts are caught
  hash = ((hash ^ bytes.first) * 16777619) & 0x7FFFFFFF;
  hash = ((hash ^ bytes.last) * 16777619) & 0x7FFFFFFF;
  return hash;
}

/// Periodic window capture source that grabs frames from a chosen desktop window,
/// crops the dialogue/textbox area (Zone A) plus an optional opponent HUD (Zone B)
/// and Multi-Instance slots, runs local OCR only on changed frames, and feeds streams.
class DesktopWindowSource
    implements
        DualZoneScannerSource,
        MultiInstanceScannerSource,
        FrameTransitionScannerSource,
        VisualFrameScannerSource {
  final DesktopCaptureDriver captureDriver;
  final DesktopOcrDriver ocrDriver;
  final DesktopPlatformBridge? nativeBridge;
  final Duration Function()? elapsedClock;
  Duration _pollInterval;

  DesktopWindowInfo? _selectedWindow;
  Rect? _cropRegion;
  ScreenRegion? _screenRegion;
  LiveFocusPreset _liveFocusPreset = LiveFocusPreset.disabled;
  ScreenRegion? _liveFocusScreenRegion;
  List<ScreenRegion> _extraFocusRegions = const [];
  CapturedFrame? _latestSnippetFrame;
  String? _ocrLanguageTag;
  OcrPreprocessProfile _preprocessProfile = OcrPreprocessProfile.standard;
  Timer? _pollTimer;
  bool _running = false;
  bool _scanInFlight = false;
  bool _disposed = false;

  // Native fast-path preview throttling & self-window masking state
  final Stopwatch _previewClock = Stopwatch()..start();
  bool _previewEnabled = true;
  int _previewMaxWidth = 320;
  Duration? _lastThumbnailRequestedAt;
  Duration? _lastFocusThumbnailRequestedAt;
  bool _maskSelfWindow = false;
  bool _forceNextNativeOcr = false;
  int _cacheGeneration = 0;

  bool get isDisposed => _disposed;
  bool get maskSelfWindow => _maskSelfWindow;
  bool get previewEnabled => _previewEnabled;
  int get previewMaxWidth => _previewMaxWidth;

  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<String> _focusTextController =
      StreamController<String>.broadcast();
  final StreamController<MultiInstanceTextEmission> _multiTextController =
      StreamController<MultiInstanceTextEmission>.broadcast();
  final StreamController<FrameTransitionEvent> _transitionController =
      StreamController<FrameTransitionEvent>.broadcast();
  final StreamController<SlotVisualFrame> _visualFrameController =
      StreamController<SlotVisualFrame>.broadcast();
  final FrameTransitionDetector _transitionDetector;
  final ValueNotifier<LiveOcrScanStatus> liveScanStatusNotifier =
      ValueNotifier(const LiveOcrScanStatus());
  final ValueNotifier<LiveOcrScanStatus> liveFocusStatusNotifier =
      ValueNotifier(const LiveOcrScanStatus());
  final ValueNotifier<Map<String, String>> focusBoxPreviewsNotifier =
      ValueNotifier(const {});
  final ValueNotifier<Map<String, CapturedFrame>> focusBoxFramesNotifier =
      ValueNotifier(const {});
  final ValueNotifier<List<OcrScanLogEntry>> scanLogsNotifier =
      ValueNotifier(const []);
  final ValueNotifier<bool> selfWindowOverlapNotifier = ValueNotifier(false);
  static const int _maxScanLogs = 40;
  static final RegExp _focusCandidateWordRegex = RegExp(
    r'(?:^|[\s♂♀✨])[A-Za-zÀ-ÿ]{5,}(?=$|[\s♂♀✨])',
  );
  static final RegExp _focusCandidateCjkRegex = RegExp(
    r'[\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]{2,}',
  );
  int _scanCounter = 0;
  int _focusScanCounter = 0;

  // Frame fingerprint caches (Zero-Lag static frame OCR deduplication)
  int? _lastZoneAFingerprint;
  int? _lastZoneBFingerprint;
  final Map<int, int> _lastExtraZoneBFingerprints = {};
  final Map<String, List<String>> _cachedFocusLinesByBox = {};
  final Map<String, CapturedFrame> _latestFocusFramesByBox = {};
  final Map<int, int> _lastSlotScanFingerprints = {};
  final Map<int, int> _lastSlotFocusFingerprints = {};
  List<MultiInstanceSlot> _multiInstanceSlots = const [];
  List<DesktopWindowInfo> _knownWindows = const [];

  DesktopWindowSource({
    required this.captureDriver,
    required this.ocrDriver,
    this.nativeBridge,
    this.elapsedClock,
    Duration? pollInterval,
  })  : _pollInterval = pollInterval ?? const Duration(milliseconds: 400),
        _transitionDetector = FrameTransitionDetector(elapsedClock: elapsedClock);

  Duration get _nowElapsed => elapsedClock?.call() ?? _previewClock.elapsed;

  /// Controls whether native fast-path transfers downscaled thumbnail PNGs
  /// (disabled = 0-byte image transfer in background / Shiny-Tracker mode).
  void setPreviewPolicy({required bool enabled, int maxWidth = 320}) {
    final clampedWidth = maxWidth.clamp(64, 1920);
    final changed =
        _previewEnabled != enabled || _previewMaxWidth != clampedWidth;
    final upgraded = enabled && (!_previewEnabled || clampedWidth > _previewMaxWidth);
    _previewEnabled = enabled;
    _previewMaxWidth = clampedWidth;
    if (changed && upgraded) {
      _lastThumbnailRequestedAt = null;
      _lastFocusThumbnailRequestedAt = null;
    }
  }

  void _invalidateNativeScanCache() {
    _forceNextNativeOcr = true;
    _cacheGeneration++;
    if (nativeBridge != null) {
      unawaited(nativeBridge!.clearNativeScanCache());
    }
  }

  /// Controls whether PokéVault's own window rectangle is masked black during desktop region OCR.
  void setMaskSelfWindow(bool enabled) {
    if (_maskSelfWindow == enabled) return;
    _maskSelfWindow = enabled;
    _lastZoneAFingerprint = null;
    _lastZoneBFingerprint = null;
    _lastExtraZoneBFingerprints.clear();
    _lastSlotScanFingerprints.clear();
    _lastSlotFocusFingerprints.clear();
    _invalidateNativeScanCache();
    if (enabled) {
      selfWindowOverlapNotifier.value = false;
    }
  }

  bool _shouldRequestThumbnail({bool force = false}) {
    if (!_previewEnabled) return false;
    final now = _nowElapsed;
    if (force || _lastThumbnailRequestedAt == null) {
      _lastThumbnailRequestedAt = now;
      return true;
    }
    if (now - _lastThumbnailRequestedAt! >= const Duration(milliseconds: 1000)) {
      _lastThumbnailRequestedAt = now;
      return true;
    }
    return false;
  }

  bool _shouldRequestFocusThumbnail({bool force = false}) {
    if (!_previewEnabled) return false;
    final now = _nowElapsed;
    if (force || _lastFocusThumbnailRequestedAt == null) {
      _lastFocusThumbnailRequestedAt = now;
      return true;
    }
    if (now - _lastFocusThumbnailRequestedAt! >=
        const Duration(milliseconds: 1000)) {
      _lastFocusThumbnailRequestedAt = now;
      return true;
    }
    return false;
  }

  NativeCaptureAnalyzeRequest? _buildNativeRequest({
    required DesktopWindowInfo window,
    required Rect? cropRegion,
    required ScreenRegion? screenRegion,
    required String slotKey,
    required bool forceOcr,
    required bool computeColorHistogram,
    required bool includeThumbnail,
    bool multiBandFallback = false,
    bool skipOcr = false,
  }) {
    final String mode;
    int hwnd = 0;
    Rect? effectiveCrop;
    ScreenRegion? effectiveScreen;

    if (screenRegion != null && screenRegion.isAbsoluteScreen) {
      mode = 'region';
      effectiveScreen = screenRegion;
    } else if (window.isDesktopScreen) {
      final targetRect =
          window.bounds ?? Rect.fromLTWH(0, 0, window.width, window.height);
      final absRect = cropRegion != null
          ? Rect.fromLTWH(
              targetRect.left + cropRegion.left,
              targetRect.top + cropRegion.top,
              cropRegion.width,
              cropRegion.height,
            )
          : targetRect;
      mode = 'region';
      effectiveScreen = ScreenRegion.fromRect(absRect, isAbsoluteScreen: true);
    } else if (window.hwnd > 0 && !window.isMinimized) {
      mode = 'window';
      hwnd = window.hwnd;
      effectiveCrop = cropRegion;
    } else {
      return null;
    }

    return NativeCaptureAnalyzeRequest(
      mode: mode,
      hwnd: hwnd,
      cropRegion: effectiveCrop,
      screenRegion: effectiveScreen,
      slotKey: slotKey,
      forceOcr: forceOcr,
      languageTag: _ocrLanguageTag,
      preprocessProfile: _preprocessProfile.name,
      maskSelfWindow: _maskSelfWindow,
      computeColorHistogram: computeColorHistogram,
      includeThumbnail: includeThumbnail,
      thumbnailMaxWidth: _previewMaxWidth,
      multiBandFallback: multiBandFallback,
      skipOcr: skipOcr,
    );
  }

  Duration get pollInterval => _pollInterval;

  void setPollInterval(Duration interval) {
    final clampedMs = interval.inMilliseconds.clamp(150, 5000);
    final next = Duration(milliseconds: clampedMs);
    if (_pollInterval == next) return;
    _pollInterval = next;
    if (_running) {
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
    }
  }

  @override
  Stream<String> get textStream => _textController.stream;

  @override
  Stream<String> get focusTextStream => _focusTextController.stream;

  @override
  Stream<MultiInstanceTextEmission> get multiInstanceTextStream =>
      _multiTextController.stream;

  @override
  Stream<FrameTransitionEvent> get transitionStream =>
      _transitionController.stream;

  @override
  Stream<SlotVisualFrame> get visualFrameStream =>
      _visualFrameController.stream;

  @override
  void updateTransitionMinDuration(Duration duration) {
    _transitionDetector.setMinTransitionDuration(duration);
  }

  @override
  void updateTransitionThresholds({
    required int blackThreshold,
    required int whiteThreshold,
  }) {
    _transitionDetector.updateThresholds(
      blackThreshold: blackThreshold,
      whiteThreshold: whiteThreshold,
    );
  }

  @override
  void updateSlotTransitionConfigs(Map<int, SlotTransitionConfig> configs) {
    _transitionDetector.setSlotConfigs(configs);
  }

  List<MultiInstanceSlot> get multiInstanceSlots => _multiInstanceSlots;

  @override
  bool get isRunning => _running;

  DesktopWindowInfo? get selectedWindow => _selectedWindow;

  Rect? get cropRegion => _cropRegion;

  ScreenRegion? get screenRegion => _screenRegion;

  LiveFocusPreset get liveFocusPreset => _liveFocusPreset;

  ScreenRegion? get liveFocusScreenRegion => _liveFocusScreenRegion;

  List<ScreenRegion> get extraFocusRegions => _extraFocusRegions;

  Map<String, String> get focusBoxPreviewLines =>
      focusBoxPreviewsNotifier.value;

  CapturedFrame? get latestSnippetFrame => _latestSnippetFrame;

  String? get ocrLanguageTag => _ocrLanguageTag;

  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  void setOcrLanguageTag(String? languageTag) {
    _ocrLanguageTag = languageTag;
    _lastZoneAFingerprint = null;
    _lastZoneBFingerprint = null;
    _lastExtraZoneBFingerprints.clear();
    _lastSlotScanFingerprints.clear();
    _lastSlotFocusFingerprints.clear();
    _invalidateNativeScanCache();
    if (ocrDriver is LanguageAwareOcrDriver) {
      (ocrDriver as LanguageAwareOcrDriver).setLanguageTag(languageTag);
    }
  }

  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
    _lastZoneAFingerprint = null;
    _lastZoneBFingerprint = null;
    _lastExtraZoneBFingerprints.clear();
    _lastSlotScanFingerprints.clear();
    _lastSlotFocusFingerprints.clear();
    _invalidateNativeScanCache();
    if (ocrDriver is PreprocessAwareOcrDriver) {
      (ocrDriver as PreprocessAwareOcrDriver).setPreprocessProfile(profile);
    }
  }

  /// Selects the target window to monitor. If cropRegion is not set, defaults
  /// to the lower dialogue region.
  void setSelectedWindow(DesktopWindowInfo? window) {
    _selectedWindow = window;
    _lastZoneAFingerprint = null;
    _lastZoneBFingerprint = null;
    _invalidateNativeScanCache();
    if (window != null && _cropRegion == null) {
      _cropRegion = WindowDetector().calculateDefaultDialogueRegion(
        windowWidth: window.width,
        windowHeight: window.height,
      );
    }
  }

  void setCropRegion(Rect? region) {
    _cropRegion = region;
    _lastZoneAFingerprint = null;
    _invalidateNativeScanCache();
  }

  void setScreenRegion(ScreenRegion? region) {
    _screenRegion = region;
    _lastZoneAFingerprint = null;
    _invalidateNativeScanCache();
    if (region == null) {
      selfWindowOverlapNotifier.value = false;
    }
  }

  /// Configures Zone B (Live-Focus / Opponent HUD) preset mode.
  void setLiveFocusPreset(LiveFocusPreset preset) {
    _liveFocusPreset = preset;
    _lastZoneBFingerprint = null;
    _lastExtraZoneBFingerprints.clear();
    _cachedFocusLinesByBox.clear();
    _invalidateNativeScanCache();
    if (preset != LiveFocusPreset.customRegion) {
      _liveFocusScreenRegion = null;
    }
    if (preset == LiveFocusPreset.disabled) {
      _latestFocusFramesByBox.remove('B1');
      focusBoxFramesNotifier.value = Map.unmodifiable(_latestFocusFramesByBox);
      focusBoxPreviewsNotifier.value = const {};
      liveFocusStatusNotifier.value = const LiveOcrScanStatus();
    }
  }

  /// Configures Zone B with an explicit desktop snipping region (`customRegion`).
  void setLiveFocusScreenRegion(ScreenRegion? region) {
    _liveFocusScreenRegion = region;
    _lastZoneBFingerprint = null;
    _cachedFocusLinesByBox.remove('B1');
    _invalidateNativeScanCache();
    if (region != null) {
      _liveFocusPreset = LiveFocusPreset.customRegion;
    } else {
      _latestFocusFramesByBox.remove('B1');
      focusBoxFramesNotifier.value = Map.unmodifiable(_latestFocusFramesByBox);
      if (_liveFocusPreset == LiveFocusPreset.customRegion) {
        _liveFocusPreset = LiveFocusPreset.disabled;
      }
      if (_liveFocusPreset == LiveFocusPreset.disabled) {
        liveFocusStatusNotifier.value = const LiveOcrScanStatus();
      }
    }
  }

  /// Configures optional additional Zone B focus boxes (`B2`, `B3`, ...).
  void setExtraFocusRegions(List<ScreenRegion> regions) {
    _extraFocusRegions = List.unmodifiable(regions);
    _lastExtraZoneBFingerprints.clear();
    _cachedFocusLinesByBox.removeWhere((k, _) => k != 'B1');
    _latestFocusFramesByBox.removeWhere((k, _) => k != 'B1');
    focusBoxFramesNotifier.value = Map.unmodifiable(_latestFocusFramesByBox);
    _invalidateNativeScanCache();
  }

  /// Updates known desktop windows so window-bound multi-instance slots can resolve targets.
  void updateKnownWindows(List<DesktopWindowInfo> windows) {
    _knownWindows = List.unmodifiable(windows);
  }

  /// Updates numbered Multi-Instance Shiny-Hunting slots cleanly.
  void setMultiInstanceSlots(List<MultiInstanceSlot> slots) {
    _multiInstanceSlots = List.unmodifiable(slots);
    _lastSlotScanFingerprints.clear();
    _lastSlotFocusFingerprints.clear();
    _invalidateNativeScanCache();
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollOnce());
  }

  @override
  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Feeds an external screenshot or snippet (e.g. from Windows Snipping Tool
  /// or clipboard) directly into OCR and emits any detected text lines.
  Future<List<String>> processSnippet(CapturedFrame frame) async {
    _latestSnippetFrame = frame;
    try {
      final recognizedLines = await ocrDriver.recognizeText(frame);
      final validLines = recognizedLines
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      for (final line in validLines) {
        _textController.add(line);
      }
      if (validLines.length > 1) {
        _textController.add(validLines.join('\n'));
      }
      return validLines;
    } catch (_) {
      return const [];
    }
  }

  /// Captures a visual preview frame without running OCR or incrementing scan counters.
  Future<CapturedFrame?> capturePreviewOnly() async {
    final window = _selectedWindow ??
        (_screenRegion != null ? DesktopWindowInfo.primaryScreen() : null);
    if (window == null) return null;
    try {
      if (nativeBridge != null) {
        final req = _buildNativeRequest(
          window: window,
          cropRegion: _cropRegion,
          screenRegion: _screenRegion,
          slotKey: 'zoneA_preview',
          forceOcr: false,
          computeColorHistogram: false,
          includeThumbnail: true,
          skipOcr: true,
        );
        if (req != null) {
          final res = await nativeBridge!.captureAndAnalyze(req);
          if (res != null) {
            selfWindowOverlapNotifier.value =
                res.selfWindowOverlaps && !_maskSelfWindow;
            final thumb = res.thumbnailFrame;
            if (thumb != null) {
              final prev = liveScanStatusNotifier.value;
              liveScanStatusNotifier.value = LiveOcrScanStatus(
                scanCount: prev.scanCount,
                lastScanAt: prev.lastScanAt,
                recognizedLines: prev.recognizedLines,
                latestFrame: thumb,
              );
            }
            return thumb;
          }
        }
      }

      final frame = await captureDriver.captureWindow(
        window: window,
        cropRegion: _cropRegion,
        screenRegion: _screenRegion,
      );
      if (frame != null) {
        final prev = liveScanStatusNotifier.value;
        liveScanStatusNotifier.value = LiveOcrScanStatus(
          scanCount: prev.scanCount,
          lastScanAt: prev.lastScanAt,
          recognizedLines: prev.recognizedLines,
          latestFrame: frame,
        );
      }
      return frame;
    } catch (_) {
      return null;
    }
  }

  /// Clears accumulated temporary OCR diagnostic logs.
  void clearScanLogs() {
    scanLogsNotifier.value = const [];
  }

  String _describeTarget(DesktopWindowInfo window) {
    if (_screenRegion != null) {
      return '(${_screenRegion!.x.round()},${_screenRegion!.y.round()}) '
          '${_screenRegion!.width.round()}x${_screenRegion!.height.round()}';
    }
    if (_cropRegion != null) {
      return '${window.title} [crop=${_cropRegion!.left.round()},${_cropRegion!.top.round()} '
          '${_cropRegion!.width.round()}x${_cropRegion!.height.round()}]';
    }
    return '${window.title} (${window.width.round()}x${window.height.round()})';
  }

  void _appendLogEntry(OcrScanLogEntry entry) {
    if (_disposed) return;
    final next = [entry, ...scanLogsNotifier.value];
    if (next.length > _maxScanLogs) {
      next.removeRange(_maxScanLogs, next.length);
    }
    scanLogsNotifier.value = next;
  }

  /// Triggers an immediate capture and recognition cycle on demand,
  /// even if periodic polling is paused.
  Future<CapturedFrame?> triggerSingleScan() async {
    if (_disposed || _scanInFlight) return null;
    final window = _selectedWindow ??
        ((_screenRegion != null ||
                _liveFocusScreenRegion != null ||
                _extraFocusRegions.isNotEmpty ||
                _multiInstanceSlots.any((s) => s.enabled))
            ? DesktopWindowInfo.primaryScreen()
            : null);
    if (window == null) return null;

    _scanInFlight = true;
    final sourceMode = _screenRegion != null ? 'desktop-region' : 'window';
    final targetDesc = _describeTarget(window);
    final capWatch = Stopwatch()..start();
    final cycleForceOcr = _forceNextNativeOcr;
    final cycleGen = _cacheGeneration;

    try {
      final nativeReq = nativeBridge != null
          ? _buildNativeRequest(
              window: window,
              cropRegion: _cropRegion,
              screenRegion: _screenRegion,
              slotKey: 'zoneA',
              forceOcr: cycleForceOcr,
              computeColorHistogram: _visualFrameController.hasListener,
              includeThumbnail: _shouldRequestThumbnail(),
            )
          : null;
      final nativeRes = nativeReq != null
          ? await nativeBridge!.captureAndAnalyze(nativeReq)
          : null;
      if (_disposed) return nativeRes?.thumbnailFrame;

      if (nativeRes != null) {
        selfWindowOverlapNotifier.value =
            nativeRes.selfWindowOverlaps && !_maskSelfWindow;

        if (nativeRes.captured) {
          if (nativeRes.avgLuma != null && nativeRes.stdDev != null) {
            final transition = _transitionDetector.analyzeLuminance(
              avgLuma: nativeRes.avgLuma!,
              stdDev: nativeRes.stdDev!,
              slotId: 0,
            );
            if (transition != null && !_transitionController.isClosed) {
              _transitionController.add(transition);
            }
          }
          if (nativeRes.colorHistogram != null &&
              _visualFrameController.hasListener &&
              !_visualFrameController.isClosed) {
            _visualFrameController.add(
              SlotVisualFrame(
                slotId: 0,
                precomputedHistogram: nativeRes.colorHistogram,
              ),
            );
          }

          if (!nativeRes.ocrSkipped) {
            if (ocrDriver is WindowsDesktopOcrDriver) {
              (ocrDriver as WindowsDesktopOcrDriver)
                  .onRecognitionResult
                  ?.call(nativeRes.toOcrRecognitionResult());
            }
            final validLines = nativeRes.lines
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList();
            _scanCounter++;
            final prev = liveScanStatusNotifier.value;
            liveScanStatusNotifier.value = LiveOcrScanStatus(
              scanCount: _scanCounter,
              lastScanAt: DateTime.now(),
              recognizedLines: validLines,
              latestFrame: nativeRes.thumbnailFrame ?? prev.latestFrame,
            );

            _appendLogEntry(
              OcrScanLogEntry(
                scanNumber: _scanCounter,
                timestamp: DateTime.now(),
                sourceMode: sourceMode,
                targetDescription: targetDesc,
                frameWidth: nativeRes.frameWidth,
                frameHeight: nativeRes.frameHeight,
                pixelFormat: 'bgra8888',
                captureMethod: nativeRes.captureMethod,
                frameBrightnessSummary: nativeRes.brightnessSummary,
                captureDurationMs: nativeRes.captureDurationMs,
                ocrDurationMs: nativeRes.ocrDurationMs,
                requestedLanguage:
                    nativeRes.requestedLanguageTag ?? _ocrLanguageTag ?? '',
                resolvedLanguage:
                    nativeRes.resolvedLanguageTag ?? _ocrLanguageTag ?? '',
                usedFallbackLanguage: nativeRes.usedFallbackLanguage,
                availableLanguages: nativeRes.availableLanguageTags,
                rawLines: validLines,
                ocrSucceeded: nativeRes.ocrSucceeded,
                errorHint: nativeRes.errorHint,
                preprocessProfile: _preprocessProfile.name,
              ),
            );

            for (final line in validLines) {
              _textController.add(line);
            }
            if (validLines.length > 1) {
              _textController.add(validLines.join('\n'));
            }
          } else if (nativeRes.thumbnailFrame != null) {
            final prev = liveScanStatusNotifier.value;
            liveScanStatusNotifier.value = LiveOcrScanStatus(
              scanCount: prev.scanCount,
              lastScanAt: prev.lastScanAt,
              recognizedLines: prev.recognizedLines,
              latestFrame: nativeRes.thumbnailFrame,
            );
          }
        } else {
          _scanCounter++;
          _appendLogEntry(
            OcrScanLogEntry(
              scanNumber: _scanCounter,
              timestamp: DateTime.now(),
              sourceMode: sourceMode,
              targetDescription: targetDesc,
              frameWidth: 0,
              frameHeight: 0,
              pixelFormat: '-',
              captureMethod: 'capture-null',
              frameBrightnessSummary: 'no-frame',
              captureDurationMs: nativeRes.captureDurationMs,
              ocrDurationMs: 0,
              requestedLanguage: _ocrLanguageTag ?? '',
              resolvedLanguage: '',
              usedFallbackLanguage: false,
              availableLanguages: const [],
              rawLines: const [],
              ocrSucceeded: false,
              errorHint: nativeRes.errorHint ?? 'captureAndAnalyze returned not captured',
            ),
          );
        }

        await _pollZoneBFocus(window, forceOcr: cycleForceOcr);
        await _pollMultiInstanceSlots(forceOcr: cycleForceOcr);
        if (_cacheGeneration == cycleGen) {
          _forceNextNativeOcr = false;
        }
        return nativeRes.thumbnailFrame;
      }

      final frame = await captureDriver.captureWindow(
        window: window,
        cropRegion: _cropRegion,
        screenRegion: _screenRegion,
      );
      capWatch.stop();
      if (_disposed) return frame;

      if (frame != null) {
        final transition = _transitionDetector.analyzeFrame(frame, slotId: 0);
        if (transition != null && !_transitionController.isClosed) {
          _transitionController.add(transition);
        }
        if (_visualFrameController.hasListener &&
            !_visualFrameController.isClosed) {
          _visualFrameController.add(SlotVisualFrame(slotId: 0, frame: frame));
        }
        final fp = computeFrameFingerprint(frame);
        final changed = _lastZoneAFingerprint != fp;
        _lastZoneAFingerprint = fp;

        if (changed) {
          final ocrWatch = Stopwatch()..start();
          OcrRecognitionResult? detailedRes;
          List<String> recognizedLines;
          if (ocrDriver is WindowsDesktopOcrDriver) {
            detailedRes =
                await (ocrDriver as WindowsDesktopOcrDriver).recognizeTextDetailed(
              frame,
            );
            recognizedLines = detailedRes.lines;
          } else {
            recognizedLines = await ocrDriver.recognizeText(frame);
          }
          ocrWatch.stop();
          if (_disposed) return frame;

          final validLines = recognizedLines
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList();
          _scanCounter++;
          liveScanStatusNotifier.value = LiveOcrScanStatus(
            scanCount: _scanCounter,
            lastScanAt: DateTime.now(),
            recognizedLines: validLines,
            latestFrame: frame,
          );

          _appendLogEntry(
            OcrScanLogEntry(
              scanNumber: _scanCounter,
              timestamp: DateTime.now(),
              sourceMode: sourceMode,
              targetDescription: targetDesc,
              frameWidth: frame.width,
              frameHeight: frame.height,
              pixelFormat: frame.pixelFormat,
              captureMethod: frame.captureMethod ?? 'unknown',
              frameBrightnessSummary: computeFrameBrightnessSummary(frame),
              captureDurationMs: capWatch.elapsedMilliseconds,
              ocrDurationMs: detailedRes?.ocrDurationMs ?? ocrWatch.elapsedMilliseconds,
              requestedLanguage:
                  detailedRes?.requestedLanguageTag ?? _ocrLanguageTag ?? '',
              resolvedLanguage:
                  detailedRes?.resolvedLanguageTag ?? _ocrLanguageTag ?? '',
              usedFallbackLanguage: detailedRes?.usedFallbackLanguage ?? false,
              availableLanguages: detailedRes?.availableLanguageTags ?? const [],
              rawLines: validLines,
              ocrSucceeded: detailedRes?.ocrSucceeded ?? true,
              errorHint: detailedRes?.errorHint,
              preprocessProfile: _preprocessProfile.name,
            ),
          );

          for (final line in validLines) {
            _textController.add(line);
          }
          if (validLines.length > 1) {
            _textController.add(validLines.join('\n'));
          }
        }
      } else {
        _scanCounter++;
        _appendLogEntry(
          OcrScanLogEntry(
            scanNumber: _scanCounter,
            timestamp: DateTime.now(),
            sourceMode: sourceMode,
            targetDescription: targetDesc,
            frameWidth: 0,
            frameHeight: 0,
            pixelFormat: '-',
            captureMethod: 'capture-null',
            frameBrightnessSummary: 'no-frame',
            captureDurationMs: capWatch.elapsedMilliseconds,
            ocrDurationMs: 0,
            requestedLanguage: _ocrLanguageTag ?? '',
            resolvedLanguage: '',
            usedFallbackLanguage: false,
            availableLanguages: const [],
            rawLines: const [],
            ocrSucceeded: false,
            errorHint: 'captureWindow returned null',
          ),
        );
      }

      // Zone B: Optional opponent HUD capture strictly for Live-Fokus encounters
      await _pollZoneBFocus(window);
      // Multi-Instance Shiny-Hunting slots (with per-slot pixel-diff OCR skipping)
      await _pollMultiInstanceSlots();

      return frame;
    } catch (e) {
      capWatch.stop();
      _scanCounter++;
      _appendLogEntry(
        OcrScanLogEntry(
          scanNumber: _scanCounter,
          timestamp: DateTime.now(),
          sourceMode: sourceMode,
          targetDescription: targetDesc,
          frameWidth: 0,
          frameHeight: 0,
          pixelFormat: '-',
          captureMethod: 'exception',
          frameBrightnessSummary: 'error',
          captureDurationMs: capWatch.elapsedMilliseconds,
          ocrDurationMs: 0,
          requestedLanguage: _ocrLanguageTag ?? '',
          resolvedLanguage: '',
          usedFallbackLanguage: false,
          availableLanguages: const [],
          rawLines: const [],
          ocrSucceeded: false,
          errorHint: e.toString(),
        ),
      );
      return null;
    } finally {
      _scanInFlight = false;
    }
  }

  Future<List<String>> _recognizeFocusFrameWithMultiBand(
    CapturedFrame focusFrame,
  ) async {
    Future<List<String>> runOcr(CapturedFrame f) async {
      final raw = ocrDriver is WindowsDesktopOcrDriver
          ? (await (ocrDriver as WindowsDesktopOcrDriver)
                  .recognizeTextDetailed(f))
              .lines
          : await ocrDriver.recognizeText(f);
      return raw.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    }

    final merged = <String>[];
    final seenLower = <String>{};
    void addLines(List<String> lines) {
      for (final l in lines) {
        final key = l.toLowerCase();
        if (seenLower.add(key)) {
          merged.add(l);
        }
      }
    }

    bool isCandidateLine(String line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return false;
      return _focusCandidateCjkRegex.hasMatch(trimmed) ||
          _focusCandidateWordRegex.hasMatch(trimmed);
    }

    addLines(await runOcr(focusFrame));

    final candidateCount = merged.where(isCandidateLine).length;
    if (candidateCount < 2 && focusFrame.pixelFormat == 'bgra8888') {
      final bands = await FrameBandCropper.splitZoneBBandsAsync(focusFrame);
      for (final band in bands) {
        addLines(await runOcr(band));
      }
    }

    if (merged.where(isCandidateLine).isEmpty &&
        focusFrame.pixelFormat == 'bgra8888') {
      final inverted = await FrameBandCropper.invertLuminanceBgraAsync(focusFrame);
      if (inverted != null) {
        addLines(await runOcr(inverted));
        if (merged.where(isCandidateLine).length < 2) {
          final invertedBands =
              await FrameBandCropper.splitZoneBBandsAsync(inverted);
          for (final band in invertedBands) {
            addLines(await runOcr(band));
          }
        }
      }
    }

    return merged;
  }

  Future<void> _pollZoneBFocus(
    DesktopWindowInfo primaryWindow, {
    bool forceOcr = false,
  }) async {
    if (_liveFocusPreset == LiveFocusPreset.disabled &&
        _extraFocusRegions.isEmpty) {
      return;
    }

    try {
      bool anyBoxChanged = false;
      bool anyThumbUpdated = false;
      CapturedFrame? primaryLatestFrame;
      final requestThumb = _shouldRequestFocusThumbnail();

      if (_liveFocusPreset != LiveFocusPreset.disabled) {
        final ScreenRegion? b1Region =
            _liveFocusPreset == LiveFocusPreset.customRegion
                ? _liveFocusScreenRegion
                : null;
        final Rect? b1Crop = _liveFocusPreset == LiveFocusPreset.customRegion
            ? null
            : WindowDetector().calculateEnemyHudCropRegion(
                _liveFocusPreset,
                windowWidth: primaryWindow.width,
                windowHeight: primaryWindow.height,
              );
        final b1Window = _liveFocusPreset == LiveFocusPreset.customRegion
            ? DesktopWindowInfo.primaryScreen()
            : primaryWindow;

        final nativeB1Req = (nativeBridge != null &&
                (b1Region != null || b1Crop != null))
            ? _buildNativeRequest(
                window: b1Window,
                cropRegion: b1Crop,
                screenRegion: b1Region,
                slotKey: 'zoneB_1',
                forceOcr: forceOcr,
                computeColorHistogram: false,
                includeThumbnail: requestThumb,
                multiBandFallback: true,
              )
            : null;
        final nativeB1Res = nativeB1Req != null
            ? await nativeBridge!.captureAndAnalyze(nativeB1Req)
            : null;

        if (nativeB1Res != null) {
          if (nativeB1Res.captured) {
            if (nativeB1Res.thumbnailFrame != null) {
              primaryLatestFrame = nativeB1Res.thumbnailFrame;
              _latestFocusFramesByBox['B1'] = nativeB1Res.thumbnailFrame!;
              anyThumbUpdated = true;
            }
            if (!nativeB1Res.ocrSkipped) {
              anyBoxChanged = true;
              _cachedFocusLinesByBox['B1'] = nativeB1Res.lines;
            }
          }
        } else {
          CapturedFrame? focusFrame;
          if (b1Region != null) {
            focusFrame = await captureDriver.captureWindow(
              window: DesktopWindowInfo.primaryScreen(),
              cropRegion: null,
              screenRegion: b1Region,
            );
          } else if (b1Crop != null) {
            focusFrame = await captureDriver.captureWindow(
              window: primaryWindow,
              cropRegion: b1Crop,
              screenRegion: null,
            );
          }

          if (focusFrame != null) {
            primaryLatestFrame = focusFrame;
            _latestFocusFramesByBox['B1'] = focusFrame;
            anyThumbUpdated = true;
            final fp = computeFrameFingerprint(focusFrame);
            if (_lastZoneBFingerprint != fp) {
              _lastZoneBFingerprint = fp;
              anyBoxChanged = true;
              final valid = await _recognizeFocusFrameWithMultiBand(focusFrame);
              _cachedFocusLinesByBox['B1'] = valid;
            }
          }
        }
      }

      for (int i = 0; i < _extraFocusRegions.length; i++) {
        final extraRegion = _extraFocusRegions[i];
        final boxKey = 'B${i + 2}';
        final nativeExtraReq = nativeBridge != null
            ? _buildNativeRequest(
                window: DesktopWindowInfo.primaryScreen(),
                cropRegion: null,
                screenRegion: extraRegion,
                slotKey: 'zoneB_${i + 2}',
                forceOcr: forceOcr,
                computeColorHistogram: false,
                includeThumbnail: requestThumb,
                multiBandFallback: true,
              )
            : null;
        final nativeExtraRes = nativeExtraReq != null
            ? await nativeBridge!.captureAndAnalyze(nativeExtraReq)
            : null;

        if (nativeExtraRes != null) {
          if (!nativeExtraRes.captured) continue;
          if (nativeExtraRes.thumbnailFrame != null) {
            _latestFocusFramesByBox[boxKey] = nativeExtraRes.thumbnailFrame!;
            anyThumbUpdated = true;
          }
          if (!nativeExtraRes.ocrSkipped) {
            anyBoxChanged = true;
            _cachedFocusLinesByBox[boxKey] = nativeExtraRes.lines;
          }
        } else {
          final extraFrame = await captureDriver.captureWindow(
            window: DesktopWindowInfo.primaryScreen(),
            cropRegion: null,
            screenRegion: extraRegion,
          );
          if (extraFrame == null) continue;
          _latestFocusFramesByBox[boxKey] = extraFrame;
          anyThumbUpdated = true;
          final fp = computeFrameFingerprint(extraFrame);
          if (_lastExtraZoneBFingerprints[i] != fp) {
            _lastExtraZoneBFingerprints[i] = fp;
            anyBoxChanged = true;
            final valid = await _recognizeFocusFrameWithMultiBand(extraFrame);
            _cachedFocusLinesByBox[boxKey] = valid;
          }
        }
      }

      if (_disposed) return;

      if (!anyBoxChanged) {
        if (anyThumbUpdated) {
          focusBoxFramesNotifier.value =
              Map.unmodifiable(_latestFocusFramesByBox);
          if (primaryLatestFrame != null) {
            final prev = liveFocusStatusNotifier.value;
            liveFocusStatusNotifier.value = LiveOcrScanStatus(
              scanCount: prev.scanCount,
              lastScanAt: prev.lastScanAt,
              recognizedLines: prev.recognizedLines,
              latestFrame: primaryLatestFrame,
            );
          }
        }
        return;
      }

      final combinedLines = <String>[];
      final seenCombined = <String>{};
      final previewsMap = <String, String>{};

      final orderedKeys = [
        if (_liveFocusPreset != LiveFocusPreset.disabled) 'B1',
        for (int i = 0; i < _extraFocusRegions.length; i++) 'B${i + 2}',
      ];
      for (final key in orderedKeys) {
        final boxLines = _cachedFocusLinesByBox[key] ?? const [];
        previewsMap[key] = boxLines.join(' · ');
        for (final l in boxLines) {
          if (seenCombined.add(l.toLowerCase())) {
            combinedLines.add(l);
          }
        }
      }

      focusBoxPreviewsNotifier.value = Map.unmodifiable(previewsMap);
      focusBoxFramesNotifier.value = Map.unmodifiable(_latestFocusFramesByBox);
      _focusScanCounter++;
      liveFocusStatusNotifier.value = LiveOcrScanStatus(
        scanCount: _focusScanCounter,
        lastScanAt: DateTime.now(),
        recognizedLines: combinedLines,
        latestFrame: primaryLatestFrame ??
            liveFocusStatusNotifier.value.latestFrame,
      );

      if (combinedLines.isNotEmpty) {
        _focusTextController.add(combinedLines.join('\n'));
      }
    } catch (_) {
      // Non-fatal: Zone B HUD polling must not interrupt Zone A catch detection
    }
  }

  DesktopWindowInfo? _resolveBoundWindow(MultiInstanceSlot slot) {
    if (!slot.isWindowBound) return null;
    final candidates = [
      ..._knownWindows,
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

  Future<void> _emitSlotZoneOcr({
    required MultiInstanceSlot slot,
    required CapturedFrame? frame,
    required Map<int, int> fingerprintCache,
    required bool encounterOnly,
  }) async {
    if (frame == null) return;

    if (!encounterOnly) {
      final transition =
          _transitionDetector.analyzeFrame(frame, slotId: slot.id);
      if (transition != null && !_transitionController.isClosed) {
        _transitionController.add(transition);
      }
      if (_visualFrameController.hasListener &&
          !_visualFrameController.isClosed) {
        _visualFrameController.add(
          SlotVisualFrame(slotId: slot.id, frame: frame),
        );
      }
    }

    final fp = computeFrameFingerprint(frame);
    if (fingerprintCache[slot.id] == fp) return;
    fingerprintCache[slot.id] = fp;

    final List<String> lines = ocrDriver is WindowsDesktopOcrDriver
        ? (await (ocrDriver as WindowsDesktopOcrDriver)
                .recognizeTextDetailed(frame))
            .lines
        : await ocrDriver.recognizeText(frame);

    final valid =
        lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (valid.isNotEmpty && !_multiTextController.isClosed) {
      _multiTextController.add(
        MultiInstanceTextEmission(
          slotId: slot.id,
          colorHex: slot.colorHex,
          rawText: valid.join('\n'),
          encounterOnly: encounterOnly,
        ),
      );
    }
  }

  Future<void> _pollMultiInstanceSlots({bool forceOcr = false}) async {
    if (_multiInstanceSlots.isEmpty) return;
    final detector = WindowDetector();
    final activeSlots = _multiInstanceSlots.where((s) => s.enabled).toList();
    if (activeSlots.isEmpty) return;

    final zoneSpecs = <({
      MultiInstanceSlot slot,
      DesktopWindowInfo targetWindow,
      Rect? cropRegion,
      ScreenRegion? screenRegion,
      Map<int, int> fingerprintCache,
      bool encounterOnly,
    })>[];

    for (final slot in activeSlots) {
      final boundWindow = _resolveBoundWindow(slot);

      if (slot.hasScan) {
        if (slot.scanRegion != null) {
          zoneSpecs.add((
            slot: slot,
            targetWindow: DesktopWindowInfo.primaryScreen(),
            cropRegion: null,
            screenRegion: slot.scanRegion,
            fingerprintCache: _lastSlotScanFingerprints,
            encounterOnly: false,
          ));
        } else if (boundWindow != null) {
          zoneSpecs.add((
            slot: slot,
            targetWindow: boundWindow,
            cropRegion: detector.calculateScanRegion(
              slot.scanPreset,
              windowWidth: boundWindow.width,
              windowHeight: boundWindow.height,
            ),
            screenRegion: null,
            fingerprintCache: _lastSlotScanFingerprints,
            encounterOnly: false,
          ));
        }
      }

      if (slot.hasFocus) {
        if (slot.focusPreset == LiveFocusPreset.customRegion &&
            slot.focusRegion != null) {
          zoneSpecs.add((
            slot: slot,
            targetWindow: DesktopWindowInfo.primaryScreen(),
            cropRegion: null,
            screenRegion: slot.focusRegion,
            fingerprintCache: _lastSlotFocusFingerprints,
            encounterOnly: true,
          ));
        } else if (slot.focusPreset != LiveFocusPreset.disabled &&
            slot.focusPreset != LiveFocusPreset.customRegion &&
            boundWindow != null) {
          final focusCrop = detector.calculateEnemyHudCropRegion(
            slot.focusPreset,
            windowWidth: boundWindow.width,
            windowHeight: boundWindow.height,
          );
          if (focusCrop != null) {
            zoneSpecs.add((
              slot: slot,
              targetWindow: boundWindow,
              cropRegion: focusCrop,
              screenRegion: null,
              fingerprintCache: _lastSlotFocusFingerprints,
              encounterOnly: true,
            ));
          }
        }
      }
    }

    if (zoneSpecs.isEmpty) return;

    if (nativeBridge != null) {
      final wantHist = _visualFrameController.hasListener;
      final nativeSpecs = <({
        MultiInstanceSlot slot,
        bool encounterOnly,
        NativeCaptureAnalyzeRequest req,
      })>[];
      bool canUseAllNative = true;
      for (final spec in zoneSpecs) {
        final req = _buildNativeRequest(
          window: spec.targetWindow,
          cropRegion: spec.cropRegion,
          screenRegion: spec.screenRegion,
          slotKey:
              'multi_${spec.slot.id}_${spec.encounterOnly ? 'focus' : 'scan'}',
          forceOcr: forceOcr,
          computeColorHistogram: !spec.encounterOnly && wantHist,
          includeThumbnail: false,
        );
        if (req == null) {
          canUseAllNative = false;
          break;
        }
        nativeSpecs.add((
          slot: spec.slot,
          encounterOnly: spec.encounterOnly,
          req: req,
        ));
      }

      if (canUseAllNative) {
        final results = await Future.wait([
          for (final item in nativeSpecs)
            nativeBridge!
                .captureAndAnalyze(item.req)
                .catchError((_) => null),
        ]);

        bool handledAny = false;
        for (int i = 0; i < nativeSpecs.length; i++) {
          final res = results[i];
          if (res == null) continue;
          handledAny = true;
          final item = nativeSpecs[i];
          if (!res.captured) continue;

          if (!item.encounterOnly) {
            if (res.avgLuma != null && res.stdDev != null) {
              final transition = _transitionDetector.analyzeLuminance(
                avgLuma: res.avgLuma!,
                stdDev: res.stdDev!,
                slotId: item.slot.id,
              );
              if (transition != null && !_transitionController.isClosed) {
                _transitionController.add(transition);
              }
            }
            if (res.colorHistogram != null &&
                _visualFrameController.hasListener &&
                !_visualFrameController.isClosed) {
              _visualFrameController.add(
                SlotVisualFrame(
                  slotId: item.slot.id,
                  precomputedHistogram: res.colorHistogram,
                ),
              );
            }
          }

          if (!res.ocrSkipped) {
            final valid = res.lines
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList();
            if (valid.isNotEmpty && !_multiTextController.isClosed) {
              _multiTextController.add(
                MultiInstanceTextEmission(
                  slotId: item.slot.id,
                  colorHex: item.slot.colorHex,
                  rawText: valid.join('\n'),
                  encounterOnly: item.encounterOnly,
                ),
              );
            }
          }
        }
        if (handledAny) return;
      }
    }

    final capturedFrames = await Future.wait([
      for (final spec in zoneSpecs)
        captureDriver
            .captureWindow(
              window: spec.targetWindow,
              cropRegion: spec.cropRegion,
              screenRegion: spec.screenRegion,
            )
            .catchError((_) => null),
    ]);

    for (int i = 0; i < zoneSpecs.length; i++) {
      final spec = zoneSpecs[i];
      try {
        await _emitSlotZoneOcr(
          slot: spec.slot,
          frame: capturedFrames[i],
          fingerprintCache: spec.fingerprintCache,
          encounterOnly: spec.encounterOnly,
        );
      } catch (_) {
        // Isolate per-slot errors so other Shiny-Hunting instances keep scanning
      }
    }
  }

  Future<void> _pollOnce() async {
    if (!_running) return;
    await triggerSingleScan();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    liveScanStatusNotifier.dispose();
    liveFocusStatusNotifier.dispose();
    focusBoxPreviewsNotifier.dispose();
    focusBoxFramesNotifier.dispose();
    scanLogsNotifier.dispose();
    selfWindowOverlapNotifier.dispose();
    await _textController.close();
    await _focusTextController.close();
    await _multiTextController.close();
    await _transitionController.close();
    await _visualFrameController.close();
  }
}
