import 'package:material_ui/material_ui.dart';

import '../../../i18n/strings.g.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';

/// Modal configuration dialog for preset scan region, auto-mark caught,
/// and OCR language selection in [DesktopTrackerScreen].
class TrackerSettingsDialog extends StatefulWidget {
  final ScanRegionPreset currentPreset;
  final ScannerSettings settings;
  final ValueChanged<ScanRegionPreset> onPresetChanged;
  final ValueChanged<ScannerSettings> onSettingsChanged;

  const TrackerSettingsDialog({
    super.key,
    required this.currentPreset,
    required this.settings,
    required this.onPresetChanged,
    required this.onSettingsChanged,
  });

  @override
  State<TrackerSettingsDialog> createState() => _TrackerSettingsDialogState();
}

class _TrackerSettingsDialogState extends State<TrackerSettingsDialog> {
  late ScanRegionPreset _preset;
  late bool _autoMark;
  late bool _maskSelfWindow;
  late String _ocrLanguage;

  @override
  void initState() {
    super.initState();
    _preset = widget.currentPreset;
    _autoMark = widget.settings.autoMarkCaught;
    _maskSelfWindow = widget.settings.maskSelfWindow;
    _ocrLanguage = widget.settings.ocrLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, size: 20),
              const SizedBox(width: 8),
              Text(
                t.scanner_settings_dialog_title,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          IconButton(
            key: const Key('btn_close_settings'),
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.scanner_settings_region_title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                t.scanner_settings_region_desc,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              RadioGroup<ScanRegionPreset>(
                groupValue: _preset,
                onChanged: (p) {
                  if (p != null) {
                    setState(() => _preset = p);
                    widget.onPresetChanged(p);
                  }
                },
                child: Column(
                  children: [
                    _buildPresetOption(
                      key: 'preset_full_window',
                      preset: ScanRegionPreset.fullWindow,
                      title: t.scanner_settings_full_title,
                      subtitle: t.scanner_settings_full_sub,
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_top_screen',
                      preset: ScanRegionPreset.dsTopScreen,
                      title: t.scanner_settings_ds_top_title,
                      subtitle: t.scanner_settings_ds_top_sub,
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_bottom_screen',
                      preset: ScanRegionPreset.dsBottomScreen,
                      title: t.scanner_settings_ds_bottom_title,
                      subtitle: t.scanner_settings_ds_bottom_sub,
                    ),
                    _buildPresetOption(
                      key: 'preset_bottom_dialogue',
                      preset: ScanRegionPreset.bottomDialogue,
                      title: t.scanner_settings_dialogue_title,
                      subtitle: t.scanner_settings_dialogue_sub,
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              SwitchListTile(
                key: const Key('switch_auto_mark_caught'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t.scanner_settings_auto_mark_title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  t.scanner_settings_auto_mark_sub,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                value: _autoMark,
                onChanged: (val) {
                  setState(() => _autoMark = val);
                  widget.onSettingsChanged(
                    widget.settings.copyWith(autoMarkCaught: val),
                  );
                },
              ),
              SwitchListTile(
                key: const Key('switch_mask_self_window'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'PokéVault-Fenster beim Desktop-Scan ausblenden',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Maskiert das eigene Fenster vor der OCR schwarz, um Self-Scans und unnötige CPU-Last zu verhindern.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                value: _maskSelfWindow,
                onChanged: (val) {
                  setState(() => _maskSelfWindow = val);
                  widget.onSettingsChanged(
                    widget.settings.copyWith(maskSelfWindow: val),
                  );
                },
              ),
              const Divider(height: 24),
              Text(
                t.scanner_settings_ocr_lang_title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: const Key('dropdown_desktop_ocr_language'),
                isExpanded: true,
                initialValue: kSupportedScannerOcrLanguages
                        .any((o) => o.code == _ocrLanguage)
                    ? _ocrLanguage
                    : 'auto',
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: kSupportedScannerOcrLanguages
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.code,
                        child: Text(o.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _ocrLanguage = val);
                  widget.onSettingsChanged(
                    widget.settings.copyWith(ocrLanguage: val),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetOption({
    required String key,
    required ScanRegionPreset preset,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      key: Key(key),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Radio<ScanRegionPreset>(
        value: preset,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      onTap: () {
        setState(() => _preset = preset);
        widget.onPresetChanged(preset);
      },
    );
  }
}
