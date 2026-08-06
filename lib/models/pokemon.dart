class PokemonForm {
  final String name;
  final int minGen;
  final int imageId;
  final List<String> exclusiveRegions;
  final String? extraInfo;

  const PokemonForm({
    required this.name,
    required this.minGen,
    required this.imageId,
    this.exclusiveRegions = const [],
    this.extraInfo,
  });
}

class Pokemon {
  final int id;
  final Map<String, String> names;
  final bool hasGenderDifferences;
  final List<PokemonForm> forms;
  final String? extraInfo;

  const Pokemon({
    required this.id,
    required this.names,
    this.hasGenderDifferences = false,
    this.forms = const [],
    this.extraInfo,
  });

  String getName([String lang = 'de']) {
    return names[lang] ?? names['de'] ?? 'Unbekannt';
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}
