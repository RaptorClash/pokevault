import 'dart:js_interop';
import 'dart:typed_data';
import 'web_ocr_status.dart';
import 'web_tesseract_js_bridge_stub.dart';

export 'web_tesseract_js_bridge_stub.dart'
    show WebTesseractDelegate, WebTesseractResult;

@JS('pokevaultWebOcr')
external _JsPokevaultWebOcr? get _jsPokevaultWebOcr;

@JS()
extension type _JsPokevaultWebOcr(JSObject _) implements JSObject {
  external JSPromise<_JsWebOcrResult> recognizeRgba(
    JSUint8Array rgbaBytes,
    int width,
    int height,
    String langCode,
  );

  external JSPromise<JSAny?> dispose();
}

@JS()
extension type _JsWebOcrResult(JSObject _) implements JSObject {
  external JSArray<JSString>? get lines;
  external String? get cacheSource;
  external String? get error;
}

WebTesseractDelegate createBrowserTesseractDelegate() =>
    const _BrowserWebTesseractDelegate();

class _BrowserWebTesseractDelegate implements WebTesseractDelegate {
  const _BrowserWebTesseractDelegate();

  @override
  Future<WebTesseractResult> recognizeRgba({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required String tesseractLang,
  }) async {
    final bridge = _jsPokevaultWebOcr;
    if (bridge == null) {
      return const WebTesseractResult(
        cacheSource: WebOcrCacheSource.error,
        error: 'window.pokevaultWebOcr ist nicht initialisiert.',
      );
    }

    try {
      final res = await bridge
          .recognizeRgba(rgbaBytes.toJS, width, height, tesseractLang)
          .toDart;
      final rawLines = res.lines?.toDart ?? const <JSString>[];
      final parsedLines = rawLines
          .map((e) => e.toDart.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final src = switch (res.cacheSource) {
        'indexedDbCache' => WebOcrCacheSource.indexedDbCache,
        'downloadedToIndexedDb' => WebOcrCacheSource.downloadedToIndexedDb,
        'error' => WebOcrCacheSource.error,
        _ => WebOcrCacheSource.localBundled,
      };
      return WebTesseractResult(
        lines: parsedLines,
        cacheSource: src,
        error: res.error,
      );
    } catch (e) {
      return WebTesseractResult(
        cacheSource: WebOcrCacheSource.error,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> dispose() async {
    final bridge = _jsPokevaultWebOcr;
    if (bridge == null) return;
    try {
      await bridge.dispose().toDart;
    } catch (_) {}
  }
}
