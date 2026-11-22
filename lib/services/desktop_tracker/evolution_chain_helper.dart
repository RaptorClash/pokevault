import '../../models/pokemon.dart';
import '../../models/user_dex.dart';

/// Structured summary of whether later evolutions of a scanned Pokémon are still missing.
class EvolutionCheckStatus {
  final int pokemonId;
  final int totalFutureCount;
  final List<int> missingIds;
  final List<String> missingNames;
  final String languageCode;

  const EvolutionCheckStatus({
    required this.pokemonId,
    required this.totalFutureCount,
    required this.missingIds,
    required this.missingNames,
    this.languageCode = 'de',
  });

  bool get hasEvolutions => totalFutureCount > 0;
  bool get hasMissingEvolutions => missingIds.isNotEmpty;

  String get summaryLabel {
    if (totalFutureCount == 0) return '';
    if (missingNames.isEmpty) {
      return languageCode == 'de'
          ? 'Alle Entw. ✓ Im Dex'
          : 'All evos ✓ Caught';
    }
    final shown = missingNames.take(2).join(', ');
    final extra = missingNames.length > 2 ? ' +${missingNames.length - 2}' : '';
    return languageCode == 'de'
        ? 'Entw.: $shown$extra fehlt!'
        : 'Evo: $shown$extra missing!';
  }

  /// Concise single-line label for native Win32 HUD overlays.
  String get hudShortLabel {
    if (totalFutureCount == 0) return '';
    if (missingNames.isEmpty) {
      return languageCode == 'de' ? 'Entw.: Alle ✓' : 'Evos: All ✓';
    }
    final first = missingNames.first;
    final extra = missingNames.length > 1 ? ' +${missingNames.length - 1}' : '';
    return languageCode == 'de'
        ? 'Entw.: $first$extra fehlt!'
        : 'Evo: $first$extra missing!';
  }
}

/// Evaluates missing descendant evolutions for any Pokémon ID using a parsed `evolutions.chain_json` tree.
class EvolutionChainHelper {
  const EvolutionChainHelper._();

  static EvolutionCheckStatus evaluate({
    required int pokemonId,
    required Map<String, dynamic>? chainData,
    required UserDex? activeDex,
    required Map<int, Pokemon> pokemonById,
    String languageCode = 'de',
  }) {
    if (chainData == null || activeDex == null) {
      return EvolutionCheckStatus(
        pokemonId: pokemonId,
        totalFutureCount: 0,
        missingIds: const [],
        missingNames: const [],
        languageCode: languageCode,
      );
    }

    final targetNode = _findSpeciesNode(chainData, pokemonId);
    if (targetNode == null) {
      return EvolutionCheckStatus(
        pokemonId: pokemonId,
        totalFutureCount: 0,
        missingIds: const [],
        missingNames: const [],
        languageCode: languageCode,
      );
    }

    final futureIds = <int>[];
    final seen = <int>{};
    _collectDescendantIds(targetNode, futureIds, seen);

    final caughtSet = activeDex.isShinyDex
        ? activeDex.shinyIds.toSet()
        : activeDex.caughtIds.toSet();

    final missingIds = <int>[];
    final missingNames = <String>[];
    for (final evoId in futureIds) {
      if (!caughtSet.contains(evoId.toString())) {
        missingIds.add(evoId);
        final pkmn = pokemonById[evoId];
        final name = pkmn?.getName(languageCode) ?? '#$evoId';
        missingNames.add(name);
      }
    }

    return EvolutionCheckStatus(
      pokemonId: pokemonId,
      totalFutureCount: futureIds.length,
      missingIds: List.unmodifiable(missingIds),
      missingNames: List.unmodifiable(missingNames),
      languageCode: languageCode,
    );
  }

  static Map<String, dynamic>? _findSpeciesNode(
    Map<String, dynamic> node,
    int speciesId,
  ) {
    final currentId = (node['species_id'] as num?)?.toInt();
    if (currentId == speciesId) return node;
    final children = node['evolves_to'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          final found = _findSpeciesNode(child, speciesId);
          if (found != null) return found;
        } else if (child is Map) {
          final found = _findSpeciesNode(Map<String, dynamic>.from(child), speciesId);
          if (found != null) return found;
        }
      }
    }
    return null;
  }

  static void _collectDescendantIds(
    Map<String, dynamic> node,
    List<int> outIds,
    Set<int> seen,
  ) {
    final children = node['evolves_to'];
    if (children is! List) return;
    for (final child in children) {
      final map = child is Map<String, dynamic>
          ? child
          : (child is Map ? Map<String, dynamic>.from(child) : null);
      if (map == null) continue;
      final evoId = (map['species_id'] as num?)?.toInt();
      if (evoId != null && evoId > 0 && seen.add(evoId)) {
        outIds.add(evoId);
      }
      _collectDescendantIds(map, outIds, seen);
    }
  }
}
