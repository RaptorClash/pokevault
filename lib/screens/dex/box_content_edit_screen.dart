import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_dex.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../utils/dex_logic_helper.dart';
import '../../i18n/strings.g.dart';
import '../../services/database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pokemon_search_selection.dart';
import '../../utils/box_sequence_manager.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../providers/tutorial_provider.dart';

class SlotData {
  final String keyId;
  String pokemonId;
  SlotData(this.keyId, this.pokemonId);
}

class BoxContentEditScreen extends StatefulWidget {
  final UserDex dex;
  final int boxIndex;
  final List<DexDisplayEntry> allAvailableEntries;

  const BoxContentEditScreen({
    super.key,
    required this.dex,
    required this.boxIndex,
    required this.allAvailableEntries,
  });

  @override
  State<BoxContentEditScreen> createState() => _BoxContentEditScreenState();
}

class _BoxContentEditScreenState extends State<BoxContentEditScreen> {
  late List<SlotData> _slots;
  late int _capacity;

  @override
  void initState() {
    super.initState();
    _initList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TutorialProvider? tut;
      try {
        tut = Provider.of<TutorialProvider>(context, listen: false);
      } catch (_) {}
      if (tut != null && !tut.hasSeenFeature('box_content_edit')) {
        TutorialOverlay.show(
          context,
          TutorialFeature(
            id: 'box_content_edit',
            nameKey: 'tutorial_box_content_intro_title',
            steps: [
              TutorialStep(
                targetKey: null,
                titleKey: 'tutorial_box_content_intro_title',
                textKey: 'tutorial_box_content_intro_text',
              ),
            ],
          ),
          () => tut?.markFeatureAsSeen('box_content_edit'),
        );
      }
    });
  }

  void _initList() {
    final box = widget.dex.customBoxes[widget.boxIndex];
    _capacity = box.columns * box.rows;
    _slots = [];
    for (int i = 0; i < _capacity; i++) {
      String pid = i < box.pokemonIds.length ? box.pokemonIds[i] : '';
      _slots.add(SlotData(UniqueKey().toString(), pid));
    }
  }

  void _saveData() {
    widget.dex.customBoxes[widget.boxIndex].pokemonIds = _slots.map((s) => s.pokemonId).toList();
    try {
      context.read<DexProvider>().saveUserDexAndSync(widget.dex);
    } on ProviderNotFoundException {
      DatabaseService.instance.saveUserDex(widget.dex);
    }
  }

  Future<void> _pickPokemon(int index) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => PokemonSearchSelectionScreen(
          allAvailableEntries: widget.allAvailableEntries,
          dexId: widget.dex.id,
          initialShiny: widget.dex.isShinyDex,
        ),
      ),
    );

    if (result != null) {
      if (result == 'placeholder') {
        _insertPlaceholder(index);
        return;
      }
      setState(() {
        final isShinySelection = result.startsWith('shiny:');
        final baseId = DexLogicHelper.getBaseId(result);
        DexLogicHelper.ensurePrimaryInstancePersisted(widget.dex, baseId);
        final instanceId = '${baseId}__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}_$index';
        _slots[index].pokemonId = instanceId;
        if (isShinySelection && !widget.dex.shinyIds.contains(instanceId)) {
          widget.dex.shinyIds.add(instanceId);
          DatabaseService.instance.savePokemonStatus(widget.dex.id, instanceId, isShiny: true);
        } else if (!isShinySelection) {
          widget.dex.shinyIds.remove(instanceId);
          DatabaseService.instance.savePokemonStatus(widget.dex.id, instanceId, isShiny: false);
        }
        _saveData();
      });
    }
  }

  void _insertPlaceholder([int? index]) {
    int targetIndex = index ?? _slots.indexWhere((s) => s.pokemonId.isEmpty);
    if (targetIndex == -1) {
      targetIndex = 0;
    }
    setState(() {
      final instanceId = 'placeholder__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}_$targetIndex';
      _slots[targetIndex].pokemonId = instanceId;
      _saveData();
    });
  }

  void _clearSlot(int index) {
    if (widget.boxIndex < 0 || widget.boxIndex >= widget.dex.customBoxes.length) return;
    if (index < 0 || index >= _slots.length) return;
    if (_slots[index].pokemonId.isEmpty) return;

    final targetBox = widget.dex.customBoxes[widget.boxIndex];

    // Synchronize box pokemonIds with current _slots before removing
    targetBox.pokemonIds = _slots.map((s) => s.pokemonId).toList();

    BoxSequenceManager.removeWithShiftBack(
      dex: widget.dex,
      boxIndex: widget.boxIndex,
      slotIndex: index,
    );

    try {
      context.read<DexProvider>().saveUserDexAndSync(widget.dex);
    } on ProviderNotFoundException {
      DatabaseService.instance.saveUserDex(widget.dex);
    }

    // If targetBox was deleted by empty box cleanup, exit the content edit screen
    if (!widget.dex.customBoxes.contains(targetBox)) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _initList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.boxIndex < 0 || widget.boxIndex >= widget.dex.customBoxes.length) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final box = widget.dex.customBoxes[widget.boxIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(box.title),
        actions: [
          IconButton(
            key: const Key('box_content_insert_placeholder'),
            icon: const Icon(Icons.crop_free),
            tooltip: t.insert_placeholder,
            onPressed: () => _insertPlaceholder(),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _slots.length,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = _slots.removeAt(oldIndex);
            _slots.insert(newIndex, item);
            _saveData();
          });
        },
        itemBuilder: (context, index) {
          final slot = _slots[index];
          final id = slot.pokemonId;
          final isEmpty = id.isEmpty;
          
          DexDisplayEntry? entry;
          if (!isEmpty) {
            if (DexLogicHelper.isPlaceholder(id)) {
              entry = DexDisplayEntry.placeholderEntry(id);
            } else {
              final baseId = DexLogicHelper.getBaseId(id);
              for (final e in widget.allAvailableEntries) {
                if (e.uniqueId == id) {
                  entry = e;
                  break;
                }
              }
              if (entry == null) {
                for (final e in widget.allAvailableEntries) {
                  final entryBaseId = DexLogicHelper.getBaseId(e.uniqueId);
                  if (entryBaseId == baseId) {
                    entry = e;
                    break;
                  }
                }
              }
            }
          }

          return ListTile(
            key: ValueKey(slot.keyId),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle, color: Colors.grey),
                const SizedBox(width: 8),
                if (entry != null && !entry.isPlaceholder)
                  CachedNetworkImage(
                    imageUrl: entry.imageUrl,
                    width: 40,
                    height: 40,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                else if (entry != null && entry.isPlaceholder)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(Icons.crop_free, color: Colors.amberAccent, size: 20),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white54),
                  ),
              ],
            ),
            title: Text(
              entry != null 
                  ? (entry.isPlaceholder
                      ? t.placeholder
                      : (LocaleSettings.currentLocale == AppLocale.en ? entry.pokemon.nameEn : entry.pokemon.nameDe))
                  : t.box_edit_empty_slot,
              style: TextStyle(
                color: entry != null ? Colors.white : Colors.white54,
              ),
            ),
            subtitle: entry != null 
                ? Text(
                    entry.isPlaceholder
                        ? t.placeholder_desc
                        : (entry.displaySuffix.isNotEmpty ? '#${entry.pokemon.id} ${entry.displaySuffix}' : '#${entry.pokemon.id}'),
                  )
                : null,
            trailing: entry != null
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.redAccent),
                    onPressed: () => _clearSlot(index),
                    tooltip: t.box_edit_remove,
                  )
                : null,
            onTap: () => _pickPokemon(index),
          );
        },
      ),
    );
  }
}
