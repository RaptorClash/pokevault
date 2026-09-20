import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_dex.dart';
import '../../services/database_service.dart';
import '../../providers/dex_provider.dart';
import '../../l10n/app_translations.dart';

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
    widget.dex.megaSort = _megaSort;
    widget.dex.gmaxSort = _gmaxSort;
    widget.dex.regionalSort = _regionalSort;
    
    DatabaseService.instance.saveUserDex(widget.dex);
    context.read<DexProvider>().notifyListeners(); 
  }

  Widget _buildRadioOption(String title, String value, String groupValue, Function(String?) onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        onChanged(val);
        _saveSettings();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translator.get('advanced_sort_title', fallback: 'Erweiterte Sortierung')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(Translator.get('sort_mega_title', fallback: 'Mega-Entwicklungen'), [
            _buildRadioOption(Translator.get('sort_origin_kanto', fallback: 'Ursprungsregion (z.B. Kanto)'), 'origin', _megaSort, (v) => setState(() => _megaSort = v!)),
            _buildRadioOption(Translator.get('sort_mechanic_mega', fallback: 'Region der Mechanik (Kalos/Hoenn)'), 'mechanic', _megaSort, (v) => setState(() => _megaSort = v!)),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard(Translator.get('sort_gmax_title', fallback: 'Giga-Dynamax'), [
            _buildRadioOption(Translator.get('sort_origin_kanto', fallback: 'Ursprungsregion (z.B. Kanto)'), 'origin', _gmaxSort, (v) => setState(() => _gmaxSort = v!)),
            _buildRadioOption(Translator.get('sort_mechanic_gmax', fallback: 'Region der Mechanik (Galar)'), 'mechanic', _gmaxSort, (v) => setState(() => _gmaxSort = v!)),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard(Translator.get('sort_regional_title', fallback: 'Regionalformen'), [
            _buildRadioOption(Translator.get('sort_origin_kanto', fallback: 'Ursprungsregion (z.B. Kanto)'), 'origin', _regionalSort, (v) => setState(() => _regionalSort = v!)),
            _buildRadioOption(Translator.get('sort_mechanic_regional', fallback: 'Region der Form (z.B. Alola)'), 'mechanic', _regionalSort, (v) => setState(() => _regionalSort = v!)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}