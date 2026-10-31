import 'package:flutter/material.dart';

import '../../../models/dex_card_models.dart';
import '../../../models/dex_progress_models.dart';
import '../../../i18n/strings.g.dart';
import 'card_painter_renderer.dart';

/// Renders the complete statistical breakdown (gauge, KPIs, generation/variant bars,
/// type pills) for Dex Completion Cards.
class CardStatsSummary extends StatelessWidget {
  final DexProgressStats stats;
  final DexCardConfig config;
  final double scale;
  final bool isEn;
  final int gaps;
  final CardBoxDetails boxDetails;
  final CardSpecialStats specialStats;

  const CardStatsSummary({
    super.key,
    required this.stats,
    required this.config,
    required this.scale,
    required this.isEn,
    required this.gaps,
    required this.boxDetails,
    required this.specialStats,
  });

  @override
  Widget build(BuildContext context) {
    final is100 = stats.percentage >= 99.99 && stats.totalCount > 0;
    return config.ratio == DexCardRatio.portrait9_16
        ? _buildAnalystPortraitBody(isEn, is100, gaps, boxDetails, specialStats, scale)
        : _buildAnalystLandscapeBody(isEn, is100, gaps, boxDetails, specialStats, scale);
  }

  Widget _buildAnalystLandscapeBody(
    bool isEn,
    bool is100,
    int gaps,
    CardBoxDetails boxDetails,
    CardSpecialStats specialStats,
    double scale,
  ) {
    final formStats = _getFormVariantStats();
    final allGens = stats.generationStats;
    final effectiveGens = config.showOnlyStartedGenerations
        ? allGens.where((g) => g.caught > 0).toList()
        : allGens;
    final hasGenerations =
        config.showGenerations && effectiveGens.isNotEmpty;
    final hasVariants = config.showVariants && formStats.isNotEmpty;
    final hasKpi = config.showSpecialCollections || config.showBoxStats;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: Circular Progress Gauge Card
        Expanded(
          flex: 4,
          child: _buildCircularGaugeCard(isEn, is100, gaps, scale),
        ),
        SizedBox(width: 16 * scale + 4),

        // Right: KPI Grid + Sub-progress bars + Types
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KPI Cards Row (Shinies, Alphas, Ribbons, Boxes) - Well-proportioned Height
              if (hasKpi) ...[
                SizedBox(
                  height: 84 * scale + 18,
                  child: _buildKpiRow(isEn, boxDetails, specialStats, scale),
                ),
                SizedBox(height: 12 * scale + 2),
              ],

              // Generations & Variants Breakdown Section - Expanded to fill remaining vertical space
              if (hasGenerations && hasVariants)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildGenerationsCard(scale),
                      ),
                      SizedBox(width: 8 * scale + 2),
                      Expanded(
                        flex: 5,
                        child: _buildVariantsCard(scale),
                      ),
                    ],
                  ),
                )
              else if (hasGenerations)
                Expanded(
                  child: _buildGenerationsCard(scale),
                )
              else if (hasVariants)
                Expanded(
                  child: _buildVariantsCard(scale),
                )
              else
                const Spacer(),

              // Type Coverage Pills
              if (config.showTypes && stats.typeStats.isNotEmpty) ...[
                SizedBox(height: 8 * scale + 2),
                _buildTypeCoverageRow(isEn, scale),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalystPortraitBody(
    bool isEn,
    bool is100,
    int gaps,
    CardBoxDetails boxDetails,
    CardSpecialStats specialStats,
    double scale,
  ) {
    final formStats = _getFormVariantStats();
    final allGens = stats.generationStats;
    final effectiveGens = config.showOnlyStartedGenerations
        ? allGens.where((g) => g.caught > 0).toList()
        : allGens;
    final hasKpi = config.showSpecialCollections || config.showBoxStats;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Circular Gauge Card
          SizedBox(
            height: 160 * scale + 60,
            child: _buildCircularGaugeCard(isEn, is100, gaps, scale),
          ),
          SizedBox(height: 12 * scale),

          // KPI Cards Row
          if (hasKpi) ...[
            SizedBox(
              height: 70 * scale + 20,
              child: _buildKpiRow(isEn, boxDetails, specialStats, scale),
            ),
            SizedBox(height: 12 * scale),
          ],

          // Generations Breakdown
          if (config.showGenerations && effectiveGens.isNotEmpty) ...[
            _buildGenerationsCard(scale),
            SizedBox(height: 12 * scale),
          ],

          // Variants Breakdown
          if (config.showVariants && formStats.isNotEmpty) ...[
            _buildVariantsCard(scale),
            SizedBox(height: 12 * scale),
          ],

          // Type Coverage Pills
          if (config.showTypes && stats.typeStats.isNotEmpty)
            _buildTypeCoverageRow(isEn, scale),
        ],
      ),
    );
  }

  Widget _buildCircularGaugeCard(
    bool isEn,
    bool is100,
    int gaps,
    double scale,
  ) {
    return Container(
      padding: EdgeInsets.all(16.0 * scale + 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.65),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16 * scale + 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: CustomPaint(
                painter: CircularGaugePainter(
                  percentage: stats.percentage,
                  strokeWidth: 10.0 * scale + 2,
                  trackColor: Colors.white.withValues(alpha: 0.08),
                  progressColor: is100
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.percentage.toStringAsFixed(stats.percentage == 100.0 ? 0 : 1)}%',
                        style: TextStyle(
                          fontSize: 24.0 * scale + 4,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        is100
                            ? (isEn ? 'COMPLETE' : 'KOMPLETT')
                            : (isEn ? 'PROGRESS' : 'FORTSCHRITT'),
                        style: TextStyle(
                          fontSize: 8.0 * scale + 2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: is100
                              ? const Color(0xFF10B981)
                              : const Color(0xFF60A5FA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10 * scale + 2),
          Text(
            '${stats.caughtCount} / ${stats.totalCount} ${isEn ? 'Caught' : 'Gefangen'}',
            style: TextStyle(
              fontSize: 13.0 * scale + 2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE2E8F0),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2 * scale),
          Text(
            '$gaps ${isEn ? 'gaps remaining' : 'Lücken verbleibend'}',
            style: TextStyle(
              fontSize: 9.5 * scale + 1.5,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    bool isEn,
    CardBoxDetails boxDetails,
    CardSpecialStats specialStats,
    double scale,
  ) {
    final tiles = <Widget>[];

    if (config.showSpecialCollections) {
      final shinyPct = stats.totalCount > 0
          ? (stats.shinyCount / stats.totalCount * 100).toStringAsFixed(1)
          : '0.0';
      final alphaPct = stats.totalCount > 0
          ? (stats.alphaCount / stats.totalCount * 100).toStringAsFixed(1)
          : '0.0';

      tiles.add(
        Expanded(
          child: _buildMetricTile(
            emoji: '✨',
            title: isEn ? 'Shinies' : 'Shinies',
            value: '${stats.shinyCount}',
            subtitle: '$shinyPct% ${isEn ? 'of dex' : 'des Dex'}',
            scale: scale,
          ),
        ),
      );

      tiles.add(
        Expanded(
          child: _buildMetricTile(
            emoji: '🔥',
            title: isEn ? 'Alphas' : 'Alphas',
            value: '${stats.alphaCount}',
            subtitle: '$alphaPct% ${isEn ? 'of dex' : 'des Dex'}',
            scale: scale,
          ),
        ),
      );

      if (specialStats.ribbons > 0) {
        tiles.add(
          Expanded(
            child: _buildMetricTile(
              emoji: '🎀',
              title: isEn ? 'Ribbons' : 'Bänder',
              value: '${specialStats.ribbons}',
              subtitle: isEn ? 'Awarded' : 'Gesammelt',
              scale: scale,
            ),
          ),
        );
      }

      if (specialStats.teraTypes > 0) {
        tiles.add(
          Expanded(
            child: _buildMetricTile(
              emoji: '💎',
              title: isEn ? 'Tera Types' : 'Tera-Typen',
              value: '${specialStats.teraTypes}',
              subtitle: isEn ? 'Mastered' : 'Gemeistert',
              scale: scale,
            ),
          ),
        );
      }

      if (specialStats.languages > 0) {
        tiles.add(
          Expanded(
            child: _buildMetricTile(
              emoji: '🌐',
              title: isEn ? 'Languages' : 'Sprachen',
              value: '${specialStats.languages}',
              subtitle: isEn ? 'Collected' : 'Gesammelt',
              scale: scale,
            ),
          ),
        );
      }
    }

    if (config.showBoxStats) {
      final String boxSubtitle = boxDetails.partialBoxes > 0
          ? '${boxDetails.fullBoxes} ${isEn ? "full" : "voll"} • ${boxDetails.partialBoxes} ${isEn ? "part." : "teilw."} • ${boxDetails.gapsRemaining} ${isEn ? "gaps" : "Lücken"}'
          : '${boxDetails.fullBoxes} ${isEn ? "full" : "voll"} • ${boxDetails.gapsRemaining} ${isEn ? "gaps" : "Lücken"}';

      tiles.add(
        Expanded(
          child: _buildMetricTile(
            emoji: '📦',
            title: isEn ? 'Boxes' : 'PC-Boxen',
            value: '${boxDetails.totalBoxes}',
            subtitle: boxSubtitle,
            scale: scale,
          ),
        ),
      );
    }

    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i > 0) {
        children.add(SizedBox(width: 8 * scale + 2));
      }
      children.add(tiles[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildMetricTile({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale + 2,
        vertical: 8 * scale + 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 10 * scale + 2)),
              SizedBox(width: 4 * scale),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5 * scale + 1.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17.0 * scale + 3,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            style: TextStyle(
              fontSize: 8.5 * scale + 1,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationsCard(double scale, {int? maxItems}) {
    final allGens = stats.generationStats;
    final filteredGens = config.showOnlyStartedGenerations
        ? allGens.where((g) => g.caught > 0).toList()
        : allGens;
    final displayGens =
        maxItems != null ? filteredGens.take(maxItems).toList() : filteredGens;

    if (displayGens.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(12 * scale + 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.hasBoundedHeight;
          final titleWidget = Text(
            t.dex_progress_generations.toUpperCase(),
            style: TextStyle(
              fontSize: 9.0 * scale + 1.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          );

          // When container height is bounded and we have 4+ generations, distribute
          // the generation rows harmoniously using spaceBetween to eliminate the dark empty void.
          final minHeightNeeded = (displayGens.length * 16.0 + 36.0) * scale;
          final shouldSpace = isBounded &&
              constraints.maxHeight >= minHeightNeeded &&
              displayGens.length >= 4;

          if (shouldSpace) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                SizedBox(height: 6 * scale),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: displayGens
                        .map((gen) =>
                            _buildGenerationRow(gen, scale, isSpaced: true))
                        .toList(),
                  ),
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              SizedBox(height: 6 * scale),
              ...displayGens.map((gen) => _buildGenerationRow(gen, scale)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGenerationRow(
    ProgressItem gen,
    double scale, {
    bool compact = false,
    bool isSpaced = false,
  }) {
    final pct = gen.total > 0 ? (gen.caught / gen.total) : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isSpaced ? 0.0 : ((compact ? 3.5 : 5.0) * scale),
      ),
      child: Row(
        children: [
          SizedBox(
            width: (compact ? 96 : 120) * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                gen.name,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: (compact ? 9.0 : 10.0) * scale + 1.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
          SizedBox(width: 6 * scale),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: (compact ? 6 : 7) * scale + 1,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  gen.color ?? const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          SizedBox(width: 6 * scale),
          ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: (compact ? 62 : 78) * scale),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${gen.caught}/${gen.total}',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: (compact ? 8.5 : 9.5) * scale + 1.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsCard(double scale, {int? maxItems}) {
    final formStats = _getFormVariantStats();
    if (formStats.isEmpty) return const SizedBox.shrink();

    final displayForms =
        maxItems != null ? formStats.take(maxItems).toList() : formStats;

    return Container(
      padding: EdgeInsets.all(12 * scale + 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns =
              displayForms.length > 4 && constraints.maxWidth >= 400 * scale;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.dex_progress_forms.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.0 * scale + 1.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 6 * scale),
              if (useTwoColumns) ...[
                Builder(
                  builder: (context) {
                    final half = (displayForms.length + 1) ~/ 2;
                    final left = displayForms.take(half).toList();
                    final right = displayForms.skip(half).toList();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: left
                                .map((v) => _buildVariantRow(v, scale,
                                    compact: true))
                                .toList(),
                          ),
                        ),
                        SizedBox(width: 10 * scale + 2),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: right
                                .map((v) => _buildVariantRow(v, scale,
                                    compact: true))
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                if (constraints.hasBoundedHeight &&
                    displayForms.length >= 3 &&
                    constraints.maxHeight >=
                        (displayForms.length * 16.0 + 36.0) * scale)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: displayForms
                          .map((v) =>
                              _buildVariantRow(v, scale, isSpaced: true))
                          .toList(),
                    ),
                  )
                else
                  ...displayForms.map((v) => _buildVariantRow(v, scale)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildVariantRow(
    ProgressItem v,
    double scale, {
    bool compact = false,
    bool isSpaced = false,
  }) {
    final pct = v.total > 0 ? (v.caught / v.total) : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isSpaced ? 0.0 : ((compact ? 3.5 : 5.0) * scale),
      ),
      child: Row(
        children: [
          SizedBox(
            width: (compact ? 112 : 140) * scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                v.name,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: (compact ? 9.0 : 10.0) * scale + 1.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
          SizedBox(width: 6 * scale),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: (compact ? 6 : 7) * scale + 1,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  v.color ?? const Color(0xFF9333EA),
                ),
              ),
            ),
          ),
          SizedBox(width: 6 * scale),
          ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: (compact ? 62 : 78) * scale),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${v.caught}/${v.total}',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: (compact ? 8.5 : 9.5) * scale + 1.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ProgressItem> _getFormVariantStats() {
    return stats.variantStats
        .where((v) => v.key != 'shiny' && v.key != 'alpha')
        .toList();
  }

  Widget _buildTypeCoverageRow(bool isEn, double scale) {
    final displayTypes = stats.typeStats.take(config.typeDisplayLimit).toList();

    return Wrap(
      spacing: 6 * scale + 1,
      runSpacing: 4 * scale + 1,
      children: displayTypes.map((type) {
        final color = type.color ?? const Color(0xFF6390F0);
        final isBright =
            ThemeData.estimateBrightnessForColor(color) == Brightness.light;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 6 * scale + 2,
            vertical: 2.5 * scale + 1,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
          child: Text(
            '${type.name}: ${type.caught}/${type.total}',
            style: TextStyle(
              fontSize: 8.5 * scale + 1,
              fontWeight: FontWeight.w700,
              color: isBright ? Colors.black : Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}
