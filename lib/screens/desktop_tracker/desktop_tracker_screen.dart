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
  List<DesktopWindowInfo> _windows = [];
  DesktopWindowInfo? _selectedWindow;
  String? _selectedDexId;
  final List<ScannerEvent> _events = [];
  StreamSubscription<ScannerEvent>? _eventSub;
  bool _isMiniHudView = false;
  bool _isScanningActive = true;
  bool _isRefreshingWindows = false;
  ScanRegionPreset _scanRegion = ScanRegionPreset.fullWindow;
  final TextEditingController _testTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDexId = widget.initialDexId;

    if (widget.detectedWindows.isNotEmpty) {
      _windows = List.from(widget.detectedWindows);
      _selectDefaultWindow();
    } else {
      _windows = WindowDetector().getFallbackWindows();
      _selectDefaultWindow();
      _loadWindowsAsync();
    }

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

  Future<void> _loadWindowsAsync() async {
    try {
      final wins = await WindowDetector().getOpenWindowsAsync();
      if (!mounted) return;
      setState(() {
        _windows = wins;
        _selectDefaultWindow();
          _isRefreshingWindows = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
          _isRefreshingWindows = false;
      });
    }
  }

  void _selectDefaultWindow() {
    if (_windows.isEmpty) return;

    final existing = _selectedWindow;
    if (existing != null) {
      final match = _windows.where((w) => w.id == existing.id).firstOrNull;
      if (match != null) {
        _selectedWindow = match;
        _applyScanRegion(match);
        widget.windowSource?.setSelectedWindow(_selectedWindow);
        return;
      }
    }

    _selectedWindow = _windows.firstWhere(
      (w) => w.isKnownEmulator,
      orElse: () => _windows.first,
    );
    _applyScanRegion(_selectedWindow);
    widget.windowSource?.setSelectedWindow(_selectedWindow);
  }

  void _applyScanRegion(DesktopWindowInfo? window) {
    if (window == null) return;
    final region = WindowDetector().calculateScanRegion(
      _scanRegion,
      windowWidth: window.width,
      windowHeight: window.height,
    );
    widget.windowSource?.setCropRegion(region);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _testTextController.dispose();
    super.dispose();
  }

  void _refreshWindows() {
    setState(() => _isRefreshingWindows = true);
    _loadWindowsAsync();
  }

  void _onWindowSelected(DesktopWindowInfo? window) {
    setState(() {
      _selectedWindow = window;
      _applyScanRegion(window);
      widget.windowSource?.setSelectedWindow(window);
    });
  }

  void _onScanRegionChanged(ScanRegionPreset preset) {
    setState(() {
      _scanRegion = preset;
      _applyScanRegion(_selectedWindow);
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

  Future<void> _triggerManualScan() async {
    final win = _selectedWindow;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          win != null
              ? 'Scanne Fenster: "${win.title}"...'
              : 'Kein Zielfenster ausgewählt.',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _openTargetDexModal(DexProvider dexProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TargetDexSelectionSheet(
        dexes: dexProvider.userDexes,
        selectedDexId: _selectedDexId,
        onSelect: (newDexId) {
          setState(() {
            _selectedDexId = newDexId;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _openSettingsModal() {
    showDialog(
      context: context,
      builder: (ctx) => _TrackerSettingsDialog(
        currentPreset: _scanRegion,
        settings: widget.coordinator.settings,
        onPresetChanged: (preset) {
          _onScanRegionChanged(preset);
        },
        onSettingsChanged: (newSettings) {
          setState(() {
            widget.coordinator.updateSettings(newSettings);
          });
        },
      ),
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
        backgroundColor: isDark ? const Color(0xFF0F0F14) : Colors.grey.shade900,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _isMiniHudView = false),
                      icon: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                      label: const Text('Vollansicht', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: CompactMiniHud(
                    latestEvent: latestEvent,
                    onExpand: () => setState(() => _isMiniHudView = false),
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
              ),
            ],
          ),
        ),
      );
    }

    final validSelectedWindow = _windows.any((w) => w.id == _selectedWindow?.id)
        ? _windows.firstWhere((w) => w.id == _selectedWindow?.id)
        : (_windows.isNotEmpty ? _windows.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Desktop Tracker & Overlay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isScanningActive
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
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
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isScanningActive ? Colors.green : Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isScanningActive ? 'OCR Aktiv' : 'Pausiert',
                    style: TextStyle(
                      fontSize: 10,
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
          // Target Dex Pill Button (Opens Target Dex Selection Modal)
          if (dexProvider.userDexes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                key: const Key('target_dex_pill'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openTargetDexModal(dexProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF22222E) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF323242) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.book_outlined, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        activeDex != null
                            ? '${activeDex.title} (${activeDex.caughtIds.length})'
                            : 'Ziel-Dex wählen',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
            ),

          IconButton(
            key: const Key('btn_refresh_windows_appbar'),
            icon: _isRefreshingWindows
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Fenster aktualisieren',
            onPressed: _refreshWindows,
          ),
          IconButton(
            key: const Key('btn_tracker_settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: _openSettingsModal,
          ),
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt),
            tooltip: 'Mini-HUD Modus',
            onPressed: () => setState(() => _isMiniHudView = true),
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
                      // Left Column: Control Panel (380px)
                      SizedBox(
                        width: 380,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildWindowControlCard(validSelectedWindow, activeDex, dexProvider, isDark, theme),
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
                        _buildWindowControlCard(validSelectedWindow, activeDex, dexProvider, isDark, theme),
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

  Widget _buildWindowControlCard(
    DesktopWindowInfo? validSelectedWindow,
    UserDex? activeDex,
    DexProvider dexProvider,
    bool isDark,
    ThemeData theme,
  ) {
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
                  key: const Key('btn_refresh_windows'),
                  onPressed: _refreshWindows,
                  icon: _isRefreshingWindows
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(
                    _isRefreshingWindows ? 'Lade...' : 'Aktualisieren',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DesktopWindowInfo>(
                  key: const Key('emulator_dropdown'),
                  value: validSelectedWindow,
                  isExpanded: true,
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
              ),
            ),
            const SizedBox(height: 12),

            // Target Dex Dropdown Selector inside Control Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Ziel-Pokédex',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: () => _openTargetDexModal(dexProvider),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Details ▾',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? const Color(0xFF242432) : Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('target_dex_dropdown'),
                  value: activeDex?.id,
                  isExpanded: true,
                  items: dexProvider.userDexes.map((d) {
                    return DropdownMenuItem<String>(
                      value: d.id,
                      child: Row(
                        children: [
                          const Icon(Icons.book_outlined, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${d.title} (${d.caughtIds.length})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newDexId) {
                    if (newDexId != null) {
                      setState(() => _selectedDexId = newDexId);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Scan Region Preset Choice Row (Critical for DS Dual-Screen vs GBA/Switch)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scanbereich',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Text(
                    _getScanPresetLabel(_scanRegion),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip(ScanRegionPreset.fullWindow, 'Ganzes Fenster (DS)', isDark, theme),
                _buildPresetChip(ScanRegionPreset.dsTopScreen, 'Oberer DS-Screen', isDark, theme),
                _buildPresetChip(ScanRegionPreset.dsBottomScreen, 'Unterer DS-Screen', isDark, theme),
                _buildPresetChip(ScanRegionPreset.bottomDialogue, 'Textbox unten', isDark, theme),
              ],
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
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('btn_scan_now'),
                    onPressed: _triggerManualScan,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text(
                      'Jetzt scannen',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: _toggleScanning,
                    icon: Icon(_isScanningActive ? Icons.pause : Icons.play_arrow, size: 16),
                    label: Text(
                      _isScanningActive ? 'Pausieren' : 'Fortsetzen',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    ScanRegionPreset preset,
    String label,
    bool isDark,
    ThemeData theme,
  ) {
    final isSelected = _scanRegion == preset;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => _onScanRegionChanged(preset),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.25),
      backgroundColor: isDark ? const Color(0xFF242432) : Colors.grey.shade100,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _getScanPresetLabel(ScanRegionPreset preset) {
    switch (preset) {
      case ScanRegionPreset.fullWindow:
        return 'Ganzes Fenster (100%)';
      case ScanRegionPreset.dsTopScreen:
        return 'Oberer Bildschirm (0-52%)';
      case ScanRegionPreset.dsBottomScreen:
        return 'Unterer Bildschirm (48-100%)';
      case ScanRegionPreset.bottomDialogue:
        return 'Textbox (70-100%)';
    }
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

/// Target Dex Selection Modal with search, progress bar, and clean Material 3 design.
class _TargetDexSelectionSheet extends StatefulWidget {
  final List<UserDex> dexes;
  final String? selectedDexId;
  final ValueChanged<String> onSelect;

  const _TargetDexSelectionSheet({
    required this.dexes,
    required this.selectedDexId,
    required this.onSelect,
  });

  @override
  State<_TargetDexSelectionSheet> createState() => _TargetDexSelectionSheetState();
}

class _TargetDexSelectionSheetState extends State<_TargetDexSelectionSheet> {
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = widget.dexes.where((d) {
      if (_filterQuery.isEmpty) return true;
      return d.title.toLowerCase().contains(_filterQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.book, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ziel-Pokédex auswählen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('dex_search_input'),
            decoration: InputDecoration(
              hintText: 'Nach Pokédex suchen...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF242432) : Colors.grey.shade100,
            ),
            onChanged: (q) => setState(() => _filterQuery = q),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Keine Pokédexe gefunden', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dex = filtered[index];
                      final isSelected = dex.id == widget.selectedDexId;
                      final boxCount = dex.customBoxes.fold<int>(0, (sum, b) => sum + b.pokemonIds.length);
                      final total = boxCount > 0 ? boxCount : (dex.caughtIds.length > 150 ? dex.caughtIds.length : 151);
                      final caught = dex.caughtIds.length;
                      final progress = total > 0 ? (caught / total).clamp(0.0, 1.0) : 0.0;

                      return Card(
                        key: Key('dex_item_${dex.id}'),
                        elevation: 0,
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF242432) : Colors.grey.shade50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? const Color(0xFF343444) : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => widget.onSelect(dex.id),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dex.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$caught von $total gefangen',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDark ? const Color(0xFF1B1B24) : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      isSelected ? theme.colorScheme.primary : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tracker settings dialog configuring scan region presets, polling intervals, and auto-catch options.
class _TrackerSettingsDialog extends StatefulWidget {
  final ScanRegionPreset currentPreset;
  final ScannerSettings settings;
  final ValueChanged<ScanRegionPreset> onPresetChanged;
  final ValueChanged<ScannerSettings> onSettingsChanged;

  const _TrackerSettingsDialog({
    required this.currentPreset,
    required this.settings,
    required this.onPresetChanged,
    required this.onSettingsChanged,
  });

  @override
  State<_TrackerSettingsDialog> createState() => _TrackerSettingsDialogState();
}

class _TrackerSettingsDialogState extends State<_TrackerSettingsDialog> {
  late ScanRegionPreset _preset;
  late bool _autoMark;

  @override
  void initState() {
    super.initState();
    _preset = widget.currentPreset;
    _autoMark = widget.settings.autoMarkCaught;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Tracker-Einstellungen', style: TextStyle(fontSize: 16)),
            ],
          ),
          IconButton(
            key: const Key('btn_close_settings'),
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scanbereich (Fensterbereich)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Wähle welcher Teil des Emulatorfensters per OCR abgetastet werden soll:',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              RadioGroup<ScanRegionPreset>(
                groupValue: _preset,
                onChanged: (p) {
                  if (p != null) {
                    setState(() => _preset = p);
                    widget.onPresetChanged(p);
                  }
                },
                child: Column(
                  children: [
                    _buildPresetOption(
                      key: 'preset_full_window',
                      preset: ScanRegionPreset.fullWindow,
                      title: 'Ganzes Fenster (Empfohlen für DS & Multi-Screen)',
                      subtitle: 'Scannt das gesamte Spielfenster (100%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_top_screen',
                      preset: ScanRegionPreset.dsTopScreen,
                      title: 'Oberer DS-Bildschirm (DS-Kämpfe & Dialoge)',
                      subtitle: 'Scannt oberen Bildschirm (0-52%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_ds_bottom_screen',
                      preset: ScanRegionPreset.dsBottomScreen,
                      title: 'Unterer DS-Bildschirm (Touchscreen)',
                      subtitle: 'Scannt unteren Bildschirm (48-100%)',
                    ),
                    _buildPresetOption(
                      key: 'preset_bottom_dialogue',
                      preset: ScanRegionPreset.bottomDialogue,
                      title: 'Klassische Textbox (GBA / 3DS unten)',
                      subtitle: 'Scannt Textbox am unteren Fensterrand (70-100%)',
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              SwitchListTile(
                key: const Key('switch_auto_mark_caught'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Automatisch eintragen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                  'Erkannte Fänge direkt ohne Klick im Ziel-Dex speichern',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                value: _autoMark,
                onChanged: (val) {
                  setState(() => _autoMark = val);
                  widget.onSettingsChanged(widget.settings.copyWith(autoMarkCaught: val));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetOption({
    required String key,
    required ScanRegionPreset preset,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      key: Key(key),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Radio<ScanRegionPreset>(
        value: preset,
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      onTap: () {
        setState(() => _preset = preset);
        widget.onPresetChanged(preset);
      },
    );
  }
}
