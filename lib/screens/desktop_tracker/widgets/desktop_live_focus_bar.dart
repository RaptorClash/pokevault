import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../../services/desktop_tracker/desktop_window_source.dart';
import '../../../services/desktop_tracker/window_detector.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';
import '../controllers/desktop_tracker_dex_controller.dart';
import 'live_frame_thumbnail.dart';

/// Signature for opening the live-updating enlarged preview dialog.
typedef EnlargedPreviewCallback = void Function({
  required CapturedFrame? liveFrame,
  required Uint8List? fallbackPng,
  required String title,
  ValueListenable<LiveOcrScanStatus>? statusListenable,
  ValueListenable<CapturedFrame?>? frameListenable,
  ValueListenable<Map<String, CapturedFrame>>? boxFramesListenable,
  ValueListenable<Map<String, String>>? boxPreviewsListenable,
  String? boxKey,
});

/// Shared live capture preview card used identically by Zone A and Zone B.
class DesktopLivePreviewCard extends StatelessWidget {
  final Key? cardKey;
  final Key? enlargeButtonKey;
  final Color accentColor;
  final CapturedFrame? liveFrame;
  final Uint8List? fallbackPngBytes;
  final IconData fallbackIcon;
  final String statusText;
  final int scanCount;
  final String metaText;
  final String recognizedText;
  final String idleHintText;
  final bool isDark;
  final VoidCallback? onTapPreview;
  final Widget? trailing;

  const DesktopLivePreviewCard({
    super.key,
    this.cardKey,
    this.enlargeButtonKey,
    required this.accentColor,
    required this.liveFrame,
    required this.fallbackPngBytes,
    required this.fallbackIcon,
    required this.statusText,
    required this.scanCount,
    required this.metaText,
    required this.recognizedText,
    required this.idleHintText,
    required this.isDark,
    this.onTapPreview,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: enlargeButtonKey,
            onTap: onTapPreview,
            child: Tooltip(
              message: 'Live-Bild vergrößern',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 68,
                  height: 44,
                  color: Colors.black38,
                  child: LiveFrameThumbnail(
                    liveFrame: liveFrame,
                    fallbackPngBytes: fallbackPngBytes,
                    fallbackIcon: fallbackIcon,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        scanCount > 0
                            ? '$statusText · #$scanCount'
                            : statusText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  metaText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recognizedText.isNotEmpty
                      ? 'OCR: $recognizedText'
                      : idleHintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: recognizedText.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Shared info toggle icon button for scan-zone / profile cards.
class DesktopInfoToggleButton extends StatelessWidget {
  final Key buttonKey;
  final bool isOpen;
  final Color accentColor;
  final String tooltip;
  final VoidCallback onPressed;

  const DesktopInfoToggleButton({
    super.key,
    required this.buttonKey,
    required this.isOpen,
    required this.accentColor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            isOpen ? Icons.info : Icons.info_outline,
            size: 14,
            color: accentColor,
          ),
        ),
      ),
    );
  }
}

/// Shared collapsible explanation banner for scan-zone / profile cards.
class DesktopInlineInfoBanner extends StatelessWidget {
  final Key boxKey;
  final Color accentColor;
  final bool isDark;
  final String title;
  final String body;

  const DesktopInlineInfoBanner({
    super.key,
    required this.boxKey,
    required this.accentColor,
    required this.isDark,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: boxKey,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: TextStyle(
              fontSize: 10,
              height: 1.35,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live-Focus-Zone (Zone B) panel + starter protection chip list.
class DesktopLiveFocusZoneBar extends StatelessWidget {
  final ScannerSettings settings;
  final DesktopWindowSource windowSource;
  final Uint8List? focusSnippetPreviewBytes;
  final bool showZoneBInfo;
  final bool isDark;
  final bool isScanningActive;
  final DesktopWindowInfo? selectedWindow;
  final EnlargedPreviewCallback? onShowEnlargedPreview;
  final VoidCallback onToggleInfo;
  final ValueChanged<LiveFocusPreset> onSelectPreset;
  final VoidCallback onStartSnipping;
  final VoidCallback? onAddExtraFocusBox;
  final ValueChanged<int>? onRemoveExtraFocusBox;
  final ValueChanged<int> onUnignorePokemon;

  const DesktopLiveFocusZoneBar({
    super.key,
    required this.settings,
    required this.windowSource,
    required this.focusSnippetPreviewBytes,
    required this.showZoneBInfo,
    required this.isDark,
    this.isScanningActive = true,
    this.selectedWindow,
    this.onShowEnlargedPreview,
    required this.onToggleInfo,
    required this.onSelectPreset,
    required this.onStartSnipping,
    this.onAddExtraFocusBox,
    this.onRemoveExtraFocusBox,
    required this.onUnignorePokemon,
  });

  @override
  Widget build(BuildContext context) {
    final activeFocusPreset = settings.liveFocusPreset;
    final focusRegion = windowSource.liveFocusScreenRegion;
    final hasCustomFocusRegion =
        activeFocusPreset == LiveFocusPreset.customRegion && focusRegion != null;
    final isEnabled = activeFocusPreset != LiveFocusPreset.disabled;
    final ignoredIds = settings.ignoredPokemonIds;
    final dexProvider = Provider.of<DexProvider>(context, listen: false);

    final String focusModeLabel;
    if (hasCustomFocusRegion) {
      focusModeLabel =
          '${focusRegion.width.round()}×${focusRegion.height.round()} px';
    } else if (isEnabled) {
      focusModeLabel = activeFocusPreset.labelDe;
    } else {
      focusModeLabel = t.scanner_focus_disabled;
    }

    final presetOptions = <({LiveFocusPreset preset, String label})>[
      (preset: LiveFocusPreset.disabled, label: t.scanner_focus_disabled),
      (preset: LiveFocusPreset.topLeft, label: '↖ ${t.scanner_focus_top_left}'),
      (preset: LiveFocusPreset.topRight, label: '↗ ${t.scanner_focus_top_right}'),
      (preset: LiveFocusPreset.topBanner, label: '▭ ${t.scanner_focus_top_banner}'),
    ];

    final intervalMs = settings.scanIntervalMs;
    final intervalLabel = intervalMs >= 1000
        ? '${(intervalMs / 1000).toStringAsFixed(1)}s'
        : '${intervalMs}ms';

    return Container(
      key: const Key('scan_zone_b_card'),
      child: Container(
        key: const Key('live_focus_zone_panel'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? Colors.cyanAccent.withValues(alpha: 0.55)
                : (isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300),
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
                        Icons.center_focus_strong,
                        size: 14,
                        color: Colors.cyanAccent,
                      ),
                      Text(
                        t.scanner_zone_b_header,
                        style: const TextStyle(
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
                          color: Colors.cyanAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.scanner_zone_b_badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                      DesktopInfoToggleButton(
                        buttonKey: const Key('btn_info_zone_b'),
                        isOpen: showZoneBInfo,
                        accentColor: Colors.cyanAccent,
                        tooltip: t.scanner_zone_b_info_tooltip,
                        onPressed: onToggleInfo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    key: const Key('label_active_focus_mode'),
                    focusModeLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (showZoneBInfo)
              DesktopInlineInfoBanner(
                boxKey: const Key('info_box_zone_b'),
                accentColor: Colors.cyanAccent,
                isDark: isDark,
                title: t.scanner_zone_b_info_title,
                body: t.scanner_zone_b_info_body,
              ),
            if (!hasCustomFocusRegion) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presetOptions.map((opt) {
                  final selected = activeFocusPreset == opt.preset;
                  return ChoiceChip(
                    key: Key('focus_preset_${opt.preset.name}'),
                    label: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 0,
                    ),
                    onSelected: (_) => onSelectPreset(opt.preset),
                  );
                }).toList(),
              ),
            ],
            if (isEnabled) ...[
              const SizedBox(height: 8),
              ValueListenableBuilder<LiveOcrScanStatus>(
                valueListenable: windowSource.liveFocusStatusNotifier,
                builder: (context, focusStatus, _) {
                  final cropRect = (!hasCustomFocusRegion &&
                          selectedWindow != null)
                      ? WindowDetector().calculateEnemyHudCropRegion(
                          activeFocusPreset,
                          windowWidth: selectedWindow!.width,
                          windowHeight: selectedWindow!.height,
                        )
                      : null;
                  final metaText = hasCustomFocusRegion
                      ? '(${focusRegion.x.round()}, ${focusRegion.y.round()}) · '
                          '${focusRegion.width.round()}×${focusRegion.height.round()} px'
                      : (cropRect != null && selectedWindow != null
                          ? '${selectedWindow!.title} · '
                              '${cropRect.width.round()}×${cropRect.height.round()} px'
                          : activeFocusPreset.labelDe);
                  final accentColor = isScanningActive
                      ? (isDark ? Colors.cyanAccent : Colors.cyan.shade700)
                      : Colors.amber;
                  final statusText = isScanningActive
                      ? 'LIVE-FOKUS AKTIV'
                      : 'LIVE-FOKUS PAUSIERT';
                  final fallbackBytes =
                      hasCustomFocusRegion ? focusSnippetPreviewBytes : null;

                  return DesktopLivePreviewCard(
                    cardKey: const Key('desktop_focus_preview_card'),
                    enlargeButtonKey: const Key('btn_enlarge_zone_b_preview'),
                    accentColor: accentColor,
                    liveFrame: focusStatus.latestFrame,
                    fallbackPngBytes: fallbackBytes,
                    fallbackIcon: Icons.center_focus_strong,
                    statusText: statusText,
                    scanCount: focusStatus.scanCount,
                    metaText: metaText,
                    recognizedText: focusStatus.previewText,
                    idleHintText: 'Warte auf Text (alle $intervalLabel)...',
                    isDark: isDark,
                    onTapPreview: onShowEnlargedPreview != null
                        ? () => onShowEnlargedPreview!(
                              liveFrame: focusStatus.latestFrame,
                              fallbackPng: fallbackBytes,
                              title: metaText,
                              statusListenable:
                                  windowSource.liveFocusStatusNotifier,
                            )
                        : null,
                    trailing: IconButton(
                      key: const Key('btn_reset_focus_snippet'),
                      tooltip: t.scanner_disable_focus_tooltip,
                      icon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onSelectPreset(LiveFocusPreset.disabled),
                    ),
                  );
                },
              ),
              if (settings.extraFocusRegions.isNotEmpty) ...[
                const SizedBox(height: 6),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    windowSource.focusBoxPreviewsNotifier,
                    windowSource.focusBoxFramesNotifier,
                  ]),
                  builder: (context, _) {
                    final boxPreviews = windowSource.focusBoxPreviewsNotifier.value;
                    final boxFrames = windowSource.focusBoxFramesNotifier.value;
                    final extraAccent =
                        isDark ? Colors.cyanAccent : Colors.cyan.shade700;
                    return Column(
                      children: [
                        for (int i = 0;
                            i < settings.extraFocusRegions.length;
                            i++)
                          Builder(
                            builder: (_) {
                              final region = settings.extraFocusRegions[i];
                              final boxKey = 'B${i + 2}';
                              final boxFrame = boxFrames[boxKey];
                              final boxOcr = boxPreviews[boxKey] ?? '';
                              final meta =
                                  '$boxKey · (${region.x.round()}, ${region.y.round()}) · '
                                  '${region.width.round()}×${region.height.round()} px';
                              return Container(
                                key: Key('extra_focus_chip_$boxKey'),
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: extraAccent.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: extraAccent.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: onShowEnlargedPreview != null
                                          ? () => onShowEnlargedPreview!(
                                                liveFrame: boxFrame,
                                                fallbackPng: null,
                                                title: meta,
                                                boxFramesListenable: windowSource
                                                    .focusBoxFramesNotifier,
                                                boxPreviewsListenable:
                                                    windowSource
                                                        .focusBoxPreviewsNotifier,
                                                boxKey: boxKey,
                                              )
                                          : null,
                                      child: Tooltip(
                                        message: 'Live-Bild vergrößern',
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Container(
                                            width: 48,
                                            height: 32,
                                            color: Colors.black38,
                                            child: LiveFrameThumbnail(
                                              liveFrame: boxFrame,
                                              fallbackPngBytes: null,
                                              fallbackIcon:
                                                  Icons.center_focus_weak,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meta,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              color: extraAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            boxOcr.isNotEmpty
                                                ? 'OCR: $boxOcr'
                                                : 'Warte auf Text...',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontStyle: boxOcr.isEmpty
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Fokus $boxKey entfernen',
                                      icon: const Icon(Icons.close, size: 15),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: onRemoveExtraFocusBox != null
                                          ? () => onRemoveExtraFocusBox!(i)
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('btn_live_focus_snipping'),
                onPressed: onStartSnipping,
                icon: const Icon(
                  Icons.crop_free,
                  size: 14,
                  color: Colors.cyanAccent,
                ),
                label: Text(
                  hasCustomFocusRegion
                      ? t.scanner_redraw_focus_region
                      : t.scanner_draw_focus_region,
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
                    color: hasCustomFocusRegion
                        ? Colors.cyanAccent
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (isEnabled &&
                onAddExtraFocusBox != null &&
                settings.extraFocusRegions.length < 4) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('btn_add_extra_focus_box'),
                  onPressed: onAddExtraFocusBox,
                  icon: const Icon(
                    Icons.add_box_outlined,
                    size: 14,
                    color: Colors.cyanAccent,
                  ),
                  label: Text(
                    '+ Weitere Fokus-Box (B${settings.extraFocusRegions.length + 2})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    side: BorderSide(
                      color: Colors.cyanAccent.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
            if (ignoredIds.isNotEmpty) ...[
              const Divider(height: 14),
              Text(
                t.scanner_ignored_team_header,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ignoredIds.map((id) {
                  final label =
                      DesktopTrackerDexController.resolvePokemonName(
                    dexProvider,
                    id,
                  );
                  return InputChip(
                    key: Key('ignored_pokemon_chip_$id'),
                    avatar: const Icon(
                      Icons.shield,
                      size: 13,
                      color: Colors.orangeAccent,
                    ),
                    label: Text(
                      '$label (#$id)',
                      style: const TextStyle(fontSize: 10),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () => onUnignorePokemon(id),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// OCR preprocessing profile, scan rate, game language, and custom pattern studio bar.
class DesktopRefreshRateAndPatternsBar extends StatelessWidget {
  final ScannerSettings settings;
  final bool showScanProfileInfo;
  final bool isDark;
  final VoidCallback onToggleInfo;
  final ValueChanged<OcrPreprocessProfile> onUpdatePreprocessProfile;
  final ValueChanged<int> onUpdateScanInterval;
  final VoidCallback onOpenCustomPatterns;
  final ValueChanged<String>? onUpdateOcrLanguage;
  final String? effectiveLanguageTag;

  const DesktopRefreshRateAndPatternsBar({
    super.key,
    required this.settings,
    required this.showScanProfileInfo,
    required this.isDark,
    required this.onToggleInfo,
    required this.onUpdatePreprocessProfile,
    required this.onUpdateScanInterval,
    required this.onOpenCustomPatterns,
    this.onUpdateOcrLanguage,
    this.effectiveLanguageTag,
  });

  @override
  Widget build(BuildContext context) {
    final currentIntervalMs = settings.scanIntervalMs;
    final currentProfile = settings.preprocessProfile;
    final activePatternsCount =
        settings.customPatterns.where((p) => p.enabled).length;
    const rateOptions = <({int ms, String label})>[
      (ms: 250, label: '250 ms'),
      (ms: 400, label: '400 ms'),
      (ms: 750, label: '750 ms'),
      (ms: 1200, label: '1.2 s'),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 14, color: Colors.deepPurpleAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.scanner_profile_header,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              DesktopInfoToggleButton(
                buttonKey: const Key('btn_info_scan_profile'),
                isOpen: showScanProfileInfo,
                accentColor: Colors.deepPurpleAccent,
                tooltip: t.scanner_profile_info_tooltip,
                onPressed: onToggleInfo,
              ),
            ],
          ),
          if (showScanProfileInfo)
            DesktopInlineInfoBanner(
              boxKey: const Key('info_box_scan_profile'),
              accentColor: Colors.deepPurpleAccent,
              isDark: isDark,
              title: t.scanner_profile_info_title,
              body: t.scanner_profile_info_body,
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: OcrPreprocessProfile.values.map((profile) {
              final selected = currentProfile == profile;
              return ChoiceChip(
                key: Key('profile_${profile.name}'),
                label: Text(
                  profile.labelDe,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 0,
                ),
                onSelected: (_) => onUpdatePreprocessProfile(profile),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.speed, size: 14, color: Colors.blueAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.scanner_rate_header,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                currentIntervalMs >= 1000
                    ? '${(currentIntervalMs / 1000).toStringAsFixed(1)} s'
                    : '$currentIntervalMs ms',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rateOptions.map((opt) {
              final selected = currentIntervalMs == opt.ms;
              return ChoiceChip(
                key: Key('refresh_rate_${opt.ms}'),
                label: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 0,
                ),
                onSelected: (_) => onUpdateScanInterval(opt.ms),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (onUpdateOcrLanguage != null) ...[
            DropdownButtonFormField<String>(
              key: const Key('dropdown_inline_ocr_language'),
              initialValue: kSupportedScannerOcrLanguages
                      .any((o) => o.code == settings.ocrLanguage)
                  ? settings.ocrLanguage
                  : 'auto',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.scanner_settings_ocr_lang_title,
                prefixIcon: const Icon(
                  Icons.translate,
                  size: 16,
                  color: Colors.blueAccent,
                ),
                helperText: effectiveLanguageTag != null &&
                        settings.ocrLanguage == 'auto'
                    ? 'Aktiv: $effectiveLanguageTag'
                    : null,
                helperStyle: const TextStyle(fontSize: 10),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: kSupportedScannerOcrLanguages
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o.code,
                      child: Text(
                        o.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) onUpdateOcrLanguage!(val);
              },
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('btn_custom_patterns'),
              onPressed: onOpenCustomPatterns,
              icon: const Icon(
                Icons.auto_fix_high,
                size: 15,
                color: Colors.amber,
              ),
              label: Text(
                t.scanner_custom_patterns_btn
                    .replaceAll('{count}', '$activePatternsCount'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
