import 'dart:async';
import 'package:flutter/foundation.dart';
import '../desktop_tracker/desktop_capture_driver.dart';
import '../desktop_tracker/desktop_ocr_driver.dart';
import '../desktop_tracker/desktop_window_source.dart';
import '../desktop_tracker/window_detector.dart';
import '../scanner_core/models/scanner_settings.dart';
import '../scanner_core/source/scanner_source.dart';
import 'camera_frame_processor.dart';
import 'camera_scan_region.dart';

/// Camera-backed [ScannerSource] supporting Auto full-frame mode as well as
/// strict per-rectangle ROI cropping for Zone A, Zone B (Live-Fokus), and Multi-Instance slots.
class MobileCameraSource
    implements DualZoneScannerSource, MultiInstanceScannerSource {
  final DesktopOcrDriver ocrDriver;
  Duration _pollInterval;
  MobileCameraScanMode _scanMode;
  ScanRegionPreset _autoPreset;
  List<NormalizedScanRect> _regions;
  String? _ocrLanguageTag;
  OcrPreprocessProfile _preprocessProfile;

  bool _running = false;
  bool _scanInFlight = false;
  DateTime? _lastProcessedAt;
  CapturedFrame? _latestUprightFrame;
  final Map<String, int> _lastFingerprintByZone = {};
  int _scanCounter = 0;
  static const int _maxScanLogs = 40;

  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<String> _focusTextController =
      StreamController<String>.broadcast();
  final StreamController<MultiInstanceTextEmission> _multiTextController =
      StreamController<MultiInstanceTextEmission>.broadcast();

  final ValueNotifier<LiveOcrScanStatus> liveScanStatusNotifier =
      ValueNotifier(const LiveOcrScanStatus());
  final ValueNotifier<LiveOcrScanStatus> liveFocusStatusNotifier =
      ValueNotifier(const LiveOcrScanStatus());
  final ValueNotifier<List<OcrScanLogEntry>> scanLogsNotifier =
      ValueNotifier(const []);

  MobileCameraSource({
    required this.ocrDriver,
    this._pollInterval = const Duration(milliseconds: 400),
    this._scanMode = MobileCameraScanMode.autoFull,
    this._autoPreset = ScanRegionPreset.fullWindow,
    List<NormalizedScanRect> regions = const [],
    this._preprocessProfile = OcrPreprocessProfile.cameraDisplay,
  }) : _regions = List.unmodifiable(regions);

  @override
  Stream<String> get textStream => _textController.stream;

  @override
  Stream<String> get focusTextStream => _focusTextController.stream;

  @override
  Stream<MultiInstanceTextEmission> get multiInstanceTextStream =>
      _multiTextController.stream;

  @override
  bool get isRunning => _running;

  Duration get pollInterval => _pollInterval;
  MobileCameraScanMode get scanMode => _scanMode;
  ScanRegionPreset get autoPreset => _autoPreset;
  List<NormalizedScanRect> get regions => _regions;
  String? get ocrLanguageTag => _ocrLanguageTag;
  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  void setPollInterval(Duration interval) {
    final ms = ScannerSettings.clampScanIntervalMs(interval.inMilliseconds);
    _pollInterval = Duration(milliseconds: ms);
  }

  void setScanMode(MobileCameraScanMode mode) {
    if (_scanMode == mode) return;
    _scanMode = mode;
    _lastFingerprintByZone.clear();
  }

  void setAutoPreset(ScanRegionPreset preset) {
    if (_autoPreset == preset) return;
    _autoPreset = preset;
    _lastFingerprintByZone.clear();
  }

  void setRegions(List<NormalizedScanRect> regions) {
    _regions = List.unmodifiable(regions);
    _lastFingerprintByZone.clear();
  }

  void setOcrLanguageTag(String? languageTag) {
    _ocrLanguageTag = languageTag;
    if (ocrDriver is LanguageAwareOcrDriver) {
      (ocrDriver as LanguageAwareOcrDriver).setLanguageTag(languageTag);
    }
    _lastFingerprintByZone.clear();
  }

  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
    if (ocrDriver is PreprocessAwareOcrDriver) {
      (ocrDriver as PreprocessAwareOcrDriver).setPreprocessProfile(profile);
    }
    _lastFingerprintByZone.clear();
  }

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }

  /// Processes a single imported photo or screenshot immediately.
  Future<void> processPhotoFrame(CapturedFrame frame) async {
    await _processFrameInternal(frame, bypassThrottle: true, bypassHash: true);
  }

  /// Triggers an immediate re-scan of the most recent camera frame.
  Future<void> triggerSingleScan() async {
    final frame = _latestUprightFrame;
    if (frame == null) return;
    await _processFrameInternal(frame, bypassThrottle: true, bypassHash: true);
  }

  /// Checks whether a live camera frame should be converted and processed now,
  /// allowing the camera stream callback to drop frames cheaply before YUV->BGRA work.
  bool shouldProcessFrameNow() {
    if (!_running || _scanInFlight) return false;
    if (_lastProcessedAt != null &&
        DateTime.now().difference(_lastProcessedAt!) < _pollInterval) {
      return false;
    }
    return true;
  }

  /// Submits a live camera frame for throttled ROI cropping and OCR recognition.
  Future<void> submitCameraFrame(
    CapturedFrame uprightFrame, {
    bool bypassThrottle = false,
  }) async {
    _latestUprightFrame = uprightFrame;
    if (!_running) return;
    await _processFrameInternal(
      uprightFrame,
      bypassThrottle: bypassThrottle,
      bypassHash: false,
    );
  }

  Future<void> _processFrameInternal(
    CapturedFrame uprightFrame, {
    required bool bypassThrottle,
    required bool bypassHash,
  }) async {
    if (_scanInFlight) return;
    final now = DateTime.now();
    if (!bypassThrottle &&
        _lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _pollInterval) {
      return;
    }

    _scanInFlight = true;
    _lastProcessedAt = now;
    try {
      if (_scanMode == MobileCameraScanMode.autoFull) {
        await _scanAutoFull(uprightFrame, bypassHash: bypassHash);
      } else {
        await _scanCustomRegions(uprightFrame, bypassHash: bypassHash);
      }
    } finally {
      _scanInFlight = false;
    }
  }

  Future<void> _scanAutoFull(
    CapturedFrame uprightFrame, {
    required bool bypassHash,
  }) async {
    CapturedFrame target = uprightFrame;
    if (_autoPreset != ScanRegionPreset.fullWindow) {
      final detector = WindowDetector();
      final crop = detector.calculateScanRegion(
        _autoPreset,
        windowWidth: uprightFrame.width.toDouble(),
        windowHeight: uprightFrame.height.toDouble(),
      );
      final normalized = NormalizedScanRect.fromPixelRect(
        id: 'auto_${_autoPreset.name}',
        role: CameraZoneRole.scan,
        pixelRect: crop,
        frameWidth: uprightFrame.width.toDouble(),
        frameHeight: uprightFrame.height.toDouble(),
        colorHex: 0xFF10B981,
        label: _autoPreset.labelDe,
      );
      target = CameraFrameProcessor.cropFrameToNormalizedRect(
            uprightFrame,
            normalized,
          ) ??
          uprightFrame;
    }

    await _runOcrOnRegion(
      zoneKey: 'auto_full',
      targetDescription: 'Auto (${_autoPreset.labelDe})',
      croppedFrame: target,
      role: CameraZoneRole.scan,
      bypassHash: bypassHash,
    );
  }

  Future<void> _scanCustomRegions(
    CapturedFrame uprightFrame, {
    required bool bypassHash,
  }) async {
    final enabledRegions = _regions.where((r) => r.enabled).toList();
    if (enabledRegions.isEmpty) return;

    for (final region in enabledRegions) {
      final cropped = CameraFrameProcessor.cropFrameToNormalizedRect(
        uprightFrame,
        region,
      );
      if (cropped == null) continue;

      await _runOcrOnRegion(
        zoneKey: region.id,
        targetDescription: region.label,
        croppedFrame: cropped,
        role: region.role,
        slotId: region.slotId,
        colorHex: region.colorHex,
        encounterOnly: region.encounterOnly,
        bypassHash: bypassHash,
      );
    }
  }

  Future<void> _runOcrOnRegion({
    required String zoneKey,
    required String targetDescription,
    required CapturedFrame croppedFrame,
    required CameraZoneRole role,
    int? slotId,
    int? colorHex,
    bool encounterOnly = false,
    required bool bypassHash,
  }) async {
    final fingerprint = computeFrameFingerprint(croppedFrame);
    if (!bypassHash && _lastFingerprintByZone[zoneKey] == fingerprint) {
      return;
    }
    _lastFingerprintByZone[zoneKey] = fingerprint;

    final t0 = DateTime.now();
    final lines = await ocrDriver.recognizeText(croppedFrame);
    final ocrMs = DateTime.now().difference(t0).inMilliseconds;
    final joined = lines.join('\n').trim();
    final diagnosticHint = ocrDriver is DiagnosticOcrDriver
        ? (ocrDriver as DiagnosticOcrDriver).lastDiagnosticHint
        : null;

    _scanCounter++;
    _appendLog(
      OcrScanLogEntry(
        scanNumber: _scanCounter,
        timestamp: DateTime.now(),
        sourceMode: _scanMode == MobileCameraScanMode.autoFull
            ? 'camera_auto'
            : 'camera_${role.name}',
        targetDescription: targetDescription,
        frameWidth: croppedFrame.width,
        frameHeight: croppedFrame.height,
        pixelFormat: croppedFrame.pixelFormat,
        captureMethod: croppedFrame.captureMethod ?? 'mobile_camera',
        frameBrightnessSummary: computeFrameBrightnessSummary(croppedFrame),
        captureDurationMs: 0,
        ocrDurationMs: ocrMs,
        requestedLanguage: _ocrLanguageTag ?? 'auto',
        resolvedLanguage: _ocrLanguageTag ?? 'auto',
        usedFallbackLanguage: false,
        availableLanguages: const [],
        rawLines: lines,
        ocrSucceeded: diagnosticHint == null,
        errorHint: diagnosticHint,
        preprocessProfile: _preprocessProfile.name,
      ),
    );

    final status = LiveOcrScanStatus(
      scanCount: _scanCounter,
      lastScanAt: DateTime.now(),
      recognizedLines: lines,
      latestFrame: croppedFrame,
    );

    if (role == CameraZoneRole.focus) {
      liveFocusStatusNotifier.value = status;
      if (joined.isNotEmpty && !_focusTextController.isClosed) {
        _focusTextController.add(joined);
      }
      return;
    }

    if (role == CameraZoneRole.multiInstance) {
      if (encounterOnly) {
        liveFocusStatusNotifier.value = status;
      } else {
        liveScanStatusNotifier.value = status;
      }
      if (joined.isNotEmpty && !_multiTextController.isClosed) {
        _multiTextController.add(
          MultiInstanceTextEmission(
            slotId: slotId ?? 2,
            colorHex: colorHex ?? 0xFFA855F7,
            rawText: joined,
            encounterOnly: encounterOnly,
          ),
        );
      }
      return;
    }

    liveScanStatusNotifier.value = status;
    if (joined.isNotEmpty && !_textController.isClosed) {
      _textController.add(joined);
    }
  }

  void _appendLog(OcrScanLogEntry entry) {
    final current = List<OcrScanLogEntry>.from(scanLogsNotifier.value);
    current.insert(0, entry);
    if (current.length > _maxScanLogs) {
      current.removeRange(_maxScanLogs, current.length);
    }
    scanLogsNotifier.value = List.unmodifiable(current);
  }

  @override
  Future<void> dispose() async {
    _running = false;
    await _textController.close();
    await _focusTextController.close();
    await _multiTextController.close();
  }
}
