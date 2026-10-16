import 'package:flutter/material.dart';
import '../../models/user_dex.dart';
import '../../models/dex_view_models.dart';
import '../../l10n/app_translations.dart';
import '../../services/database_service.dart';
import '../../utils/dex_logic_helper.dart';
import 'box_content_edit_screen.dart';

class BoxEditScreen extends StatefulWidget {
  final UserDex dex;
  final List<BoxData> initialBoxes;

  const BoxEditScreen({
    super.key, 
    required this.dex,
    required this.initialBoxes,
  });

  @override
  State<BoxEditScreen> createState() => _BoxEditScreenState();
}

class _BoxEditScreenState extends State<BoxEditScreen> {
  bool _autoShift = true;
  bool _strictLimits = true;
  bool _patternAutoCreate = true;
  bool _autoDeleteEmpty = true;

  @override
  void initState() {
    super.initState();
    if (widget.dex.customBoxes.isEmpty && widget.initialBoxes.isNotEmpty) {
      int c = 0;
      widget.dex.customBoxes = widget.initialBoxes.map((b) => CustomBoxState(
        title: b.title,
        pokemonIds: b.entries.map((e) {
          if (e.uniqueId.isEmpty) return '';
          if (e.uniqueId.contains('__')) return e.uniqueId;
          final instanceId = '${e.uniqueId}__${DateTime.now().millisecondsSinceEpoch}_${c++}';
          if (widget.dex.caughtIds.contains(e.uniqueId) && !widget.dex.caughtIds.contains(instanceId)) {
            widget.dex.caughtIds.add(instanceId);
            DatabaseService.instance.savePokemonStatus(widget.dex.id, instanceId, isCaught: true);
          }
          if (widget.dex.shinyIds.contains(e.uniqueId) && !widget.dex.shinyIds.contains(instanceId)) {
            widget.dex.shinyIds.add(instanceId);
            DatabaseService.instance.savePokemonStatus(widget.dex.id, instanceId, isShiny: true);
          }
          if (widget.dex.alphaIds.contains(e.uniqueId) && !widget.dex.alphaIds.contains(instanceId)) {
            widget.dex.alphaIds.add(instanceId);
            DatabaseService.instance.savePokemonStatus(widget.dex.id, instanceId, isAlpha: true);
          }
          return instanceId;
        }).toList(),
        regionKey: b.regionKey,
        autoShift: _autoShift,
        strictLimits: _strictLimits,
        patternAutoCreate: _patternAutoCreate,
        autoDeleteEmpty: _autoDeleteEmpty,
      )).toList();
      DatabaseService.instance.saveUserDex(widget.dex);
    }

    if (widget.dex.customBoxes.isNotEmpty) {
      final first = widget.dex.customBoxes.first;
      _autoShift = first.autoShift;
      _strictLimits = first.strictLimits;
      _patternAutoCreate = first.patternAutoCreate;
      _autoDeleteEmpty = first.autoDeleteEmpty;
    }
  }

  void _updateSettings({
    bool? autoShift,
    bool? strictLimits,
    bool? patternAutoCreate,
    bool? autoDeleteEmpty,
  }) {
    setState(() {
      if (autoShift != null) {
        _autoShift = autoShift;
        for (var box in widget.dex.customBoxes) {
          box.autoShift = autoShift;
        }
      }
      if (strictLimits != null) {
        _strictLimits = strictLimits;
        for (var box in widget.dex.customBoxes) {
          box.strictLimits = strictLimits;
        }
      }
      if (patternAutoCreate != null) {
        _patternAutoCreate = patternAutoCreate;
        for (var box in widget.dex.customBoxes) {
          box.patternAutoCreate = patternAutoCreate;
        }
      }
      if (autoDeleteEmpty != null) {
        _autoDeleteEmpty = autoDeleteEmpty;
        for (var box in widget.dex.customBoxes) {
          box.autoDeleteEmpty = autoDeleteEmpty;
        }
      }
      DatabaseService.instance.saveUserDex(widget.dex);
    });
  }

  void _addBox() {
    showDialog(
      context: context,
      builder: (context) {
        String newName = '';
        return AlertDialog(
          title: Text(Translator.get('box_edit_add_box')),
          content: TextField(
            autofocus: true,
            onChanged: (val) => newName = val,
            decoration: InputDecoration(hintText: Translator.get('box_edit_rename_box')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Translator.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.isNotEmpty) {
                  setState(() {
                    widget.dex.customBoxes.add(CustomBoxState(
                      title: newName,
                      pokemonIds: [],
                      autoShift: _autoShift,
                      strictLimits: _strictLimits,
                      patternAutoCreate: _patternAutoCreate,
                      autoDeleteEmpty: _autoDeleteEmpty,
                    ));
                    DatabaseService.instance.saveUserDex(widget.dex);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(Translator.get('create')),
            ),
          ],
        );
      }
    );
  }

  void _renameBox(int index) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = widget.dex.customBoxes[index].title;
        return AlertDialog(
          title: Text(Translator.get('box_edit_rename_box')),
          content: TextField(
            autofocus: true,
            controller: TextEditingController(text: newName),
            onChanged: (val) => newName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Translator.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.isNotEmpty) {
                  setState(() {
                    widget.dex.customBoxes[index].title = newName;
                    DatabaseService.instance.saveUserDex(widget.dex);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(Translator.get('edit')),
            ),
          ],
        );
      }
    );
  }

  void _showGridSettingsDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        int currentCols = widget.dex.customBoxes[index].columns;
        int currentRows = widget.dex.customBoxes[index].rows;
        bool applyToAll = false;
        
        final colsController = TextEditingController(text: currentCols.toString());
        final rowsController = TextEditingController(text: currentRows.toString());

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(Translator.currentLanguage == 'de' ? 'Rastergröße ändern' : 'Change Grid Size'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: colsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: Translator.currentLanguage == 'de' ? 'Spalten' : 'Columns',
                          ),
                          onChanged: (val) {
                            int? parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) currentCols = parsed;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: rowsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: Translator.currentLanguage == 'de' ? 'Reihen' : 'Rows',
                          ),
                          onChanged: (val) {
                            int? parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) currentRows = parsed;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text(Translator.currentLanguage == 'de' ? 'Für alle Boxen übernehmen' : 'Apply to all boxes'),
                    value: applyToAll,
                    onChanged: (val) {
                      setDialogState(() => applyToAll = val ?? false);
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
                  onPressed: () {
                    setState(() {
                      if (applyToAll) {
                        for (var box in widget.dex.customBoxes) {
                          box.columns = currentCols;
                          box.rows = currentRows;
                        }
                      } else {
                        widget.dex.customBoxes[index].columns = currentCols;
                        widget.dex.customBoxes[index].rows = currentRows;
                      }
                      if (widget.dex.customBoxes.isNotEmpty && widget.dex.customBoxes.first.autoFlow) {
                        DexLogicHelper.enforceAutoFlow(widget.dex);
                      }
                      DatabaseService.instance.saveUserDex(widget.dex);
                    });
                    Navigator.pop(context);
                  },
                  child: Text(Translator.get('save', fallback: 'Speichern')),
                ),
              ],
            );
          },
        );
      }
    );
  }

  void _deleteBox(int index) {
    setState(() {
      widget.dex.customBoxes.removeAt(index); DatabaseService.instance.saveUserDex(widget.dex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translator.get('box_edit_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Auf Standard zurücksetzen',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Boxen zurücksetzen?'),
                  content: const Text('Möchtest du alle deine benutzerdefinierten Boxen löschen und das Layout auf den Standard-Pokédex zurücksetzen? Deine gefangenen Pokémon bleiben dabei erhalten!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(Translator.get('cancel')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        setState(() {
                          widget.dex.customBoxes.clear();
                          DatabaseService.instance.saveUserDex(widget.dex);
                        });
                        Navigator.pop(ctx); // Close dialog
                        Navigator.pop(context); // Go back to dex screen to trigger recalculation
                      },
                      child: const Text('Zurücksetzen', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        header: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 20, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get('box_edit_settings_header'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                dense: true,
                title: Text(Translator.get('box_edit_auto_shift_title')),
                subtitle: Text(Translator.get('box_edit_auto_shift_subtitle')),
                value: _autoShift,
                onChanged: (val) => _updateSettings(autoShift: val),
              ),
              SwitchListTile(
                dense: true,
                title: Text(Translator.get('box_edit_strict_limits_title')),
                subtitle: Text(Translator.get('box_edit_strict_limits_subtitle')),
                value: _strictLimits,
                onChanged: (val) => _updateSettings(strictLimits: val),
              ),
              SwitchListTile(
                dense: true,
                title: Text(Translator.get('box_edit_pattern_auto_create_title')),
                subtitle: Text(Translator.get('box_edit_pattern_auto_create_subtitle')),
                value: _patternAutoCreate,
                onChanged: (val) => _updateSettings(patternAutoCreate: val),
              ),
              SwitchListTile(
                dense: true,
                title: Text(Translator.get('box_edit_auto_delete_empty_title')),
                subtitle: Text(Translator.get('box_edit_auto_delete_empty_subtitle')),
                value: _autoDeleteEmpty,
                onChanged: (val) => _updateSettings(autoDeleteEmpty: val),
              ),
            ],
          ),
        ),
        itemCount: widget.dex.customBoxes.length,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = widget.dex.customBoxes.removeAt(oldIndex);
            widget.dex.customBoxes.insert(newIndex, item);
            DatabaseService.instance.saveUserDex(widget.dex);
          });
        },
        itemBuilder: (context, index) {
          final box = widget.dex.customBoxes[index];
          return Card(
            key: ValueKey('box_${index}_${box.title}'),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: () {
                final allAvailable = widget.initialBoxes
                    .expand((b) => b.entries)
                    .where((e) => e.uniqueId.isNotEmpty)
                    .toList();
                // Remove duplicates if any
                final uniqueEntries = <String, DexDisplayEntry>{};
                for (var e in allAvailable) {
                  uniqueEntries[e.uniqueId] = e;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => BoxContentEditScreen(
                      dex: widget.dex,
                      boxIndex: index,
                      allAvailableEntries: uniqueEntries.values.toList(),
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.drag_indicator, color: Colors.grey),
              title: Text(box.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${box.pokemonIds.length} Pokémon'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.grid_view, size: 20),
                    onPressed: () => _showGridSettingsDialog(index),
                    tooltip: Translator.currentLanguage == 'de' ? 'Spaltenanzahl ändern' : 'Change Grid Columns',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _renameBox(index),
                    tooltip: Translator.get('box_edit_rename_box'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    onPressed: () => _deleteBox(index),
                    tooltip: Translator.get('box_edit_delete_box'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBox,
        tooltip: Translator.get('box_edit_add_box'),
        child: const Icon(Icons.add),
      ),
    );
  }
}





