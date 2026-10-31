import 'package:flutter/material.dart';
import '../../../models/dex_card_models.dart';
import '../../../models/dex_progress_models.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/user_dex.dart';
import '../../../utils/dex_logic_helper.dart';
import 'card_painter_renderer.dart';

/// Renders the complete Living Dex as an adaptive visual grid heatmap or box mosaic.
class CardPokemonMosaic extends StatelessWidget {
  final List<DexDisplayEntry> entries;
  final UserDex dex;
  final DexProgressStats stats;
  final DexCardConfig config;
  final double scale;
  final bool isEn;
  final CardBoxDetails boxDetails;
  final int missingCount;
  final List<Color>? boxColors;

  const CardPokemonMosaic({
    super.key,
    required this.entries,
    required this.dex,
    required this.stats,
    required this.config,
    required this.scale,
    required this.isEn,
    required this.boxDetails,
    required this.missingCount,
    this.boxColors,
  });

  @override
  Widget build(BuildContext context) {
    final isBoxesMode = config.mosaicMode == DexMosaicMode.boxes;

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
                    buildLegendItem(
                      const Color(0xFF10B981),
                      '${isEn ? "Full Boxes" : "Volle Boxen"} (${boxDetails.fullBoxes})',
                      scale,
                    ),
                    SizedBox(width: 10 * scale),
                    buildLegendItem(
                      const Color(0xFF38BDF8),
                      '${isEn ? "Partial" : "Angefangene"} (${boxDetails.partialBoxes})',
                      scale,
                    ),
                    SizedBox(width: 10 * scale),
                    buildLegendItem(
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
                    buildLegendItem(
                      const Color(0xFF10B981),
                      '${isEn ? "Caught" : "Gefangen"} (${stats.caughtCount})',
                      scale,
                    ),
                    if (config.showSpecialCollections) ...[
                      SizedBox(width: 10 * scale),
                      buildLegendItem(
                        const Color(0xFFF59E0B),
                        'Shiny (${stats.shinyCount})',
                        scale,
                      ),
                      if (stats.alphaCount > 0) ...[
                        SizedBox(width: 10 * scale),
                        buildLegendItem(
                          const Color(0xFFEF4444),
                          'Alpha (${stats.alphaCount})',
                          scale,
                        ),
                      ],
                    ],
                    if (missingCount > 0) ...[
                      SizedBox(width: 10 * scale),
                      buildLegendItem(
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
              child: buildMosaicCells(scale),
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

  Widget buildMosaicCells(double scale) {
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
      itemColors = boxColors ?? [];
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
          painter: MosaicHeatmapPainter(
            itemColors: itemColors,
            scale: scale,
          ),
        );
      },
    );
  }

  static Widget buildLegendItem(Color color, String label, double scale) {
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
