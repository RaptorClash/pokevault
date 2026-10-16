import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../i18n/strings.g.dart';

class DexSortSettingsScreen extends StatefulWidget {
  final UserDex dex;

  const DexSortSettingsScreen({super.key, required this.dex});

  @override
  State<DexSortSettingsScreen> createState() => _DexSortSettingsScreenState();
}

class _DexSortSettingsScreenState extends State<DexSortSettingsScreen> {
  late String _megaSort;
  late String _gmaxSort;
  late String _regionalSort;

  @override
  void initState() {
    super.initState();
    _megaSort = widget.dex.megaSort;
    _gmaxSort = widget.dex.gmaxSort;
    _regionalSort = widget.dex.regionalSort;
  }

  void _saveSettings() {
    context.read<DexProvider>().updateSortSettings(
      dex: widget.dex,
      megaSort: _megaSort,
      gmaxSort: _gmaxSort,
      regionalSort: _regionalSort,
    );
  }

  Widget _buildRadioOption(String title, String value) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.advanced_sort_title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            t.sort_mega_title,
            _megaSort,
            (v) => setState(() => _megaSort = v!),
            [
              _buildRadioOption(t.sort_origin_kanto, 'origin'),
              _buildRadioOption(t.sort_mechanic_mega, 'mechanic'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            t.sort_gmax_title,
            _gmaxSort,
            (v) => setState(() => _gmaxSort = v!),
            [
              _buildRadioOption(t.sort_origin_kanto, 'origin'),
              _buildRadioOption(t.sort_mechanic_gmax, 'mechanic'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            t.sort_regional_title,
            _regionalSort,
            (v) => setState(() => _regionalSort = v!),
            [
              _buildRadioOption(t.sort_origin_kanto, 'origin'),
              _buildRadioOption(t.sort_mechanic_regional, 'mechanic'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    String groupValue,
    ValueChanged<String?> onChanged,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioGroup<String>(
        groupValue: groupValue,
        onChanged: (val) {
          if (val != null) {
            onChanged(val);
            _saveSettings();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}