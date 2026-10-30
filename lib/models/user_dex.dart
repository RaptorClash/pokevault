import 'dart:convert';
class CustomBoxState {
  String title;
  List<String> pokemonIds;
  String regionKey;
  int columns;
  int rows;
  bool autoFlow;
  bool autoShift;
  bool strictLimits;
  bool patternAutoCreate;
  bool autoDeleteEmpty;

  CustomBoxState({
    required this.title,
    required this.pokemonIds,
    this.regionKey = 'custom',
    this.columns = 6,
    this.rows = 5,
    this.autoFlow = false,
    this.autoShift = true,
    this.strictLimits = true,
    this.patternAutoCreate = true,
    this.autoDeleteEmpty = true,
  });

  /// Computed grid capacity for the box.
  int get capacity => columns * rows;

  /// Creates a copy of this box state with optional overrides.
  CustomBoxState copyWith({
    String? title,
    List<String>? pokemonIds,
    String? regionKey,
    int? columns,
    int? rows,
    bool? autoFlow,
    bool? autoShift,
    bool? strictLimits,
    bool? patternAutoCreate,
    bool? autoDeleteEmpty,
  }) {
    return CustomBoxState(
      title: title ?? this.title,
      pokemonIds: pokemonIds ?? List<String>.from(this.pokemonIds),
      regionKey: regionKey ?? this.regionKey,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      autoFlow: autoFlow ?? this.autoFlow,
      autoShift: autoShift ?? this.autoShift,
      strictLimits: strictLimits ?? this.strictLimits,
      patternAutoCreate: patternAutoCreate ?? this.patternAutoCreate,
      autoDeleteEmpty: autoDeleteEmpty ?? this.autoDeleteEmpty,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'pokemonIds': pokemonIds,
    'regionKey': regionKey,
    'columns': columns,
    'rows': rows,
    'autoFlow': autoFlow,
    'autoShift': autoShift,
    'strictLimits': strictLimits,
    'patternAutoCreate': patternAutoCreate,
    'autoDeleteEmpty': autoDeleteEmpty,
  };

  factory CustomBoxState.fromMap(Map<String, dynamic> map) => CustomBoxState(
    title: map['title']?.toString() ?? 'Box',
    pokemonIds: List<String>.from(map['pokemonIds'] ?? []),
    regionKey: map['regionKey']?.toString() ?? 'custom',
    columns: (map['columns'] as int?) ?? 6,
    rows: (map['rows'] as int?) ?? 5,
    autoFlow: (map['autoFlow'] as bool?) ?? false,
    autoShift: (map['autoShift'] as bool?) ?? true,
    strictLimits: (map['strictLimits'] as bool?) ?? true,
    patternAutoCreate: (map['patternAutoCreate'] as bool?) ?? true,
    autoDeleteEmpty: (map['autoDeleteEmpty'] as bool?) ?? true,
  );
}

class UserDex {
  final String id;
  final String title;
  final String region;
  final bool includeGenders;
  final bool includeRegional;
  final bool includeMega;
  final bool includeGMax;
  final bool includeOther;
  final bool includeTrades;
  final bool includeGifts;
  final bool includeGlitch;
  final bool isShinyDex;
  List<String> caughtIds;
  List<String> shinyIds;
  List<String> ignoredIds;
  List<String> alphaIds;
  String viewMode;
  String sortMode;
  String megaSort;
  String gmaxSort;
  String regionalSort;
  Map<String, List<String>> caughtRibbons = {};
  Map<String, List<String>> caughtTeraTypes = {};
  Map<String, List<String>> caughtLanguages = {};
  List<CustomBoxState> customBoxes = [];

  UserDex({
    required this.id,
    required this.title,
    required this.region,
    required this.includeGenders,
    required this.includeRegional,
    required this.includeMega,
    required this.includeGMax,
    required this.includeOther,
    this.includeTrades = false,
    this.includeGifts = false,
    this.includeGlitch = false,
    required this.isShinyDex,
    List<String>? caughtIds,
    List<String>? shinyIds,
    List<String>? ignoredIds,
    List<String>? alphaIds,
    this.viewMode = 'list',
    List<CustomBoxState>? customBoxes,
    this.sortMode = 'dex',
    this.megaSort = 'origin',
    this.gmaxSort = 'origin',
    this.regionalSort = 'mechanic',
    Map<String, List<String>>? caughtRibbons,
    Map<String, List<String>>? caughtTeraTypes,
    Map<String, List<String>>? caughtLanguages,
  })  : caughtIds = caughtIds != null ? List.from(caughtIds) : [],
        shinyIds = shinyIds != null ? List.from(shinyIds) : [],
        ignoredIds = ignoredIds != null ? List.from(ignoredIds) : [],
        alphaIds = alphaIds != null ? List.from(alphaIds) : [],
        customBoxes = customBoxes != null ? List.from(customBoxes) : [],
        caughtRibbons = caughtRibbons != null ? Map.from(caughtRibbons) : {},
        caughtTeraTypes = caughtTeraTypes != null ? Map.from(caughtTeraTypes) : {},
        caughtLanguages = caughtLanguages != null ? Map.from(caughtLanguages) : {};

  factory UserDex.fallback([String id = '']) => UserDex(
    id: id,
    title: '',
    region: 'kanto',
    includeGenders: false,
    includeRegional: false,
    includeMega: false,
    includeGMax: false,
    includeOther: false,
    includeTrades: false,
    includeGifts: false,
    includeGlitch: false,
    isShinyDex: false,
    customBoxes: [],
  );

  factory UserDex.fromMap(Map<String, dynamic> map) {
    return UserDex(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      region: map['region']?.toString() ?? '',
      includeGenders: (map['include_genders'] as num?)?.toInt() == 1,
      includeRegional: (map['include_regional'] as num?)?.toInt() == 1,
      includeMega: (map['include_mega'] as num?)?.toInt() == 1,
      includeGMax: (map['include_gmax'] as num?)?.toInt() == 1,
      includeOther: (map['include_other'] as num?)?.toInt() == 1,
      includeTrades: (map['include_trades'] as num?)?.toInt() == 1,
      includeGifts: (map['include_gifts'] as num?)?.toInt() == 1,
      includeGlitch: (map['include_glitch'] as num?)?.toInt() == 1,
      isShinyDex: (map['is_shiny_dex'] as num?)?.toInt() == 1,
      viewMode: map['view_mode']?.toString() ?? 'list',
      sortMode: map['sort_mode']?.toString() ?? 'dex',
      alphaIds: [],
      caughtIds: [],
      shinyIds: [],
      ignoredIds: [],
      megaSort: map['mega_sort']?.toString() ?? 'origin',
      gmaxSort: map['gmax_sort']?.toString() ?? 'origin',
      regionalSort: map['regional_sort']?.toString() ?? 'mechanic',
      customBoxes: map['custom_boxes'] != null && map['custom_boxes'].toString().isNotEmpty
          ? List<CustomBoxState>.from(jsonDecode(map['custom_boxes']).map((x) => CustomBoxState.fromMap(x)))
          : [],
      caughtRibbons: {},
      caughtTeraTypes: {},
      caughtLanguages: {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'region': region,
      'include_genders': includeGenders ? 1 : 0,
      'include_regional': includeRegional ? 1 : 0,
      'include_mega': includeMega ? 1 : 0,
      'include_gmax': includeGMax ? 1 : 0,
      'include_other': includeOther ? 1 : 0,
      'include_trades': includeTrades ? 1 : 0,
      'include_gifts': includeGifts ? 1 : 0,
      'include_glitch': includeGlitch ? 1 : 0,
      'is_shiny_dex': isShinyDex ? 1 : 0,
      'view_mode': viewMode,
      'sort_mode': sortMode,
      'mega_sort': megaSort,
      'gmax_sort': gmaxSort,
      'regional_sort': regionalSort,
      'custom_boxes': jsonEncode(customBoxes.map((e) => e.toMap()).toList()),
      'caught_ids': caughtIds.join(','),
      'shiny_ids': shinyIds.join(','),
      'alpha_ids': alphaIds.join(','),
      'caught_languages': caughtLanguages.map(
        (key, value) => MapEntry(key, value.join(',')),
      ),
      'caught_ribbons': caughtRibbons.map(
        (key, value) => MapEntry(key, value.join(',')),
      ),
      'caught_tera_types': caughtTeraTypes.map(
        (key, value) => MapEntry(key, value.join(',')),
      ),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'region': region,
      'includeGenders': includeGenders,
      'includeRegional': includeRegional,
      'includeMega': includeMega,
      'includeGMax': includeGMax,
      'includeOther': includeOther,
      'includeTrades': includeTrades,
      'includeGifts': includeGifts,
      'includeGlitch': includeGlitch,
      'isShinyDex': isShinyDex,
      'viewMode': viewMode,
      'sortMode': sortMode,
      'megaSort': megaSort,
      'gmaxSort': gmaxSort,
      'regionalSort': regionalSort,
      'customBoxes': customBoxes.map((e) => e.toMap()).toList(),
      'alphaIds': alphaIds,
      'caughtIds': caughtIds,
      'shinyIds': shinyIds,
      'ignoredIds': ignoredIds,
      'caughtRibbons': caughtRibbons,
      'caughtTeraTypes': caughtTeraTypes,
      'caughtLanguages': caughtLanguages,
    };
  }

  factory UserDex.fromJson(Map<String, dynamic> json) {
    return UserDex(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      includeGenders: json['includeGenders'] ?? false,
      includeRegional: json['includeRegional'] ?? false,
      includeMega: json['includeMega'] ?? false,
      includeGMax: json['includeGMax'] ?? false,
      includeOther: json['includeOther'] ?? false,
      includeTrades: json['includeTrades'] ?? false,
      includeGifts: json['includeGifts'] ?? false,
      includeGlitch: json['includeGlitch'] ?? false,
      isShinyDex: json['isShinyDex'] ?? false,
      viewMode: json['viewMode']?.toString() ?? 'list',
      sortMode: json['sortMode']?.toString() ?? 'dex',
      customBoxes: json['customBoxes'] != null
          ? List<CustomBoxState>.from((json['customBoxes'] as List).map((x) => CustomBoxState.fromMap(x)))
          : [],
      alphaIds: List<String>.from(json['alphaIds'] ?? []),
      caughtIds: List<String>.from(json['caughtIds'] ?? []),
      shinyIds: List<String>.from(json['shinyIds'] ?? []),
      ignoredIds: List<String>.from(json['ignoredIds'] ?? []),
      caughtRibbons: Map<String, List<String>>.from(
        (json['caughtRibbons'] ?? {}).map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value)),
        ),
      ),
      caughtTeraTypes: Map<String, List<String>>.from(
        (json['caughtTeraTypes'] ?? {}).map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value)),
        ),
      ),
      caughtLanguages: Map<String, List<String>>.from(
        (json['caughtLanguages'] ?? {}).map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value)),
        ),
      ),
    );
  }
}

class DexFolder {
  final String id;
  final String title;

  DexFolder({required this.id, required this.title});

  factory DexFolder.fromMap(Map<String, dynamic> map) {
    return DexFolder(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title};
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title};
  }

  factory DexFolder.fromJson(Map<String, dynamic> json) {
    return DexFolder(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }
}


