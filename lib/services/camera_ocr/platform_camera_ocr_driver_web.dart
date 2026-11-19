import 'package:flutter/foundation.dart';
import '../desktop_tracker/desktop_capture_driver.dart';
import '../desktop_tracker/desktop_ocr_driver.dart';
import '../mobile_scanner/camera_frame_processor.dart';
import '../scanner_core/models/scanner_settings.dart';
import 'web_ocr_status.dart';
import 'web_tesseract_js_bridge_stub.dart' show WebTesseractDelegate;
import 'web_tesseract_js_bridge_stub.dart'
    if (dart.library.js_interop) 'web_tesseract_js_bridge_web.dart'
    as browser_bridge;

export 'web_ocr_status.dart';
export 'web_tesseract_js_bridge_stub.dart'
    show WebTesseractDelegate, WebTesseractResult;

/// Browser Tesseract.js WASM OCR driver with Smart-Hybrid DE/EN local assets
/// and IndexedDB caching for additional languages.
class WebTesseractOcrDriver
    implements
        LanguageAwareOcrDriver,
        PreprocessAwareOcrDriver,
        WebOcrStatusReportingDriver {
  final WebTesseractDelegate _delegate;
  String? _languageTag;
  OcrPreprocessProfile _preprocessProfile;

  final ValueNotifier<WebOcrEngineStatus> statusNotifier = ValueNotifier(
    const WebOcrEngineStatus(),
  );

  WebTesseractOcrDriver({
    String? initialLanguageTag,
    OcrPreprocessProfile initialPreprocessProfile =
        OcrPreprocessProfile.cameraDisplay,
    WebTesseractDelegate? delegate,
  })  : _languageTag = initialLanguageTag,
        _preprocessProfile = initialPreprocessProfile,
        _delegate = delegate ?? browser_bridge.createBrowserTesseractDelegate() {
    final mapped = mapLanguageToTesseract(initialLanguageTag);
    statusNotifier.value = WebOcrEngineStatus(
      languageCode: mapped,
      cacheSource: (mapped == 'deu' || mapped == 'eng')
          ? WebOcrCacheSource.localBundled
          : WebOcrCacheSource.indexedDbCache,
    );
  }

  @override
  ValueListenable<WebOcrEngineStatus> get statusListenable => statusNotifier;

  @override
  String? get languageTag => _languageTag;

  @override
  void setLanguageTag(String? languageTag) {
    _languageTag = languageTag;
    final mapped = mapLanguageToTesseract(languageTag);
    statusNotifier.value = WebOcrEngineStatus(
      languageCode: mapped,
      cacheSource: (mapped == 'deu' || mapped == 'eng')
          ? WebOcrCacheSource.localBundled
          : WebOcrCacheSource.indexedDbCache,
    );
  }

  @override
  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  @override
  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
  }

  /// Maps PokéVault / BCP-47 language codes to Tesseract traineddata identifiers.
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

  /// Swaps BGRA8888 channel order to RGBA8888 expected by HTML Canvas `ImageData`.
  static Uint8List convertBgraToRgba(List<int> bgraBytes) {
    final rgba = Uint8List(bgraBytes.length);
    for (int i = 0; i + 3 < bgraBytes.length; i += 4) {
      rgba[i] = bgraBytes[i + 2]; // R
      rgba[i + 1] = bgraBytes[i + 1]; // G
      rgba[i + 2] = bgraBytes[i]; // B
      rgba[i + 3] = bgraBytes[i + 3]; // A
    }
    return rgba;
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
    final tesseractLang = mapLanguageToTesseract(_languageTag);
    final rawBytes = processed.bytes;
    final rgba = processed.pixelFormat == 'rgba8888'
        ? (rawBytes is Uint8List ? rawBytes : Uint8List.fromList(rawBytes))
        : convertBgraToRgba(rawBytes);

    final result = await _delegate.recognizeRgba(
      rgbaBytes: rgba,
      width: processed.width,
      height: processed.height,
      tesseractLang: tesseractLang,
    );

    statusNotifier.value = WebOcrEngineStatus(
      languageCode: tesseractLang,
      cacheSource: result.cacheSource,
      errorMessage: result.error,
    );

    return result.lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> dispose() async {
    await _delegate.dispose();
    statusNotifier.dispose();
  }
}

/// Web factory entry point matched by conditional import in `platform_camera_ocr_driver.dart`.
DesktopOcrDriver createPlatformCameraOcrDriver({
  Object? windowsBridge,
  String? initialLanguageTag,
  OcrPreprocessProfile initialPreprocessProfile =
      OcrPreprocessProfile.cameraDisplay,
}) {
  return WebTesseractOcrDriver(
    initialLanguageTag: initialLanguageTag,
    initialPreprocessProfile: initialPreprocessProfile,
  );
}
