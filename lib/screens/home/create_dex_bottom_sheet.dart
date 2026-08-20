import 'package:flutter/material.dart';
import '../../data/dex_groups_data.dart';
import '../../l10n/app_translations.dart';
import '../../providers/dex_provider.dart';

class CreateDexBottomSheet extends StatefulWidget {
  final DexProvider provider;
  final String currentFolderId;

  const CreateDexBottomSheet({
    super.key,
    required this.provider,
    required this.currentFolderId,
  });

  @override
  State<CreateDexBottomSheet> createState() => _CreateDexBottomSheetState();
}

class _CreateDexBottomSheetState extends State<CreateDexBottomSheet> {
  final TextEditingController nameController = TextEditingController();
  late DexGroup selectedGroup;
  late String selectedSubDex;

  bool includeGenders = false;
  bool includeRegional = false;
  bool includeMega = false;
  bool includeGMax = false;
  bool includeOther = false;
  bool isShinyDex = false;

  late Map<String, bool> features;

  @override
  void initState() {
    super.initState();
    selectedGroup = DexGroupsData.groups.first;
    selectedSubDex = selectedGroup.dexKeys.first;
    features = DexGroupsData.getAvailableFeatures(selectedSubDex);
    nameController.text = Translator.get('region_$selectedSubDex');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Widget _buildCollage(List<int> ids) {
    const String baseUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/';
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[0]}.png',
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[1]}.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[2]}.png',
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Image.network(
                  '$baseUrl${ids[3]}.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    bool isMegaDex = selectedSubDex == 'mega_dex';

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.get('create_dex_title'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.get('choose_generation'),
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: DexGroupsData.groups.length,
                itemBuilder: (context, index) {
                  final group = DexGroupsData.groups[index];
                  final isSelected = selectedGroup == group;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedGroup = group;
                        selectedSubDex = group.dexKeys.first;
                        nameController.text = Translator.get(
                          'region_$selectedSubDex',
                        );
                        features = DexGroupsData.getAvailableFeatures(
                          selectedSubDex,
                        );
                        includeMega = selectedSubDex == 'mega_dex';
                        includeOther = selectedSubDex == 'icognito_dex';
                        if (!features['regional']!) includeRegional = false;
                        if (!features['mega']! &&
                            selectedSubDex != 'mega_dex') {
                          includeMega = false;
                        }
                        if (!features['gmax']!) includeGMax = false;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 140,
                      margin: const EdgeInsets.only(right: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.withOpacity(0.15)
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildCollage(group.displayPokemonIds),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.red
                                    : Colors.black.withOpacity(0.1),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(14),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Translator.get(group.nameKey),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (selectedGroup.dexKeys.length > 1) ...[
              DropdownButtonFormField<String>(
                value: selectedSubDex,
                decoration: InputDecoration(
                  labelText: Translator.get('exact_pokedex'),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: selectedGroup.dexKeys.map((key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(
                      Translator.get('region_$key') != 'region_$key'
                          ? Translator.get('region_$key')
                          : key,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedSubDex = val;
                      nameController.text = Translator.get(
                        'region_$selectedSubDex',
                      );
                      features = DexGroupsData.getAvailableFeatures(
                        selectedSubDex,
                      );
                      includeMega = selectedSubDex == 'mega_dex';
                      includeOther = selectedSubDex == 'icognito_dex';
                      if (!features['regional']!) includeRegional = false;
                      if (!features['mega']! && selectedSubDex != 'mega_dex') {
                        includeMega = false;
                      }
                      if (!features['gmax']!) includeGMax = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: Translator.get('create_dex_hint'),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
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
                        title: Text(Translator.get('form_regional')),
                        value: includeRegional,
                        activeColor: Colors.red,
                        enabled: features['regional']!,
                        onChanged: features['regional']!
                            ? (val) =>
                                  setState(() => includeRegional = val ?? false)
                            : null,
                      ),
                      CheckboxListTile(
                        title: Text(Translator.get('form_mega')),
                        value: isMegaDex ? true : includeMega,
                        activeColor: Colors.red,
                        enabled: !isMegaDex && features['mega']!,
                        onChanged: (!isMegaDex && features['mega']!)
                            ? (val) =>
                                  setState(() => includeMega = val ?? false)
                            : null,
                      ),
                      CheckboxListTile(
                        title: Text(Translator.get('form_gmax')),
                        value: includeGMax,
                        activeColor: Colors.red,
                        enabled: features['gmax']!,
                        onChanged: features['gmax']!
                            ? (val) =>
                                  setState(() => includeGMax = val ?? false)
                            : null,
                      ),
                      CheckboxListTile(
                        title: Text(Translator.get('form_other')),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(Translator.get('cancel')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        widget.provider.createDex(
                          nameController.text,
                          selectedSubDex,
                          includeGenders,
                          includeRegional,
                          includeMega,
                          includeGMax,
                          includeOther,
                          isShinyDex,
                          widget.currentFolderId,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      Translator.get('create'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
