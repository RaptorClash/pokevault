import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_dex.dart';
import '../../models/pokemon.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../l10n/app_translations.dart';
import '../../i18n/strings.g.dart';
import '../../utils/dex_logic_helper.dart';
import '../../utils/notification_helper.dart';
import '../../screens/pokemon_info/widgets/breeding_data.dart';
import '../../utils/shiny_logic_helper.dart';
import '../ignored_list/ignored_list_screen.dart';
import 'dex_box_view.dart';
import 'dex_list_view.dart';
import 'pokemon_search_selection.dart';
import 'route_tracker_screen.dart';
import '../pokemon_info/pokemon_info_screen.dart';
import '../../services/database_service.dart';
import 'dex_sort_settings_screen.dart';
import 'box_edit_screen.dart';
import '../../utils/box_sequence_manager.dart';

class DexScreen extends StatefulWidget {
  final UserDex initialDex;
  final List<Pokemon> pokemonList;

  const DexScreen({
    super.key,
    required this.initialDex,
    required this.pokemonList,
  });

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';
  String _lastSearchQuery = '';
  String _lastFilter = 'all';

  bool _isBoxView = false;
  bool _separateForms = true;

  bool _isLoadingData = true;
  bool _isCalculatingBoxes = false;
  bool _pendingRecalculate = false;
  bool _isEditMode = false;
  final Set<String> _selectedForEdit = {};
  bool _isMoveTargetMode = false;
  List<CustomBoxState>? _customBoxesSnapshot;
  bool _wasCustomBoxesEmptyOriginally = false;
  int _lastBoxIndex = 0;
  late int _lastIgnoredCount;
  List<DexDisplayEntry> _rawEntries = [];
  List<BoxData> _boxes = [];
  Map<int, Map<String, dynamic>> _preEvolutions = {};

  final PageController _pageController = PageController();
  Timer? _debounce;

  final GlobalKey _firstPokemonKey = GlobalKey();
  final GlobalKey _sortMenuKey = GlobalKey();
  final GlobalKey _fakeMenuBoxKey = GlobalKey();
  final GlobalKey _fakeMenuFormsKey = GlobalKey();
  final GlobalKey _fakeMenuIgnoredKey = GlobalKey();
  final GlobalKey _searchBarKey = GlobalKey();

  bool _showFakeMenu = false;
  String? _tutorialTargetId;
  int _lastCustomBoxesCount = 0;

  @override
  void initState() {
    super.initState();
    _lastIgnoredCount = widget.initialDex.ignoredIds.length;
    _lastCustomBoxesCount = widget.initialDex.customBoxes.fold(0, (sum, b) => sum + b.pokemonIds.length);
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        _lastBoxIndex = _pageController.page!.round();
      }
    });
    _initializeDataAsync();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    _customBoxesSnapshot = null;
    super.dispose();
  }

  Future<void> _initializeDataAsync() async {
    try {
      _isBoxView = widget.initialDex.viewMode == 'box';
      _separateForms = widget.initialDex.sortMode != 'forms';

      final lang = context.read<SettingsProvider>().currentLanguage;

      _preEvolutions = await DatabaseService.instance.getGen12PreEvolutions();

      final specialObtainables = await DatabaseService.instance
          .getSpecialObtainables();

      _rawEntries = await DexLogicHelper.buildEntriesInBackground(
        widget.initialDex,
        widget.pokemonList,
        lang,
        specialObtainables,
      );

      final baseList = _rawEntries
          .where((e) => !widget.initialDex.ignoredIds.contains(e.uniqueId))
          .toList();

      if (widget.initialDex.customBoxes.isNotEmpty) {
        final migrated = DexLogicHelper.migrateCustomBoxInstances(widget.initialDex);
        if (migrated) {
          DatabaseService.instance.saveUserDex(widget.initialDex);
        }
        DexLogicHelper.enforceAutoFlow(widget.initialDex);
      }

      _boxes = await DexLogicHelper.generateBoxesInBackground(
        baseList,
        _separateForms,
        widget.initialDex,
        lang,
      );

      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });

        if (baseList.isNotEmpty) {
          _tutorialTargetId = baseList.first.uniqueId;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTutorialIfNeeded();
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError('${Translator.get('error')} $e');
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _recalculateBoxesAsync(UserDex liveDex) async {
    if (!mounted) return;
    if (_isCalculatingBoxes) {
      _pendingRecalculate = true;
      return;
    }
    
    int savedPage = _pageController.hasClients
        ? (_pageController.page?.round() ?? _lastBoxIndex)
        : _lastBoxIndex;

    setState(() => _isCalculatingBoxes = true);

    try {
      final baseList = _rawEntries
          .where((e) => !liveDex.ignoredIds.contains(e.uniqueId))
          .toList();

      final lang = context.read<SettingsProvider>().currentLanguage;

      if (liveDex.customBoxes.isNotEmpty) {
        final migrated = DexLogicHelper.migrateCustomBoxInstances(liveDex);
        if (migrated && !_isEditMode) {
          DatabaseService.instance.saveUserDex(liveDex);
        }
        DexLogicHelper.enforceAutoFlow(liveDex);
      }

      final newBoxes = await DexLogicHelper.generateBoxesInBackground(
        baseList,
        _separateForms,
        liveDex,
        lang,
      );

      if (mounted) {
        setState(() {
          _boxes = newBoxes;
          _isCalculatingBoxes = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients && _boxes.isNotEmpty) {
            int targetPage = savedPage;
            if (targetPage >= _boxes.length) {
              targetPage = _boxes.length - 1;
            }
            if (targetPage < 0) {
              targetPage = 0;
            }
            if (_pageController.page?.round() != targetPage) {
              _pageController.jumpToPage(targetPage);
            }
            _lastBoxIndex = targetPage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError('${Translator.get('error')} $e');
        setState(() => _isCalculatingBoxes = false);
      }
    } finally {
      if (mounted && _pendingRecalculate) {
        _pendingRecalculate = false;
        _recalculateBoxesAsync(liveDex);
      }
    }
  }

  Future<void> _handleSaveEditMode(UserDex liveDex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.edit_mode_save_title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.yes),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final activeIds = liveDex.customBoxes
          .expand((b) => b.pokemonIds)
          .where((id) => id.isNotEmpty && !DexLogicHelper.isPlaceholder(id))
          .toSet();

      setState(() {
        _isEditMode = false;
        _selectedForEdit.clear();
        _isMoveTargetMode = false;
        _customBoxesSnapshot = null;
        _wasCustomBoxesEmptyOriginally = false;
      });

      DexLogicHelper.pruneOrphanedInstances(liveDex, activeIds);

      await DatabaseService.instance.saveUserDex(liveDex);
      await DatabaseService.instance.cleanupOrphanedPokemon(liveDex.id, activeIds);
      if (mounted) {
        await _recalculateBoxesAsync(liveDex);
      }
    }
  }

  Future<void> _handleCancelEditMode(UserDex liveDex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.edit_mode_discard_title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.discard),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final activeIds = <String>{};
      setState(() {
        if (_wasCustomBoxesEmptyOriginally) {
          liveDex.customBoxes = [];
        } else if (_customBoxesSnapshot != null) {
          liveDex.customBoxes =
              _customBoxesSnapshot!.map((b) => b.copyWith()).toList();
          activeIds.addAll(
            liveDex.customBoxes
                .expand((b) => b.pokemonIds)
                .where((id) => id.isNotEmpty && !DexLogicHelper.isPlaceholder(id)),
          );
        }
        _customBoxesSnapshot = null;
        _wasCustomBoxesEmptyOriginally = false;
        _selectedForEdit.clear();
        _isMoveTargetMode = false;
        _isEditMode = false;
      });

      DexLogicHelper.pruneOrphanedInstances(liveDex, activeIds);

      await DatabaseService.instance.saveUserDex(liveDex);
      await DatabaseService.instance.cleanupOrphanedPokemon(liveDex.id, activeIds);
      if (mounted) {
        await _recalculateBoxesAsync(liveDex);
      }
    }
  }

  void _ensureCustomBoxesInitialized(UserDex liveDex) {
    if (liveDex.customBoxes.isNotEmpty) return;
    liveDex.customBoxes = DexLogicHelper.initializeCustomBoxesFromEntries(
      liveDex,
      const [],
      boxes: _boxes,
    );
  }

  void _executeMoveMultipleToSlot(
    UserDex liveDex,
    List<String> sourceIds,
    int targetBoxIndex,
    int? targetSlotIndex,
  ) {
    if (sourceIds.isEmpty) return;

    _ensureCustomBoxesInitialized(liveDex);

    BoxSequenceManager.moveMultiplePokemon(
      dex: liveDex,
      sourceIds: sourceIds,
      targetBoxIndex: targetBoxIndex,
      targetSlotIndex: targetSlotIndex,
    );

    if (liveDex.customBoxes.isNotEmpty && liveDex.customBoxes.first.autoFlow) {
      for (var b in liveDex.customBoxes) {
        b.autoFlow = false;
      }
    }

    if (!_isEditMode) {
      DatabaseService.instance.saveUserDex(liveDex);
    }

    _selectedForEdit.clear();
    _isMoveTargetMode = false;
    _lastBoxIndex = targetBoxIndex;
    if (_pageController.hasClients && targetBoxIndex < _boxes.length) {
      _pageController.jumpToPage(targetBoxIndex);
    }
    _recalculateBoxesAsync(liveDex);
  }

  void _executeMoveSelectedToSlot(UserDex liveDex, int targetBoxIndex, int targetSlotIndex) {
    if (_selectedForEdit.isEmpty) return;

    final sortedKeys = _selectedForEdit.toList()
      ..sort((a, b) {
        final pA = a.split('_').map(int.parse).toList();
        final pB = b.split('_').map(int.parse).toList();
        if (pA[0] != pB[0]) return pA[0].compareTo(pB[0]);
        return pA[1].compareTo(pB[1]);
      });

    final selectedIds = <String>[];
    for (final key in sortedKeys) {
      final parts = key.split('_').map(int.parse).toList();
      final bIdx = parts[0];
      final sIdx = parts[1];
      if (bIdx < liveDex.customBoxes.length && sIdx < liveDex.customBoxes[bIdx].pokemonIds.length) {
        final id = liveDex.customBoxes[bIdx].pokemonIds[sIdx];
        if (id.isNotEmpty) {
          selectedIds.add(id);
        }
      } else if (bIdx < _boxes.length && sIdx < _boxes[bIdx].entries.length) {
        final id = _boxes[bIdx].entries[sIdx].uniqueId;
        if (id.isNotEmpty) {
          selectedIds.add(id);
        }
      }
    }

    _executeMoveMultipleToSlot(liveDex, selectedIds, targetBoxIndex, targetSlotIndex);
  }

  void _executeMoveSelectedToBox(UserDex liveDex, int targetBoxIndex) {
    if (_selectedForEdit.isEmpty) return;

    final sortedKeys = _selectedForEdit.toList()
      ..sort((a, b) {
        final pA = a.split('_').map(int.parse).toList();
        final pB = b.split('_').map(int.parse).toList();
        if (pA[0] != pB[0]) return pA[0].compareTo(pB[0]);
        return pA[1].compareTo(pB[1]);
      });

    final selectedIds = <String>[];
    for (final key in sortedKeys) {
      final parts = key.split('_').map(int.parse).toList();
      final bIdx = parts[0];
      final sIdx = parts[1];
      if (bIdx < liveDex.customBoxes.length && sIdx < liveDex.customBoxes[bIdx].pokemonIds.length) {
        final id = liveDex.customBoxes[bIdx].pokemonIds[sIdx];
        if (id.isNotEmpty) {
          selectedIds.add(id);
        }
      } else if (bIdx < _boxes.length && sIdx < _boxes[bIdx].entries.length) {
        final id = _boxes[bIdx].entries[sIdx].uniqueId;
        if (id.isNotEmpty) {
          selectedIds.add(id);
        }
      }
    }

    _executeMoveMultipleToSlot(liveDex, selectedIds, targetBoxIndex, null);
  }

  Future<void> _showMoveToBoxDialog(UserDex liveDex) async {
    final boxCount = liveDex.customBoxes.isNotEmpty
        ? liveDex.customBoxes.length
        : _boxes.length;

    final selectedBox = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.select_target_box),
          content: SizedBox(
            width: 320,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: boxCount,
              itemBuilder: (context, i) {
                final title = liveDex.customBoxes.isNotEmpty
                    ? liveDex.customBoxes[i].title
                    : _boxes[i].title;
                return ListTile(
                  leading: const Icon(Icons.inbox),
                  title: Text(title),
                  onTap: () => Navigator.of(ctx).pop(i),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(t.cancel),
            ),
          ],
        );
      },
    );

    if (selectedBox != null && mounted) {
      setState(() {
        _executeMoveSelectedToBox(liveDex, selectedBox);
      });
    }
  }

  void _showTutorialIfNeeded() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    final dexProvider = Provider.of<DexProvider>(context, listen: false);

    if (!tutProvider.hasSeenFeature('dex_screen')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'dex_screen',
          nameKey: 'tutorial_feature_details',
          steps: [
            TutorialStep(
              targetKey: null,
              titleKey: 'tutorial_dex_intro_title',
              textKey: 'tutorial_dex_intro_text',
            ),
            TutorialStep(
              targetKey: _firstPokemonKey,
              titleKey: 'tutorial_dex_tap_title',
              textKey: 'tutorial_dex_tap_text',
              requireTargetTap: true,
              onTargetTap: () {
                try {
                  final baseList = _rawEntries
                      .where(
                        (e) =>
                            !widget.initialDex.ignoredIds.contains(e.uniqueId),
                      )
                      .toList();
                  if (baseList.isNotEmpty) {
                    dexProvider.togglePokemon(
                      widget.initialDex.id,
                      baseList.first.uniqueId,
                    );
                  }
                } catch (e) {
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              },
            ),
            TutorialStep(
              targetKey: _sortMenuKey,
              titleKey: 'tutorial_dex_menu_title',
              textKey: 'tutorial_dex_menu_text',
              requireTargetTap: true,
              onTargetTap: () {
                setState(() => _showFakeMenu = true);
              },
            ),
            TutorialStep(
              targetKey: _fakeMenuFormsKey,
              titleKey: 'tutorial_dex_menu_forms_title',
              textKey: 'tutorial_dex_menu_forms_text',
              requireTargetTap: true,
              onTargetTap: () {
                _toggleSeparateForms();
              },
            ),
            TutorialStep(
              targetKey: _fakeMenuBoxKey,
              titleKey: 'tutorial_dex_menu_box_title',
              textKey: 'tutorial_dex_menu_box_text',
              requireTargetTap: true,
              onTargetTap: () {
                setState(() => _showFakeMenu = false);
                _toggleBoxView();
              },
            ),
            TutorialStep(
              targetKey: _searchBarKey,
              titleKey: 'tutorial_dex_search_title',
              textKey: 'tutorial_dex_search_text',
              requireTargetTap: false,
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('dex_screen'),
      );
    } else if (tutProvider.hasSeenFeature('pokemon_details') &&
        !tutProvider.hasSeenFeature('ignored_pokemon')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'ignored_pokemon',
          nameKey: 'tutorial_feature_details',
          steps: [
            TutorialStep(
              targetKey: _sortMenuKey,
              titleKey: 'tutorial_dex_menu_ignored_title',
              textKey: 'tutorial_dex_menu_ignored_text',
              requireTargetTap: true,
              onTargetTap: () {
                setState(() => _showFakeMenu = true);
              },
            ),
            TutorialStep(
              targetKey: _fakeMenuIgnoredKey,
              titleKey: 'tutorial_dex_menu_ignored_btn_title',
              textKey: 'tutorial_dex_menu_ignored_btn_text',
              requireTargetTap: true,
              onTargetTap: () {
                setState(() => _showFakeMenu = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IgnoredListScreen(
                      dexId: widget.initialDex.id,
                      allRawEntries: _rawEntries,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _showTutorialIfNeeded();
                });
              },
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('ignored_pokemon'),
      );
    }
  }

  void _showMachomeiFoundTutorial() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final lang = settingsProvider.currentLanguage;

    final baseList = _rawEntries
        .where((e) => !widget.initialDex.ignoredIds.contains(e.uniqueId))
        .toList();
    final filtered = baseList
        .where((e) => _matchesSearch(e, widget.initialDex, dexProvider, lang))
        .toList();

    if (filtered.isNotEmpty) {
      setState(() {
        _tutorialTargetId = filtered.first.uniqueId;
      });
    }

    TutorialOverlay.show(
      context,
      TutorialFeature(
        id: 'dex_machomei_found',
        nameKey: 'tutorial_feature_details',
        steps: [
          TutorialStep(
            targetKey: _firstPokemonKey,
            titleKey: 'tutorial_longpress_title',
            textKey: 'tutorial_longpress_text',
            requireTargetTap: true,
            requireLongPress: true,
            preCalculateDelayMilliseconds: 800,
            onTargetTap: () {
              try {
                final listToUse = filtered.isNotEmpty ? filtered : baseList;
                if (listToUse.isNotEmpty) {
                  int targetIndex = listToUse.indexWhere(
                    (e) => e.uniqueId == _tutorialTargetId,
                  );
                  if (targetIndex == -1) targetIndex = 0;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => PokemonInfoScreen(
                        entries: listToUse,
                        initialIndex: targetIndex,
                        dexId: widget.initialDex.id,
                        isBoxView: _isBoxView,
                        boxes: _boxes,
                      ),
                    ),
                  ).then((_) {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                    if (mounted) _showTutorialIfNeeded();
                  });
                }
              } catch (e) {
                NotificationHelper.showError('${Translator.get('error')} $e');
              }
            },
          ),
        ],
      ),
      () => tutProvider.markFeatureAsSeen('dex_machomei_found'),
    );
  }

  Future<void> _toggleBoxView() async {
    setState(() {
      _isBoxView = !_isBoxView;
    });

    final provider = context.read<DexProvider>();
    final liveDex = provider.userDexes.firstWhere(
      (d) => d.id == widget.initialDex.id,
      orElse: () => widget.initialDex,
    );
    liveDex.viewMode = _isBoxView ? 'box' : 'list';
    await DatabaseService.instance.saveUserDex(liveDex);
  }

  Future<void> _toggleSeparateForms() async {
    if (_isCalculatingBoxes) return;

    setState(() {
      _separateForms = !_separateForms;
    });

    final provider = context.read<DexProvider>();
    final liveDex = provider.userDexes.firstWhere(
      (d) => d.id == widget.initialDex.id,
      orElse: () => widget.initialDex,
    );
    liveDex.sortMode = _separateForms ? 'dex' : 'forms';
    await DatabaseService.instance.saveUserDex(liveDex);

    await _recalculateBoxesAsync(liveDex);
  }

  bool _matchesSearch(
    DexDisplayEntry entry,
    UserDex liveDex,
    DexProvider provider,
    String currentLanguage,
  ) {
    if (_searchQuery.trim().isEmpty) return true;

    final form = entry.resolvedForm;

    String regionId = DexLogicHelper.getPokemonRegionId(
      entry.pokemon,
      form,
      liveDex,
    );

    final orTerms = _searchQuery.toLowerCase().split(',');
    for (String orTerm in orTerms) {
      if (orTerm.trim().isEmpty) continue;

      final andTerms = orTerm.split('&');
      bool allAndsMatch = true;

      for (String term in andTerms) {
        term = term.trim();
        if (term.isEmpty) continue;

        bool match = false;

        final rangeMatch = RegExp(r'^#?(\d+)\s*-\s*#?(\d+)$').firstMatch(term);
        if (rangeMatch != null) {
          int min = int.parse(rangeMatch.group(1)!);
          int max = int.parse(rangeMatch.group(2)!);
          if (entry.pokemon.id >= min && entry.pokemon.id <= max) match = true;
        } else {
          final exactMatch = RegExp(r'^#?(\d+)$').firstMatch(term);
          if (exactMatch != null) {
            if (entry.pokemon.id == int.parse(exactMatch.group(1)!)) {
              match = true;
            }
          } else if (term == 'shiny') {
            if (DexLogicHelper.isPokemonShiny(liveDex, entry.uniqueId)) match = true;
          } else if (term == 'caught') {
            if (DexLogicHelper.isPokemonCaught(liveDex, entry.uniqueId)) match = true;
          } else if (term == 'uncaught' || term == 'missing') {
            if (!DexLogicHelper.isPokemonCaught(liveDex, entry.uniqueId)) match = true;
          } else if (term == 'mega' || term == 'gmax') {
            if (entry.uniqueId.contains(term)) match = true;
          } else {
            final regionKeys = [
              'kanto',
              'johto',
              'hoenn',
              'sinnoh',
              'unova',
              'kalos',
              'alola',
              'galar',
              'hisui',
              'paldea',
            ];
            String? matchedRegion;
            for (var r in regionKeys) {
              if (term == r ||
                  term == Translator.get('group_$r').toLowerCase() ||
                  term == Translator.get('region_name_$r').toLowerCase()) {
                matchedRegion = r;
                break;
              }
            }

            if (matchedRegion != null) {
              if (regionId == matchedRegion) match = true;
            } else if (term.startsWith('+')) {
              String familyTarget = term.substring(1).trim();
              if (familyTarget.isNotEmpty) {
                final targetPoke = widget.pokemonList
                    .where(
                      (p) =>
                          p.getName(currentLanguage).toLowerCase() ==
                          familyTarget,
                    )
                    .firstOrNull;

                if (targetPoke != null) {
                  final family = BreedingData.getFullFamily(
                    targetPoke.id,
                    provider,
                    _preEvolutions,
                  );
                  if (family.contains(
                    ShinyLogicHelper.getBaseForm(
                      entry.pokemon.id,
                      _preEvolutions,
                    ),
                  )) {
                    match = true;
                  } else if (entry.pokemon.id == targetPoke.id) {
                    match = true;
                  }
                }
              }
            } else {
              final types = form?.types ?? [];
              bool typeMatch = types.any(
                (t) =>
                    t.toLowerCase() == term ||
                    Translator.get('type_$t').toLowerCase() == term,
              );

              if (typeMatch) {
                match = true;
              } else {
                final baseName = entry.pokemon
                    .getName(currentLanguage)
                    .toLowerCase();

                String searchableText = baseName;
                if (form != null) {
                  searchableText += ' ${form.name.toLowerCase()}';
                  searchableText +=
                      ' ${Translator.get('form_name_${form.name}').toLowerCase()}';
                }

                if (entry.uniqueId.contains('_trade_')) {
                  searchableText += ' trade tausche tausch';
                }
                if (entry.uniqueId.contains('_gift_')) {
                  searchableText += ' gift geschenk';
                }
                if (entry.uniqueId.contains('_n_')) {
                  searchableText += " n's pokemon n";
                }

                if (term.contains('*')) {
                  try {
                    String rStr =
                        '^${term.split('*').map((s) => RegExp.escape(s)).join('.*')}\$';
                    if (RegExp(rStr).hasMatch(searchableText)) {
                      match = true;
                    }
                  } catch (_) {
                    if (searchableText.contains(term)) match = true;
                  }
                } else {
                  if (searchableText.contains(term) ||
                      entry.pokemon.id.toString() == term) {
                    match = true;
                  }
                }
              }
            }
          }
        }

        if (!match) {
          allAndsMatch = false;
          break;
        }
      }

      if (allAndsMatch) return true;
    }
    return false;
  }

  void _showSearchHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          Translator.get('search_help_title', fallback: 'Such-Befehle'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _helpItem(
                '15 / #15',
                Translator.get(
                  'search_help_id',
                  fallback: 'Sucht exakt nach einer ID.',
                ),
              ),
              _helpItem(
                '1-151',
                Translator.get(
                  'search_help_range',
                  fallback: 'Zeigt PokÃ©mon im ID-Bereich.',
                ),
              ),
              _helpItem(
                'shiny, caught, missing',
                Translator.get(
                  'search_help_status',
                  fallback: 'Filtert nach Status.',
                ),
              ),
              _helpItem(
                'kanto, alola, mega',
                Translator.get(
                  'search_help_forms',
                  fallback: 'Filtert nach Regionen oder Formen.',
                ),
              ),
              _helpItem(
                '+Bisasam',
                Translator.get(
                  'search_help_family',
                  fallback: 'Zeigt die Entwicklungsreihe.',
                ),
              ),
              _helpItem(
                'Pika* / *chu',
                Translator.get(
                  'search_help_wildcard',
                  fallback: 'Wildcard-Suche.',
                ),
              ),
              _helpItem(
                'shiny & kanto',
                Translator.get(
                  'search_help_and',
                  fallback: 'Mit "&" mÃ¼ssen beide Begriffe zutreffen.',
                ),
              ),
              _helpItem(
                '1-9, Evoli',
                Translator.get(
                  'search_help_or',
                  fallback: 'Mit "," reicht ein Treffer (ODER).',
                ),
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

  Widget _helpItem(String title, String desc) {
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = context.watch<DexProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final liveDex = provider.userDexes.firstWhere(
      (d) => d.id == widget.initialDex.id,
      orElse: () => widget.initialDex,
    );

    int currentCustomBoxesCount = liveDex.customBoxes.fold(0, (sum, b) => sum + b.pokemonIds.length);
    if (liveDex.ignoredIds.length != _lastIgnoredCount || currentCustomBoxesCount != _lastCustomBoxesCount) {
      _lastIgnoredCount = liveDex.ignoredIds.length;
      _lastCustomBoxesCount = currentCustomBoxesCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recalculateBoxesAsync(liveDex);
      });
    }

    List<DexDisplayEntry> baseList = _rawEntries
        .where((e) => !liveDex.ignoredIds.contains(e.uniqueId))
        .toList();
        
    if (liveDex.customBoxes.isNotEmpty) {
      baseList = _boxes
          .expand((b) => b.entries)
          .where((e) => e.uniqueId.isNotEmpty && !e.isPlaceholder)
          .toList();
    }

    final occupiedCustomPokemonIds = liveDex.customBoxes
        .expand((b) => b.pokemonIds)
        .where((id) => id.isNotEmpty && !DexLogicHelper.isPlaceholder(id))
        .toList();

    int caughtCount = baseList
        .where((e) => DexLogicHelper.isPokemonCaught(liveDex, e.uniqueId))
        .length;
    int totalCount = baseList.length;

    if (liveDex.region == 'custom_empty') {
      totalCount = baseList.isNotEmpty
          ? baseList.length
          : occupiedCustomPokemonIds.length;
      caughtCount = baseList.isNotEmpty
          ? baseList
              .where((e) => DexLogicHelper.isPokemonCaught(liveDex, e.uniqueId))
              .length
          : occupiedCustomPokemonIds
              .where((id) => DexLogicHelper.isPokemonCaught(liveDex, id))
              .length;
    } else if (liveDex.customBoxes.isNotEmpty) {
      if (occupiedCustomPokemonIds.length > totalCount) {
        totalCount = occupiedCustomPokemonIds.length;
      }
    }
    if (caughtCount > totalCount) {
      totalCount = caughtCount;
    }

    final filteredList = baseList.where((entry) {
      final isCaught = DexLogicHelper.isPokemonCaught(liveDex, entry.uniqueId);
      if (_filter == 'caught' && !isCaught) return false;
      if (_filter == 'uncaught' && isCaught) return false;

      return _matchesSearch(
        entry,
        liveDex,
        provider,
        settingsProvider.currentLanguage,
      );
    }).toList();

    final bool isSearchActive =
        _searchQuery.trim().isNotEmpty || _filter != 'all';
    final Set<String> highlightedIds = filteredList
        .map((e) => e.uniqueId)
        .toSet();

    if (isSearchActive &&
        (_searchQuery != _lastSearchQuery || _filter != _lastFilter)) {
      _lastSearchQuery = _searchQuery;
      _lastFilter = _filter;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isBoxView && _pageController.hasClients) {
          int currentPage = _pageController.page?.round() ?? 0;
          if (_boxes.isNotEmpty && currentPage < _boxes.length) {
            bool currentHasMatch = _boxes[currentPage].entries.any(
              (e) => highlightedIds.contains(e.uniqueId),
            );
            if (!currentHasMatch) {
              int firstMatchIndex = _boxes.indexWhere(
                (box) =>
                    box.entries.any((e) => highlightedIds.contains(e.uniqueId)),
              );
              if (firstMatchIndex != -1) {
                _pageController.animateToPage(
                  firstMatchIndex,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              }
            }
          }
        }
      });
    } else if (!isSearchActive) {
      _lastSearchQuery = _searchQuery;
      _lastFilter = _filter;
    }

    Widget bodyContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: _searchBarKey,
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: Translator.get('search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () => _showSearchHelpDialog(context),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      setState(() => _searchQuery = val);

                      final tutProvider = Provider.of<TutorialProvider>(
                        context,
                        listen: false,
                      );
                      if (tutProvider.hasSeenFeature('dex_screen') &&
                          !tutProvider.hasSeenFeature('dex_machomei_found')) {
                        final q = val.toLowerCase().trim();
                        if (q == 'machomei' ||
                            q == 'machamp' ||
                            q == '068' ||
                            q == '68' ||
                            q == '#068') {
                          _showMachomeiFoundTutorial();
                        }
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filter,
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(Translator.get('filter_all')),
                  ),
                  DropdownMenuItem(
                    value: 'caught',
                    child: Text(Translator.get('filter_caught')),
                  ),
                  DropdownMenuItem(
                    value: 'uncaught',
                    child: Text(Translator.get('filter_missing')),
                  ),
                ],
                onChanged: (val) => setState(() => _filter = val ?? 'all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _isBoxView
                  ? DexBoxView(
                      firstItemKey: _firstPokemonKey,
                      tutorialTargetId: _tutorialTargetId,
                      boxes: _boxes,
                      liveDex: liveDex,
                      provider: provider,
                      pageController: _pageController,
                      separateForms: _separateForms,
                      highlightedIds: highlightedIds,
                      isSearchActive: isSearchActive,
                      isEditMode: _isEditMode,
                      selectedForEdit: _selectedForEdit,
                      onSelectionChanged: (boxIndex, itemIndex) {
                        if (_isMoveTargetMode) {
                          setState(() {
                            _executeMoveSelectedToSlot(liveDex, boxIndex, itemIndex);
                          });
                          return;
                        }
                        setState(() {
                          final key = '${boxIndex}_$itemIndex';
                          if (_selectedForEdit.contains(key)) {
                            _selectedForEdit.remove(key);
                          } else {
                            _selectedForEdit.add(key);
                          }
                        });
                      },
                      onInsertPokemon: (boxIndex, insertIndex) async {
                        if (_isEditMode && _selectedForEdit.isNotEmpty) {
                          setState(() {
                            _executeMoveSelectedToSlot(liveDex, boxIndex, insertIndex);
                          });
                          return;
                        }
                        final selectedId = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (ctx) => PokemonSearchSelectionScreen(
                              allAvailableEntries: _rawEntries,
                              dexId: liveDex.id,
                              initialShiny: liveDex.isShinyDex,
                            ),
                          ),
                        );
                        if (selectedId != null && selectedId.isNotEmpty && mounted) {
                          setState(() {
                            _ensureCustomBoxesInitialized(liveDex);

                            if (selectedId == 'placeholder') {
                              final instanceId =
                                  'placeholder__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';

                              if (boxIndex < liveDex.customBoxes.length) {
                                final box = liveDex.customBoxes[boxIndex];
                                if (insertIndex < box.pokemonIds.length &&
                                    (DexLogicHelper.isPlaceholder(box.pokemonIds[insertIndex]) ||
                                     box.pokemonIds[insertIndex].isEmpty)) {
                                  box.pokemonIds[insertIndex] = instanceId;
                                } else {
                                  BoxSequenceManager.insertWithShiftAndOverflow(
                                    dex: liveDex,
                                    boxIndex: boxIndex,
                                    slotIndex: insertIndex,
                                    pokemonId: instanceId,
                                  );
                                }
                              }

                              if (!_isEditMode) {
                                DatabaseService.instance.saveUserDex(liveDex);
                              }
                            } else {
                              final isShinySelection = selectedId.startsWith('shiny:');
                              final cleanSelectedId = isShinySelection ? selectedId.substring(6) : selectedId;
                              DexLogicHelper.ensurePrimaryInstancePersisted(liveDex, cleanSelectedId);
                              final instanceId = '${cleanSelectedId}__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';

                              if (boxIndex < liveDex.customBoxes.length) {
                                final box = liveDex.customBoxes[boxIndex];
                                if (insertIndex < box.pokemonIds.length &&
                                    (DexLogicHelper.isPlaceholder(box.pokemonIds[insertIndex]) ||
                                     box.pokemonIds[insertIndex].isEmpty)) {
                                  box.pokemonIds[insertIndex] = instanceId;
                                } else {
                                  BoxSequenceManager.insertWithShiftAndOverflow(
                                    dex: liveDex,
                                    boxIndex: boxIndex,
                                    slotIndex: insertIndex,
                                    pokemonId: instanceId,
                                  );
                                }
                              }

                              if (isShinySelection && !liveDex.shinyIds.contains(instanceId)) {
                                liveDex.shinyIds.add(instanceId);
                                DatabaseService.instance.savePokemonStatus(liveDex.id, instanceId, isShiny: true);
                              } else if (!isShinySelection && liveDex.shinyIds.contains(instanceId)) {
                                liveDex.shinyIds.remove(instanceId);
                                DatabaseService.instance.savePokemonStatus(liveDex.id, instanceId, isShiny: false);
                              }
                              if (!_isEditMode) {
                                DatabaseService.instance.saveUserDex(liveDex);
                              }
                            }
                          });
                          _recalculateBoxesAsync(liveDex);
                        }
                      },
                      onMovePokemonWithSource: (sourceId, targetBox, targetIndex, sourceBox, sourceSlot) {
                        final slotDrag = BoxSlotDragData.tryParse(sourceId);
                        final actualSourceId = slotDrag != null ? slotDrag.uniqueId : sourceId;
                        final actualSourceBox = sourceBox ?? slotDrag?.boxIndex;
                        final actualSourceSlot = sourceSlot ?? slotDrag?.slotIndex;
                        setState(() {
                          _ensureCustomBoxesInitialized(liveDex);

                          BoxSequenceManager.movePokemon(
                            dex: liveDex,
                            sourceId: actualSourceId,
                            sourceBoxIndex: actualSourceBox,
                            sourceSlotIndex: actualSourceSlot,
                            targetBoxIndex: targetBox,
                            targetSlotIndex: targetIndex,
                          );

                          if (liveDex.customBoxes.isNotEmpty && liveDex.customBoxes.first.autoFlow) {
                            for (var b in liveDex.customBoxes) {
                              b.autoFlow = false;
                            }
                          }

                          if (!_isEditMode) {
                            DatabaseService.instance.saveUserDex(liveDex);
                          } else if (_selectedForEdit.isNotEmpty) {
                            _selectedForEdit.clear();
                          }
                        });
                        _recalculateBoxesAsync(liveDex);
                      },
                      onSwapPokemonWithSource: (sourceId, targetBox, targetIndex, sourceBox, sourceSlot) {
                        final slotDrag = BoxSlotDragData.tryParse(sourceId);
                        final actualSourceId = slotDrag != null ? slotDrag.uniqueId : sourceId;
                        final actualSourceBox = sourceBox ?? slotDrag?.boxIndex;
                        final actualSourceSlot = sourceSlot ?? slotDrag?.slotIndex;
                        setState(() {
                          _ensureCustomBoxesInitialized(liveDex);

                          if (actualSourceBox != null && actualSourceSlot != null) {
                            BoxSequenceManager.swapPokemonByIndices(
                              dex: liveDex,
                              sourceBoxIndex: actualSourceBox,
                              sourceSlotIndex: actualSourceSlot,
                              targetBoxIndex: targetBox,
                              targetSlotIndex: targetIndex,
                            );
                          } else {
                            BoxSequenceManager.swapPokemon(
                              dex: liveDex,
                              sourceId: actualSourceId,
                              targetBoxIndex: targetBox,
                              targetSlotIndex: targetIndex,
                            );
                          }

                          if (liveDex.customBoxes.isNotEmpty && liveDex.customBoxes.first.autoFlow) {
                            for (var b in liveDex.customBoxes) {
                              b.autoFlow = false;
                            }
                          }

                          if (!_isEditMode) {
                            DatabaseService.instance.saveUserDex(liveDex);
                          } else if (_selectedForEdit.isNotEmpty) {
                            _selectedForEdit.clear();
                          }
                        });
                        _recalculateBoxesAsync(liveDex);
                      },
                      onMoveMultiplePokemon: (sourceIds, targetBox, targetIndex) {
                        setState(() {
                          _executeMoveMultipleToSlot(liveDex, sourceIds, targetBox, targetIndex);
                        });
                      },
                    )
                  : DexListView(
                      firstItemKey: _firstPokemonKey,
                      tutorialTargetId: _tutorialTargetId,
                      displayList: filteredList,
                      liveDex: liveDex,
                      provider: provider,
                    ),
              if (_isCalculatingBoxes)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_isEditMode && _selectedForEdit.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).cardColor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_selectedForEdit.length} Pokémon ${Translator.get('selected', fallback: 'ausgewählt')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (_isMoveTargetMode)
                                  Text(
                                    t.tap_target_slot,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isMoveTargetMode ? Icons.check_circle : Icons.open_with,
                              color: _isMoveTargetMode ? Theme.of(context).colorScheme.primary : null,
                            ),
                            tooltip: t.move_selected_block,
                            onPressed: () {
                              setState(() {
                                _isMoveTargetMode = !_isMoveTargetMode;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.drive_file_move_outlined),
                            tooltip: t.move_selected_to_box,
                            onPressed: () => _showMoveToBoxDialog(liveDex),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: t.box_edit_remove_selected,
                            onPressed: () {
                              setState(() {
                                _ensureCustomBoxesInitialized(liveDex);

                                BoxSequenceManager.batchRemoveWithShiftBack(
                                  dex: liveDex,
                                  selectedKeys: _selectedForEdit.toList(),
                                );

                                if (!_isEditMode) {
                                  DatabaseService.instance.saveUserDex(liveDex);
                                }
                                _selectedForEdit.clear();
                                _isMoveTargetMode = false;
                              });
                              _recalculateBoxesAsync(liveDex);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: t.cancel_selection,
                            onPressed: () {
                              setState(() {
                                _selectedForEdit.clear();
                                _isMoveTargetMode = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return PopScope(
      canPop: !_isEditMode,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (_isEditMode) {
          await _handleCancelEditMode(liveDex);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isEditMode
              ? IconButton(
                  icon: const BackButtonIcon(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => _handleCancelEditMode(liveDex),
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                liveDex.title,
                style: const TextStyle(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$caughtCount / $totalCount ${Translator.get('caught')}',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_isEditMode && _selectedForEdit.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: t.box_edit_remove_selected,
                onPressed: () {
                  setState(() {
                    _ensureCustomBoxesInitialized(liveDex);

                    BoxSequenceManager.batchRemoveWithShiftBack(
                      dex: liveDex,
                      selectedKeys: _selectedForEdit.toList(),
                    );

                    if (!_isEditMode) {
                      DatabaseService.instance.saveUserDex(liveDex);
                    }
                    _selectedForEdit.clear();
                  });
                  _recalculateBoxesAsync(liveDex);
                },
              ),
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: Translator.get('add_pokemon', fallback: 'Hinzufügen'),
                onPressed: () async {
                  final targetBoxIndex = _pageController.hasClients
                      ? (_pageController.page?.round() ?? _lastBoxIndex)
                      : _lastBoxIndex;

                  final selectedId = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (ctx) => PokemonSearchSelectionScreen(
                        allAvailableEntries: _rawEntries,
                        dexId: liveDex.id,
                        initialShiny: liveDex.isShinyDex,
                      ),
                    ),
                  );
                  if (selectedId != null && selectedId.isNotEmpty && mounted) {
                    setState(() {
                      int currentBoxIndex = targetBoxIndex;
                      _ensureCustomBoxesInitialized(liveDex);

                      if (currentBoxIndex < liveDex.customBoxes.length) {
                        final box = liveDex.customBoxes[currentBoxIndex];
                        int targetSlot = box.pokemonIds.indexOf("");
                        if (targetSlot == -1) {
                          targetSlot = box.pokemonIds.length;
                        }

                        if (selectedId == 'placeholder') {
                          final instanceId =
                              'placeholder__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';

                          if (targetSlot < box.pokemonIds.length && box.pokemonIds[targetSlot].isEmpty) {
                            box.pokemonIds[targetSlot] = instanceId;
                          } else {
                            BoxSequenceManager.insertWithShiftAndOverflow(
                              dex: liveDex,
                              boxIndex: currentBoxIndex,
                              slotIndex: targetSlot,
                              pokemonId: instanceId,
                            );
                          }

                          if (!_isEditMode) {
                            DatabaseService.instance.saveUserDex(liveDex);
                          }
                        } else {
                          final isShinySelection = selectedId.startsWith('shiny:');
                          final cleanSelectedId = isShinySelection ? selectedId.substring(6) : selectedId;
                          DexLogicHelper.ensurePrimaryInstancePersisted(liveDex, cleanSelectedId);
                          final instanceId =
                              '${cleanSelectedId}__${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';

                          if (targetSlot < box.pokemonIds.length && box.pokemonIds[targetSlot].isEmpty) {
                            box.pokemonIds[targetSlot] = instanceId;
                          } else {
                            BoxSequenceManager.insertWithShiftAndOverflow(
                              dex: liveDex,
                              boxIndex: currentBoxIndex,
                              slotIndex: targetSlot,
                              pokemonId: instanceId,
                            );
                          }

                          if (isShinySelection && !liveDex.shinyIds.contains(instanceId)) {
                            liveDex.shinyIds.add(instanceId);
                            DatabaseService.instance.savePokemonStatus(liveDex.id, instanceId, isShiny: true);
                          } else if (!isShinySelection && liveDex.shinyIds.contains(instanceId)) {
                            liveDex.shinyIds.remove(instanceId);
                            DatabaseService.instance.savePokemonStatus(liveDex.id, instanceId, isShiny: false);
                          }

                          if (!_isEditMode) {
                            DatabaseService.instance.saveUserDex(liveDex);
                          }
                        }
                      }
                    });
                    _recalculateBoxesAsync(liveDex);
                  }
                },
              ),
            if (!_isEditMode)
              IconButton(
                icon: const Icon(Icons.checklist),
                tooltip: t.box_edit_manage_content,
                onPressed: () {
                  setState(() {
                    _wasCustomBoxesEmptyOriginally = liveDex.customBoxes.isEmpty;
                    if (liveDex.customBoxes.isEmpty) {
                      _ensureCustomBoxesInitialized(liveDex);
                    }
                    _customBoxesSnapshot =
                        liveDex.customBoxes.map((b) => b.copyWith()).toList();
                    _isEditMode = true;
                    _isBoxView = true;
                  });
                },
              ),
            if (!_isEditMode)
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: t.box_edit_title,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BoxEditScreen(dex: liveDex, initialBoxes: _boxes),
                    ),
                  );
                  // Neu berechnen, falls Boxen verschoben/gelöscht/umbenannt wurden
                  if (mounted) {
                    setState(() {});
                    _recalculateBoxesAsync(liveDex);
                  }
                },
              ),
            if (!_isEditMode)
              IconButton(
                icon: const Icon(Icons.location_on),
                tooltip: Translator.get('route_tracker'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteTrackerScreen(
                        liveDex: liveDex,
                        displayEntries: _rawEntries,
                      ),
                    ),
                  );
                },
              ),
            if (!_isEditMode)
              PopupMenuButton<String>(
              key: _sortMenuKey,
              icon: const Icon(Icons.sort),
              tooltip: Translator.get('tooltip_view_sort'),
              onSelected: (value) {
                if (value == 'toggle_view') _toggleBoxView();
                if (value == 'toggle_sort') _toggleSeparateForms();
                if (value == 'advanced_sort') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DexSortSettingsScreen(dex: liveDex),
                    ),
                  ).then((_) {
                    _recalculateBoxesAsync(liveDex);
                  });
                }
                if (value == 'ignored_list') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IgnoredListScreen(
                        dexId: liveDex.id,
                        allRawEntries: _rawEntries,
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_view',
                  child: Row(
                    children: [
                      Icon(
                        _isBoxView ? Icons.list : Icons.grid_view,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isBoxView
                              ? Translator.get('view_list')
                              : Translator.get('view_box'),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_sort',
                  child: Row(
                    children: [
                      Icon(
                        _separateForms
                            ? Icons.format_list_numbered
                            : Icons.category,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _separateForms
                              ? Translator.get('sort_dex')
                              : Translator.get('sort_forms'),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'advanced_sort',
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Translator.get(
                            'advanced_sort_title',
                            fallback: 'Erweiterte Sortierung',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'ignored_list',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_off, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Translator.get(
                            'ignored_list_title',
                            fallback: 'Ausgeblendete Pokemon',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isEditMode) ...[
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: t.cancel,
                onPressed: () => _handleCancelEditMode(liveDex),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: t.save,
                onPressed: () => _handleSaveEditMode(liveDex),
              ),
            ],
          ],
        ),
      body: Stack(
        children: [
          bodyContent,
          if (_showFakeMenu)
            Positioned(
              top: 0,
              right: 8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        key: _fakeMenuBoxKey,
                        onTap: () {
                          setState(() => _showFakeMenu = false);
                          _toggleBoxView();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _isBoxView ? Icons.list : Icons.grid_view,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBoxView
                                    ? Translator.get('view_list')
                                    : Translator.get('view_box'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        key: _fakeMenuFormsKey,
                        onTap: () {
                          _toggleSeparateForms();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _separateForms
                                    ? Icons.format_list_numbered
                                    : Icons.category,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _separateForms
                                    ? Translator.get('sort_dex')
                                    : Translator.get('sort_forms'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () {
                          setState(() => _showFakeMenu = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DexSortSettingsScreen(dex: liveDex),
                            ),
                          ).then((_) {
                            _recalculateBoxesAsync(liveDex);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.tune, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                Translator.get(
                                  'advanced_sort_title',
                                  fallback: 'Erweiterte Sortierung',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        key: _fakeMenuIgnoredKey,
                        onTap: () {
                          setState(() => _showFakeMenu = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IgnoredListScreen(
                                dexId: liveDex.id,
                                allRawEntries: _rawEntries,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) _showTutorialIfNeeded();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_off, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                Translator.get(
                                  'ignored_list_title',
                                  fallback: 'Ausgeblendete Pokemon',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}





