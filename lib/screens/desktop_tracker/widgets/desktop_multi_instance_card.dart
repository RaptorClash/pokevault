import 'package:flutter/material.dart';

import '../../../services/desktop_tracker/window_detector.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';

/// Multi-instance configuration card allowing parallel tracking across
/// independent screen regions or bound emulator windows.
class DesktopMultiInstanceCard extends StatelessWidget {
  final List<MultiInstanceSlot> slots;
  final List<DesktopWindowInfo> windows;
  final bool isDark;
  final VoidCallback onAddSlot;
  final VoidCallback onClearSlots;
  final ValueChanged<int> onRemoveSlot;
  final void Function(
    int slotId,
    MultiInstanceSlot Function(MultiInstanceSlot slot) updater,
  ) onUpdateSlot;
  final Future<void> Function(int slotId, {required bool isFocus})
      onStartSnipping;

  const DesktopMultiInstanceCard({
    super.key,
    required this.slots,
    required this.windows,
    required this.isDark,
    required this.onAddSlot,
    required this.onClearSlots,
    required this.onRemoveSlot,
    required this.onUpdateSlot,
    required this.onStartSnipping,
  });

  String _multiWindowValueForWindow(DesktopWindowInfo w) {
    return w.hwnd != 0 ? 'hwnd:${w.hwnd}' : 'id:${w.id}';
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = slots.where((s) => s.enabled).length;
    return Container(
      key: const Key('multi_instance_card'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222230) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slots.isNotEmpty
              ? const Color(0xFFA855F7).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF2F2F42) : Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                size: 14,
                color: Color(0xFFA855F7),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'MULTI-INSTANZEN',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${activeCount + 1} aktiv',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA855F7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Zone A/B oben = Instanz #1 · Weitere Instanzen frei mit Scan/Fokus oder Fenster koppeln:',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                key: const Key('btn_multi_add_instance'),
                onPressed: onAddSlot,
                icon: const Icon(Icons.add_box_outlined, size: 13),
                label: Text(
                  '+ Instanz #${slots.fold<int>(1, (m, s) => s.id > m ? s.id : m) + 1}',
                  style: const TextStyle(fontSize: 10),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              if (slots.isNotEmpty)
                TextButton(
                  key: const Key('btn_multi_clear'),
                  onPressed: onClearSlots,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Alle löschen',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
          if (slots.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...slots.map((slot) => _buildSingleSlotCard(slot)),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleSlotCard(MultiInstanceSlot slot) {
    final color = Color(slot.colorHex);
    final openApps = windows.where((w) => !w.isDesktopScreen).toList();
    String selectedWinVal = '';
    if (slot.isWindowBound) {
      if (slot.windowHwnd != null && slot.windowHwnd != 0) {
        selectedWinVal = 'hwnd:${slot.windowHwnd}';
      } else if (slot.windowId != null && slot.windowId != 0) {
        selectedWinVal = 'id:${slot.windowId}';
      }
    }

    final dropdownItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text(
          'Freie Bereiche (ohne festes Fenster)',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10),
        ),
      ),
      ...openApps.map((w) {
        return DropdownMenuItem<String>(
          value: _multiWindowValueForWindow(w),
          child: Text(
            '${w.title} (${w.width.round()}×${w.height.round()})',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        );
      }),
    ];
    if (selectedWinVal.isNotEmpty &&
        !dropdownItems.any((item) => item.value == selectedWinVal)) {
      dropdownItems.add(
        DropdownMenuItem<String>(
          value: selectedWinVal,
          child: Text(
            slot.windowTitle ?? 'Gebundenes Fenster',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
    }

    final roleSummary = switch ((slot.hasScan, slot.hasFocus)) {
      (true, true) => 'Scan + Fokus',
      (true, false) => 'Nur Scan',
      (false, true) => 'Nur Fokus',
      (false, false) => 'Bereich wählen',
    };

    return Container(
      key: Key('multi_instance_card_${slot.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191924) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: slot.enabled ? 0.65 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: 9,
                child: Text(
                  '${slot.id}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instanz ${slot.label}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      roleSummary,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: slot.enabled,
                  activeThumbColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => onUpdateSlot(
                    slot.id,
                    (s) => s.copyWith(enabled: v),
                  ),
                ),
              ),
              IconButton(
                key: Key('btn_multi_remove_${slot.id}'),
                tooltip: 'Instanz entfernen',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.close, size: 14),
                onPressed: () => onRemoveSlot(slot.id),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InputDecorator(
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              prefixIcon: const Icon(Icons.desktop_windows_outlined, size: 13),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 28, minHeight: 24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: Key('dropdown_multi_window_${slot.id}'),
                value: selectedWinVal,
                isExpanded: true,
                isDense: true,
                items: dropdownItems,
                onChanged: (val) {
                  if (val == null || val.isEmpty) {
                    onUpdateSlot(
                      slot.id,
                      (s) => s.copyWith(clearWindow: true),
                    );
                    return;
                  }
                  DesktopWindowInfo? chosen;
                  for (final w in openApps) {
                    if (_multiWindowValueForWindow(w) == val) {
                      chosen = w;
                      break;
                    }
                  }
                  if (chosen != null) {
                    onUpdateSlot(
                      slot.id,
                      (s) => s.copyWith(
                        enabled: true,
                        windowHwnd: chosen!.hwnd,
                        windowId: chosen.id,
                        windowTitle: chosen.title,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 22,
                child: Switch(
                  key: Key('switch_multi_scan_${slot.id}'),
                  value: slot.scanEnabled,
                  activeThumbColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => onUpdateSlot(
                    slot.id,
                    (s) => s.copyWith(scanEnabled: v),
                  ),
                ),
              ),
              Text(
                'Scan ${slot.label}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              OutlinedButton.icon(
                key: Key('btn_multi_draw_scan_${slot.id}'),
                onPressed: () => onStartSnipping(slot.id, isFocus: false),
                icon: const Icon(Icons.crop_free, size: 12),
                label: Text(
                  slot.scanRegion != null ? 'Scan neu' : 'Scan zeichnen',
                  style: const TextStyle(fontSize: 9),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.55)),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
              if (slot.scanRegion != null)
                InputChip(
                  label: Text(
                    '${slot.scanRegion!.width.round()}×${slot.scanRegion!.height.round()}',
                    style: const TextStyle(fontSize: 9),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () => onUpdateSlot(
                    slot.id,
                    (s) => s.copyWith(clearScanRegion: true),
                  ),
                ),
            ],
          ),
          if (slot.scanEnabled &&
              slot.scanRegion == null &&
              slot.isWindowBound) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: ScanRegionPreset.values.map((preset) {
                final selected = slot.scanPreset == preset;
                return ChoiceChip(
                  label: Text(preset.labelDe, style: const TextStyle(fontSize: 9)),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => onUpdateSlot(
                    slot.id,
                    (s) => s.copyWith(scanPreset: preset),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.center_focus_strong, size: 13, color: color),
              Text(
                'Fokus ${slot.label}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              OutlinedButton.icon(
                key: Key('btn_multi_draw_focus_${slot.id}'),
                onPressed: () => onStartSnipping(slot.id, isFocus: true),
                icon: const Icon(Icons.crop_free, size: 12),
                label: Text(
                  slot.focusRegion != null ? 'Fokus neu' : 'Fokus zeichnen',
                  style: const TextStyle(fontSize: 9),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.55)),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
              if (slot.focusPreset == LiveFocusPreset.customRegion &&
                  slot.focusRegion != null)
                InputChip(
                  label: Text(
                    '${slot.focusRegion!.width.round()}×${slot.focusRegion!.height.round()}',
                    style: const TextStyle(fontSize: 9),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () => onUpdateSlot(
                    slot.id,
                    (s) => s.copyWith(
                      focusPreset: LiveFocusPreset.disabled,
                      clearFocusRegion: true,
                    ),
                  ),
                ),
            ],
          ),
          if (slot.isWindowBound) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: const [
                LiveFocusPreset.disabled,
                LiveFocusPreset.topLeft,
                LiveFocusPreset.topRight,
                LiveFocusPreset.topBanner,
              ].map((preset) {
                final selected = slot.focusPreset == preset;
                return ChoiceChip(
                  label: Text(preset.labelDe, style: const TextStyle(fontSize: 9)),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => onUpdateSlot(
                    slot.id,
                    (s) => s.copyWith(focusPreset: preset),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
