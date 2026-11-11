import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;

/// Known supported emulator systems.
enum EmulatorType {
  mgba,
  desmume,
  ryujinx,
  citra,
  dolphin,
  bizhawk,
  melonds,
  visualboyadvance,
  unknown,
}

/// Metadata describing a desktop window.
class DesktopWindowInfo {
  final int id;
  final String title;
  final String? processName;
  final EmulatorType emulatorType;
  final String? extractedRomName;
  final double width;
  final double height;

  const DesktopWindowInfo({
    required this.id,
    required this.title,
    this.processName,
    this.emulatorType = EmulatorType.unknown,
    this.extractedRomName,
    this.width = 800.0,
    this.height = 600.0,
  });

  bool get isKnownEmulator => emulatorType != EmulatorType.unknown;

  @override
  String toString() => 'DesktopWindowInfo(id: $id, title: "$title", emu: $emulatorType, proc: $processName)';
}

/// Detects running emulator windows, parses ROM titles, and calculates scan regions.
class WindowDetector {
  static final Map<EmulatorType, RegExp> _emulatorSignatures = {
    EmulatorType.mgba: RegExp(r'\bmGBA\b', caseSensitive: false),
    EmulatorType.desmume: RegExp(r'\bDeSmuME\b', caseSensitive: false),
    EmulatorType.ryujinx: RegExp(r'\bRyujinx\b', caseSensitive: false),
    EmulatorType.citra: RegExp(r'\bCitra\b', caseSensitive: false),
    EmulatorType.dolphin: RegExp(r'\bDolphin\b', caseSensitive: false),
    EmulatorType.bizhawk: RegExp(r'\bBizHawk\b', caseSensitive: false),
    EmulatorType.melonds: RegExp(r'\bmelonDS\b', caseSensitive: false),
    EmulatorType.visualboyadvance:
        RegExp(r'\b(?:VisualBoyAdvance|VBA-M)\b', caseSensitive: false),
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

  /// Analyzes [title] and returns a [DesktopWindowInfo] identifying the emulator if recognized.
  DesktopWindowInfo identifyEmulator(
    String title, {
    int id = 0,
    String? processName,
    double width = 800.0,
    double height = 600.0,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return DesktopWindowInfo(
        id: id,
        title: title,
        processName: processName,
        width: width,
        height: height,
      );
    }

    for (final entry in _emulatorSignatures.entries) {
      if (entry.value.hasMatch(trimmed) ||
          (processName != null && entry.value.hasMatch(processName))) {
        final rom = _extractRomTitle(trimmed, entry.key);
        return DesktopWindowInfo(
          id: id,
          title: trimmed,
          processName: processName,
          emulatorType: entry.key,
          extractedRomName: rom,
          width: width,
          height: height,
        );
      }
    }

    return DesktopWindowInfo(
      id: id,
      title: trimmed,
      processName: processName,
      emulatorType: EmulatorType.unknown,
      width: width,
      height: height,
    );
  }

  /// Parses CSV output from `tasklist /V /FO CSV` on Windows.
  List<DesktopWindowInfo> parseTasklistCsv(String csv) {
    if (csv.trim().isEmpty) return [];

    final lines = csv.split(RegExp(r'\r?\n'));
    final rawWindows = <DesktopWindowInfo>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final values = _parseCsvRow(trimmed);
      if (values.length < 9) continue;

      final processName = values[0];
      final pidStr = values[1];
      final title = values[8];

      // Skip header row
      if (pidStr.toLowerCase() == 'pid') continue;

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

  /// Discovers all currently open desktop windows on the system.
  List<DesktopWindowInfo> getOpenWindows() {
    if (!kIsWeb && io.Platform.isWindows && !io.Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        final result = io.Process.runSync('tasklist', ['/V', '/FO', 'CSV']);
        if (result.exitCode == 0) {
          final parsed = parseTasklistCsv(result.stdout.toString());
          if (parsed.isNotEmpty) {
            return parsed;
          }
        }
      } catch (_) {
        // Fall back gracefully if tasklist cannot be executed
      }
    }

    // Default fallback windows
    return filterAndRankWindows(const [
      DesktopWindowInfo(id: 1, title: 'mGBA (GameBoy Advance)', emulatorType: EmulatorType.mgba),
      DesktopWindowInfo(id: 2, title: 'melonDS (Nintendo DS)', emulatorType: EmulatorType.melonds),
      DesktopWindowInfo(id: 3, title: 'Ryujinx (Nintendo Switch)', emulatorType: EmulatorType.ryujinx),
      DesktopWindowInfo(id: 4, title: 'Citra (Nintendo 3DS)', emulatorType: EmulatorType.citra),
    ]);
  }

  /// Filters out empty windows and ranks known emulator windows at the top.
  List<DesktopWindowInfo> filterAndRankWindows(
    List<DesktopWindowInfo> rawWindows,
  ) {
    final recognized = <DesktopWindowInfo>[];
    for (final w in rawWindows) {
      if (w.title.trim().isEmpty) continue;
      final info = w.emulatorType != EmulatorType.unknown
          ? w
          : identifyEmulator(w.title, id: w.id, processName: w.processName, width: w.width, height: w.height);
      recognized.add(info);
    }

    recognized.sort((a, b) {
      if (a.isKnownEmulator && !b.isKnownEmulator) return -1;
      if (!a.isKnownEmulator && b.isKnownEmulator) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return recognized;
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

  String? _extractRomTitle(String title, EmulatorType type) {
    final match = RegExp(
      r'^(?:mGBA|DeSmuME|Ryujinx|Citra|Dolphin|BizHawk|melonDS|VisualBoyAdvance|VBA-M)[^\-|]*[\-|]\s*(?:[\d\.]+[^\-|]*[\-|]\s*)?(.*)$',
      caseSensitive: false,
    ).firstMatch(title);
    if (match != null && match.group(1) != null && match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    final parts = title.split(RegExp(r'[-|]'));
    if (parts.length > 1) {
      return parts.sublist(1).join('-').trim();
    }
    return null;
  }
}
