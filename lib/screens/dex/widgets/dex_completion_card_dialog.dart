import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/dex_card_models.dart';
import '../../../models/dex_progress_models.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/pokemon.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/database_service.dart';
import '../../../services/dex_card_export_service.dart';
import '../../../utils/dex_logic_helper.dart';
import '../../../utils/dex_progress_helper.dart';
import '../../../widgets/dex_card/dex_completion_card.dart';
import '../../../i18n/strings.g.dart';
import '../pokemon_search_selection.dart';
import 'completion_card/completion_card_actions_bar.dart';
import 'completion_card/completion_card_appearance_section.dart';
import 'completion_card/completion_card_toggles_section.dart';

/// Modal dialog for live customizing, previewing, and exporting Living Dex Completion Cards.
class DexCompletionCardDialog extends StatefulWidget {
  final UserDex liveDex;
  final List<DexDisplayEntry>? entries;

  const DexCompletionCardDialog({
    super.key,
    required this.liveDex,
    this.entries,
  });

  /// Displays the interactive Dex Completion Card Customizer as an adaptive dialog.
  static Future<void> show(
    BuildContext context, {
    required UserDex liveDex,
    List<DexDisplayEntry>? entries,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DexCompletionCardDialog(
        liveDex: liveDex,
        entries: entries,
      ),
    );
  }

  @override
  State<DexCompletionCardDialog> createState() =>
      _DexCompletionCardDialogState();
}

class _DexCompletionCardDialogState extends State<DexCompletionCardDialog> {
  late DexCardConfig _config;
  late TextEditingController _trainerNoteController;
  final GlobalKey _cardRepaintKey = GlobalKey();
  List<DexDisplayEntry>? _effectiveEntries;
  bool _isLoadingEntries = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _config = DexCardConfig();
    _trainerNoteController =
        TextEditingController(text: _config.customTrainerNote ?? '');
    _effectiveEntries = widget.entries;

    if (_effectiveEntries == null || _effectiveEntries!.isEmpty) {
      _loadEntriesAsync();
    }
  }

  @override
  void dispose() {
    _trainerNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadEntriesAsync() async {
    setState(() => _isLoadingEntries = true);
    try {
      final provider = context.read<DexProvider>();
      final lang = context.read<SettingsProvider>().currentLanguage;

      List<int> selectedOrder =
          provider.allAvailableDexes[widget.liveDex.region] ?? [];
      if (widget.liveDex.region == 'custom_empty' || selectedOrder.isEmpty) {
        selectedOrder =
            provider.allAvailableDexes['national_overall'] ?? [];
      }
      final pokemonMap = {for (var p in provider.allPokemon) p.id: p};
      final selectedDatabase = selectedOrder
          .map(
            (id) =>
                pokemonMap[id] ??
                Pokemon(
                  id: id,
                  nameDe: 'Unbekannt',
                  nameEn: 'Unknown',
                  hasGenderDifferences: false,
                  genderRate: -1,
                  captureRate: 255,
                  evolutionChainId: -1,
                  eggGroups: [],
                  weight: 0.0,
                  speed: 0,
                  forms: [],
                ),
          )
          .toList();

      final specialObtainables =
          await DatabaseService.instance.getSpecialObtainables();

      final rawEntries = await DexLogicHelper.buildEntriesInBackground(
        widget.liveDex,
        selectedDatabase,
        lang,
        specialObtainables,
      );

      if (mounted) {
        setState(() {
          _effectiveEntries = rawEntries;
          _isLoadingEntries = false;
        });
      }
    } catch (e) {
      debugPrint('DexCompletionCardDialog: Error loading entries: $e');
      if (mounted) {
        setState(() {
          _effectiveEntries = [];
          _isLoadingEntries = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleSettings.currentLocale.languageCode;
    final isEn = lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF13171F) : Colors.grey.shade50;
    final panelBg = isDark ? const Color(0xFF19202B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final entries = _effectiveEntries ?? [];
    final stats = DexProgressHelper.calculate(
      widget.liveDex,
      entries,
      language: lang,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Container(
        width: 1060,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            _buildDialogHeader(context, isDark, borderColor),

            // 2. Body Area (Preview on Top/Left, Controls on Bottom/Right)
            Expanded(
              child: _isLoadingEntries
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 760;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: Live Preview
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  child: Center(
                                    child: _buildRepaintPreview(stats, entries),
                                  ),
                                ),
                              ),

                              // Right: Controls Sidebar
                              Expanded(
                                flex: 5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: borderColor),
                                    ),
                                    color: panelBg,
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(18),
                                    child: _buildControlsSection(
                                      context,
                                      stats,
                                      entries,
                                      isEn,
                                      borderColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Mobile / Narrow Layout
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                _buildRepaintPreview(stats, entries),
                                const SizedBox(height: 16),
                                _buildControlsSection(
                                  context,
                                  stats,
                                  entries,
                                  isEn,
                                  borderColor,
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
            ),

            // 3. Action Buttons Footer
            _buildActionButtonsFooter(
              context,
              stats,
              isDark,
              borderColor,
              isEn,
              lang,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(
    BuildContext context,
    bool isDark,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
        color: isDark ? const Color(0xFF1B222E) : Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.dex_card_title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.liveDex.title,
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
            tooltip: t.dex_progress_close,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaintPreview(
    DexProgressStats stats,
    List<DexDisplayEntry> entries,
  ) {
    final isEn = LocaleSettings.currentLocale == AppLocale.en;
    return Stack(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.zoomIn,
          child: GestureDetector(
            onTap: () => _openZoomLightbox(context, stats, entries),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: RepaintBoundary(
                key: _cardRepaintKey,
                child: DexCompletionCard(
                  dex: widget.liveDex,
                  stats: stats,
                  entries: entries,
                  config: _config,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Tooltip(
            message:
                isEn ? 'Enlarge preview & zoom' : 'Vorschau vergrößern & zoomen',
            child: Material(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                key: const Key('btn_zoom_preview'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openZoomLightbox(context, stats, entries),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openZoomLightbox(
    BuildContext context,
    DexProgressStats stats,
    List<DexDisplayEntry> entries,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => _CardZoomLightboxDialog(
        dex: widget.liveDex,
        stats: stats,
        entries: entries,
        config: _config,
      ),
    );
  }

  Widget _buildControlsSection(
    BuildContext context,
    DexProgressStats stats,
    List<DexDisplayEntry> entries,
    bool isEn,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1-4. Appearance Section (Styles, Ratios, Watermark, Opacity)
        CompletionCardAppearanceSection(
          config: _config,
          isEn: isEn,
          allPokemon: entries.map((e) => e.pokemon).toList(),
          onConfigChanged: (newConfig) => setState(() => _config = newConfig),
          onWatermarkPokemonChanged: (_) {},
          onPickWatermarkPressed: () => _openWatermarkSearch(context, entries, isEn),
        ),
        const SizedBox(height: 18),
        // 5. Custom Trainer Note / Tag
        _buildSectionHeader(
          icon: Icons.badge_outlined,
          title: isEn
              ? 'Trainer Note / Tag (Optional)'
              : 'Trainer-Notiz / Tag (Optional)',
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('input_trainer_note'),
          controller: _trainerNoteController,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: isEn
                ? 'e.g. Trainer: Marvin • Pokémon HOME'
                : 'z. B. Trainer: Marvin • Pokémon HOME',
            hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            prefixIcon: const Icon(Icons.edit_note, size: 18),
            suffixIcon: _trainerNoteController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _trainerNoteController.clear();
                      setState(() {
                        _config =
                            _config.copyWith(clearCustomTrainerNote: true);
                      });
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.1),
          ),
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(
                customTrainerNote: val.trim().isEmpty ? null : val.trim(),
                clearCustomTrainerNote: val.trim().isEmpty,
              );
            });
          },
        ),
        const SizedBox(height: 18),

        // 6. Living Dex Elements Toggles
        CompletionCardTogglesSection(
          config: _config,
          onConfigChanged: (newConfig) => setState(() => _config = newConfig),
          isEn: isEn,
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF818CF8)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Future<void> _openWatermarkSearch(
    BuildContext context,
    List<DexDisplayEntry> currentEntries,
    bool isEn,
  ) async {
    final provider = context.read<DexProvider>();
    List<DexDisplayEntry> searchList;

    if (provider.allPokemon.isNotEmpty) {
      final masterDex = UserDex(
        id: 'watermark_picker_master',
        title: 'All Pokémon',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: widget.liveDex.isShinyDex,
      );
      searchList = DexLogicHelper.buildDisplayEntries(
        masterDex,
        provider.allPokemon,
        const [],
      );
    } else {
      searchList = currentEntries;
    }

    if (searchList.isEmpty && provider.allPokemon.isNotEmpty) {
      searchList = provider.allPokemon.map((p) {
        return DexDisplayEntry(
          uniqueId: '${p.id}',
          pokemon: p,
          displaySuffix: '',
          imageUrl:
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${p.id}.png',
        );
      }).toList();
    }

    SettingsProvider? settings;
    try {
      settings = context.read<SettingsProvider>();
    } catch (_) {}
    final selectedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PokemonSearchSelectionScreen(
          allAvailableEntries: searchList,
          dexId: widget.liveDex.id,
          initialShiny: widget.liveDex.isShinyDex,
          allowNone: true,
          showPlaceholder: false,
        ),
      ),
    );

    if (!mounted || selectedId == null) return;

    if (selectedId == 'none') {
      setState(() {
        _config = _config.copyWith(clearWatermark: true);
      });
      return;
    }

    final isShiny = selectedId.startsWith('shiny:');
    final cleanId = isShiny ? selectedId.substring(6) : selectedId;

    // Find the entry to extract name and image URL
    final foundEntry = searchList.where((e) {
      if (e.uniqueId == cleanId) return true;
      final base = DexLogicHelper.getBaseId(e.uniqueId);
      final cleanBase = DexLogicHelper.getBaseId(cleanId);
      return e.uniqueId == cleanBase || base == cleanId || base == cleanBase;
    }).firstOrNull;

    if (foundEntry != null) {
      String pokeLang = isEn ? 'en' : 'de';
      if (settings != null) {
        try {
          pokeLang = settings.effectivePokemonLanguage;
        } catch (_) {}
      }
      final baseName = foundEntry.pokemon.getName(pokeLang);
      final displayName = foundEntry.displaySuffix.trim().isNotEmpty
          ? '$baseName ${foundEntry.displaySuffix.trim()}'
          : baseName;

      String finalUrl = foundEntry.imageUrl;
      if (isShiny && !finalUrl.contains('/shiny/')) {
        if (finalUrl.contains('official-artwork/')) {
          finalUrl = finalUrl.replaceFirst('official-artwork/', 'official-artwork/shiny/');
        } else if (finalUrl.contains('home/female/')) {
          finalUrl = finalUrl.replaceFirst('home/female/', 'home/shiny/female/');
        } else if (finalUrl.contains('home/')) {
          finalUrl = finalUrl.replaceFirst('home/', 'home/shiny/');
        }
      } else if (!isShiny && finalUrl.contains('/shiny/')) {
        if (finalUrl.contains('/shiny/female/')) {
          finalUrl = finalUrl.replaceFirst('/shiny/female/', '/female/');
        } else {
          finalUrl = finalUrl.replaceFirst('/shiny/', '/');
        }
      }

      setState(() {
        _config = _config.copyWith(
          watermarkPokemon: DexCardPokemonWatermark(
            pokemonId: foundEntry.pokemon.id,
            name: displayName,
            imageUrl: finalUrl,
            formName: foundEntry.resolvedForm?.name,
            isShiny: isShiny,
          ),
          watermarkOpacity:
              _config.watermarkOpacity > 0.0 ? _config.watermarkOpacity : 0.18,
        );
      });
    }
  }

  Widget _buildActionButtonsFooter(
    BuildContext context,
    DexProgressStats stats,
    bool isDark,
    Color borderColor,
    bool isEn,
    String lang,
  ) {
    return CompletionCardActionsBar(
      isExporting: _isExporting,
      isDark: isDark,
      borderColor: borderColor,
      onCopyText: () {
        final shareText = DexCardExportService.generateShareText(
          widget.liveDex,
          stats,
          language: lang,
        );
        DexCardExportService.copyToClipboard(shareText);
      },
      onShare: () async {
        setState(() => _isExporting = true);
        final pngBytes = await DexCardExportService.capturePng(
          _cardRepaintKey,
        );
        if (pngBytes != null && mounted) {
          final shareText = DexCardExportService.generateShareText(
            widget.liveDex,
            stats,
            language: lang,
          );
          await DexCardExportService.sharePng(
            pngBytes,
            dexTitle: widget.liveDex.title,
            shareText: shareText,
          );
        }
        if (mounted) setState(() => _isExporting = false);
      },
      onSavePng: () async {
        setState(() => _isExporting = true);
        final pngBytes = await DexCardExportService.capturePng(
          _cardRepaintKey,
        );
        if (pngBytes != null && mounted) {
          await DexCardExportService.savePngToDisk(
            pngBytes,
            dexTitle: widget.liveDex.title,
          );
        }
        if (mounted) setState(() => _isExporting = false);
      },
    );
  }


}

/// Interactive Fullscreen Lightbox for previewing Living Dex completion cards
/// with fine-grained pan, pinch-zoom, and button controls.
class _CardZoomLightboxDialog extends StatefulWidget {
  final UserDex dex;
  final DexProgressStats stats;
  final List<DexDisplayEntry> entries;
  final DexCardConfig config;

  const _CardZoomLightboxDialog({
    required this.dex,
    required this.stats,
    required this.entries,
    required this.config,
  });

  @override
  State<_CardZoomLightboxDialog> createState() =>
      _CardZoomLightboxDialogState();
}

class _CardZoomLightboxDialogState extends State<_CardZoomLightboxDialog> {
  late final TransformationController _transformationController;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_handleTransform);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransform);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTransform() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _zoomLevel).abs() > 0.05) {
      setState(() => _zoomLevel = scale);
    }
  }

  void _setZoom(double newScale) {
    final clamped = newScale.clamp(0.5, 4.0);
    setState(() {
      _zoomLevel = clamped;
      _transformationController.value =
          Matrix4.diagonal3Values(clamped, clamped, 1.0);
    });
  }

  void _zoomIn() => _setZoom(_zoomLevel + 0.5);

  void _zoomOut() => _setZoom(_zoomLevel - 0.5);

  void _resetZoom() => _setZoom(1.0);

  void _onDoubleTap() {
    if (_zoomLevel > 1.2) {
      _resetZoom();
    } else {
      _setZoom(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleSettings.currentLocale == AppLocale.en;

    return Dialog(
      key: const Key('card_zoom_lightbox'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(120),
              child: Center(
                child: GestureDetector(
                  onDoubleTap: _onDoubleTap,
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 1400, maxHeight: 900),
                    padding: const EdgeInsets.all(16),
                    child: DexCompletionCard(
                      dex: widget.dex,
                      stats: widget.stats,
                      entries: widget.entries,
                      config: widget.config,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top-Right Toolbar (Zoom In, Zoom Out, Reset, Close)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('btn_zoom_out'),
                    icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                    tooltip: isEn ? 'Zoom Out (-)' : 'Verkleinern (-)',
                    onPressed: _zoomOut,
                    visualDensity: VisualDensity.compact,
                  ),
                  InkWell(
                    key: const Key('btn_zoom_reset'),
                    onTap: _resetZoom,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(_zoomLevel * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('btn_zoom_in'),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    tooltip: isEn ? 'Zoom In (+)' : 'Vergrößern (+)',
                    onPressed: _zoomIn,
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  IconButton(
                    key: const Key('btn_close_lightbox'),
                    icon: const Icon(Icons.close, size: 20, color: Colors.white),
                    tooltip: t.dex_progress_close,
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Hint Bar
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pinch,
                        size: 16, color: Color(0xFFA5B4FC)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isEn
                            ? 'Pinch or buttons to zoom • Drag to pan'
                            : 'Geste oder Buttons zum Zoomen • Ziehen zum Verschieben',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

