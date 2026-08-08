class UserDex {
  final String id;
  final String title;
  final String region;
  final Set<String> caughtIds;
  final Set<String> ignoredIds;
  final Set<String> shinyIds;
  final bool includeGenders;
  final bool includeRegional;
  final bool includeMega;
  final bool includeGMax;
  final bool includeOther;
  final bool isShinyDex;

  UserDex({
    required this.id,
    required this.title,
    required this.region,
    required this.caughtIds,
    this.ignoredIds = const {},
    this.shinyIds = const {},
    this.includeGenders = false,
    required this.includeRegional,
    required this.includeMega,
    required this.includeGMax,
    required this.includeOther,
    this.isShinyDex = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'region': region,
      'caughtIds': caughtIds.toList(),
      'ignoredIds': ignoredIds.toList(),
      'shinyIds': shinyIds.toList(),
      'includeRegional': includeRegional,
      'includeMega': includeMega,
      'includeGMax': includeGMax,
      'includeOther': includeOther,
      'includeGenders': includeGenders,
      'isShinyDex': isShinyDex,
    };
  }

  factory UserDex.fromJson(Map<String, dynamic> json) {
    return UserDex(
      id: json['id'] as String,
      title: json['title'] as String,
      region: json['region'] as String,
      caughtIds:
          (json['caughtIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      ignoredIds:
          (json['ignoredIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      shinyIds:
          (json['shinyIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      includeGenders: json['includeGenders'] as bool? ?? false,
      includeRegional: json['includeRegional'] as bool? ?? false,
      includeMega: json['includeMega'] as bool? ?? false,
      includeGMax: json['includeGMax'] as bool? ?? false,
      includeOther: json['includeOther'] as bool? ?? false,
      isShinyDex:
          json['isShinyDex'] as bool? ??
          false,
    );
  }
}
