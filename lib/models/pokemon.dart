class Pokemon {
  final int id;
  final String nameDe;
  final String nameEn;
  final Map<String, String> names;
  final bool hasGenderDifferences;
  final int genderRate;
  final int captureRate;
  final int evolutionChainId;
  final List<String> eggGroups;
  final double weight;
  final int speed;
  final List<PokemonForm> forms;
  final List<String> catchRateTags;

  Pokemon({
    required this.id,
    required this.nameDe,
    required this.nameEn,
    Map<String, String>? names,
    required this.hasGenderDifferences,
    required this.genderRate,
    required this.captureRate,
    required this.evolutionChainId,
    required this.eggGroups,
    required this.weight,
    required this.speed,
    required this.forms,
    this.catchRateTags = const [],
  }) : names = {
         ...?names,
         if (names == null || !names.containsKey('de')) 'de': nameDe,
         if (names == null || !names.containsKey('en')) 'en': nameEn,
       };

  factory Pokemon.fromMap(
    Map<String, dynamic> map, [
    List<PokemonForm> forms = const [],
  ]) {
    final names = <String, String>{};
    for (final key in map.keys) {
      if (key.startsWith('name_')) {
        final langKey = key.substring(5).replaceAll('_', '-');
        final val = map[key]?.toString();
        if (val != null && val.isNotEmpty) {
          names[langKey] = val;
        }
      }
    }

    final de = names['de'] ?? map['name_de']?.toString() ?? 'Unknown';
    final en = names['en'] ?? map['name_en']?.toString() ?? 'Unknown';
    names['de'] = de;
    names['en'] = en;

    return Pokemon(
      id: (map['id'] as num?)?.toInt() ?? 0,
      nameDe: de,
      nameEn: en,
      names: names,
      hasGenderDifferences:
          (map['has_gender_differences'] as num?)?.toInt() == 1,
      genderRate: (map['gender_rate'] as num?)?.toInt() ?? -1,
      captureRate: (map['capture_rate'] as num?)?.toInt() ?? 255,
      evolutionChainId: (map['evolution_chain_id'] as num?)?.toInt() ?? -1,
      eggGroups: (map['egg_groups']?.toString() ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toInt() ?? 0,
      forms: forms,
      catchRateTags: (map['catch_rate_tags']?.toString() ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  String getName(String languageCode) {
    final normalized = languageCode.toLowerCase().replaceAll('_', '-');

    for (final entry in names.entries) {
      if (entry.key.toLowerCase().replaceAll('_', '-') == normalized) {
        return entry.value;
      }
    }

    if (normalized == 'de') {
      return nameDe != 'Unknown' ? nameDe : nameEn;
    }
    return nameEn != 'Unknown'
        ? nameEn
        : (nameDe != 'Unknown' ? nameDe : 'Unknown');
  }

  bool get isUltraBeast => catchRateTags.contains('ultra_beast');
  bool get isMoonBallTarget => catchRateTags.contains('moon_ball');
  bool get isFastBallGen2Target => catchRateTags.contains('fast_ball_gen2');
}

class PokemonForm {
  final String name;
  final String formType;
  final int minGen;
  final int imageId;
  final List<String> types;
  final List<String> exclusiveRegions;
  final String? forcedTeraType;

  PokemonForm({
    required this.name,
    required this.formType,
    required this.minGen,
    required this.imageId,
    required this.types,
    required this.exclusiveRegions,
    this.forcedTeraType,
  });

  factory PokemonForm.fromMap(Map<String, dynamic> map) {
    return PokemonForm(
      name: map['name']?.toString() ?? 'normal',
      formType: map['form_type']?.toString() ?? 'other',
      minGen: (map['min_gen'] as num?)?.toInt() ?? 9,
      imageId: (map['image_id'] as num?)?.toInt() ?? 0,
      types: (map['types']?.toString() ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      exclusiveRegions: (map['exclusive_regions']?.toString() ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      forcedTeraType: map['forced_tera_type'] as String?,
    );
  }
}
