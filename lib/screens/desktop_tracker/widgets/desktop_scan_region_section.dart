import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../../services/desktop_tracker/desktop_window_source.dart';
import '../../../services/desktop_tracker/screen_region.dart';
import '../../../services/desktop_tracker/window_detector.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';
import 'desktop_live_focus_bar.dart';

/// Complete scan region configuration section (border toggle, Zone A card,
/// live Zone B card, multi-instance card, and scan profile / rate bar).
class DesktopScanRegionSection extends StatelessWidget {
  final GlobalKey bordersToggleKey;
  final GlobalKey zoneASectionKey;
  final GlobalKey zoneBSectionKey;
  final GlobalKey multiSectionKey;
  final bool showOverlayControls;
  final bool isDark;
  final ScannerSettings settings;
  final ScreenRegion? customScreenRegion;
  final Uint8List? snippetPreviewBytes;
  final ScanRegionPreset scanRegion;
  final DesktopWindowInfo? selectedWindow;
  final bool isScanningActive;
  final bool showZoneAInfo;
  final DesktopWindowSource windowSource;
  final Widget liveFocusZoneBar;
  final Widget multiInstanceCard;
  final Widget refreshRateAndPatternsBar;
  final ValueChanged<bool> onToggleScreenBorders;
  final VoidCallback onToggleZoneAInfo;
  final ValueChanged<ScanRegionPreset> onSelectPresetMode;
  final VoidCallback onStartSnipping;
  final EnlargedPreviewCallback onShowEnlargedPreview;

  const DesktopScanRegionSection({
    super.key,
    required this.bordersToggleKey,
    required this.zoneASectionKey,
    required this.zoneBSectionKey,
    required this.multiSectionKey,
    required this.showOverlayControls,
    required this.isDark,
    required this.settings,
    required this.customScreenRegion,
    required this.snippetPreviewBytes,
    required this.scanRegion,
    required this.selectedWindow,
    required this.isScanningActive,
    required this.showZoneAInfo,
    required this.windowSource,
    required this.liveFocusZoneBar,
    required this.multiInstanceCard,
    required this.refreshRateAndPatternsBar,
    required this.onToggleScreenBorders,
    required this.onToggleZoneAInfo,
    required this.onSelectPresetMode,
    required this.onStartSnipping,
    required this.onShowEnlargedPreview,
  });

  Widget _buildScanPresetButton({
    required Key buttonKey,
    required ScanRegionPreset preset,
    required bool isSelected,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        key: buttonKey,
        onPressed: () => onSelectPresetMode(preset),
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFFEF5350).withValues(alpha: 0.15)
              : null,
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFEF5350)
                : (isDark ? Colors.white24 : Colors.black12),
          ),
          foregroundColor: isSelected
              ? const Color(0xFFEF5350)
              : (isDark ? Colors.white : Colors.black87),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomRegion = customScreenRegion != null;
    final isFull =
        !hasCustomRegion && scanRegion == ScanRegionPreset.fullWindow;
    final isDialogue =
        !hasCustomRegion && scanRegion == ScanRegionPreset.bottomDialogue;
    final isDsTop =
        !hasCustomRegion && scanRegion == ScanRegionPreset.dsTopScreen;
    final isDsBottom =
        !hasCustomRegion && scanRegion == ScanRegionPreset.dsBottomScreen;

    String modeLabel;
    if (hasCustomRegion) {
      modeLabel =
          '${customScreenRegion!.width.round()}×${customScreenRegion!.height.round()} px';
    } else if (isFull) {
      modeLabel = 'Ganzes Fenster (100%)';
    } else if (isDsTop) {
      modeLabel = 'DS Oben (Top-Screen 50%)';
    } else if (isDsBottom) {
      modeLabel = 'DS Unten (Touchscreen 50%)';
    } else {
      modeLabel = 'Textbox unten (30%)';
    }

    final showBorders = settings.showScreenBorders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOverlayControls)
          Container(
            key: bordersToggleKey,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: showBorders
                    ? Colors.cyanAccent.withValues(alpha: 0.45)
                    : (isDark
                        ? const Color(0xFF2F2F42)
                        : Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  showBorders ? Icons.visibility : Icons.visibility_off_outlined,
                  size: 15,
                  color: showBorders ? Colors.cyanAccent : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Farbige Bildschirm-Rahmen anzeigen',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Switch.adaptive(
                  key: const Key('switch_screen_borders'),
                  value: showBorders,
                  onChanged: onToggleScreenBorders,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        KeyedSubtree(
          key: zoneASectionKey,
          child: Container(
            key: const Key('scan_zone_a_card'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.crop_din,
                            size: 14,
                            color: Colors.greenAccent,
                          ),
                          const Text(
                            'SCAN-BEREICH (ZONE A)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.greenAccent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'GRÜN · TEXTBOX',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                          DesktopInfoToggleButton(
                            buttonKey: const Key('btn_info_zone_a'),
                            isOpen: showZoneAInfo,
                            accentColor: Colors.greenAccent,
                            tooltip: 'Info zu Scan-Bereich (Zone A)',
                            onPressed: onToggleZoneAInfo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        key: const Key('label_active_scan_mode'),
                        modeLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showZoneAInfo)
                  DesktopInlineInfoBanner(
                    boxKey: const Key('info_box_zone_a'),
                    accentColor: Colors.greenAccent,
                    isDark: isDark,
                    title: 'Wofür ist Scan-Bereich (Zone A)?',
                    body:
                        'Haupt-Scan-Zone für Spieltexte (z. B. Dialogbox unten). '
                        'Erkennt Fänge, Entwicklungen und wilde Begegnungen und '
                        'trägt gefangene Pokémon automatisch in deinen Ziel-Dex ein.',
                  ),
                if (!hasCustomRegion) ...[
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        children: [
                          _buildScanPresetButton(
                            buttonKey: const Key('btn_scan_mode_full'),
                            preset: ScanRegionPreset.fullWindow,
                            isSelected: isFull,
                            icon: Icons.fullscreen,
                            label: 'Ganzes Fenster',
                          ),
                          const SizedBox(width: 8),
                          _buildScanPresetButton(
                            buttonKey: const Key('btn_scan_mode_dialogue'),
                            preset: ScanRegionPreset.bottomDialogue,
                            isSelected: isDialogue,
                            icon: Icons.chat_bubble_outline,
                            label: 'Textbox unten',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildScanPresetButton(
                            buttonKey: const Key('btn_scan_mode_ds_top'),
                            preset: ScanRegionPreset.dsTopScreen,
                            isSelected: isDsTop,
                            icon: Icons.vertical_align_top,
                            label: 'DS Oben (Top)',
                          ),
                          const SizedBox(width: 8),
                          _buildScanPresetButton(
                            buttonKey: const Key('btn_scan_mode_ds_bottom'),
                            preset: ScanRegionPreset.dsBottomScreen,
                            isSelected: isDsBottom,
                            icon: Icons.vertical_align_bottom,
                            label: 'DS Unten (Touch)',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                if (!hasCustomRegion &&
                    (selectedWindow?.isDesktopScreen ?? false) &&
                    !isScanningActive) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Wähle ein Emulator-Fenster oder markiere einen Live-OCR-Bereich auf dem Desktop.',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.amber.shade200
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasCustomRegion || selectedWindow != null) ...[
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    child: ValueListenableBuilder<LiveOcrScanStatus>(
                      valueListenable: windowSource.liveScanStatusNotifier,
                    builder: (context, scanStatus, _) {
                      final isMonitor = !hasCustomRegion &&
                          (selectedWindow?.isDesktopScreen ?? false);
                      final accentColor =
                          isScanningActive ? Colors.green : Colors.amber;
                      final statusText = hasCustomRegion
                          ? (isScanningActive
                              ? 'LIVE-OCR AKTIV'
                              : 'LIVE-OCR PAUSIERT')
                          : isMonitor
                              ? (isScanningActive
                                  ? 'LIVE-OCR ÜBERWACHT MONITOR'
                                  : 'MONITOR-VORSCHAU · PAUSIERT')
                              : (isScanningActive
                                  ? 'LIVE-OCR ÜBERWACHT FENSTER'
                                  : 'FENSTER-VORSCHAU PAUSIERT');
                      final recognized = scanStatus.previewText;
                      final activeCrop = windowSource.cropRegion;
                      final metaText = hasCustomRegion
                          ? '(${customScreenRegion!.x.round()}, ${customScreenRegion!.y.round()}) · '
                              '${customScreenRegion!.width.round()}×${customScreenRegion!.height.round()} px'
                          : '${selectedWindow!.title} · '
                              '${(activeCrop?.width ?? selectedWindow!.width).round()}×'
                              '${(activeCrop?.height ?? selectedWindow!.height).round()} px';
                      final intervalMs = settings.scanIntervalMs;
                      final intervalLabel = intervalMs >= 1000
                          ? '${(intervalMs / 1000).toStringAsFixed(1)}s'
                          : '${intervalMs}ms';
                      final Widget? trailingAction = isMonitor
                          ? IconButton(
                              key: const Key('btn_refresh_monitor_preview'),
                              tooltip: 'Monitor-Vorschau aktualisieren',
                              icon: const Icon(Icons.refresh, size: 16),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => unawaited(
                                windowSource.capturePreviewOnly(),
                              ),
                            )
                          : (hasCustomRegion
                              ? IconButton(
                                  key: const Key('btn_reset_snippet'),
                                  tooltip: 'Bereich zurücksetzen',
                                  icon: const Icon(Icons.close, size: 16),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      onSelectPresetMode(scanRegion),
                                )
                              : null);

                      return DesktopLivePreviewCard(
                        cardKey: Key(
                          hasCustomRegion
                              ? 'desktop_snippet_preview_card'
                              : 'active_scan_preview_card',
                        ),
                        enlargeButtonKey:
                            const Key('btn_enlarge_zone_a_preview'),
                        accentColor: accentColor,
                        liveFrame: scanStatus.latestFrame,
                        fallbackPngBytes:
                            hasCustomRegion ? snippetPreviewBytes : null,
                        fallbackIcon: hasCustomRegion
                            ? Icons.crop
                            : (isMonitor
                                ? Icons.monitor
                                : Icons.desktop_windows),
                        statusText: statusText,
                        scanCount: scanStatus.scanCount,
                        metaText: metaText,
                        recognizedText: recognized,
                        idleHintText: isMonitor && !isScanningActive
                            ? 'Vorschau ohne Auto-OCR (↻ aktualisieren)'
                            : 'Warte auf Text (alle $intervalLabel)...',
                        isDark: isDark,
                        onTapPreview: () => onShowEnlargedPreview(
                          liveFrame: scanStatus.latestFrame,
                          fallbackPng:
                              hasCustomRegion ? snippetPreviewBytes : null,
                          title: metaText,
                          statusListenable: windowSource.liveScanStatusNotifier,
                        ),
                        trailing: trailingAction,
                      );
                    },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('btn_start_snipping'),
                    onPressed: onStartSnipping,
                    icon: const Icon(
                      Icons.crop_free,
                      size: 15,
                      color: Colors.greenAccent,
                    ),
                    label: Text(
                      hasCustomRegion
                          ? 'Scan-Bereich neu zeichnen'
                          : 'Scan-Bereich frei zeichnen',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      side: BorderSide(
                        color: hasCustomRegion
                            ? Colors.greenAccent
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: zoneBSectionKey,
          child: liveFocusZoneBar,
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: multiSectionKey,
          child: multiInstanceCard,
        ),
        const SizedBox(height: 10),
        refreshRateAndPatternsBar,
      ],
    );
  }
}
