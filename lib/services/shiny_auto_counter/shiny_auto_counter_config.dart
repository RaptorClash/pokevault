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
  final int blackLumaThreshold;
  final int whiteLumaThreshold;
  final List<CustomOcrPattern> customTriggerPatterns;
  final List<String> customResetPatterns;
  final bool playSoundOnCount;
  final bool playHapticOnCount;
  final bool playSoundOnShiny;
  final bool playHapticOnShiny;
  final bool autoPauseSlotOnShiny;
  final Map<int, String> slotToHuntOverrides;
  final bool usePerHuntMethodDefaults;
  final Map<String, ShinyAutoCounterSettings> huntSettingsOverrides;

  const ShinyAutoCounterSettings({
    this.detectionMode = ShinyHuntDetectionMode.wildEncounter,
    this.matchFilter = ShinyMatchFilter.allPokemon,
    this.useEventEncounterCount = true,
    this.enableBlackScreenReset = true,
    this.enableWhiteScreenReset = false,
    this.minResetCooldownMs = 1200,
    this.transitionMinDurationMs = 350,
    this.blackLumaThreshold = 18,
    this.whiteLumaThreshold = 240,
    this.customTriggerPatterns = const [],
    this.customResetPatterns = const [],
    this.playSoundOnCount = false,
    this.playHapticOnCount = true,
    this.playSoundOnShiny = true,
    this.playHapticOnShiny = true,
    this.autoPauseSlotOnShiny = true,
    this.slotToHuntOverrides = const {},
    this.usePerHuntMethodDefaults = false,
    this.huntSettingsOverrides = const {},
  });

  factory ShinyAutoCounterSettings.forHuntMethod(
    String method, {
    bool usePerHuntMethodDefaults = true,
  }) {
    final mode = ShinyHuntDetectionModeHelpers.defaultForHuntMethod(method);
    return ShinyAutoCounterSettings(
      detectionMode: mode,
      matchFilter: mode.defaultMatchFilter,
      usePerHuntMethodDefaults: usePerHuntMethodDefaults,
    );
  }

  /// Resolves the effective settings for [huntId] / [huntMethod]:
  /// 1. Explicit per-hunt override in [huntSettingsOverrides] wins.
  /// 2. If [usePerHuntMethodDefaults] is enabled, derives detection mode & filter
  ///    from [huntMethod] while inheriting global safety/transition preferences.
  /// 3. Otherwise falls back to this base settings object.
  ShinyAutoCounterSettings resolveForHunt({
    String? huntId,
    String? huntMethod,
  }) {
    if (huntId != null && huntSettingsOverrides.containsKey(huntId)) {
      return huntSettingsOverrides[huntId]!;
    }
    if (usePerHuntMethodDefaults &&
        huntMethod != null &&
        huntMethod.trim().isNotEmpty) {
      final mode = ShinyHuntDetectionModeHelpers.defaultForHuntMethod(huntMethod);
      return copyWith(
        detectionMode: mode,
        matchFilter: mode.defaultMatchFilter,
        huntSettingsOverrides: const {},
      );
    }
    return this;
  }

  ShinyAutoCounterSettings copyWith({
    ShinyHuntDetectionMode? detectionMode,
    ShinyMatchFilter? matchFilter,
    bool? useEventEncounterCount,
    bool? enableBlackScreenReset,
    bool? enableWhiteScreenReset,
    int? minResetCooldownMs,
    int? transitionMinDurationMs,
    int? blackLumaThreshold,
    int? whiteLumaThreshold,
    List<CustomOcrPattern>? customTriggerPatterns,
    List<String>? customResetPatterns,
    bool? playSoundOnCount,
    bool? playHapticOnCount,
    bool? playSoundOnShiny,
    bool? playHapticOnShiny,
    bool? autoPauseSlotOnShiny,
    Map<int, String>? slotToHuntOverrides,
    bool? usePerHuntMethodDefaults,
    Map<String, ShinyAutoCounterSettings>? huntSettingsOverrides,
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
      blackLumaThreshold:
          (blackLumaThreshold ?? this.blackLumaThreshold).clamp(5, 80),
      whiteLumaThreshold:
          (whiteLumaThreshold ?? this.whiteLumaThreshold).clamp(175, 252),
      customTriggerPatterns:
          customTriggerPatterns ?? this.customTriggerPatterns,
      customResetPatterns: customResetPatterns ?? this.customResetPatterns,
      playSoundOnCount: playSoundOnCount ?? this.playSoundOnCount,
      playHapticOnCount: playHapticOnCount ?? this.playHapticOnCount,
      playSoundOnShiny: playSoundOnShiny ?? this.playSoundOnShiny,
      playHapticOnShiny: playHapticOnShiny ?? this.playHapticOnShiny,
      autoPauseSlotOnShiny: autoPauseSlotOnShiny ?? this.autoPauseSlotOnShiny,
      slotToHuntOverrides: slotToHuntOverrides ?? this.slotToHuntOverrides,
      usePerHuntMethodDefaults:
          usePerHuntMethodDefaults ?? this.usePerHuntMethodDefaults,
      huntSettingsOverrides:
          huntSettingsOverrides ?? this.huntSettingsOverrides,
    );
  }

  /// Returns the minimum transition duration across base settings and all per-hunt overrides.
  int effectiveMinTransitionDurationMs() {
    int minMs = transitionMinDurationMs;
    for (final override in huntSettingsOverrides.values) {
      if (override.transitionMinDurationMs < minMs) {
        minMs = override.transitionMinDurationMs;
      }
    }
    return minMs;
  }

  /// Returns the most sensitive (highest) black luminance threshold across base and per-hunt overrides.
  int effectiveBlackLumaThreshold() {
    int maxBlack = blackLumaThreshold;
    for (final override in huntSettingsOverrides.values) {
      if (override.blackLumaThreshold > maxBlack) {
        maxBlack = override.blackLumaThreshold;
      }
    }
    return maxBlack;
  }

  /// Returns the most sensitive (lowest) white luminance threshold across base and per-hunt overrides.
  int effectiveWhiteLumaThreshold() {
    int minWhite = whiteLumaThreshold;
    for (final override in huntSettingsOverrides.values) {
      if (override.whiteLumaThreshold < minWhite) {
        minWhite = override.whiteLumaThreshold;
      }
    }
    return minWhite;
  }

  /// Builds combined custom patterns for `OcrDetectionEngine.updateCustomPatterns`,
  /// including any per-hunt custom trigger/reset patterns.
  List<CustomOcrPattern> buildEngineCustomPatterns() {
    final result = <CustomOcrPattern>[];
    final seenIds = <String>{};

    void addRuleSet(ShinyAutoCounterSettings s, String? huntIdScope) {
      for (final p in s.customTriggerPatterns) {
        final scopedId =
            huntIdScope != null ? 'shiny_hunt:$huntIdScope:${p.id}' : p.id;
        if (seenIds.add(scopedId)) {
          result.add(
            CustomOcrPattern(
              id: scopedId,
              template: p.template,
              eventType: p.eventType,
              enabled: p.enabled,
            ),
          );
        }
      }
      for (int i = 0; i < s.customResetPatterns.length; i++) {
        final phrase = s.customResetPatterns[i].trim();
        if (phrase.isEmpty) continue;
        final id = huntIdScope != null
            ? 'shiny_hunt:$huntIdScope:reset_$i'
            : 'shiny_reset_$i';
        if (seenIds.add(id)) {
          result.add(
            CustomOcrPattern(
              id: id,
              template: phrase,
              eventType: ScannerEventType.customReset,
              enabled: true,
            ),
          );
        }
      }
    }

    addRuleSet(this, null);
    for (final entry in huntSettingsOverrides.entries) {
      addRuleSet(entry.value, entry.key);
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
      'blackLumaThreshold': blackLumaThreshold,
      'whiteLumaThreshold': whiteLumaThreshold,
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
      'usePerHuntMethodDefaults': usePerHuntMethodDefaults,
      if (huntSettingsOverrides.isNotEmpty)
        'huntSettingsOverrides': {
          for (final e in huntSettingsOverrides.entries)
            e.key: e.value.copyWith(huntSettingsOverrides: const {}).toMap(),
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

    final huntOverrides = <String, ShinyAutoCounterSettings>{};
    final rawHuntOverrides = map['huntSettingsOverrides'];
    if (rawHuntOverrides is Map) {
      for (final e in rawHuntOverrides.entries) {
        final hid = e.key.toString();
        if (hid.isNotEmpty && e.value is Map) {
          huntOverrides[hid] = ShinyAutoCounterSettings.fromMap(
            Map<String, dynamic>.from(e.value as Map),
          ).copyWith(huntSettingsOverrides: const {});
        }
      }
    }

    return ShinyAutoCounterSettings(
      detectionMode: mode,
      matchFilter: filter,
      useEventEncounterCount: map['useEventEncounterCount'] as bool? ?? true,
      enableBlackScreenReset: map['enableBlackScreenReset'] as bool? ?? true,
      enableWhiteScreenReset: map['enableWhiteScreenReset'] as bool? ?? false,
      minResetCooldownMs:
          ((map['minResetCooldownMs'] as num?)?.toInt() ?? 1200)
              .clamp(200, 30000),
      transitionMinDurationMs:
          ((map['transitionMinDurationMs'] as num?)?.toInt() ?? 350)
              .clamp(150, 5000),
      blackLumaThreshold:
          ((map['blackLumaThreshold'] as num?)?.toInt() ?? 18).clamp(5, 80),
      whiteLumaThreshold:
          ((map['whiteLumaThreshold'] as num?)?.toInt() ?? 240).clamp(175, 252),
      customTriggerPatterns: List.unmodifiable(triggers),
      customResetPatterns: List.unmodifiable(resets),
      playSoundOnCount: map['playSoundOnCount'] as bool? ?? false,
      playHapticOnCount: map['playHapticOnCount'] as bool? ?? true,
      playSoundOnShiny: map['playSoundOnShiny'] as bool? ?? true,
      playHapticOnShiny: map['playHapticOnShiny'] as bool? ?? true,
      autoPauseSlotOnShiny: map['autoPauseSlotOnShiny'] as bool? ?? true,
      slotToHuntOverrides: Map.unmodifiable(overrides),
      usePerHuntMethodDefaults:
          map['usePerHuntMethodDefaults'] as bool? ?? false,
      huntSettingsOverrides: Map.unmodifiable(huntOverrides),
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
