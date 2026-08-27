import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../models/tutorial_step.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';
import '../../../utils/notification_helper.dart';
import '../create_dex_bottom_sheet.dart';

class FolderCard extends StatelessWidget {
  final DexFolder folder;
  final bool isRootLevel;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final bool initiallyExpanded;
  final bool showDragIndicator;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onOpenFolder;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final List<Widget> childrenWidgets;

  const FolderCard({
    super.key,
    required this.folder,
    required this.isRootLevel,
    required this.index,
    required this.isSelected,
    required this.isSelectionMode,
    required this.initiallyExpanded,
    required this.showDragIndicator,
    required this.onTap,
    required this.onLongPress,
    required this.onOpenFolder,
    required this.onRename,
    required this.onMove,
    required this.onDelete,
    required this.childrenWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
        onLongPress: onLongPress,
        onTap: onTap,
        child: IgnorePointer(
          ignoring: isSelectionMode,
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            leading: IconButton(
              icon: const Icon(
                Icons.folder,
                color: Colors.blueAccent,
                size: 28,
              ),
              onPressed: onOpenFolder,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    folder.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'rename') onRename();
                    if (val == 'move') onMove();
                    if (val == 'delete') onDelete();
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
                if (showDragIndicator)
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
                child: Column(children: childrenWidgets),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DexCard extends StatelessWidget {
  final UserDex dex;
  final String regionName;
  final bool isRootLevel;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final bool showDragIndicator;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const DexCard({
    super.key,
    required this.dex,
    required this.regionName,
    required this.isRootLevel,
    required this.index,
    required this.isSelected,
    required this.isSelectionMode,
    required this.showDragIndicator,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
        onLongPress: onLongPress,
        onTap: onTap,
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.red,
            child: Icon(Icons.catching_pokemon, color: Colors.white),
          ),
          title: Text(
            dex.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${Translator.get('region')}: $regionName | ${Translator.get('caught')}: ${dex.caughtIds.length}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'move') onMove();
                  if (value == 'delete') onDelete();
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
                        Text('Löschen', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              if (showDragIndicator)
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    color: Colors.transparent,
                    child: const Icon(Icons.drag_indicator, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeBottomSheetMenu extends StatefulWidget {
  final DexProvider provider;
  final String currentFolderId;
  final VoidCallback onFolderCreate;

  const HomeBottomSheetMenu({
    super.key,
    required this.provider,
    required this.currentFolderId,
    required this.onFolderCreate,
  });

  @override
  State<HomeBottomSheetMenu> createState() => _HomeBottomSheetMenuState();
}

class _HomeBottomSheetMenuState extends State<HomeBottomSheetMenu> {
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
