import 'package:flutter/material.dart';
import '../../../../models/dex_card_models.dart';
import '../../../../i18n/strings.g.dart';

/// Detail toggles section (Generations, Variants, Types, Collections, Box Stats, Date, Branding)
/// for [DexCompletionCardDialog].
class CompletionCardTogglesSection extends StatelessWidget {
  final DexCardConfig config;
  final bool isEn;
  final ValueChanged<DexCardConfig> onConfigChanged;

  const CompletionCardTogglesSection({
    super.key,
    required this.config,
    required this.isEn,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist_rtl_outlined, size: 16, color: Color(0xFF818CF8)),
            const SizedBox(width: 6),
            Text(
              isEn ? 'Living Dex Card Elements' : 'Karten-Inhalte anpassen',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1. Generationen
        _buildToggleTile(
          key: const Key('toggle_generations'),
          title: isEn ? 'Generation Breakdown' : 'Generationen-Abdeckung',
          subtitle: isEn
              ? 'Shows Gen 1-9 progression bars'
              : 'Zeigt Fortschrittsbalken pro Region/Gen',
          icon: Icons.auto_graph,
          value: config.showGenerations,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(showGenerations: val)),
        ),
        if (config.showGenerations)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _buildToggleTile(
              key: const Key('toggle_only_started_generations'),
              title: t.dex_card_only_started_gens,
              subtitle: t.dex_card_only_started_gens_sub,
              icon: Icons.filter_alt_outlined,
              value: config.showOnlyStartedGenerations,
              onChanged: (val) =>
                  onConfigChanged(config.copyWith(showOnlyStartedGenerations: val)),
            ),
          ),

        // 2. Varianten
        _buildToggleTile(
          key: const Key('toggle_variants'),
          title: isEn ? 'Variants & Forms' : 'Formen & Varianten',
          subtitle: isEn
              ? 'Megas, Gigantamax, Regional forms'
              : 'Megas, Gigadynamax, Regional-Formen',
          icon: Icons.category_outlined,
          value: config.showVariants,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(showVariants: val)),
        ),

        // 3. Typen
        _buildToggleTile(
          key: const Key('toggle_types'),
          title: isEn ? 'Type Coverage' : 'Typen-Abdeckung',
          subtitle: isEn
              ? 'Shows element type badges'
              : 'Zeigt Element-Typen Badges',
          icon: Icons.bubble_chart_outlined,
          value: config.showTypes,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(showTypes: val)),
        ),
        if (config.showTypes)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
            child: _buildTypeDisplayLimitSelector(isEn),
          ),

        // 4. Spezial-Sammlungen
        _buildToggleTile(
          key: const Key('toggle_special_collections'),
          title: isEn ? 'Special Collections' : 'Spezial-Sammlungen',
          subtitle: isEn
              ? 'Shinies, Alphas, Ribbons, Tera'
              : 'Shinies, Alpha-Riesen, Bänder, Tera',
          icon: Icons.stars_outlined,
          value: config.showSpecialCollections,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(showSpecialCollections: val)),
        ),

        // 5. Box-Statistiken
        _buildToggleTile(
          key: const Key('toggle_box_stats'),
          title: isEn ? 'Box Statistics' : 'PC-Boxen Statistik',
          subtitle: isEn
              ? 'Full boxes, gaps remaining'
              : 'Volle Boxen, verbleibende Lücken',
          icon: Icons.inventory_2_outlined,
          value: config.showBoxStats,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(showBoxStats: val)),
        ),

        // 6. Datum
        _buildToggleTile(
          key: const Key('toggle_date'),
          title: isEn ? 'Completion Date' : 'Datum & Zeitstempel',
          subtitle: isEn
              ? 'Display date on card'
              : 'Datum auf der Karte anzeigen',
          icon: Icons.calendar_today_outlined,
          value: config.showDate,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(showDate: val)),
        ),

        // 7. PokéVault-Logo Wasserzeichen
        _buildToggleTile(
          key: const Key('toggle_watermark_logo'),
          title: isEn ? 'PokéVault Branding' : 'PokéVault-Wasserzeichen',
          subtitle: isEn
              ? 'Display PokéVault logo watermark'
              : 'PokéVault Logo & Branding einblenden',
          icon: Icons.verified_outlined,
          value: config.showWatermarkLogo,
          onChanged: (val) =>
              onConfigChanged(config.copyWith(showWatermarkLogo: val)),
        ),
      ],
    );
  }

  Widget _buildTypeDisplayLimitSelector(bool isEn) {
    return SegmentedButton<int>(
      key: const Key('segment_type_display_limit'),
      segments: [
        ButtonSegment(
          value: 6,
          label: Text(
            t.dex_card_types_top6,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        ButtonSegment(
          value: 12,
          label: Text(
            t.dex_card_types_top12,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        ButtonSegment(
          value: 18,
          label: Text(
            t.dex_card_types_all18,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
      selected: {config.typeDisplayLimit},
      onSelectionChanged: (newSelection) {
        if (newSelection.isNotEmpty) {
          onConfigChanged(config.copyWith(typeDisplayLimit: newSelection.first));
        }
      },
    );
  }

  Widget _buildToggleTile({
    required Key key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: SwitchListTile(
          key: key,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          secondary: Icon(icon, size: 18, color: const Color(0xFF818CF8)),
          title: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          value: value,
          activeThumbColor: const Color(0xFF6366F1),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
