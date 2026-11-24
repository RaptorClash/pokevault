import 'package:material_ui/material_ui.dart';

import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/desktop_tracker/screen_region.dart';
import '../../../services/desktop_tracker/window_detector.dart';
import 'desktop_target_dex_card.dart';

/// Left-column setup card combining scan source selection, target Pokédex,
/// scan region configuration, HUD toggle, and primary scan/pause controls.
class DesktopWindowControlCard extends StatelessWidget {
  final GlobalKey sourceTutorialKey;
  final GlobalKey targetDexTutorialKey;
  final List<DesktopWindowInfo> windows;
  final DesktopWindowInfo? validSelectedWindow;
  final ScreenRegion? customScreenRegion;
  final bool isRefreshingWindows;
  final bool showOverlayControls;
  final bool showFloatingHud;
  final bool isScanningActive;
  final UserDex? activeDex;
  final DexProvider dexProvider;
  final bool isDark;
  final Widget scanRegionSection;
  final VoidCallback onRefreshWindows;
  final VoidCallback onExitCustomRegion;
  final ValueChanged<DesktopWindowInfo?> onWindowSelected;
  final VoidCallback onChangeDex;
  final VoidCallback onToggleFloatingHud;
  final VoidCallback onTriggerManualScan;
  final VoidCallback onToggleScanning;

  const DesktopWindowControlCard({
    super.key,
    required this.sourceTutorialKey,
    required this.targetDexTutorialKey,
    required this.windows,
    required this.validSelectedWindow,
    required this.customScreenRegion,
    required this.isRefreshingWindows,
    required this.showOverlayControls,
    required this.showFloatingHud,
    required this.isScanningActive,
    required this.activeDex,
    required this.dexProvider,
    required this.isDark,
    required this.scanRegionSection,
    required this.onRefreshWindows,
    required this.onExitCustomRegion,
    required this.onWindowSelected,
    required this.onChangeDex,
    required this.onToggleFloatingHud,
    required this.onTriggerManualScan,
    required this.onToggleScanning,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyedSubtree(
              key: sourceTutorialKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Scan-Quelle / Zielfenster',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('btn_refresh_windows'),
                        onPressed: onRefreshWindows,
                        icon: isRefreshingWindows
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, size: 14),
                        label: Text(
                          isRefreshingWindows ? 'Lade...' : 'Aktualisieren',
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  if (customScreenRegion != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      key: const Key('custom_region_source_banner'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.crop_free,
                            size: 15,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Eigener Desktop-Bereich',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '${customScreenRegion!.width.round()}×${customScreenRegion!.height.round()} px '
                                  'bei (${customScreenRegion!.x.round()}, ${customScreenRegion!.y.round()})',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            key: const Key('btn_exit_custom_region'),
                            onPressed: onExitCustomRegion,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            child: const Text(
                              'Zu Fenster',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    InputDecorator(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF242432)
                            : Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DesktopWindowInfo>(
                          key: const Key('emulator_dropdown'),
                          value: validSelectedWindow,
                          isExpanded: true,
                          items: windows.map((w) {
                            final icon = w.isCameraSource
                                ? '📷'
                                : (w.isKnownEmulator
                                    ? '🎮'
                                    : (w.isDesktopScreen ? '🖥️' : '🪟'));
                            final metaParts = w.isCameraSource
                                ? <String>[
                                    if (w.cameraIndex >= 0)
                                      '${w.width.round()}×${w.height.round()}'
                                    else
                                      'Foto',
                                  ]
                                : <String>[
                                    if (!w.isDesktopScreen &&
                                        w.processName != null &&
                                        w.processName!.isNotEmpty)
                                      w.processName!,
                                    '${w.width.round()}×${w.height.round()}',
                                    if (w.isMinimized) 'minimiert',
                                  ];
                            return DropdownMenuItem<DesktopWindowInfo>(
                              value: w,
                              child: Row(
                                children: [
                                  Text(
                                    icon,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      w.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: w.isKnownEmulator
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    flex: 0,
                                    child: Text(
                                      metaParts.join(' · '),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: onWindowSelected,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            DesktopTargetDexCard(
              tutorialKey: targetDexTutorialKey,
              activeDex: activeDex,
              dexProvider: dexProvider,
              isDark: isDark,
              onChangeDex: onChangeDex,
            ),
            const SizedBox(height: 10),
            scanRegionSection,
            const SizedBox(height: 10),
            if (showOverlayControls) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('btn_launch_floating_hud'),
                      onPressed: onToggleFloatingHud,
                      icon: Icon(
                        showFloatingHud
                            ? Icons.picture_in_picture
                            : Icons.picture_in_picture_alt,
                        size: 16,
                        color: const Color(0xFFEF5350),
                      ),
                      label: Text(
                        showFloatingHud
                            ? 'HUD schließen'
                            : 'Floating HUD öffnen',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white : Colors.black87,
                        side: const BorderSide(color: Color(0xFFEF5350)),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('btn_scan_now'),
                    onPressed: onTriggerManualScan,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text(
                      'Jetzt scannen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: onToggleScanning,
                    icon: Icon(
                      isScanningActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      isScanningActive ? 'Pausieren' : 'Fortsetzen',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
