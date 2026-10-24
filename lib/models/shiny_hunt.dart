import 'dart:convert';

class ShinyPhaseEntry {
  final int phaseNumber;
  final int encounters;
  final int? caughtPokemonId;
  final String? caughtPokemonName;
  final DateTime completedAt;

  ShinyPhaseEntry({
    required this.phaseNumber,
    required this.encounters,
    this.caughtPokemonId,
    this.caughtPokemonName,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
    'phase_number': phaseNumber,
    'encounters': encounters,
    'caught_pokemon_id': caughtPokemonId,
    'caught_pokemon_name': caughtPokemonName,
    'completed_at': completedAt.millisecondsSinceEpoch,
  };

  factory ShinyPhaseEntry.fromMap(Map<String, dynamic> map) => ShinyPhaseEntry(
    phaseNumber: (map['phase_number'] as num?)?.toInt() ?? 1,
    encounters: (map['encounters'] as num?)?.toInt() ?? 0,
    caughtPokemonId: (map['caught_pokemon_id'] as num?)?.toInt(),
    caughtPokemonName: map['caught_pokemon_name']?.toString(),
    completedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['completed_at'] as num?)?.toInt() ?? 0,
    ),
  );

  Map<String, dynamic> toJson() => toMap();
  factory ShinyPhaseEntry.fromJson(Map<String, dynamic> json) =>
      ShinyPhaseEntry.fromMap(json);

  ShinyPhaseEntry copyWith({
    int? phaseNumber,
    int? encounters,
    int? caughtPokemonId,
    String? caughtPokemonName,
    DateTime? completedAt,
  }) {
    return ShinyPhaseEntry(
      phaseNumber: phaseNumber ?? this.phaseNumber,
      encounters: encounters ?? this.encounters,
      caughtPokemonId: caughtPokemonId ?? this.caughtPokemonId,
      caughtPokemonName: caughtPokemonName ?? this.caughtPokemonName,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class ShinyPauseInterval {
  final DateTime pausedAt;
  DateTime? resumedAt;

  ShinyPauseInterval({
    required this.pausedAt,
    this.resumedAt,
  });

  Map<String, dynamic> toMap() => {
    'paused_at': pausedAt.millisecondsSinceEpoch,
    'resumed_at': resumedAt?.millisecondsSinceEpoch,
  };

  factory ShinyPauseInterval.fromMap(Map<String, dynamic> map) => ShinyPauseInterval(
    pausedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['paused_at'] as num?)?.toInt() ?? 0,
    ),
    resumedAt: map['resumed_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch((map['resumed_at'] as num).toInt())
        : null,
  );

  Map<String, dynamic> toJson() => toMap();
  factory ShinyPauseInterval.fromJson(Map<String, dynamic> json) =>
      ShinyPauseInterval.fromMap(json);

  Duration? get duration {
    if (resumedAt == null) return null;
    final diff = resumedAt!.difference(pausedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  ShinyPauseInterval copyWith({
    DateTime? pausedAt,
    DateTime? resumedAt,
  }) {
    return ShinyPauseInterval(
      pausedAt: pausedAt ?? this.pausedAt,
      resumedAt: resumedAt ?? this.resumedAt,
    );
  }
}

class ShinyHunt {
  final String id;
  String title;
  final int pokemonId;
  final String pokemonName;
  final int? pokemonFormId;
  String? targetDexId;
  String? targetUniqueId;
  String game;
  double generation;
  String method;
  bool hasShinyCharm;
  double baseOdds;
  int spawnsPerEncounter;
  int currentEncounters;
  int priorPhaseEncounters;
  int incrementStep;
  String status; // 'active', 'paused', 'completed', 'failed'
  int phase;
  List<ShinyPhaseEntry> phaseHistory;
  List<ShinyPauseInterval> pauseHistory;
  int totalTimeSeconds;
  String? ballUsed;
  String? notes;
  String? huntingType;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt;
  int deletedAt; // 0 = active, >0 = deleted

  ShinyHunt({
    required this.id,
    required this.title,
    required this.pokemonId,
    required this.pokemonName,
    this.pokemonFormId,
    this.targetDexId,
    this.targetUniqueId,
    required this.game,
    required this.generation,
    required this.method,
    this.hasShinyCharm = false,
    required this.baseOdds,
    this.spawnsPerEncounter = 1,
    this.currentEncounters = 0,
    this.priorPhaseEncounters = 0,
    this.incrementStep = 1,
    this.status = 'active',
    this.phase = 1,
    List<ShinyPhaseEntry>? phaseHistory,
    List<ShinyPauseInterval>? pauseHistory,
    this.totalTimeSeconds = 0,
    this.ballUsed,
    this.notes,
    this.huntingType,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.deletedAt = 0,
  })  : phaseHistory = phaseHistory != null ? List<ShinyPhaseEntry>.from(phaseHistory) : [],
        pauseHistory = pauseHistory != null ? List<ShinyPauseInterval>.from(pauseHistory) : [];

  // Berechnete Werte für aktuelle Phase vs. Gesamt-Hunt
  int get currentPhaseRolls => currentEncounters * spawnsPerEncounter;
  int get totalEncounters => priorPhaseEncounters + currentEncounters;
  int get totalRolls => totalEncounters * spawnsPerEncounter;

  int get effectiveSpriteId =>
      (pokemonFormId != null && pokemonFormId! > 0) ? pokemonFormId! : pokemonId;

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pokemon_id': pokemonId,
      'pokemon_name': pokemonName,
      'pokemon_form_id': pokemonFormId,
      'target_dex_id': targetDexId,
      'target_unique_id': targetUniqueId,
      'game': game,
      'generation': generation,
      'method': method,
      'has_shiny_charm': hasShinyCharm ? 1 : 0,
      'base_odds': baseOdds,
      'spawns_per_encounter': spawnsPerEncounter,
      'current_encounters': currentEncounters,
      'prior_phase_encounters': priorPhaseEncounters,
      'increment_step': incrementStep,
      'status': status,
      'phase': phase,
      'phase_history': jsonEncode(phaseHistory.map((p) => p.toMap()).toList()),
      'pause_history': jsonEncode(pauseHistory.map((p) => p.toMap()).toList()),
      'total_time_seconds': totalTimeSeconds,
      'ball_used': ballUsed,
      'notes': notes,
      'hunting_type': huntingType,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'deleted_at': deletedAt,
    };
  }

  factory ShinyHunt.fromMap(Map<String, dynamic> map) {
    List<ShinyPhaseEntry> parsedHistory = [];
    final rawHistory = map['phase_history'];
    if (rawHistory != null) {
      if (rawHistory is String && rawHistory.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawHistory);
          if (decoded is List) {
            parsedHistory = decoded
                .map((item) => ShinyPhaseEntry.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          }
        } catch (_) {}
      } else if (rawHistory is List) {
        parsedHistory = rawHistory
            .map((item) => ShinyPhaseEntry.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    List<ShinyPauseInterval> parsedPauseHistory = [];
    final rawPauseHistory = map['pause_history'];
    if (rawPauseHistory != null) {
      if (rawPauseHistory is String && rawPauseHistory.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawPauseHistory);
          if (decoded is List) {
            parsedPauseHistory = decoded
                .map((item) => ShinyPauseInterval.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          }
        } catch (_) {}
      } else if (rawPauseHistory is List) {
        parsedPauseHistory = rawPauseHistory
            .map((item) => ShinyPauseInterval.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    return ShinyHunt(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      pokemonId: (map['pokemon_id'] as num?)?.toInt() ?? 0,
      pokemonName: map['pokemon_name']?.toString() ?? '',
      pokemonFormId: (map['pokemon_form_id'] as num?)?.toInt(),
      targetDexId: map['target_dex_id']?.toString(),
      targetUniqueId: map['target_unique_id']?.toString(),
      game: map['game']?.toString() ?? '',
      generation: (map['generation'] as num?)?.toDouble() ?? 1.0,
      method: map['method']?.toString() ?? 'Wild',
      hasShinyCharm: (map['has_shiny_charm'] as num?)?.toInt() == 1,
      baseOdds: (map['base_odds'] as num?)?.toDouble() ?? 4096.0,
      spawnsPerEncounter: (map['spawns_per_encounter'] as num?)?.toInt() ?? 1,
      currentEncounters: (map['current_encounters'] as num?)?.toInt() ?? 0,
      priorPhaseEncounters: (map['prior_phase_encounters'] as num?)?.toInt() ?? 0,
      incrementStep: (map['increment_step'] as num?)?.toInt() ?? 1,
      status: map['status']?.toString() ?? 'active',
      phase: (map['phase'] as num?)?.toInt() ?? 1,
      phaseHistory: parsedHistory,
      pauseHistory: parsedPauseHistory,
      totalTimeSeconds: (map['total_time_seconds'] as num?)?.toInt() ?? 0,
      ballUsed: map['ball_used']?.toString(),
      notes: map['notes']?.toString(),
      huntingType: map['hunting_type']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as num?)?.toInt() ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as num?)?.toInt() ?? 0,
      ),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['completed_at'] as num).toInt())
          : null,
      deletedAt: (map['deleted_at'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory ShinyHunt.fromJson(Map<String, dynamic> json) => ShinyHunt.fromMap(json);

  ShinyHunt copyWith({
    String? id,
    String? title,
    int? pokemonId,
    String? pokemonName,
    int? pokemonFormId,
    String? targetDexId,
    String? targetUniqueId,
    String? game,
    double? generation,
    String? method,
    bool? hasShinyCharm,
    double? baseOdds,
    int? spawnsPerEncounter,
    int? currentEncounters,
    int? priorPhaseEncounters,
    int? incrementStep,
    String? status,
    int? phase,
    List<ShinyPhaseEntry>? phaseHistory,
    List<ShinyPauseInterval>? pauseHistory,
    int? totalTimeSeconds,
    String? ballUsed,
    String? notes,
    String? huntingType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? deletedAt,
  }) {
    return ShinyHunt(
      id: id ?? this.id,
      title: title ?? this.title,
      pokemonId: pokemonId ?? this.pokemonId,
      pokemonName: pokemonName ?? this.pokemonName,
      pokemonFormId: pokemonFormId ?? this.pokemonFormId,
      targetDexId: targetDexId ?? this.targetDexId,
      targetUniqueId: targetUniqueId ?? this.targetUniqueId,
      game: game ?? this.game,
      generation: generation ?? this.generation,
      method: method ?? this.method,
      hasShinyCharm: hasShinyCharm ?? this.hasShinyCharm,
      baseOdds: baseOdds ?? this.baseOdds,
      spawnsPerEncounter: spawnsPerEncounter ?? this.spawnsPerEncounter,
      currentEncounters: currentEncounters ?? this.currentEncounters,
      priorPhaseEncounters: priorPhaseEncounters ?? this.priorPhaseEncounters,
      incrementStep: incrementStep ?? this.incrementStep,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      phaseHistory: phaseHistory ?? List.from(this.phaseHistory),
      pauseHistory: pauseHistory ?? List.from(this.pauseHistory),
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      ballUsed: ballUsed ?? this.ballUsed,
      notes: notes ?? this.notes,
      huntingType: huntingType ?? this.huntingType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
