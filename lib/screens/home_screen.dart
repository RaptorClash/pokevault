import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dex_provider.dart';
import '../services/dex_storage_service.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import 'dex_screen.dart';
import '../data/national_dex_data.dart';
import '../data/dex_orders.dart';

class DexGroup {
  final String name;
  final List<int> displayPokemonIds;
  final List<String> dexKeys;

  DexGroup(this.name, this.displayPokemonIds, this.dexKeys);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedDexIds = {};
  bool get _isSelectionMode => _selectedDexIds.isNotEmpty;

  final List<DexGroup> _dexGroups = [
    DexGroup('National', [151, 251, 385, 493], ['national_overall']),

    DexGroup(
      'Kanto',
      [3, 6, 9, 25],
      ['kanto_regional', 'letsgo_kanto_regional'],
    ),

    DexGroup(
      'Johto',
      [250, 249, 245, 251],
      ['johto_regional', 'updated_johto_regional'],
    ),

    DexGroup(
      'Hoenn',
      [382, 383, 384, 386],
      ['hoenn_regional', 'updated_hoenn_regional'],
    ),

    DexGroup(
      'Sinnoh',
      [483, 484, 487, 448],
      ['sinnoh_regional', 'extended_sinnoh_regional'],
    ),

    DexGroup(
      'Einall',
      [643, 644, 646, 494],
      ['unova_regional', 'updated_unova_regional'],
    ),

    DexGroup(
      'Kalos & Z-A',
      [716, 717, 718, 719],
      [
        'kalos_central_regional',
        'kalos_coastal_regional',
        'kalos_mountain_regional',
        'lumiose_regional',
        'lumiose_dimensions_regional',
      ],
    ),

    DexGroup(
      'Alola',
      [791, 792, 800, 773],
      [
        'alola_regional',
        'melemele_regional',
        'akala_regional',
        'ulaula_regional',
        'poni_regional',
        'updated_alola_regional',
        'updated_melemele_regional',
        'updated_akala_regional',
        'updated_ulaula_regional',
        'updated_poni_regional',
      ],
    ),

    DexGroup(
      'Galar & Hisui',
      [888, 889, 890, 493],
      [
        'galar_regional',
        'isle_of_armor_regional',
        'crown_tundra_regional',
        'hisui_regional',
      ],
    ),

    DexGroup(
      'Paldea',
      [1007, 1008, 1017, 1024],
      ['paldea_regional', 'kitakami_regional', 'blueberry_regional'],
    ),
  ];

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedDexIds.contains(id))
        _selectedDexIds.remove(id);
      else
        _selectedDexIds.add(id);
    });
  }

  void _clearSelection() => setState(() => _selectedDexIds.clear());

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
                '${_selectedDexIds.length} ${provider.getText('selected')}',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.upload),
                  tooltip: provider.getText('export_tooltip'),
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
              title: Text(provider.getText('app_title')),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              leading: PopupMenuButton<String>(
                icon: const Icon(Icons.settings),
                tooltip: provider.getText('settings'),
                onSelected: (value) async {
                  if (value == 'theme') provider.toggleTheme();
                  if (value == 'de' || value == 'en')
                    provider.setLanguage(value);
                  if (value == 'import') await provider.importJsonData();
                  if (value == 'export') {
                    if (dexes.isEmpty) return;
                    await DexStorageService.exportDexes(dexes, provider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          provider.themeMode == ThemeMode.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.getText(
                            provider.themeMode == ThemeMode.dark
                                ? 'light_mode'
                                : 'dark_mode',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'de',
                    child: Text('🇩🇪 Deutsch (DE)'),
                  ),
                  const PopupMenuItem(
                    value: 'en',
                    child: Text('🇬🇧 English (EN)'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        const Icon(Icons.download),
                        const SizedBox(width: 8),
                        Text(provider.getText('import_tooltip')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        const Icon(Icons.upload),
                        const SizedBox(width: 8),
                        Text(provider.getText('export_tooltip')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: dexes.isEmpty
          ? Center(
              child: Text(
                provider.getText('no_dex'),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: dexes.length,
              itemBuilder: (context, index) {
                final dex = dexes[index];
                String regionName = provider.getText('region_${dex.region}');
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
                    '${provider.getText('region')}: $regionName | ${provider.getText('caught')}: ${dex.caughtIds.length}',
                  ),
                  trailing: _isSelectionMode
                      ? null
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit')
                              _showEditDexDialog(context, provider, dex);
                            else if (value == 'delete')
                              _confirmDelete(context, provider, dex);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  Text(provider.getText('edit')),
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
                                    provider.getText('delete'),
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
                        return nationalPokemonDatabase.firstWhere(
                          (pokemon) => pokemon.id == id,
                          orElse: () => Pokemon(
                            id: id,
                            names: {'de': 'Unbekannt', 'en': 'Unknown'},
                          ),
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
              onPressed: () => _showCreateDexBottomSheet(context, provider),
              child: const Icon(Icons.add),
            ),
    );
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

  void _showCreateDexBottomSheet(BuildContext context, DexProvider provider) {
    final TextEditingController nameController = TextEditingController();

    DexGroup selectedGroup = _dexGroups.first;
    String selectedSubDex = selectedGroup.dexKeys.first;
    bool includeForms = false;
    bool includeGenders = false;

    nameController.text = provider.getText('region_$selectedSubDex');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                bottom: bottomPadding,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.getText('create_dex_title'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.getText('choose_generation'),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dexGroups.length,
                      itemBuilder: (context, index) {
                        final group = _dexGroups[index];
                        final isSelected = selectedGroup == group;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGroup = group;
                              selectedSubDex = group.dexKeys.first;
                              nameController.text = provider.getText(
                                'region_$selectedSubDex',
                              );
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 140, // Breite der Collage-Karte
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
                                color: isSelected
                                    ? Colors.red
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: _buildCollage(
                                      group.displayPokemonIds,
                                    ),
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
                                      group.name,
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
                        labelText: provider.getText('exact_pokedex'),
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
                            provider.getText('region_$key') != 'region_$key'
                                ? provider.getText('region_$key')
                                : key,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedSubDex = val;
                            nameController.text = provider.getText(
                              'region_$selectedSubDex',
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: provider.getText('create_dex_hint'),
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

                  // EINSTELLUNGEN
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
                          title: Text(provider.getText('include_forms')),
                          secondary: const Icon(Icons.auto_awesome),
                          value: includeForms,
                          activeColor: Colors.red,
                          onChanged: (val) =>
                              setState(() => includeForms = val),
                        ),
                        SwitchListTile(
                          title: Text(provider.getText('include_genders')),
                          secondary: const Icon(Icons.wc),
                          value: includeGenders,
                          activeColor: Colors.red,
                          onChanged: (val) =>
                              setState(() => includeGenders = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(provider.getText('cancel')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isNotEmpty) {
                              provider.createDex(
                                nameController.text,
                                selectedSubDex,
                                includeForms,
                                includeGenders,
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
                            provider.getText('create'),
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
            );
          },
        );
      },
    );
  }

  void _showEditDexDialog(
    BuildContext context,
    DexProvider provider,
    UserDex dex,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: dex.title,
    );
    bool includeForms = dex.includeForms;
    bool includeGenders = dex.includeGenders;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(provider.getText('edit')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: provider.getText('create_dex_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.edit),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(provider.getText('include_forms')),
                      secondary: const Icon(Icons.auto_awesome),
                      value: includeForms,
                      activeColor: Colors.red,
                      onChanged: (val) => setState(() => includeForms = val),
                    ),
                    SwitchListTile(
                      title: Text(provider.getText('include_genders')),
                      secondary: const Icon(Icons.wc),
                      value: includeGenders,
                      activeColor: Colors.red,
                      onChanged: (val) => setState(() => includeGenders = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(provider.getText('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      provider.updateDex(
                        dex.id,
                        nameController.text,
                        includeForms,
                        includeGenders,
                      ); //[cite: 3]
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(provider.getText('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DexProvider provider, UserDex dex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.getText('delete_confirm_title')),
        content: Text(provider.getText('delete_confirm_text')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(provider.getText('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.deleteDex(dex.id); //[cite: 3]
              Navigator.pop(context);
            },
            child: Text(provider.getText('delete')),
          ),
        ],
      ),
    );
  }

  void _confirmMultipleDelete(BuildContext context, DexProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.getText('delete_multiple_confirm_title')),
        content: Text(provider.getText('delete_multiple_confirm_text')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(provider.getText('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.deleteMultipleDexes(_selectedDexIds); //[cite: 3]
              _clearSelection(); //[cite: 4]
              Navigator.pop(context);
            },
            child: Text(provider.getText('delete')),
          ),
        ],
      ),
    );
  }
}
