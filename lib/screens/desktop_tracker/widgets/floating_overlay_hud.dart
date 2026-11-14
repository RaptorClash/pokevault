import 'package:flutter/material.dart';
import '../../../models/user_dex.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// Lightweight, draggable Always-on-Top Floating HUD designed to hover over
/// an emulator or game window to display real-time encounter and dex status.
class FloatingOverlayHud extends StatefulWidget {
  final ScannerEvent? latestEvent;
  final UserDex? activeDex;
  final VoidCallback? onMarkCaught;
  final VoidCallback? onClose;
  final double initialOpacity;
  final bool isPinned;
  final bool isCompact;
  final ValueChanged<double>? onOpacityChanged;
  final ValueChanged<bool>? onCompactChanged;
  final ValueChanged<bool>? onPinnedChanged;
  final String? evolutionSummary;
  final bool hasMissingEvolutions;

  const FloatingOverlayHud({
    super.key,
    this.latestEvent,
    this.activeDex,
    this.onMarkCaught,
    this.onClose,
    this.initialOpacity = 0.90,
    this.isPinned = true,
    this.isCompact = false,
    this.onOpacityChanged,
    this.onCompactChanged,
    this.onPinnedChanged,
    this.evolutionSummary,
    this.hasMissingEvolutions = false,
  });

  @override
  State<FloatingOverlayHud> createState() => _FloatingOverlayHudState();
}

class _FloatingOverlayHudState extends State<FloatingOverlayHud> {
  late double _opacity;
  late bool _compact;
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    _opacity = widget.initialOpacity.clamp(0.3, 1.0);
    _compact = widget.isCompact;
    _pinned = widget.isPinned;
  }

  @override
  void didUpdateWidget(covariant FloatingOverlayHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompact != oldWidget.isCompact) {
      _compact = widget.isCompact;
    }
    if (widget.isPinned != oldWidget.isPinned) {
      _pinned = widget.isPinned;
    }
  }

  void _toggleCompact() {
    setState(() {
      _compact = !_compact;
    });
    widget.onCompactChanged?.call(_compact);
  }

  void _togglePinned() {
    setState(() {
      _pinned = !_pinned;
    });
    widget.onPinnedChanged?.call(_pinned);
  }

  void _updateOpacity(double val) {
    setState(() {
      _opacity = val;
    });
    widget.onOpacityChanged?.call(_opacity);
  }

  bool _isPokemonCaught() {
    final event = widget.latestEvent;
    final dex = widget.activeDex;
    if (event == null || dex == null || event.pokemonId == null) return false;
    return dex.caughtIds.contains(event.pokemonId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCaught = _isPokemonCaught();
    final event = widget.latestEvent;
    final isShiny = event?.isShiny ?? false;

    return Opacity(
      opacity: _opacity,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _compact ? 280 : 330,
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: _compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isShiny
                  ? const Color(0xFFFBC02D)
                  : (isDark ? const Color(0xFF323246) : Colors.grey.shade700),
              width: isShiny ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isShiny
                    ? const Color(0xFFFBC02D).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.5),
                blurRadius: isShiny ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'PokéVault HUD',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Compact Toggle
                      IconButton(
                        key: const Key('btn_hud_toggle_compact'),
                        icon: Icon(
                          _compact ? Icons.unfold_more : Icons.unfold_less,
                          size: 15,
                          color: Colors.white70,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: _compact ? 'Erweitern' : 'Kompakt',
                        onPressed: _toggleCompact,
                      ),
                      const SizedBox(width: 4),
                      // Pin Toggle
                      IconButton(
                        key: const Key('btn_hud_pin'),
                        icon: Icon(
                          _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 15,
                          color: _pinned ? const Color(0xFFFBC02D) : Colors.white70,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: 'Immer im Vordergrund',
                        onPressed: _togglePinned,
                      ),
                      const SizedBox(width: 4),
                      // Close button
                      if (widget.onClose != null)
                        IconButton(
                          key: const Key('btn_hud_close'),
                          icon: const Icon(Icons.close, size: 15, color: Colors.white70),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          tooltip: 'Schließen',
                          onPressed: widget.onClose,
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Content Body
              if (event == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: Colors.white54),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warte auf Spiel-Ereignis...',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pokémon Icon / Sprite Avatar
                    Container(
                      width: _compact ? 36 : 48,
                      height: _compact ? 36 : 48,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isShiny
                              ? const Color(0xFFFBC02D)
                              : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isShiny ? '✨' : '🎮',
                          style: TextStyle(fontSize: _compact ? 18 : 24),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Pokémon Name, ID & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${isShiny ? '✨ ' : ''}${event.matchedName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isShiny
                                        ? const Color(0xFFFFF176)
                                        : Colors.white,
                                    fontSize: _compact ? 13 : 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (event.instanceIndex != null) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Color(event.instanceColorHex ?? 0xFFA855F7)
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Color(event.instanceColorHex ?? 0xFFA855F7),
                                    ),
                                  ),
                                  child: Text(
                                    '#${event.instanceIndex}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (isShiny) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBC02D).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFBC02D).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'SHINY',
                                    style: TextStyle(
                                      color: Color(0xFFFDD835),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCaught
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCaught
                                          ? Colors.green.withValues(alpha: 0.5)
                                          : Colors.amber.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    isCaught ? '✔ Gefangen' : '⚠️ Fehlt im Ziel-Dex',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCaught ? Colors.greenAccent : Colors.amberAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (event.pokemonId != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '#${event.pokemonId!.toString().padLeft(3, '0')}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if ((widget.evolutionSummary ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.evolutionSummary!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.hasMissingEvolutions
                                    ? const Color(0xFF67E8F9)
                                    : Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Quick Catch Button
                    if (widget.onMarkCaught != null && !isCaught)
                      IconButton(
                        key: const Key('btn_hud_mark_caught'),
                        onPressed: widget.onMarkCaught,
                        icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 26),
                        tooltip: 'In Ziel-Dex eintragen',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),

              // Opacity Slider (hidden in compact mode)
              if (!_compact) ...[
                const SizedBox(height: 6),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Deckkraft',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: Colors.redAccent,
                          thumbColor: Colors.redAccent,
                        ),
                        child: Slider(
                          key: const Key('hud_opacity_slider'),
                          value: _opacity,
                          min: 0.3,
                          max: 1.0,
                          onChanged: _updateOpacity,
                        ),
                      ),
                    ),
                    Text(
                      '${(_opacity * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
