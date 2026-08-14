import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
import '../../providers/dex_provider.dart';
import '../../services/dex_storage_service.dart';
import '../../models/pokemon.dart';
import '../../models/user_dex.dart';
import '../../data/national_dex_data.dart';
import '../../data/dex_orders.dart';
import '../dex/dex_screen.dart';
import '../settings_screen.dart';
import '../../utils/notification_helper.dart';
import '../../utils/update_helper.dart';

// Die ausgelagerten Widgets importieren
import 'create_dex_bottom_sheet.dart';
import 'edit_dex_dialog.dart';

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
      // Leise scheitern, wenn kein Update gefunden wurde
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
