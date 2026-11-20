import 'package:flutter/material.dart';

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
  late String _ocrLanguage;

  @override
  void initState() {
    super.initState();
    _preset = widget.currentPreset;
    _autoMark = widget.settings.autoMarkCaught;
    _ocrLanguage = widget.settings.ocrLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Tracker-Einstellungen', style: TextStyle(fontSize: 16)),
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
              const Text(
                'Scanbereich (Fensterbereich)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Wähle welcher Teil des Emulatorfensters per OCR abgetastet werden soll:',
                style: TextStyle(fontSize: 11, color: Colors.grey),
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
                      title: 'Ganzes Fenster (Empfohlen für DS & Multi-Screen)',
                      subtitle: 'Scannt das gesamte Spielfenster (100%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_top_screen',
                      preset: ScanRegionPreset.dsTopScreen,
                      title: 'Oberer DS-Bildschirm (DS-Kämpfe & Dialoge)',
                      subtitle: 'Scannt oberen Bildschirm (0-52%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_bottom_screen',
                      preset: ScanRegionPreset.dsBottomScreen,
                      title: 'Unterer DS-Bildschirm (Touchscreen)',
                      subtitle: 'Scannt unteren Bildschirm (48-100%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_bottom_dialogue',
                      preset: ScanRegionPreset.bottomDialogue,
                      title: 'Klassische Textbox (GBA / 3DS unten)',
                      subtitle:
                          'Scannt Textbox am unteren Fensterrand (70-100%)',
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              SwitchListTile(
                key: const Key('switch_auto_mark_caught'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Automatisch eintragen',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Erkannte Fänge direkt ohne Klick im Ziel-Dex speichern',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                value: _autoMark,
                onChanged: (val) {
                  setState(() => _autoMark = val);
                  widget.onSettingsChanged(
                    widget.settings.copyWith(autoMarkCaught: val),
                  );
                },
              ),
              const Divider(height: 24),
              const Text(
                'OCR-Sprache (Spieltext-Erkennung)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: const Key('dropdown_desktop_ocr_language'),
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
