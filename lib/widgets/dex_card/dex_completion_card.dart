import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/dex_card_models.dart';
import '../../models/dex_progress_models.dart';
import '../../models/dex_view_models.dart';
import '../../models/user_dex.dart';
import '../../utils/dex_logic_helper.dart';
import '../../i18n/strings.g.dart';
import 'widgets/card_painter_renderer.dart';
import 'widgets/card_stats_summary.dart';
import 'widgets/card_pokemon_mosaic.dart';

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
            DexCardStyle.mosaic => CardPokemonMosaic(
                dex: dex,
                stats: stats,
                config: config,
                entries: entries,
                scale: scale,
                isEn: isEn,
                boxDetails: _calculateBoxDetails(),
                boxColors: _evaluateBoxes().map((b) => b.color).toList(),
                missingCount: math.max(0, stats.totalCount - stats.caughtCount),
              ),
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
                    child: CardStatsSummary(
                      stats: stats,
                      config: config,
                      specialStats: specialStats,
                      boxDetails: boxDetails,
                      gaps: gaps,
                      isEn: isEn,
                      scale: scale,
                    ),
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

  List<CardBoxItemStatus> _evaluateBoxes() {
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
        return CardBoxItemStatus(
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
      final result = <CardBoxItemStatus>[];
      for (int b = 0; b < totalBoxes; b++) {
        final start = b * 30;
        final end = math.min(start + 30, entries.length);
        if (start >= entries.length) {
          result.add(const CardBoxItemStatus(
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
        result.add(CardBoxItemStatus(
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
          (_) => const CardBoxItemStatus(
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

      final result = <CardBoxItemStatus>[];
      for (int i = 0; i < fullCount; i++) {
        result.add(const CardBoxItemStatus(
          caught: 30,
          capacity: 30,
          color: Color(0xFF10B981),
          isFull: true,
          isPartial: false,
          isEmpty: false,
        ));
      }
      if (partialCount > 0) {
        result.add(CardBoxItemStatus(
          caught: remainder,
          capacity: 30,
          color: const Color(0xFF38BDF8),
          isFull: false,
          isPartial: true,
          isEmpty: false,
        ));
      }
      for (int i = 0; i < emptyCount; i++) {
        result.add(const CardBoxItemStatus(
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

  CardBoxDetails _calculateBoxDetails() {
    final boxes = _evaluateBoxes();
    final full = boxes.where((b) => b.isFull).length;
    final partial = boxes.where((b) => b.isPartial).length;
    final empty = boxes.where((b) => b.isEmpty).length;
    final gaps = math.max(0, stats.totalCount - stats.caughtCount);
    return CardBoxDetails(
      totalBoxes: boxes.length,
      fullBoxes: full,
      partialBoxes: partial,
      emptyBoxes: empty,
      gapsRemaining: gaps,
    );
  }

  CardSpecialStats _calculateSpecialStats() {
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

    return CardSpecialStats(
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
