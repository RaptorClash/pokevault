import 'package:flutter/material.dart';

/// Represents a single progress row or category in the dex statistics.
class ProgressItem {
  final String key;
  final String name;
  final String? subtitle;
  final int caught;
  final int total;
  final double percentage;
  final Color? color;
  final bool isComplete;

  const ProgressItem({
    required this.key,
    required this.name,
    this.subtitle,
    required this.caught,
    required this.total,
    required this.percentage,
    this.color,
    required this.isComplete,
  });

  factory ProgressItem.create({
    required String key,
    required String name,
    String? subtitle,
    required int caught,
    required int total,
    Color? color,
  }) {
    final double pct = total > 0 ? (caught / total) * 100.0 : 0.0;
    return ProgressItem(
      key: key,
      name: name,
      subtitle: subtitle,
      caught: caught,
      total: total,
      percentage: pct,
      color: color,
      isComplete: total > 0 && caught >= total,
    );
  }
}

/// Comprehensive progress model containing aggregated counts, percentages,
/// and breakdowns across generations, types, and forms/variants.
class DexProgressStats {
  final int totalCount;
  final int caughtCount;
  final double percentage;
  final int shinyCount;
  final int alphaCount;
  final List<ProgressItem> generationStats;
  final List<ProgressItem> typeStats;
  final List<ProgressItem> variantStats;

  const DexProgressStats({
    required this.totalCount,
    required this.caughtCount,
    required this.percentage,
    required this.shinyCount,
    required this.alphaCount,
    required this.generationStats,
    required this.typeStats,
    required this.variantStats,
  });

  factory DexProgressStats.empty() {
    return const DexProgressStats(
      totalCount: 0,
      caughtCount: 0,
      percentage: 0.0,
      shinyCount: 0,
      alphaCount: 0,
      generationStats: [],
      typeStats: [],
      variantStats: [],
    );
  }
}
