import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/desktop_tracker/desktop_window_source.dart';
import '../../services/desktop_tracker/window_detector.dart';
import '../../services/scanner_core/models/scanner_event.dart';
import '../../services/scanner_core/models/scanner_settings.dart';
import '../../services/scanner_core/scanner_coordinator.dart';
import 'widgets/compact_mini_hud.dart';

/// Full Desktop Tracker Dashboard supporting Full Screen, Always-on-Top Mini-HUD, and Silent tracking.
class DesktopTrackerScreen extends StatefulWidget {
  final ScannerCoordinator coordinator;
  final List<DesktopWindowInfo> detectedWindows;
  final DesktopWindowSource? windowSource;

  const DesktopTrackerScreen({
    super.key,
    required this.coordinator,
    this.detectedWindows = const [],
    this.windowSource,
  });

  @override
  State<DesktopTrackerScreen> createState() => _DesktopTrackerScreenState();
}

class _DesktopTrackerScreenState extends State<DesktopTrackerScreen> {
  DesktopOverlayMode _activeMode = DesktopOverlayMode.floatingHud;
  DesktopWindowInfo? _selectedWindow;
  final List<ScannerEvent> _events = [];
  StreamSubscription<ScannerEvent>? _eventSub;
  bool _isMiniHudView = false;

  @override
  void initState() {
    super.initState();
    if (widget.detectedWindows.isNotEmpty) {
      _selectedWindow = widget.detectedWindows.first;
      widget.windowSource?.setSelectedWindow(_selectedWindow);
    }

    _eventSub = widget.coordinator.events.listen((event) {
      if (mounted) {
        setState(() {
          _events.insert(0, event);
          if (_events.length > 50) {
            _events.removeLast();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _onWindowSelected(DesktopWindowInfo? window) {
    setState(() {
      _selectedWindow = window;
      widget.windowSource?.setSelectedWindow(window);
    });
  }

  void _setMode(DesktopOverlayMode mode) {
    setState(() {
      _activeMode = mode;
      _isMiniHudView = mode == DesktopOverlayMode.clickThroughOverlay ||
          mode == DesktopOverlayMode.floatingHud && _isMiniHudView;
    });
    widget.coordinator.updateSettings(
      widget.coordinator.settings.copyWith(desktopOverlayMode: mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final latestEvent = _events.isNotEmpty ? _events.first : null;

    if (_isMiniHudView) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CompactMiniHud(
            latestEvent: latestEvent,
            onExpand: () {
              setState(() {
                _isMiniHudView = false;
              });
            },
            onMarkCaught: () {
              if (latestEvent?.pokemonId != null) {
                widget.coordinator.processText(
                  '${latestEvent!.matchedName} wurde gefangen!',
                );
              }
            },
            onEvolve: () {
              if (latestEvent?.matchedName != null) {
                widget.coordinator.processText(
                  '${latestEvent!.matchedName} hat sich zu Entwicklung entwickelt!',
                );
              }
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Desktop Tracker & Overlay'),
        actions: [
          IconButton(
            tooltip: 'Log leeren',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                _events.clear();
              });
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar: Window Selection & Mode Config (300px)
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B22) : Colors.grey.shade50,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF2E2E3C) : Colors.grey.shade300,
                ),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overlay & Tracker Modus',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Mode Tabs
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildModeChip(
                        key: const Key('tab_dashboard'),
                        label: 'Dashboard',
                        icon: Icons.dashboard_outlined,
                        mode: DesktopOverlayMode.floatingHud,
                        isSelected: !_isMiniHudView && _activeMode == DesktopOverlayMode.floatingHud,
                        onTap: () {
                          setState(() {
                            _isMiniHudView = false;
                            _activeMode = DesktopOverlayMode.floatingHud;
                          });
                        },
                      ),
                      _buildModeChip(
                        key: const Key('tab_mini_hud'),
                        label: 'Kompakt-HUD',
                        icon: Icons.picture_in_picture_alt,
                        mode: DesktopOverlayMode.floatingHud,
                        isSelected: _isMiniHudView,
                        onTap: () {
                          setState(() {
                            _isMiniHudView = true;
                          });
                        },
                      ),
                      _buildModeChip(
                        key: const Key('tab_silent'),
                        label: 'Stiller Modus',
                        icon: Icons.visibility_off_outlined,
                        mode: DesktopOverlayMode.silentBackground,
                        isSelected: _activeMode == DesktopOverlayMode.silentBackground,
                        onTap: () => _setMode(DesktopOverlayMode.silentBackground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Emulator Selector
                  const Text(
                    'Zielfenster / Emulator',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DesktopWindowInfo>(
                    key: const Key('emulator_dropdown'),
                    initialValue: _selectedWindow,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: widget.detectedWindows.map((w) {
                      return DropdownMenuItem<DesktopWindowInfo>(
                        value: w,
                        child: Text(
                          w.isKnownEmulator ? '🎮 ${w.title}' : w.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: w.isKnownEmulator ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onWindowSelected,
                  ),
                  const SizedBox(height: 16),

                  // Dialogue Crop Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF24242F) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF363647) : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.crop_outlined, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            const Text(
                              'Hybrid-Scanbereich',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Automatisch zentriert auf Textbox (untere 30% des Spielfensters).',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mini Preview Card
                  const Text(
                    'Aktueller Live-Fokus',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CompactMiniHud(
                    latestEvent: latestEvent,
                    onExpand: null,
                  ),
                ],
              ),
            ),
          ),

          // Right Area: Live Event Feed & Catches
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Live Tracker Stream & Fänge',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, size: 8, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'OCR Aktiv',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Event list
                  Expanded(
                    child: _events.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 48,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Warte auf In-Game Textbox...',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _events.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final ev = _events[index];
                              return _buildEventTile(ev, isDark, theme);
                            },
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

  Widget _buildModeChip({
    required Key key,
    required String label,
    required IconData icon,
    required DesktopOverlayMode mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(ScannerEvent ev, bool isDark, ThemeData theme) {
    final id = ev.pokemonId;
    final isCaught = ev.type == ScannerEventType.caught;
    final isShiny = ev.isShiny;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22222D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isShiny
              ? const Color(0xFFFFB300)
              : (isDark ? const Color(0xFF323244) : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171720) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: id != null && id > 0
                  ? Image.network(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${isShiny ? 'shiny/' : ''}$id.png',
                      errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 20),
                    )
                  : const Icon(Icons.help_outline, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ev.matchedName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (id != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '#${id.toString().padLeft(3, '0')}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                    if (isShiny) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '✨ SHINY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB300),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ev.rawText,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isCaught ? Colors.green.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isCaught ? '✔ Gefangen' : 'Encounter',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isCaught ? Colors.green : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
