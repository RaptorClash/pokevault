class PokemonForm {
  final String name;
  final String formType;
  final int minGen;
  final int imageId;
  final List<String> types;
  final List<String> exclusiveRegions;
  final String? extraInfo;

  const PokemonForm({
    required this.name,
    required this.formType,
    required this.minGen,
    required this.imageId,
    required this.types,
    required this.exclusiveRegions,
    this.extraInfo,
  });
}

class Pokemon {
  final int id;
  final Map<String, String> names;
  final bool hasGenderDifferences;
  final int genderRate;
  final List<String> eggGroups;
  final int evolutionChainId;
  final List<PokemonForm> forms;
  final String? extraInfo;
  final int captureRate;

  const Pokemon({
    required this.id,
    required this.names,
    required this.hasGenderDifferences,
    required this.genderRate,
    required this.eggGroups,
    required this.evolutionChainId,
    required this.forms,
    this.extraInfo,
    required this.captureRate,
  });

  String getName(String languageCode) {
    return names[languageCode] ?? names['en'] ?? 'Unknown';
  }
}
