import 'dart:async';

import '../../../models/pokemon.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/database_service.dart';
import '../../../services/desktop_tracker/desktop_tracker_service.dart';
import '../../../services/desktop_tracker/evolution_chain_helper.dart';
import '../../../services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// Handles target Pokédex resolution, caught/shiny/alpha persistence,
/// event correction/deletion rollbacks, and evolution chain evaluation
/// for [DesktopTrackerScreen].
class DesktopTrackerDexController {
  final Map<int, Map<String, dynamic>?> _evoChainCache = {};
  int? _lastEvoPokemonId;
  String? _lastEvoDexKey;
  EvolutionCheckStatus? activeEvolutionStatus;

  /// Resolves the active [UserDex] by [dexId], falling back to the first dex.
  static UserDex? resolveTargetDex(DexProvider dexProvider, String? dexId) {
    final dexes = dexProvider.userDexes;
    if (dexes.isEmpty) return null;
    return dexes.cast<UserDex?>().firstWhere(
          (d) => d?.id == dexId,
          orElse: () => dexes.first,
        );
  }

  /// Resolves a Pokémon's localized display name or `#id` fallback.
  static String resolvePokemonName(DexProvider dexProvider, int pokemonId) {
    for (final p in dexProvider.allPokemon) {
      if (p.id == pokemonId) return p.nameDe;
    }
    return '#$pokemonId';
  }

  /// Persists caught/shiny/alpha flags for [pokemonId] in [targetDex].
  /// Returns `true` if [targetDex] was mutated.
  static Future<bool> persistCaughtStatus(
    DexProvider dexProvider,
    UserDex targetDex,
    int pokemonId, {
    bool isShiny = false,
    bool isAlpha = false,
    bool skipSaveIfUnchanged = false,
  }) async {
    final idStr = pokemonId.toString();
    var mutated = false;
    if (!targetDex.caughtIds.contains(idStr)) {
      targetDex.caughtIds.add(idStr);
      mutated = true;
    }
    if (isShiny && !targetDex.shinyIds.contains(idStr)) {
      targetDex.shinyIds.add(idStr);
      mutated = true;
    }
    if (isAlpha && !targetDex.alphaIds.contains(idStr)) {
      targetDex.alphaIds.add(idStr);
      mutated = true;
    }
    if (skipSaveIfUnchanged && !mutated) return false;

    try {
      await DatabaseService.instance.savePokemonStatus(
        targetDex.id,
        idStr,
        isCaught: true,
        isShiny: isShiny ? true : null,
        isAlpha: isAlpha ? true : null,
      );
    } catch (_) {
      // DatabaseService might be mocked or in memory in tests.
    }
    await dexProvider.saveUserDexAndSync(targetDex);
    return mutated;
  }

  /// Checks whether [events] has another caught entry for [pokemonId]
  /// outside [excludeIndex] (optionally requiring shiny/alpha).
  static bool hasOtherCaughtEvent(
    List<ScannerEvent> events,
    int excludeIndex,
    int pokemonId, {
    bool requireShiny = false,
    bool requireAlpha = false,
  }) {
    for (int i = 0; i < events.length; i++) {
      if (i == excludeIndex) continue;
      final ev = events[i];
      if (ev.type != ScannerEventType.caught || ev.pokemonId != pokemonId) {
        continue;
      }
      if (requireShiny && !ev.isShiny) continue;
      if (requireAlpha && !ev.isAlpha) continue;
      return true;
    }
    return false;
  }

  /// Corrects event at [index] in [events], rolling back auto-added dex flags
  /// when appropriate and persisting the corrected species.
  static Future<ScannerEvent> correctEventAt({
    required List<ScannerEvent> events,
    required int index,
    required int newPokemonId,
    required String newPokemonName,
    required DexProvider dexProvider,
    required UserDex? targetDex,
    required bool autoMarkCaught,
    bool? isShiny,
    bool? isAlpha,
  }) async {
    final oldEvent = events[index];
    final nextShiny = isShiny ?? oldEvent.isShiny;
    final nextAlpha = isAlpha ?? oldEvent.isAlpha;

    bool addedCaught = false;
    bool addedShiny = false;
    bool addedAlpha = false;
    bool removeCaught = false;
    bool removeShiny = false;
    bool removeAlpha = false;
    bool dexMutated = false;
    final oldId = oldEvent.pokemonId;

    if (targetDex != null && oldEvent.type == ScannerEventType.caught) {
      if (oldId != null) {
        final oldIdStr = oldId.toString();
        final changingSpecies = oldId != newPokemonId;
        removeCaught = oldEvent.autoAddedCaught &&
            changingSpecies &&
            !hasOtherCaughtEvent(events, index, oldId);
        removeShiny = oldEvent.autoAddedShiny &&
            (changingSpecies || !nextShiny) &&
            !hasOtherCaughtEvent(events, index, oldId, requireShiny: true);
        removeAlpha = oldEvent.autoAddedAlpha &&
            (changingSpecies || !nextAlpha) &&
            !hasOtherCaughtEvent(events, index, oldId, requireAlpha: true);

        if (removeCaught && targetDex.caughtIds.remove(oldIdStr)) {
          dexMutated = true;
        }
        if (removeShiny && targetDex.shinyIds.remove(oldIdStr)) {
          dexMutated = true;
        }
        if (removeAlpha && targetDex.alphaIds.remove(oldIdStr)) {
          dexMutated = true;
        }
      }

      if (autoMarkCaught) {
        final newIdStr = newPokemonId.toString();
        final sameId = oldId == newPokemonId;
        addedCaught = (sameId && oldEvent.autoAddedCaught) ||
            !targetDex.caughtIds.contains(newIdStr);
        addedShiny = nextShiny &&
            ((sameId && oldEvent.autoAddedShiny) ||
                !targetDex.shinyIds.contains(newIdStr));
        addedAlpha = nextAlpha &&
            ((sameId && oldEvent.autoAddedAlpha) ||
                !targetDex.alphaIds.contains(newIdStr));

        if (!targetDex.caughtIds.contains(newIdStr)) {
          targetDex.caughtIds.add(newIdStr);
          dexMutated = true;
        }
        if (nextShiny && !targetDex.shinyIds.contains(newIdStr)) {
          targetDex.shinyIds.add(newIdStr);
          dexMutated = true;
        }
        if (nextAlpha && !targetDex.alphaIds.contains(newIdStr)) {
          targetDex.alphaIds.add(newIdStr);
          dexMutated = true;
        }
      }
    }

    final updated = oldEvent.copyWith(
      pokemonId: newPokemonId,
      matchedName: newPokemonName,
      isShiny: nextShiny,
      isAlpha: nextAlpha,
      autoAddedCaught: addedCaught,
      autoAddedShiny: addedShiny,
      autoAddedAlpha: addedAlpha,
    );
    events[index] = updated;

    if (targetDex != null && dexMutated) {
      if (oldId != null && (removeCaught || removeShiny || removeAlpha)) {
        try {
          await DatabaseService.instance.savePokemonStatus(
            targetDex.id,
            oldId.toString(),
            isCaught: removeCaught ? false : null,
            isShiny: removeShiny ? false : null,
            isAlpha: removeAlpha ? false : null,
          );
        } catch (_) {}
      }
      if (autoMarkCaught) {
        try {
          await DatabaseService.instance.savePokemonStatus(
            targetDex.id,
            newPokemonId.toString(),
            isCaught: true,
            isShiny: nextShiny ? true : null,
            isAlpha: nextAlpha ? true : null,
          );
        } catch (_) {}
      }
      await dexProvider.saveUserDexAndSync(targetDex);
    }

    return updated;
  }

  /// Deletes event at [index] in [events] and rolls back any dex flags that
  /// were automatically added solely by that event.
  static Future<void> deleteEventAt({
    required List<ScannerEvent> events,
    required int index,
    required DexProvider dexProvider,
    required UserDex? targetDex,
  }) async {
    if (index < 0 || index >= events.length) return;
    final oldEvent = events[index];

    if (targetDex != null &&
        oldEvent.type == ScannerEventType.caught &&
        oldEvent.pokemonId != null) {
      final oldId = oldEvent.pokemonId!;
      final oldIdStr = oldId.toString();
      final removeCaught = oldEvent.autoAddedCaught &&
          !hasOtherCaughtEvent(events, index, oldId);
      final removeShiny = oldEvent.autoAddedShiny &&
          !hasOtherCaughtEvent(events, index, oldId, requireShiny: true);
      final removeAlpha = oldEvent.autoAddedAlpha &&
          !hasOtherCaughtEvent(events, index, oldId, requireAlpha: true);

      bool dexMutated = false;
      if (removeCaught && targetDex.caughtIds.remove(oldIdStr)) {
        dexMutated = true;
      }
      if (removeShiny && targetDex.shinyIds.remove(oldIdStr)) {
        dexMutated = true;
      }
      if (removeAlpha && targetDex.alphaIds.remove(oldIdStr)) {
        dexMutated = true;
      }

      events.removeAt(index);

      if (dexMutated) {
        try {
          await DatabaseService.instance.savePokemonStatus(
            targetDex.id,
            oldIdStr,
            isCaught: removeCaught ? false : null,
            isShiny: removeShiny ? false : null,
            isAlpha: removeAlpha ? false : null,
          );
        } catch (_) {}
        try {
          await dexProvider.saveUserDexAndSync(targetDex);
        } catch (_) {}
      }
      return;
    }

    events.removeAt(index);
  }

  /// Builds ranked top-10 candidate matches for event correction.
  static List<({int id, String name, double confidence})> buildCorrectionTop10({
    required ScannerEvent event,
    required PokemonFuzzyMatcher matcher,
    required Map<int, Pokemon> pokemonMap,
  }) {
    final rawRankedMap = <int, double>{};
    for (final alt in event.alternatives) {
      final prev = rawRankedMap[alt.pokemonId] ?? 0.0;
      if (alt.confidence > prev) rawRankedMap[alt.pokemonId] = alt.confidence;
    }
    for (final fuzzy in matcher.matchTopK(
      event.rawText,
      limit: 10,
      threshold: 0.20,
    )) {
      final prev = rawRankedMap[fuzzy.pokemonId] ?? 0.0;
      if (fuzzy.confidence > prev) {
        rawRankedMap[fuzzy.pokemonId] = fuzzy.confidence;
      }
    }
    if (event.pokemonId != null && !rawRankedMap.containsKey(event.pokemonId)) {
      rawRankedMap[event.pokemonId!] = event.confidence;
    }

    String resolveName(int id, [String? fallback]) =>
        pokemonMap[id]?.nameDe ?? fallback ?? '#$id';

    final list = rawRankedMap.entries
        .map(
          (e) => (
            id: e.key,
            name: resolveName(
              e.key,
              e.key == event.pokemonId ? event.matchedName : null,
            ),
            confidence: e.value,
          ),
        )
        .toList()
      ..sort((a, b) {
        final cmp = b.confidence.compareTo(a.confidence);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
    return list.take(10).toList(growable: false);
  }

  /// Refreshes cached evolution chain status for [event] against [activeDex]
  /// and notifies [onStatusChanged] when updated.
  void refreshEvolutionStatusFor({
    required ScannerEvent? event,
    required UserDex? activeDex,
    required DexProvider dexProvider,
    required String languageCode,
    required bool Function() isMounted,
    required void Function(EvolutionCheckStatus? status) onStatusChanged,
  }) {
    final pid = event?.pokemonId;
    if (pid == null || pid <= 0 || activeDex == null) {
      if (activeEvolutionStatus != null) {
        activeEvolutionStatus = null;
        onStatusChanged(null);
      }
      DesktopTrackerService.instance.updateEvolutionStatus(null);
      return;
    }

    final dexSig =
        '${activeDex.id}:${activeDex.caughtIds.length}:${activeDex.shinyIds.length}';
    if (_lastEvoPokemonId == pid &&
        _lastEvoDexKey == dexSig &&
        activeEvolutionStatus != null) {
      return;
    }
    _lastEvoPokemonId = pid;
    _lastEvoDexKey = dexSig;

    final byId = <int, Pokemon>{
      for (final p in dexProvider.allPokemon) p.id: p,
    };
    final target = byId[pid];
    if (target == null || target.evolutionChainId == -1) {
      activeEvolutionStatus = null;
      onStatusChanged(null);
      DesktopTrackerService.instance.updateEvolutionStatus(null);
      return;
    }

    final chainId = target.evolutionChainId;
    if (_evoChainCache.containsKey(chainId)) {
      final status = EvolutionChainHelper.evaluate(
        pokemonId: pid,
        chainData: _evoChainCache[chainId],
        activeDex: activeDex,
        pokemonById: byId,
        languageCode: languageCode,
      );
      activeEvolutionStatus = status;
      if (isMounted()) onStatusChanged(status);
      DesktopTrackerService.instance.updateEvolutionStatus(status);
      return;
    }

    unawaited(() async {
      try {
        final chain = await DatabaseService.instance.getEvolutionChain(chainId);
        _evoChainCache[chainId] = chain;
        if (!isMounted()) return;
        final status = EvolutionChainHelper.evaluate(
          pokemonId: pid,
          chainData: chain,
          activeDex: activeDex,
          pokemonById: byId,
          languageCode: languageCode,
        );
        activeEvolutionStatus = status;
        onStatusChanged(status);
        DesktopTrackerService.instance.updateEvolutionStatus(status);
      } catch (_) {
        // Ignore in isolated widget tests without sqlite
      }
    }());
  }
}
