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
import '../settings/settings_screen.dart';
import '../../utils/update_helper.dart';
import '../../widgets/dialogs/update_dialog.dart';
import 'create_dex_bottom_sheet.dart';
import 'edit_dex_dialog.dart';

class HomeScreen extends StatefulWidget {
  final String currentFolderId;
  final String? folderName;

  const HomeScreen({super.key, this.currentFolderId = 'root', this.folderName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedDexIds = {};
  late final Map<int, Pokemon> _pokemonCache;

  String _searchQuery = '';
  String _currentSort = 'manual';

  bool get _isSelectionMode => _selectedDexIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pokemonCache = {for (var p in nationalPokemonDatabase) p.id: p};
    if (widget.currentFolderId == 'root') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdates();
      });
    }
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
    } catch (e) {}
  }

  void _confirmDeleteDex(
    BuildContext context,
    DexProvider provider,
    UserDex dex,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Translator.get('dex_delete_title') != 'dex_delete_title'
              ? Translator.get('dex_delete_title')
              : 'Pokédex löschen',
        ),
        content: Text(
          Translator.get('dex_delete_text') != 'dex_delete_text'
              ? Translator.get('dex_delete_text')
              : 'Möchtest du diesen Pokédex wirklich löschen?',
        ),
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
  }

  void _confirmDeleteFolder(
    BuildContext context,
    DexProvider provider,
    DexFolder folder,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Translator.get('delete_folder_title') != 'delete_folder_title'
              ? Translator.get('delete_folder_title')
              : 'Ordner löschen',
        ),
        content: Text(
          Translator.get('delete_folder_text') != 'delete_folder_text'
              ? Translator.get('delete_folder_text')
              : 'Möchtest du diesen Ordner wirklich löschen? Der Inhalt wird sicher auf den Hauptbildschirm verschoben.',
        ),
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
              provider.deleteFolder(folder.id);
              Navigator.pop(context);
            },
            child: Text(Translator.get('delete')),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(DexProvider provider) {
    final TextEditingController _ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          Translator.get('folder_create_title') != 'folder_create_title'
              ? Translator.get('folder_create_title')
              : 'Neuer Ordner',
        ),
        content: TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: Translator.get('folder_name_hint') != 'folder_name_hint'
                ? Translator.get('folder_name_hint')
                : 'Ordnername',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translator.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (_ctrl.text.isNotEmpty) {
                provider.createFolder(_ctrl.text, widget.currentFolderId);
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(DexProvider provider, DexFolder folder) {
    final TextEditingController _ctrl = TextEditingController(
      text: folder.title,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          Translator.get('folder_rename_title') != 'folder_rename_title'
              ? Translator.get('folder_rename_title')
              : 'Ordner umbenennen',
        ),
        content: TextField(controller: _ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translator.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (_ctrl.text.isNotEmpty) {
                provider.renameFolder(folder.id, _ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(DexProvider provider, String itemId) {
    showDialog(
      context: context,
      builder: (ctx) {
        List<MapEntry<String, String>> targets = [];

        void buildTargetTree(String parentId, int depth) {
          if (provider.isDescendant(itemId, parentId)) return;

          if (parentId == 'root') {
            targets.add(
              MapEntry(
                'root',
                '🏠 ${Translator.get('folder_root') != 'folder_root' ? Translator.get('folder_root') : 'Hauptbildschirm'}',
              ),
            );
          } else {
            final f = provider.folders
                .where((x) => x.id == parentId)
                .firstOrNull;
            if (f != null) {
              String prefix = List.filled(depth, '—').join(' ');
              targets.add(MapEntry(parentId, '$prefix 📁 ${f.title}'));
            }
          }

          final children = provider.structure[parentId] ?? [];
          for (var childId in children) {
            if (childId.startsWith('folder_')) {
              buildTargetTree(childId, depth + 1);
            }
          }
        }

        buildTargetTree('root', 0);

        return AlertDialog(
          title: Text(
            Translator.get('folder_move_title') != 'folder_move_title'
                ? Translator.get('folder_move_title')
                : 'Verschieben nach...',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: targets.length,
              itemBuilder: (context, i) {
                return ListTile(
                  title: Text(targets[i].value),
                  onTap: () {
                    provider.moveItem(itemId, targets[i].key);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  bool _folderHasMatch(DexProvider provider, String folderId, String query) {
    final children = provider.structure[folderId] ?? [];
    for (var child in children) {
      if (child.startsWith('folder_')) {
        final f = provider.folders.where((x) => x.id == child).firstOrNull;
        if (f != null && f.title.toLowerCase().contains(query)) return true;
        if (_folderHasMatch(provider, child, query)) return true;
      } else {
        final d = provider.userDexes.where((x) => x.id == child).firstOrNull;
        if (d != null && d.title.toLowerCase().contains(query)) return true;
      }
    }
    return false;
  }

  List<dynamic> _getSortedItems(DexProvider provider, String folderId) {
    final itemIds = provider.structure[folderId] ?? [];
    List<dynamic> items = [];
    for (var id in itemIds) {
      if (id.startsWith('folder_')) {
        final f = provider.folders.where((x) => x.id == id).firstOrNull;
        if (f != null) items.add(f);
      } else {
        final d = provider.userDexes.where((x) => x.id == id).firstOrNull;
        if (d != null) items.add(d);
      }
    }

    if (_currentSort != 'manual') {
      items.sort((a, b) {
        if (a is DexFolder && b is UserDex) return -1;
        if (a is UserDex && b is DexFolder) return 1;
        if (a is UserDex && b is UserDex) {
          if (_currentSort == 'az') return a.title.compareTo(b.title);
          if (_currentSort == 'caught')
            return b.caughtIds.length.compareTo(a.caughtIds.length);
          if (_currentSort == 'region') return a.region.compareTo(b.region);
        }
        if (a is DexFolder && b is DexFolder) {
          return a.title.compareTo(b.title);
        }
        return 0;
      });
    }
    return items;
  }

  List<Widget> _buildTree(
    DexProvider provider,
    String parentId,
    bool isRootLevel,
  ) {
    final items = _getSortedItems(provider, parentId);
    List<Widget> widgets = [];
    final q = _searchQuery.toLowerCase();

    for (int index = 0; index < items.length; index++) {
      final item = items[index];

      if (item is DexFolder) {
        bool matchesSearch = item.title.toLowerCase().contains(q);
        bool hasMatchInChildren = _folderHasMatch(provider, item.id, q);

        if (q.isNotEmpty && !matchesSearch && !hasMatchInChildren) continue;

        widgets.add(
          Card(
            key: ValueKey(item.id),
            margin: EdgeInsets.symmetric(
              horizontal: isRootLevel ? 16 : 0,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: q.isNotEmpty && hasMatchInChildren,
                leading: IconButton(
                  icon: const Icon(
                    Icons.folder,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  tooltip: Translator.get('action_open') != 'action_open'
                      ? Translator.get('action_open')
                      : 'Ordner öffnen',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          currentFolderId: item.id,
                          folderName: item.title,
                        ),
                      ),
                    );
                  },
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (val) {
                        if (val == 'rename')
                          _showRenameFolderDialog(provider, item);
                        if (val == 'move') _showMoveDialog(provider, item.id);
                        if (val == 'delete')
                          _confirmDeleteFolder(context, provider, item);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text(
                            Translator.get('action_rename') != 'action_rename'
                                ? Translator.get('action_rename')
                                : 'Umbenennen',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'move',
                          child: Text(
                            Translator.get('action_move') != 'action_move'
                                ? Translator.get('action_move')
                                : 'Verschieben...',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            Translator.get('action_delete_keep') !=
                                    'action_delete_keep'
                                ? Translator.get('action_delete_keep')
                                : 'Löschen (Inhalt bleibt)',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    if (isRootLevel && _currentSort == 'manual' && q.isEmpty)
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 16,
                            bottom: 16,
                          ),
                          color: Colors.transparent,
                          child: const Icon(
                            Icons.drag_indicator,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: Column(
                      children: _buildTree(provider, item.id, false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (item is UserDex) {
        String regionName = Translator.get('region_${item.region}');
        bool matchesSearch =
            item.title.toLowerCase().contains(q) ||
            regionName.toLowerCase().contains(q);

        if (q.isNotEmpty && !matchesSearch) continue;

        bool isSelected = _selectedDexIds.contains(item.id);

        widgets.add(
          Card(
            key: ValueKey(item.id),
            elevation: isSelected ? 4 : 1,
            margin: EdgeInsets.symmetric(
              horizontal: isRootLevel ? 16 : 0,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.catching_pokemon, color: Colors.white),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${Translator.get('region')}: $regionName | ${Translator.get('caught')}: ${item.caughtIds.length}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit')
                        showDialog(
                          context: context,
                          builder: (_) =>
                              EditDexDialog(provider: provider, dex: item),
                        );
                      if (value == 'move') _showMoveDialog(provider, item.id);
                      if (value == 'delete')
                        _confirmDeleteDex(context, provider, item);
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
                        value: 'move',
                        child: Row(
                          children: [
                            const Icon(Icons.drive_file_move_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              Translator.get('action_move') != 'action_move'
                                  ? Translator.get('action_move')
                                  : 'Verschieben...',
                            ),
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
                  if (isRootLevel && _currentSort == 'manual' && q.isEmpty)
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 16,
                          bottom: 16,
                        ),
                        color: Colors.transparent,
                        child: const Icon(
                          Icons.drag_indicator,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                List<int> selectedOrder = allAvailableDexes[item.region] ?? [];
                List<Pokemon> selectedDatabase = selectedOrder
                    .map(
                      (id) =>
                          _pokemonCache[id] ??
                          Pokemon(
                            id: id,
                            names: {'de': 'Unbekannt', 'en': 'Unknown'},
                            hasGenderDifferences: false,
                            forms: [],
                          ),
                    )
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DexScreen(
                      initialDex: item,
                      pokemonList: selectedDatabase,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
    return widgets;
  }

  void _clearSelection() => setState(() => _selectedDexIds.clear());

  void _confirmMultipleDelete(BuildContext context, DexProvider provider) {
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final itemsTreeWidgets = _buildTree(provider, widget.currentFolderId, true);

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
                    final selectedDexes = provider.userDexes
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
              title: Text(widget.folderName ?? Translator.get('app_title')),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                if (widget.currentFolderId == 'root')
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: Translator.get('settings'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                  ),
              ],
            ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: Translator.get('search_hint') != 'search_hint'
                          ? Translator.get('search_hint')
                          : 'Suchen...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currentSort,
                      icon: const Icon(Icons.sort),
                      items: [
                        DropdownMenuItem(
                          value: 'manual',
                          child: Text(
                            Translator.get('sort_manual') != 'sort_manual'
                                ? Translator.get('sort_manual')
                                : 'Manuell',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'az',
                          child: Text(
                            Translator.get('sort_az') != 'sort_az'
                                ? Translator.get('sort_az')
                                : 'A-Z',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'caught',
                          child: Text(
                            Translator.get('sort_progress') != 'sort_progress'
                                ? Translator.get('sort_progress')
                                : 'Fortschritt',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'region',
                          child: Text(
                            Translator.get('sort_region') != 'sort_region'
                                ? Translator.get('sort_region')
                                : 'Region',
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _currentSort = val!),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: itemsTreeWidgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 80,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Translator.get('folder_empty') != 'folder_empty'
                              ? Translator.get('folder_empty')
                              : 'Hier ist es noch leer.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: 88, top: 8),
                    onReorder:
                        (_currentSort == 'manual' && _searchQuery.isEmpty)
                        ? (oldIndex, newIndex) {
                            int adjustedNewIndex = newIndex;
                            if (oldIndex < newIndex) adjustedNewIndex -= 1;
                            provider.reorderItemsInFolder(
                              widget.currentFolderId,
                              oldIndex,
                              adjustedNewIndex,
                            );
                          }
                        : (o, n) {},
                    children: itemsTreeWidgets,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.catching_pokemon,
                    color: Colors.red,
                  ),
                  title: const Text('Neuen Pokédex erstellen'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CreateDexBottomSheet(
                        provider: provider,
                        currentFolderId: widget.currentFolderId,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder, color: Colors.blueAccent),
                  title: Text(
                    Translator.get('folder_create_title') !=
                            'folder_create_title'
                        ? Translator.get('folder_create_title')
                        : 'Neuen Ordner erstellen',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreateFolderDialog(provider);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
