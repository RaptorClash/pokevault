import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;
import '../scanner_core/models/scanner_settings.dart';
export '../scanner_core/models/scanner_settings.dart' show ScanRegionPreset;
import 'windows_desktop_bridge.dart';

/// Known supported emulator systems.
enum EmulatorType {
  mgba,
  desmume,
  ryujinx,
  citra,
  azahar,
  lime3ds,
  dolphin,
  bizhawk,
  melonds,
  visualboyadvance,
  retroarch,
  cemu,
  yuzu,
  eden,
  sudachi,
  snes9x,
  nogba,
  skyemu,
  duckstation,
  pcsx2,
  unknown,
}

/// Metadata describing a desktop window or display monitor.
class DesktopWindowInfo {
  final int id;
  final int hwnd;
  final String title;
  final String? processName;
  final EmulatorType emulatorType;
  final String? extractedRomName;
  final double width;
  final double height;
  final Rect? bounds;
  final bool isDesktopScreen;
  final bool isMinimized;
  final bool isVirtualDesktop;
  final int monitorIndex;
  final bool isCameraSource;
  final int cameraIndex;
  final int sensorOrientation;

  const DesktopWindowInfo({
    required this.id,
    this.hwnd = 0,
    required this.title,
    this.processName,
    this.emulatorType = EmulatorType.unknown,
    this.extractedRomName,
    this.width = 800.0,
    this.height = 600.0,
    this.bounds,
    this.isDesktopScreen = false,
    this.isMinimized = false,
    this.isVirtualDesktop = false,
    this.monitorIndex = 0,
    this.isCameraSource = false,
    this.cameraIndex = -1,
    this.sensorOrientation = 0,
  });

  /// Factory for the entire desktop / primary monitor display.
  factory DesktopWindowInfo.primaryScreen({
    double width = 1920.0,
    double height = 1080.0,
    String title = '🖥️ Gesamter Desktop (Bildschirm 1)',
    int monitorIndex = 1,
    Rect? bounds,
  }) {
    return DesktopWindowInfo(
      id: -monitorIndex,
      hwnd: 0,
      title: title,
      processName: 'Desktop',
      isDesktopScreen: true,
      monitorIndex: monitorIndex,
      width: width,
      height: height,
      bounds: bounds ?? Rect.fromLTWH(0, 0, width, height),
    );
  }

  /// Factory for a live physical/virtual webcam source integrated into DesktopTrackerScreen.
  factory DesktopWindowInfo.webcam({
    required int index,
    required String name,
    int sensorOrientation = 0,
    double width = 1280.0,
    double height = 720.0,
  }) {
    final cleaned = name.trim().isEmpty ? 'Webcam ${index + 1}' : name.trim();
    return DesktopWindowInfo(
      id: -1000 - index,
      hwnd: 0,
      title: '📷 $cleaned',
      processName: 'Webcam',
      width: width,
      height: height,
      isCameraSource: true,
      cameraIndex: index,
      sensorOrientation: sensorOrientation,
    );
  }

  /// Fallback camera source when no webcam is connected, enabling manual photo OCR import.
  factory DesktopWindowInfo.webcamFallbackPhoto({
    String title = '📷 Webcam / Foto-Scan',
  }) {
    return DesktopWindowInfo(
      id: -1000,
      hwnd: 0,
      title: title,
      processName: 'Webcam',
      width: 1280.0,
      height: 720.0,
      isCameraSource: true,
      cameraIndex: -1,
    );
  }

  bool get isKnownEmulator => emulatorType != EmulatorType.unknown;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DesktopWindowInfo) return false;
    if (isCameraSource || other.isCameraSource) {
      return isCameraSource &&
          other.isCameraSource &&
          cameraIndex == other.cameraIndex &&
          title == other.title;
    }
    if (isDesktopScreen || other.isDesktopScreen) {
      return isDesktopScreen &&
          other.isDesktopScreen &&
          monitorIndex == other.monitorIndex &&
          isVirtualDesktop == other.isVirtualDesktop;
    }
    if (hwnd > 0 || other.hwnd > 0) {
      return hwnd == other.hwnd;
    }
    if (id > 0 && other.id > 0) {
      return id == other.id;
    }
    return title == other.title && processName == other.processName;
  }

  @override
  int get hashCode {
    if (isCameraSource) {
      return Object.hash('webcam', cameraIndex, title);
    }
    if (isDesktopScreen) {
      return Object.hash(true, monitorIndex, isVirtualDesktop);
    }
    if (hwnd > 0) return hwnd.hashCode;
    if (id > 0) return id.hashCode;
    return Object.hash(title, processName);
  }

  @override
  String toString() =>
      'DesktopWindowInfo(id: $id, hwnd: $hwnd, title: "$title", emu: $emulatorType, proc: $processName, desktop: $isDesktopScreen, cam: $isCameraSource#$cameraIndex, min: $isMinimized)';
}

/// Detects running emulator windows, parses ROM titles, and calculates scan regions.
class WindowDetector {
  final Future<io.ProcessResult> Function(String exe, List<String> args)?
      processRunner;
  final Future<List<DesktopWindowInfo>> Function()? nativeWindowEnumerator;

  WindowDetector({
    this.processRunner,
    this.nativeWindowEnumerator,
  });

  static final Map<EmulatorType, RegExp> _emulatorSignatures = {
    EmulatorType.retroarch: RegExp(r'\bRetroArch\b', caseSensitive: false),
    EmulatorType.mgba: RegExp(r'\bmGBA\b', caseSensitive: false),
    EmulatorType.desmume: RegExp(r'\bDeSmuME\b', caseSensitive: false),
    EmulatorType.ryujinx: RegExp(r'\bRyujinx\b', caseSensitive: false),
    EmulatorType.azahar: RegExp(r'\bAzahar\b', caseSensitive: false),
    EmulatorType.lime3ds: RegExp(r'\bLime3DS\b', caseSensitive: false),
    EmulatorType.citra: RegExp(r'\bCitra(?:-qt)?\b', caseSensitive: false),
    EmulatorType.dolphin: RegExp(r'\bDolphin\b', caseSensitive: false),
    EmulatorType.bizhawk:
        RegExp(r'\b(?:BizHawk|EmuHawk)\b', caseSensitive: false),
    EmulatorType.melonds: RegExp(r'\bmelonDS\b', caseSensitive: false),
    EmulatorType.visualboyadvance:
        RegExp(r'\b(?:VisualBoyAdvance|VBA-M|visualboyadvance-m)\b', caseSensitive: false),
    EmulatorType.cemu: RegExp(r'\bCemu\b', caseSensitive: false),
    EmulatorType.yuzu: RegExp(r'\bYuzu\b', caseSensitive: false),
    EmulatorType.eden: RegExp(r'\bEden\b', caseSensitive: false),
    EmulatorType.sudachi: RegExp(r'\bSudachi\b', caseSensitive: false),
    EmulatorType.snes9x: RegExp(r'\bSnes9x\b', caseSensitive: false),
    EmulatorType.nogba: RegExp(r'\bNO\$GBA\b', caseSensitive: false),
    EmulatorType.skyemu: RegExp(r'\bSkyEmu\b', caseSensitive: false),
    EmulatorType.duckstation: RegExp(r'\bDuckStation\b', caseSensitive: false),
    EmulatorType.pcsx2: RegExp(r'\bPCSX2\b', caseSensitive: false),
  };

  static const List<String> _systemWindowExclusions = [
    'nicht zutreffend',
    'n/a',
    'olemainthreadwndname',
    'task host window',
    'dwm notification window',
    'gdi+ window',
    'broadcastlistenerwindow',
    'windows push notifications platform',
    'the event manager dashboard',
    'olechannelwnd',
    'microsoft text input application',
    'realtekaudiobackgroundprocessclass',
    'filewatcher_',
    'drivercore',
    'discord overlay input trap',
    'wuiconwindow',
    'neue benachrichtigung',
    'innosetupldrwindow',
    'adb power notification window',
    'microsoft onedrive sync service',
    'start',
    'suche',
    'medienwiedergabe',
    'kein fan.',
  ];

  /// Analyzes [title] and [processName] and returns a [DesktopWindowInfo] identifying the emulator if recognized.
  DesktopWindowInfo identifyEmulator(
    String title, {
    int id = 0,
    int hwnd = 0,
    String? processName,
    double width = 800.0,
    double height = 600.0,
    Rect? bounds,
    bool isMinimized = false,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return DesktopWindowInfo(
        id: id,
        hwnd: hwnd,
        title: title,
        processName: processName,
        width: width,
        height: height,
        bounds: bounds,
        isMinimized: isMinimized,
      );
    }

    for (final entry in _emulatorSignatures.entries) {
      if (entry.value.hasMatch(trimmed) ||
          (processName != null && entry.value.hasMatch(processName))) {
        final rom = _extractRomTitle(trimmed, entry.key);
        return DesktopWindowInfo(
          id: id,
          hwnd: hwnd,
          title: trimmed,
          processName: processName,
          emulatorType: entry.key,
          extractedRomName: rom,
          width: width,
          height: height,
          bounds: bounds,
          isMinimized: isMinimized,
        );
      }
    }

    return DesktopWindowInfo(
      id: id,
      hwnd: hwnd,
      title: trimmed,
      processName: processName,
      emulatorType: EmulatorType.unknown,
      width: width,
      height: height,
      bounds: bounds,
      isMinimized: isMinimized,
    );
  }

  /// Parses CSV output from `tasklist /V /FO CSV` on Windows.
  List<DesktopWindowInfo> parseTasklistCsv(String csv) {
    if (csv.trim().isEmpty) return [];

    final lines = csv.split(RegExp(r'\r?\n'));
    final rawWindows = <DesktopWindowInfo>[];
    int procIdx = 0;
    int pidIdx = 1;
    int titleIdx = 8;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final values = _parseCsvRow(trimmed);
      if (values.length < 3) continue;

      final maybePidCol = values.length > 1 ? values[1].toLowerCase() : '';
      // Detect localized CSV header dynamically (EN: "Image Name","PID",...,"Window Title"; DE: "Abbildname","PID",...,"Fenstertitel")
      if (maybePidCol == 'pid' ||
          values.any((v) => v.toLowerCase() == 'fenstertitel' || v.toLowerCase() == 'window title')) {
        bool foundTitle = false;
        for (int i = 0; i < values.length; i++) {
          final lower = values[i].toLowerCase();
          if (lower == 'pid') pidIdx = i;
          if (lower == 'image name' || lower == 'abbildname') procIdx = i;
          if (lower == 'window title' || lower == 'fenstertitel') {
            titleIdx = i;
            foundTitle = true;
          }
        }
        if (!foundTitle && values.length >= 4) {
          titleIdx = values.length - 1;
        }
        continue;
      }

      if (titleIdx >= values.length || pidIdx >= values.length || procIdx >= values.length) {
        if (values.length < 9) continue;
      }
      final safeTitleIdx = titleIdx < values.length ? titleIdx : values.length - 1;
      final processName = values[procIdx];
      final pidStr = values[pidIdx];
      final title = values[safeTitleIdx];

      final pid = int.tryParse(pidStr) ?? 0;
      final cleanTitle = title.trim();

      if (cleanTitle.isEmpty) continue;

      final lowerTitle = cleanTitle.toLowerCase();
      final lowerProc = processName.toLowerCase();

      // Exclude self (PokéVault app itself)
      if (lowerProc == 'pokevault.exe' ||
          lowerProc == 'pokevault' ||
          lowerTitle == 'pokévault' ||
          lowerTitle == 'pokevault') {
        continue;
      }

      // Exclude known system and helper windows
      if (_systemWindowExclusions.any((ex) => lowerTitle.contains(ex))) {
        continue;
      }

      // Exclude GUIDs {xxxx-xxxx}
      if (cleanTitle.startsWith('{') && cleanTitle.endsWith('}')) {
        continue;
      }

      final info = identifyEmulator(
        cleanTitle,
        id: pid,
        processName: processName,
      );
      rawWindows.add(info);
    }

    return filterAndRankWindows(rawWindows);
  }

  List<String> _parseCsvRow(String line) {
    final values = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        values.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(c);
      }
    }
    values.add(sb.toString().trim());
    return values;
  }

  /// Discovers all currently open desktop windows and monitors asynchronously.
  Future<List<DesktopWindowInfo>> getOpenWindowsAsync() async {
    if (nativeWindowEnumerator != null) {
      try {
        final wins = await nativeWindowEnumerator!();
        return filterAndRankWindows(wins);
      } catch (_) {}
    }

    if (processRunner != null) {
      try {
        final result = await processRunner!(
          'tasklist',
          ['/FI', 'SESSION ne 0', '/V', '/FO', 'CSV'],
        );
        if (result.exitCode == 0) {
          final parsed = parseTasklistCsv(result.stdout.toString());
          if (parsed.isNotEmpty) {
            return filterAndRankWindows([
              DesktopWindowInfo.primaryScreen(),
              ...parsed,
            ]);
          }
        }
      } catch (_) {}
    }

    if (!kIsWeb &&
        io.Platform.isWindows &&
        !io.Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        final nativeWins =
            await WindowsDesktopBridge.instance.enumerateWindowsAndMonitors();
        if (nativeWins.isNotEmpty) {
          return filterAndRankWindows(nativeWins);
        }
        return [DesktopWindowInfo.primaryScreen()];
      } catch (_) {
        return [DesktopWindowInfo.primaryScreen()];
      }
    }

    return getFallbackWindows();
  }

  /// Default fallback windows for testing or when OS process inspection is disabled.
  List<DesktopWindowInfo> getFallbackWindows() {
    return filterAndRankWindows([
      DesktopWindowInfo.primaryScreen(),
      const DesktopWindowInfo(
          id: 1, title: 'mGBA (GameBoy Advance)', emulatorType: EmulatorType.mgba),
      const DesktopWindowInfo(
          id: 2, title: 'melonDS (Nintendo DS)', emulatorType: EmulatorType.melonds),
      const DesktopWindowInfo(
          id: 3, title: 'Ryujinx (Nintendo Switch)', emulatorType: EmulatorType.ryujinx),
      const DesktopWindowInfo(
          id: 4, title: 'Citra (Nintendo 3DS)', emulatorType: EmulatorType.citra),
    ]);
  }

  /// Discovers fallback desktop windows synchronously without blocking on OS subprocesses.
  /// Prefer [getOpenWindowsAsync] for live native OS window enumeration.
  List<DesktopWindowInfo> getOpenWindows() {
    return getFallbackWindows();
  }

  /// Filters out empty windows and ranks known emulator windows at the top,
  /// followed by Desktop/Monitors and general application windows.
  List<DesktopWindowInfo> filterAndRankWindows(
    List<DesktopWindowInfo> rawWindows,
  ) {
    final recognized = <DesktopWindowInfo>[];
    for (final w in rawWindows) {
      if (w.title.trim().isEmpty) continue;
      final info = (w.emulatorType != EmulatorType.unknown || w.isDesktopScreen)
          ? w
          : identifyEmulator(
              w.title,
              id: w.id,
              hwnd: w.hwnd,
              processName: w.processName,
              width: w.width,
              height: w.height,
              bounds: w.bounds,
              isMinimized: w.isMinimized,
            );
      recognized.add(info);
    }

    recognized.sort((a, b) {
      if (a.isKnownEmulator && !b.isKnownEmulator) return -1;
      if (!a.isKnownEmulator && b.isKnownEmulator) return 1;
      if (a.isDesktopScreen && !b.isDesktopScreen) return -1;
      if (!a.isDesktopScreen && b.isDesktopScreen) return 1;
      if (a.isDesktopScreen && b.isDesktopScreen) {
        if (a.isVirtualDesktop != b.isVirtualDesktop) {
          return a.isVirtualDesktop ? 1 : -1;
        }
        return a.monitorIndex.compareTo(b.monitorIndex);
      }
      if (a.isMinimized != b.isMinimized) {
        return a.isMinimized ? 1 : -1;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return recognized;
  }

  /// Calculates scan region rectangle for any [ScanRegionPreset].
  Rect calculateScanRegion(
    ScanRegionPreset preset, {
    required double windowWidth,
    required double windowHeight,
  }) {
    switch (preset) {
      case ScanRegionPreset.fullWindow:
        return Rect.fromLTWH(0.0, 0.0, windowWidth, windowHeight);
      case ScanRegionPreset.dsTopScreen:
        return Rect.fromLTWH(0.0, 0.0, windowWidth, windowHeight * 0.52);
      case ScanRegionPreset.dsBottomScreen:
        return Rect.fromLTWH(
            0.0, windowHeight * 0.48, windowWidth, windowHeight * 0.52);
      case ScanRegionPreset.bottomDialogue:
        return calculateDefaultDialogueRegion(
          windowWidth: windowWidth,
          windowHeight: windowHeight,
        );
    }
  }

  /// Calculates default dialogue textbox scan rectangle (lower 30% of the window).
  Rect calculateDefaultDialogueRegion({
    required double windowWidth,
    required double windowHeight,
  }) {
    final top = windowHeight * 0.70;
    final height = windowHeight * 0.30;
    return Rect.fromLTWH(0.0, top, windowWidth, height);
  }

  /// Calculates Zone B (opponent HUD) crop region inside a window for [preset].
  /// Returns `null` when [preset] is disabled or managed by an external custom screen region.
  Rect? calculateEnemyHudCropRegion(
    LiveFocusPreset preset, {
    required double windowWidth,
    required double windowHeight,
  }) {
    if (windowWidth <= 0 || windowHeight <= 0) return null;
    switch (preset) {
      case LiveFocusPreset.disabled:
      case LiveFocusPreset.customRegion:
        return null;
      case LiveFocusPreset.topLeft:
        return Rect.fromLTWH(0.0, 0.0, windowWidth * 0.42, windowHeight * 0.22);
      case LiveFocusPreset.topRight:
        return Rect.fromLTWH(
          windowWidth * 0.58,
          0.0,
          windowWidth * 0.42,
          windowHeight * 0.22,
        );
      case LiveFocusPreset.topBanner:
        return Rect.fromLTWH(0.0, 0.0, windowWidth, windowHeight * 0.24);
    }
  }

  String? _extractRomTitle(String title, EmulatorType type) {
    // Strip leading bracketed FPS counter like "[79/60] "
    final cleaned =
        title.replaceFirst(RegExp(r'^\[\s*\d+\s*/\s*\d+\s*\]\s*'), '');

    final match = RegExp(
      r'^(?:mGBA|DeSmuME|Ryujinx|Citra|Azahar|Lime3DS|Dolphin|BizHawk|EmuHawk|melonDS|VisualBoyAdvance|VBA-M|RetroArch|Cemu|Yuzu|Eden|Sudachi|Snes9x|NO\$GBA|SkyEmu|DuckStation|PCSX2)[^\-|]*[\-|]\s*(?:[\d\.]+[^\-|]*[\-|]\s*)?(.*)$',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (match != null &&
        match.group(1) != null &&
        match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    final parts = cleaned.split(RegExp(r'[-|]'));
    if (parts.length > 1) {
      return parts.sublist(1).join('-').trim();
    }
    return null;
  }
}
