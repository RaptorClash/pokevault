import '../../desktop_tracker/screen_region.dart';
import 'scanner_event.dart';

/// Supported OCR language overrides shared across Desktop & Mobile trackers.
const List<({String code, String label})> kSupportedScannerOcrLanguages = [
  (code: 'auto', label: 'Automatisch (App/Dex-Sprache)'),
  (code: 'de', label: 'Deutsch (DE)'),
  (code: 'en', label: 'English (EN)'),
  (code: 'fr', label: 'Français (FR)'),
  (code: 'es', label: 'Español (ES)'),
  (code: 'it', label: 'Italiano (IT)'),
  (code: 'ja', label: '日本語 (JA)'),
  (code: 'ko', label: '한국어 (KO)'),
  (code: 'zh-Hans', label: '简体中文 (ZH-Hans)'),
  (code: 'zh-Hant', label: '繁體中文 (ZH-Hant)'),
];

/// Behavior for Living Dex when an evolution is recognized.
enum LivingDexEvolutionAction {
  askBeforeRemoving,
  autoRemovePreEvolution,
  keepPreEvolution,
}

/// Display and interaction mode for the desktop overlay.
enum DesktopOverlayMode {
  floatingHud,
  clickThroughOverlay,
  silentBackground,
}

/// Image preprocessing profile before running local/camera OCR.
enum OcrPreprocessProfile {
  standard,
  pixelArtDs,
  cameraDisplay,
}

extension OcrPreprocessProfileUi on OcrPreprocessProfile {
  String get labelDe => switch (this) {
        OcrPreprocessProfile.standard => 'Standard',
        OcrPreprocessProfile.pixelArtDs => 'Pixel-Art (DS)',
        OcrPreprocessProfile.cameraDisplay => 'Kamera / Display',
      };
}

/// Pre-configured scan regions for different console types and emulator layouts.
enum ScanRegionPreset {
  fullWindow,
  dsTopScreen,
  dsBottomScreen,
  bottomDialogue,
}

extension ScanRegionPresetUi on ScanRegionPreset {
  String get labelDe => switch (this) {
        ScanRegionPreset.fullWindow => 'Ganzes Fenster',
        ScanRegionPreset.dsTopScreen => 'DS Oben',
        ScanRegionPreset.dsBottomScreen => 'DS Unten',
        ScanRegionPreset.bottomDialogue => 'Textbox unten',
      };
}

/// Optional second scan zone targeting the opponent HUD purely for Live-Fokus encounters.
enum LiveFocusPreset {
  disabled,
  topLeft,
  topRight,
  topBanner,
  customRegion,
}

extension LiveFocusPresetUi on LiveFocusPreset {
  String get labelDe => switch (this) {
        LiveFocusPreset.disabled => 'Aus',
        LiveFocusPreset.topLeft => 'Oben Links',
        LiveFocusPreset.topRight => 'Oben Rechts',
        LiveFocusPreset.topBanner => 'Oberer Streifen',
        LiveFocusPreset.customRegion => 'Eigener Bereich',
      };
}

/// User-defined OCR pattern rule supporting `{pokemon}` and `*` wildcards.
class CustomOcrPattern {
  final String id;
  final String template;
  final ScannerEventType eventType;
  final bool enabled;

  const CustomOcrPattern({
    required this.id,
    required this.template,
    this.eventType = ScannerEventType.caught,
    this.enabled = true,
  });

  CustomOcrPattern copyWith({
    String? id,
    String? template,
    ScannerEventType? eventType,
    bool? enabled,
  }) {
    return CustomOcrPattern(
      id: id ?? this.id,
      template: template ?? this.template,
      eventType: eventType ?? this.eventType,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template': template,
      'eventType': eventType.name,
      'enabled': enabled,
    };
  }

  factory CustomOcrPattern.fromMap(Map<String, dynamic> map) {
    ScannerEventType type = ScannerEventType.caught;
    final typeStr = map['eventType']?.toString();
    if (typeStr != null) {
      for (final value in ScannerEventType.values) {
        if (value.name == typeStr) {
          type = value;
          break;
        }
      }
    }
    return CustomOcrPattern(
      id: map['id']?.toString() ?? '',
      template: map['template']?.toString() ?? '',
      eventType: type,
      enabled: map['enabled'] as bool? ?? true,
    );
  }
}

/// A coupled instance in Multi-Instance Shiny-Hunting mode (Scan #N + Fokus #N and/or bound window).
class MultiInstanceSlot {
  final int id;
  final String label;
  final int colorHex;
  final bool enabled;
  final bool scanEnabled;
  final ScreenRegion? scanRegion;
  final ScreenRegion? focusRegion;
  final LiveFocusPreset focusPreset;
  final ScanRegionPreset scanPreset;
  final int? windowHwnd;
  final int? windowId;
  final String? windowTitle;

  const MultiInstanceSlot({
    required this.id,
    required this.label,
    required this.colorHex,
    this.enabled = true,
    this.scanEnabled = true,
    ScreenRegion? scanRegion,
    ScreenRegion? region,
    this.focusRegion,
    this.focusPreset = LiveFocusPreset.disabled,
    this.scanPreset = ScanRegionPreset.bottomDialogue,
    this.windowHwnd,
    this.windowId,
    this.windowTitle,
  }) : scanRegion = scanRegion ?? region;

  /// Legacy single-box accessor for backward compatibility with older grid helpers/tests.
  ScreenRegion get region =>
      scanRegion ??
      focusRegion ??
      ScreenRegion(x: 0, y: 0, width: 100, height: 100, isAbsoluteScreen: true);

  bool get isWindowBound =>
      (windowHwnd != null && windowHwnd != 0) ||
      (windowId != null && windowId != 0) ||
      (windowTitle != null && windowTitle!.trim().isNotEmpty);

  bool get hasScan =>
      enabled && scanEnabled && (scanRegion != null || isWindowBound);

  bool get hasFocus =>
      enabled &&
      focusPreset != LiveFocusPreset.disabled &&
      (focusPreset == LiveFocusPreset.customRegion
          ? focusRegion != null
          : isWindowBound);

  MultiInstanceSlot copyWith({
    int? id,
    String? label,
    int? colorHex,
    bool? enabled,
    bool? scanEnabled,
    ScreenRegion? scanRegion,
    ScreenRegion? region,
    ScreenRegion? focusRegion,
    LiveFocusPreset? focusPreset,
    ScanRegionPreset? scanPreset,
    int? windowHwnd,
    int? windowId,
    String? windowTitle,
    bool clearScanRegion = false,
    bool clearFocusRegion = false,
    bool clearWindow = false,
  }) {
    return MultiInstanceSlot(
      id: id ?? this.id,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
      enabled: enabled ?? this.enabled,
      scanEnabled: scanEnabled ?? this.scanEnabled,
      scanRegion:
          clearScanRegion ? null : (scanRegion ?? region ?? this.scanRegion),
      focusRegion: clearFocusRegion ? null : (focusRegion ?? this.focusRegion),
      focusPreset: focusPreset ?? this.focusPreset,
      scanPreset: scanPreset ?? this.scanPreset,
      windowHwnd: clearWindow ? null : (windowHwnd ?? this.windowHwnd),
      windowId: clearWindow ? null : (windowId ?? this.windowId),
      windowTitle: clearWindow ? null : (windowTitle ?? this.windowTitle),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'colorHex': colorHex,
        'enabled': enabled,
        'scanEnabled': scanEnabled,
        'scanPreset': scanPreset.name,
        'focusPreset': focusPreset.name,
        if (scanRegion != null) 'scanRegion': scanRegion!.toMap(),
        if (scanRegion != null) 'region': scanRegion!.toMap(),
        if (focusRegion != null) 'focusRegion': focusRegion!.toMap(),
        if (windowHwnd != null) 'windowHwnd': windowHwnd,
        if (windowId != null) 'windowId': windowId,
        if (windowTitle != null) 'windowTitle': windowTitle,
      };

  factory MultiInstanceSlot.fromMap(Map<String, dynamic> map) {
    final rawScanMap = map['scanRegion'] ?? map['region'];
    final ScreenRegion? parsedScan = rawScanMap is Map
        ? ScreenRegion.fromMap(Map<String, dynamic>.from(rawScanMap))
        : null;
    final rawFocusMap = map['focusRegion'];
    final ScreenRegion? parsedFocus = rawFocusMap is Map
        ? ScreenRegion.fromMap(Map<String, dynamic>.from(rawFocusMap))
        : null;

    var parsedScanPreset = ScanRegionPreset.bottomDialogue;
    final scanPresetName = map['scanPreset']?.toString();
    if (scanPresetName != null) {
      for (final value in ScanRegionPreset.values) {
        if (value.name == scanPresetName) {
          parsedScanPreset = value;
          break;
        }
      }
    }

    var parsedFocusPreset =
        parsedFocus != null ? LiveFocusPreset.customRegion : LiveFocusPreset.disabled;
    final focusPresetName = map['focusPreset']?.toString();
    if (focusPresetName != null) {
      for (final value in LiveFocusPreset.values) {
        if (value.name == focusPresetName) {
          parsedFocusPreset = value;
          break;
        }
      }
    }

    return MultiInstanceSlot(
      id: (map['id'] as num?)?.toInt() ?? 1,
      label: map['label']?.toString() ?? '#1',
      colorHex: (map['colorHex'] as num?)?.toInt() ?? 0xFFA855F7,
      enabled: map['enabled'] as bool? ?? true,
      scanEnabled: map['scanEnabled'] as bool? ?? true,
      scanRegion: parsedScan,
      focusRegion: parsedFocus,
      focusPreset: parsedFocusPreset,
      scanPreset: parsedScanPreset,
      windowHwnd: (map['windowHwnd'] as num?)?.toInt(),
      windowId: (map['windowId'] as num?)?.toInt(),
      windowTitle: map['windowTitle']?.toString(),
    );
  }
}

/// Splits one large desktop capture rectangle into equal numbered multi-instance slots.
class MultiInstanceGridHelper {
  static const List<int> defaultPalette = [
    0xFFA855F7, // Violet (#1)
    0xFFEC4899, // Pink (#2)
    0xFFF59E0B, // Amber (#3)
    0xFF3B82F6, // Blue (#4)
    0xFF14B8A6, // Teal (#5)
    0xFFF97316, // Orange (#6)
  ];

  static int colorForIndex(int zeroBasedIndex) {
    return defaultPalette[zeroBasedIndex % defaultPalette.length];
  }

  static List<MultiInstanceSlot> splitRegionIntoGrid(
    ScreenRegion region, {
    required int rows,
    required int cols,
  }) {
    final safeRows = rows < 1 ? 1 : (rows > 4 ? 4 : rows);
    final safeCols = cols < 1 ? 1 : (cols > 4 ? 4 : cols);
    final cellW = region.width / safeCols;
    final cellH = region.height / safeRows;
    final slots = <MultiInstanceSlot>[];
    int n = 1;
    for (int r = 0; r < safeRows; r++) {
      for (int c = 0; c < safeCols; c++) {
        slots.add(
          MultiInstanceSlot(
            id: n,
            label: '#$n',
            region: ScreenRegion(
              x: region.x + c * cellW,
              y: region.y + r * cellH,
              width: cellW,
              height: cellH,
              isAbsoluteScreen: region.isAbsoluteScreen,
              label: 'Instanz #$n',
            ),
            colorHex: colorForIndex(n - 1),
          ),
        );
        n++;
      }
    }
    return List.unmodifiable(slots);
  }
}

/// User configurable settings for OCR detection, overlay presentation, and feedback.
class ScannerSettings {
  final bool autoMarkCaught;
  final bool trackEvolutions;
  final LivingDexEvolutionAction livingDexEvolutionAction;
  final bool detectShinies;
  final bool detectAlphas;
  final bool playAudioFeedback;
  final bool playHapticFeedback;
  final DesktopOverlayMode desktopOverlayMode;
  final String ocrLanguage;
  final OcrPreprocessProfile preprocessProfile;
  final int scanIntervalMs;
  final List<CustomOcrPattern> customPatterns;
  final LiveFocusPreset liveFocusPreset;
  final List<int> ignoredPokemonIds;
  final bool showScreenBorders;
  final List<MultiInstanceSlot> multiInstanceSlots;
  final List<ScreenRegion> extraFocusRegions;
  final bool maskSelfWindow;
  final bool suppressSelfScanWarning;

  static const int minScanIntervalMs = 150;
  static const int maxScanIntervalMs = 5000;
  static const int defaultScanIntervalMs = 400;

  const ScannerSettings({
    this.autoMarkCaught = true,
    this.trackEvolutions = true,
    this.livingDexEvolutionAction = LivingDexEvolutionAction.askBeforeRemoving,
    this.detectShinies = true,
    this.detectAlphas = true,
    this.playAudioFeedback = true,
    this.playHapticFeedback = true,
    this.desktopOverlayMode = DesktopOverlayMode.floatingHud,
    this.ocrLanguage = 'auto',
    this.preprocessProfile = OcrPreprocessProfile.standard,
    this.scanIntervalMs = defaultScanIntervalMs,
    this.customPatterns = const [],
    this.liveFocusPreset = LiveFocusPreset.disabled,
    this.ignoredPokemonIds = const [],
    this.showScreenBorders = true,
    this.multiInstanceSlots = const [],
    this.extraFocusRegions = const [],
    this.maskSelfWindow = false,
    this.suppressSelfScanWarning = false,
  });

  factory ScannerSettings.defaults() => const ScannerSettings();

  static int clampScanIntervalMs(int value) {
    if (value < minScanIntervalMs) return minScanIntervalMs;
    if (value > maxScanIntervalMs) return maxScanIntervalMs;
    return value;
  }

  ScannerSettings copyWith({
    bool? autoMarkCaught,
    bool? trackEvolutions,
    LivingDexEvolutionAction? livingDexEvolutionAction,
    bool? detectShinies,
    bool? detectAlphas,
    bool? playAudioFeedback,
    bool? playHapticFeedback,
    DesktopOverlayMode? desktopOverlayMode,
    String? ocrLanguage,
    OcrPreprocessProfile? preprocessProfile,
    int? scanIntervalMs,
    List<CustomOcrPattern>? customPatterns,
    LiveFocusPreset? liveFocusPreset,
    List<int>? ignoredPokemonIds,
    bool? showScreenBorders,
    List<MultiInstanceSlot>? multiInstanceSlots,
    List<ScreenRegion>? extraFocusRegions,
    bool? maskSelfWindow,
    bool? suppressSelfScanWarning,
  }) {
    return ScannerSettings(
      autoMarkCaught: autoMarkCaught ?? this.autoMarkCaught,
      trackEvolutions: trackEvolutions ?? this.trackEvolutions,
      livingDexEvolutionAction:
          livingDexEvolutionAction ?? this.livingDexEvolutionAction,
      detectShinies: detectShinies ?? this.detectShinies,
      detectAlphas: detectAlphas ?? this.detectAlphas,
      playAudioFeedback: playAudioFeedback ?? this.playAudioFeedback,
      playHapticFeedback: playHapticFeedback ?? this.playHapticFeedback,
      desktopOverlayMode: desktopOverlayMode ?? this.desktopOverlayMode,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      preprocessProfile: preprocessProfile ?? this.preprocessProfile,
      scanIntervalMs: scanIntervalMs != null
          ? clampScanIntervalMs(scanIntervalMs)
          : this.scanIntervalMs,
      customPatterns: customPatterns ?? this.customPatterns,
      liveFocusPreset: liveFocusPreset ?? this.liveFocusPreset,
      ignoredPokemonIds: ignoredPokemonIds ?? this.ignoredPokemonIds,
      showScreenBorders: showScreenBorders ?? this.showScreenBorders,
      multiInstanceSlots: multiInstanceSlots ?? this.multiInstanceSlots,
      extraFocusRegions: extraFocusRegions ?? this.extraFocusRegions,
      maskSelfWindow: maskSelfWindow ?? this.maskSelfWindow,
      suppressSelfScanWarning:
          suppressSelfScanWarning ?? this.suppressSelfScanWarning,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoMarkCaught': autoMarkCaught,
      'trackEvolutions': trackEvolutions,
      'livingDexEvolutionAction': livingDexEvolutionAction.name,
      'detectShinies': detectShinies,
      'detectAlphas': detectAlphas,
      'playAudioFeedback': playAudioFeedback,
      'playHapticFeedback': playHapticFeedback,
      'desktopOverlayMode': desktopOverlayMode.name,
      'ocrLanguage': ocrLanguage,
      'preprocessProfile': preprocessProfile.name,
      'scanIntervalMs': scanIntervalMs,
      'customPatterns': customPatterns.map((p) => p.toMap()).toList(),
      'liveFocusPreset': liveFocusPreset.name,
      'ignoredPokemonIds': ignoredPokemonIds,
      'showScreenBorders': showScreenBorders,
      'multiInstanceSlots': multiInstanceSlots.map((s) => s.toMap()).toList(),
      'extraFocusRegions': extraFocusRegions.map((r) => r.toMap()).toList(),
      'maskSelfWindow': maskSelfWindow,
      'suppressSelfScanWarning': suppressSelfScanWarning,
    };
  }

  factory ScannerSettings.fromMap(Map<String, dynamic> map) {
    LivingDexEvolutionAction action = LivingDexEvolutionAction.askBeforeRemoving;
    final actionStr = map['livingDexEvolutionAction']?.toString();
    if (actionStr != null) {
      for (final a in LivingDexEvolutionAction.values) {
        if (a.name == actionStr) {
          action = a;
          break;
        }
      }
    }

    DesktopOverlayMode mode = DesktopOverlayMode.floatingHud;
    final modeStr = map['desktopOverlayMode']?.toString();
    if (modeStr != null) {
      for (final m in DesktopOverlayMode.values) {
        if (m.name == modeStr) {
          mode = m;
          break;
        }
      }
    }

    OcrPreprocessProfile profile = OcrPreprocessProfile.standard;
    final profileStr = map['preprocessProfile']?.toString();
    if (profileStr != null) {
      for (final p in OcrPreprocessProfile.values) {
        if (p.name == profileStr) {
          profile = p;
          break;
        }
      }
    }

    LiveFocusPreset focusPreset = LiveFocusPreset.disabled;
    final focusStr = map['liveFocusPreset']?.toString();
    if (focusStr != null) {
      for (final fp in LiveFocusPreset.values) {
        if (fp.name == focusStr) {
          focusPreset = fp;
          break;
        }
      }
    }

    final rawInterval = map['scanIntervalMs'];
    final parsedInterval = rawInterval is num
        ? clampScanIntervalMs(rawInterval.round())
        : defaultScanIntervalMs;

    final patterns = <CustomOcrPattern>[];
    final rawPatterns = map['customPatterns'];
    if (rawPatterns is List) {
      for (final item in rawPatterns) {
        if (item is Map) {
          final parsed = CustomOcrPattern.fromMap(Map<String, dynamic>.from(item));
          if (parsed.template.trim().isNotEmpty) {
            patterns.add(parsed);
          }
        }
      }
    }

    final ignoredIds = <int>[];
    final rawIgnored = map['ignoredPokemonIds'];
    if (rawIgnored is List) {
      for (final item in rawIgnored) {
        final parsed = item is num ? item.toInt() : int.tryParse(item.toString());
        if (parsed != null && parsed > 0 && !ignoredIds.contains(parsed)) {
          ignoredIds.add(parsed);
        }
      }
    }

    final slots = <MultiInstanceSlot>[];
    final rawSlots = map['multiInstanceSlots'];
    if (rawSlots is List) {
      for (final item in rawSlots) {
        if (item is Map) {
          slots.add(MultiInstanceSlot.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final extraFocus = <ScreenRegion>[];
    final rawExtraFocus = map['extraFocusRegions'];
    if (rawExtraFocus is List) {
      for (final item in rawExtraFocus) {
        if (item is Map) {
          extraFocus.add(ScreenRegion.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ScannerSettings(
      autoMarkCaught: map['autoMarkCaught'] as bool? ?? true,
      trackEvolutions: map['trackEvolutions'] as bool? ?? true,
      livingDexEvolutionAction: action,
      detectShinies: map['detectShinies'] as bool? ?? true,
      detectAlphas: map['detectAlphas'] as bool? ?? true,
      playAudioFeedback: map['playAudioFeedback'] as bool? ?? true,
      playHapticFeedback: map['playHapticFeedback'] as bool? ?? true,
      desktopOverlayMode: mode,
      ocrLanguage: map['ocrLanguage']?.toString() ?? 'auto',
      preprocessProfile: profile,
      scanIntervalMs: parsedInterval,
      customPatterns: List.unmodifiable(patterns),
      liveFocusPreset: focusPreset,
      ignoredPokemonIds: List.unmodifiable(ignoredIds),
      showScreenBorders: map['showScreenBorders'] as bool? ?? true,
      multiInstanceSlots: List.unmodifiable(slots),
      extraFocusRegions: List.unmodifiable(extraFocus),
      maskSelfWindow: map['maskSelfWindow'] as bool? ?? false,
      suppressSelfScanWarning: map['suppressSelfScanWarning'] as bool? ?? false,
    );
  }
}
