import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../models/shiny_hunt.dart';
import 'shiny_logic_helper.dart';
import '../l10n/app_translations.dart';

enum OddsClassification {
  underOdds,
  atOdds,
  overOdds,
}

extension OddsClassificationExtension on OddsClassification {
  String get label {
    switch (this) {
      case OddsClassification.underOdds:
        return 'Under Odds';
      case OddsClassification.atOdds:
        return 'At Odds';
      case OddsClassification.overOdds:
        return 'Over Odds';
    }
  }

  Color get color {
    switch (this) {
      case OddsClassification.underOdds:
        return const Color(0xFF4CAF50); // Grün
      case OddsClassification.atOdds:
        return const Color(0xFFFFB300); // Gelb/Bernstein
      case OddsClassification.overOdds:
        return const Color(0xFFE53935); // Rot
    }
  }
}

class ShinyMethodPreset {
  final String name;
  final String? description;
  final double defaultBaseOdds;
  final int defaultSpawns;
  final bool isChainMethod;
  final int? maxChain;
  final double? oddsWithCharm;
  final String? warningNote;

  const ShinyMethodPreset({
    required this.name,
    this.description,
    required this.defaultBaseOdds,
    this.defaultSpawns = 1,
    this.isChainMethod = false,
    this.maxChain,
    this.oddsWithCharm,
    this.warningNote,
  });

  double effectiveOdds(bool hasShinyCharm) {
    if (hasShinyCharm && oddsWithCharm != null) {
      return oddsWithCharm!;
    }
    return defaultBaseOdds;
  }
}

class ShinyHuntOddsHelper {
  /// Berechnet die Wahrscheinlichkeit, bei [rolls] Versuchen mindestens ein Shiny zu finden:
  /// P(X >= 1) = 1 - (1 - 1/baseOdds)^rolls
  static double calculateProbability(double baseOdds, int rolls) {
    if (rolls <= 0 || baseOdds <= 0) return 0.0;
    if (baseOdds <= 1.0) return 1.0;

    final p = 1.0 / baseOdds;
    if (p >= 1.0) return 1.0;

    final q = 1.0 - p;
    // Schutz vor numerischer Auslöschung bei sehr großen Exponenten
    final noShinyProb = pow(q, rolls).toDouble();
    return (1.0 - noShinyProb).clamp(0.0, 1.0);
  }

  /// Berechnet die Gegenwahrscheinlichkeit (bisher noch KEIN Shiny):
  /// P(X = 0) = (1 - 1/baseOdds)^rolls
  static double calculateComplementProbability(double baseOdds, int rolls) {
    if (rolls <= 0 || baseOdds <= 0) return 1.0;
    if (baseOdds <= 1.0) return 0.0;

    final p = 1.0 / baseOdds;
    if (p >= 1.0) return 0.0;

    final q = 1.0 - p;
    return pow(q, rolls).toDouble().clamp(0.0, 1.0);
  }

  /// Verhältnis aus absolvierten Würfen und Basis-Quote (z. B. 5120 / 4096 = 1.25x)
  static double calculateOddsRatio(int rolls, double baseOdds) {
    if (baseOdds <= 0) return 0.0;
    return rolls / baseOdds;
  }

  /// Klassifizierung: Under Odds (<100%), At Odds (100%..200%), Over Odds (>200%)
  static OddsClassification getClassification(int rolls, double baseOdds) {
    if (baseOdds <= 0) return OddsClassification.underOdds;
    final ratio = rolls / baseOdds;
    if (ratio < 1.0) {
      return OddsClassification.underOdds;
    } else if (ratio <= 2.0) {
      return OddsClassification.atOdds;
    } else {
      return OddsClassification.overOdds;
    }
  }

  /// Prüft, ob eine Methode eine Kettenmethode mit ansteigender Wahrscheinlichkeit ist
  static bool isChainMethod(String method) {
    final lower = method.toLowerCase().replaceAll('.', '');
    return lower.contains('radar') ||
        lower.contains('fishing') ||
        lower.contains('kettensurf') ||
        lower.contains('sos') ||
        lower.contains('fangserie') ||
        lower.contains('combo') ||
        lower.contains('ausbruch') ||
        lower.contains('outbreak') ||
        lower.contains('dexnav');
  }

  /// Berechnet die effektive Wahrscheinlichkeit (unterstützt dynamische Ketten sowie statische Quoten)
  static double calculateEffectiveProbability(ShinyHunt hunt) {
    if (isChainMethod(hunt.method) && hunt.baseOdds > 1500.0) {
      return calculateDynamicChainProbability(
        method: hunt.method,
        currentChain: hunt.currentEncounters,
        spawnsPerEncounter: hunt.spawnsPerEncounter,
        hasShinyCharm: hunt.hasShinyCharm,
        game: hunt.game,
        generation: hunt.generation,
      );
    }
    return calculateProbability(hunt.baseOdds, hunt.currentPhaseRolls);
  }

  /// Berechnet die effektive Gegenwahrscheinlichkeit (bisher noch kein Shiny)
  static double calculateEffectiveComplementProbability(ShinyHunt hunt) {
    return (1.0 - calculateEffectiveProbability(hunt)).clamp(0.0, 1.0);
  }

  /// Dynamische Ketten-Skalierung für ansteigende Wahrscheinlichkeiten
  /// P(mindestens 1 Shiny) = 1 - prod_{i=1}^n (1 - p_i)^k
  static double calculateDynamicChainProbability({
    required String method,
    required int currentChain,
    required int spawnsPerEncounter,
    required bool hasShinyCharm,
    String? game,
    double generation = 4.0,
  }) {
    if (currentChain <= 0) return 0.0;

    double productNoShiny = 1.0;
    for (int i = 1; i <= currentChain; i++) {
      final stepOdds = getStepOddsForChainMethod(
        method: method,
        step: i,
        hasShinyCharm: hasShinyCharm,
        game: game,
        generation: generation,
      );
      final p = (1.0 / stepOdds).clamp(0.0, 1.0);
      final q = 1.0 - p;
      final stepNoShiny = pow(q, spawnsPerEncounter).toDouble();
      productNoShiny *= stepNoShiny;
    }

    return (1.0 - productNoShiny).clamp(0.0, 1.0);
  }

  /// Liefert die Quote bei einem konkreten Kettenschritt [step]
  static double getStepOddsForChainMethod({
    required String method,
    required int step,
    required bool hasShinyCharm,
    String? game,
    double generation = 4.0,
  }) {
    final lowerMethod = method.toLowerCase().replaceAll('.', '');

    // 1. Poké-Radar (Gen 4, Gen 6, BDSP)
    if (lowerMethod.contains('radar')) {
      if (step >= 40) return 200.0;
      final base = (generation <= 4.0 || isBDSP(game)) ? 8192.0 : 4096.0;
      final t = step / 40.0;
      // Monotone exponentielle Skalierung von Basis-Quote bis auf 1/200 bei Kette 40
      return base - pow(t, 3.0) * (base - 200.0);
    }

    // 2. Chain Fishing / Kettensurfen (Gen 6)
    if (lowerMethod.contains('fishing') || lowerMethod.contains('kettensurf')) {
      final streak = min(step, 20);
      int rolls = 1 + (streak * 2);
      if (hasShinyCharm) rolls += 2;
      return 4096.0 / rolls;
    }

    // 3. SOS-Chains (Gen 7)
    if (lowerMethod.contains('sos')) {
      int extraRolls = 0;
      if (step >= 31) {
        extraRolls = 12;
      } else if (step >= 21) {
        extraRolls = 8;
      } else if (step >= 11) {
        extraRolls = 4;
      }
      int rolls = 1 + extraRolls + (hasShinyCharm ? 2 : 0);
      return 4096.0 / rolls;
    }

    // 4. Fangserien / Catch Combos (Gen 7.5 Let's Go)
    if (lowerMethod.contains('fangserie') || lowerMethod.contains('combo')) {
      if (step >= 31) {
        return hasShinyCharm ? 273.0 : 341.3;
      } else if (step >= 21) {
        return 512.0;
      } else if (step >= 11) {
        return 1024.0;
      } else {
        return hasShinyCharm ? 1365.3 : 4096.0;
      }
    }

    // 5. Massenausbrüche (Gen 9)
    if (lowerMethod.contains('ausbruch') || lowerMethod.contains('outbreak')) {
      int extraRolls = 0;
      if (step >= 60) {
        extraRolls = 2;
      } else if (step >= 20) {
        extraRolls = 1;
      }
      int rolls = 1 + extraRolls + (hasShinyCharm ? 2 : 0);
      return 4096.0 / rolls;
    }

    // Fallback: Standard-Quote
    return generation <= 5.0 ? 8192.0 : 4096.0;
  }

  /// Prüft, ob es sich um die BDSP-Spiele handelt
  static bool isBDSP(String? game) {
    if (game == null) return false;
    final g = game.toLowerCase();
    return g.contains('bdsp') ||
        g.contains('brilliant diamond') ||
        g.contains('shining pearl') ||
        g.contains('strahlender diamant') ||
        g.contains('leuchtende perle');
  }

  /// Prüft, ob der Schillerpin in der angegebenen Konstellation wirkt.
  /// WICHTIG: In BDSP wirkt der Pin NUR bei der Masuda-Methode (Zucht)!
  static bool isShinyCharmApplicable(String game, String method, double generation) {
    if (isBDSP(game)) {
      final m = method.toLowerCase();
      // In BDSP wirkt der Schillerpin NUR bei Masuda / Eiern
      return m.contains('masuda') || m.contains('zucht') || m.contains('egg') || m.contains('breeding');
    }

    if (generation < 5.0) return false; // Schillerpin existiert erst ab Gen 5

    return true;
  }

  /// Gibt ggf. einen speziellen Hinweistext zurück (z. B. BDSP Schillerpin-Bug)
  static String? getSpecialNote({
    required String game,
    required String method,
    required double generation,
    required bool hasShinyCharm,
  }) {
    if (isBDSP(game) && hasShinyCharm) {
      final m = method.toLowerCase();
      final isMasuda = m.contains('masuda') || m.contains('zucht') || m.contains('egg') || m.contains('breeding');
      if (!isMasuda) {
        return 'Hinweis: In SD/LP wirkt der Schillerpin wegen eines Spielfehlers nur bei Eiern (Masuda-Methode), nicht bei wilden Pokémon oder im Untergrund.';
      }
    }
    return null;
  }

  /// Liefert den lokalisierten Namen eines Pokéballs (z.B. Sympaball für love_ball)
  static String getLocalizedBallName(String? ballKey) {
    if (ballKey == null || ballKey.isEmpty) return '';
    final cleanKey = ballKey.replaceAll('-', '_').toLowerCase();
    final transKey = 'ball_$cleanKey';
    final translated = Translator.get(transKey);
    if (translated != transKey) {
      return translated;
    }
    return ballKey
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  /// Liefert den lokalisierten Namen der Jagdart / des Hunting-Typs
  static String getLocalizedHuntingType(String? huntingType) {
    if (huntingType == null || huntingType.isEmpty) return '';
    final key = huntingType.toLowerCase().replaceAll('-', '_');
    switch (key) {
      case 'wild':
        return Translator.get('shiny_hunt_type_wild', fallback: 'Wildfang');
      case 'breeding':
        return Translator.get('shiny_hunt_type_breeding', fallback: 'Zucht / Ei');
      case 'trade':
        return Translator.get('shiny_hunt_type_trade', fallback: 'Tausch');
      case 'soft_reset':
        return Translator.get('shiny_hunt_type_soft_reset', fallback: 'Soft Reset');
      case 'raid':
        return Translator.get('shiny_hunt_type_raid', fallback: 'Raid');
      case 'fossil':
        return Translator.get('shiny_hunt_type_fossil', fallback: 'Fossil');
      case 'gift':
        return Translator.get('shiny_hunt_type_gift', fallback: 'Geschenk / Event');
      case 'other':
        return Translator.get('shiny_hunt_type_other', fallback: 'Sonstiges');
      default:
        final trans = Translator.get('shiny_hunt_type_$key');
        if (trans != 'shiny_hunt_type_$key') return trans;
        return huntingType;
    }
  }

  /// Liefert das passende Icon zur Jagdart
  static IconData getHuntingTypeIcon(String? huntingType) {
    final key = huntingType?.toLowerCase().replaceAll('-', '_');
    switch (key) {
      case 'trade':
        return Icons.swap_horiz_rounded;
      case 'breeding':
        return Icons.egg_outlined;
      case 'soft_reset':
        return Icons.restart_alt_rounded;
      case 'raid':
        return Icons.flash_on_rounded;
      case 'fossil':
        return Icons.hourglass_bottom_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'wild':
      default:
        return Icons.catching_pokemon;
    }
  }

  /// Leitet eine Standard-Jagdart aus dem Preset- oder Methodennamen ab
  static String inferHuntingTypeFromMethod(String method) {
    final m = method.toLowerCase();
    if (m.contains('masuda') || m.contains('zucht') || m.contains('egg') || m.contains('breeding')) {
      return 'breeding';
    }
    if (m.contains('tausch') || m.contains('trade')) {
      return 'trade';
    }
    if (m.contains('reset') || m.contains('starter') || m.contains('stationary')) {
      return 'soft_reset';
    }
    if (m.contains('raid') || m.contains('dynamax')) {
      return 'raid';
    }
    if (m.contains('fossil')) {
      return 'fossil';
    }
    if (m.contains('geschenk') || m.contains('gift')) {
      return 'gift';
    }
    return 'wild';
  }

  /// Prüft synchron, ob ein Pokémon anhand seiner ID als Legendär, Mythisch oder Ultrabestie gilt.
  static bool isLegendaryOrMythicalId(int id) {
    // Gen 1
    if (id >= 144 && id <= 146) return true; // Arktos, Zapdos, Lavados
    if (id == 150 || id == 151) return true; // Mewtu, Mew
    // Gen 2
    if (id >= 243 && id <= 245) return true; // Raikou, Entei, Suicune
    if (id >= 249 && id <= 251) return true; // Lugia, Ho-Oh, Celebi
    // Gen 3
    if (id >= 377 && id <= 386) return true; // Regirock-Registeel, Latias, Latios, Kyogre, Groudon, Rayquaza, Jirachi, Deoxys
    // Gen 4
    if (id >= 480 && id <= 493) return true; // Selfe, Vesprit, Tobutz, Dialga, Palkia, Heatran, Regigigas, Giratina, Cresselia, Phione, Manaphy, Darkrai, Shaymin, Arceus
    // Gen 5
    if (id == 494) return true; // Victini
    if (id >= 638 && id <= 649) return true; // Kobalium, Terrakium, Viridium, Boreos, Voltolos, Reshiram, Zekrom, Demeteros, Kyurem, Keldeo, Meloetta, Genesect
    // Gen 6
    if (id >= 716 && id <= 721) return true; // Xerneas, Yveltal, Zygarde, Diancie, Hoopa, Volcanion
    // Gen 7
    if (id == 772 || id == 773) return true; // Typ:Null, Amigento
    if (id >= 785 && id <= 809) return true; // Kapus, Cosmog, Cosmoem, Solgaleo, Lunala, UBs, Necrozma, Magearna, Marshadow, Venicro, Agoyon, Muramura, Kopplosio, Zeraora, Meltan, Melmetal
    // Gen 8
    if (id >= 888 && id <= 898) return true; // Zacian, Zamazenta, Endynalos, Dakuma, Wulaosu, Zarude, Regieleki, Regidrago, Polar-/Phantoross, Coronospa
    if (id == 905) return true; // Cupidos
    // Gen 9
    if (id >= 1001 && id <= 1004) return true; // Schätze des Unheils
    if (id == 1007 || id == 1008) return true; // Koraidon, Miraidon
    if (id >= 1014 && id <= 1017) return true; // Drei Gefährten, Ogerpon
    if (id == 1024 || id == 1025) return true; // Terapagos, Pfirsit
    return false;
  }

  /// Prüft, ob ein Pokémon züchtbar ist (inklusive Zucht von Baby-Pokémon).
  static bool isBreedablePokemon(Pokemon? pokemon, int? pokeId) {
    if (pokeId != null && isLegendaryOrMythicalId(pokeId)) return false;
    if (pokemon != null) {
      if (isLegendaryOrMythicalId(pokemon.id)) return false;
      return ShinyLogicHelper.isBreedable(pokemon) || ShinyLogicHelper.isBaby(pokemon.id);
    }
    if (pokeId != null && ShinyLogicHelper.isBaby(pokeId)) return true;
    return true;
  }

  /// Erkennt Spiel & Generation anhand eines verknüpften Dex-Keys (Smart Defaults)
  static ({String game, double generation}) detectGameAndGenForDex(String dexKey) {
    final key = dexKey.toLowerCase();

    // Gen 1
    if (key == 'kanto_regional') {
      return (game: 'FireRed / LeafGreen', generation: 3.0);
    }
    if (key == 'letsgo_kanto_regional') {
      return (game: "Let's Go, Pikachu! / Evoli!", generation: 7.5);
    }

    // Gen 2 / 4
    if (key == 'johto_regional') {
      return (game: 'Gold / Silber / Kristall', generation: 2.0);
    }
    if (key == 'updated_johto_regional') {
      return (game: 'HeartGold / SoulSilver', generation: 4.0);
    }

    // Gen 3 / 6
    if (key == 'hoenn_regional') {
      return (game: 'Rubin / Saphir / Smaragd', generation: 3.0);
    }
    if (key == 'updated_hoenn_regional') {
      return (game: 'Omega Rubin / Alpha Saphir', generation: 6.0);
    }

    // Gen 4
    if (key == 'sinnoh_regional' || key == 'extended_sinnoh_regional') {
      return (game: 'Diamant / Perl / Platin', generation: 4.0);
    }

    // Gen 5
    if (key == 'unova_regional') {
      return (game: 'Schwarz / Weiß', generation: 5.0);
    }
    if (key == 'updated_unova_regional') {
      return (game: 'Schwarz 2 / Weiß 2', generation: 5.0);
    }

    // Gen 6
    if (key.startsWith('kalos_')) {
      return (game: 'X / Y', generation: 6.0);
    }

    // Gen 7
    if (key.contains('alola') ||
        key.contains('melemele') ||
        key.contains('akala') ||
        key.contains('ulaula') ||
        key.contains('poni')) {
      if (key.startsWith('updated_')) {
        return (game: 'Ultra Sonne / Ultra Mond', generation: 7.0);
      }
      return (game: 'Sonne / Mond', generation: 7.0);
    }

    // Gen 8
    if (key == 'galar_regional' ||
        key == 'isle_of_armor_regional' ||
        key == 'crown_tundra_regional') {
      return (game: 'Schwert / Schild', generation: 8.0);
    }
    if (key == 'hisui_regional') {
      return (game: 'Legenden: Arceus', generation: 8.5);
    }

    // Gen 9
    if (key == 'paldea_regional' ||
        key == 'kitakami_regional' ||
        key == 'blueberry_regional') {
      return (game: 'Karmesin / Purpur', generation: 9.0);
    }

    // Gen 9.5
    if (key.contains('lumiose')) {
      return (game: 'Legenden: Z-A', generation: 9.5);
    }

    // Default Fallback
    return (game: 'Karmesin / Purpur', generation: 9.0);
  }

  /// Liefert alle vordefinierten Methoden-Presets für die angegebene Generation / das Spiel
  static List<ShinyMethodPreset> getPresetsForGameAndGen(String game, double generation) {
    final presets = <ShinyMethodPreset>[];

    // BDSP Remake
    if (isBDSP(game)) {
      presets.add(const ShinyMethodPreset(
        name: 'Wild / Soft Reset',
        description: 'Standard-Begegnung oder Soft-Reset in SD/LP (1/4096)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 4096.0, // Pin wirkt wegen Bug nicht!
        warningNote: 'In SD/LP wirkt der Schillerpin wegen eines Bugs nur bei Masuda-Zucht!',
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode (Zucht)',
        description: 'Zucht mit zwei Pokémon unterschiedlicher Sprachregionen (1/683)',
        defaultBaseOdds: 682.67,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Poké-Radar (Kette 40+)',
        description: 'Volle Radar-Kette erreicht (1/200)',
        defaultBaseOdds: 200.0,
        oddsWithCharm: 200.0,
        isChainMethod: true,
        maxChain: 40,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Untergrund-Höhlen',
        description: 'Begegnungen im Untergrund (1/4096)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 4096.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 1 (RBY)
    if (generation == 1.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Über DVs in Gen 1 bestimmt (1/8192)',
        defaultBaseOdds: 8192.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Pokémon-Turm / Silph Scope',
        description: 'DV-Reroll durch Silph Scope im Pokémon-Turm (1/8192)',
        defaultBaseOdds: 8192.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 2 (GSK)
    if (generation == 2.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Standard-Quote der 2. Generation (1/8192)',
        defaultBaseOdds: 8192.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Shiny-Zucht / Ditto-Glitch',
        description: 'Zucht mit schillerndem Ditto oder Zuchtpartner (1/64)',
        defaultBaseOdds: 64.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Kurioses Ei / Odd Egg (Kristall)',
        description: 'Ei aus der Kristall-Pension (14% westlich = 1/7,14)',
        defaultBaseOdds: 100.0 / 14.0, // 7.142857
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 3 (RSE / FRLG)
    if (generation == 3.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Standard-Quote der 3. Generation (1/8192)',
        defaultBaseOdds: 8192.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Safari-Zone',
        description: 'Safari-Begegnung (1/8192)',
        defaultBaseOdds: 8192.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 4 (DPPt & HGSS)
    if (generation == 4.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Standard-Quote der 4. Generation (1/8192)',
        defaultBaseOdds: 8192.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'HGSS Starter Soft Reset',
        description: '3 Starter-Bälle gleichzeitig einsehbar (1/8192 mit k=3)',
        defaultBaseOdds: 8192.0,
        defaultSpawns: 3,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode',
        description: 'Internationale Zucht (1/1638)',
        defaultBaseOdds: 1638.4,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Poké-Radar (Kette 40+)',
        description: 'Radar-Kette ab 40 (1/200)',
        defaultBaseOdds: 200.0,
        isChainMethod: true,
        maxChain: 40,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Cute Charm Glitch',
        description: 'Charmebolzen-Glitch bei passender TID/SID (21,34% = 1/4,686)',
        defaultBaseOdds: 100.0 / 21.34, // 4.6860356
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 5 (BW & B2W2)
    if (generation == 5.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Standard-Quote Gen 5 (1/8192 ohne Pin, 1/2730 mit Pin)',
        defaultBaseOdds: 8192.0,
        oddsWithCharm: 8192.0 / 3.0, // 2730.67
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode',
        description: 'Internationale Zucht (1/1365 ohne Pin, 1/1024 mit Pin)',
        defaultBaseOdds: 1365.33,
        oddsWithCharm: 1024.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Doppelgras-Begegnung',
        description: 'Dunkles Gras mit zwei wilden Pokémon (k=2)',
        defaultBaseOdds: 8192.0,
        oddsWithCharm: 8192.0 / 3.0,
        defaultSpawns: 2,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 6 (XY & ORAS)
    if (generation == 6.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Ab Gen 6 halbierte Basis-Quote (1/4096 ohne Pin, 1/1365 mit Pin)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 4096.0 / 3.0, // 1365.33
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode',
        description: 'Internationale Zucht (1/683 ohne Pin, 1/512 mit Pin)',
        defaultBaseOdds: 682.67,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Hordenkämpfe',
        description: '5 wilde Pokémon gleichzeitig (k=5, 1/4096)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 4096.0 / 3.0,
        defaultSpawns: 5,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Kontaktsafari (Friend Safari)',
        description: 'Feste flache Quote in der Kontaktsafari (1/512)',
        defaultBaseOdds: 512.0,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Kettensurfen / Chain Fishing',
        description: 'Angel-Serie ab Kette 20 (ca. 1/100)',
        defaultBaseOdds: 100.0,
        oddsWithCharm: 95.25,
        isChainMethod: true,
        maxChain: 20,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Poké-Radar (Kette 40+)',
        description: 'Volle Radar-Kette ab 40 (1/200)',
        defaultBaseOdds: 200.0,
        oddsWithCharm: 200.0,
        isChainMethod: true,
        maxChain: 40,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'DexNav (ORAS)',
        description: 'Such-Level 999 mit Kette (bis zu 1/173)',
        defaultBaseOdds: 173.0,
        oddsWithCharm: 173.0,
        isChainMethod: true,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 7 (SM & USUM)
    if (generation == 7.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Standard-Quote Gen 7 (1/4096 ohne Pin, 1/1365 mit Pin)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 1365.33,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode',
        description: 'Internationale Zucht (1/683 ohne Pin, 1/512 mit Pin)',
        defaultBaseOdds: 682.67,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'SOS-Chains (Kette 31+)',
        description: 'Hilferuf-Kette ab 31 (1/1024 ohne Pin, 1/683 mit Pin)',
        defaultBaseOdds: 1024.0,
        oddsWithCharm: 682.67,
        isChainMethod: true,
        maxChain: 31,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Ultrapforte (Ultra Wormhole)',
        description: 'Sehr hohe Shiny-Chance bis zu 36% (1/2,78)',
        defaultBaseOdds: 100.0 / 36.0,
        oddsWithCharm: 100.0 / 36.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 7.5 (Let's Go Pikachu / Eevee)
    if (generation == 7.5) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild',
        description: 'Standard-Quote (1/4096 ohne Pin, 1/1365 mit Pin)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 1365.33,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Fangserie 31+ (mit Lockduft)',
        description: 'Fangserie 31+ mit Lockparfüm (1/341 ohne Pin, 1/273 mit Pin)',
        defaultBaseOdds: 341.33,
        oddsWithCharm: 273.07,
        isChainMethod: true,
        maxChain: 31,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 8 (Sword / Shield)
    if (generation == 8.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Standard-Quote (1/4096 ohne Pin, 1/1365 mit Pin)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 1365.33,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode',
        description: 'Internationale Zucht (1/683 ohne Pin, 1/512 mit Pin)',
        defaultBaseOdds: 682.67,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'KO-Methode (500+ Besiegte)',
        description: 'Erhöhte Würfe bei brillanten Auren (1/512 bei Auslösung)',
        defaultBaseOdds: 585.0,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Dynamax-Abenteuer',
        description: 'Dynamax-Abenteuer im Kronen-Schneeland (1/300 ohne Pin, 1/100 mit Pin!)',
        defaultBaseOdds: 300.0,
        oddsWithCharm: 100.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 8.5 (Legends: Arceus)
    if (generation == 8.5) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild',
        description: 'Standard-Quote (1/4096 ohne Pin, 1/2048 mit Pin)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 2048.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Massenausbruch (Outbreak)',
        description: 'Massenausbruch (1/158 ohne Pin, 1/128 mit Pin)',
        defaultBaseOdds: 158.0,
        oddsWithCharm: 128.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Mega-Auflauf (MMO)',
        description: 'Mega-Auflauf im Regen / Schnee (1/315 ohne Pin, 1/216 mit Pin)',
        defaultBaseOdds: 315.0,
        oddsWithCharm: 216.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 9 (Scarlet / Violet)
    if (generation == 9.0) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild',
        description: 'Standard-Quote (1/4096 ohne Pin, 1/1365 mit Pin)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 1365.33,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode (Picknick-Zucht)',
        description: 'Picknick-Zucht mit fremder Sprache (1/683 ohne Pin, 1/512 mit Pin)',
        defaultBaseOdds: 682.67,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Massenausbruch 60+',
        description: '60 Pokémon im Ausbruch besiegt (1/1365 ohne Pin, 1/819 mit Pin)',
        defaultBaseOdds: 1365.33,
        oddsWithCharm: 819.2,
        isChainMethod: true,
        maxChain: 60,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Sandwich Schillerkraft Lv 3',
        description: 'Schillerkraft Stufe 3 (1/1024 ohne Pin, 1/683 mit Pin)',
        defaultBaseOdds: 1024.0,
        oddsWithCharm: 682.67,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Ausbruch 60+ & Sandwich Lv 3 & Pin',
        description: 'Optimale Vorbereitung in Paldea (1/512)',
        defaultBaseOdds: 512.0,
        oddsWithCharm: 512.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Gen 9.5 (Legends: Z-A)
    if (generation == 9.5) {
      presets.add(const ShinyMethodPreset(
        name: 'Standard Wild / Soft Reset',
        description: 'Standard-Quote (1/4096 ohne Pin, 1/1365 mit Pin)',
        defaultBaseOdds: 4096.0,
        oddsWithCharm: 1365.33,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Masuda-Methode / Zucht',
        description: 'Zucht mit ausländischem Partner (1/683 ohne Pin, 1/512 mit Pin)',
        defaultBaseOdds: 682.67,
        oddsWithCharm: 512.0,
      ));
      presets.add(const ShinyMethodPreset(
        name: 'Spezial-Methode (Legends: Z-A)',
        description: 'Erhöhte Chance in Illumina City (1/512)',
        defaultBaseOdds: 512.0,
        oddsWithCharm: 512.0,
      ));
      _addCustomPreset(presets);
      return presets;
    }

    // Fallback
    presets.add(const ShinyMethodPreset(
      name: 'Standard Wild',
      defaultBaseOdds: 4096.0,
      oddsWithCharm: 1365.33,
    ));
    _addCustomPreset(presets);
    return presets;
  }

  static void _addCustomPreset(List<ShinyMethodPreset> list) {
    list.add(const ShinyMethodPreset(
      name: 'Benutzerdefiniert / Eigene Odds',
      description: 'Freie Eingabe von Nenner D und Multi-Spawns k',
      defaultBaseOdds: 4096.0,
      defaultSpawns: 1,
    ));
  }
}
