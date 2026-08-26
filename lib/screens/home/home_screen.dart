import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../services/dex_storage_service.dart';
import '../../models/pokemon.dart';
import '../../models/user_dex.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../data/national_dex_data.dart';
import '../../data/dex_orders.dart';
import '../dex/dex_screen.dart';
import '../settings/settings_screen.dart';
import '../../utils/update_helper.dart';
import '../../widgets/dialogs/update_dialog.dart';
import '../../utils/notification_helper.dart';
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
  final GlobalKey _fabKey = GlobalKey();

  final Map<String, GlobalKey> _dexKeys = {};

  final Set<String> _selectedItemIds = {};
  late final Map<int, Pokemon> _pokemonCache;
  String _searchQuery = '';
  String _currentSort = 'manual';
  late String _currentFolderId;

  bool get _isSelectionMode => _selectedItemIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.currentFolderId;
    _pokemonCache = {for (var p in nationalPokemonDatabase) p.id: p};

    if (_currentFolderId == 'root') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdates();
        _showTutorialIfNeeded();
      });
    }
  }

  void _showTutorialIfNeeded() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    final dexProvider = Provider.of<DexProvider>(context, listen: false);

    if (!tutProvider.hasSeenFeature('home_screen')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'home_screen',
          nameKey: 'tutorial_feature_home',
          steps: [
            TutorialStep(
              targetKey: null,
              titleKey: 'tutorial_home_intro_title',
              textKey: 'tutorial_home_intro_text',
            ),
            TutorialStep(
              targetKey: _fabKey,
              titleKey: 'tutorial_home_fab_title',
              textKey: 'tutorial_home_fab_text',
              requireTargetTap: true,
              onTargetTap: () {
                try {
                  tutProvider.markFeatureAsSeen('home_screen');
                  _openCreateBottomSheet();
                } catch (e) {
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              },
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('home_screen'),
        initialIndex: tutProvider.getFeatureStep('home_screen'),
        onStepChanged: (step) =>
            tutProvider.updateFatureStep('home_screen', step),
      );
    } else if (dexProvider.userDexes.isNotEmpty &&
        !tutProvider.hasSeenFeature('open_dex')) {
      final newestDex = dexProvider.userDexes.last;

      if (!_dexKeys.containsKey(newestDex.id)) {
        _dexKeys[newestDex.id] = GlobalKey();
      }

      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'open_dex',
          nameKey: 'tutorial_feature_home',
          steps: [
            TutorialStep(
              targetKey: _dexKeys[newestDex.id],
              titleKey: 'tutorial_open_dex_title',
              textKey: 'tutorial_open_dex_text',
              requireTargetTap: true,
              onTargetTap: () {
                tutProvider.markFeatureAsSeen('open_dex');

                List<int> selectedOrder =
                    allAvailableDexes[newestDex.region] ?? [];
                List<Pokemon> selectedDatabase = selectedOrder
                    .map(
                      (id) =>
                          _pokemonCache[id] ??
                          Pokemon(
                            id: id,
                            names: {'de': 'Unbekannt', 'en': 'Unknown'},
                            hasGenderDifferences: false,
                            genderRate: -1,
                            eggGroups: [],
                            evolutionChainId: -1,
                            forms: [],
                            captureRate: 255,
                          ),
                    )
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DexScreen(
                      initialDex: newestDex,
                      pokemonList: selectedDatabase,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _showTutorialIfNeeded();
                });
              },
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('open_dex'),
      );
    }
  }

  void _openCreateBottomSheet() {
    final provider = Provider.of<DexProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _HomeBottomSheetContent(
        provider: provider,
        currentFolderId: _currentFolderId,
        onFolderCreate: () {
          Navigator.pop(ctx);
          _showCreateFolderDialog(provider);
        },
      ),
    );
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

  String _getParentId(DexProvider provider, String id) {
    for (var entry in provider.structure.entries) {
      if (entry.value.contains(id)) return entry.key;
    }
    return 'root';
  }

  void _recursiveDelete(DexProvider provider, String itemId) {
    if (itemId.startsWith('folder_')) {
      final children = List<String>.from(provider.structure[itemId] ?? []);
      for (var child in children) {
        _recursiveDelete(provider, child);
      }
      provider.deleteFolder(itemId);
    } else {
      provider.deleteDex(itemId);
    }
  }

  List<UserDex> _getDexesToExport(
    DexProvider provider,
    Set<String> selectedIds,
  ) {
    Set<String> dexIdsToExport = {};
    void gather(String id) {
      if (id.startsWith('folder_')) {
        final children = provider.structure[id] ?? [];
        for (var child in children) {
          gather(child);
        }
      } else {
        dexIdsToExport.add(id);
      }
    }

    for (var id in selectedIds) {
      gather(id);
    }
    return provider.userDexes
        .where((d) => dexIdsToExport.contains(d.id))
        .toList();
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
              try {
                provider.deleteDex(dex.id);
                Navigator.pop(context);
                NotificationHelper.showSuccess('Erfolgreich gelöscht.');
              } catch (e) {
                Navigator.pop(context);
                NotificationHelper.showError(
                  '${Translator.get('error_delete_dex')} $e',
                );
              }
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
    bool recursiveDelete = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(
              Translator.get('delete_folder_title') != 'delete_folder_title'
                  ? Translator.get('delete_folder_title')
                  : 'Ordner löschen',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translator.get('delete_folder_text') != 'delete_folder_text'
                      ? Translator.get('delete_folder_text')
                      : 'Möchtest du diesen Ordner wirklich löschen?',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Inhalt rekursiv löschen',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: recursiveDelete,
                  onChanged: (val) {
                    setStateSB(() => recursiveDelete = val ?? false);
                  },
                ),
              ],
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
                  try {
                    if (recursiveDelete) {
                      _recursiveDelete(provider, folder.id);
                    } else {
                      provider.deleteFolder(folder.id);
                    }
                    Navigator.pop(context);
                    NotificationHelper.showSuccess('Erfolgreich gelöscht.');
                  } catch (e) {
                    Navigator.pop(context);
                    NotificationHelper.showError(
                      '${Translator.get('error_delete_folder')} $e',
                    );
                  }
                },
                child: Text(Translator.get('delete')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateFolderDialog(DexProvider provider) {
    final TextEditingController _ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuer Ordner'),
        content: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(hintText: 'Ordnername'),
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
                try {
                  provider.createFolder(_ctrl.text, _currentFolderId);
                  Navigator.pop(ctx);
                } catch (e) {
                  Navigator.pop(ctx);
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
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
        title: const Text('Ordner umbenennen'),
        content: TextField(controller: _ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translator.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (_ctrl.text.isNotEmpty) {
                try {
                  provider.renameFolder(folder.id, _ctrl.text);
                  Navigator.pop(ctx);
                } catch (e) {
                  Navigator.pop(ctx);
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(DexProvider provider, Set<String> itemIds) {
    Set<String>? commonAllowed;
    for (String itemId in itemIds) {
      String currentParentId = _getParentId(provider, itemId);
      Set<String> allowed = {'root'};
      if (currentParentId != 'root') {
        allowed.add(_getParentId(provider, currentParentId));
      }
      final childrenOfParent = provider.structure[currentParentId] ?? [];
      for (var childId in childrenOfParent) {
        if (childId.startsWith('folder_')) {
          allowed.add(childId);
        }
      }
      allowed.remove(currentParentId);
      if (itemId.startsWith('folder_')) {
        allowed.removeWhere((id) => provider.isDescendant(itemId, id));
        allowed.remove(itemId);
      }
      if (commonAllowed == null) {
        commonAllowed = allowed;
      } else {
        commonAllowed = commonAllowed.intersection(allowed);
      }
    }
    if (commonAllowed == null || commonAllowed.isEmpty) {
      NotificationHelper.showInfo(
        'Kein gemeinsames gültiges Ziel zum Verschieben verfügbar.',
      );
      return;
    }
    List<MapEntry<String, String>> targets = [];
    if (commonAllowed.contains('root')) {
      targets.add(const MapEntry('root', 'Hauptverzeichnis'));
    }
    for (var folder in provider.folders) {
      if (commonAllowed.contains(folder.id)) {
        targets.add(MapEntry(folder.id, folder.title));
      }
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Verschieben nach...'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: targets.length,
              itemBuilder: (context, i) {
                return ListTile(
                  leading: Icon(
                    targets[i].key == 'root' ? Icons.home : Icons.folder,
                    color: targets[i].key == 'root'
                        ? Colors.red
                        : Colors.blueAccent,
                  ),
                  title: Text(targets[i].value),
                  onTap: () {
                    try {
                      for (String id in itemIds) {
                        provider.moveItem(id, targets[i].key);
                      }
                      _clearSelection();
                      Navigator.pop(ctx);
                      NotificationHelper.showSuccess('Erfolgreich verschoben.');
                    } catch (e) {
                      Navigator.pop(ctx);
                      NotificationHelper.showError(
                        '${Translator.get('error_move_item')} $e',
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(Translator.get('cancel')),
            ),
          ],
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
        if (d != null) {
          String regionName = Translator.get(
            'region_${d.region}',
          ).toLowerCase();
          if (d.title.toLowerCase().contains(query) ||
              regionName.contains(query)) {
            return true;
          }
        }
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

        bool isSelected = isRootLevel && _selectedItemIds.contains(item.id);

        widgets.add(
          Card(
            key: ValueKey('${item.id}_${q}_$_isSelectionMode'),
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
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onLongPress: isRootLevel
                  ? () {
                      setState(() {
                        _selectedItemIds.add(item.id);
                      });
                    }
                  : () {},
              onTap: (_isSelectionMode && isRootLevel)
                  ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedItemIds.remove(item.id);
                        } else {
                          _selectedItemIds.add(item.id);
                        }
                      });
                    }
                  : (_isSelectionMode ? () {} : null),
              child: IgnorePointer(
                ignoring: _isSelectionMode,
                child: ExpansionTile(
                  initiallyExpanded:
                      !_isSelectionMode && q.isNotEmpty && hasMatchInChildren,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.folder,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        _currentFolderId = item.id;
                        _searchQuery = '';
                      });
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
                          if (val == 'move')
                            _showMoveDialog(provider, {item.id});
                          if (val == 'delete')
                            _confirmDeleteFolder(context, provider, item);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Umbenennen'),
                          ),
                          const PopupMenuItem(
                            value: 'move',
                            child: Text('Verschieben...'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Löschen',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      if (isRootLevel &&
                          _currentSort == 'manual' &&
                          q.isEmpty &&
                          !_isSelectionMode)
                        ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
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
          ),
        );
      } else if (item is UserDex) {
        String regionName = Translator.get('region_${item.region}');
        bool matchesSearch =
            item.title.toLowerCase().contains(q) ||
            regionName.toLowerCase().contains(q);
        if (q.isNotEmpty && !matchesSearch) continue;

        bool isSelected = isRootLevel && _selectedItemIds.contains(item.id);

        if (!_dexKeys.containsKey(item.id)) {
          _dexKeys[item.id] = GlobalKey();
        }
        Key currentKey = _dexKeys[item.id]!;

        widgets.add(
          Card(
            key: currentKey,
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
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onLongPress: isRootLevel
                  ? () {
                      setState(() {
                        _selectedItemIds.add(item.id);
                      });
                    }
                  : () {},
              onTap: () {
                if (_isSelectionMode) {
                  if (isRootLevel) {
                    setState(() {
                      if (isSelected) {
                        _selectedItemIds.remove(item.id);
                      } else {
                        _selectedItemIds.add(item.id);
                      }
                    });
                  }
                  return;
                }

                final tutProvider = Provider.of<TutorialProvider>(
                  context,
                  listen: false,
                );
                if (!tutProvider.hasSeenFeature('open_dex')) {
                  tutProvider.markFeatureAsSeen('open_dex');
                }

                List<int> selectedOrder = allAvailableDexes[item.region] ?? [];
                List<Pokemon> selectedDatabase = selectedOrder
                    .map(
                      (id) =>
                          _pokemonCache[id] ??
                          Pokemon(
                            id: id,
                            names: {'de': 'Unbekannt', 'en': 'Unknown'},
                            hasGenderDifferences: false,
                            genderRate: -1,
                            eggGroups: [],
                            evolutionChainId: -1,
                            forms: [],
                            captureRate: 255,
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
                ).then((_) {
                  if (mounted) _showTutorialIfNeeded();
                });
              },
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
                        if (value == 'move')
                          _showMoveDialog(provider, {item.id});
                        if (value == 'delete')
                          _confirmDeleteDex(context, provider, item);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Bearbeiten'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'move',
                          child: Row(
                            children: [
                              Icon(Icons.drive_file_move_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Verschieben...'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Löschen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isRootLevel &&
                        _currentSort == 'manual' &&
                        q.isEmpty &&
                        !_isSelectionMode)
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
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
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  void _clearSelection() => setState(() => _selectedItemIds.clear());

  void _confirmMultipleDelete(BuildContext context, DexProvider provider) {
    bool hasFolder = _selectedItemIds.any((id) => id.startsWith('folder_'));
    bool recursiveDelete = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(Translator.get('delete_multiple_confirm_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Translator.get('delete_multiple_confirm_text')),
                if (hasFolder) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Ordnerinhalte rekursiv löschen',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: recursiveDelete,
                    onChanged: (val) {
                      setStateSB(() => recursiveDelete = val ?? false);
                    },
                  ),
                ],
              ],
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
                  try {
                    for (String id in _selectedItemIds) {
                      if (id.startsWith('folder_')) {
                        if (recursiveDelete) {
                          _recursiveDelete(provider, id);
                        } else {
                          provider.deleteFolder(id);
                        }
                      } else {
                        provider.deleteDex(id);
                      }
                    }
                    _clearSelection();
                    Navigator.pop(context);
                    NotificationHelper.showSuccess('Elemente gelöscht.');
                  } catch (e) {
                    Navigator.pop(context);
                    NotificationHelper.showError(
                      '${Translator.get('error')} $e',
                    );
                  }
                },
                child: Text(Translator.get('delete')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentFolderId == 'root') _showTutorialIfNeeded();
    });

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : (_currentFolderId != 'root'
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _currentFolderId = _getParentId(
                            provider,
                            _currentFolderId,
                          );
                          _searchQuery = '';
                        });
                      },
                    )
                  : null),
        title: _isSelectionMode
            ? Text('${_selectedItemIds.length} ausgewählt')
            : Text(
                _currentFolderId == 'root'
                    ? 'PokeVault'
                    : (provider.folders
                              .where((f) => f.id == _currentFolderId)
                              .firstOrNull
                              ?.title ??
                          'Ordner'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline),
                  tooltip: 'Verschieben',
                  onPressed: () => _showMoveDialog(provider, _selectedItemIds),
                ),
                IconButton(
                  icon: const Icon(Icons.upload),
                  tooltip: 'Exportieren',
                  onPressed: () async {
                    try {
                      final dexesToExport = _getDexesToExport(
                        provider,
                        _selectedItemIds,
                      );
                      if (dexesToExport.isNotEmpty) {
                        await DexStorageService.exportDexes(
                          dexesToExport,
                          provider,
                        );
                        _clearSelection();
                      } else {
                        NotificationHelper.showWarning(
                          'Keine Dexe zum Exportieren in der Auswahl gefunden.',
                        );
                      }
                    } catch (e) {
                      NotificationHelper.showError(
                        '${Translator.get('error')} $e',
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Löschen',
                  onPressed: () => _confirmMultipleDelete(context, provider),
                ),
              ]
            : [
                if (_currentFolderId == 'root')
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ).then((_) {
                        _showTutorialIfNeeded();
                      });
                    },
                  ),
              ],
      ),
      body: Column(
        children: [
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: Translator.get('search_hint'),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      onSelected: (value) =>
                          setState(() => _currentSort = value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'manual',
                          child: Text(
                            'Manuell',
                            style: TextStyle(
                              fontWeight: _currentSort == 'manual'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'az',
                          child: Text(
                            'A-Z',
                            style: TextStyle(
                              fontWeight: _currentSort == 'az'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'caught',
                          child: Text(
                            'Meiste Gefangen',
                            style: TextStyle(
                              fontWeight: _currentSort == 'caught'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'region',
                          child: Text(
                            'Nach Region',
                            style: TextStyle(
                              fontWeight: _currentSort == 'region'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: provider.userDexes.isEmpty && provider.folders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.catching_pokemon,
                          size: 64,
                          color: Theme.of(context).hintColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Translator.get('no_dexes'),
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : (_currentSort == 'manual' &&
                      _searchQuery.isEmpty &&
                      !_isSelectionMode)
                ? ReorderableListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final items = List<String>.from(
                          provider.structure[_currentFolderId] ?? [],
                        );
                        final item = items.removeAt(oldIndex);
                        items.insert(newIndex, item);
                        provider.updateStructureOrder(_currentFolderId, items);
                      });
                    },
                    children: _buildTree(provider, _currentFolderId, true),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: _buildTree(provider, _currentFolderId, true),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: _openCreateBottomSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HomeBottomSheetContent extends StatefulWidget {
  final DexProvider provider;
  final String currentFolderId;
  final VoidCallback onFolderCreate;

  const _HomeBottomSheetContent({
    required this.provider,
    required this.currentFolderId,
    required this.onFolderCreate,
  });

  @override
  State<_HomeBottomSheetContent> createState() =>
      _HomeBottomSheetContentState();
}

class _HomeBottomSheetContentState extends State<_HomeBottomSheetContent> {
  final GlobalKey _createDexKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
      if (!tutProvider.hasSeenFeature('home_bottom_sheet')) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          TutorialOverlay.show(
            context,
            TutorialFeature(
              id: 'home_bottom_sheet',
              nameKey: 'tutorial_home_sheet_title',
              steps: [
                TutorialStep(
                  targetKey: _createDexKey,
                  titleKey: 'tutorial_home_sheet_title',
                  textKey: 'tutorial_home_sheet_text',
                  requireTargetTap: true,
                  onTargetTap: () {
                    try {
                      tutProvider.markFeatureAsSeen('home_bottom_sheet');
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => CreateDexBottomSheet(
                          provider: widget.provider,
                          currentFolderId: widget.currentFolderId,
                        ),
                      );
                    } catch (e) {
                      NotificationHelper.showError(
                        '${Translator.get('error')} $e',
                      );
                    }
                  },
                ),
              ],
            ),
            () => tutProvider.markFeatureAsSeen('home_bottom_sheet'),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: _createDexKey,
          leading: const Icon(Icons.catching_pokemon, color: Colors.red),
          title: const Text('Neuen Pokédex erstellen'),
          onTap: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => CreateDexBottomSheet(
                provider: widget.provider,
                currentFolderId: widget.currentFolderId,
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder, color: Colors.blueAccent),
          title: Text(
            Translator.get('folder_create_title') != 'folder_create_title'
                ? Translator.get('folder_create_title')
                : 'Neuen Ordner erstellen',
          ),
          onTap: widget.onFolderCreate,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
