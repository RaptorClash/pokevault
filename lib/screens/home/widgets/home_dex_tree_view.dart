import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../utils/dex_logic_helper.dart';
import '../../../i18n/strings.g.dart';
import '../../dex/widgets/dex_completion_card_dialog.dart';
import '../edit_dex_dialog.dart';
import 'home_dialogs.dart';
import 'home_ui_components.dart';

/// Renders the tree view of folders and Dexes on the Home screen with
/// drag-and-drop reordering, folder recursion, and search filtering.
class HomeDexTreeView extends StatelessWidget {
  final String currentFolderId;
  final String searchQuery;
  final String currentSort;
  final Set<String> selectedItemIds;
  final Map<String, GlobalKey>? dexKeys;
  final ValueChanged<UserDex> onOpenDex;
  final ValueChanged<DexFolder> onOpenFolder;
  final ValueChanged<String> onToggleSelect;
  final VoidCallback? onClearSelection;
  final VoidCallback? onCreateDexPressed;

  const HomeDexTreeView({
    super.key,
    required this.currentFolderId,
    required this.searchQuery,
    required this.currentSort,
    required this.selectedItemIds,
    this.dexKeys,
    required this.onOpenDex,
    required this.onOpenFolder,
    required this.onToggleSelect,
    this.onClearSelection,
    this.onCreateDexPressed,
  });

  bool get isSelectionMode => selectedItemIds.isNotEmpty;

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
          String regionName = (t['region_${d.region}'] ?? d.region).toLowerCase();
          if (d.title.toLowerCase().contains(query) ||
              regionName.contains(query)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<dynamic> getSortedItems(DexProvider provider, String folderId) {
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

    if (currentSort != 'manual') {
      items.sort((a, b) {
        if (a is DexFolder && b is UserDex) return -1;
        if (a is UserDex && b is DexFolder) return 1;
        if (a is UserDex && b is UserDex) {
          if (currentSort == 'az') return a.title.compareTo(b.title);
          if (currentSort == 'caught') {
            return DexLogicHelper.getCaughtCount(b).compareTo(DexLogicHelper.getCaughtCount(a));
          }
          if (currentSort == 'region') return a.region.compareTo(b.region);
        }
        if (a is DexFolder && b is DexFolder) return a.title.compareTo(b.title);
        return 0;
      });
    }

    return items;
  }

  List<Widget> _buildTree(
    BuildContext context,
    DexProvider provider,
    String parentId,
    bool isRootLevel,
  ) {
    final items = getSortedItems(provider, parentId);
    List<Widget> widgets = [];
    final q = searchQuery.toLowerCase();

    for (int index = 0; index < items.length; index++) {
      final item = items[index];

      if (item is DexFolder) {
        bool matchesSearch = item.title.toLowerCase().contains(q);
        bool hasMatchInChildren = _folderHasMatch(provider, item.id, q);

        if (q.isNotEmpty && !matchesSearch && !hasMatchInChildren) continue;

        bool isSelected = isRootLevel && selectedItemIds.contains(item.id);

        widgets.add(
          FolderCard(
            key: ValueKey(item.id),
            folder: item,
            isRootLevel: isRootLevel,
            index: index,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            initiallyExpanded:
                !isSelectionMode && q.isNotEmpty && hasMatchInChildren,
            showDragIndicator:
                isRootLevel &&
                currentSort == 'manual' &&
                q.isEmpty &&
                !isSelectionMode,
            onTap: (isSelectionMode && isRootLevel)
                ? () => onToggleSelect(item.id)
                : null,
            onLongPress: isRootLevel
                ? () => onToggleSelect(item.id)
                : () {},
            onOpenFolder: () => onOpenFolder(item),
            onRename: () =>
                HomeDialogs.showRenameFolderDialog(context, provider, item),
            onMove: () => HomeDialogs.showMoveDialog(
              context,
              provider,
              {item.id},
              onClearSelection ?? () {},
            ),
            onDelete: () =>
                HomeDialogs.confirmDeleteFolder(context, provider, item),
            childrenWidgets: _buildTree(context, provider, item.id, false),
          ),
        );
      } else if (item is UserDex) {
        String regionName = (t['region_${item.region}'] ?? item.region);
        bool matchesSearch =
            item.title.toLowerCase().contains(q) ||
            regionName.toLowerCase().contains(q);

        if (q.isNotEmpty && !matchesSearch) continue;

        bool isSelected = isRootLevel && selectedItemIds.contains(item.id);

        final tutorialKey = dexKeys?[item.id];

        widgets.add(
          DexCard(
            key: ValueKey(item.id),
            tutorialTargetKey: tutorialKey,
            dex: item,
            regionName: regionName,
            isRootLevel: isRootLevel,
            index: index,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            showDragIndicator:
                isRootLevel &&
                currentSort == 'manual' &&
                q.isEmpty &&
                !isSelectionMode,
            onTap: () {
              if (isSelectionMode) {
                if (isRootLevel) {
                  onToggleSelect(item.id);
                }
                return;
              }
              try {
                final tutProvider = Provider.of<TutorialProvider>(
                  context,
                  listen: false,
                );
                if (!tutProvider.hasSeenFeature('open_dex')) {
                  tutProvider.markFeatureAsSeen('open_dex');
                }
              } catch (_) {}
              onOpenDex(item);
            },
            onLongPress: isRootLevel
                ? () => onToggleSelect(item.id)
                : () {},
            onEdit: () {
              showDialog(
                context: context,
                builder: (_) => EditDexDialog(provider: provider, dex: item),
              );
            },
            onMove: () => HomeDialogs.showMoveDialog(
              context,
              provider,
              {item.id},
              onClearSelection ?? () {},
            ),
            onDelete: () =>
                HomeDialogs.confirmDeleteDex(context, provider, item),
            onShareCard: () =>
                DexCompletionCardDialog.show(context, liveDex: item),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final items = getSortedItems(provider, currentFolderId);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.catching_pokemon,
              size: 64,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? t.no_dex
                  : 'Keine Ergebnisse gefunden',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (currentSort == 'manual' && searchQuery.isEmpty && !isSelectionMode) {
      return ReorderableListView(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        onReorderItem: (oldIndex, newIndex) {
          if (oldIndex < 0 ||
              oldIndex >= items.length ||
              newIndex < 0 ||
              newIndex >= items.length) {
            return;
          }
          final oldItem = items[oldIndex];
          final newItem = items[newIndex];
          final list = provider.structure[currentFolderId];
          if (list != null) {
            final realOld = list.indexOf(oldItem.id);
            final realNew = list.indexOf(newItem.id);
            if (realOld != -1 && realNew != -1) {
              provider.reorderItem(
                currentFolderId,
                realOld,
                realNew,
              );
            }
          }
        },
        children: _buildTree(context, provider, currentFolderId, true),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        bottom: 80,
        left: 16,
        right: 16,
      ),
      children: _buildTree(context, provider, currentFolderId, true),
    );
  }
}
