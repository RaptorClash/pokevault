import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../services/database_service.dart';
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
  final String? initialDexId;

  const DesktopTrackerScreen({
    super.key,
    required this.coordinator,
    this.detectedWindows = const [],
    this.windowSource,
    this.initialDexId,
  });

  @override
  State<DesktopTrackerScreen> createState() => _DesktopTrackerScreenState();
}

class _DesktopTrackerScreenState extends State<DesktopTrackerScreen> {
  DesktopOverlayMode _activeMode = DesktopOverlayMode.floatingHud;
  late List<DesktopWindowInfo> _windows;
  DesktopWindowInfo? _selectedWindow;
  String? _selectedDexId;
  final List<ScannerEvent> _events = [];
  StreamSubscription<ScannerEvent>? _eventSub;
  bool _isMiniHudView = false;
  bool _isScanningActive = true;
  final TextEditingController _testTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _windows = widget.detectedWindows.isNotEmpty
        ? List.from(widget.detectedWindows)
        : WindowDetector().getOpenWindows();

    if (_windows.isNotEmpty) {
      // Prioritize known emulators if present
      _selectedWindow = _windows.firstWhere(
        (w) => w.isKnownEmulator,
        orElse: () => _windows.first,
      );
      widget.windowSource?.setSelectedWindow(_selectedWindow);
    }

    _selectedDexId = widget.initialDexId;

    _eventSub = widget.coordinator.events.listen((event) {
      if (!mounted) return;
      setState(() {
        _events.insert(0, event);
        if (_events.length > 50) {
          _events.removeLast();
        }
      });

      // Auto-mark caught if configured
      if (widget.coordinator.settings.autoMarkCaught &&
          event.type == ScannerEventType.caught &&
          event.pokemonId != null &&
          _selectedDexId != null) {
        _markPokemonCaughtInDex(
          event.pokemonId!,
          isShiny: event.isShiny,
          isAlpha: event.isAlpha,
          silent: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _testTextController.dispose();
    super.dispose();
  }

  void _refreshWindows() {
    setState(() {
      _windows = WindowDetector().getOpenWindows();
      if (_windows.isNotEmpty) {
        if (!_windows.any((w) => w.id == _selectedWindow?.id)) {
          _selectedWindow = _windows.firstWhere(
            (w) => w.isKnownEmulator,
            orElse: () => _windows.first,
          );
          widget.windowSource?.setSelectedWindow(_selectedWindow);
        }
      }
    });
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
          (mode == DesktopOverlayMode.floatingHud && _isMiniHudView);
    });
    widget.coordinator.updateSettings(
      widget.coordinator.settings.copyWith(desktopOverlayMode: mode),
    );
  }

  void _toggleScanning() {
    setState(() {
      _isScanningActive = !_isScanningActive;
      if (_isScanningActive) {
        widget.coordinator.start();
      } else {
        widget.coordinator.stop();
      }
    });
  }

  Future<void> _markPokemonCaughtInDex(
    int pokemonId, {
    bool isShiny = false,
    bool isAlpha = false,
    bool silent = false,
  }) async {
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final targetDex = _getActiveDex(dexProvider);
    if (targetDex == null) return;

    final idStr = pokemonId.toString();
    if (!targetDex.caughtIds.contains(idStr)) {
      targetDex.caughtIds.add(idStr);
    }
    if (isShiny && !targetDex.shinyIds.contains(idStr)) {
      targetDex.shinyIds.add(idStr);
    }
    if (isAlpha && !targetDex.alphaIds.contains(idStr)) {
      targetDex.alphaIds.add(idStr);
    }

    try {
      await DatabaseService.instance.savePokemonStatus(
        targetDex.id,
        idStr,
        isCaught: true,
        isShiny: isShiny ? true : null,
        isAlpha: isAlpha ? true : null,
      );
    } catch (_) {
      // DatabaseService might be mocked or in memory in tests
    }

    await dexProvider.saveUserDexAndSync(targetDex);

    if (mounted) {
      setState(() {});
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('In "${targetDex.title}" eingetragen!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  UserDex? _getActiveDex(DexProvider dexProvider) {
    final dexes = dexProvider.userDexes;
    if (dexes.isEmpty) return null;
    _selectedDexId ??= dexes.first.id;
    return dexes.cast<UserDex?>().firstWhere(
          (d) => d?.id == _selectedDexId,
          orElse: () => dexes.first,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dexProvider = Provider.of<DexProvider>(context);
    final activeDex = _getActiveDex(dexProvider);
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
                _markPokemonCaughtInDex(
                  latestEvent!.pokemonId!,
                  isShiny: latestEvent.isShiny,
                  isAlpha: latestEvent.isAlpha,
                );
              }
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Desktop Tracker & Overlay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isScanningActive
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isScanningActive
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.amber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isScanningActive ? Colors.green : Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isScanningActive ? 'Live Aktiv' : 'Pausiert',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isScanningActive ? Colors.green : Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Target Dex Dropdown in AppBar
          if (dexProvider.userDexes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF22222E) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF323242) : Colors.grey.shade300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('target_dex_dropdown'),
                    value: activeDex?.id,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: dexProvider.userDexes.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.book_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${d.title} (${d.caughtIds.length})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newDexId) {
                      if (newDexId != null) {
                        setState(() {
                          _selectedDexId = newDexId;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Fenster aktualisieren',
            onPressed: _refreshWindows,
          ),
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt),
            tooltip: 'Kompakt-HUD Modus',
            onPressed: () {
              setState(() {
                _isMiniHudView = true;
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Control Panel (360px)
                      SizedBox(
                        width: 360,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildWindowControlCard(isDark, theme),
                              const SizedBox(height: 14),
                              _buildTargetFocusCard(latestEvent, activeDex, isDark, theme),
                              const SizedBox(height: 14),
                              _buildTestInputCard(isDark, theme),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right Column: Live Event Feed (Flexible)
                      Expanded(
                        child: _buildEventFeedCard(activeDex, isDark, theme),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildWindowControlCard(isDark, theme),
                        const SizedBox(height: 14),
                        _buildTargetFocusCard(latestEvent, activeDex, isDark, theme),
                        const SizedBox(height: 14),
                        _buildTestInputCard(isDark, theme),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 400,
                          child: _buildEventFeedCard(activeDex, isDark, theme),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildWindowControlCard(bool isDark, ThemeData theme) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Zielfenster / Anwendung',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshWindows,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Aktualisieren', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<DesktopWindowInfo>(
              key: const Key('emulator_dropdown'),
              initialValue: _selectedWindow,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
              ),
              items: _windows.map((w) {
                return DropdownMenuItem<DesktopWindowInfo>(
                  value: w,
                  child: Row(
                    children: [
                      Text(w.isKnownEmulator ? '🎮' : '🖥️', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: w.isKnownEmulator ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onWindowSelected,
            ),
            const SizedBox(height: 14),
            const Text(
              'Modus',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildModeOption(
                    key: 'tab_dashboard',
                    label: 'Dashboard',
                    icon: Icons.dashboard,
                    isSelected: _activeMode == DesktopOverlayMode.floatingHud && !_isMiniHudView,
                    onTap: () => _setMode(DesktopOverlayMode.floatingHud),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildModeOption(
                    key: 'tab_mini_hud',
                    label: 'Mini-HUD',
                    icon: Icons.picture_in_picture_alt,
                    isSelected: _isMiniHudView,
                    onTap: () {
                      setState(() {
                        _isMiniHudView = true;
                      });
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildModeOption(
                    key: 'tab_silent',
                    label: 'Stiller Modus',
                    icon: Icons.visibility_off,
                    isSelected: _activeMode == DesktopOverlayMode.silentBackground,
                    onTap: () => _setMode(DesktopOverlayMode.silentBackground),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _toggleScanning,
                icon: Icon(_isScanningActive ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _isScanningActive ? 'Erfassung pausieren' : 'Erfassung starten',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _isScanningActive ? Colors.amber.shade800 : Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      key: Key(key),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF242432) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isDark ? const Color(0xFF343444) : Colors.grey.shade300),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetFocusCard(
    ScannerEvent? event,
    UserDex? activeDex,
    bool isDark,
    ThemeData theme,
  ) {
    final id = event?.pokemonId;
    final name = event?.matchedName ?? 'Warte auf Spiel...';
    final isCaught = activeDex != null && id != null && activeDex.caughtIds.contains(id.toString());
    final isShiny = event?.isShiny ?? false;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktueller Live-Fokus',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                if (event != null)
                  Text(
                    event.type.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: event.type == ScannerEventType.caught ? Colors.green : Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF343444) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: id != null && id > 0
                          ? Image.network(
                              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${isShiny ? 'shiny/' : ''}$id.png',
                              errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 28),
                            )
                          : const Icon(Icons.search, size: 28, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isShiny) ...[
                              const SizedBox(width: 4),
                              const Text('✨', style: TextStyle(fontSize: 14)),
                            ],
                          ],
                        ),
                        if (id != null)
                          Text(
                            '#${id.toString().padLeft(3, '0')}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCaught
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCaught
                                  ? Colors.green.withValues(alpha: 0.4)
                                  : Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            isCaught ? '✓ Im Ziel-Dex gefangen' : '★ Fehlt im Ziel-Dex!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCaught ? Colors.green : Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (id != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('btn_mark_caught_in_dex'),
                  onPressed: () => _markPokemonCaughtInDex(
                    id,
                    isShiny: isShiny,
                    isAlpha: event?.isAlpha ?? false,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('In "${activeDex?.title ?? "Dex"}" eintragen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInputCard(bool isDark, ThemeData theme) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schnelltest (OCR-Simulator)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _testTextController,
                    decoration: InputDecoration(
                      hintText: 'z. B. Glumanda wurde gefangen!',
                      hintStyle: const TextStyle(fontSize: 11),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onSubmitted: (txt) {
                      if (txt.trim().isNotEmpty) {
                        widget.coordinator.processText(txt.trim());
                        _testTextController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  tooltip: 'Text testen',
                  onPressed: () {
                    final txt = _testTextController.text.trim();
                    if (txt.isNotEmpty) {
                      widget.coordinator.processText(txt);
                      _testTextController.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventFeedCard(UserDex? activeDex, bool isDark, ThemeData theme) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B1B24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C3C) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Live-Ereignisse',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_events.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_events.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _events.clear()),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Leeren', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.catching_pokemon, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Warte auf In-Game Ereignisse...',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Wähle dein Emulator-Fenster aus. Fänge und Begegnungen werden automatisch erkannt.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ev = _events[index];
                        final isCaught = activeDex != null &&
                            ev.pokemonId != null &&
                            activeDex.caughtIds.contains(ev.pokemonId.toString());

                        return _buildEventTile(ev, isCaught, isDark, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(ScannerEvent ev, bool isCaught, bool isDark, ThemeData theme) {
    final id = ev.pokemonId;
    final isShiny = ev.isShiny;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF343444) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B24) : Colors.white,
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    if (isShiny) const Text(' ✨'),
                    const SizedBox(width: 6),
                    _buildEventTypeBadge(ev.type),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ev.rawText,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (id != null)
            isCaught
                ? const Text('✓ Im Dex', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))
                : TextButton(
                    onPressed: () => _markPokemonCaughtInDex(
                      id,
                      isShiny: isShiny,
                      isAlpha: ev.isAlpha,
                    ),
                    child: const Text('+ Eintragen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
        ],
      ),
    );
  }

  Widget _buildEventTypeBadge(ScannerEventType type) {
    Color bg;
    Color fg;
    String label;

    switch (type) {
      case ScannerEventType.caught:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green;
        label = 'FANG';
        break;
      case ScannerEventType.encounter:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        label = 'BEGEGNUNG';
        break;
      case ScannerEventType.evolved:
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        label = 'ENTWICKLUNG';
        break;
      case ScannerEventType.shinyDetected:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber;
        label = 'SHINY';
        break;
      case ScannerEventType.alphaDetected:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red;
        label = 'ALPHA';
        break;
      case ScannerEventType.unknown:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = 'INFO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
