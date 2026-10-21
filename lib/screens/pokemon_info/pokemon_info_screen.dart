import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dex_view_models.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../l10n/app_translations.dart';
import 'utils/pokemon_info_keys.dart';
import 'dialogs/ignore_pokemon_dialog.dart';
import 'widgets/pokemon_info_page.dart';
import '../../utils/box_sequence_manager.dart';

class PokemonInfoScreen extends StatefulWidget {
  final List<DexDisplayEntry> entries;
  final int initialIndex;
  final String dexId;
  final List<BoxData>? boxes;
  final bool isBoxView;
  final ValueChanged<int>? onPageChanged;
  final String? selectionActionLabel;
  final ValueChanged<String>? onSelectionAction;
  final bool? initialShiny;

  const PokemonInfoScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.dexId,
    this.boxes,
    this.isBoxView = false,
    this.onPageChanged,
    this.selectionActionLabel,
    this.onSelectionAction,
    this.initialShiny,
  });

  @override
  State<PokemonInfoScreen> createState() => _PokemonInfoScreenState();
}

class _PokemonInfoScreenState extends State<PokemonInfoScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool? _manualShinyToggle;

  final PokemonInfoKeys _keys = PokemonInfoKeys();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _manualShinyToggle = widget.initialShiny;
    _pageController = PageController(initialPage: widget.initialIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  void _showTutorialIfNeeded() {
    if (widget.entries.isEmpty) return;

    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    final currentId = widget.entries[_currentIndex].uniqueId;

    if (!tutProvider.hasSeenFeature('pokemon_details')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'pokemon_details',
          nameKey: 'tutorial_feature_details',
          steps: _buildTutorialSteps(currentId),
        ),
        () => tutProvider.markFeatureAsSeen('pokemon_details'),
      );
    }
  }

  List<TutorialStep> _buildTutorialSteps(String currentId) {
    return [
      TutorialStep(
        targetKey: _keys.appBarKey,
        titleKey: 'tutorial_info_appbar_title',
        textKey: 'tutorial_info_appbar_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.shinyToggle, currentId),
        titleKey: 'tutorial_info_shiny_toggle_title',
        textKey: 'tutorial_info_shiny_toggle_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.basicInfo, currentId),
        titleKey: 'tutorial_info_basic_title',
        textKey: 'tutorial_info_basic_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.caughtStatus, currentId),
        titleKey: 'tutorial_info_caught_title',
        textKey: 'tutorial_info_caught_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.shinyStatus, currentId),
        titleKey: 'tutorial_info_shiny_title',
        textKey: 'tutorial_info_shiny_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.alphaToggle, currentId),
        titleKey: 'tutorial_info_alpha_title',
        textKey: 'tutorial_info_alpha_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.breeding, currentId),
        titleKey: 'tutorial_info_breeding_title',
        textKey: 'tutorial_info_breeding_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.catchCalc, currentId),
        titleKey: 'tutorial_info_catchcalc_title',
        textKey: 'tutorial_info_catchcalc_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.matchingBalls, currentId),
        titleKey: 'tutorial_info_matchingballs_title',
        textKey: 'tutorial_info_matchingballs_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.language, currentId),
        titleKey: 'tutorial_info_language_title',
        textKey: 'tutorial_info_language_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.tera, currentId),
        titleKey: 'tutorial_info_tera_title',
        textKey: 'tutorial_info_tera_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.ribbons, currentId),
        titleKey: 'tutorial_info_ribbons_title',
        textKey: 'tutorial_info_ribbons_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.marks, currentId),
        titleKey: 'tutorial_info_marks_title',
        textKey: 'tutorial_info_marks_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.encounters, currentId),
        titleKey: 'tutorial_info_encounters_title',
        textKey: 'tutorial_info_encounters_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.shinyGuide, currentId),
        titleKey: 'tutorial_info_shinyguide_title',
        textKey: 'tutorial_info_shinyguide_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: _keys.get(_keys.ignoreBtn, currentId),
        titleKey: 'tutorial_info_ignore_title',
        textKey: 'tutorial_info_ignore_text',
        requireTargetTap: true,
        onTargetTap: () {
          IgnorePokemonDialog.show(
            context,
            provider: context.read<DexProvider>(),
            entry: widget.entries[_currentIndex],
            dexId: widget.dexId,
            showTutorial: true,
          );
        },
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? boxTitle;
    int indexInBox = 0;
    int boxTotal = 0;

    if (widget.isBoxView && widget.boxes != null) {
      final currentEntry = widget.entries[_currentIndex];
      try {
        final box = widget.boxes!.firstWhere(
          (b) => b.entries.contains(currentEntry),
        );
        boxTitle = box.title;
        indexInBox = box.entries.indexOf(currentEntry) + 1;
        boxTotal = box.entries.length;
      } catch (_) {}
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          key: _keys.appBarKey,
          child: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translator.get('extra_info', fallback: 'Zusatzinformationen'),
                  style: TextStyle(fontSize: boxTitle != null ? 16 : 20),
                ),
                if (boxTitle != null)
                  Text(
                    '$boxTitle - $indexInBox / $boxTotal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color:
                          Theme.of(context).textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7) ??
                          Colors.white70,
                    ),
                  ),
              ],
            ),
            leading: const CloseButton(),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.entries.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        findChildIndexCallback: (Key key) {
          if (key is ValueKey<String>) {
            final int idx =
                widget.entries.indexWhere((e) => e.uniqueId == key.value);
            return idx != -1 ? idx : null;
          }
          return null;
        },
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _manualShinyToggle = widget.initialShiny;
          });
          final start = (index - 2).clamp(0, widget.entries.length);
          final end = (index + 3).clamp(0, widget.entries.length);
          final activeIds = widget.entries.sublist(start, end).map((e) => e.uniqueId).toSet();
          _keys.prune(activeIds);
          if (widget.onPageChanged != null) widget.onPageChanged!(index);
        },
        itemCount: widget.entries.length,
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          final id = entry.uniqueId;

          return PokemonInfoPage(
            key: ValueKey(id),
            entry: entry,
            dexId: widget.dexId,
            selectionActionLabel: widget.selectionActionLabel,
            onSelectionAction: widget.onSelectionAction,
            manualShinyToggle: _manualShinyToggle,
            onShinyToggled: () => setState(
              () => _manualShinyToggle = !(_manualShinyToggle ?? false),
            ),
            onIgnore: () {
              bool isCustomBoxes = false;
              int? bIndex;
              int? iIndex;
              
              final provider = context.read<DexProvider>();
              final liveDex = provider.userDexes.firstWhere(
                (d) => d.id == widget.dexId,
                orElse: () => UserDex.fallback(widget.dexId),
              );
              
              if (widget.isBoxView && widget.boxes != null && liveDex.customBoxes.isNotEmpty) {
                 isCustomBoxes = true;
                 int count = 0;
                 for (int b = 0; b < widget.boxes!.length; b++) {
                   final box = widget.boxes![b];
                   if (_currentIndex < count + box.entries.length) {
                     bIndex = b;
                     iIndex = _currentIndex - count;
                     break;
                   }
                   count += box.entries.length;
                 }
              }

              if (isCustomBoxes && bIndex != null && iIndex != null) {
                int targetBoxIndex = bIndex;
                int targetSlotIndex = iIndex;

                // Verify exact slot matching entry.uniqueId (handles filtered search lists)
                if (targetBoxIndex >= liveDex.customBoxes.length ||
                    targetSlotIndex >= liveDex.customBoxes[targetBoxIndex].pokemonIds.length ||
                    liveDex.customBoxes[targetBoxIndex].pokemonIds[targetSlotIndex] != entry.uniqueId) {
                  for (int b = 0; b < liveDex.customBoxes.length; b++) {
                    final s = liveDex.customBoxes[b].pokemonIds.indexOf(entry.uniqueId);
                    if (s != -1) {
                      targetBoxIndex = b;
                      targetSlotIndex = s;
                      break;
                    }
                  }
                }

                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(Translator.get('remove_from_box_title', fallback: 'Pokémon entfernen')),
                    content: Text(Translator.get('remove_from_box_desc', fallback: 'Möchtest du dieses Pokémon nur aus dieser Box entfernen oder komplett aus dem Pokédex ausblenden?')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(Translator.get('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          if (targetBoxIndex < liveDex.customBoxes.length &&
                              targetSlotIndex < liveDex.customBoxes[targetBoxIndex].pokemonIds.length) {
                            BoxSequenceManager.removeWithShiftBack(
                              dex: liveDex,
                              boxIndex: targetBoxIndex,
                              slotIndex: targetSlotIndex,
                            );
                            provider.saveUserDexAndSync(liveDex);
                            provider.forceRefresh();
                          }
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Text(Translator.get('remove_from_box_only', fallback: 'Nur aus Box')),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          provider.ignorePokemon(widget.dexId, entry.uniqueId);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Text(Translator.get('ignore_pokemon', fallback: 'Komplett ausblenden')),
                      ),
                    ],
                  ),
                );
              } else {
                IgnorePokemonDialog.show(
                  context,
                  provider: provider,
                  entry: entry,
                  dexId: widget.dexId,
                );
              }
            },
            shinyToggleKey: _keys.get(_keys.shinyToggle, id),
            alphaToggleKey: _keys.get(_keys.alphaToggle, id),
            basicInfoKey: _keys.get(_keys.basicInfo, id),
            caughtStatusKey: _keys.get(_keys.caughtStatus, id),
            shinyStatusKey: _keys.get(_keys.shinyStatus, id),
            breedingKey: _keys.get(_keys.breeding, id),
            catchCalcKey: _keys.get(_keys.catchCalc, id),
            matchingBallsKey: _keys.get(_keys.matchingBalls, id),
            languageKey: _keys.get(_keys.language, id),
            teraKey: _keys.get(_keys.tera, id),
            ribbonsKey: _keys.get(_keys.ribbons, id),
            marksKey: _keys.get(_keys.marks, id),
            encountersKey: _keys.get(_keys.encounters, id),
            shinyGuideKey: _keys.get(_keys.shinyGuide, id),
            ignoreBtnKey: _keys.get(_keys.ignoreBtn, id),
          );
        },
      ),
    );
  }
}
