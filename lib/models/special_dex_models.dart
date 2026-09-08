class PokeAbility {
  final int id;
  final String nameDe;
  final String nameEn;
  final String descDe;
  final String descEn;

  PokeAbility({
    required this.id,
    required this.nameDe,
    required this.nameEn,
    required this.descDe,
    required this.descEn,
  });

  String getName(String lang) => lang == 'de' ? nameDe : nameEn;
  String getDesc(String lang) => lang == 'de' ? descDe : descEn;
}

class PokeMove {
  final int id;
  final String nameDe;
  final String nameEn;
  final String descDe;
  final String descEn;
  final String type;
  final int power;
  final int accuracy;
  final int pp;
  final String damageClass;

  PokeMove({
    required this.id,
    required this.nameDe,
    required this.nameEn,
    required this.type,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.damageClass,
    required this.descDe,
    required this.descEn,
  });

  String getName(String lang) => lang == 'de' ? nameDe : nameEn;
  String getDesc(String lang) => lang == 'de' ? descDe : descEn;
}

class PokemonLearnset {
  final int pokemonId;
  final String learnMethod;
  final int levelLearned;
  final String versionGroup;
  final bool isHiddenAbility;

  PokemonLearnset({
    required this.pokemonId,
    required this.learnMethod,
    required this.levelLearned,
    required this.versionGroup,
    this.isHiddenAbility = false,
  });
}
