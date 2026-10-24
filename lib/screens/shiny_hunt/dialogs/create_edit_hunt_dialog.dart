import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/pokemon.dart';
import '../../../models/shiny_hunt.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/shiny_hunt_provider.dart';
import '../../../utils/shiny_hunt_odds_helper.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../utils/dex_logic_helper.dart';
import '../../../services/database_service.dart';
import '../../../l10n/app_translations.dart';
import '../../../widgets/universal_poke_image.dart';
import '../../../models/tutorial_step.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';
import '../../../providers/tutorial_provider.dart';

class CreateEditHuntDialog extends StatefulWidget {
  final ShinyHunt? existingHunt;
  final int? initialPokemonId;
  final String? initialPokemonName;
  final int? initialFormId;
  final String? initialGame;
  final double? initialGeneration;
  final String? initialMethod;
  final double? initialBaseOdds;
  final int? initialSpawns;
  final String? initialDexId;
  final String? initialUniqueId;

  const CreateEditHuntDialog({
    super.key,
    this.existingHunt,
    this.initialPokemonId,
    this.initialPokemonName,
    this.initialFormId,
    this.initialGame,
    this.initialGeneration,
    this.initialMethod,
    this.initialBaseOdds,
    this.initialSpawns,
    this.initialDexId,
    this.initialUniqueId,
  });

  @override
  State<CreateEditHuntDialog> createState() => _CreateEditHuntDialogState();
}

class _GameOption {
  final String name;
  final double generation;
  final String label;

  const _GameOption({
    required this.name,
    required this.generation,
    required this.label,
  });
}

class _CreateEditHuntDialogState extends State<CreateEditHuntDialog> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _pokemonSectionKey = GlobalKey();
  final GlobalKey _gameMethodSectionKey = GlobalKey();
  final GlobalKey _paramsSectionKey = GlobalKey();
  final GlobalKey _saveBtnKey = GlobalKey();

  static const List<_GameOption> _allGames = [
    _GameOption(name: 'Rot / Blau / Gelb', generation: 1.0, label: 'Gen 1: Rot / Blau / Gelb'),
    _GameOption(name: 'Gold / Silber / Kristall', generation: 2.0, label: 'Gen 2: Gold / Silber / Kristall'),
    _GameOption(name: 'Rubin / Saphir / Smaragd', generation: 3.0, label: 'Gen 3: Rubin / Saphir / Smaragd'),
    _GameOption(name: 'Feuerrot / Blattgrün', generation: 3.0, label: 'Gen 3: Feuerrot / Blattgrün'),
    _GameOption(name: 'Diamant / Perl / Platin', generation: 4.0, label: 'Gen 4: Diamant / Perl / Platin'),
    _GameOption(name: 'HeartGold / SoulSilver', generation: 4.0, label: 'Gen 4: HeartGold / SoulSilver'),
    _GameOption(name: 'Strahlender Diamant / Leuchtende Perle', generation: 4.0, label: 'Gen 4 Remake: SD / LP (BDSP)'),
    _GameOption(name: 'Schwarz / Weiß', generation: 5.0, label: 'Gen 5: Schwarz / Weiß'),
    _GameOption(name: 'Schwarz 2 / Weiß 2', generation: 5.0, label: 'Gen 5: Schwarz 2 / Weiß 2'),
    _GameOption(name: 'X / Y', generation: 6.0, label: 'Gen 6: X / Y'),
    _GameOption(name: 'Omega Rubin / Alpha Saphir', generation: 6.0, label: 'Gen 6: Omega Rubin / Alpha Saphir'),
    _GameOption(name: 'Sonne / Mond', generation: 7.0, label: 'Gen 7: Sonne / Mond'),
    _GameOption(name: 'Ultra Sonne / Ultra Mond', generation: 7.0, label: 'Gen 7: Ultra Sonne / Ultra Mond'),
    _GameOption(name: "Let's Go, Pikachu! / Evoli!", generation: 7.5, label: "Gen 7.5: Let's Go"),
    _GameOption(name: 'Schwert / Schild', generation: 8.0, label: 'Gen 8: Schwert / Schild'),
    _GameOption(name: 'Legenden: Arceus', generation: 8.5, label: 'Gen 8.5: Legenden: Arceus'),
    _GameOption(name: 'Karmesin / Purpur', generation: 9.0, label: 'Gen 9: Karmesin / Purpur'),
    _GameOption(name: 'Legenden: Z-A', generation: 9.5, label: 'Gen 9.5: Legenden: Z-A'),
  ];

  static double _getMinGenForPokemon(int id) {
    if (id <= 151) return 1.0;
    if (id <= 251) return 2.0;
    if (id <= 386) return 3.0;
    if (id <= 493) return 4.0;
    if (id <= 649) return 5.0;
    if (id <= 721) return 6.0;
    if (id <= 809) return 7.0;
    if (id <= 905) return 8.0;
    return 9.0;
  }

  static bool _isGameAvailableForPokemon(_GameOption game, int? pokemonId) {
    if (pokemonId == null) return true;
    final minGen = _getMinGenForPokemon(pokemonId);
    if (game.generation < minGen) return false;
    if (game.generation == 7.5 || game.name.contains("Let's Go")) {
      return pokemonId <= 151 || pokemonId == 808 || pokemonId == 809;
    }
    if (ShinyHuntOddsHelper.isBDSP(game.name)) {
      return pokemonId <= 493;
    }
    if (game.generation == 8.5 || game.name.contains('Arceus')) {
      return pokemonId <= 905;
    }
    return true;
  }

  List<_GameOption> get _availableGames =>
      _allGames.where((g) => _isGameAvailableForPokemon(g, _pokemonId)).toList();

  late TextEditingController _titleController;
  late TextEditingController _customOddsController;
  late TextEditingController _spawnsController;
  late TextEditingController _stepController;

  int? _pokemonId;
  String _pokemonName = '';
  int? _pokemonFormId;
  String? _selectedHuntingType;

  String? _selectedDexId;
  String? _targetUniqueId;

  late String _selectedGame;
  late double _generation;
  bool _showGameSelector = false;

  String? _selectedMethod;
  bool _hasShinyCharm = false;
  bool _isChainPrepared = false;
  double _baseOdds = 4096.0;
  int _spawnsPerEncounter = 1;
  int _incrementStep = 1;

  List<ShinyMethodPreset> _availablePresets = [];
  bool _isInitialDexChecked = false;
  List<String> _shinyCategories = [];
  Map<String, Map<String, List<String>>>? _encounters;

  Future<void> _loadPokemonMetadata(int pokeId) async {
    try {
      final cats = await DatabaseService.instance.getShinyCategories(pokeId);
      final encs = await DatabaseService.instance.getEncounters(pokeId);
      if (mounted && _pokemonId == pokeId) {
        setState(() {
          _shinyCategories = cats;
          _encounters = encs;
          _updatePresets();
        });
      }
    } catch (_) {}
  }

  void _onPokemonSelected(int pokeId, String name) {
    setState(() {
      _pokemonId = pokeId;
      _pokemonName = name;
      DexProvider? dexProvider;
      try {
        dexProvider = Provider.of<DexProvider>(context, listen: false);
      } catch (_) {}
      final forms = dexProvider?.allPokemon.where((p) => p.id == pokeId).firstOrNull?.forms ?? [];
      _pokemonFormId = forms.isNotEmpty
          ? (forms.first.imageId > 0 ? forms.first.imageId : pokeId)
          : pokeId;

      final form = forms.firstOrNull;
      if (form != null) {
        _targetUniqueId = '${pokeId}_${form.name}';
      } else {
        _targetUniqueId = '${pokeId}_normal';
      }

      final games = _availableGames;
      if (!games.any((g) => g.name == _selectedGame)) {
        final fallbackGame = games.isNotEmpty ? games.first : _allGames.last;
        _selectedGame = fallbackGame.name;
        _generation = fallbackGame.generation;
      }
      _updatePresets();
      _titleController.text = _generateSuggestedTitle(forms: forms);
    });
    _loadPokemonMetadata(pokeId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialDexChecked) {
      _isInitialDexChecked = true;
      if (_selectedDexId == null && widget.existingHunt == null && widget.initialDexId == null) {
        final dexProvider = Provider.of<DexProvider>(context, listen: false);
        if (dexProvider.userDexes.isNotEmpty) {
          final shinyDex = dexProvider.userDexes.where((d) => d.isShinyDex).firstOrNull;
          _selectedDexId = (shinyDex ?? dexProvider.userDexes.first).id;
        }
      }
      if (_selectedDexId != null && widget.existingHunt == null) {
        final dexProvider = Provider.of<DexProvider>(context, listen: false);
        final dex = dexProvider.userDexes.where((d) => d.id == _selectedDexId).firstOrNull;
        if (dex != null) {
          if (dex.region != 'national' && !dex.region.contains('national')) {
            final detected = ShinyHuntOddsHelper.detectGameAndGenForDex(dex.region);
            _selectedGame = detected.game;
            _generation = detected.generation;
            _showGameSelector = false;
          } else {
            _showGameSelector = true;
          }
        }
      }

      // Ensure _selectedGame is available for _pokemonId
      final games = _availableGames;
      if (games.isNotEmpty && !games.any((g) => g.name == _selectedGame)) {
        final fallback = games.first;
        _selectedGame = fallback.name;
        _generation = fallback.generation;
      }

      if (_pokemonId != null && (_pokemonFormId == null || _pokemonFormId == 0)) {
        final dexProvider = Provider.of<DexProvider>(context, listen: false);
        final forms = dexProvider.allPokemon.where((p) => p.id == _pokemonId).firstOrNull?.forms ?? [];
        if (forms.isNotEmpty) {
          _pokemonFormId = forms.first.imageId > 0 ? forms.first.imageId : _pokemonId;
        }
      }

      if (_pokemonId != null && (_targetUniqueId == null || _targetUniqueId!.isEmpty)) {
        final dexProvider = Provider.of<DexProvider>(context, listen: false);
        final forms = dexProvider.allPokemon.where((p) => p.id == _pokemonId).firstOrNull?.forms ?? [];
        final matched = forms.where((f) => (f.imageId > 0 ? f.imageId : _pokemonId!) == _pokemonFormId).firstOrNull ?? forms.firstOrNull;
        if (matched != null) {
          _targetUniqueId = '${_pokemonId}_${matched.name}';
        } else {
          _targetUniqueId = '${_pokemonId}_normal';
        }
      }

      _updatePresets();

      if (_availablePresets.isNotEmpty && widget.initialMethod == null && widget.existingHunt == null) {
        _selectedMethod = _availablePresets.first.name;
        _baseOdds = _availablePresets.first.effectiveOdds(_hasShinyCharm);
        _spawnsPerEncounter = _availablePresets.first.defaultSpawns;
        _customOddsController.text = _formatOddsNumber(_baseOdds);
        _spawnsController.text = _spawnsPerEncounter.toString();
        _titleController.text = _generateSuggestedTitle();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _customOddsController = TextEditingController();
    _spawnsController = TextEditingController();
    _stepController = TextEditingController();

    final hunt = widget.existingHunt;
    if (hunt != null) {
      _pokemonId = hunt.pokemonId;
      _pokemonName = hunt.pokemonName;
      _pokemonFormId = hunt.pokemonFormId;
      _selectedHuntingType = hunt.huntingType;
      _selectedDexId = hunt.targetDexId;
      _targetUniqueId = hunt.targetUniqueId;
      _selectedGame = hunt.game;
      _generation = hunt.generation;
      _selectedMethod = hunt.method;
      _hasShinyCharm = hunt.hasShinyCharm;
      _baseOdds = hunt.baseOdds;
      _spawnsPerEncounter = hunt.spawnsPerEncounter;
      _incrementStep = hunt.incrementStep;
      _showGameSelector = true;
      _loadPokemonMetadata(_pokemonId!);
    } else {
      _pokemonId = widget.initialPokemonId;
      _pokemonName = widget.initialPokemonName ?? '';
      _pokemonFormId = widget.initialFormId;
      _selectedHuntingType = null;
      _selectedDexId = widget.initialDexId;
      _targetUniqueId = widget.initialUniqueId;

      if (widget.initialGame != null) {
        _selectedGame = widget.initialGame!;
        _generation = widget.initialGeneration ?? 9.0;
        _showGameSelector = false;
      } else if (widget.initialGeneration != null) {
        _generation = widget.initialGeneration!;
        _selectedGame = _defaultGameForGen(_generation);
        _showGameSelector = false;
      } else if (_selectedDexId != null) {
        // Smart Regionaldex Erkennung
        final detected = ShinyHuntOddsHelper.detectGameAndGenForDex(_selectedDexId!);
        _selectedGame = detected.game;
        _generation = detected.generation;
        _showGameSelector = false;
      } else {
        _selectedGame = 'Karmesin / Purpur';
        _generation = 9.0;
        _showGameSelector = true;
      }

      // Check if _selectedGame is valid for _pokemonId
      if (_pokemonId != null) {
        final games = _availableGames;
        if (games.isNotEmpty && !games.any((g) => g.name == _selectedGame)) {
          _selectedGame = games.first.name;
          _generation = games.first.generation;
        }
        _loadPokemonMetadata(_pokemonId!);
      }

      _hasShinyCharm = false;
      _incrementStep = 1;
      _updatePresets();

      if (widget.initialMethod != null) {
        _selectedMethod = widget.initialMethod!;
        final matchPreset = _availablePresets
            .where((p) => p.name.toLowerCase() == widget.initialMethod!.toLowerCase())
            .firstOrNull;
        if (matchPreset != null) {
          _baseOdds = widget.initialBaseOdds ?? matchPreset.effectiveOdds(_hasShinyCharm);
          _spawnsPerEncounter = widget.initialSpawns ?? matchPreset.defaultSpawns;
        } else {
          _baseOdds = widget.initialBaseOdds ?? 4096.0;
          _spawnsPerEncounter = widget.initialSpawns ?? 1;
        }
      } else if (_availablePresets.isNotEmpty) {
        _selectedMethod = _availablePresets.first.name;
        _baseOdds = _availablePresets.first.effectiveOdds(_hasShinyCharm);
        _spawnsPerEncounter = _availablePresets.first.defaultSpawns;
      } else {
        _selectedMethod = 'Standard Wild';
        _baseOdds = 4096.0;
        _spawnsPerEncounter = 1;
      }
    }

    _titleController.text = hunt?.title ?? _generateSuggestedTitle();
    _customOddsController.text = _formatOddsNumber(_baseOdds);
    _spawnsController.text = _spawnsPerEncounter.toString();
    _stepController.text = _incrementStep.toString();

    _updatePresets();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TutorialProvider? tut;
      try {
        tut = Provider.of<TutorialProvider>(context, listen: false);
      } catch (_) {}
      if (tut != null && !tut.hasSeenFeature('create_hunt_dialog')) {
        TutorialOverlay.show(
          context,
          TutorialFeature(
            id: 'create_hunt_dialog',
            nameKey: 'tutorial_hunt_pokemon_title',
            steps: [
              TutorialStep(
                targetKey: _pokemonSectionKey,
                titleKey: 'tutorial_hunt_pokemon_title',
                textKey: 'tutorial_hunt_pokemon_text',
              ),
              TutorialStep(
                targetKey: _gameMethodSectionKey,
                titleKey: 'tutorial_hunt_game_method_title',
                textKey: 'tutorial_hunt_game_method_text',
              ),
              TutorialStep(
                targetKey: _paramsSectionKey,
                titleKey: 'tutorial_hunt_params_title',
                textKey: 'tutorial_hunt_params_text',
              ),
              TutorialStep(
                targetKey: _saveBtnKey,
                titleKey: 'tutorial_hunt_save_title',
                textKey: 'tutorial_hunt_save_text',
              ),
            ],
          ),
          () => tut?.markFeatureAsSeen('create_hunt_dialog'),
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customOddsController.dispose();
    _spawnsController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  String _formatOddsNumber(double odds) {
    if (odds == odds.roundToDouble()) {
      return odds.toInt().toString();
    }
    return odds.toStringAsFixed(2);
  }

  static String _defaultGameForGen(double gen) {
    if (gen == 1.0) return 'Rot / Blau / Gelb';
    if (gen == 2.0) return 'Gold / Silber / Kristall';
    if (gen == 3.0) return 'Rubin / Saphir / Smaragd';
    if (gen == 4.0) return 'Diamant / Perl / Platin';
    if (gen == 5.0) return 'Schwarz / Weiß';
    if (gen == 6.0) return 'X / Y';
    if (gen == 7.0) return 'Ultra Sonne / Ultra Mond';
    if (gen == 7.5) return "Let's Go, Pikachu! / Evoli!";
    if (gen == 8.0) return 'Schwert / Schild';
    if (gen == 8.5) return 'Legenden: Arceus';
    if (gen == 9.0) return 'Karmesin / Purpur';
    if (gen == 9.5) return 'Legenden: Z-A';
    return 'Karmesin / Purpur';
  }

  String _generateSuggestedTitle({List<PokemonForm>? forms}) {
    if (_pokemonName.isEmpty) return 'Shiny Hunt';
    String formSuffix = '';
    if (_pokemonFormId != null && _pokemonFormId != _pokemonId) {
      List<PokemonForm> formList = forms ?? [];
      if (formList.isEmpty && _pokemonId != null) {
        try {
          final dexProvider = Provider.of<DexProvider>(context, listen: false);
          formList = dexProvider.allPokemon.where((p) => p.id == _pokemonId).firstOrNull?.forms ?? [];
        } catch (_) {}
      }
      final matchedForm = formList.where((f) => (f.imageId > 0 ? f.imageId : _pokemonId) == _pokemonFormId).firstOrNull;
      if (matchedForm != null && matchedForm.name != 'normal') {
        formSuffix = ' (${DexLogicHelper.getFormDisplayName(matchedForm.name)})';
      }
    }
    return '$_pokemonName$formSuffix ($_selectedGame)';
  }

  void _updatePresets() {
    final rawPresets = ShinyHuntOddsHelper.getPresetsForGameAndGen(_selectedGame, _generation);
    if (_pokemonId == null) {
      _availablePresets = rawPresets;
      return;
    }

    DexProvider? dexProvider;
    try {
      dexProvider = Provider.of<DexProvider>(context, listen: false);
    } catch (_) {}

    final pokemon = dexProvider?.allPokemon.where((p) => p.id == _pokemonId).firstOrNull;

    final isLegendary = ShinyHuntOddsHelper.isLegendaryOrMythicalId(_pokemonId!) ||
        _shinyCategories.contains('legendary_mythical');

    final isBreedable = ShinyHuntOddsHelper.isBreedablePokemon(pokemon, _pokemonId);

    final isGenderless = pokemon != null ? pokemon.genderRate == -1 : false;

    bool hasRadarEncounter = false;
    bool hasFishingEncounter = false;
    if (_encounters != null) {
      final genKey = _generation == 4.0 ? 'gen_4' : (_generation == 6.0 ? 'gen_6' : null);
      if (genKey != null && _encounters!.containsKey(genKey)) {
        final genData = _encounters![genKey]!;
        for (var ver in genData.keys) {
          for (var loc in genData[ver]!) {
            final l = loc.toLowerCase();
            if (l.contains('radar') ||
                l.contains('grass') ||
                l.contains('walk') ||
                l.contains('gras')) {
              hasRadarEncounter = true;
            }
            if (l.contains('fish') ||
                l.contains('angel') ||
                l.contains('rod') ||
                l.contains('surfen') ||
                l.contains('surf')) {
              hasFishingEncounter = true;
            }
          }
        }
      }
    }

    _availablePresets = rawPresets.where((preset) {
      final nameLower = preset.name.toLowerCase();

      // Custom preset is always available
      if (nameLower.contains('benutzerdefiniert') || nameLower.contains('custom')) {
        return true;
      }

      // If legendary / mythical: ONLY Soft Reset / Wild and Dynamax Adventures are valid!
      if (isLegendary) {
        if (nameLower.contains('dynamax')) return true;
        if (nameLower.contains('soft reset') ||
            nameLower.contains('wild') ||
            nameLower.contains('standard')) {
          if (nameLower.contains('starter') ||
              nameLower.contains('ausbruch') ||
              nameLower.contains('outbreak') ||
              nameLower.contains('sandwich') ||
              nameLower.contains('radar') ||
              nameLower.contains('schillerkraft') ||
              nameLower.contains('doppelgras') ||
              nameLower.contains('safari') ||
              nameLower.contains('untergrund') ||
              nameLower.contains('fishing') ||
              nameLower.contains('surfen') ||
              nameLower.contains('dexnav') ||
              nameLower.contains('sos') ||
              nameLower.contains('fangserie') ||
              nameLower.contains('ko-methode')) {
            return false;
          }
          return true;
        }
        return false;
      }

      // 1. Zucht / Masuda: Pokémon must be breedable
      if (nameLower.contains('masuda') ||
          nameLower.contains('zucht') ||
          nameLower.contains('breeding') ||
          nameLower.contains('ditto-glitch')) {
        if (!isBreedable) return false;
      }

      // 2. Odd Egg: only baby Pokémon in Gen 2
      if (nameLower.contains('odd egg') || nameLower.contains('kurioses ei')) {
        if (!ShinyLogicHelper.isBaby(_pokemonId!)) return false;
      }

      // 3. Cute Charm Glitch: only works if Pokémon has gender, is breedable, and not legendary
      if (nameLower.contains('cute charm')) {
        if (isGenderless || isLegendary || !isBreedable) return false;
      }

      // 4. HGSS Starter Soft Reset: only #152, #155, #158
      if (nameLower.contains('hgss starter')) {
        if (_pokemonId != 152 && _pokemonId != 155 && _pokemonId != 158) {
          return false;
        }
      }

      // 5. Poké-Radar: only if not legendary and has radar encounter
      if (nameLower.contains('radar')) {
        if (isLegendary) return false;
        if (_encounters != null && !hasRadarEncounter) {
          return false;
        }
      }

      // 6. Chain Fishing / Kettensurfen: only if fishing encounter exists
      if (nameLower.contains('fishing') || nameLower.contains('kettensurf')) {
        if (_encounters != null && !hasFishingEncounter) {
          return false;
        }
      }

      // 7. Silph Scope / Pokémon-Turm: only for #92, #93, #104, #105
      if (nameLower.contains('silph scope') || nameLower.contains('pokémon-turm')) {
        if (![92, 93, 104, 105].contains(_pokemonId)) {
          return false;
        }
      }

      return true;
    }).toList();

    if (_generation == 1.0 && [92, 93, 104, 105].contains(_pokemonId)) {
      _availablePresets.sort((a, b) {
        final aIsSilph = a.name.toLowerCase().contains('silph scope') || a.name.toLowerCase().contains('pokémon-turm');
        final bIsSilph = b.name.toLowerCase().contains('silph scope') || b.name.toLowerCase().contains('pokémon-turm');
        if (aIsSilph && !bIsSilph) return -1;
        if (!aIsSilph && bIsSilph) return 1;
        return 0;
      });
    }

    final currentMethod = _selectedMethod;
    if (currentMethod == null || !_availablePresets.any((p) => p.name == currentMethod)) {
      if (_availablePresets.isNotEmpty) {
        _selectedMethod = _availablePresets.first.name;
        _baseOdds = _availablePresets.first.effectiveOdds(_hasShinyCharm);
        _spawnsPerEncounter = _availablePresets.first.defaultSpawns;
        if (mounted) {
          _customOddsController.text = _formatOddsNumber(_baseOdds);
          _spawnsController.text = _spawnsPerEncounter.toString();
        }
      }
    }
  }

  void _onGameChanged(String newGame, double newGen) {
    setState(() {
      _selectedGame = newGame;
      _generation = newGen;
      _updatePresets();
      if (_availablePresets.isNotEmpty) {
        _selectedMethod = _availablePresets.first.name;
        _onPresetSelected(_availablePresets.first);
      }
      _titleController.text = _generateSuggestedTitle();
    });
  }

  void _onPresetSelected(ShinyMethodPreset preset) {
    setState(() {
      _selectedMethod = preset.name;
      final charmApplies = ShinyHuntOddsHelper.isShinyCharmApplicable(_selectedGame, preset.name, _generation);
      if (preset.isChainMethod && !_isChainPrepared) {
        _baseOdds = (_generation <= 4.0 || ShinyHuntOddsHelper.isBDSP(_selectedGame)) ? 8192.0 : 4096.0;
      } else {
        _baseOdds = preset.effectiveOdds(_hasShinyCharm && charmApplies);
      }
      _spawnsPerEncounter = preset.defaultSpawns;
      _customOddsController.text = _formatOddsNumber(_baseOdds);
      _spawnsController.text = _spawnsPerEncounter.toString();
    });
  }

  void _onCharmToggled(bool value) {
    setState(() {
      _hasShinyCharm = value;
      final charmApplies = ShinyHuntOddsHelper.isShinyCharmApplicable(_selectedGame, _selectedMethod ?? '', _generation);
      final currentPreset = _availablePresets.firstWhere(
        (p) => p.name == _selectedMethod,
        orElse: () => _availablePresets.first,
      );
      if (currentPreset.isChainMethod && !_isChainPrepared) {
        _baseOdds = (_generation <= 4.0 || ShinyHuntOddsHelper.isBDSP(_selectedGame)) ? 8192.0 : 4096.0;
      } else {
        _baseOdds = currentPreset.effectiveOdds(value && charmApplies);
      }
      _customOddsController.text = _formatOddsNumber(_baseOdds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dexProvider = Provider.of<DexProvider>(context);
    final allPokemon = dexProvider.allPokemon;
    final currentPokemon = allPokemon.where((p) => p.id == _pokemonId).firstOrNull;
    final availableForms = currentPokemon?.forms ?? [];
    final lang = Translator.currentLanguage;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final specialNote = ShinyHuntOddsHelper.getSpecialNote(
      game: _selectedGame,
      method: _selectedMethod ?? '',
      generation: _generation,
      hasShinyCharm: _hasShinyCharm,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.track_changes, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.existingHunt != null
                            ? Translator.get('shiny_hunt_dialog_edit_title')
                            : Translator.get('shiny_hunt_dialog_create_title'),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                  KeyedSubtree(
                    key: _pokemonSectionKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Pokémon Auswahl
                        if (_pokemonId == null) ...[
                    Autocomplete<Pokemon>(
                      displayStringForOption: (option) => option.getName(lang),
                      optionsBuilder: (textEditingValue) {
                        final query = textEditingValue.text.trim().toLowerCase();
                        if (query.isEmpty) return const Iterable<Pokemon>.empty();
                        return allPokemon.where((p) {
                          final de = p.nameDe.toLowerCase();
                          final en = p.nameEn.toLowerCase();
                          final id = p.id.toString();
                          return de.contains(query) || en.contains(query) || id == query;
                        }).take(10);
                      },
                      onSelected: (selection) {
                        _onPokemonSelected(selection.id, selection.getName(lang));
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: Translator.get('shiny_hunt_target_pokemon'),
                            hintText: 'Pokémon suchen...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          validator: (v) => _pokemonId == null ? 'Bitte ein Pokémon auswählen' : null,
                        );
                      },
                    ),
                  ] else ...[
                    // Ausgewähltes Pokémon Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              UniversalPokeImage(
                                imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/${(_pokemonFormId != null && _pokemonFormId! > 0) ? _pokemonFormId : _pokemonId}.png',
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pokemonName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      '#$_pokemonId',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.existingHunt == null)
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Anderes Pokémon wählen',
                                  onPressed: () {
                                    setState(() {
                                      _pokemonId = null;
                                      _pokemonFormId = null;
                                      _targetUniqueId = null;
                                      _shinyCategories = [];
                                      _encounters = null;
                                      _updatePresets();
                                    });
                                  },
                                ),
                            ],
                          ),
                          Builder(
                            builder: (context) {
                              final seenFormIds = <int>{};
                              final uniqueForms = availableForms.where((f) {
                                final imgId = f.imageId > 0 ? f.imageId : (_pokemonId ?? 0);
                                return seenFormIds.add(imgId);
                              }).toList();

                              if (uniqueForms.length <= 1) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: _pokemonFormId != null && uniqueForms.any((f) => (f.imageId > 0 ? f.imageId : _pokemonId!) == _pokemonFormId)
                                      ? _pokemonFormId
                                      : (uniqueForms.first.imageId > 0 ? uniqueForms.first.imageId : _pokemonId),
                                  decoration: InputDecoration(
                                    labelText: Translator.get('shiny_hunt_form_label', fallback: 'Form'),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: uniqueForms.map((form) {
                                    final formImgId = form.imageId > 0 ? form.imageId : _pokemonId!;
                                    final formTitle = DexLogicHelper.getFormDisplayName(form.name);
                                    return DropdownMenuItem<int>(
                                      value: formImgId,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          UniversalPokeImage(
                                            imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$formImgId.png',
                                            width: 24,
                                            height: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(formTitle),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newFormId) {
                                    setState(() {
                                      _pokemonFormId = newFormId;
                                      if (_pokemonId != null) {
                                        final matchedForm = uniqueForms.where((f) => (f.imageId > 0 ? f.imageId : _pokemonId!) == newFormId).firstOrNull;
                                        if (matchedForm != null) {
                                          _targetUniqueId = '${_pokemonId}_${matchedForm.name}';
                                        } else {
                                          _targetUniqueId = '${_pokemonId}_normal';
                                        }
                                      }
                                      _titleController.text = _generateSuggestedTitle(forms: uniqueForms);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Titel / Notiz
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: Translator.get('shiny_hunt_title_field'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ziel-Dex Auswahl (Smart Defaults)
                  if (dexProvider.userDexes.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: dexProvider.userDexes.any((d) => d.id == _selectedDexId)
                          ? _selectedDexId
                          : null,
                      decoration: InputDecoration(
                        labelText: Translator.get('shiny_hunt_target_dex'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(Translator.get('shiny_hunt_target_dex_none', fallback: 'Kein Dex (Nicht verknüpft)')),
                        ),
                        ...dexProvider.userDexes.map((d) => DropdownMenuItem<String?>(
                          value: d.id,
                          child: Text(d.title),
                        )),
                      ],
                      onChanged: (newDexId) {
                        setState(() {
                          _selectedDexId = newDexId;
                          if (newDexId != null) {
                            final dex = dexProvider.userDexes.firstWhere((d) => d.id == newDexId);
                            if (dex.region != 'national' && !dex.region.contains('national')) {
                              final detected = ShinyHuntOddsHelper.detectGameAndGenForDex(dex.region);
                              _selectedGame = detected.game;
                              _generation = detected.generation;
                              _showGameSelector = false;
                              _updatePresets();
                              if (_availablePresets.isNotEmpty) {
                                _onPresetSelected(_availablePresets.first);
                              }
                            } else {
                              _showGameSelector = true;
                            }
                          } else {
                            _showGameSelector = true;
                          }
                          _titleController.text = _generateSuggestedTitle();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  KeyedSubtree(
                    key: _gameMethodSectionKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 2. Spiel / Edition & Smart Skip
                        if (!_showGameSelector) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sports_esports, color: Colors.blueAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Spiel: $_selectedGame (Gen ${_generation.toString().replaceAll('.0', '')})',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => _showGameSelector = true),
                                  child: const Text('Ändern'),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            key: ValueKey('game-$_selectedGame-$_generation-${_availableGames.length}'),
                            initialValue: _availableGames.any((g) => g.name == _selectedGame)
                                ? _selectedGame
                                : (_availableGames.isNotEmpty ? _availableGames.first.name : null),
                            decoration: InputDecoration(
                              labelText: Translator.get('shiny_hunt_game'),
                              border: const OutlineInputBorder(),
                            ),
                            items: _availableGames.map((g) {
                              return DropdownMenuItem<String>(
                                value: g.name,
                                child: Text(g.label),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              final match = _availableGames.firstWhere((g) => g.name == val);
                              _onGameChanged(match.name, match.generation);
                            },
                          ),
                        ],
                        const SizedBox(height: 12),

                        // 3. Methode Dropdown
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          key: ValueKey('method-$_selectedMethod-${_availablePresets.length}'),
                          initialValue: _availablePresets.any((p) => p.name == _selectedMethod)
                              ? _selectedMethod
                              : (_availablePresets.isNotEmpty ? _availablePresets.first.name : null),
                          decoration: InputDecoration(
                            labelText: Translator.get('shiny_hunt_method'),
                            border: const OutlineInputBorder(),
                          ),
                          items: _availablePresets.map((preset) {
                            return DropdownMenuItem<String>(
                              value: preset.name,
                              child: Text(
                                preset.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (methodName) {
                            if (methodName == null) return;
                            final preset = _availablePresets.firstWhere((p) => p.name == methodName);
                            _onPresetSelected(preset);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3b. Jagdart / Herkunft
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedHuntingType ?? 'auto',
                    decoration: InputDecoration(
                      labelText: Translator.get('shiny_hunt_hunting_type', fallback: 'Jagdart / Herkunft'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'auto',
                        child: Text(Translator.get('shiny_hunt_type_auto', fallback: 'Automatisch (nach Methode)')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'wild',
                        child: Text(Translator.get('shiny_hunt_type_wild', fallback: 'Wildfang')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'breeding',
                        child: Text(Translator.get('shiny_hunt_type_breeding', fallback: 'Zucht / Ei')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'trade',
                        child: Text(Translator.get('shiny_hunt_type_trade', fallback: 'Tausch')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'soft_reset',
                        child: Text(Translator.get('shiny_hunt_type_soft_reset', fallback: 'Soft Reset')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'raid',
                        child: Text(Translator.get('shiny_hunt_type_raid', fallback: 'Raid')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'fossil',
                        child: Text(Translator.get('shiny_hunt_type_fossil', fallback: 'Fossil')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'gift',
                        child: Text(Translator.get('shiny_hunt_type_gift', fallback: 'Geschenk / Event')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'other',
                        child: Text(Translator.get('shiny_hunt_type_other', fallback: 'Sonstiges')),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedHuntingType = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Schillerpin Schalter (erst ab Gen 5 bzw. BDSP)
                  if (_generation >= 5.0 || ShinyHuntOddsHelper.isBDSP(_selectedGame)) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(Translator.get('shiny_hunt_has_charm')),
                      secondary: const Icon(Icons.flare, color: Colors.amber),
                      value: _hasShinyCharm,
                      onChanged: _onCharmToggled,
                    ),
                  ],

                  // Hinweistext (z. B. BDSP Bug)
                  if (specialNote != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              specialNote,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Checkbox Kette vorbereitet (für Kettenmethoden)
                  if (_availablePresets.any((p) => p.name == _selectedMethod && p.isChainMethod)) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(Translator.get('shiny_hunt_chain_prepared')),
                      value: _isChainPrepared,
                      onChanged: (val) {
                        setState(() {
                          _isChainPrepared = val ?? false;
                          final preset = _availablePresets.firstWhere((p) => p.name == _selectedMethod);
                          final charmApplies = ShinyHuntOddsHelper.isShinyCharmApplicable(_selectedGame, preset.name, _generation);
                          if (_isChainPrepared) {
                            _baseOdds = preset.effectiveOdds(_hasShinyCharm && charmApplies);
                          } else {
                            _baseOdds = (_generation <= 4.0 || ShinyHuntOddsHelper.isBDSP(_selectedGame)) ? 8192.0 : 4096.0;
                          }
                          _customOddsController.text = _formatOddsNumber(_baseOdds);
                        });
                      },
                    ),
                  ],

                  // Feineinstellung: Basis-Quote (1/D) und Multi-Spawns (k)
                  KeyedSubtree(
                    key: _paramsSectionKey,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _customOddsController,
                            decoration: InputDecoration(
                              labelText: Translator.get('shiny_hunt_base_odds'),
                              hintText: '4096.0',
                              border: const OutlineInputBorder(),
                              prefixText: '1 / ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) {
                              final parsed = double.tryParse(v);
                              if (parsed != null && parsed > 0) {
                                _baseOdds = parsed;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _spawnsController,
                            decoration: InputDecoration(
                              labelText: Translator.get('shiny_hunt_spawns_per_step'),
                              hintText: '1',
                              border: const OutlineInputBorder(),
                              prefixText: 'k = ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final parsed = int.tryParse(v);
                              if (parsed != null && parsed > 0) {
                                _spawnsPerEncounter = parsed;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Schrittweite Pill / Field
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Text('${Translator.get('shiny_hunt_step_label')}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...[1, 5, 10].map((step) {
                        final isSel = _incrementStep == step;
                        return ChoiceChip(
                          label: Text('+$step'),
                          selected: isSel,
                          onSelected: (_) => setState(() {
                            _incrementStep = step;
                            _stepController.text = step.toString();
                          }),
                        );
                      }),
                      if (![1, 5, 10].contains(_incrementStep))
                        ChoiceChip(
                          label: Text('+$_incrementStep'),
                          selected: true,
                          onSelected: (_) {},
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.edit, size: 14),
                        label: Text(Translator.get('shiny_hunt_step_custom', fallback: 'Custom')),
                        onPressed: () {
                            final c = TextEditingController(text: _incrementStep.toString());
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(Translator.get('shiny_hunt_step_custom_title', fallback: 'Eigene Schrittweite')),
                                content: TextField(
                                  controller: c,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    labelText: Translator.get('shiny_hunt_step_custom_hint', fallback: 'Schrittweite eingeben (z. B. 3, 30)...'),
                                    border: const OutlineInputBorder(),
                                  ),
                                  onSubmitted: (val) {
                                    final p = int.tryParse(val.trim());
                                    if (p != null && p > 0 && p <= 99999) {
                                      setState(() {
                                        _incrementStep = p;
                                        _stepController.text = p.toString();
                                      });
                                    }
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final p = int.tryParse(c.text.trim());
                                      if (p != null && p > 0 && p <= 99999) {
                                        setState(() {
                                          _incrementStep = p;
                                          _stepController.text = p.toString();
                                        });
                                      }
                                      Navigator.of(ctx).pop();
                                    },
                                    child: Text(Translator.get('save', fallback: 'Speichern')),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        key: _saveBtnKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (_pokemonId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bitte ein Pokémon auswählen')),
                            );
                            return;
                          }

                          final huntProvider = Provider.of<ShinyHuntProvider>(context, listen: false);
                          final now = DateTime.now();

                          final effectiveHuntingType = (_selectedHuntingType == null || _selectedHuntingType == 'auto')
                              ? ShinyHuntOddsHelper.inferHuntingTypeFromMethod(_selectedMethod ?? '')
                              : _selectedHuntingType;

                          String? resolvedUid = _targetUniqueId;
                          if (resolvedUid == null || resolvedUid.isEmpty) {
                            if (_pokemonId != null) {
                              DexProvider? dp;
                              try {
                                dp = Provider.of<DexProvider>(context, listen: false);
                              } catch (_) {}
                              final forms = dp?.allPokemon.where((p) => p.id == _pokemonId).firstOrNull?.forms ?? [];
                              final matched = forms.where((f) => (f.imageId > 0 ? f.imageId : _pokemonId!) == _pokemonFormId).firstOrNull ?? forms.firstOrNull;
                              if (matched != null) {
                                resolvedUid = '${_pokemonId}_${matched.name}';
                              } else {
                                resolvedUid = '${_pokemonId}_normal';
                              }
                            }
                          }

                          if (widget.existingHunt != null) {
                            final updated = widget.existingHunt!.copyWith(
                              title: _titleController.text.trim().isNotEmpty
                                  ? _titleController.text.trim()
                                  : _pokemonName,
                              pokemonFormId: (_pokemonFormId != null && _pokemonFormId! > 0)
                                  ? _pokemonFormId
                                  : _pokemonId,
                              huntingType: effectiveHuntingType,
                              game: _selectedGame,
                              generation: _generation,
                              method: _selectedMethod ?? widget.existingHunt!.method,
                              hasShinyCharm: _hasShinyCharm,
                              baseOdds: _baseOdds,
                              spawnsPerEncounter: _spawnsPerEncounter,
                              incrementStep: _incrementStep,
                              targetDexId: _selectedDexId,
                              targetUniqueId: resolvedUid,
                              updatedAt: now,
                            );
                            await huntProvider.updateHunt(updated);
                            if (context.mounted) {
                              Navigator.of(context).pop(updated);
                            }
                          } else {
                            final newHunt = ShinyHunt(
                              id: const Uuid().v4(),
                              title: _titleController.text.trim().isNotEmpty
                                  ? _titleController.text.trim()
                                  : _pokemonName,
                              pokemonId: _pokemonId!,
                              pokemonName: _pokemonName,
                              pokemonFormId: (_pokemonFormId != null && _pokemonFormId! > 0)
                                  ? _pokemonFormId
                                  : _pokemonId,
                              huntingType: effectiveHuntingType,
                              game: _selectedGame,
                              generation: _generation,
                              method: _selectedMethod ?? (_availablePresets.isNotEmpty ? _availablePresets.first.name : 'Standard Wild'),
                              hasShinyCharm: _hasShinyCharm,
                              baseOdds: _baseOdds,
                              spawnsPerEncounter: _spawnsPerEncounter,
                              incrementStep: _incrementStep,
                              targetDexId: _selectedDexId,
                              targetUniqueId: resolvedUid,
                              createdAt: now,
                              updatedAt: now,
                            );
                            await huntProvider.createHunt(newHunt);
                            if (context.mounted) {
                              Navigator.of(context).pop(newHunt);
                            }
                          }
                        },
                        child: Text(
                          widget.existingHunt != null
                              ? Translator.get('save', fallback: 'Speichern')
                              : Translator.get('start', fallback: 'Starten'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
