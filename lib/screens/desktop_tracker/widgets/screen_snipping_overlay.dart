import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../services/desktop_tracker/screen_region.dart';
import '../../../services/desktop_tracker/window_detector.dart';

/// Fullscreen interactive overlay allowing the user to drag a snipping rectangle
/// across their game / window to define the active OCR scan region.
class ScreenSnippingOverlay extends StatefulWidget {
  final ValueChanged<ScreenRegion> onRegionSelected;
  final VoidCallback onCancel;
  final DesktopWindowInfo? targetWindow;
  final Uint8List? desktopBackgroundBytes;
  final VoidCallback? onTriggerWindowsSnipping;
  final VoidCallback? onPasteFromClipboard;

  const ScreenSnippingOverlay({
    super.key,
    required this.onRegionSelected,
    required this.onCancel,
    this.targetWindow,
    this.desktopBackgroundBytes,
    this.onTriggerWindowsSnipping,
    this.onPasteFromClipboard,
  });

  @override
  State<ScreenSnippingOverlay> createState() => _ScreenSnippingOverlayState();
}

class _ScreenSnippingOverlayState extends State<ScreenSnippingOverlay> {
  Offset? _dragStart;
  Offset? _dragCurrent;
  Rect? _presetRect;
  String _activePresetLabel = 'Benutzerdefinierter Bereich';

  Rect? get _currentRect {
    if (_presetRect != null) return _presetRect;
    if (_dragStart == null || _dragCurrent == null) return null;
    final left = math.min(_dragStart!.dx, _dragCurrent!.dx);
    final top = math.min(_dragStart!.dy, _dragCurrent!.dy);
    final right = math.max(_dragStart!.dx, _dragCurrent!.dx);
    final bottom = math.max(_dragStart!.dy, _dragCurrent!.dy);

    final width = right - left;
    final height = bottom - top;

    if (width < 5 || height < 5) return null;
    return Rect.fromLTWH(left, top, width, height);
  }

  void _applyPreset(ScanRegionPreset preset, Size size) {
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
      final detector = WindowDetector();
      final r = detector.calculateScanRegion(
        preset,
        windowWidth: size.width,
        windowHeight: size.height,
      );
      _presetRect = r;
      switch (preset) {
        case ScanRegionPreset.fullWindow:
          _activePresetLabel = 'Ganzes Fenster (100%)';
          break;
        case ScanRegionPreset.dsTopScreen:
          _activePresetLabel = 'DS Oben (Top-Screen 50%)';
          break;
        case ScanRegionPreset.dsBottomScreen:
          _activePresetLabel = 'DS Unten (Touchscreen 50%)';
          break;
        case ScanRegionPreset.bottomDialogue:
          _activePresetLabel = 'Textbox unten (30%)';
          break;
      }
    });
  }

  void _confirmSelection() {
    final rect = _currentRect;
    if (rect != null) {
      final region = ScreenRegion.fromRect(
        rect,
        isAbsoluteScreen: true,
        label: _activePresetLabel,
      );
      widget.onRegionSelected(region);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = _currentRect;
    final screenWidth = MediaQuery.of(context).size.width;

    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() {
            _presetRect = null;
            _activePresetLabel = 'Benutzerdefinierter Bereich';
            _dragStart = details.localPosition;
            _dragCurrent = details.localPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _dragCurrent = details.localPosition;
          });
        },
        child: Stack(
          children: [
            if (widget.desktopBackgroundBytes != null)
              Positioned.fill(
                child: Image.memory(
                  widget.desktopBackgroundBytes!,
                  key: const Key('desktop_background_image'),
                  fit: BoxFit.contain,
                ),
              ),
            Container(
              color: Colors.black.withValues(alpha: widget.desktopBackgroundBytes != null ? 0.35 : 0.65),
              child: Stack(
                children: [
                  // Top instruction bar
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 780),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF323246)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.crop, color: Colors.blueAccent, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.targetWindow != null
                                        ? (widget.targetWindow!.isDesktopScreen
                                            ? 'Desktop-Snipping: Ziehe einen Bereich über den Bildschirm'
                                            : 'Snipping (${widget.targetWindow!.title}): Wähle oder ziehe einen Scan-Bereich')
                                        : 'Snipping-Modus: Ziehe ein Rechteck über den Lesebereich',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (widget.onTriggerWindowsSnipping != null) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    key: const Key('btn_native_desktop_snipping'),
                                    onPressed: widget.onTriggerWindowsSnipping,
                                    icon: const Icon(Icons.content_cut, size: 13),
                                    label: const Text('Windows (Win+Shift+S)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                                if (widget.onPasteFromClipboard != null) ...[
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    key: const Key('btn_paste_from_clipboard_in_snipping'),
                                    onPressed: widget.onPasteFromClipboard,
                                    icon: const Icon(Icons.paste, size: 13),
                                    label: const Text('Zwischenablage', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white38),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  key: const Key('btn_cancel_snipping'),
                                  onPressed: widget.onCancel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(color: Colors.white24),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  child: const Text('Abbrechen', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActionChip(
                                key: const Key('chip_preset_full'),
                                label: const Text('Ganzes Fenster (100%)', style: TextStyle(fontSize: 10)),
                                onPressed: () => _applyPreset(ScanRegionPreset.fullWindow, MediaQuery.of(context).size),
                              ),
                              const SizedBox(width: 6),
                              ActionChip(
                                key: const Key('chip_preset_ds_top'),
                                label: const Text('🎮 DS Oben (Top-Screen 50%)', style: TextStyle(fontSize: 10)),
                                onPressed: () => _applyPreset(ScanRegionPreset.dsTopScreen, MediaQuery.of(context).size),
                              ),
                              const SizedBox(width: 6),
                              ActionChip(
                                key: const Key('chip_preset_ds_bottom'),
                                label: const Text('🎮 DS Unten (Touch 50%)', style: TextStyle(fontSize: 10)),
                                onPressed: () => _applyPreset(ScanRegionPreset.dsBottomScreen, MediaQuery.of(context).size),
                              ),
                              const SizedBox(width: 6),
                              ActionChip(
                                key: const Key('chip_preset_dialogue'),
                                label: const Text('💬 Textbox unten (30%)', style: TextStyle(fontSize: 10)),
                                onPressed: () => _applyPreset(ScanRegionPreset.bottomDialogue, MediaQuery.of(context).size),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Center guide placeholder before user draws a rectangle
              if (rect == null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black45,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.aspect_ratio, color: Colors.blueAccent, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          widget.targetWindow?.isDesktopScreen == true
                              ? '🖥️ Desktop-Fokus (Bildschirm 1)'
                              : (widget.targetWindow != null ? '🎮 ${widget.targetWindow!.title}' : '🖥️ Bildschirm-Scanbereich'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Klicke und ziehe mit der Maus über das Spielfenster,\noder nutze oben die DS Oben/Unten & Textbox Presets.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),

              // Active crop rectangle
              if (rect != null) ...[
                Positioned(
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${rect.width.round()} x ${rect.height.round()} px',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Confirm button positioned below or inside the rect
                Positioned(
                  left: math.max(10.0, math.min(rect.left, screenWidth - 220)),
                  top: rect.bottom + 10 < MediaQuery.of(context).size.height - 60
                      ? rect.bottom + 10
                      : math.max(60.0, rect.top - 46),
                  child: ElevatedButton.icon(
                    key: const Key('btn_confirm_snipping'),
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Diesen Bereich scannen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  ),
);
  }
}
