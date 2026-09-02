import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../l10n/app_translations.dart';

import 'utils/pokemon_info_keys.dart';
import 'dialogs/ignore_pokemon_dialog.dart';
import 'widgets/pokemon_info_page.dart';

class PokemonInfoScreen extends StatefulWidget {
  final List<DexDisplayEntry> entries;
  final int initialIndex;
  final String dexId;
  final List<BoxData>? boxes;
  final bool isBoxView;
  final ValueChanged<int>? onPageChanged;

  const PokemonInfoScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.dexId,
    this.boxes,
    this.isBoxView = false,
    this.onPageChanged,
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
      appBar: AppBar(
        key: _keys.appBarKey,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.get('extra_info') != 'extra_info'
                  ? Translator.get('extra_info')
                  : 'Zusatzinformationen',
              style: TextStyle(fontSize: boxTitle != null ? 16 : 20),
            ),
            if (boxTitle != null)
              Text(
                '$boxTitle - $indexInBox / $boxTotal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ??
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
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _manualShinyToggle = null;
          });
          if (widget.onPageChanged != null) widget.onPageChanged!(index);
        },
        itemCount: widget.entries.length,
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          final id = entry.uniqueId;

          return PokemonInfoPage(
            entry: entry,
            dexId: widget.dexId,
            manualShinyToggle: _manualShinyToggle,
            onShinyToggled: () => setState(
              () => _manualShinyToggle = !(_manualShinyToggle ?? false),
            ),
            onIgnore: () => IgnorePokemonDialog.show(
              context,
              provider: context.read<DexProvider>(),
              entry: entry,
              dexId: widget.dexId,
            ),

            shinyToggleKey: _keys.get(_keys.shinyToggle, id),
            basicInfoKey: _keys.get(_keys.basicInfo, id),
            caughtStatusKey: _keys.get(_keys.caughtStatus, id),
            shinyStatusKey: _keys.get(_keys.shinyStatus, id),
            breedingKey: _keys.get(_keys.breeding, id),
            catchCalcKey: _keys.get(_keys.catchCalc, id),
            matchingBallsKey: _keys.get(_keys.matchingBalls, id),
            encountersKey: _keys.get(_keys.encounters, id),
            shinyGuideKey: _keys.get(_keys.shinyGuide, id),
            ignoreBtnKey: _keys.get(_keys.ignoreBtn, id),
          );
        },
      ),
    );
  }
}
