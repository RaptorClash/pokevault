class UserDex {
  final String id;
  final String title;
  final String region;
  final Set<String> caughtIds;
  final bool includeForms;
  final bool includeGenders;

  UserDex({
    required this.id,
    required this.title,
    required this.region,
    required this.caughtIds,
    this.includeForms = false,
    this.includeGenders = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'region': region,
      'caughtIds': caughtIds.toList(),
      'includeForms': includeForms,
      'includeGenders': includeGenders,
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
      includeForms: json['includeForms'] as bool? ?? false,
      includeGenders: json['includeGenders'] as bool? ?? false,
    );
  }
}
