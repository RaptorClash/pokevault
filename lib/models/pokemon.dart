class Pokemon {
  final int id;
  final String nameDe;
  final String nameEn;
  final bool hasGenderDifferences;
  final int genderRate;
  final int captureRate;
  final int evolutionChainId;
  final List<String> eggGroups;
  final double weight;
  final int speed;
  final List<PokemonForm> forms;

  Pokemon({
    required this.id,
    required this.nameDe,
    required this.nameEn,
    required this.hasGenderDifferences,
    required this.genderRate,
    required this.captureRate,
    required this.evolutionChainId,
    required this.eggGroups,
    required this.weight,
    required this.speed,
    required this.forms,
  });

  factory Pokemon.fromMap(Map<String, dynamic> map, List<PokemonForm> forms) {
    return Pokemon(
      id: (map['id'] as num?)?.toInt() ?? 0,
      nameDe: map['name_de']?.toString() ?? 'Unknown',
      nameEn: map['name_en']?.toString() ?? 'Unknown',
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
    );
  }

  String getName(String languageCode) {
    return languageCode == 'de' ? nameDe : nameEn;
  }
}

class PokemonForm {
  final String name;
  final String formType;
  final int minGen;
  final int imageId;
  final List<String> types;
  final List<String> exclusiveRegions;

  PokemonForm({
    required this.name,
    required this.formType,
    required this.minGen,
    required this.imageId,
    required this.types,
    required this.exclusiveRegions,
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
    );
  }
}
