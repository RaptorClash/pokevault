import 'package:flutter/services.dart';
import '../scanner_core/models/scanner_settings.dart';
import 'desktop_capture_driver.dart';
import 'desktop_ocr_driver.dart';
import 'screen_region.dart';
import 'window_detector.dart';

/// Result returned by native full-desktop snipping overlay.
class ScreenRegionCaptureResult {
  final ScreenRegion region;
  final Uint8List? previewBytes;

  const ScreenRegionCaptureResult({
    required this.region,
    this.previewBytes,
  });
}

/// Result returned by native OCR engine including fallback language info and diagnostics.
class OcrRecognitionResult {
  final List<String> lines;
  final bool usedFallbackLanguage;
  final String? resolvedLanguageTag;
  final String? requestedLanguageTag;
  final List<String> availableLanguageTags;
  final bool ocrSucceeded;
  final int? ocrDurationMs;
  final String? errorHint;

  const OcrRecognitionResult({
    this.lines = const [],
    this.usedFallbackLanguage = false,
    this.resolvedLanguageTag,
    this.requestedLanguageTag,
    this.availableLanguageTags = const [],
    this.ocrSucceeded = true,
    this.ocrDurationMs,
    this.errorHint,
  });
}

enum NativeHudActionType {
  markCaught,
  compactChanged,
  pinnedChanged,
  close,
  moved,
}

class NativeHudAction {
  final NativeHudActionType type;
  final bool? boolValue;
  final Offset? position;
  final int? pokemonId;

  const NativeHudAction({
    required this.type,
    this.boolValue,
    this.position,
    this.pokemonId,
  });
}

/// Single enemy row inside [NativeHudState.focusEntries] for multi-encounter HUDs.
class NativeHudFocusEntry {
  final int? pokemonId;
  final String pokemonName;
  final bool isShiny;
  final bool isCaught;
  final int encounterCount;

  const NativeHudFocusEntry({
    this.pokemonId,
    required this.pokemonName,
    this.isShiny = false,
    this.isCaught = false,
    this.encounterCount = 1,
  });

  Map<String, dynamic> toMap() => {
        'pokemonId': pokemonId ?? 0,
        'pokemonName': pokemonName,
        'isShiny': isShiny,
        'isCaught': isCaught,
        'encounterCount': encounterCount,
      };
}

/// Descriptor for one colored hollow desktop overlay rectangle (`Zone A`, `Zone B` cyan, or Multi-Instance slots).
class OverlayBorderSpec {
  final String id;
  final ScreenRegion region;
  final int colorArgb;
  final String label;
  final bool visible;

  const OverlayBorderSpec({
    required this.id,
    required this.region,
    required this.colorArgb,
    this.label = '',
    this.visible = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'x': region.x,
        'y': region.y,
        'width': region.width,
        'height': region.height,
        'colorArgb': colorArgb,
        'label': label,
        'visible': visible,
      };
}

/// Immutable payload synchronizing the native Always-on-Top desktop HUD.
class NativeHudState {
  final String pokemonName;
  final int? pokemonId;
  final bool isShiny;
  final bool isCaught;
  final bool isCompact;
  final bool isPinned;
  final double opacity;
  final bool hasEvent;
  final Rect? anchorRect;
  final String evolutionSummary;
  final bool hasMissingEvolutions;
  final String? instanceLabel;
  final String? waitingLabel;
  final String? caughtLabel;
  final String? missingLabel;
  final String? footerLabel;
  final List<NativeHudFocusEntry> focusEntries;

  const NativeHudState({
    this.pokemonName = 'Warte auf Spiel...',
    this.pokemonId,
    this.isShiny = false,
    this.isCaught = false,
    this.isCompact = false,
    this.isPinned = true,
    this.opacity = 0.92,
    this.hasEvent = false,
    this.anchorRect,
    this.evolutionSummary = '',
    this.hasMissingEvolutions = false,
    this.instanceLabel,
    this.waitingLabel,
    this.caughtLabel,
    this.missingLabel,
    this.footerLabel,
    this.focusEntries = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'pokemonName': pokemonName,
      'pokemonId': pokemonId ?? 0,
      'isShiny': isShiny,
      'isCaught': isCaught,
      'isCompact': isCompact,
      'isPinned': isPinned,
      'opacity': opacity,
      'hasEvent': hasEvent,
      'evolutionSummary': evolutionSummary,
      'hasMissingEvolutions': hasMissingEvolutions,
      if (focusEntries.isNotEmpty)
        'focusEntries': focusEntries.map((e) => e.toMap()).toList(),
      if (instanceLabel != null) 'instanceLabel': instanceLabel,
      if (waitingLabel != null) 'waitingLabel': waitingLabel,
      if (caughtLabel != null) 'caughtLabel': caughtLabel,
      if (missingLabel != null) 'missingLabel': missingLabel,
      if (footerLabel != null) 'footerLabel': footerLabel,
      if (anchorRect != null)
        'anchorRect': {
          'x': anchorRect!.left,
          'y': anchorRect!.top,
          'width': anchorRect!.width,
          'height': anchorRect!.height,
        },
    };
  }
}

/// Abstract platform bridge for desktop tracker operations.
abstract class DesktopPlatformBridge {
  ValueChanged<NativeHudAction>? get onHudAction;
  set onHudAction(ValueChanged<NativeHudAction>? callback);

  Future<List<DesktopWindowInfo>> enumerateWindowsAndMonitors();

  Future<ScreenRegionCaptureResult?> startDesktopSnipping({
    bool hideAppWindow = false,
    String? hintLabel,
    String? confirmLabel,
    String? cancelLabel,
  });

  Future<CapturedFrame?> captureRegion(ScreenRegion region);

  Future<CapturedFrame?> captureWindow(
    DesktopWindowInfo window, {
    Rect? cropRegion,
  });

  Future<OcrRecognitionResult> recognizeText(
    CapturedFrame frame, {
    String? languageTag,
    String? preprocessProfile,
  });

  Future<bool> showFloatingHud(NativeHudState state);

  Future<bool> updateFloatingHud(NativeHudState state);

  Future<void> hideFloatingHud();

  Future<void> setScanRegionBorder(
    ScreenRegion? region, {
    bool active = true,
  });

  Future<void> setOverlayBorders(List<OverlayBorderSpec> borders) async {}
}

/// Windows MethodChannel implementation backed by `DesktopTrackerPlugin` in C++.
class WindowsDesktopBridge implements DesktopPlatformBridge {
  static final WindowsDesktopBridge instance = WindowsDesktopBridge();

  final MethodChannel channel;
  @override
  ValueChanged<NativeHudAction>? onHudAction;

  WindowsDesktopBridge({
    this.channel = const MethodChannel('pokevault/desktop_tracker'),
  }) {
    channel.setMethodCallHandler(_handleIncomingCall);
  }

  /// Maps PokéVault franchise language codes (e.g. `de`, `ja`, `zh-Hans`) to BCP-47 tags.
  static String mapPokemonLanguageToBcp47(String code) {
    switch (code.trim().toLowerCase()) {
      case 'de':
        return 'de-DE';
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'it':
        return 'it-IT';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'nl':
        return 'nl-NL';
      case 'pl':
        return 'pl-PL';
      case 'pt':
        return 'pt-BR';
      case 'ru':
        return 'ru-RU';
      case 'zh-hans':
        return 'zh-Hans';
      case 'zh-hant':
        return 'zh-Hant';
      default:
        return 'en-US';
    }
  }

  Future<dynamic> _handleIncomingCall(MethodCall call) async {
    final cb = onHudAction;
    if (cb == null) return null;

    switch (call.method) {
      case 'onHudMarkCaught':
        final args = call.arguments as Map?;
        final pid = (args?['pokemonId'] as num?)?.toInt();
        cb(NativeHudAction(
          type: NativeHudActionType.markCaught,
          pokemonId: pid != null && pid > 0 ? pid : null,
        ));
        break;
      case 'onHudClose':
        cb(const NativeHudAction(type: NativeHudActionType.close));
        break;
      case 'onHudCompactChanged':
        final args = call.arguments as Map?;
        cb(NativeHudAction(
          type: NativeHudActionType.compactChanged,
          boolValue: args?['isCompact'] as bool?,
        ));
        break;
      case 'onHudPinnedChanged':
        final args = call.arguments as Map?;
        cb(NativeHudAction(
          type: NativeHudActionType.pinnedChanged,
          boolValue: args?['isPinned'] as bool?,
        ));
        break;
      case 'onHudMoved':
        final args = call.arguments as Map?;
        final x = (args?['x'] as num?)?.toDouble();
        final y = (args?['y'] as num?)?.toDouble();
        if (x != null && y != null) {
          cb(NativeHudAction(
            type: NativeHudActionType.moved,
            position: Offset(x, y),
          ));
        }
        break;
    }
    return null;
  }

  @override
  Future<List<DesktopWindowInfo>> enumerateWindowsAndMonitors() async {
    try {
      final raw = await channel.invokeMapMethod<String, dynamic>(
        'enumerateWindows',
      );
      if (raw == null) return const [];

      final results = <DesktopWindowInfo>[];
      final detector = WindowDetector();

      final rawMonitors = raw['monitors'] as List?;
      if (rawMonitors != null) {
        for (final item in rawMonitors) {
          if (item is! Map) continue;
          final x = (item['x'] as num?)?.toDouble() ?? 0.0;
          final y = (item['y'] as num?)?.toDouble() ?? 0.0;
          final w = (item['width'] as num?)?.toDouble() ?? 1920.0;
          final h = (item['height'] as num?)?.toDouble() ?? 1080.0;
          final idx = (item['index'] as num?)?.toInt() ?? 1;
          final isVirtual = item['isVirtualDesktop'] as bool? ?? false;
          final title = (item['title'] as String?)?.trim();
          if (title == null || title.isEmpty) continue;

          results.add(DesktopWindowInfo(
            id: isVirtual ? -99 : -idx,
            hwnd: 0,
            title: title,
            processName: 'Desktop',
            width: w,
            height: h,
            bounds: Rect.fromLTWH(x, y, w, h),
            isDesktopScreen: true,
            isVirtualDesktop: isVirtual,
            monitorIndex: idx,
          ));
        }
      }

      final rawWindows = raw['windows'] as List?;
      if (rawWindows != null) {
        for (final item in rawWindows) {
          if (item is! Map) continue;
          final hwnd = (item['hwnd'] as num?)?.toInt() ?? 0;
          final pid = (item['pid'] as num?)?.toInt() ?? 0;
          final title = (item['title'] as String?) ?? '';
          final processName = item['processName'] as String?;
          final x = (item['x'] as num?)?.toDouble() ?? 0.0;
          final y = (item['y'] as num?)?.toDouble() ?? 0.0;
          final w = (item['width'] as num?)?.toDouble() ?? 800.0;
          final h = (item['height'] as num?)?.toDouble() ?? 600.0;
          final isMinimized = item['isMinimized'] as bool? ?? false;

          if (title.trim().isEmpty) continue;
          final identified = detector.identifyEmulator(
            title,
            id: pid,
            hwnd: hwnd,
            processName: processName,
            width: w,
            height: h,
            bounds: Rect.fromLTWH(x, y, w, h),
            isMinimized: isMinimized,
          );
          results.add(identified);
        }
      }

      return detector.filterAndRankWindows(results);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<ScreenRegionCaptureResult?> startDesktopSnipping({
    bool hideAppWindow = false,
    String? hintLabel,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    try {
      final raw = await channel.invokeMapMethod<String, dynamic>(
        'startDesktopSnipping',
        {
          'hideAppWindow': hideAppWindow,
          'hintLabel': ?hintLabel,
          'confirmLabel': ?confirmLabel,
          'cancelLabel': ?cancelLabel,
        },
      );
      if (raw == null) return null;

      final x = (raw['x'] as num?)?.toDouble();
      final y = (raw['y'] as num?)?.toDouble();
      final width = (raw['width'] as num?)?.toDouble();
      final height = (raw['height'] as num?)?.toDouble();
      if (x == null || y == null || width == null || height == null) {
        return null;
      }

      final previewRaw = raw['previewPng'];
      Uint8List? previewBytes;
      if (previewRaw is Uint8List) {
        previewBytes = previewRaw;
      } else if (previewRaw is List<int>) {
        previewBytes = Uint8List.fromList(previewRaw);
      }

      return ScreenRegionCaptureResult(
        region: ScreenRegion(
          x: x,
          y: y,
          width: width,
          height: height,
          isAbsoluteScreen: true,
          label: 'Desktop-Snipping',
        ),
        previewBytes: previewBytes,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CapturedFrame?> captureRegion(ScreenRegion region) async {
    try {
      final raw = await channel.invokeMapMethod<String, dynamic>(
        'captureRegion',
        {
          'x': region.x,
          'y': region.y,
          'width': region.width,
          'height': region.height,
        },
      );
      return _parseCapturedFrame(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CapturedFrame?> captureWindow(
    DesktopWindowInfo window, {
    Rect? cropRegion,
  }) async {
    try {
      if (window.isDesktopScreen) {
        final targetRect = window.bounds ??
            Rect.fromLTWH(0, 0, window.width, window.height);
        final effectiveRect = cropRegion != null
            ? Rect.fromLTWH(
                targetRect.left + cropRegion.left,
                targetRect.top + cropRegion.top,
                cropRegion.width,
                cropRegion.height,
              )
            : targetRect;
        return await captureRegion(
          ScreenRegion.fromRect(effectiveRect, isAbsoluteScreen: true),
        );
      }

      if (window.hwnd <= 0 || window.isMinimized) return null;

      final raw = await channel.invokeMapMethod<String, dynamic>(
        'captureWindow',
        {
          'hwnd': window.hwnd,
          if (cropRegion != null)
            'cropRegion': {
              'x': cropRegion.left,
              'y': cropRegion.top,
              'width': cropRegion.width,
              'height': cropRegion.height,
            },
        },
      );
      return _parseCapturedFrame(raw);
    } catch (_) {
      return null;
    }
  }

  CapturedFrame? _parseCapturedFrame(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final width = (raw['width'] as num?)?.toInt() ?? 0;
    final height = (raw['height'] as num?)?.toInt() ?? 0;
    final bytesRaw = raw['bytes'];
    if (width <= 0 || height <= 0 || bytesRaw is! List) {
      return null;
    }
    final Uint8List bytes;
    if (bytesRaw is Uint8List) {
      bytes = bytesRaw;
    } else if (bytesRaw is List<int>) {
      bytes = Uint8List.fromList(bytesRaw);
    } else {
      bytes = Uint8List.fromList(bytesRaw.whereType<num>().map((n) => n.toInt()).toList(growable: false));
    }
    return CapturedFrame(
      width: width,
      height: height,
      bytes: bytes,
      pixelFormat: (raw['pixelFormat'] as String?) ?? 'bgra8888',
      captureMethod: raw['captureMethod'] as String?,
    );
  }

  @override
  Future<OcrRecognitionResult> recognizeText(
    CapturedFrame frame, {
    String? languageTag,
    String? preprocessProfile,
  }) async {
    if (frame.width <= 0 || frame.height <= 0 || frame.bytes.isEmpty) {
      return const OcrRecognitionResult(
        ocrSucceeded: false,
        errorHint: 'Empty frame',
      );
    }
    try {
      final raw = await channel.invokeMapMethod<String, dynamic>(
        'recognizeText',
        {
          'width': frame.width,
          'height': frame.height,
          'pixelFormat': frame.pixelFormat,
          'bytes': frame.bytes is Uint8List
              ? frame.bytes
              : Uint8List.fromList(frame.bytes),
          if (languageTag != null && languageTag.isNotEmpty)
            'languageTag': languageTag,
          if (preprocessProfile != null && preprocessProfile.isNotEmpty)
            'preprocessProfile': preprocessProfile,
        },
      );
      if (raw == null) {
        return OcrRecognitionResult(
          requestedLanguageTag: languageTag,
          ocrSucceeded: false,
          errorHint: 'Native channel returned null',
        );
      }
      final linesRaw = raw['lines'] as List? ?? const [];
      final lines = linesRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final availRaw = raw['availableLanguages'] as List? ?? const [];
      final availableLanguageTags = availRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return OcrRecognitionResult(
        lines: lines,
        usedFallbackLanguage: raw['usedFallbackLanguage'] as bool? ?? false,
        resolvedLanguageTag: raw['resolvedLanguageTag'] as String?,
        requestedLanguageTag:
            (raw['requestedLanguageTag'] as String?) ?? languageTag,
        availableLanguageTags: availableLanguageTags,
        ocrSucceeded: raw['ocrSucceeded'] as bool? ?? true,
        ocrDurationMs: (raw['ocrDurationMs'] as num?)?.toInt(),
        errorHint: raw['errorHint'] as String?,
      );
    } catch (e) {
      return OcrRecognitionResult(
        requestedLanguageTag: languageTag,
        ocrSucceeded: false,
        errorHint: e.toString(),
      );
    }
  }

  @override
  Future<bool> showFloatingHud(NativeHudState state) async {
    try {
      final res = await channel.invokeMethod<bool>(
        'showFloatingHud',
        state.toMap(),
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> updateFloatingHud(NativeHudState state) async {
    try {
      final res = await channel.invokeMethod<bool>(
        'updateFloatingHud',
        state.toMap(),
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> hideFloatingHud() async {
    try {
      await channel.invokeMethod<bool>('hideFloatingHud');
    } catch (_) {}
  }

  @override
  Future<void> setScanRegionBorder(
    ScreenRegion? region, {
    bool active = true,
  }) async {
    try {
      if (region == null || !region.isAbsoluteScreen) {
        await channel.invokeMethod<bool>('hideScanRegionBorder');
        return;
      }
      await channel.invokeMethod<bool>('showScanRegionBorder', {
        'x': region.x,
        'y': region.y,
        'width': region.width,
        'height': region.height,
        'active': active,
      });
    } catch (_) {}
  }

  @override
  Future<void> setOverlayBorders(List<OverlayBorderSpec> borders) async {
    try {
      await channel.invokeMethod<bool>('setOverlayBorders', {
        'borders': borders
            .where((b) => b.visible && b.region.isAbsoluteScreen)
            .map((b) => b.toMap())
            .toList(),
      });
    } catch (_) {}
  }
}

/// Default Windows capture driver delegating to [DesktopPlatformBridge].
class WindowsDesktopCaptureDriver extends DefaultDesktopCaptureDriver {
  WindowsDesktopCaptureDriver({DesktopPlatformBridge? bridge})
      : super(
          nativeCaptureHandler: (window, cropRegion, screenRegion) async {
            final b = bridge ?? WindowsDesktopBridge.instance;
            if (screenRegion != null && screenRegion.isAbsoluteScreen) {
              return b.captureRegion(screenRegion);
            }
            return b.captureWindow(window, cropRegion: cropRegion);
          },
        );
}

/// Default Windows OCR driver delegating to [DesktopPlatformBridge] with game language
/// and preprocessing profile support.
class WindowsDesktopOcrDriver extends DefaultDesktopOcrDriver
    implements PreprocessAwareOcrDriver {
  final DesktopPlatformBridge? bridge;
  final ValueChanged<OcrRecognitionResult>? onRecognitionResult;
  OcrRecognitionResult? lastRecognitionResult;
  OcrPreprocessProfile _preprocessProfile;

  WindowsDesktopOcrDriver({
    this.bridge,
    super.initialLanguageTag,
    OcrPreprocessProfile initialPreprocessProfile = OcrPreprocessProfile.standard,
    this.onRecognitionResult,
  }) : _preprocessProfile = initialPreprocessProfile;

  @override
  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  @override
  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
  }

  /// Runs OCR and returns full diagnostic metadata alongside trimmed lines.
  Future<OcrRecognitionResult> recognizeTextDetailed(
    CapturedFrame frame, {
    OcrPreprocessProfile? profileOverride,
  }) async {
    if (frame.width <= 0 || frame.height <= 0) {
      return const OcrRecognitionResult(
        ocrSucceeded: false,
        errorHint: 'Empty frame dimensions',
      );
    }
    final b = bridge ?? WindowsDesktopBridge.instance;
    final activeProfile = profileOverride ?? _preprocessProfile;
    final res = await b.recognizeText(
      frame,
      languageTag: languageTag,
      preprocessProfile: activeProfile.name,
    );
    lastRecognitionResult = res;
    onRecognitionResult?.call(res);
    return res;
  }

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    final res = await recognizeTextDetailed(frame);
    return res.lines;
  }
}
