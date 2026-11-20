import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../desktop_tracker/desktop_capture_driver.dart';
import '../desktop_tracker/desktop_ocr_driver.dart';
import '../desktop_tracker/windows_desktop_bridge.dart';
import '../mobile_scanner/camera_frame_processor.dart';
import '../mobile_scanner/mobile_ocr_driver.dart';
import '../scanner_core/models/scanner_settings.dart';

/// Output returned by an invoked Linux OCR subprocess.
class LinuxOcrProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const LinuxOcrProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

/// Exception thrown when the `tesseract` binary cannot be spawned on Linux.
class LinuxOcrExecutableMissingException implements Exception {
  final String message;

  const LinuxOcrExecutableMissingException(this.message);

  @override
  String toString() => message;
}

typedef LinuxProcessRunner = Future<LinuxOcrProcessResult> Function(
  String executable,
  List<String> arguments, {
  required Uint8List stdinBytes,
});

/// Windows Camera OCR driver reusing native WinRT `Windows Media OCR` over [DesktopPlatformBridge].
class WindowsCameraOcrDriver
    implements
        LanguageAwareOcrDriver,
        PreprocessAwareOcrDriver,
        DiagnosticOcrDriver {
  final DesktopPlatformBridge bridge;
  String? _languageTag;
  OcrPreprocessProfile _preprocessProfile;
  @override
  String? lastDiagnosticHint;

  WindowsCameraOcrDriver({
    DesktopPlatformBridge? bridge,
    String? initialLanguageTag,
    OcrPreprocessProfile initialPreprocessProfile =
        OcrPreprocessProfile.cameraDisplay,
  })  : bridge = bridge ?? WindowsDesktopBridge.instance,
        _languageTag = initialLanguageTag,
        _preprocessProfile = initialPreprocessProfile;

  @override
  String? get languageTag => _languageTag;

  @override
  void setLanguageTag(String? languageTag) {
    _languageTag = languageTag;
  }

  @override
  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  @override
  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
  }

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    if (frame.width <= 0 || frame.height <= 0 || frame.bytes.isEmpty) {
      return const [];
    }
    final result = await bridge.recognizeText(
      frame,
      languageTag: _languageTag,
      preprocessProfile: _preprocessProfile.name,
    );
    if (!result.ocrSucceeded) {
      lastDiagnosticHint = result.errorHint ?? 'Windows Media OCR fehlgeschlagen';
      return const [];
    }
    lastDiagnosticHint = null;
    return result.lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
  }
}

/// macOS Camera OCR driver backed by native Apple Vision (`VNRecognizeTextRequest`).
class MacosVisionOcrDriver
    implements
        LanguageAwareOcrDriver,
        PreprocessAwareOcrDriver,
        DiagnosticOcrDriver {
  final MethodChannel channel;
  String? _languageTag;
  OcrPreprocessProfile _preprocessProfile;
  @override
  String? lastDiagnosticHint;

  MacosVisionOcrDriver({
    this.channel = const MethodChannel('pokevault/macos_vision_ocr'),
    String? initialLanguageTag,
    OcrPreprocessProfile initialPreprocessProfile =
        OcrPreprocessProfile.cameraDisplay,
  })  : _languageTag = initialLanguageTag,
        _preprocessProfile = initialPreprocessProfile;

  @override
  String? get languageTag => _languageTag;

  @override
  void setLanguageTag(String? languageTag) {
    _languageTag = languageTag;
  }

  @override
  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  @override
  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
  }

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    if (frame.width <= 0 || frame.height <= 0 || frame.bytes.isEmpty) {
      return const [];
    }
    final processed = CameraFrameProcessor.applyPreprocessProfile(
      frame,
      _preprocessProfile,
    );
    try {
      final raw = await channel.invokeMapMethod<String, dynamic>(
        'recognizeText',
        {
          'width': processed.width,
          'height': processed.height,
          'pixelFormat': processed.pixelFormat,
          'bytes': processed.bytes,
          if (_languageTag != null && _languageTag!.isNotEmpty)
            'languageTag': _languageTag,
          'preprocessProfile': _preprocessProfile.name,
        },
      );
      if (raw == null) {
        lastDiagnosticHint = 'macOS Vision Channel hat null geliefert';
        return const [];
      }
      final succeeded = raw['ocrSucceeded'] as bool? ?? true;
      if (!succeeded) {
        lastDiagnosticHint =
            raw['errorHint']?.toString() ?? 'macOS Vision OCR fehlgeschlagen';
        return const [];
      }
      final linesRaw = raw['lines'] as List? ?? const [];
      lastDiagnosticHint = null;
      return linesRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    } on MissingPluginException {
      lastDiagnosticHint =
          'macOS Vision OCR Channel nicht registriert (kein macOS-Build).';
      return const [];
    } catch (e) {
      lastDiagnosticHint = 'macOS Vision OCR Fehler: $e';
      return const [];
    }
  }
}

/// Linux Camera OCR driver invoking system `tesseract` CLI via binary PPM (`P6`) stdin.
class LinuxTesseractOcrDriver
    implements
        LanguageAwareOcrDriver,
        PreprocessAwareOcrDriver,
        DiagnosticOcrDriver {
  final LinuxProcessRunner _processRunner;
  String? _languageTag;
  OcrPreprocessProfile _preprocessProfile;
  @override
  String? lastDiagnosticHint;

  LinuxTesseractOcrDriver({
    String? initialLanguageTag,
    OcrPreprocessProfile initialPreprocessProfile =
        OcrPreprocessProfile.cameraDisplay,
    LinuxProcessRunner? processRunner,
  })  : _languageTag = initialLanguageTag,
        _preprocessProfile = initialPreprocessProfile,
        _processRunner = processRunner ?? _defaultProcessRunner;

  @override
  String? get languageTag => _languageTag;

  @override
  void setLanguageTag(String? languageTag) {
    _languageTag = languageTag;
  }

  @override
  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  @override
  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
  }

  /// Maps PokéVault / BCP-47 language codes to installed Tesseract traineddata codes.
  static String mapLanguageToTesseract(String? languageTag) {
    final norm = (languageTag ?? '').trim().toLowerCase();
    if (norm.startsWith('de')) return 'deu';
    if (norm.startsWith('fr')) return 'fra';
    if (norm.startsWith('es')) return 'spa';
    if (norm.startsWith('it')) return 'ita';
    if (norm.startsWith('ja')) return 'jpn';
    if (norm.startsWith('ko')) return 'kor';
    if (norm.startsWith('zh-hant') || norm.startsWith('zh_tw')) {
      return 'chi_tra';
    }
    if (norm.startsWith('zh')) return 'chi_sim';
    if (norm.startsWith('nl')) return 'nld';
    if (norm.startsWith('pl')) return 'pol';
    if (norm.startsWith('pt')) return 'por';
    if (norm.startsWith('ru')) return 'rus';
    return 'eng';
  }

  /// Encodes BGRA8888 raw pixels into an uncompressed binary PPM (`P6`) buffer for `tesseract stdin`.
  static Uint8List encodeBgraAsPpm(CapturedFrame frame) {
    final header = ascii.encode('P6\n${frame.width} ${frame.height}\n255\n');
    final pixelCount = frame.width * frame.height;
    final out = Uint8List(header.length + pixelCount * 3);
    out.setAll(0, header);
    final src = frame.bytes;
    int dstIdx = header.length;
    for (int i = 0; i < pixelCount; i++) {
      final srcIdx = i * 4;
      if (srcIdx + 2 >= src.length) break;
      out[dstIdx++] = src[srcIdx + 2]; // R
      out[dstIdx++] = src[srcIdx + 1]; // G
      out[dstIdx++] = src[srcIdx]; // B
    }
    return out;
  }

  static Future<LinuxOcrProcessResult> _defaultProcessRunner(
    String executable,
    List<String> arguments, {
    required Uint8List stdinBytes,
  }) async {
    try {
      final process = await Process.start(executable, arguments);
      process.stdin.add(stdinBytes);
      await process.stdin.close();
      final stdoutFuture = utf8.decodeStream(process.stdout);
      final stderrFuture = utf8.decodeStream(process.stderr);
      final exitCode = await process.exitCode;
      return LinuxOcrProcessResult(
        exitCode: exitCode,
        stdout: await stdoutFuture,
        stderr: await stderrFuture,
      );
    } on ProcessException catch (e) {
      throw LinuxOcrExecutableMissingException(e.message);
    }
  }

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    if (frame.width <= 0 || frame.height <= 0 || frame.bytes.isEmpty) {
      return const [];
    }
    final processed = CameraFrameProcessor.applyPreprocessProfile(
      frame,
      _preprocessProfile,
    );
    final ppm = encodeBgraAsPpm(processed);
    final lang = mapLanguageToTesseract(_languageTag);

    try {
      final result = await _processRunner(
        'tesseract',
        ['stdin', 'stdout', '-l', lang, '--psm', '6'],
        stdinBytes: ppm,
      );
      if (result.exitCode != 0) {
        lastDiagnosticHint =
            'tesseract ($lang) Exit ${result.exitCode}: ${result.stderr.trim()}';
        return const [];
      }
      lastDiagnosticHint = null;
      return result.stdout
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList(growable: false);
    } on LinuxOcrExecutableMissingException {
      lastDiagnosticHint =
          'Systempaket "tesseract-ocr" nicht gefunden. Installieren z. B. mit: sudo apt install tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng';
      return const [];
    } catch (e) {
      lastDiagnosticHint = 'Linux Tesseract Fehler: $e';
      return const [];
    }
  }
}

/// Testable selector mapping IO [TargetPlatform] to its native offline OCR driver.
DesktopOcrDriver selectIoCameraOcrDriverForPlatform(
  TargetPlatform platform, {
  DesktopPlatformBridge? windowsBridge,
  String? initialLanguageTag,
  OcrPreprocessProfile initialPreprocessProfile =
      OcrPreprocessProfile.cameraDisplay,
}) {
  switch (platform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return MobileOcrDriver(
        initialLanguageTag: initialLanguageTag,
        initialPreprocessProfile: initialPreprocessProfile,
      );
    case TargetPlatform.windows:
      return WindowsCameraOcrDriver(
        bridge: windowsBridge,
        initialLanguageTag: initialLanguageTag,
        initialPreprocessProfile: initialPreprocessProfile,
      );
    case TargetPlatform.macOS:
      return MacosVisionOcrDriver(
        initialLanguageTag: initialLanguageTag,
        initialPreprocessProfile: initialPreprocessProfile,
      );
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return LinuxTesseractOcrDriver(
        initialLanguageTag: initialLanguageTag,
        initialPreprocessProfile: initialPreprocessProfile,
      );
  }
}

/// IO factory entry point matched by conditional import in `platform_camera_ocr_driver.dart`.
DesktopOcrDriver createPlatformCameraOcrDriver({
  Object? windowsBridge,
  String? initialLanguageTag,
  OcrPreprocessProfile initialPreprocessProfile =
      OcrPreprocessProfile.cameraDisplay,
}) {
  final bridge = windowsBridge is DesktopPlatformBridge ? windowsBridge : null;
  return selectIoCameraOcrDriverForPlatform(
    defaultTargetPlatform,
    windowsBridge: bridge,
    initialLanguageTag: initialLanguageTag,
    initialPreprocessProfile: initialPreprocessProfile,
  );
}
