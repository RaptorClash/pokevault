class UserDex {
  final String id;
  final String title;
  final String region;
  final bool includeGenders;
  final bool includeRegional;
  final bool includeMega;
  final bool includeGMax;
  final bool includeOther;
  final bool isShinyDex;
  List<String> caughtIds;
  List<String> shinyIds;
  List<String> ignoredIds;
  String viewMode;
  String sortMode;

  UserDex({
    required this.id,
    required this.title,
    required this.region,
    required this.includeGenders,
    required this.includeRegional,
    required this.includeMega,
    required this.includeGMax,
    required this.includeOther,
    required this.isShinyDex,
    this.caughtIds = const [],
    this.shinyIds = const [],
    this.ignoredIds = const [],
    this.viewMode = 'list',
    this.sortMode = 'dex',
  });

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
      isShinyDex: (map['is_shiny_dex'] as num?)?.toInt() == 1,
      viewMode: map['view_mode']?.toString() ?? 'list',
      sortMode: map['sort_mode']?.toString() ?? 'dex',
      caughtIds: [],
      shinyIds: [],
      ignoredIds: [],
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
      'is_shiny_dex': isShinyDex ? 1 : 0,
      'view_mode': viewMode,
      'sort_mode': sortMode,
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
      'isShinyDex': isShinyDex,
      'viewMode': viewMode,
      'sortMode': sortMode,
      'caughtIds': caughtIds,
      'shinyIds': shinyIds,
      'ignoredIds': ignoredIds,
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
      isShinyDex: json['isShinyDex'] ?? false,
      viewMode: json['viewMode']?.toString() ?? 'list',
      sortMode: json['sortMode']?.toString() ?? 'dex',
      caughtIds: List<String>.from(json['caughtIds'] ?? []),
      shinyIds: List<String>.from(json['shinyIds'] ?? []),
      ignoredIds: List<String>.from(json['ignoredIds'] ?? []),
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
