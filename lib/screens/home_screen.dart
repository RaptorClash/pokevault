import 'package:flutter/material.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:provider/provider.dart';
import '../providers/dex_provider.dart';
import '../services/dex_storage_service.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import 'dex_screen.dart';
import '../data/national_dex_data.dart';
import '../data/dex_orders.dart';
import 'settings_screen.dart';
import '../utils/notification_helper.dart';

class DexGroup {
  final String nameKey;
  final List<int> displayPokemonIds;
  final List<String> dexKeys;

  DexGroup(this.nameKey, this.displayPokemonIds, this.dexKeys);
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
    DexGroup('group_national', [151, 251, 385, 493], ['national_overall']),
    DexGroup(
      'group_kanto',
      [3, 6, 9, 25],
      ['kanto_regional', 'letsgo_kanto_regional'],
    ),
    DexGroup(
      'group_johto',
      [250, 249, 245, 251],
      ['johto_regional', 'updated_johto_regional'],
    ),
    DexGroup(
      'group_hoenn',
      [382, 383, 384, 386],
      ['hoenn_regional', 'updated_hoenn_regional'],
    ),
    DexGroup(
      'group_sinnoh',
      [483, 484, 487, 448],
      ['sinnoh_regional', 'extended_sinnoh_regional'],
    ),
    DexGroup(
      'group_unova',
      [643, 644, 646, 494],
      ['unova_regional', 'updated_unova_regional'],
    ),
    DexGroup(
      'group_kalos',
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
      'group_alola',
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
      'group_galar',
      [888, 889, 890, 493],
      [
        'galar_regional',
        'isle_of_armor_regional',
        'crown_tundra_regional',
        'hisui_regional',
      ],
    ),
    DexGroup(
      'group_paldea',
      [1007, 1008, 1017, 1024],
      ['paldea_regional', 'kitakami_regional', 'blueberry_regional'],
    ),
  ];

  Map<String, bool> _getAvailableFeatures(String dexKey) {
    try {
      if (dexKey == 'national_overall') {
        return {'regional': true, 'mega': true, 'gmax': true};
      }
      if (dexKey == 'letsgo_kanto_regional') {
        return {'regional': true, 'mega': true, 'gmax': false};
      }
      if (dexKey == 'updated_hoenn_regional') {
        return {'regional': false, 'mega': true, 'gmax': false};
      }
      if (dexKey.contains('kalos') || dexKey.contains('lumiose')) {
        return {'regional': false, 'mega': true, 'gmax': false};
      }
      if (dexKey.contains('alola') ||
          dexKey.contains('melemele') ||
          dexKey.contains('akala') ||
          dexKey.contains('ulaula') ||
          dexKey.contains('poni')) {
        return {'regional': true, 'mega': true, 'gmax': false};
      }
      if (dexKey.contains('galar') ||
          dexKey.contains('armor') ||
          dexKey.contains('tundra')) {
        return {'regional': true, 'mega': false, 'gmax': true};
      }
      if (dexKey.contains('hisui') ||
          dexKey.contains('paldea') ||
          dexKey.contains('kitakami') ||
          dexKey.contains('blueberry')) {
        return {'regional': true, 'mega': false, 'gmax': false};
      }
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_getting_available_features')} $e",
      );
    }
    return {'regional': false, 'mega': false, 'gmax': false};
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
                              _showEditDexDialog(context, provider, dex);
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
                        return nationalPokemonDatabase.firstWhere(
                          (pokemon) => pokemon.id == id,
                          orElse: () => Pokemon(
                            id: id,
                            names: {'de': 'Unbekannt', 'en': 'Unknown'},
                            hasGenderDifferences: false,
                            forms: [],
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

    bool includeGenders = false;
    bool includeRegional = false;
    bool includeMega = false;
    bool includeGMax = false;
    bool includeOther = false;

    Map<String, bool> features = _getAvailableFeatures(selectedSubDex);

    nameController.text = Translator.get('region_$selectedSubDex');

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translator.get('create_dex_title'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                        itemCount: _dexGroups.length,
                        itemBuilder: (context, index) {
                          final group = _dexGroups[index];
                          final isSelected = selectedGroup == group;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedGroup = group;
                                selectedSubDex = group.dexKeys.first;
                                nameController.text = Translator.get(
                                  'region_$selectedSubDex',
                                );

                                features = _getAvailableFeatures(
                                  selectedSubDex,
                                );
                                if (!features['regional']!)
                                  includeRegional = false;
                                if (!features['mega']!) includeMega = false;
                                if (!features['gmax']!) includeGMax = false;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 140,
                              margin: const EdgeInsets.only(
                                right: 12,
                                bottom: 8,
                              ),
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
                                        borderRadius:
                                            const BorderRadius.vertical(
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
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
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

                              features = _getAvailableFeatures(selectedSubDex);
                              if (!features['regional']!)
                                includeRegional = false;
                              if (!features['mega']!) includeMega = false;
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
                            title: Text(Translator.get('include_genders')),
                            secondary: const Icon(Icons.wc),
                            value: includeGenders,
                            activeColor: Colors.red,
                            onChanged: (val) =>
                                setState(() => includeGenders = val),
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
                                    ? (val) => setState(
                                        () => includeRegional = val ?? false,
                                      )
                                    : null,
                              ),
                              CheckboxListTile(
                                title: Text(Translator.get('form_mega')),
                                value: includeMega,
                                activeColor: Colors.red,
                                enabled: features['mega']!,
                                onChanged: features['mega']!
                                    ? (val) => setState(
                                        () => includeMega = val ?? false,
                                      )
                                    : null,
                              ),
                              CheckboxListTile(
                                title: Text(Translator.get('form_gmax')),
                                value: includeGMax,
                                activeColor: Colors.red,
                                enabled: features['gmax']!,
                                onChanged: features['gmax']!
                                    ? (val) => setState(
                                        () => includeGMax = val ?? false,
                                      )
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
                                provider.createDex(
                                  nameController.text,
                                  selectedSubDex,
                                  includeGenders,
                                  includeRegional,
                                  includeMega,
                                  includeGMax,
                                  includeOther,
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
    try {
      final TextEditingController nameController = TextEditingController(
        text: dex.title,
      );

      bool includeGenders = dex.includeGenders;
      bool includeRegional = dex.includeRegional;
      bool includeMega = dex.includeMega;
      bool includeGMax = dex.includeGMax;
      bool includeOther = dex.includeOther;

      final features = _getAvailableFeatures(dex.region);

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
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
                        title: Text(Translator.get('include_genders')),
                        secondary: const Icon(Icons.wc),
                        value: includeGenders,
                        activeColor: Colors.red,
                        onChanged: (val) =>
                            setState(() => includeGenders = val),
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
                                ? (val) => setState(
                                    () => includeRegional = val ?? false,
                                  )
                                : null,
                          ),
                          CheckboxListTile(
                            title: Text(Translator.get('form_mega')),
                            value: includeMega,
                            activeColor: Colors.red,
                            enabled: features['mega']!,
                            onChanged: features['mega']!
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
                        provider.updateDex(
                          dex.id,
                          nameController.text,
                          includeGenders,
                          includeRegional,
                          includeMega,
                          includeGMax,
                          includeOther,
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
            },
          );
        },
      );
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_show_edit_dex_dialog')} $e",
      );
    }
  }

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
}
