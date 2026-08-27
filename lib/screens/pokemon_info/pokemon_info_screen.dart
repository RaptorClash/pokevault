import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dex_view_models.dart';
import '../../models/pokemon.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';

import 'shiny_guide_widget.dart';
import 'widgets/catch_rate_calculator.dart';
import 'widgets/breeding_info_widget.dart';
import 'widgets/pokemon_info_widgets.dart';
import 'widgets/encounters_widget.dart';

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

  final GlobalKey _appBarKey = GlobalKey();

  final Map<String, GlobalKey> _shinyToggleKeys = {};
  final Map<String, GlobalKey> _basicInfoKeys = {};
  final Map<String, GlobalKey> _caughtStatusKeys = {};
  final Map<String, GlobalKey> _shinyStatusKeys = {};
  final Map<String, GlobalKey> _breedingKeys = {};
  final Map<String, GlobalKey> _catchCalcKeys = {};
  final Map<String, GlobalKey> _matchingBallsKeys = {};
  final Map<String, GlobalKey> _encountersKeys = {};
  final Map<String, GlobalKey> _shinyGuideKeys = {};
  final Map<String, GlobalKey> _ignoreBtnKeys = {};

  GlobalKey _getKey(Map<String, GlobalKey> map, String id) {
    return map.putIfAbsent(id, () => GlobalKey());
  }

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
          steps: [
            TutorialStep(
              targetKey: _appBarKey,
              titleKey: 'tutorial_info_appbar_title',
              textKey: 'tutorial_info_appbar_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_shinyToggleKeys, currentId),
              titleKey: 'tutorial_info_shiny_toggle_title',
              textKey: 'tutorial_info_shiny_toggle_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_basicInfoKeys, currentId),
              titleKey: 'tutorial_info_basic_title',
              textKey: 'tutorial_info_basic_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_caughtStatusKeys, currentId),
              titleKey: 'tutorial_info_caught_title',
              textKey: 'tutorial_info_caught_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_shinyStatusKeys, currentId),
              titleKey: 'tutorial_info_shiny_title',
              textKey: 'tutorial_info_shiny_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_breedingKeys, currentId),
              titleKey: 'tutorial_info_breeding_title',
              textKey: 'tutorial_info_breeding_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_catchCalcKeys, currentId),
              titleKey: 'tutorial_info_catchcalc_title',
              textKey: 'tutorial_info_catchcalc_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_matchingBallsKeys, currentId),
              titleKey: 'tutorial_info_matchingballs_title',
              textKey: 'tutorial_info_matchingballs_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_encountersKeys, currentId),
              titleKey: 'tutorial_info_encounters_title',
              textKey: 'tutorial_info_encounters_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_shinyGuideKeys, currentId),
              titleKey: 'tutorial_info_shinyguide_title',
              textKey: 'tutorial_info_shinyguide_text',
              requireTargetTap: false,
            ),
            TutorialStep(
              targetKey: _getKey(_ignoreBtnKeys, currentId),
              titleKey: 'tutorial_info_ignore_title',
              textKey: 'tutorial_info_ignore_text',
              requireTargetTap: true,
              onTargetTap: () {
                _confirmIgnore(
                  context,
                  context.read<DexProvider>(),
                  widget.entries[_currentIndex],
                  showTutorial: true,
                );
              },
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('pokemon_details'),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _confirmIgnore(
    BuildContext context,
    DexProvider provider,
    DexDisplayEntry entry, {
    bool showTutorial = false,
  }) {
    final GlobalKey confirmKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) {
        if (showTutorial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final tutProvider = Provider.of<TutorialProvider>(
              ctx,
              listen: false,
            );
            TutorialOverlay.show(
              ctx,
              TutorialFeature(
                id: 'ignore_confirm',
                nameKey: 'tutorial_feature_details',
                steps: [
                  TutorialStep(
                    targetKey: confirmKey,
                    titleKey: 'tutorial_info_ignore_confirm_title',
                    textKey: 'tutorial_info_ignore_confirm_text',
                    requireTargetTap: true,
                    onTargetTap: () {
                      provider.ignorePokemon(widget.dexId, entry.uniqueId);
                      tutProvider.markFeatureAsSeen('ignore_confirm');
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              () => tutProvider.markFeatureAsSeen('ignore_confirm'),
            );
          });
        }
        return AlertDialog(
          title: Text(
            Translator.get('ignore_confirm_title') != 'ignore_confirm_title'
                ? Translator.get('ignore_confirm_title')
                : 'Pokémon entfernen?',
          ),
          content: Text(
            Translator.get('ignore_confirm_text') != 'ignore_confirm_text'
                ? Translator.get('ignore_confirm_text')
                : 'Möchtest du dieses Pokémon ausblenden? Du kannst es im Menü jederzeit wiederherstellen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(Translator.get('cancel')),
            ),
            ElevatedButton(
              key: confirmKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                provider.ignorePokemon(widget.dexId, entry.uniqueId);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                Translator.get('ignore_pokemon') != 'ignore_pokemon'
                    ? Translator.get('ignore_pokemon')
                    : 'Entfernen',
              ),
            ),
          ],
        );
      },
    );
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
        key: _appBarKey,
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
          if (widget.onPageChanged != null) {
            widget.onPageChanged!(index);
          }
        },
        itemCount: widget.entries.length,
        itemBuilder: (context, index) {
          return _buildPokemonPage(context, widget.entries[index]);
        },
      ),
    );
  }

  Widget _buildPokemonPage(BuildContext context, DexDisplayEntry entry) {
    try {
      final provider = context.watch<DexProvider>();
      final liveDex = provider.userDexes.firstWhere(
        (d) => d.id == widget.dexId,
      );
      final isCaught = liveDex.caughtIds.contains(entry.uniqueId);
      final isShiny = liveDex.shinyIds.contains(entry.uniqueId);
      bool wantShiny = _manualShinyToggle ?? liveDex.isShinyDex;

      String formName = 'normal';
      if (entry.uniqueId.contains('_')) {
        formName = entry.uniqueId.substring(entry.uniqueId.indexOf('_') + 1);
        if (formName == 'm' || formName == 'f') formName = 'normal';
      }

      PokemonForm? currentForm;
      try {
        currentForm = entry.pokemon.forms.firstWhere((f) => f.name == formName);
      } catch (_) {
        if (entry.pokemon.forms.isNotEmpty) {
          currentForm = entry.pokemon.forms.first;
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PokemonHeaderWidget(
              entry: entry,
              wantShiny: wantShiny,
              currentForm: currentForm,
              shinyToggleKey: _getKey(_shinyToggleKeys, entry.uniqueId),
              onShinyToggled: () {
                setState(() {
                  _manualShinyToggle = !wantShiny;
                });
              },
            ),
            const SizedBox(height: 24),
            PokemonBasicInfoWidget(
              entry: entry,
              provider: provider,
              basicInfoKey: _getKey(_basicInfoKeys, entry.uniqueId),
              currentForm: currentForm,
            ),
            const SizedBox(height: 32),
            PokemonStatusTogglesWidget(
              dexId: widget.dexId,
              entry: entry,
              isCaught: isCaught,
              isShiny: isShiny,
              provider: provider,
              caughtStatusKey: _getKey(_caughtStatusKeys, entry.uniqueId),
              shinyStatusKey: _getKey(_shinyStatusKeys, entry.uniqueId),
            ),
            const SizedBox(height: 16),
            Container(
              key: _getKey(_breedingKeys, entry.uniqueId),
              child: BreedingInfoWidget(pokemon: entry.pokemon),
            ),
            Card(
              key: _getKey(_catchCalcKeys, entry.uniqueId),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.calculate_outlined,
                  color: Colors.purple,
                ),
                title: Text(
                  Translator.get('catch_calculator_title') !=
                          'catch_calculator_title'
                      ? Translator.get('catch_calculator_title')
                      : 'Ultimativer Fangratenrechner',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [CatchRateCalculator(pokemon: entry.pokemon)],
              ),
            ),
            const SizedBox(height: 16),
            MatchingBallsWidget(
              entry: entry,
              matchingBallsKey: _getKey(_matchingBallsKeys, entry.uniqueId),
            ),
            EncountersWidget(
              pokemonId: entry.pokemon.id,
              encountersKey: _getKey(_encountersKeys, entry.uniqueId),
            ),
            const SizedBox(height: 16),
            Container(
              key: _getKey(_shinyGuideKeys, entry.uniqueId),
              child: ShinyGuideWidget(entry: entry, dexId: widget.dexId),
            ),
            const SizedBox(height: 32),
            IgnorePokemonButton(
              ignoreBtnKey: _getKey(_ignoreBtnKeys, entry.uniqueId),
              onIgnore: () => _confirmIgnore(context, provider, entry),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_page_load') != 'error_page_load' ? Translator.get('error_page_load') : 'Fehler beim Laden der Seite:'} $e",
        );
      });
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        ),
      );
    }
  }
}
