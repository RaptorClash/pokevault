import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/dex_provider.dart';
import '../../../services/desktop_tracker/desktop_window_source.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';
import '../controllers/desktop_tracker_dex_controller.dart';

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
    final ignoredIds = settings.ignoredPokemonIds;
    final dexProvider = Provider.of<DexProvider>(context, listen: false);

    const presetOptions = <({LiveFocusPreset preset, String label})>[
      (preset: LiveFocusPreset.disabled, label: 'Aus'),
      (preset: LiveFocusPreset.topLeft, label: '↖ Oben Links'),
      (preset: LiveFocusPreset.topRight, label: '↗ Oben Rechts'),
      (preset: LiveFocusPreset.topBanner, label: '▭ Oberer Streifen'),
    ];

    return Container(
      key: const Key('scan_zone_b_card'),
      child: Container(
        key: const Key('live_focus_zone_panel'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeFocusPreset != LiveFocusPreset.disabled
                ? Colors.cyanAccent.withValues(alpha: 0.55)
                : (isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.center_focus_strong,
                  size: 14,
                  color: Colors.cyanAccent,
                ),
                const Text(
                  'LIVE-FOKUS-ZONE (ZONE B)',
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
                    color: Colors.cyanAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TÜRKIS · NUR ENCOUNTER',
                    style: TextStyle(
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
                  tooltip: 'Info zu Live-Fokus-Zone (Zone B)',
                  onPressed: onToggleInfo,
                ),
              ],
            ),
            if (showZoneBInfo)
              DesktopInlineInfoBanner(
                boxKey: const Key('info_box_zone_b'),
                accentColor: Colors.cyanAccent,
                isDark: isDark,
                title: 'Wofür ist Live-Fokus-Zone (Zone B)?',
                body:
                    'Liest nur den Gegnernamen oben im Kampf-HUD (z. B. oben '
                    'links/rechts oder frei markiert) als Begegnung — perfekt '
                    'für Live-Fokus und Mehrfachbegegnungen, ohne eigene Pokémon '
                    'oder Teammitglieder als gefangen zu werten.',
              ),
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
            const SizedBox(height: 6),
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
                  activeFocusPreset == LiveFocusPreset.customRegion &&
                          focusRegion != null
                      ? 'Fokus-Bereich neu zeichnen'
                      : 'Live-Fokus-Bereich frei zeichnen',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  side: BorderSide(
                    color: activeFocusPreset == LiveFocusPreset.customRegion
                        ? Colors.cyanAccent
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (activeFocusPreset != LiveFocusPreset.disabled) ...[
              if (onAddExtraFocusBox != null &&
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
              const SizedBox(height: 6),
              ValueListenableBuilder<LiveOcrScanStatus>(
                valueListenable: windowSource.liveFocusStatusNotifier,
                builder: (context, focusStatus, _) {
                  final text = focusStatus.previewText;
                  return Row(
                    children: [
                      if (focusSnippetPreviewBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            focusSnippetPreviewBytes!,
                            width: 32,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          text.isNotEmpty
                              ? 'Zone B: $text'
                              : 'Zone B aktiv (${activeFocusPreset.labelDe})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                      if (activeFocusPreset == LiveFocusPreset.customRegion)
                        IconButton(
                          tooltip: 'Fokus-Bereich deaktivieren',
                          icon: const Icon(Icons.close, size: 14),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () =>
                              onSelectPreset(LiveFocusPreset.disabled),
                        ),
                    ],
                  );
                },
              ),
              if (settings.extraFocusRegions.isNotEmpty) ...[
                const SizedBox(height: 4),
                ValueListenableBuilder<Map<String, String>>(
                  valueListenable: windowSource.focusBoxPreviewsNotifier,
                  builder: (context, boxPreviews, _) {
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (int i = 0;
                            i < settings.extraFocusRegions.length;
                            i++)
                          InputChip(
                            key: Key('extra_focus_chip_B${i + 2}'),
                            avatar: const Icon(
                              Icons.crop_free,
                              size: 12,
                              color: Colors.cyanAccent,
                            ),
                            label: Text(
                              (boxPreviews['B${i + 2}'] ?? '').isNotEmpty
                                  ? 'B${i + 2}: ${boxPreviews['B${i + 2}']}'
                                  : 'Fokus B${i + 2}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            deleteIcon: const Icon(Icons.close, size: 13),
                            onDeleted: onRemoveExtraFocusBox != null
                                ? () => onRemoveExtraFocusBox!(i)
                                : null,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
            if (ignoredIds.isNotEmpty) ...[
              const Divider(height: 14),
              const Text(
                'IGNORIERTE TEAM-POKÉMON (STARTER-SCHUTZ)',
                style: TextStyle(
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

/// OCR preprocessing profile, scan rate, and custom pattern studio bar.
class DesktopRefreshRateAndPatternsBar extends StatelessWidget {
  final ScannerSettings settings;
  final bool showScanProfileInfo;
  final bool isDark;
  final VoidCallback onToggleInfo;
  final ValueChanged<OcrPreprocessProfile> onUpdatePreprocessProfile;
  final ValueChanged<int> onUpdateScanInterval;
  final VoidCallback onOpenCustomPatterns;

  const DesktopRefreshRateAndPatternsBar({
    super.key,
    required this.settings,
    required this.showScanProfileInfo,
    required this.isDark,
    required this.onToggleInfo,
    required this.onUpdatePreprocessProfile,
    required this.onUpdateScanInterval,
    required this.onOpenCustomPatterns,
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
              const Expanded(
                child: Text(
                  'SCAN-PROFIL',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
                tooltip: 'Info zu den Scan-Profilen',
                onPressed: onToggleInfo,
              ),
            ],
          ),
          if (showScanProfileInfo)
            DesktopInlineInfoBanner(
              boxKey: const Key('info_box_scan_profile'),
              accentColor: Colors.deepPurpleAccent,
              isDark: isDark,
              title: 'Bild-Optimierung pro Quelle',
              body: '• Standard: Für scharfe PC- oder HD-Fenster.\n'
                  '• Pixel-Art (DS): Schärft & skaliert pixelige DS-/GBA-Texte (z. B. melonDS, Gen 4/5).\n'
                  '• Kamera / Display: Erhöht Kontrast für blasse oder abgefilmte Bildschirme.',
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
              const Expanded(
                child: Text(
                  'OCR-SCAN-RATE',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
                'Eigene OCR-Muster ($activePatternsCount)',
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
