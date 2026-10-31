import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/dex_card_models.dart';
import '../../models/dex_progress_models.dart';
import '../../models/dex_view_models.dart';
import '../../models/user_dex.dart';
import '../../utils/dex_logic_helper.dart';
import '../../i18n/strings.g.dart';

/// Customizable Living Dex Completion Card widget supporting 4 stats-focused design styles
/// and 3 aspect ratios (16:9 Landscape, 1:1 Square, 9:16 Story/Portrait).
class DexCompletionCard extends StatelessWidget {
  final UserDex dex;
  final DexProgressStats stats;
  final List<DexDisplayEntry> entries;
  final DexCardConfig config;

  const DexCompletionCard({
    super.key,
    required this.dex,
    required this.stats,
    required this.entries,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final lang = LocaleSettings.currentLocale.languageCode;
    final isEn = lang == 'en';

    return AspectRatio(
      aspectRatio: config.ratio.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Base reference dimensions for scaling content smoothly
          final targetWidth = config.ratio.exportDimensions.width;
          final scale = (constraints.maxWidth / targetWidth).clamp(0.2, 1.0);

          Widget cardContent = switch (config.style) {
            DexCardStyle.analyst => _buildAnalystCard(context, isEn, scale),
            DexCardStyle.certificate =>
              _buildCertificateCard(context, isEn, scale),
            DexCardStyle.mosaic => _buildMosaicCard(context, isEn, scale),
            DexCardStyle.minimalist =>
              _buildMinimalistCard(context, isEn, scale),
          };

          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * scale + 4),
            ),
            child: cardContent,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESIGN 1: THE ANALYST (Infografik / Dashboard)
  // ---------------------------------------------------------------------------
  Widget _buildAnalystCard(BuildContext context, bool isEn, double scale) {
    final is100 = stats.percentage >= 99.99 && stats.totalCount > 0;
    final gaps = math.max(0, stats.totalCount - stats.caughtCount);
    final boxDetails = _calculateBoxDetails();
    final specialStats = _calculateSpecialStats();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D121C), Color(0xFF151D2C), Color(0xFF0D121C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background Watermark Artwork
          if (config.hasWatermark)
            Positioned(
              right: -30 * scale,
              bottom: -40 * scale,
              width: 480 * scale + 100,
              height: 480 * scale + 100,
              child: _buildWatermarkImage(),
            ),

          // Main Card Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(24.0 * scale + 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header
                  _buildAnalystHeader(isEn, is100, scale),
                  SizedBox(height: 16.0 * scale + 4),

                  // Middle Stats Content (Adapts to Ratio)
                  Expanded(
                    child: config.ratio == DexCardRatio.portrait9_16
                        ? _buildAnalystPortraitBody(
                            isEn, is100, gaps, boxDetails, specialStats, scale)
                        : _buildAnalystLandscapeBody(
                            isEn, is100, gaps, boxDetails, specialStats, scale),
                  ),

                  // Footer
                  if (config.showWatermarkLogo) ...[
                    SizedBox(height: 10.0 * scale + 2),
                    _buildCardFooter(scale),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalystHeader(bool isEn, bool is100, double scale) {
    final regionUpper = dex.region.toUpperCase().replaceAll('_', ' ');
    final dateStr = _formatDate(config.completionDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale + 2,
                  vertical: 3 * scale + 1,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6 * scale + 2,
                      height: 6 * scale + 2,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6 * scale + 2),
                    Flexible(
                      child: Text(
                        '$regionUpper LIVING DEX',
                        style: TextStyle(
                          fontSize: 10.0 * scale + 2,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA5B4FC),
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6 * scale + 1),
              Text(
                dex.title.isNotEmpty ? dex.title : 'Living Dex',
                style: TextStyle(
                  fontSize: 20.0 * scale + 4,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (config.customTrainerNote != null &&
                  config.customTrainerNote!.trim().isNotEmpty) ...[
                SizedBox(height: 3 * scale + 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 11 * scale + 2,
                      color: const Color(0xFFA5B4FC),
                    ),
                    SizedBox(width: 4 * scale),
                    Flexible(
                      child: Text(
                        config.customTrainerNote!.trim(),
                        style: TextStyle(
                          fontSize: 10.5 * scale + 1.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA5B4FC),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12 * scale),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale + 4,
                vertical: 5 * scale + 2,
              ),
              decoration: BoxDecoration(
                color: is100
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                border: Border.all(
                  color: is100
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                is100
                    ? (isEn ? '★ 100% MASTERED' : '★ 100% GEMEISTERT')
                    : '★ ${stats.percentage.toStringAsFixed(1)}% ${isEn ? 'IN PROGRESS' : 'IN ARBEIT'}',
                style: TextStyle(
                  fontSize: 10.0 * scale + 2,
                  fontWeight: FontWeight.w900,
                  color:
                      is100 ? const Color(0xFF34D399) : const Color(0xFF60A5FA),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (config.showDate) ...[
              SizedBox(height: 4 * scale),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 10.0 * scale + 1,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAnalystLandscapeBody(
    bool isEn,
    bool is100,
    int gaps,
    _BoxDetails boxDetails,
    _SpecialStats specialStats,
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
    _BoxDetails boxDetails,
    _SpecialStats specialStats,
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
                painter: _CircularGaugePainter(
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
    _BoxDetails boxDetails,
    _SpecialStats specialStats,
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

  // ---------------------------------------------------------------------------
  // DESIGN 2: TRAINER CERTIFICATE (Hall of Fame / Diplom)
  // ---------------------------------------------------------------------------
  Widget _buildCertificateCard(BuildContext context, bool isEn, double scale) {
    final boxDetails = _calculateBoxDetails();

    final pillars = <Widget>[
      Expanded(
        child: _buildCertificatePillar(
          title: isEn ? 'Caught' : 'Gefangen',
          value: '${stats.caughtCount} / ${stats.totalCount}',
          subtitle:
              '${stats.percentage.toStringAsFixed(1)}% ${isEn ? "Quote" : "Quote"}',
          scale: scale,
        ),
      ),
    ];

    if (config.showSpecialCollections) {
      pillars.add(_buildPillarDivider(scale));
      pillars.add(
        Expanded(
          child: _buildCertificatePillar(
            title: isEn ? 'Shinies' : 'Shiny Funde',
            value: '${stats.shinyCount}',
            subtitle: isEn ? 'Star Rank' : 'Sternen-Rang',
            scale: scale,
          ),
        ),
      );
      pillars.add(_buildPillarDivider(scale));
      pillars.add(
        Expanded(
          child: _buildCertificatePillar(
            title: isEn ? 'Alphas' : 'Alpha Riesen',
            value: '${stats.alphaCount}',
            subtitle: isEn ? 'Mastery' : 'Meisterhaft',
            scale: scale,
          ),
        ),
      );
    }

    if (config.showBoxStats) {
      pillars.add(_buildPillarDivider(scale));
      final String boxSubtitle = boxDetails.partialBoxes > 0
          ? '${boxDetails.fullBoxes} ${isEn ? "full" : "voll"} (${boxDetails.partialBoxes} ${isEn ? "part." : "teilw."})'
          : (isEn ? 'Organized' : 'Perfekt geordnet');
      pillars.add(
        Expanded(
          child: _buildCertificatePillar(
            title: isEn ? 'Boxes' : 'Boxen Belegt',
            value: '${boxDetails.totalBoxes} ${isEn ? "Boxes" : "Boxen"}',
            subtitle: boxSubtitle,
            scale: scale,
          ),
        ),
      );
    }

    if (!config.showSpecialCollections && !config.showBoxStats) {
      pillars.add(_buildPillarDivider(scale));
      pillars.add(
        Expanded(
          child: _buildCertificatePillar(
            title: isEn ? 'Gaps' : 'Lücken',
            value: '${boxDetails.gapsRemaining}',
            subtitle: isEn ? 'Remaining' : 'Verbleibend',
            scale: scale,
          ),
        ),
      );
      if (config.showDate) {
        pillars.add(_buildPillarDivider(scale));
        pillars.add(
          Expanded(
            child: _buildCertificatePillar(
              title: isEn ? 'Date' : 'Datum',
              value: _formatDate(config.completionDate),
              subtitle: isEn ? 'Timestamp' : 'Zeitstempel',
              scale: scale,
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF121215)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2.5 * scale + 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 30 * scale,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Watermark Artwork
          if (config.hasWatermark)
            Positioned(
              right: 10 * scale,
              top: 50 * scale,
              width: 420 * scale + 80,
              height: 420 * scale + 80,
              child: _buildWatermarkImage(),
            ),

          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(26.0 * scale + 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Diploma Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12 * scale + 2,
                                vertical: 4 * scale + 1,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isEn
                                    ? '🏆 Official Pokédex Diploma'
                                    : '🏆 Offizielles Pokédex-Diplom',
                                style: TextStyle(
                                  fontSize: 10.0 * scale + 2,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            SizedBox(height: 8 * scale + 2),
                            Text(
                              '${dex.title.isNotEmpty ? dex.title : "Living Dex"} ${isEn ? "Certificate" : "Zertifikat"}',
                              style: TextStyle(
                                fontSize: 22.0 * scale + 4,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (config.customTrainerNote != null &&
                                config.customTrainerNote!.trim().isNotEmpty) ...[
                              SizedBox(height: 2 * scale),
                              Text(
                                config.customTrainerNote!.trim(),
                                style: TextStyle(
                                  fontSize: 11.5 * scale + 2,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFBBF24),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: 2 * scale),
                            Text(
                              isEn
                                  ? 'Awarded for comprehensive collection and living dex mastery'
                                  : 'Verliehen an den Trainer für die vollständige Erfassung aller Spezies',
                              style: TextStyle(
                                fontSize: 10.5 * scale + 1.5,
                                color: const Color(0xFFD4D4D8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stats.percentage.toStringAsFixed(stats.percentage == 100.0 ? 0 : 1)}%',
                            style: TextStyle(
                              fontSize: 34.0 * scale + 6,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFF59E0B),
                              height: 1.0,
                            ),
                          ),
                          Text(
                            stats.percentage >= 99.99
                                ? (isEn ? 'COMPLETE' : 'VOLLSTÄNDIG')
                                : (isEn ? 'IN PROGRESS' : 'IN ARBEIT'),
                            style: TextStyle(
                              fontSize: 9.5 * scale + 1.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Stat Pillars Grid
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14 * scale + 2,
                      vertical: 14 * scale + 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(14 * scale),
                    ),
                    child: Row(children: pillars),
                  ),

                  // Certificate Footer & Official Seal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          () {
                            final dateText = config.showDate
                                ? _formatDate(config.completionDate)
                                : '';
                            if (config.showWatermarkLogo) {
                              final prefix =
                                  dateText.isNotEmpty ? '$dateText • ' : '';
                              return isEn
                                  ? '${prefix}Registered in PokéVault • Verified by Save State Inspection'
                                  : '${prefix}Registriert in PokéVault • Verifiziert durch Spielstand-Prüfung';
                            } else {
                              return dateText;
                            }
                          }(),
                          style: TextStyle(
                            fontSize: 9.5 * scale + 1.5,
                            color: const Color(0xFFA1A1AA),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        isEn
                            ? 'Champion-Seal ★★★★★'
                            : 'Champion-Siegel ★★★★★',
                        style: TextStyle(
                          fontSize: 10.5 * scale + 1.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatePillar({
    required String title,
    required String value,
    required String subtitle,
    required double scale,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 9.5 * scale + 1.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF59E0B),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3 * scale),
        Text(
          value,
          style: TextStyle(
            fontSize: 17.0 * scale + 3,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2 * scale),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 8.5 * scale + 1,
            color: const Color(0xFFA1A1AA),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPillarDivider(double scale) {
    return Container(
      width: 1,
      height: 36 * scale + 8,
      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
      margin: EdgeInsets.symmetric(horizontal: 4 * scale),
    );
  }

  // ---------------------------------------------------------------------------
  // DESIGN 3: LIVING DEX MOSAIC (Visual Grid / Heatmap)
  // ---------------------------------------------------------------------------
  Widget _buildMosaicCard(BuildContext context, bool isEn, double scale) {
    final isBoxesMode = config.mosaicMode == DexMosaicMode.boxes;
    final boxDetails = _calculateBoxDetails();
    final missingCount = math.max(0, stats.totalCount - stats.caughtCount);

    return Container(
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.all(22.0 * scale + 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (isBoxesMode
                              ? 'Living Dex Box Grid'
                              : 'Living Dex Visual Grid')
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5 * scale + 1.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF38BDF8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      '${dex.title.isNotEmpty ? dex.title : "Living Dex"} ${isBoxesMode ? (isEn ? "Box Mosaic" : "Boxen-Mosaik") : (isEn ? "Mosaic" : "Kachel-Mosaik")}',
                      style: TextStyle(
                        fontSize: 19.0 * scale + 3,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (config.customTrainerNote != null &&
                        config.customTrainerNote!.trim().isNotEmpty) ...[
                      SizedBox(height: 2 * scale),
                      Text(
                        config.customTrainerNote!.trim(),
                        style: TextStyle(
                          fontSize: 10.5 * scale + 1.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF38BDF8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Legend
              if (isBoxesMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(
                      const Color(0xFF10B981),
                      '${isEn ? "Full Boxes" : "Volle Boxen"} (${boxDetails.fullBoxes})',
                      scale,
                    ),
                    SizedBox(width: 10 * scale),
                    _buildLegendItem(
                      const Color(0xFF38BDF8),
                      '${isEn ? "Partial" : "Angefangene"} (${boxDetails.partialBoxes})',
                      scale,
                    ),
                    SizedBox(width: 10 * scale),
                    _buildLegendItem(
                      const Color(0xFF1E293B),
                      '${isEn ? "Empty" : "Leere"} (${boxDetails.emptyBoxes})',
                      scale,
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(
                      const Color(0xFF10B981),
                      '${isEn ? "Caught" : "Gefangen"} (${stats.caughtCount})',
                      scale,
                    ),
                    if (config.showSpecialCollections) ...[
                      SizedBox(width: 10 * scale),
                      _buildLegendItem(
                        const Color(0xFFF59E0B),
                        'Shiny (${stats.shinyCount})',
                        scale,
                      ),
                      if (stats.alphaCount > 0) ...[
                        SizedBox(width: 10 * scale),
                        _buildLegendItem(
                          const Color(0xFFEF4444),
                          'Alpha (${stats.alphaCount})',
                          scale,
                        ),
                      ],
                    ],
                    if (missingCount > 0) ...[
                      SizedBox(width: 10 * scale),
                      _buildLegendItem(
                        const Color(0xFF1E293B),
                        '${isEn ? "Missing" : "Fehlend"} ($missingCount)',
                        scale,
                      ),
                    ],
                  ],
                ),
            ],
          ),
          SizedBox(height: 12 * scale + 4),

          // Center Mosaic Cells Grid
          Expanded(
            child: Container(
              key: const Key('mosaic_grid'),
              padding: EdgeInsets.all(10 * scale + 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: _buildMosaicCells(scale),
            ),
          ),
          SizedBox(height: 10 * scale + 2),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  isBoxesMode
                      ? '${isEn ? "Total:" : "Gesamt:"} ${boxDetails.totalBoxes} ${isEn ? (boxDetails.totalBoxes == 1 ? "Box" : "Boxes") : (boxDetails.totalBoxes == 1 ? "Box" : "Boxen")} (${stats.caughtCount}/${stats.totalCount} Pokémon)${config.showDate ? " • ${_formatDate(config.completionDate, isEn)}" : ""}'
                      : '${isEn ? "Total:" : "Gesamt:"} ${stats.totalCount} Pokémon${config.showDate ? " • ${_formatDate(config.completionDate, isEn)}" : ""}',
                  style: TextStyle(
                    fontSize: 9.5 * scale + 1.5,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (config.showWatermarkLogo)
                Text(
                  'PokéVault Living Dex Tracker',
                  style: TextStyle(
                    fontSize: 9.5 * scale + 1.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMosaicCells(double scale) {
    final isBoxesMode = config.mosaicMode == DexMosaicMode.boxes;

    if (entries.isEmpty && !isBoxesMode) {
      return Center(
        child: Text(
          '0 Pokémon',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 12 * scale + 2,
          ),
        ),
      );
    }

    List<Color> itemColors;
    if (isBoxesMode) {
      itemColors = _calculateMosaicBoxColors();
      if (itemColors.isEmpty) {
        return Center(
          child: Text(
            '0 Boxen',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 12 * scale + 2,
            ),
          ),
        );
      }
    } else {
      itemColors = entries.map<Color>((entry) {
        final isCaught = DexLogicHelper.isPokemonCaught(dex, entry.uniqueId);
        if (!isCaught) {
          return const Color(0xFF1E293B);
        }
        if (config.showSpecialCollections) {
          final isShiny = DexLogicHelper.isPokemonShiny(dex, entry.uniqueId);
          if (isShiny) {
            return const Color(0xFFF59E0B);
          }
          final isAlpha = DexLogicHelper.isPokemonAlpha(dex, entry.uniqueId);
          if (isAlpha) {
            return const Color(0xFFEF4444);
          }
        }
        return const Color(0xFF10B981);
      }).toList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _MosaicHeatmapPainter(
            itemColors: itemColors,
            scale: scale,
          ),
        );
      },
    );
  }

  List<Color> _calculateMosaicBoxColors() {
    return _evaluateBoxes().map((b) => b.color).toList();
  }

  Widget _buildLegendItem(Color color, String label, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8 * scale + 2,
          height: 8 * scale + 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: color == const Color(0xFF1E293B)
                ? Border.all(color: const Color(0xFF334155))
                : null,
          ),
        ),
        SizedBox(width: 4 * scale),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.0 * scale + 1.5,
            color: const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DESIGN 4: MINIMALIST GLASS (Kompakt & Modern)
  // ---------------------------------------------------------------------------
  Widget _buildMinimalistCard(BuildContext context, bool isEn, double scale) {
    final boxDetails = _calculateBoxDetails();
    final specialStats = _calculateSpecialStats();
    final dateStr = _formatDate(config.completionDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121826).withValues(alpha: 0.88),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          // Background Watermark Artwork
          if (config.hasWatermark)
            Positioned(
              right: -20 * scale,
              bottom: -30 * scale,
              width: 420 * scale + 80,
              height: 420 * scale + 80,
              child: _buildWatermarkImage(),
            ),

          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(28.0 * scale + 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POKEVAULT PROGRESS SUMMARY',
                        style: TextStyle(
                          fontSize: 10.0 * scale + 2,
                          color: const Color(0xFF818CF8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        dex.title.isNotEmpty ? dex.title : 'Living Dex',
                        style: TextStyle(
                          fontSize: 28.0 * scale + 6,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (config.customTrainerNote != null &&
                          config.customTrainerNote!.trim().isNotEmpty) ...[
                        SizedBox(height: 3 * scale),
                        Text(
                          config.customTrainerNote!.trim(),
                          style: TextStyle(
                            fontSize: 12.0 * scale + 2,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA5B4FC),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),

                  // Big Center Percentage
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${stats.percentage.toStringAsFixed(stats.percentage == 100.0 ? 0 : 1)}%',
                        style: TextStyle(
                          fontSize: 46.0 * scale + 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981),
                          height: 1.0,
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Flexible(
                        child: Text(
                          '(${stats.caughtCount} ${isEn ? "of" : "von"} ${stats.totalCount} ${isEn ? "Caught" : "Gefangen"})',
                          style: TextStyle(
                            fontSize: 17.0 * scale + 3,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Stat Badges Row
                  Container(
                    padding: EdgeInsets.only(top: 14 * scale + 2),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Wrap(
                      spacing: 16 * scale + 4,
                      runSpacing: 6 * scale,
                      children: [
                        if (config.showSpecialCollections) ...[
                          Text(
                            '✨ ${stats.shinyCount} Shinies',
                            style: TextStyle(
                              fontSize: 12.0 * scale + 2,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                          Text(
                            '🔥 ${stats.alphaCount} Alphas',
                            style: TextStyle(
                              fontSize: 12.0 * scale + 2,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                          if (specialStats.ribbons > 0)
                            Text(
                              '🎀 ${specialStats.ribbons} ${isEn ? "Ribbons" : "Bänder"}',
                              style: TextStyle(
                                fontSize: 12.0 * scale + 2,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                          if (specialStats.teraTypes > 0)
                            Text(
                              '💎 ${specialStats.teraTypes} Tera',
                              style: TextStyle(
                                fontSize: 12.0 * scale + 2,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                          if (specialStats.languages > 0)
                            Text(
                              '🌐 ${specialStats.languages} ${isEn ? "Languages" : "Sprachen"}',
                              style: TextStyle(
                                fontSize: 12.0 * scale + 2,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                        ],
                        if (config.showBoxStats)
                          Text(
                            boxDetails.partialBoxes > 0
                                ? '📦 ${boxDetails.totalBoxes} ${isEn ? "Boxes" : "Boxen"} (${boxDetails.fullBoxes} ${isEn ? "full" : "voll"}, ${boxDetails.partialBoxes} ${isEn ? "part." : "teilw."})'
                                : '📦 ${boxDetails.totalBoxes} ${isEn ? "Boxes" : "Boxen"} (${boxDetails.fullBoxes} ${isEn ? "full" : "voll"})',
                            style: TextStyle(
                              fontSize: 12.0 * scale + 2,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        if (config.showDate)
                          Text(
                            '📅 $dateStr',
                            style: TextStyle(
                              fontSize: 12.0 * scale + 2,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        if (config.showWatermarkLogo)
                          Text(
                            '⚡ PokéVault',
                            style: TextStyle(
                              fontSize: 12.0 * scale + 2,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF818CF8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED UTILITIES & COMPONENTS
  // ---------------------------------------------------------------------------
  Widget _buildWatermarkImage() {
    final wm = config.watermarkPokemon;
    if (wm == null || wm.imageUrl.isEmpty) return const SizedBox.shrink();

    return Opacity(
      opacity: config.watermarkOpacity,
      child: CachedNetworkImage(
        imageUrl: wm.imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCardFooter(double scale) {
    if (!config.showWatermarkLogo) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 5 * scale + 1,
                vertical: 2 * scale + 0.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PKV',
                style: TextStyle(
                  fontSize: 8.0 * scale + 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 5 * scale),
            Text(
              'PokéVault',
              style: TextStyle(
                fontSize: 9.5 * scale + 1.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Text(
              ' • Living Dex Manager',
              style: TextStyle(
                fontSize: 9.5 * scale + 1.5,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
        Text(
          'pokevault.app',
          style: TextStyle(
            fontSize: 9.0 * scale + 1,
            color: const Color(0xFF64748B),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  List<_BoxItemStatus> _evaluateBoxes() {
    if (dex.customBoxes.isNotEmpty) {
      return dex.customBoxes.map((box) {
        final validIds = box.pokemonIds
            .where((id) => id.isNotEmpty && !DexLogicHelper.isPlaceholder(id))
            .toList();
        final capacity = box.capacity > 0
            ? box.capacity
            : (validIds.isNotEmpty ? validIds.length : 30);
        final caught = validIds
            .where((id) => DexLogicHelper.isPokemonCaught(dex, id))
            .length;
        final isFull = capacity > 0 && caught >= capacity;
        final isPartial = !isFull && caught > 0;
        final isEmpty = !isFull && !isPartial;
        final color = isFull
            ? const Color(0xFF10B981)
            : (isPartial ? const Color(0xFF38BDF8) : const Color(0xFF1E293B));
        return _BoxItemStatus(
          caught: caught,
          capacity: capacity,
          color: color,
          isFull: isFull,
          isPartial: isPartial,
          isEmpty: isEmpty,
        );
      }).toList();
    }

    final totalBoxes = stats.totalCount > 0
        ? (stats.totalCount / 30).ceil()
        : (entries.isNotEmpty ? (entries.length / 30).ceil() : 0);

    if (totalBoxes == 0) return const [];

    if (entries.isNotEmpty) {
      final result = <_BoxItemStatus>[];
      for (int b = 0; b < totalBoxes; b++) {
        final start = b * 30;
        final end = math.min(start + 30, entries.length);
        if (start >= entries.length) {
          result.add(const _BoxItemStatus(
            caught: 0,
            capacity: 30,
            color: Color(0xFF1E293B),
            isFull: false,
            isPartial: false,
            isEmpty: true,
          ));
          continue;
        }
        final boxEntries = entries.sublist(start, end);
        final capacity = boxEntries.length;
        final caught = boxEntries
            .where((e) => DexLogicHelper.isPokemonCaught(dex, e.uniqueId))
            .length;
        final isFull = capacity > 0 && caught >= capacity;
        final isPartial = !isFull && caught > 0;
        final isEmpty = !isFull && !isPartial;
        final color = isFull
            ? const Color(0xFF10B981)
            : (isPartial ? const Color(0xFF38BDF8) : const Color(0xFF1E293B));
        result.add(_BoxItemStatus(
          caught: caught,
          capacity: capacity,
          color: color,
          isFull: isFull,
          isPartial: isPartial,
          isEmpty: isEmpty,
        ));
      }
      return result;
    } else {
      // Fallback when entries list is empty
      if (stats.caughtCount >= stats.totalCount && stats.totalCount > 0) {
        return List.generate(
          totalBoxes,
          (_) => const _BoxItemStatus(
            caught: 30,
            capacity: 30,
            color: Color(0xFF10B981),
            isFull: true,
            isPartial: false,
            isEmpty: false,
          ),
        );
      }
      final fullCount = stats.caughtCount ~/ 30;
      final remainder = stats.caughtCount % 30;
      final partialCount = remainder > 0 ? 1 : 0;
      final emptyCount = math.max(0, totalBoxes - fullCount - partialCount);

      final result = <_BoxItemStatus>[];
      for (int i = 0; i < fullCount; i++) {
        result.add(const _BoxItemStatus(
          caught: 30,
          capacity: 30,
          color: Color(0xFF10B981),
          isFull: true,
          isPartial: false,
          isEmpty: false,
        ));
      }
      if (partialCount > 0) {
        result.add(_BoxItemStatus(
          caught: remainder,
          capacity: 30,
          color: const Color(0xFF38BDF8),
          isFull: false,
          isPartial: true,
          isEmpty: false,
        ));
      }
      for (int i = 0; i < emptyCount; i++) {
        result.add(const _BoxItemStatus(
          caught: 0,
          capacity: 30,
          color: Color(0xFF1E293B),
          isFull: false,
          isPartial: false,
          isEmpty: true,
        ));
      }
      return result;
    }
  }

  _BoxDetails _calculateBoxDetails() {
    final boxes = _evaluateBoxes();
    final full = boxes.where((b) => b.isFull).length;
    final partial = boxes.where((b) => b.isPartial).length;
    final empty = boxes.where((b) => b.isEmpty).length;
    final gaps = math.max(0, stats.totalCount - stats.caughtCount);
    return _BoxDetails(
      totalBoxes: boxes.length,
      fullBoxes: full,
      partialBoxes: partial,
      emptyBoxes: empty,
      gapsRemaining: gaps,
    );
  }

  _SpecialStats _calculateSpecialStats() {
    final totalRibbons = dex.caughtRibbons.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final totalTera = dex.caughtTeraTypes.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final totalLanguages = dex.caughtLanguages.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return _SpecialStats(
      shinies: stats.shinyCount,
      alphas: stats.alphaCount,
      ribbons: totalRibbons > 0 ? totalRibbons : dex.caughtRibbons.length,
      teraTypes: totalTera > 0 ? totalTera : dex.caughtTeraTypes.length,
      languages:
          totalLanguages > 0 ? totalLanguages : dex.caughtLanguages.length,
    );
  }

  String _formatDate(DateTime date, [bool isEn = false]) {
    const monthsDe = [
      'Jan.',
      'Feb.',
      'März',
      'Apr.',
      'Mai',
      'Juni',
      'Juli',
      'Aug.',
      'Sept.',
      'Okt.',
      'Nov.',
      'Dez.'
    ];
    const monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = (isEn ? monthsEn : monthsDe)[date.month - 1];
    return isEn
        ? '$month ${date.day}, ${date.year}'
        : '${date.day}. $month ${date.year}';
  }
}

class _BoxItemStatus {
  final int caught;
  final int capacity;
  final Color color;
  final bool isFull;
  final bool isPartial;
  final bool isEmpty;

  const _BoxItemStatus({
    required this.caught,
    required this.capacity,
    required this.color,
    required this.isFull,
    required this.isPartial,
    required this.isEmpty,
  });
}

class _BoxDetails {
  final int totalBoxes;
  final int fullBoxes;
  final int partialBoxes;
  final int emptyBoxes;
  final int gapsRemaining;

  const _BoxDetails({
    required this.totalBoxes,
    required this.fullBoxes,
    required this.partialBoxes,
    required this.emptyBoxes,
    required this.gapsRemaining,
  });
}

class _SpecialStats {
  final int shinies;
  final int alphas;
  final int ribbons;
  final int teraTypes;
  final int languages;

  const _SpecialStats({
    required this.shinies,
    required this.alphas,
    required this.ribbons,
    required this.teraTypes,
    required this.languages,
  });
}

/// Custom painter for drawing smooth circular progress gauges without raster artifacts.
class _CircularGaugePainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _CircularGaugePainter({
    required this.percentage,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = (percentage.clamp(0.0, 100.0) / 100.0) * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

/// Custom painter for rendering the entire Living Dex as an adaptive visual grid heatmap.
/// Mathematically guarantees that ALL entries fit into the canvas without clipping or truncation.
class _MosaicHeatmapPainter extends CustomPainter {
  final List<Color> itemColors;
  final double scale;

  _MosaicHeatmapPainter({
    required this.itemColors,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int n = itemColors.length;
    if (n == 0 || size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final double a = w / h;

    final int bestC = (math.sqrt(n * a)).round().clamp(1, n);
    double bestCellSize = -1.0;
    int optimalC = bestC;
    int optimalR = (n / bestC).ceil();
    double optimalGap = 1.0;

    for (int testC = math.max(1, bestC - 5);
        testC <= math.min(n, bestC + 5);
        testC++) {
      final testR = (n / testC).ceil();
      final idealGap = math.min(
          2.5 * scale, math.min((w / testC) * 0.15, (h / testR) * 0.15));
      final testGap = math.max(0.0, idealGap);
      final cellW = (w - (testC - 1) * testGap) / testC;
      final cellH = (h - (testR - 1) * testGap) / testR;
      final s = math.min(cellW, cellH);
      if (s > bestCellSize) {
        bestCellSize = s;
        optimalC = testC;
        optimalR = testR;
        optimalGap = testGap;
      }
    }

    if (bestCellSize <= 0) return;

    final double gridW = optimalC * bestCellSize + (optimalC - 1) * optimalGap;
    final double gridH = optimalR * bestCellSize + (optimalR - 1) * optimalGap;
    final double startX = (w - gridW) / 2;
    final double startY = (h - gridH) / 2;

    final double cornerRadius = (bestCellSize * 0.2).clamp(0.5, 4.0 * scale);
    final Radius r = Radius.circular(cornerRadius);

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final col = i % optimalC;
      final row = i ~/ optimalC;
      final x = startX + col * (bestCellSize + optimalGap);
      final y = startY + row * (bestCellSize + optimalGap);
      final rect = Rect.fromLTWH(x, y, bestCellSize, bestCellSize);

      paint.color = itemColors[i];
      if (bestCellSize >= 6.0 && cornerRadius >= 1.0) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, r), paint);
      } else {
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MosaicHeatmapPainter oldDelegate) {
    if (oldDelegate.scale != scale ||
        oldDelegate.itemColors.length != itemColors.length) {
      return true;
    }
    for (int i = 0; i < itemColors.length; i++) {
      if (oldDelegate.itemColors[i] != itemColors[i]) {
        return true;
      }
    }
    return false;
  }
}
