import 'dart:ui';

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
  final EmulatorType emulatorType;
  final String? extractedRomName;
  final double width;
  final double height;

  const DesktopWindowInfo({
    required this.id,
    required this.title,
    this.emulatorType = EmulatorType.unknown,
    this.extractedRomName,
    this.width = 800.0,
    this.height = 600.0,
  });

  bool get isKnownEmulator => emulatorType != EmulatorType.unknown;

  @override
  String toString() => 'DesktopWindowInfo(id: $id, title: "$title", emu: $emulatorType)';
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

  /// Analyzes [title] and returns a [DesktopWindowInfo] identifying the emulator if recognized.
  DesktopWindowInfo identifyEmulator(
    String title, {
    int id = 0,
    double width = 800.0,
    double height = 600.0,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return DesktopWindowInfo(id: id, title: title, width: width, height: height);
    }

    for (final entry in _emulatorSignatures.entries) {
      if (entry.value.hasMatch(trimmed)) {
        final rom = _extractRomTitle(trimmed, entry.key);
        return DesktopWindowInfo(
          id: id,
          title: trimmed,
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
      emulatorType: EmulatorType.unknown,
      width: width,
      height: height,
    );
  }

  /// Filters out empty windows and ranks known emulator windows at the top.
  List<DesktopWindowInfo> filterAndRankWindows(
    List<DesktopWindowInfo> rawWindows,
  ) {
    final recognized = <DesktopWindowInfo>[];
    for (final w in rawWindows) {
      if (w.title.trim().isEmpty) continue;
      // Re-evaluate if not already identified
      final info = w.emulatorType != EmulatorType.unknown
          ? w
          : identifyEmulator(w.title, id: w.id, width: w.width, height: w.height);
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
    // Strip emulator name and optional version prefix
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
