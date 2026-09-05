import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import 'shiny_logic_helper.dart';

class BreedingCalcArgs {
  final int startId;
  final int targetId;
  final bool useOnlyCaught;
  final Set<int> caughtBaseIds;
  final List<Pokemon> allPokemon;

  BreedingCalcArgs({
    required this.startId,
    required this.targetId,
    required this.useOnlyCaught,
    required this.caughtBaseIds,
    required this.allPokemon,
  });
}

class BreedingLogicHelper {
  static Future<List<List<int>>> calculatePathsInBackground(
    BreedingCalcArgs args,
  ) async {
    return await compute(_calculatePathTask, args);
  }
}

List<List<int>> _calculatePathTask(BreedingCalcArgs args) {
  final startId = args.startId;
  final targetId = args.targetId;
  final useOnlyCaught = args.useOnlyCaught;
  final caughtBaseIds = args.caughtBaseIds;
  final allPokemon = args.allPokemon;

  if (startId == targetId) {
    return [
      [startId],
    ];
  }
  if (startId == 132) {
    return [
      [132, targetId],
    ];
  }

  Map<int, List<String>> eggGroups = {};
  for (var p in allPokemon) {
    eggGroups[p.id] = p.eggGroups;
  }

  Map<int, List<List<int>>> pathsToNode = {
    startId: [
      [startId],
    ],
  };
  Queue<int> queue = Queue();
  queue.add(startId);
  int? targetDepth;

  while (queue.isNotEmpty) {
    int current = queue.removeFirst();
    int currentDepth = pathsToNode[current]!.first.length;

    if (targetDepth != null && currentDepth >= targetDepth) continue;
    if (ShinyLogicHelper.isBaby(current)) continue;

    var currentGroups = eggGroups[current] ?? [];

    for (int nextId = 1; nextId <= 251; nextId++) {
      final nextPoke = allPokemon.where((p) => p.id == nextId).firstOrNull;
      if (nextPoke == null) continue;

      if (!ShinyLogicHelper.isBreedable(nextPoke) &&
          !ShinyLogicHelper.isBaby(nextId)) {
        continue;
      }

      int baseNextId = ShinyLogicHelper.getBaseForm(nextId);
      final baseNextPoke = allPokemon
          .where((p) => p.id == baseNextId)
          .firstOrNull;

      if (useOnlyCaught &&
          nextId != targetId &&
          !caughtBaseIds.contains(baseNextId)) {
        continue;
      }

      if (baseNextPoke != null) {
        if (nextId == targetId) {
          if (startId != 132 &&
              (baseNextPoke.genderRate == -1 || baseNextPoke.genderRate == 0)) {
            continue;
          }
        } else {
          if (baseNextPoke.genderRate == -1 ||
              baseNextPoke.genderRate == 0 ||
              baseNextPoke.genderRate == 8) {
            continue;
          }
        }
      }

      var nextGroups = eggGroups[nextId] ?? [];
      if (ShinyLogicHelper.isBaby(nextId)) {
        int adultId = ShinyLogicHelper.getAdultForBaby(nextId);
        nextGroups = eggGroups[adultId] ?? [];
      }

      bool sharesGroup = currentGroups.any((g) => nextGroups.contains(g));
      if (sharesGroup) {
        bool isNewNode = !pathsToNode.containsKey(nextId);
        bool isSameDepth =
            !isNewNode && pathsToNode[nextId]!.first.length == currentDepth + 1;

        if (isNewNode || isSameDepth) {
          if (isNewNode) pathsToNode[nextId] = [];
          for (var p in pathsToNode[current]!) {
            if (!p.contains(nextId)) {
              pathsToNode[nextId]!.add(List<int>.from(p)..add(nextId));
            }
          }

          if (isNewNode) {
            if (nextId == targetId) {
              targetDepth = currentDepth + 1;
            } else {
              queue.add(nextId);
            }
          }
        }
      }
    }
  }

  List<List<int>> validPaths = pathsToNode[targetId] ?? [];
  Map<String, List<int>> uniquePathsMap = {};

  for (var p in validPaths) {
    String routeKey = 'direct';
    if (p.length > 2) {
      int intermediateBase = ShinyLogicHelper.getBaseForm(p[1]);
      routeKey = 'via_$intermediateBase';
    }

    if (!uniquePathsMap.containsKey(routeKey) ||
        p.length < uniquePathsMap[routeKey]!.length) {
      uniquePathsMap[routeKey] = p;
    }
  }

  List<List<int>> finalPaths = uniquePathsMap.values.toList();
  finalPaths.sort((a, b) => a.length.compareTo(b.length));
  if (finalPaths.length > 5) finalPaths = finalPaths.sublist(0, 5);

  return finalPaths;
}
