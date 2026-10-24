import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dex_view_models.dart';
import '../../models/pokemon.dart';
import '../../providers/dex_provider.dart';
import '../../l10n/app_translations.dart';
import '../../i18n/strings.g.dart';
import '../../utils/dex_logic_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../pokemon_info/pokemon_info_screen.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../providers/tutorial_provider.dart';

const Map<String, Color> _typeColors = {
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705848),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

class PokemonSearchSelectionScreen extends StatefulWidget {
  final List<DexDisplayEntry> allAvailableEntries;
  final String? dexId;
  final bool initialShiny;
  final bool allowNone;
  final bool showPlaceholder;

  const PokemonSearchSelectionScreen({
    super.key,
    required this.allAvailableEntries,
    this.dexId,
    this.initialShiny = false,
    this.allowNone = false,
    this.showPlaceholder = true,
  });

  @override
  State<PokemonSearchSelectionScreen> createState() =>
      _PokemonSearchSelectionScreenState();
}

class _PokemonSearchSelectionScreenState
    extends State<PokemonSearchSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  final Set<String> _selectedRegions = {};
  final Set<String> _selectedForms = {};
  final Set<String> _selectedGenders = {};
  late bool _isShinyMode;
  late List<DexDisplayEntry> _filteredEntries;

  static const List<Map<String, String>> _regions = [
    {'key': 'kanto', 'labelDe': 'Kanto', 'labelEn': 'Kanto'},
    {'key': 'johto', 'labelDe': 'Johto', 'labelEn': 'Johto'},
    {'key': 'hoenn', 'labelDe': 'Hoenn', 'labelEn': 'Hoenn'},
    {'key': 'sinnoh', 'labelDe': 'Sinnoh', 'labelEn': 'Sinnoh'},
    {'key': 'einall', 'labelDe': 'Einall', 'labelEn': 'Unova'},
    {'key': 'kalos', 'labelDe': 'Kalos', 'labelEn': 'Kalos'},
    {'key': 'alola', 'labelDe': 'Alola', 'labelEn': 'Alola'},
    {'key': 'galar', 'labelDe': 'Galar', 'labelEn': 'Galar'},
    {'key': 'hisui', 'labelDe': 'Hisui', 'labelEn': 'Hisui'},
    {'key': 'paldea', 'labelDe': 'Paldea', 'labelEn': 'Paldea'},
  ];

  static const List<Map<String, String>> _forms = [
    {'key': 'normal', 'labelDe': 'Normal', 'labelEn': 'Normal'},
    {'key': 'mega', 'labelDe': 'Mega', 'labelEn': 'Mega'},
    {'key': 'gmax', 'labelDe': 'Gigadynamax', 'labelEn': 'Gigantamax'},
    {'key': 'regional', 'labelDe': 'Regionalformen', 'labelEn': 'Regional'},
  ];

  static const List<Map<String, String>> _genders = [
    {'key': 'male', 'labelDe': 'Männlich (♂)', 'labelEn': 'Male (♂)'},
    {'key': 'female', 'labelDe': 'Weiblich (♀)', 'labelEn': 'Female (♀)'},
    {'key': 'genderless', 'labelDe': 'Geschlechtslos', 'labelEn': 'Genderless'},
    {'key': 'differences', 'labelDe': 'Unterschiede', 'labelEn': 'Differences'},
  ];

  @override
  void initState() {
    super.initState();
    _isShinyMode = widget.initialShiny;
    _filteredEntries = widget.allAvailableEntries;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TutorialProvider? tut;
      try {
        tut = Provider.of<TutorialProvider>(context, listen: false);
      } catch (_) {}
      if (tut != null && !tut.hasSeenFeature('pokemon_search_selection')) {
        TutorialOverlay.show(
          context,
          TutorialFeature(
            id: 'pokemon_search_selection',
            nameKey: 'tutorial_search_select_intro_title',
            steps: [
              TutorialStep(
                targetKey: null,
                titleKey: 'tutorial_search_select_intro_title',
                textKey: 'tutorial_search_select_intro_text',
              ),
            ],
          ),
          () => tut?.markFeatureAsSeen('pokemon_search_selection'),
        );
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = val.trim().toLowerCase();
      });
      _applyFilter();
    });
  }

  PokemonForm? _getEntryForm(DexDisplayEntry entry) {
    return entry.resolvedForm;
  }

  List<String> _getEntryTypes(DexDisplayEntry entry) {
    final form = _getEntryForm(entry);
    if (form != null && form.types.isNotEmpty) {
      return form.types;
    }
    if (entry.pokemon.forms.isNotEmpty &&
        entry.pokemon.forms.first.types.isNotEmpty) {
      return entry.pokemon.forms.first.types;
    }
    return [];
  }

  bool _matchesRegion(DexDisplayEntry entry, String regionKey) {
    final id = entry.pokemon.id;
    final form = _getEntryForm(entry);
    final formName = (form?.name ?? '').toLowerCase();

    switch (regionKey) {
      case 'kanto':
        return id >= 1 &&
            id <= 151 &&
            !formName.contains('alola') &&
            !formName.contains('galar') &&
            !formName.contains('hisui') &&
            !formName.contains('paldea');
      case 'johto':
        return id >= 152 &&
            id <= 251 &&
            !formName.contains('galar') &&
            !formName.contains('hisui') &&
            !formName.contains('paldea');
      case 'hoenn':
        return id >= 252 && id <= 386 && !formName.contains('galar');
      case 'sinnoh':
        return id >= 387 && id <= 493 && !formName.contains('hisui');
      case 'einall':
        return id >= 494 && id <= 649 && !formName.contains('hisui');
      case 'kalos':
        return id >= 650 && id <= 721;
      case 'alola':
        return (id >= 722 && id <= 809) || formName.contains('alola');
      case 'galar':
        return (id >= 810 && id <= 898) || formName.contains('galar');
      case 'hisui':
        return (id >= 899 && id <= 905) || formName.contains('hisui');
      case 'paldea':
        return (id >= 906 && id <= 1025) || formName.contains('paldea');
      default:
        return true;
    }
  }

  bool _matchesForm(DexDisplayEntry entry, String formKey) {
    final form = _getEntryForm(entry);
    final formType = (form?.formType ?? 'normal').toLowerCase();
    final formName = (form?.name ?? '').toLowerCase();

    switch (formKey) {
      case 'normal':
        return formType == 'normal' ||
            (formType == 'other' &&
                !formName.contains('mega') &&
                !formName.contains('gmax') &&
                !formName.contains('alola') &&
                !formName.contains('galar') &&
                !formName.contains('hisui') &&
                !formName.contains('paldea'));
      case 'mega':
        return formType == 'mega' || formName.contains('mega');
      case 'gmax':
        return formType == 'gmax' || formName.contains('gmax');
      case 'regional':
        return formType == 'regional' ||
            formName.contains('alola') ||
            formName.contains('galar') ||
            formName.contains('hisui') ||
            formName.contains('paldea');
      default:
        return true;
    }
  }

  String _getDisplayImageUrl(DexDisplayEntry entry, bool wantShiny) {
    String url = entry.imageUrl;
    bool isCurrentlyShiny = url.contains('/shiny/');
    if (wantShiny && !isCurrentlyShiny) {
      if (url.contains('official-artwork/')) {
        return url.replaceFirst('official-artwork/', 'official-artwork/shiny/');
      } else if (url.contains('home/female/')) {
        return url.replaceFirst('home/female/', 'home/shiny/female/');
      } else if (url.contains('home/')) {
        return url.replaceFirst('home/', 'home/shiny/');
      }
    } else if (!wantShiny && isCurrentlyShiny) {
      if (url.contains('/shiny/female/')) {
        return url.replaceFirst('/shiny/female/', '/female/');
      } else {
        return url.replaceFirst('/shiny/', '/');
      }
    }
    return url;
  }

  bool _matchesGender(DexDisplayEntry entry, String genderKey) {
    final p = entry.pokemon;
    final form = _getEntryForm(entry);
    final formName = (form?.name ?? '').toLowerCase();
    final baseId = DexLogicHelper.getBaseId(entry.uniqueId);
    final isExplicitMale = baseId.endsWith('_m') ||
        entry.displaySuffix.contains('♂') ||
        formName == 'male' ||
        formName.contains('-male');
    final isExplicitFemale = baseId.endsWith('_f') ||
        entry.displaySuffix.contains('♀') ||
        formName == 'female' ||
        formName.contains('-female');

    switch (genderKey) {
      case 'male':
        if (isExplicitFemale) return false;
        if (isExplicitMale) return true;
        return p.genderRate >= 0 && p.genderRate < 8;

      case 'female':
        if (isExplicitMale) return false;
        if (isExplicitFemale) return true;
        return p.genderRate >= 1 && p.genderRate <= 8;

      case 'genderless':
        if (isExplicitMale || isExplicitFemale) return false;
        return p.genderRate == -1;

      case 'differences':
        return p.hasGenderDifferences;

      default:
        return true;
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredEntries = widget.allAvailableEntries.where((entry) {
        // Query match
        if (_searchQuery.isNotEmpty) {
          final nameDe = entry.pokemon.nameDe.toLowerCase();
          final nameEn = entry.pokemon.nameEn.toLowerCase();
          final cleanQuery = _searchQuery.replaceAll('#', '').trim();
          final numStr = entry.pokemon.id.toString();
          final paddedId3 = numStr.padLeft(3, '0');
          final paddedId4 = numStr.padLeft(4, '0');

          final matchesName = nameDe.contains(_searchQuery) ||
              nameEn.contains(_searchQuery) ||
              nameDe.contains(cleanQuery) ||
              nameEn.contains(cleanQuery);

          final matchesNumber = cleanQuery.isNotEmpty &&
              (numStr == cleanQuery ||
               paddedId3 == cleanQuery ||
               paddedId4 == cleanQuery ||
               numStr.contains(cleanQuery) ||
               paddedId3.contains(cleanQuery));

          if (!matchesName && !matchesNumber) return false;
        }

        // Region match (multi-select: matches if any selected region matches)
        if (_selectedRegions.isNotEmpty) {
          final matchesAnyRegion = _selectedRegions.any((r) => _matchesRegion(entry, r));
          if (!matchesAnyRegion) return false;
        }

        // Form match (multi-select: matches if any selected form matches)
        if (_selectedForms.isNotEmpty) {
          final matchesAnyForm = _selectedForms.any((f) => _matchesForm(entry, f));
          if (!matchesAnyForm) return false;
        }

        // Gender match (multi-select: matches if any selected gender matches, and intersects differences with genders)
        if (_selectedGenders.isNotEmpty) {
          final hasDiff = _selectedGenders.contains('differences');
          final explicitGenders = _selectedGenders.difference({'differences'});
          if (hasDiff && explicitGenders.isNotEmpty) {
            final matchesDiff = _matchesGender(entry, 'differences');
            final matchesGender = explicitGenders.any((g) => _matchesGender(entry, g));
            if (!matchesDiff || !matchesGender) return false;
          } else {
            final matchesAnyGender = _selectedGenders.any((g) => _matchesGender(entry, g));
            if (!matchesAnyGender) return false;
          }
        }

        return true;
      }).toList();
    });
  }

  bool get _shouldShowPlaceholderCard {
    if (!widget.showPlaceholder) return false;
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase().trim();
    if (q == '#---' || q == '---') return true;
    if (q.length < 3) return false;

    final dePlaceholder =
        t.placeholder.toLowerCase();
    final deInsert =
        t.insert_placeholder.toLowerCase();

    final terms = [
      dePlaceholder,
      deInsert,
      'placeholder',
      'platzhalter',
      'leer',
      'frei',
      'gap',
      'slot',
      'empty',
      'blank',
      'space',
    ];

    return terms.any((term) => term.startsWith(q) || q.contains(term));
  }

  bool get _shouldShowNoneCard {
    if (!widget.allowNone) return false;
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase().trim();
    final terms = [
      'kein',
      'keine',
      'none',
      'ohne',
      'without',
      'watermark',
      'wasserzeichen',
      'leer',
      'frei',
      'block',
      '#---',
    ];
    return terms.any((term) => term.startsWith(q) || q.contains(term));
  }

  Widget _buildNoneCard(BuildContext context, ThemeData theme, bool isEn) {
    return Card(
      key: const Key('pokemon_search_none_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop('none');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#---',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                  ),
                  Icon(
                    Icons.block,
                    size: 14,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.block,
                      size: 32,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
              Text(
                isEn ? 'No Pokémon' : 'Kein Pokémon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (isEn ? 'NO WATERMARK' : 'KEIN WASSERZEICHEN').toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context, ThemeData theme, bool isEn) {
    return Card(
      key: const Key('pokemon_search_placeholder_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop('placeholder');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Number placeholder & icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#---',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  Icon(
                    Icons.crop_free,
                    size: 14,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ],
              ),

              // Center Icon / Visual
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.crop_free,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),

              // Name / Label
              Text(
                t.placeholder,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (isEn ? 'SLOT' : 'FREI').toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleSettings.currentLocale == AppLocale.en;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          decoration: InputDecoration(
            hintText: t.search_pokemon_hint,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _debounceTimer?.cancel();
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      _applyFilter();
                    },
                  )
                : null,
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
          onChanged: _onSearchChanged,
        ),
        actions: [
          IconButton(
            key: const Key('toggle_shiny_button'),
            icon: Icon(
              _isShinyMode ? Icons.star : Icons.star_border,
              color: _isShinyMode ? Colors.amber : null,
            ),
            tooltip: _isShinyMode
                ? (isEn ? 'Show Normal' : 'Normal anzeigen')
                : (isEn ? 'Show Shiny' : 'Schillernd anzeigen'),
            onPressed: () {
              setState(() {
                _isShinyMode = !_isShinyMode;
              });
            },
          ),
          if (widget.allowNone)
            TextButton.icon(
              key: const Key('select_none_pokemon_button'),
              icon: const Icon(Icons.block, size: 18),
              label: Text(
                isEn ? 'No Pokémon' : 'Kein Pokémon',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop('none');
              },
            ),
          if (widget.showPlaceholder)
            TextButton.icon(
              key: const Key('insert_placeholder_button'),
              icon: const Icon(Icons.crop_free, size: 18),
              label: Text(
                t.placeholder,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop('placeholder');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Region Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          t.filter_regions,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      ..._regions.map((reg) {
                        final key = reg['key']!;
                        final label = isEn ? reg['labelEn']! : reg['labelDe']!;
                        final isSelected = _selectedRegions.contains(key);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            visualDensity: VisualDensity.compact,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                            selectedColor: theme.colorScheme.primaryContainer,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRegions.add(key);
                                } else {
                                  _selectedRegions.remove(key);
                                }
                              });
                              _applyFilter();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Form Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          t.filter_forms,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      ..._forms.map((form) {
                        final key = form['key']!;
                        final label = switch (key) {
                          'normal' => t.form_normal,
                          'mega' => t.form_mega,
                          'gmax' => t.form_gmax,
                          'regional' => t.form_regional,
                          _ => isEn ? form['labelEn']! : form['labelDe']!,
                        };
                        final isSelected = _selectedForms.contains(key);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            visualDensity: VisualDensity.compact,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                            selectedColor: theme.colorScheme.secondaryContainer,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedForms.add(key);
                                } else {
                                  _selectedForms.remove(key);
                                }
                              });
                              _applyFilter();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Gender Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          t.filter_gender,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                      ..._genders.map((gen) {
                        final key = gen['key']!;
                        final label = switch (key) {
                          'male' => t.gender_male,
                          'female' => t.gender_female,
                          'genderless' => t.gender_genderless,
                          'differences' => t.gender_differences,
                          _ => isEn ? gen['labelEn']! : gen['labelDe']!,
                        };
                        final isSelected = _selectedGenders.contains(key);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            visualDensity: VisualDensity.compact,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onTertiaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                            selectedColor: theme.colorScheme.tertiaryContainer,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGenders.add(key);
                                } else {
                                  _selectedGenders.remove(key);
                                }
                              });
                              _applyFilter();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Variant Filter Chips (Normal vs Shiny)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          t.filter_variant,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          key: const Key('variant_normal_chip'),
                          label: Text(t.variant_normal),
                          selected: !_isShinyMode,
                          visualDensity: VisualDensity.compact,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: !_isShinyMode ? FontWeight.bold : FontWeight.normal,
                            color: !_isShinyMode
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                          selectedColor: theme.colorScheme.surfaceContainerHighest,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _isShinyMode = false;
                              });
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          key: const Key('variant_shiny_chip'),
                          avatar: const Icon(Icons.star, size: 14, color: Colors.amber),
                          label: Text(t.variant_shiny),
                          selected: _isShinyMode,
                          visualDensity: VisualDensity.compact,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: _isShinyMode ? FontWeight.bold : FontWeight.normal,
                            color: _isShinyMode ? Colors.amber.shade900 : theme.colorScheme.onSurface,
                          ),
                          selectedColor: Colors.amber.withValues(alpha: 0.3),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _isShinyMode = true;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Count & Clear Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${_filteredEntries.length} ${isEn ? 'Pokémon' : 'Pokémon'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (_selectedRegions.isNotEmpty ||
                    _selectedForms.isNotEmpty ||
                    _selectedGenders.isNotEmpty ||
                    _searchQuery.isNotEmpty ||
                    _isShinyMode != widget.initialShiny)
                  InkWell(
                    onTap: () {
                      _debounceTimer?.cancel();
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedRegions.clear();
                        _selectedForms.clear();
                        _selectedGenders.clear();
                        _isShinyMode = widget.initialShiny;
                      });
                      _applyFilter();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt_off, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            t.reset_filters,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Grid View
          Expanded(
            child: (_filteredEntries.isEmpty && !_shouldShowPlaceholderCard && !_shouldShowNoneCard)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isEn ? 'No Pokémon found' : 'Keine Pokémon gefunden',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = (constraints.maxWidth / 120).floor().clamp(2, 6);
                      final showNone = _shouldShowNoneCard;
                      final showPlaceholder = _shouldShowPlaceholderCard;
                      final leadingSpecialCount = (showNone ? 1 : 0) + (showPlaceholder ? 1 : 0);
                      final totalCount = _filteredEntries.length + leadingSpecialCount;
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.76,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: totalCount,
                        itemBuilder: (context, index) {
                          if (showNone && index == 0) {
                            return _buildNoneCard(context, theme, isEn);
                          }

                          if (showPlaceholder && index == (showNone ? 1 : 0)) {
                            return _buildPlaceholderCard(context, theme, isEn);
                          }

                          final entryIndex = index - leadingSpecialCount;
                          final entry = _filteredEntries[entryIndex];
                          final name = isEn ? entry.pokemon.nameEn : entry.pokemon.nameDe;
                          final types = _getEntryTypes(entry);
                          final idStr = '#${entry.pokemon.id.toString().padLeft(3, '0')}';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.dividerColor.withValues(alpha: 0.2),
                              ),
                            ),
                            color: theme.cardColor,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop(
                                  _isShinyMode ? 'shiny:${entry.uniqueId}' : entry.uniqueId,
                                );
                              },
                              onLongPress: () {
                                String effectiveDexId = widget.dexId ?? '';
                                try {
                                  final provider = context.read<DexProvider>();
                                  if (!provider.userDexes.any((d) => d.id == effectiveDexId)) {
                                    if (provider.userDexes.isNotEmpty) {
                                      effectiveDexId = provider.userDexes.first.id;
                                    }
                                  }
                                } catch (_) {}

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => PokemonInfoScreen(
                                      entries: _filteredEntries,
                                      initialIndex: entryIndex,
                                      dexId: effectiveDexId.isNotEmpty
                                          ? effectiveDexId
                                          : 'national_overall',
                                      initialShiny: _isShinyMode,
                                      selectionActionLabel: isEn
                                          ? 'Add to Dex'
                                          : 'Zum Dex hinzufügen',
                                      onSelectionAction: (id) {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop(id);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top Row: Number, Shiny star & Suffix
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              idStr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                              ),
                                            ),
                                            if (_isShinyMode) ...[
                                              const SizedBox(width: 2),
                                              const Icon(Icons.star, size: 11, color: Colors.amber),
                                            ],
                                          ],
                                        ),
                                        if (entry.displaySuffix.isNotEmpty)
                                          Flexible(
                                            child: Text(
                                              entry.displaySuffix.trim(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.primary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Image
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: CachedNetworkImage(
                                          imageUrl: _getDisplayImageUrl(entry, _isShinyMode),
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) => Center(
                                            child: Icon(
                                              Icons.catching_pokemon,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                                              size: 28,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.catching_pokemon,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Name
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),

                                    // Type Badges
                                    if (types.isNotEmpty)
                                      Wrap(
                                        spacing: 3,
                                        runSpacing: 2,
                                        alignment: WrapAlignment.center,
                                        children: types.map((type) {
                                          final color = _typeColors[type.toLowerCase()] ?? Colors.grey;
                                          final typeName = Translator.get('type_$type');
                                          final label = (typeName != 'type_$type' && typeName.isNotEmpty)
                                              ? typeName
                                              : type;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              label.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    else
                                      const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
