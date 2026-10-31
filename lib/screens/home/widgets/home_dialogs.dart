import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../models/tutorial_step.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/notification_helper.dart';

class HomeDialogs {
  static String getParentId(DexProvider provider, String id) {
    for (var entry in provider.structure.entries) {
      if (entry.value.contains(id)) return entry.key;
    }
    return 'root';
  }

  static void recursiveDelete(DexProvider provider, String itemId) {
    if (itemId.startsWith('folder_')) {
      final children = List<String>.from(provider.structure[itemId] ?? []);
      for (var child in children) {
        recursiveDelete(provider, child);
      }
      provider.deleteFolder(itemId, true);
    } else {
      provider.deleteDex(itemId);
    }
  }

  static List<UserDex> getDexesToExport(
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

  static Future<void> showCreateFolderDialog(
    BuildContext context,
    DexProvider provider,
    String currentFolderId,
  ) async {
    final TextEditingController ctrl = TextEditingController();
    final GlobalKey okKey = GlobalKey();
    await showDialog(
      context: context,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          TutorialProvider? tut;
          try {
            tut = Provider.of<TutorialProvider>(context, listen: false);
          } catch (_) {}
          if (tut != null && !tut.hasSeenFeature('create_folder_dialog')) {
            TutorialOverlay.show(
              ctx,
              TutorialFeature(
                id: 'create_folder_dialog',
                nameKey: 'tutorial_folder_dialog_title',
                steps: [
                  TutorialStep(
                    targetKey: okKey,
                    titleKey: 'tutorial_folder_dialog_title',
                    textKey: 'tutorial_folder_dialog_text',
                  ),
                ],
              ),
              () => tut?.markFeatureAsSeen('create_folder_dialog'),
            );
          }
        });
        return AlertDialog(
          title: const Text('Neuer Ordner'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Ordnername'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              key: okKey,
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  try {
                    provider.createFolder(ctrl.text, currentFolderId);
                    Navigator.pop(ctx);
                  } catch (e) {
                    Navigator.pop(ctx);
                    NotificationHelper.showError('${t.error} $e');
                  }
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showRenameFolderDialog(
    BuildContext context,
    DexProvider provider,
    DexFolder folder,
  ) {
    final TextEditingController ctrl = TextEditingController(
      text: folder.title,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ordner umbenennen'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                try {
                  provider.renameFolder(folder.id, ctrl.text);
                  Navigator.pop(ctx);
                } catch (e) {
                  Navigator.pop(ctx);
                  NotificationHelper.showError('${t.error} $e');
                }
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showMoveDialog(
    BuildContext context,
    DexProvider provider,
    Set<String> itemIds,
    VoidCallback clearSelection,
  ) {
    Set<String>? commonAllowed;
    for (String itemId in itemIds) {
      String currentParentId = getParentId(provider, itemId);
      Set<String> allowed = {'root'};
      if (currentParentId != 'root') {
        allowed.add(getParentId(provider, currentParentId));
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
                      clearSelection();
                      Navigator.pop(ctx);
                      NotificationHelper.showSuccess('Erfolgreich verschoben.');
                    } catch (e) {
                      Navigator.pop(ctx);
                      NotificationHelper.showError(
                        '${t.error_move_item} $e',
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
              child: Text(t.cancel),
            ),
          ],
        );
      },
    );
  }

  static void confirmDeleteDex(
    BuildContext context,
    DexProvider provider,
    UserDex dex,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          t.dex_delete_title,
        ),
        content: Text(
          t.dex_delete_text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
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
                  '${t.error_delete_dex} $e',
                );
              }
            },
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }

  static void confirmDeleteFolder(
    BuildContext context,
    DexProvider provider,
    DexFolder folder,
  ) {
    bool doRecursiveDelete = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(
              t.delete_folder_title,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.delete_folder_text,
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
                  value: doRecursiveDelete,
                  onChanged: (val) {
                    setStateSB(() => doRecursiveDelete = val ?? false);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  try {
                    if (doRecursiveDelete) {
                      HomeDialogs.recursiveDelete(provider, folder.id);
                    } else {
                      provider.deleteFolder(folder.id, false);
                    }
                    Navigator.pop(context);
                    NotificationHelper.showSuccess('Erfolgreich gelöscht.');
                  } catch (e) {
                    Navigator.pop(context);
                    NotificationHelper.showError(
                      '${t.error_delete_folder} $e',
                    );
                  }
                },
                child: Text(t.delete),
              ),
            ],
          );
        },
      ),
    );
  }

  static void confirmMultipleDelete(
    BuildContext context,
    DexProvider provider,
    Set<String> selectedItemIds,
    VoidCallback clearSelection,
  ) {
    bool hasFolder = selectedItemIds.any((id) => id.startsWith('folder_'));
    bool doRecursiveDelete = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(t.delete_multiple_confirm_title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.delete_multiple_confirm_text),
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
                    value: doRecursiveDelete,
                    onChanged: (val) {
                      setStateSB(() => doRecursiveDelete = val ?? false);
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  try {
                    for (String id in selectedItemIds) {
                      if (id.startsWith('folder_')) {
                        if (doRecursiveDelete) {
                          HomeDialogs.recursiveDelete(provider, id);
                        } else {
                          provider.deleteFolder(id, false);
                        }
                      } else {
                        provider.deleteDex(id);
                      }
                    }
                    clearSelection();
                    Navigator.pop(context);
                    NotificationHelper.showSuccess('Elemente gelöscht.');
                  } catch (e) {
                    Navigator.pop(context);
                    NotificationHelper.showError(
                      '${t.error} $e',
                    );
                  }
                },
                child: Text(t.delete),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showSearchHelpDialog(BuildContext context) {
    Widget helpItem(String title, String desc) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            children: [
              TextSpan(
                text: '$title\n',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          t.search_help_title,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              helpItem(
                '15 / #15',
                t.search_help_id,
              ),
              helpItem(
                '1-151',
                t.search_help_range,
              ),
              helpItem(
                'shiny, caught, missing',
                t.search_help_status,
              ),
              helpItem(
                'kanto, alola, mega',
                t.search_help_forms,
              ),
              helpItem(
                '+Bisasam',
                t.search_help_family,
              ),
              helpItem(
                'Pika* / *chu',
                t.search_help_wildcard,
              ),
              helpItem(
                'shiny & kanto',
                t.search_help_and,
              ),
              helpItem(
                '1-9, Evoli',
                t.search_help_or,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
