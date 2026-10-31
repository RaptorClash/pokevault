import 'package:flutter/material.dart';
import '../../../../models/dex_card_models.dart';
import '../../../../models/pokemon.dart';
import '../../../../i18n/strings.g.dart';

/// Appearance configuration section (Style, Ratio, Mosaic mode, Watermark)
/// for [DexCompletionCardDialog].
class CompletionCardAppearanceSection extends StatelessWidget {
  final DexCardConfig config;
  final bool isEn;
  final ValueChanged<DexCardConfig> onConfigChanged;
  final List<Pokemon> allPokemon;
  final Pokemon? selectedWatermarkPokemon;
  final ValueChanged<Pokemon?> onWatermarkPokemonChanged;
  final VoidCallback? onPickWatermarkPressed;

  const CompletionCardAppearanceSection({
    super.key,
    required this.config,
    required this.isEn,
    required this.onConfigChanged,
    required this.allPokemon,
    this.selectedWatermarkPokemon,
    required this.onWatermarkPokemonChanged,
    this.onPickWatermarkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Stil & Design
        _buildSectionHeader(
          icon: Icons.style_outlined,
          title: isEn ? 'DESIGN STYLE' : 'DESIGN & STIL',
        ),
        const SizedBox(height: 8),

        // Style Selector Chips
        _buildStyleSelector(),
        const SizedBox(height: 12),

        // Ratio Selector
        _buildSectionHeader(
          icon: Icons.aspect_ratio_outlined,
          title: isEn ? 'ASPECT RATIO' : 'SEITENVERHÄLTNIS',
        ),
        const SizedBox(height: 8),
        _buildRatioSelector(),

        // Mosaic Mode (only when Style is Mosaic)
        if (config.style == DexCardStyle.mosaic) ...[
          const SizedBox(height: 12),
          _buildSectionHeader(
            icon: Icons.view_comfy_alt_outlined,
            title: isEn ? 'MOSAIC DISPLAY MODE' : 'MOSAIK-ANZEIGE',
          ),
          const SizedBox(height: 8),
          _buildMosaicModeSelector(isEn),
        ],

        const SizedBox(height: 12),
        // Watermark Selection Header
        _buildSectionHeader(
          icon: Icons.water_drop_outlined,
          title: isEn ? 'BACKGROUND WATERMARK' : 'HINTERGRUND-WASSERZEICHEN',
        ),
        const SizedBox(height: 8),
        _buildWatermarkPicker(context),
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildStyleChip(
          key: const Key('tab_analyst'),
          style: DexCardStyle.analyst,
          label: '1. The Analyst 📊',
        ),
        _buildStyleChip(
          key: const Key('tab_certificate'),
          style: DexCardStyle.certificate,
          label: '2. Zertifikat 🏆',
        ),
        _buildStyleChip(
          key: const Key('tab_mosaic'),
          style: DexCardStyle.mosaic,
          label: '3. Mosaik 🧩',
        ),
        _buildStyleChip(
          key: const Key('tab_minimalist'),
          style: DexCardStyle.minimalist,
          label: '4. Minimalist ✨',
        ),
      ],
    );
  }

  Widget _buildStyleChip({
    required Key key,
    required DexCardStyle style,
    required String label,
  }) {
    final isSelected = config.style == style;
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFFA5B4FC) : null,
      ),
      onSelected: (selected) {
        if (selected) {
          onConfigChanged(config.copyWith(style: style));
        }
      },
    );
  }

  Widget _buildMosaicModeSelector(bool isEn) {
    return SegmentedButton<DexMosaicMode>(
      key: const Key('segment_mosaic_mode'),
      segments: [
        ButtonSegment<DexMosaicMode>(
          value: DexMosaicMode.pokemon,
          label: Text(
            isEn
                ? DexMosaicMode.pokemon.labelEn
                : DexMosaicMode.pokemon.labelDe,
            style: const TextStyle(fontSize: 11),
          ),
          icon: const Icon(Icons.catching_pokemon, size: 16),
        ),
        ButtonSegment<DexMosaicMode>(
          value: DexMosaicMode.boxes,
          label: Text(
            isEn
                ? DexMosaicMode.boxes.labelEn
                : DexMosaicMode.boxes.labelDe,
            style: const TextStyle(fontSize: 11),
          ),
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
        ),
      ],
      selected: {config.mosaicMode},
      onSelectionChanged: (newSelection) {
        if (newSelection.isNotEmpty) {
          onConfigChanged(config.copyWith(mosaicMode: newSelection.first));
        }
      },
    );
  }

  Widget _buildRatioSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<DexCardRatio>(
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
        ),
        segments: [
          ButtonSegment(
            value: DexCardRatio.landscape16_9,
            label: Text(
              DexCardRatio.landscape16_9.labelDe,
              style: const TextStyle(fontSize: 11),
            ),
            icon: const Icon(Icons.crop_16_9, size: 16),
          ),
          ButtonSegment(
            value: DexCardRatio.square1_1,
            label: Text(
              DexCardRatio.square1_1.labelDe,
              style: const TextStyle(fontSize: 11),
            ),
            icon: const Icon(Icons.crop_square, size: 16),
          ),
          ButtonSegment(
            value: DexCardRatio.portrait9_16,
            label: Text(
              DexCardRatio.portrait9_16.labelDe,
              style: const TextStyle(fontSize: 11),
            ),
            icon: const Icon(Icons.crop_portrait, size: 16),
          ),
        ],
        selected: {config.ratio},
        onSelectionChanged: (newSelection) {
          if (newSelection.isNotEmpty) {
            onConfigChanged(config.copyWith(ratio: newSelection.first));
          }
        },
      ),
    );
  }

  Widget _buildWatermarkPicker(BuildContext context) {
    final wm = config.watermarkPokemon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              wm != null ? Icons.catching_pokemon : Icons.block,
              size: 20,
              color: wm != null ? Colors.amber : Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wm != null
                      ? '#${wm.pokemonId.toString().padLeft(3, '0')} ${wm.name}'
                      : t.dex_card_no_pokemon,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  wm != null
                      ? (wm.isShiny ? '✨ Shiny' : 'Standard')
                      : t.no_watermark_sub,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton.icon(
            key: const Key('btn_pick_watermark'),
            icon: const Icon(Icons.search, size: 16),
            label: Text(
              isEn ? 'Search' : 'Suchen',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: onPickWatermarkPressed,
          ),
        ],
      ),
    );
  }
}
