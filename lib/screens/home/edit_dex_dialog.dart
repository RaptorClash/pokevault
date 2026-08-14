import 'package:flutter/material.dart';
import '../../data/dex_groups_data.dart';
import '../../l10n/app_translations.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';

class EditDexDialog extends StatefulWidget {
  final DexProvider provider;
  final UserDex dex;

  const EditDexDialog({super.key, required this.provider, required this.dex});

  @override
  State<EditDexDialog> createState() => _EditDexDialogState();
}

class _EditDexDialogState extends State<EditDexDialog> {
  late TextEditingController nameController;
  late bool includeGenders;
  late bool includeRegional;
  late bool includeMega;
  late bool includeGMax;
  late bool includeOther;
  late bool isShinyDex;
  late Map<String, bool> features;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.dex.title);
    includeGenders = widget.dex.includeGenders;
    includeRegional = widget.dex.includeRegional;
    includeMega = widget.dex.includeMega;
    includeGMax = widget.dex.includeGMax;
    includeOther = widget.dex.includeOther;
    isShinyDex = widget.dex.isShinyDex;
    features = DexGroupsData.getAvailableFeatures(widget.dex.region);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMegaDex = widget.dex.region == 'mega_dex';

    return AlertDialog(
      title: Text(Translator.get('edit')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: Translator.get('create_dex_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                Translator.get('shiny_dex') != 'shiny_dex'
                    ? Translator.get('shiny_dex')
                    : 'Shiny Dex',
              ),
              secondary: const Icon(Icons.star, color: Colors.amber),
              value: isShinyDex,
              activeColor: Colors.amber,
              onChanged: (val) => setState(() => isShinyDex = val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: Text(Translator.get('include_genders')),
              secondary: const Icon(Icons.wc),
              value: includeGenders,
              activeColor: Colors.red,
              onChanged: (val) => setState(() => includeGenders = val),
            ),
            const Divider(height: 1),
            ExpansionTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text(Translator.get('include_forms')),
              children: [
                CheckboxListTile(
                  title: Text(Translator.get('form_regional_short')),
                  value: includeRegional,
                  activeColor: Colors.red,
                  enabled: features['regional']!,
                  onChanged: features['regional']!
                      ? (val) => setState(() => includeRegional = val ?? false)
                      : null,
                ),
                CheckboxListTile(
                  title: Text(Translator.get('form_mega')),
                  value: isMegaDex ? true : includeMega,
                  activeColor: Colors.red,
                  enabled: !isMegaDex && features['mega']!,
                  onChanged: (!isMegaDex && features['mega']!)
                      ? (val) => setState(() => includeMega = val ?? false)
                      : null,
                ),
                CheckboxListTile(
                  title: Text(Translator.get('form_gmax')),
                  value: includeGMax,
                  activeColor: Colors.red,
                  enabled: features['gmax']!,
                  onChanged: features['gmax']!
                      ? (val) => setState(() => includeGMax = val ?? false)
                      : null,
                ),
                CheckboxListTile(
                  title: Text(Translator.get('form_other_short')),
                  value: includeOther,
                  activeColor: Colors.red,
                  onChanged: (val) =>
                      setState(() => includeOther = val ?? false),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Translator.get('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              widget.provider.updateDex(
                widget.dex.id,
                nameController.text,
                includeGenders,
                includeRegional,
                includeMega,
                includeGMax,
                includeOther,
                isShinyDex,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(Translator.get('save')),
        ),
      ],
    );
  }
}
