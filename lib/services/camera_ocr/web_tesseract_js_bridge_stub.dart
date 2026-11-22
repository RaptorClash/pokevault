import 'dart:typed_data';
import 'web_ocr_status.dart';

/// Result returned by a Web Tesseract delegate invocation.
class WebTesseractResult {
  final List<String> lines;
  final WebOcrCacheSource cacheSource;
  final String? error;

  const WebTesseractResult({
    this.lines = const [],
    this.cacheSource = WebOcrCacheSource.localBundled,
    this.error,
  });
}

/// Abstraction over `window.pokevaultWebOcr` so [WebTesseractOcrDriver] is testable on VM.
abstract class WebTesseractDelegate {
  Future<WebTesseractResult> recognizeRgba({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required String tesseractLang,
  });

  Future<void> dispose();
}

/// Stub fallback when not running in a browser JS runtime.
WebTesseractDelegate createBrowserTesseractDelegate() =>
    const _UnsupportedWebTesseractDelegate();

class _UnsupportedWebTesseractDelegate implements WebTesseractDelegate {
  const _UnsupportedWebTesseractDelegate();

  @override
  Future<WebTesseractResult> recognizeRgba({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required String tesseractLang,
  }) async {
    return const WebTesseractResult(
      cacheSource: WebOcrCacheSource.error,
      error: 'Web OCR JS runtime is unavailable outside a browser.',
    );
  }

  @override
  Future<void> dispose() async {}
}
