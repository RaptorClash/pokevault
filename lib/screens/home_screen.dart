import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
import '../providers/dex_provider.dart';
import '../services/dex_storage_service.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../data/dex_groups_data.dart';
import '../data/national_dex_data.dart';
import '../data/dex_orders.dart';
import 'dex_screen.dart';
import 'settings_screen.dart';
import '../utils/notification_helper.dart';
import '../utils/update_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedDexIds = {};
  late final Map<int, Pokemon> _pokemonCache;

  bool get _isSelectionMode => _selectedDexIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pokemonCache = {for (var p in nationalPokemonDatabase) p.id: p};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await UpdateHelper.checkForUpdate();
      if (updateInfo != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
      }
    } catch (e) {
    }
  }

  void _toggleSelection(String id) {
    try {
      setState(() {
        if (_selectedDexIds.contains(id)) {
          _selectedDexIds.remove(id);
        } else {
          _selectedDexIds.add(id);
        }
      });
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error')} $e");
    }
  }

  void _clearSelection() => setState(() => _selectedDexIds.clear());

  void _confirmDelete(BuildContext context, DexProvider provider, UserDex dex) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Translator.get('delete_confirm_title')),
          content: Text(Translator.get('delete_confirm_text')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Translator.get('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                provider.deleteDex(dex.id);
                Navigator.pop(context);
              },
              child: Text(Translator.get('delete')),
            ),
          ],
        ),
      );
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_confirm_delete')} $e",
      );
    }
  }

  void _confirmMultipleDelete(BuildContext context, DexProvider provider) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Translator.get('delete_multiple_confirm_title')),
          content: Text(Translator.get('delete_multiple_confirm_text')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Translator.get('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                provider.deleteMultipleDexes(_selectedDexIds);
                _clearSelection();
                Navigator.pop(context);
              },
              child: Text(Translator.get('delete')),
            ),
          ],
        ),
      );
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_confirm_mutiple_delete')} $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final dexes = provider.userDexes;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text(
                '${_selectedDexIds.length} ${Translator.get('selected')}',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.upload),
                  tooltip: Translator.get('export_tooltip'),
                  onPressed: () async {
                    final selectedDexes = dexes
                        .where((d) => _selectedDexIds.contains(d.id))
                        .toList();
                    await DexStorageService.exportDexes(
                      selectedDexes,
                      provider,
                    );
                    _clearSelection();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmMultipleDelete(context, provider),
                ),
              ],
            )
          : AppBar(
              title: Text(Translator.get('app_title')),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              leading: IconButton(
                icon: const Icon(Icons.settings),
                tooltip: Translator.get('settings'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
      body: dexes.isEmpty
          ? Center(
              child: Text(
                Translator.get('no_dex'),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: dexes.length,
              itemBuilder: (context, index) {
                final dex = dexes[index];
                String regionName = Translator.get('region_${dex.region}');
                bool isSelected = _selectedDexIds.contains(dex.id);

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (val) => _toggleSelection(dex.id),
                        )
                      : const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.catching_pokemon,
                            color: Colors.white,
                          ),
                        ),
                  title: Text(dex.title),
                  subtitle: Text(
                    '${Translator.get('region')}: $regionName | ${Translator.get('caught')}: ${dex.caughtIds.length}',
                  ),
                  trailing: _isSelectionMode
                      ? null
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    EditDexDialog(provider: provider, dex: dex),
                              );
                            } else if (value == 'delete') {
                              _confirmDelete(context, provider, dex);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  Text(Translator.get('edit')),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Translator.get('delete'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                  onLongPress: () {
                    if (!_isSelectionMode) _toggleSelection(dex.id);
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(dex.id);
                    } else {
                      List<int> selectedOrder =
                          allAvailableDexes[dex.region] ?? [];
                      List<Pokemon> selectedDatabase = selectedOrder.map((id) {
                        return _pokemonCache[id] ??
                            Pokemon(
                              id: id,
                              names: {'de': 'Unbekannt', 'en': 'Unknown'},
                              hasGenderDifferences: false,
                              forms: [],
                            );
                      }).toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DexScreen(
                            initialDex: dex,
                            pokemonList: selectedDatabase,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) =>
                      CreateDexBottomSheet(provider: provider),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}

class CreateDexBottomSheet extends StatefulWidget {
  final DexProvider provider;
  const CreateDexBottomSheet({super.key, required this.provider});

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
                        if (!features['mega']! && selectedSubDex != 'mega_dex')
                          includeMega = false;
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
                      if (!features['mega']! && selectedSubDex != 'mega_dex')
                        includeMega = false;
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
