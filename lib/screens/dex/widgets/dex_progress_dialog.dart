import 'package:flutter/material.dart';
import '../../../models/dex_progress_models.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/user_dex.dart';
import '../../../utils/dex_progress_helper.dart';
import '../../../l10n/app_translations.dart';

/// Interactive modal dashboard presenting overall dex completion,
/// generation breakdowns, type coverage, and variants distribution.
class DexProgressDialog extends StatefulWidget {
  final UserDex liveDex;
  final List<DexDisplayEntry> entries;
  final ValueChanged<String>? onFilterSelected;
  final bool isBottomSheet;

  const DexProgressDialog({
    super.key,
    required this.liveDex,
    required this.entries,
    this.onFilterSelected,
    this.isBottomSheet = false,
  });

  /// Displays the Dex Progress Dashboard as an adaptive dialog or bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required UserDex liveDex,
    required List<DexDisplayEntry> entries,
    ValueChanged<String>? onFilterSelected,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => DexProgressDialog(
          liveDex: liveDex,
          entries: entries,
          onFilterSelected: onFilterSelected,
          isBottomSheet: false,
        ),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DexProgressDialog(
          liveDex: liveDex,
          entries: entries,
          onFilterSelected: onFilterSelected,
          isBottomSheet: true,
        ),
      );
    }
  }

  @override
  State<DexProgressDialog> createState() => _DexProgressDialogState();
}

class _DexProgressDialogState extends State<DexProgressDialog> {
  int _selectedTabIndex = 0; // 0: Gens, 1: Types, 2: Variants

  @override
  Widget build(BuildContext context) {
    final lang = Translator.currentLanguage;
    final stats = DexProgressHelper.calculate(
      widget.liveDex,
      widget.entries,
      language: lang,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF191D24) : Colors.grey.shade50;
    final cardBg = isDark ? const Color(0xFF13161C) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    final dialogChild = Container(
      constraints: BoxConstraints(
        maxWidth: 620,
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header
          _buildHeader(context, isDark, borderColor),

          // 2. Scrollable Body Area (Hero Card + Tab Selector + Tab Content)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _buildHeroCard(context, stats, cardBg, borderColor, isDark),
                  ),
                  _buildTabSelector(stats, isDark, borderColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: _buildActiveTabContent(stats, cardBg, borderColor, isDark),
                  ),
                ],
              ),
            ),
          ),

          // 3. Footer Quick Actions
          _buildFooter(context, cardBg, borderColor, isDark),
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: dialogChild,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: dialogChild,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
        color: isDark ? const Color(0xFF20252E) : Colors.grey.shade100,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFE11D48)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.bar_chart, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Translator.get('dex_progress_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.liveDex.title} • ${Translator.get('dex_progress_subtitle_overview')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: Translator.get('dex_progress_close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    DexProgressStats stats,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  Translator.get('dex_progress_overall').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${stats.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stats.totalCount > 0 ? (stats.caughtCount / stats.totalCount).clamp(0.0, 1.0) : 0.0,
              minHeight: 12,
              backgroundColor: isDark ? const Color(0xFF262C36) : Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${Translator.get('caught')}: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    '${stats.caughtCount} / ${stats.totalCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '✨ ${stats.shinyCount} ${Translator.get('shinies_count')}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '🔴 ${stats.alphaCount} ${Translator.get('alphas_count')}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(DexProgressStats stats, bool isDark, Color borderColor) {
    final tabs = [
      '${Translator.get('dex_progress_generations')} (${stats.generationStats.length})',
      '${Translator.get('dex_progress_types')} (${stats.typeStats.length})',
      Translator.get('dex_progress_variants'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? const Color(0xFFEF4444) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(
    DexProgressStats stats,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildItemList(stats.generationStats, cardBg, borderColor, isDark, isGeneration: true);
      case 1:
        return _buildTypeItemList(stats.typeStats, cardBg, borderColor, isDark);
      case 2:
      default:
        return _buildItemList(stats.variantStats, cardBg, borderColor, isDark);
    }
  }

  Widget _buildItemList(
    List<ProgressItem> items,
    Color cardBg,
    Color borderColor,
    bool isDark, {
    bool isGeneration = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            Translator.get('no_results', fallback: 'Keine Einträge'),
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final barColor = item.color ?? const Color(0xFF10B981);
        final ratio = item.total > 0 ? (item.caught / item.total).clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.subtitle != null ? '${item.name} ${item.subtitle}' : item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.caught} / ${item.total}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      item.isComplete
                          ? const Text(
                              '✓ 100%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            )
                          : Text(
                              '${item.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: barColor,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF262C36) : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    item.isComplete ? const Color(0xFF10B981) : barColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeItemList(
    List<ProgressItem> items,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            Translator.get('no_results', fallback: 'Keine Einträge'),
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final typeColor = item.color ?? const Color(0xFFA8A77A);
        final ratio = item.total > 0 ? (item.caught / item.total).clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Type Badge
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: typeColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Progress Bar & Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.caught} / ${item.total}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        item.isComplete
                            ? const Text(
                                '✓ 100%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              )
                            : Text(
                                '${item.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: isDark ? const Color(0xFF262C36) : Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.isComplete ? const Color(0xFF10B981) : typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderColor)),
        borderRadius: widget.isBottomSheet
            ? BorderRadius.zero
            : const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Action: Show Missing
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E).withValues(alpha: 0.12),
              foregroundColor: const Color(0xFFF43F5E),
              side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.filter_alt, size: 14),
            label: Text(
              Translator.get('dex_progress_show_missing'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onFilterSelected?.call('uncaught');
            },
          ),

          // Action: Show Caught
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
              foregroundColor: const Color(0xFF10B981),
              side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.check, size: 14),
            label: Text(
              Translator.get('dex_progress_show_caught'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onFilterSelected?.call('caught');
            },
          ),

          // Action: Show All
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.clear_all, size: 14),
            label: Text(
              Translator.get('dex_progress_show_all'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onFilterSelected?.call('all');
            },
          ),

          // Action: Close
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF262C36) : Colors.grey.shade300,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              Translator.get('dex_progress_close'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
