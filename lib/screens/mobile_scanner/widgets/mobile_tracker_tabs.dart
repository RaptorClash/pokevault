import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/pokemon.dart';
import '../../../models/user_dex.dart';
import '../../../services/desktop_tracker/desktop_window_source.dart';
import '../../../services/desktop_tracker/evolution_chain_helper.dart';
import '../../../services/desktop_tracker/tracker_alert_service.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/mobile_scanner/mobile_camera_source.dart';
import '../../../services/scanner_core/models/scanner_event.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';
import '../../../utils/dex_logic_helper.dart';

/// Tab 1: Active target Pokédex, Live-Fokus cards, evolution chain check, and buddy ignore filter.
class MobileFocusDexTab extends StatelessWidget {
  final UserDex? activeDex;
  final List<ScannerEvent> activeFocusEvents;
  final ScannerEvent? latestEvent;
  final EvolutionCheckStatus? evolutionStatus;
  final Map<int, Pokemon> pokemonById;
  final List<int> ignoredPokemonIds;
  final bool Function(int pokemonId) isPokemonCaught;
  final VoidCallback onSelectDex;
  final VoidCallback onOpenStarterFilterInfo;
  final ValueChanged<int> onUnignorePokemon;
  final void Function(int pokemonId, {String? displayName}) onIgnorePokemon;
  final void Function(int pokemonId, {bool isShiny, bool isAlpha}) onMarkCaught;

  const MobileFocusDexTab({
    super.key,
    required this.activeDex,
    required this.activeFocusEvents,
    required this.latestEvent,
    required this.evolutionStatus,
    required this.pokemonById,
    required this.ignoredPokemonIds,
    required this.isPokemonCaught,
    required this.onSelectDex,
    required this.onOpenStarterFilterInfo,
    required this.onUnignorePokemon,
    required this.onIgnorePokemon,
    required this.onMarkCaught,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dex = activeDex;
    final stats = dex != null ? DexLogicHelper.computeDexProgress(dex) : null;
    final focusEvent =
        activeFocusEvents.isNotEmpty ? activeFocusEvents.first : latestEvent;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildTargetDexCard(context, dex, stats, theme),
        const SizedBox(height: 10),
        if (activeFocusEvents.length > 1)
          _buildMultiFocusGrid(context, activeFocusEvents, theme)
        else
          _buildLiveFocusCard(context, focusEvent, theme),
        if (ignoredPokemonIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildIgnoredSection(theme),
        ],
      ],
    );
  }

  Widget _buildMultiFocusGrid(
    BuildContext context,
    List<ScannerEvent> events,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      key: const Key('mobile_multi_focus_grid'),
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 340;
        final itemWidth =
            twoCols ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: events
              .map(
                (ev) => SizedBox(
                  width: itemWidth,
                  child: _buildLiveFocusCard(
                    context,
                    ev,
                    theme,
                    showInstanceBadge: true,
                    compact: twoCols,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildTargetDexCard(
    BuildContext context,
    UserDex? dex,
    TrackerDexProgress? stats,
    ThemeData theme,
  ) {
    final colors = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        key: const Key('btn_mobile_select_dex'),
        borderRadius: BorderRadius.circular(14),
        onTap: onSelectDex,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, size: 18, color: Color(0xFFEF5350)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dex?.title ?? t.scanner_mob_no_target_dex,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onSelectDex,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      t.scanner_mob_switch,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              if (stats != null) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: stats.percent.clamp(0.0, 1.0),
                  borderRadius: BorderRadius.circular(6),
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  t.scanner_mob_dex_progress
                      .replaceAll('{caught}', '${stats.caughtCount}')
                      .replaceAll('{total}', '${stats.totalCount}')
                      .replaceAll(
                        '{pct}',
                        (stats.percent * 100).toStringAsFixed(1),
                      ),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFocusCard(
    BuildContext context,
    ScannerEvent? ev,
    ThemeData theme, {
    bool showInstanceBadge = false,
    bool compact = false,
  }) {
    final colors = theme.colorScheme;
    if (ev == null) {
      return Card(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.center_focus_weak, color: colors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.scanner_mob_no_focus_pokemon,
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pid = ev.pokemonId;
    final caught = pid != null && isPokemonCaught(pid);
    final evo = compact ? null : evolutionStatus;
    final slotColor = ev.instanceColorHex != null
        ? Color(ev.instanceColorHex!)
        : (ev.instanceIndex != null
            ? Color(
                MultiInstanceGridHelper.colorForIndex(
                  ev.instanceIndex! > 0 ? ev.instanceIndex! - 1 : 0,
                ),
              )
            : colors.primary);

    return Card(
      key: showInstanceBadge
          ? Key('mobile_live_focus_card_${ev.instanceIndex ?? 1}')
          : const Key('mobile_live_focus_card'),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: ev.isShiny
              ? const Color(0xFFFBC02D)
              : (caught ? Colors.green : slotColor.withValues(alpha: 0.7)),
          width: ev.isShiny ? 1.8 : 1.2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showInstanceBadge) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: slotColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.scanner_multi_instance_title.replaceAll(
                    '{label}',
                    '#${ev.instanceIndex ?? 1}',
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: slotColor,
                  ),
                ),
              ),
            ],
            Row(
              children: [
                if (ev.isShiny)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('✨', style: TextStyle(fontSize: 16)),
                  ),
                if (ev.isAlpha)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('🔥', style: TextStyle(fontSize: 15)),
                  ),
                Expanded(
                  child: Text(
                    '${ev.matchedName}${pid != null ? ' (#$pid)' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (caught ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    caught
                        ? t.scanner_caught_badge_short
                        : t.scanner_mob_missing,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: caught ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            if (evo != null && evo.hasEvolutions) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (evo.hasMissingEvolutions ? Colors.amber : Colors.green)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  evo.summaryLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: evo.hasMissingEvolutions
                        ? Colors.amber.shade700
                        : Colors.green,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (pid != null)
                  ElevatedButton.icon(
                    key: showInstanceBadge
                        ? Key('btn_mobile_focus_mark_caught_${ev.instanceIndex ?? 1}')
                        : const Key('btn_mobile_focus_mark_caught'),
                    onPressed: () => onMarkCaught(
                      pid,
                      isShiny: ev.isShiny,
                      isAlpha: ev.isAlpha,
                    ),
                    icon: Icon(
                      caught ? Icons.check_circle : Icons.catching_pokemon,
                      size: 16,
                    ),
                    label: Text(
                      caught
                          ? t.scanner_mob_mark_again
                          : t.scanner_mob_mark_in_dex,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (pid != null && !compact)
                  OutlinedButton.icon(
                    onPressed: () =>
                        onIgnorePokemon(pid, displayName: ev.matchedName),
                    icon: const Icon(Icons.visibility_off_outlined, size: 15),
                    label: Text(
                      t.scanner_mob_ignore_starter,
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIgnoredSection(ThemeData theme) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.scanner_mob_ignored_starters,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: onOpenStarterFilterInfo,
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ignoredPokemonIds.map((id) {
              final name = pokemonById[id]?.nameDe ?? '#$id';
              return InputChip(
                label: Text('$name (#$id)', style: const TextStyle(fontSize: 11)),
                onDeleted: () => onUnignorePokemon(id),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Grouped camera hardware state for [MobileZonesCameraTab].
class MobileCameraHardwareConfig {
  final bool torchEnabled;
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final List<CameraDescription> cameras;
  final int selectedCameraIndex;

  const MobileCameraHardwareConfig({
    this.torchEnabled = false,
    this.zoomLevel = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
    this.cameras = const [],
    this.selectedCameraIndex = 0,
  });
}

/// Grouped scan zone and multi-instance editor state for [MobileZonesCameraTab].
class MobileZonesEditConfig {
  final MobileCameraScanMode scanMode;
  final ScanRegionPreset autoPreset;
  final List<NormalizedScanRect> regions;
  final CameraBrushTarget activeBrushTarget;
  final List<int> multiSlotIds;
  final bool isEditingRegions;

  const MobileZonesEditConfig({
    required this.scanMode,
    required this.autoPreset,
    required this.regions,
    required this.activeBrushTarget,
    required this.multiSlotIds,
    required this.isEditingRegions,
  });
}

/// Tab 2: Auto vs. Draw rectangle management, paired Multi-Instance Zone A/B cards,
/// camera selection dropdown & hardware controls, and OCR language & preprocessing.
class MobileZonesCameraTab extends StatelessWidget {
  final MobileCameraHardwareConfig? hardwareConfig;
  final MobileZonesEditConfig? zonesConfig;
  final MobileCameraScanMode? scanMode;
  final ScanRegionPreset? autoPreset;
  final List<NormalizedScanRect>? regions;
  final CameraBrushTarget? activeBrushTarget;
  final List<int>? multiSlotIds;
  final bool? isEditingRegions;
  final ScannerSettings settings;
  final String ocrLanguageCode;
  final TrackerAlertSettings alertSettings;
  final bool? torchEnabled;
  final double? zoomLevel;
  final double? minZoom;
  final double? maxZoom;
  final List<CameraDescription>? cameras;
  final int? selectedCameraIndex;
  final ValueChanged<MobileCameraScanMode> onScanModeChanged;
  final ValueChanged<ScanRegionPreset> onAutoPresetChanged;
  final ValueChanged<CameraBrushTarget> onSelectBrushTarget;
  final ValueChanged<bool> onEditingChanged;
  final VoidCallback onAddMultiSlot;
  final ValueChanged<int> onRemoveMultiSlot;
  final ValueChanged<int> onToggleMultiSlotEnabled;
  final VoidCallback onClearRegions;
  final ValueChanged<String> onDeleteRegion;
  final ValueChanged<String> onToggleRegionEnabled;
  final VoidCallback onToggleTorch;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<int> onSelectCameraIndex;
  final VoidCallback onSwitchCamera;
  final VoidCallback onImportPhoto;
  final ValueChanged<ScannerSettings> onSettingsChanged;
  final ValueChanged<String> onOcrLanguageChanged;
  final ValueChanged<TrackerAlertSettings> onAlertSettingsChanged;
  final VoidCallback onOpenCustomPatterns;

  const MobileZonesCameraTab({
    super.key,
    this.hardwareConfig,
    this.zonesConfig,
    this.scanMode,
    this.autoPreset,
    this.regions,
    this.activeBrushTarget,
    this.multiSlotIds,
    this.isEditingRegions,
    required this.settings,
    required this.ocrLanguageCode,
    required this.alertSettings,
    this.torchEnabled,
    this.zoomLevel,
    this.minZoom,
    this.maxZoom,
    this.cameras,
    this.selectedCameraIndex,
    required this.onScanModeChanged,
    required this.onAutoPresetChanged,
    required this.onSelectBrushTarget,
    required this.onEditingChanged,
    required this.onAddMultiSlot,
    required this.onRemoveMultiSlot,
    required this.onToggleMultiSlotEnabled,
    required this.onClearRegions,
    required this.onDeleteRegion,
    required this.onToggleRegionEnabled,
    required this.onToggleTorch,
    required this.onZoomChanged,
    required this.onSelectCameraIndex,
    required this.onSwitchCamera,
    required this.onImportPhoto,
    required this.onSettingsChanged,
    required this.onOcrLanguageChanged,
    required this.onAlertSettingsChanged,
    required this.onOpenCustomPatterns,
  }) : assert(zonesConfig != null || scanMode != null),
       assert(zonesConfig != null || autoPreset != null),
       assert(zonesConfig != null || regions != null),
       assert(zonesConfig != null || activeBrushTarget != null),
       assert(zonesConfig != null || multiSlotIds != null),
       assert(zonesConfig != null || isEditingRegions != null);

  MobileCameraScanMode get _scanMode => zonesConfig?.scanMode ?? scanMode!;
  ScanRegionPreset get _autoPreset => zonesConfig?.autoPreset ?? autoPreset!;
  List<NormalizedScanRect> get _regions => zonesConfig?.regions ?? regions!;
  CameraBrushTarget get _activeBrushTarget =>
      zonesConfig?.activeBrushTarget ?? activeBrushTarget!;
  List<int> get _multiSlotIds => zonesConfig?.multiSlotIds ?? multiSlotIds!;
  bool get _isEditingRegions =>
      zonesConfig?.isEditingRegions ?? isEditingRegions!;

  bool get _torchEnabled =>
      hardwareConfig?.torchEnabled ?? torchEnabled ?? false;
  double get _zoomLevel => hardwareConfig?.zoomLevel ?? zoomLevel ?? 1.0;
  double get _minZoom => hardwareConfig?.minZoom ?? minZoom ?? 1.0;
  double get _maxZoom => hardwareConfig?.maxZoom ?? maxZoom ?? 1.0;
  List<CameraDescription> get _cameras =>
      hardwareConfig?.cameras ?? cameras ?? const [];
  int get _selectedCameraIndex =>
      hardwareConfig?.selectedCameraIndex ?? selectedCameraIndex ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cardColor = colors.surface;
    final borderColor = colors.outlineVariant;
    final mainZoneA = _findById('zone_a');
    final mainZoneB = _findById('zone_b');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionCard(
          color: cardColor,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.scanner_mob_scan_mode_header,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(t.scanner_mob_auto_fullscreen),
                    selected: _scanMode == MobileCameraScanMode.autoFull,
                    onSelected: (_) =>
                        onScanModeChanged(MobileCameraScanMode.autoFull),
                  ),
                  ChoiceChip(
                    label: Text(t.scanner_mob_draw_rects),
                    selected: _scanMode == MobileCameraScanMode.customRegions,
                    onSelected: (_) =>
                        onScanModeChanged(MobileCameraScanMode.customRegions),
                  ),
                ],
              ),
              if (_scanMode == MobileCameraScanMode.autoFull) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ScanRegionPreset.values.map((p) {
                    return ChoiceChip(
                      label: Text(p.labelDe, style: const TextStyle(fontSize: 11)),
                      selected: _autoPreset == p,
                      onSelected: (_) => onAutoPresetChanged(p),
                    );
                  }).toList(),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: Text(
                        _isEditingRegions
                            ? t.scanner_mob_drawing_active
                            : t.scanner_mob_rects_locked,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: _isEditingRegions,
                      onSelected: onEditingChanged,
                    ),
                    if (_regions.isNotEmpty)
                      TextButton.icon(
                        onPressed: onClearRegions,
                        icon: const Icon(Icons.delete_sweep, size: 15),
                        label: Text(
                          t.scanner_clear_all,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildZoneRow(
                  context: context,
                  target: CameraBrushTarget.zoneA(),
                  region: mainZoneA,
                  drawLabel: mainZoneA == null
                      ? t.scanner_mob_draw_zone_a
                      : t.scanner_mob_redraw_zone_a,
                ),
                const SizedBox(height: 6),
                _buildZoneRow(
                  context: context,
                  target: CameraBrushTarget.zoneB(),
                  region: mainZoneB,
                  drawLabel: mainZoneB == null
                      ? t.scanner_mob_draw_zone_b
                      : t.scanner_mob_redraw_zone_b,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildMultiInstancesSection(
          context: context,
          cardColor: cardColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),
        _sectionCard(
          color: cardColor,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.scanner_mob_camera_photo_header,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                key: const Key('dropdown_mobile_camera_selector'),
                initialValue: _cameras.isEmpty
                    ? -1
                    : _selectedCameraIndex.clamp(0, _cameras.length - 1),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: t.scanner_mob_active_camera,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: _cameras.isEmpty
                    ? [
                        DropdownMenuItem<int>(
                          value: -1,
                          child: Text(
                            t.scanner_mob_no_hw_camera,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    : List.generate(_cameras.length, (i) {
                        final cam = _cameras[i];
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            _formatCameraLabel(cam, i),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                onChanged: _cameras.isEmpty
                    ? null
                    : (idx) {
                        if (idx != null && idx >= 0) {
                          onSelectCameraIndex(idx);
                        }
                      },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: onToggleTorch,
                    icon: Icon(
                      _torchEnabled ? Icons.flash_on : Icons.flash_off,
                      size: 16,
                    ),
                    label: Text(
                      _torchEnabled
                          ? t.scanner_mob_light_on
                          : t.scanner_mob_torch,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  if (_cameras.length > 1)
                    OutlinedButton.icon(
                      onPressed: onSwitchCamera,
                      icon: const Icon(Icons.cameraswitch_outlined, size: 16),
                      label: Text(
                        t.scanner_mob_flip_camera,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: onImportPhoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      t.scanner_webcam_scan_photo,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              if (_maxZoom > _minZoom) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.zoom_in, size: 16),
                    Expanded(
                      child: Slider(
                        value: _zoomLevel.clamp(_minZoom, _maxZoom),
                        min: _minZoom,
                        max: _maxZoom,
                        label: '${_zoomLevel.toStringAsFixed(1)}×',
                        onChanged: onZoomChanged,
                      ),
                    ),
                    Text(
                      '${_zoomLevel.toStringAsFixed(1)}×',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          color: cardColor,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.scanner_mob_ocr_automation_header,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('dropdown_mobile_ocr_language'),
                initialValue: kSupportedScannerOcrLanguages
                        .any((o) => o.code == ocrLanguageCode)
                    ? ocrLanguageCode
                    : 'auto',
                decoration: InputDecoration(
                  labelText: t.scanner_mob_ocr_lang_label,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: kSupportedScannerOcrLanguages
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.code,
                        child: Text(o.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) onOcrLanguageChanged(val);
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: OcrPreprocessProfile.values.map((profile) {
                  return ChoiceChip(
                    label: Text(
                      profile.labelDe,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: settings.preprocessProfile == profile,
                    onSelected: (_) => onSettingsChanged(
                      settings.copyWith(preprocessProfile: profile),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    t.scanner_mob_scan_interval,
                    style: const TextStyle(fontSize: 11),
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.scanIntervalMs.toDouble().clamp(200, 3000),
                      min: 200,
                      max: 3000,
                      divisions: 14,
                      label: '${settings.scanIntervalMs} ms',
                      onChanged: (val) => onSettingsChanged(
                        settings.copyWith(scanIntervalMs: val.round()),
                      ),
                    ),
                  ),
                  Text(
                    '${settings.scanIntervalMs} ms',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t.scanner_mob_auto_save,
                  style: const TextStyle(fontSize: 12),
                ),
                value: settings.autoMarkCaught,
                onChanged: (val) => onSettingsChanged(
                  settings.copyWith(autoMarkCaught: val),
                ),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t.scanner_mob_haptics_alerts,
                  style: const TextStyle(fontSize: 12),
                ),
                value: alertSettings.soundEnabled,
                onChanged: (val) => onAlertSettingsChanged(
                  alertSettings.copyWith(soundEnabled: val, hapticEnabled: val),
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                key: const Key('btn_mobile_custom_patterns'),
                onPressed: onOpenCustomPatterns,
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: Text(
                  t.scanner_mob_custom_patterns.replaceAll(
                    '{count}',
                    '${settings.customPatterns.length}',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  NormalizedScanRect? _findById(String id) {
    for (final r in _regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  String _formatCameraLabel(CameraDescription cam, int index) {
    final lens = switch (cam.lensDirection) {
      CameraLensDirection.back => t.scanner_mob_rear_camera,
      CameraLensDirection.front => t.scanner_mob_front_camera,
      CameraLensDirection.external => t.scanner_mob_external_camera,
    };
    final cleanName = cam.name.trim();
    if (cleanName.length > 2) {
      return '$cleanName ($lens)';
    }
    return '$lens #${index + 1} ($cleanName)';
  }

  Widget _buildMultiInstancesSection({
    required BuildContext context,
    required Color cardColor,
    required Color borderColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    return _sectionCard(
      color: cardColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.scanner_mob_multi_header
                      .replaceAll('{count}', '${_multiSlotIds.length}'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                key: const Key('btn_mobile_multi_add_instance'),
                onPressed: onAddMultiSlot,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  t.scanner_mob_instance_btn,
                  style: const TextStyle(fontSize: 11),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_multiSlotIds.isEmpty)
            Text(
              t.scanner_mob_multi_hint,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            )
          else
            ..._multiSlotIds.map(
              (slotId) => _buildMultiInstanceCard(context, slotId),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiInstanceCard(BuildContext context, int slotId) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final slotColor = Color(
      MultiInstanceGridHelper.colorForIndex(slotId > 0 ? slotId - 1 : 0),
    );
    final scanRect = _regions.scanRectForSlot(slotId);
    final focusRect = _regions.focusRectForSlot(slotId);
    final slotEnabled =
        (scanRect?.enabled ?? true) || (focusRect?.enabled ?? true);

    return Container(
      key: Key('mobile_multi_card_$slotId'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slotColor.withValues(alpha: 0.65), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: slotColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$slotId',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: slotColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.scanner_multi_instance_title.replaceAll(
                    '{label}',
                    '#$slotId',
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: slotEnabled,
                onChanged: (_) => onToggleMultiSlotEnabled(slotId),
              ),
              IconButton(
                key: Key('btn_mobile_multi_remove_$slotId'),
                tooltip: t.scanner_multi_remove_tooltip,
                icon: const Icon(Icons.delete_outline, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: () => onRemoveMultiSlot(slotId),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildZoneRow(
            context: context,
            target: CameraBrushTarget.multiScan(slotId),
            region: scanRect,
            drawLabel: scanRect == null
                ? t.scanner_multi_draw_scan
                : t.scanner_multi_redraw_scan,
            drawButtonKey: Key('btn_mobile_multi_draw_scan_$slotId'),
          ),
          const SizedBox(height: 6),
          _buildZoneRow(
            context: context,
            target: CameraBrushTarget.multiFocus(slotId),
            region: focusRect,
            drawLabel: focusRect == null
                ? t.scanner_multi_draw_focus
                : t.scanner_multi_redraw_focus,
            drawButtonKey: Key('btn_mobile_multi_draw_focus_$slotId'),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneRow({
    required BuildContext context,
    required CameraBrushTarget target,
    required NormalizedScanRect? region,
    required String drawLabel,
    Key? drawButtonKey,
  }) {
    final colors = Theme.of(context).colorScheme;
    final zoneColor = Color(target.colorHex);
    final isSelectedBrush = _activeBrushTarget == target;
    final sizeText = region == null
        ? t.scanner_mob_not_drawn
        : '${(region.width * 100).round()}% × ${(region.height * 100).round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelectedBrush
            ? zoneColor.withValues(alpha: 0.12)
            : colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelectedBrush ? zoneColor : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: zoneColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  target.encounterOnly
                      ? t.scanner_mob_zone_b_focus
                      : t.scanner_mob_zone_a_scan,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sizeText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (region != null) ...[
            Switch(
              value: region.enabled,
              onChanged: (_) => onToggleRegionEnabled(region.id),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 15),
              visualDensity: VisualDensity.compact,
              tooltip: t.scanner_mob_delete_rect,
              onPressed: () => onDeleteRegion(region.id),
            ),
          ],
          OutlinedButton.icon(
            key: drawButtonKey,
            onPressed: () => onSelectBrushTarget(target),
            icon: Icon(
              isSelectedBrush ? Icons.brush : Icons.crop_free,
              size: 14,
              color: zoneColor,
            ),
            label: Text(drawLabel, style: const TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              side: BorderSide(color: zoneColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Color color,
    required Color borderColor,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

/// Tab 3: Live OCR recognition feed, event correction/deletion, and raw ML Kit log console.
class MobileFeedDiagnoseTab extends StatelessWidget {
  final List<ScannerEvent> events;
  final MobileCameraSource cameraSource;
  final ValueChanged<int> onCorrectEvent;
  final ValueChanged<int> onDeleteEvent;
  final void Function(int pokemonId, {bool isShiny, bool isAlpha}) onMarkCaught;

  const MobileFeedDiagnoseTab({
    super.key,
    required this.events,
    required this.cameraSource,
    required this.onCorrectEvent,
    required this.onDeleteEvent,
    required this.onMarkCaught,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          t.scanner_mob_events_header,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (events.isEmpty)
          Card(
            elevation: 0,
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                t.scanner_mob_no_events,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          ...List.generate(events.length, (i) {
            final ev = events[i];
            final pid = ev.pokemonId;
            return Card(
              elevation: 0,
              color: colors.surface,
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: ev.isShiny
                      ? const Color(0xFFFBC02D)
                      : colors.outlineVariant,
                ),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: ev.type == ScannerEventType.caught
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.cyan.withValues(alpha: 0.2),
                  child: Icon(
                    ev.type == ScannerEventType.caught
                        ? Icons.catching_pokemon
                        : Icons.visibility,
                    size: 16,
                  ),
                ),
                title: Text(
                  '${ev.isShiny ? '✨ ' : ''}${ev.isAlpha ? '🔥 ' : ''}${ev.matchedName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  '${ev.type.name.toUpperCase()} · ${ev.rawText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pid != null)
                      IconButton(
                        tooltip: t.scanner_mob_mark_in_dex,
                        icon: const Icon(Icons.add_task, size: 17),
                        onPressed: () => onMarkCaught(
                          pid,
                          isShiny: ev.isShiny,
                          isAlpha: ev.isAlpha,
                        ),
                      ),
                    IconButton(
                      tooltip: t.scanner_mob_correct_tooltip,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      onPressed: () => onCorrectEvent(i),
                    ),
                    IconButton(
                      tooltip: t.scanner_remove_btn,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      onPressed: () => onDeleteEvent(i),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<OcrScanLogEntry>>(
          valueListenable: cameraSource.scanLogsNotifier,
          builder: (context, logs, _) {
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                t.scanner_mob_live_ocr_diagnose
                    .replaceAll('{count}', '${logs.length}'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              children: logs.take(12).map((log) {
                final textSummary = log.rawLines.isEmpty
                    ? (log.errorHint ?? '–')
                    : log.rawLines.join(' | ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '[#${log.scanNumber} · ${log.ocrDurationMs}ms] ${log.targetDescription}: $textSummary',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
