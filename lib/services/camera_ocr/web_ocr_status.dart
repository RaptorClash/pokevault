import 'package:flutter/foundation.dart';

/// Cache/origin state of the browser-side Tesseract.js language pack.
enum WebOcrCacheSource {
  localBundled,
  indexedDbCache,
  downloadedToIndexedDb,
  error,
}

/// Immutable status snapshot exposed to the Camera Tracker UI on Web.
class WebOcrEngineStatus {
  final String languageCode;
  final WebOcrCacheSource cacheSource;
  final bool isBusy;
  final String? errorMessage;

  const WebOcrEngineStatus({
    this.languageCode = 'deu',
    this.cacheSource = WebOcrCacheSource.localBundled,
    this.isBusy = false,
    this.errorMessage,
  });

  String get displayLabelDe {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return 'Web-OCR Fehler';
    }
    if (isBusy) {
      return 'Lade ${languageCode.toUpperCase()}...';
    }
    switch (cacheSource) {
      case WebOcrCacheSource.localBundled:
        return 'Tesseract.js (Lokal: ${languageCode.toUpperCase()})';
      case WebOcrCacheSource.indexedDbCache:
      case WebOcrCacheSource.downloadedToIndexedDb:
        return 'Tesseract.js (${languageCode.toUpperCase()} · IndexedDB)';
      case WebOcrCacheSource.error:
        return 'Web-OCR Fehler';
    }
  }
}

/// Optional interface implemented by Web OCR drivers so the UI can render status pills.
abstract class WebOcrStatusReportingDriver {
  ValueListenable<WebOcrEngineStatus> get statusListenable;
}
