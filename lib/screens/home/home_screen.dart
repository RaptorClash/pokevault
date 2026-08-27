import 'dart:async';
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
import '../dex/dex_screen.dart';
import '../settings/settings_screen.dart';
import '../../utils/update_helper.dart';
import '../../widgets/dialogs/update_dialog.dart';
import '../../utils/notification_helper.dart';
import 'edit_dex_dialog.dart';
import 'widgets/home_dialogs.dart';
import 'widgets/home_ui_components.dart';

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
  String _searchQuery = '';
  String _currentSort = 'manual';
  late String _currentFolderId;

  bool get _isSelectionMode => _selectedItemIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.currentFolderId;
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
                _openDex(newestDex);
              },
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('open_dex'),
      );
    }
  }

  void _openDex(UserDex dex) {
    final provider = Provider.of<DexProvider>(context, listen: false);
    List<int> selectedOrder = provider.allAvailableDexes[dex.region] ?? [];
    Map<int, Pokemon> pokemonMap = {for (var p in provider.allPokemon) p.id: p};

    List<Pokemon> selectedDatabase = selectedOrder
        .map(
          (id) =>
              pokemonMap[id] ??
              Pokemon(
                id: id,
                nameDe: 'Unbekannt',
                nameEn: 'Unknown',
                hasGenderDifferences: false,
                genderRate: -1,
                captureRate: 255,
                evolutionChainId: -1,
                eggGroups: [],
                weight: 0.0,
                speed: 0,
                forms: [],
              ),
        )
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DexScreen(initialDex: dex, pokemonList: selectedDatabase),
      ),
    ).then((_) {
      if (mounted) _showTutorialIfNeeded();
    });
  }

  void _openCreateBottomSheet() {
    final provider = Provider.of<DexProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => HomeBottomSheetMenu(
        provider: provider,
        currentFolderId: _currentFolderId,
        onFolderCreate: () {
          Navigator.pop(ctx);
          HomeDialogs.showCreateFolderDialog(
            context,
            provider,
            _currentFolderId,
          );
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
    } catch (e) {
      debugPrint("Update Check failed: $e");
    }
  }

  void _clearSelection() => setState(() => _selectedItemIds.clear());

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
          if (_currentSort == 'caught') {
            return b.caughtIds.length.compareTo(a.caughtIds.length);
          }
          if (_currentSort == 'region') return a.region.compareTo(b.region);
        }
        if (a is DexFolder && b is DexFolder) return a.title.compareTo(b.title);
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
          FolderCard(
            key: ValueKey('${item.id}_${q}_$_isSelectionMode'),
            folder: item,
            isRootLevel: isRootLevel,
            index: index,
            isSelected: isSelected,
            isSelectionMode: _isSelectionMode,
            initiallyExpanded:
                !_isSelectionMode && q.isNotEmpty && hasMatchInChildren,
            showDragIndicator:
                isRootLevel &&
                _currentSort == 'manual' &&
                q.isEmpty &&
                !_isSelectionMode,
            onTap: (_isSelectionMode && isRootLevel)
                ? () {
                    setState(() {
                      isSelected
                          ? _selectedItemIds.remove(item.id)
                          : _selectedItemIds.add(item.id);
                    });
                  }
                : () {},
            onLongPress: isRootLevel
                ? () => setState(() => _selectedItemIds.add(item.id))
                : () {},
            onOpenFolder: () {
              setState(() {
                _currentFolderId = item.id;
                _searchQuery = '';
              });
            },
            onRename: () =>
                HomeDialogs.showRenameFolderDialog(context, provider, item),
            onMove: () => HomeDialogs.showMoveDialog(context, provider, {
              item.id,
            }, _clearSelection),
            onDelete: () =>
                HomeDialogs.confirmDeleteFolder(context, provider, item),
            childrenWidgets: _buildTree(provider, item.id, false),
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

        widgets.add(
          DexCard(
            key: _dexKeys[item.id],
            dex: item,
            regionName: regionName,
            isRootLevel: isRootLevel,
            index: index,
            isSelected: isSelected,
            isSelectionMode: _isSelectionMode,
            showDragIndicator:
                isRootLevel &&
                _currentSort == 'manual' &&
                q.isEmpty &&
                !_isSelectionMode,
            onTap: () {
              if (_isSelectionMode) {
                if (isRootLevel) {
                  setState(() {
                    isSelected
                        ? _selectedItemIds.remove(item.id)
                        : _selectedItemIds.add(item.id);
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
              _openDex(item);
            },
            onLongPress: isRootLevel
                ? () => setState(() => _selectedItemIds.add(item.id))
                : () {},
            onEdit: () {
              showDialog(
                context: context,
                builder: (_) => EditDexDialog(provider: provider, dex: item),
              );
            },
            onMove: () => HomeDialogs.showMoveDialog(context, provider, {
              item.id,
            }, _clearSelection),
            onDelete: () =>
                HomeDialogs.confirmDeleteDex(context, provider, item),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();

    if (!provider.isInitialized) {
      if (provider.isMigrating) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  Translator.get('migration_loading_text') !=
                          'migration_loading_text'
                      ? Translator.get('migration_loading_text')
                      : 'Daten werden für die neuste Version optimiert...\nBitte App nicht schließen.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return const Scaffold();
      }
    }

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
                          _currentFolderId = HomeDialogs.getParentId(
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
                  onPressed: () => HomeDialogs.showMoveDialog(
                    context,
                    provider,
                    _selectedItemIds,
                    _clearSelection,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.upload),
                  tooltip: 'Exportieren',
                  onPressed: () async {
                    try {
                      final dexesToExport = HomeDialogs.getDexesToExport(
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
                  onPressed: () => HomeDialogs.confirmMultipleDelete(
                    context,
                    provider,
                    _selectedItemIds,
                    _clearSelection,
                  ),
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
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
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
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
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
                          color: Theme.of(
                            context,
                          ).hintColor.withValues(alpha: 0.5),
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
