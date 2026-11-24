import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../scanner_core/models/scanner_event.dart';
import '../scanner_core/models/scanner_settings.dart';

/// Detection preset for a Shiny-Hunt auto-counter session.
enum ShinyHuntDetectionMode {
  wildEncounter,
  softReset,
  eggHatch,
  screenTransitionOnly,
}

/// Filter controlling which recognized Pokémon trigger an encounter increment.
enum ShinyMatchFilter {
  allPokemon,
  targetPokemonOnly,
}

extension ShinyHuntDetectionModeHelpers on ShinyHuntDetectionMode {
  static ShinyHuntDetectionMode defaultForHuntMethod(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('soft reset') ||
        lower.contains('reset') ||
        lower.contains('starter') ||
        lower.contains('static') ||
        lower.contains('gift') ||
        lower.contains('geschenk')) {
      return ShinyHuntDetectionMode.softReset;
    }
    if (lower.contains('masuda') ||
        lower.contains('egg') ||
        lower.contains('ei') ||
        lower.contains('breed') ||
        lower.contains('zucht')) {
      return ShinyHuntDetectionMode.eggHatch;
    }
    if (lower.contains('outbreak') && lower.contains('arceus')) {
      return ShinyHuntDetectionMode.screenTransitionOnly;
    }
    return ShinyHuntDetectionMode.wildEncounter;
  }

  ShinyMatchFilter get defaultMatchFilter => switch (this) {
        ShinyHuntDetectionMode.wildEncounter => ShinyMatchFilter.allPokemon,
        ShinyHuntDetectionMode.softReset => ShinyMatchFilter.targetPokemonOnly,
        ShinyHuntDetectionMode.eggHatch => ShinyMatchFilter.targetPokemonOnly,
        ShinyHuntDetectionMode.screenTransitionOnly =>
          ShinyMatchFilter.allPokemon,
      };
}

/// Persistent configuration for the Shiny-Hunt visual auto-counter.
class ShinyAutoCounterSettings {
  static const String prefsKey = 'shiny_auto_counter_settings_v1';

  final ShinyHuntDetectionMode detectionMode;
  final ShinyMatchFilter matchFilter;
  final bool useEventEncounterCount;
  final bool enableBlackScreenReset;
  final bool enableWhiteScreenReset;
  final int minResetCooldownMs;
  final int transitionMinDurationMs;
  final List<CustomOcrPattern> customTriggerPatterns;
  final List<String> customResetPatterns;
  final bool playSoundOnCount;
  final bool playHapticOnCount;
  final bool playSoundOnShiny;
  final bool playHapticOnShiny;
  final bool autoPauseSlotOnShiny;
  final Map<int, String> slotToHuntOverrides;

  const ShinyAutoCounterSettings({
    this.detectionMode = ShinyHuntDetectionMode.wildEncounter,
    this.matchFilter = ShinyMatchFilter.allPokemon,
    this.useEventEncounterCount = true,
    this.enableBlackScreenReset = true,
    this.enableWhiteScreenReset = true,
    this.minResetCooldownMs = 1200,
    this.transitionMinDurationMs = 350,
    this.customTriggerPatterns = const [],
    this.customResetPatterns = const [],
    this.playSoundOnCount = false,
    this.playHapticOnCount = true,
    this.playSoundOnShiny = true,
    this.playHapticOnShiny = true,
    this.autoPauseSlotOnShiny = true,
    this.slotToHuntOverrides = const {},
  });

  factory ShinyAutoCounterSettings.forHuntMethod(String method) {
    final mode = ShinyHuntDetectionModeHelpers.defaultForHuntMethod(method);
    return ShinyAutoCounterSettings(
      detectionMode: mode,
      matchFilter: mode.defaultMatchFilter,
    );
  }

  ShinyAutoCounterSettings copyWith({
    ShinyHuntDetectionMode? detectionMode,
    ShinyMatchFilter? matchFilter,
    bool? useEventEncounterCount,
    bool? enableBlackScreenReset,
    bool? enableWhiteScreenReset,
    int? minResetCooldownMs,
    int? transitionMinDurationMs,
    List<CustomOcrPattern>? customTriggerPatterns,
    List<String>? customResetPatterns,
    bool? playSoundOnCount,
    bool? playHapticOnCount,
    bool? playSoundOnShiny,
    bool? playHapticOnShiny,
    bool? autoPauseSlotOnShiny,
    Map<int, String>? slotToHuntOverrides,
  }) {
    return ShinyAutoCounterSettings(
      detectionMode: detectionMode ?? this.detectionMode,
      matchFilter: matchFilter ?? this.matchFilter,
      useEventEncounterCount:
          useEventEncounterCount ?? this.useEventEncounterCount,
      enableBlackScreenReset:
          enableBlackScreenReset ?? this.enableBlackScreenReset,
      enableWhiteScreenReset:
          enableWhiteScreenReset ?? this.enableWhiteScreenReset,
      minResetCooldownMs:
          (minResetCooldownMs ?? this.minResetCooldownMs).clamp(200, 30000),
      transitionMinDurationMs:
          (transitionMinDurationMs ?? this.transitionMinDurationMs)
              .clamp(150, 5000),
      customTriggerPatterns:
          customTriggerPatterns ?? this.customTriggerPatterns,
      customResetPatterns: customResetPatterns ?? this.customResetPatterns,
      playSoundOnCount: playSoundOnCount ?? this.playSoundOnCount,
      playHapticOnCount: playHapticOnCount ?? this.playHapticOnCount,
      playSoundOnShiny: playSoundOnShiny ?? this.playSoundOnShiny,
      playHapticOnShiny: playHapticOnShiny ?? this.playHapticOnShiny,
      autoPauseSlotOnShiny: autoPauseSlotOnShiny ?? this.autoPauseSlotOnShiny,
      slotToHuntOverrides: slotToHuntOverrides ?? this.slotToHuntOverrides,
    );
  }

  /// Builds combined custom patterns for `OcrDetectionEngine.updateCustomPatterns`.
  List<CustomOcrPattern> buildEngineCustomPatterns() {
    final result = <CustomOcrPattern>[...customTriggerPatterns];
    for (int i = 0; i < customResetPatterns.length; i++) {
      final phrase = customResetPatterns[i].trim();
      if (phrase.isEmpty) continue;
      result.add(
        CustomOcrPattern(
          id: 'shiny_reset_$i',
          template: phrase,
          eventType: ScannerEventType.customReset,
          enabled: true,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Map<String, dynamic> toMap() {
    return {
      'detectionMode': detectionMode.name,
      'matchFilter': matchFilter.name,
      'useEventEncounterCount': useEventEncounterCount,
      'enableBlackScreenReset': enableBlackScreenReset,
      'enableWhiteScreenReset': enableWhiteScreenReset,
      'minResetCooldownMs': minResetCooldownMs,
      'transitionMinDurationMs': transitionMinDurationMs,
      'customTriggerPatterns':
          customTriggerPatterns.map((p) => p.toMap()).toList(),
      'customResetPatterns': customResetPatterns,
      'playSoundOnCount': playSoundOnCount,
      'playHapticOnCount': playHapticOnCount,
      'playSoundOnShiny': playSoundOnShiny,
      'playHapticOnShiny': playHapticOnShiny,
      'autoPauseSlotOnShiny': autoPauseSlotOnShiny,
      'slotToHuntOverrides': {
        for (final e in slotToHuntOverrides.entries) e.key.toString(): e.value,
      },
    };
  }

  factory ShinyAutoCounterSettings.fromMap(Map<String, dynamic> map) {
    var mode = ShinyHuntDetectionMode.wildEncounter;
    final modeStr = map['detectionMode']?.toString();
    for (final v in ShinyHuntDetectionMode.values) {
      if (v.name == modeStr) {
        mode = v;
        break;
      }
    }

    var filter = mode.defaultMatchFilter;
    final filterStr = map['matchFilter']?.toString();
    for (final v in ShinyMatchFilter.values) {
      if (v.name == filterStr) {
        filter = v;
        break;
      }
    }

    final triggers = <CustomOcrPattern>[];
    final rawTriggers = map['customTriggerPatterns'];
    if (rawTriggers is List) {
      for (final item in rawTriggers) {
        if (item is Map) {
          final parsed =
              CustomOcrPattern.fromMap(Map<String, dynamic>.from(item));
          if (parsed.template.trim().isNotEmpty) {
            triggers.add(parsed);
          }
        }
      }
    }

    final resets = <String>[];
    final rawResets = map['customResetPatterns'];
    if (rawResets is List) {
      for (final item in rawResets) {
        final s = item.toString().trim();
        if (s.isNotEmpty) resets.add(s);
      }
    }

    final overrides = <int, String>{};
    final rawOverrides = map['slotToHuntOverrides'];
    if (rawOverrides is Map) {
      for (final e in rawOverrides.entries) {
        final slotId = int.tryParse(e.key.toString());
        final huntId = e.value?.toString() ?? '';
        if (slotId != null && huntId.isNotEmpty) {
          overrides[slotId] = huntId;
        }
      }
    }

    return ShinyAutoCounterSettings(
      detectionMode: mode,
      matchFilter: filter,
      useEventEncounterCount: map['useEventEncounterCount'] as bool? ?? true,
      enableBlackScreenReset: map['enableBlackScreenReset'] as bool? ?? true,
      enableWhiteScreenReset: map['enableWhiteScreenReset'] as bool? ?? true,
      minResetCooldownMs:
          ((map['minResetCooldownMs'] as num?)?.toInt() ?? 1200)
              .clamp(200, 30000),
      transitionMinDurationMs:
          ((map['transitionMinDurationMs'] as num?)?.toInt() ?? 350)
              .clamp(150, 5000),
      customTriggerPatterns: List.unmodifiable(triggers),
      customResetPatterns: List.unmodifiable(resets),
      playSoundOnCount: map['playSoundOnCount'] as bool? ?? false,
      playHapticOnCount: map['playHapticOnCount'] as bool? ?? true,
      playSoundOnShiny: map['playSoundOnShiny'] as bool? ?? true,
      playHapticOnShiny: map['playHapticOnShiny'] as bool? ?? true,
      autoPauseSlotOnShiny: map['autoPauseSlotOnShiny'] as bool? ?? true,
      slotToHuntOverrides: Map.unmodifiable(overrides),
    );
  }

  static Future<ShinyAutoCounterSettings?> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return ShinyAutoCounterSettings.fromMap(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveToPrefs(ShinyAutoCounterSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(settings.toMap()));
    } catch (_) {}
  }
}
