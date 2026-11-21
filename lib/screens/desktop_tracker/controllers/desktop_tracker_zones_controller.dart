import 'dart:async';
import 'dart:ui';

import '../../../services/desktop_tracker/desktop_tracker_service.dart';
import '../../../services/desktop_tracker/screen_region.dart';
import '../../../services/desktop_tracker/window_detector.dart';
import '../../../services/desktop_tracker/windows_desktop_bridge.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';

/// Pure geometry, border overlay, and multi-instance slot coordinator for
/// [DesktopTrackerScreen].
class DesktopTrackerZonesController {
  /// Resolves the absolute screen rectangle for Zone A (primary OCR scan zone).
  static ScreenRegion? resolveAbsoluteZoneARegion({
    required DesktopWindowInfo? selectedWindow,
    required ScreenRegion? customScreenRegion,
    required Rect? cropRegion,
  }) {
    if (customScreenRegion != null && customScreenRegion.isAbsoluteScreen) {
      return customScreenRegion;
    }
    final win = selectedWindow;
    final bounds = win?.bounds;
    if (win != null &&
        !win.isDesktopScreen &&
        bounds != null &&
        cropRegion != null) {
      return ScreenRegion(
        x: bounds.left + cropRegion.left,
        y: bounds.top + cropRegion.top,
        width: cropRegion.width,
        height: cropRegion.height,
        isAbsoluteScreen: true,
        label: 'Zone A',
      );
    }
    return null;
  }

  /// Resolves the absolute screen rectangle for Zone B (live enemy HUD focus).
  static ScreenRegion? resolveAbsoluteZoneBRegion({
    required DesktopWindowInfo? selectedWindow,
    required LiveFocusPreset liveFocusPreset,
    required ScreenRegion? liveFocusScreenRegion,
  }) {
    if (liveFocusPreset == LiveFocusPreset.disabled) return null;
    if (liveFocusPreset == LiveFocusPreset.customRegion) {
      if (liveFocusScreenRegion != null &&
          liveFocusScreenRegion.isAbsoluteScreen) {
        return liveFocusScreenRegion;
      }
      return null;
    }
    final win = selectedWindow;
    final bounds = win?.bounds;
    if (win == null || win.isDesktopScreen || bounds == null) return null;
    final crop = WindowDetector().calculateEnemyHudCropRegion(
      liveFocusPreset,
      windowWidth: win.width,
      windowHeight: win.height,
    );
    if (crop == null) return null;
    return ScreenRegion(
      x: bounds.left + crop.left,
      y: bounds.top + crop.top,
      width: crop.width,
      height: crop.height,
      isAbsoluteScreen: true,
      label: 'Fokus',
    );
  }

  /// Resolves the bound [DesktopWindowInfo] for a [MultiInstanceSlot].
  static DesktopWindowInfo? resolveMultiSlotWindow(
    MultiInstanceSlot slot, {
    required List<DesktopWindowInfo> windows,
    DesktopWindowInfo? selectedWindow,
  }) {
    if (!slot.isWindowBound) return null;
    final candidates = [
      ...windows,
      ?selectedWindow,
    ];
    if (slot.windowHwnd != null && slot.windowHwnd != 0) {
      for (final w in candidates) {
        if (w.hwnd == slot.windowHwnd) return w;
      }
    }
    if (slot.windowId != null && slot.windowId != 0) {
      for (final w in candidates) {
        if (w.id == slot.windowId) return w;
      }
    }
    if (slot.windowTitle != null && slot.windowTitle!.isNotEmpty) {
      for (final w in candidates) {
        if (w.title == slot.windowTitle) return w;
      }
    }
    return null;
  }

  /// Computes all native overlay border specifications for Zone A, Zone B,
  /// and active multi-instance slots.
  static List<OverlayBorderSpec> computeOverlayBorderSpecs({
    required bool showScreenBorders,
    required DesktopWindowInfo? selectedWindow,
    required ScreenRegion? customScreenRegion,
    required Rect? cropRegion,
    required bool isScanningActive,
    required LiveFocusPreset liveFocusPreset,
    required ScreenRegion? liveFocusScreenRegion,
    List<ScreenRegion> extraFocusRegions = const [],
    required List<MultiInstanceSlot> multiInstanceSlots,
    required List<DesktopWindowInfo> windows,
    String scanLabel = 'Scan',
    String focusLabel = 'Fokus',
  }) {
    if (!showScreenBorders) return const [];

    final specs = <OverlayBorderSpec>[];
    final zoneARegion = resolveAbsoluteZoneARegion(
      selectedWindow: selectedWindow,
      customScreenRegion: customScreenRegion,
      cropRegion: cropRegion,
    );
    if (zoneARegion != null &&
        (customScreenRegion != null || isScanningActive)) {
      specs.add(
        OverlayBorderSpec(
          id: 'zone_a',
          region: zoneARegion,
          colorArgb: isScanningActive ? 0xFF10B981 : 0xFFF59E0B,
          label: multiInstanceSlots.isNotEmpty ? '$scanLabel #1' : scanLabel,
        ),
      );
    }

    final zoneBRegion = resolveAbsoluteZoneBRegion(
      selectedWindow: selectedWindow,
      liveFocusPreset: liveFocusPreset,
      liveFocusScreenRegion: liveFocusScreenRegion,
    );
    final hasExtraFocus = extraFocusRegions.isNotEmpty;
    if (zoneBRegion != null) {
      final baseLabel =
          multiInstanceSlots.isNotEmpty ? '$focusLabel #1' : focusLabel;
      specs.add(
        OverlayBorderSpec(
          id: 'zone_b',
          region: zoneBRegion,
          colorArgb: 0xFF06B6D4,
          label: hasExtraFocus ? '$baseLabel B1' : baseLabel,
        ),
      );
    }
    for (int i = 0; i < extraFocusRegions.length; i++) {
      final extra = extraFocusRegions[i];
      if (!extra.isAbsoluteScreen) continue;
      specs.add(
        OverlayBorderSpec(
          id: 'zone_b_${i + 2}',
          region: extra,
          colorArgb: 0xFF06B6D4,
          label: '$focusLabel B${i + 2}',
        ),
      );
    }

    final detector = WindowDetector();
    for (final slot in multiInstanceSlots) {
      if (!slot.enabled) continue;
      final boundWin = resolveMultiSlotWindow(
        slot,
        windows: windows,
        selectedWindow: selectedWindow,
      );

      if (slot.hasScan) {
        ScreenRegion? scanAbs;
        if (slot.scanRegion != null && slot.scanRegion!.isAbsoluteScreen) {
          scanAbs = slot.scanRegion;
        } else if (boundWin != null &&
            boundWin.bounds != null &&
            !boundWin.isDesktopScreen) {
          final crop = detector.calculateScanRegion(
            slot.scanPreset,
            windowWidth: boundWin.width,
            windowHeight: boundWin.height,
          );
          scanAbs = ScreenRegion(
            x: boundWin.bounds!.left + crop.left,
            y: boundWin.bounds!.top + crop.top,
            width: crop.width,
            height: crop.height,
            isAbsoluteScreen: true,
          );
        }
        if (scanAbs != null) {
          specs.add(
            OverlayBorderSpec(
              id: 'multi_${slot.id}_scan',
              region: scanAbs,
              colorArgb: slot.colorHex,
              label: '$scanLabel ${slot.label}',
            ),
          );
        }
      }

      if (slot.hasFocus) {
        ScreenRegion? focusAbs;
        if (slot.focusPreset == LiveFocusPreset.customRegion &&
            slot.focusRegion != null &&
            slot.focusRegion!.isAbsoluteScreen) {
          focusAbs = slot.focusRegion;
        } else if (slot.focusPreset != LiveFocusPreset.disabled &&
            slot.focusPreset != LiveFocusPreset.customRegion &&
            boundWin != null &&
            boundWin.bounds != null &&
            !boundWin.isDesktopScreen) {
          final crop = detector.calculateEnemyHudCropRegion(
            slot.focusPreset,
            windowWidth: boundWin.width,
            windowHeight: boundWin.height,
          );
          if (crop != null) {
            focusAbs = ScreenRegion(
              x: boundWin.bounds!.left + crop.left,
              y: boundWin.bounds!.top + crop.top,
              width: crop.width,
              height: crop.height,
              isAbsoluteScreen: true,
            );
          }
        }
        if (focusAbs != null) {
          specs.add(
            OverlayBorderSpec(
              id: 'multi_${slot.id}_focus',
              region: focusAbs,
              colorArgb: slot.colorHex,
              label: '$focusLabel ${slot.label}',
            ),
          );
        }
      }
    }

    return specs;
  }

  /// Synchronizes computed overlay borders with [DesktopTrackerService] and
  /// the native Windows [bridge].
  static void syncOverlayBorders({
    required DesktopPlatformBridge? bridge,
    required bool showScreenBorders,
    required DesktopWindowInfo? selectedWindow,
    required ScreenRegion? customScreenRegion,
    required Rect? cropRegion,
    required bool isScanningActive,
    required LiveFocusPreset liveFocusPreset,
    required ScreenRegion? liveFocusScreenRegion,
    List<ScreenRegion> extraFocusRegions = const [],
    required List<MultiInstanceSlot> multiInstanceSlots,
    required List<DesktopWindowInfo> windows,
    String scanLabel = 'Scan',
    String focusLabel = 'Fokus',
  }) {
    if (bridge == null) return;
    if (!showScreenBorders) {
      unawaited(bridge.setScanRegionBorder(null));
      DesktopTrackerService.instance.updateOverlayBorders(const []);
      unawaited(bridge.setOverlayBorders(const []));
      return;
    }

    final specs = computeOverlayBorderSpecs(
      showScreenBorders: showScreenBorders,
      selectedWindow: selectedWindow,
      customScreenRegion: customScreenRegion,
      cropRegion: cropRegion,
      isScanningActive: isScanningActive,
      liveFocusPreset: liveFocusPreset,
      liveFocusScreenRegion: liveFocusScreenRegion,
      extraFocusRegions: extraFocusRegions,
      multiInstanceSlots: multiInstanceSlots,
      windows: windows,
      scanLabel: scanLabel,
      focusLabel: focusLabel,
    );

    unawaited(bridge.setScanRegionBorder(null));
    DesktopTrackerService.instance.updateOverlayBorders(specs);
    unawaited(bridge.setOverlayBorders(specs));
  }

  /// Appends a new multi-instance slot (optionally bounded by [maxSlots]).
  static List<MultiInstanceSlot> addMultiInstanceSlot(
    List<MultiInstanceSlot> existing, {
    int? maxSlots,
  }) {
    if (maxSlots != null && existing.length >= maxSlots) {
      return List.unmodifiable(existing);
    }
    final maxId = existing.fold<int>(1, (m, s) => s.id > m ? s.id : m);
    final nextId = maxId + 1;
    final newSlot = MultiInstanceSlot(
      id: nextId,
      label: '#$nextId',
      colorHex: MultiInstanceGridHelper.colorForIndex(nextId - 2),
      scanEnabled: true,
      scanPreset: ScanRegionPreset.bottomDialogue,
      focusPreset: LiveFocusPreset.disabled,
    );
    return List.unmodifiable([...existing, newSlot]);
  }

  /// Maps an update over the slot matching [slotId].
  static List<MultiInstanceSlot> updateMultiSlot(
    List<MultiInstanceSlot> existing,
    int slotId,
    MultiInstanceSlot Function(MultiInstanceSlot slot) updater,
  ) {
    return existing
        .map((s) => s.id == slotId ? updater(s) : s)
        .toList(growable: false);
  }

  /// Applies a snipped absolute [region] to scan or focus of [slotId].
  static List<MultiInstanceSlot> applyMultiSlotRegion(
    List<MultiInstanceSlot> existing,
    int slotId,
    ScreenRegion region, {
    required bool isFocus,
    String scanPrefix = 'Scan',
    String focusPrefix = 'Fokus',
  }) {
    return existing.map((slot) {
      if (slot.id != slotId) return slot;
      if (isFocus) {
        return slot.copyWith(
          enabled: true,
          focusPreset: LiveFocusPreset.customRegion,
          focusRegion: ScreenRegion(
            x: region.x,
            y: region.y,
            width: region.width,
            height: region.height,
            isAbsoluteScreen: true,
            label: '$focusPrefix ${slot.label}',
          ),
        );
      }
      return slot.copyWith(
        enabled: true,
        scanEnabled: true,
        scanRegion: ScreenRegion(
          x: region.x,
          y: region.y,
          width: region.width,
          height: region.height,
          isAbsoluteScreen: true,
          label: '$scanPrefix ${slot.label}',
        ),
      );
    }).toList(growable: false);
  }

  /// Removes the slot with [slotId].
  static List<MultiInstanceSlot> removeMultiInstanceSlot(
    List<MultiInstanceSlot> existing,
    int slotId,
  ) {
    return existing.where((s) => s.id != slotId).toList(growable: false);
  }
}
