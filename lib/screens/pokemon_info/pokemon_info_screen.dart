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
import '../../utils/dex_logic_helper.dart';
import '../../models/pokemon.dart';

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
  final bool isGenderFallbackRoute;

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
    this.isGenderFallbackRoute = false,
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
        () {
          tutProvider.markFeatureAsSeen('pokemon_details');
          tutProvider.markFeatureAsSeen('gender_differences');
          tutProvider.markFeatureAsSeen('special_obtainable');
        },
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
        targetKey: _keys.get(_keys.genderDifferences, currentId),
        titleKey: 'tutorial_info_gender_title',
        textKey: 'tutorial_info_gender_text',
        requireTargetTap: false,
      ),
      TutorialStep(
        targetKey: currentId.contains('_special_')
            ? _keys.get(_keys.specialObtainable, currentId)
            : null,
        titleKey: 'tutorial_info_obtainable_title',
        textKey: 'tutorial_info_obtainable_text',
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
        targetKey: _keys.get(_keys.shinyHuntBtn, currentId),
        titleKey: 'tutorial_info_direct_hunt_title',
        textKey: 'tutorial_info_direct_hunt_text',
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

  DexDisplayEntry _createGenderDisplayEntry(Pokemon pokemon, bool isFemale, [PokemonForm? currentForm]) {
    final hasExplicitGenderForms = pokemon.forms.any(
      (f) => f.name.toLowerCase() == 'male' || f.name.toLowerCase() == 'female',
    );

    final formName = currentForm?.name.toLowerCase();
    final isSpecificForm = formName != null &&
        formName != 'normal' &&
        formName != 'male' &&
        formName != 'female';

    String suffix = isFemale ? ' ♀' : ' ♂';
    String uniqueId;
    if (isSpecificForm) {
      suffix = ' (${DexLogicHelper.getFormDisplayName(currentForm!.name)})$suffix';
      uniqueId = '${pokemon.id}_${currentForm.name}_${isFemale ? "f" : "m"}';
    } else if (hasExplicitGenderForms) {
      uniqueId = '${pokemon.id}_${isFemale ? "female" : "male"}';
    } else {
      uniqueId = '${pokemon.id}_${isFemale ? "f" : "m"}';
    }

    final PokemonForm? form = currentForm ??
        pokemon.forms.where(
          (f) => f.name.toLowerCase() == (isFemale ? 'female' : 'male'),
        ).firstOrNull ??
        pokemon.forms.where(
          (f) => f.formType == 'normal',
        ).firstOrNull ??
        (pokemon.forms.isNotEmpty ? pokemon.forms.first : null);

    final isShiny = _manualShinyToggle ?? false;
    final femaleShinyPath = isShiny ? 'shiny/female/' : 'female/';
    final shinyPath = isShiny ? 'shiny/' : '';

    String imageUrl;
    if (isFemale) {
      if (hasExplicitGenderForms) {
        imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyPath${pokemon.id}-female.png';
      } else {
        imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$femaleShinyPath${pokemon.id}.png';
      }
    } else {
      if (hasExplicitGenderForms) {
        imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home/$shinyPath${pokemon.id}-male.png';
      } else if (form != null && form.imageId != pokemon.id && form.imageId > 0) {
        imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath${form.imageId}.png';
      } else {
        imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$shinyPath${pokemon.id}.png';
      }
    }

    return DexDisplayEntry(
      pokemon: pokemon,
      uniqueId: uniqueId,
      displaySuffix: suffix,
      imageUrl: imageUrl,
      form: form,
    );
  }

  void _navigateToGender(Pokemon pokemon, String targetGender) {
    final isTargetFemale = targetGender.toLowerCase() == 'female' || targetGender.toLowerCase() == 'f';

    // 1. Check if the current entry already matches the target gender
    final currentEntry = widget.entries[_currentIndex];
    final currentBaseId = DexLogicHelper.getBaseId(currentEntry.uniqueId).toLowerCase();
    final currentIsFemale = currentBaseId.endsWith('_f') ||
        currentBaseId.endsWith('_female') ||
        currentEntry.resolvedForm?.name.toLowerCase() == 'female';

    if (currentIsFemale == isTargetFemale && currentEntry.pokemon.id == pokemon.id) {
      return;
    }

    // 2. If this screen was opened as a gender fallback, pop back to the parent screen
    if (widget.isGenderFallbackRoute && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    // 3. Find the best matching candidate in widget.entries (prioritizing same form and closest distance)
    final currentForm = currentEntry.resolvedForm ?? currentEntry.form;
    final currentFormName = currentForm?.name.toLowerCase();
    final isSpecificForm = currentFormName != null &&
        currentFormName != 'normal' &&
        currentFormName != 'male' &&
        currentFormName != 'female';

    int targetIndex = -1;
    int minDistance = 999999;

    for (int i = 0; i < widget.entries.length; i++) {
      final e = widget.entries[i];
      if (e.pokemon.id != pokemon.id) continue;

      final bId = DexLogicHelper.getBaseId(e.uniqueId).toLowerCase();
      final isEntryFemale = bId.endsWith('_f') ||
          bId.endsWith('_female') ||
          e.resolvedForm?.name.toLowerCase() == 'female';

      if (isTargetFemale) {
        if (!isEntryFemale) continue;
      } else {
        if (isEntryFemale) continue;
        final formType = e.resolvedForm?.formType.toLowerCase();
        final eName = e.resolvedForm?.name.toLowerCase();
        final isMaleLike = bId.endsWith('_m') ||
            bId.endsWith('_male') ||
            eName == 'male' ||
            formType == 'normal' ||
            eName == 'normal' ||
            formType == null;
        if (!isMaleLike) continue;
      }

      // Check form compatibility
      final eForm = e.resolvedForm ?? e.form;
      final eFormName = eForm?.name.toLowerCase();
      if (isSpecificForm) {
        final matchesForm = eFormName == currentFormName ||
            bId.contains('_${currentFormName}_') ||
            bId.startsWith('${pokemon.id}_$currentFormName');
        if (!matchesForm) continue;
      } else {
        // Current entry is normal/base form -> do not jump to regional/mega forms!
        final isNormalLike = eFormName == null ||
            eFormName == 'normal' ||
            eFormName == 'male' ||
            eFormName == 'female' ||
            eForm?.formType == 'normal';
        if (!isNormalLike) continue;
      }

      final distance = (i - _currentIndex).abs();
      if (distance < minDistance) {
        minDistance = distance;
        targetIndex = i;
      }
    }

    // 4. If found in entries, navigate to that page
    if (targetIndex != -1) {
      if (_pageController.hasClients) {
        if ((targetIndex - _currentIndex).abs() <= 3) {
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.jumpToPage(targetIndex);
        }
      }
      return;
    }

    // 5. If not found in entries (e.g. non-gender dex or filtered search):
    // Push a new PokemonInfoScreen with the target gender variant.
    final targetEntry = _createGenderDisplayEntry(pokemon, isTargetFemale, currentEntry.resolvedForm);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PokemonInfoScreen(
          entries: [targetEntry],
          initialIndex: 0,
          dexId: widget.dexId,
          initialShiny: _manualShinyToggle,
          isGenderFallbackRoute: true,
          selectionActionLabel: widget.selectionActionLabel,
          onSelectionAction: widget.onSelectionAction,
        ),
      ),
    );
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
            onNavigateToGender: (gender) => _navigateToGender(entry.pokemon, gender),
            genderDifferencesKey: _keys.get(_keys.genderDifferences, id),
            specialObtainableKey: _keys.get(_keys.specialObtainable, id),
            shinyHuntBtnKey: _keys.get(_keys.shinyHuntBtn, id),
          );
        },
      ),
    );
  }
}
